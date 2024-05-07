import logging
from typing import Tuple, Optional, List

from segfreetk.common.states import TranslationState, HelperStates, TranslationHypothesis
from segfreetk.models.model import Model
from segfreetk.common.policies import waitk_policy
from segfreetk.common.constants import READ_ACTION, WRITE_ACTION
from segfreetk.common.subword_splitters import Splitter

logger = logging.getLogger(__name__)


class Agent:
    def __init__(self, states: TranslationState, translation_model: Model, src_splitter: Splitter,
                 tgt_splitter: Splitter, k: int, catchup: int, max_forced_read_actions_before_fallback: int,
                 src_history_max_len: int, tgt_history_max_len: int):
        self.states = states
        self.translation_model = translation_model
        self.src_splitter = src_splitter
        self.tgt_splitter = tgt_splitter
        self.gamma = catchup
        self.k = k
        self.src_history_max_len = src_history_max_len
        self.tgt_history_max_len = tgt_history_max_len
        # If this is exceeded, we fall-back to sentence-translation
        self.max_forced_read_actions_before_fallback = max_forced_read_actions_before_fallback
        self.consecutive_forced_read_actions: int = 0

    def policy(self) -> Tuple[Tuple[int, int], Optional[HelperStates]]:
        """
        Implements the policy of the agent.

        :return: (action, n_actions), extra_items
          Action is READ/WRITE action
          n_actions is how many of those to carry out. n_actions = -1 means we write as many words as possible.
          Optionally, we return a HelperStates object, which can be reused later to avoid re-computation
        """
        # TODO extract this to some sort of generic policy wrapper?
        if self.states.finished_read:
            return (WRITE_ACTION, -1), None

        hypo_list, num_prefix_tokens = self.get_translation_hypotheses()
        helper_states = HelperStates(sorted_translation_hypotheses=hypo_list, num_prefix_tokens=num_prefix_tokens)

        force_read = self.check_force_read_action(helper_states)

        # If this forced read would exceed the maximum, we fallback to sentence-level translation
        if 0 < self.max_forced_read_actions_before_fallback <= self.consecutive_forced_read_actions:
            logger.warning("Falling back to sentence-level translation")
            # Fallback to sentence-level
            self.states.src_segments = self.states.src_segments[-1:]
            self.states.tgt_segments = self.states.tgt_segments[-1:]
            self.consecutive_forced_read_actions = 0
            # After fallback, we check force read again
            force_read = self.check_force_read_action(helper_states)

        if force_read:
            self.consecutive_forced_read_actions += 1
            return (READ_ACTION, 1), helper_states
        else:
            return waitk_policy(states=self.states, gamma=self.gamma, k=self.k), helper_states

    def read_action(self, word: str) -> None:
        """
        Carries out a read action.

        This method updates self.states updated accordignly to the read operation.

        :param word: The word to be read.
        """
        raise NotImplementedError

    def process_finished_read(self) -> None:
        """
        Helper method, called when the end of the source stream is reached.

        This method must carry out any changes
        that might need to be applied when we have finished reading all input words.
        """
        self.states.finished_read = True

    def write_action(self, num_words: int = 1, extra_items: HelperStates = None) -> List[str]:
        """
        Carries out a write action.

        This method updates self.states accordingly.

        :param num_words: How many words have to be written. -1 means that we write as many words as possible.
        :param extra_items: If provided, they will be used to avoid re-computation
        :return: The list of words that have been written.
        """
        raise NotImplementedError

    def reset(self):
        raise NotImplementedError

    def get_translation_hypotheses(self) -> Tuple[List[TranslationHypothesis], int]:
        src_idx, tgt_idx = self.translation_model.get_indexes_from_states(self.states, self.src_splitter,
                                                                          self.tgt_splitter)
        if self.translation_model.append_eos:
            src_idx.append(self.translation_model.dict["src"].eos_index)

        logger.debug(f"Hypothesis indexes src {src_idx} tgt {tgt_idx}")
        hypos = self.translation_model.get_translation_hypothesis(src_idx, tgt_idx,
                                                                  max_len=500)
        return hypos, len(tgt_idx)

    def get_merged_tokens_to_write_from_hypo(self, hypo: TranslationHypothesis, num_prefix_tokens: int) -> List[str]:
        # Only select new tokens, and we disregard the last one (EOS)
        idx_to_write = hypo.translation_indexes[num_prefix_tokens:-1]

        tokens_to_write = [self.translation_model.dict["tgt"][x] for x in idx_to_write]

        merged_toks_to_write = self.tgt_splitter.merge(tokens_to_write).split()

        return merged_toks_to_write

    def check_force_read_action(self, helper_states: HelperStates) -> bool:
        top_hypo = helper_states.sorted_translation_hypotheses[0]
        num_prefix_tokens = helper_states.num_prefix_tokens

        merged_toks_to_write = self.get_merged_tokens_to_write_from_hypo(hypo=top_hypo,
                                                                         num_prefix_tokens=num_prefix_tokens)

        if len(self.states.src_segments) == 0 or len(self.states.src_segments[-1]) == 0:
            logger.debug(f"Forced READ action due to empty src")
            return True
        elif len(merged_toks_to_write) == 0:
            logger.warning(f"Forced READ action due to empty hypo")
            return True
        elif not self.states.finished_read and (merged_toks_to_write[0] == self.translation_model.special_tokens.tgt_brk
                or merged_toks_to_write[0] == self.translation_model.special_tokens.tgt_end
                or merged_toks_to_write[0] == self.translation_model.special_tokens.tgt_end_of_prefix):
            logger.warning(f"Forced READ action due to current hypo: {merged_toks_to_write[:5]}")
            return True
        else:
            return False
