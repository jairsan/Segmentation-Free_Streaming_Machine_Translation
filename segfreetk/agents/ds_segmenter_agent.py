from typing import Optional, List, Tuple
from argparse import ArgumentParser
import logging
import time

from segmenter.ds_segmenter import DsSegmenter

from segfreetk.agents.agent import Agent
from segfreetk.common.states import TranslationState, HelperStates
from segfreetk.common.constants import WRITE_ACTION

logger = logging.getLogger(__name__)


class DsSegmenterAgent(Agent):
    name = "ds_segmenter_agent"

    def __init__(self, segmenter: DsSegmenter, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.segmenter = segmenter

    @staticmethod
    def add_args(parser: ArgumentParser):
        parser.add_argument("--segmenter_checkpoint", type=str, required=True)

    def policy(self) -> Tuple[Tuple[int, int], Optional[HelperStates]]:
        if self.states.last_segmenter_decision_is_split:
            return (WRITE_ACTION, -1), None
        else:
            return super().policy()

    def check_force_read_action(self, helper_states: HelperStates) -> bool:
        top_hypo = helper_states.sorted_translation_hypotheses[0]
        num_prefix_tokens = helper_states.num_prefix_tokens

        merged_toks_to_write = self.get_merged_tokens_to_write_from_hypo(hypo=top_hypo,
                                                                         num_prefix_tokens=num_prefix_tokens)
        count_special = sum([1 if x in self.translation_model.special_tokens.all_special_tokens else 0 for x in merged_toks_to_write])

        # Because SEP does not have special meaning for the DS agent, we force read if the hypo consists only
        # in special tokens
        if count_special == len(merged_toks_to_write):
            return True
        else:
            return super().check_force_read_action(helper_states=helper_states)

    def read_action(self, word: str) -> None:
        start_t = time.time()
        processed_word, is_split = self.segmenter.step(word)
        end_t = time.time()
        cost = end_t - start_t
        logger.debug(f"Called DS segmenter, cost: {cost}")

        if processed_word is not None:
            self.states.src_segments[-1].append(processed_word)
            self.states.last_segmenter_decision_is_split = is_split

    def process_finished_read(self) -> None:
        # When we have reached the end of the source stream, there are still some words to be processed in the segmenter
        # buffer. We will now extract those words so that they are all translated.
        if len(self.segmenter.unprocessed_words) > 0:
            self.states.src_segments[-1].extend(self.segmenter.unprocessed_words)
            
        super().process_finished_read()
            
    def write_action(self, num_words: int = 1, extra_items: HelperStates = None) -> List[str]:
        if extra_items is None:
            hypos, num_prefix_tokens = self.get_translation_hypotheses()
            extra_items = HelperStates(hypos, num_prefix_tokens)

        hypos = extra_items.sorted_translation_hypotheses
        num_prefix_tokens = extra_items.num_prefix_tokens
        top_hypo = hypos[0]

        # TODO check that the hypo contains an actual word, which might require a while loop
        # TODO write until end
        merged_toks_to_write = self.get_merged_tokens_to_write_from_hypo(hypo=top_hypo,
                                                                         num_prefix_tokens=num_prefix_tokens)

        # If segmenter has finished chunk, we write all words on the hypo
        if self.states.last_segmenter_decision_is_split:
            num_words = -1

        # Only write the first num_words, unless num_words=-1, on which case we write all
        if num_words == -1:
            num_words = len(merged_toks_to_write)

        logger.debug(f"Write action will attempt to write {num_words} words out of these tokens: {merged_toks_to_write}")

        words_to_write = []

        if self.states.finished_read:
            for segment in merged_toks_to_write:
                if segment not in self.translation_model.special_tokens.all_special_tokens:
                    self.states.tgt_segments[-1].append(segment)
                    words_to_write.append(segment)

            # TODO check if some other test should be done
            self.states.finished_write = True
        else:
            # SEP tokens are ignored due to some edge cases where the model hallucinates additional SEP tokens that do
            # not exist in the src
            merged_toks_to_write = [x for x in merged_toks_to_write if x != self.translation_model.special_tokens.tgt_sep]
            for segment in merged_toks_to_write[:num_words]:
                if segment not in self.translation_model.special_tokens.all_special_tokens:
                    self.states.tgt_segments[-1].append(segment)
                    words_to_write.append(segment)

        if self.states.last_segmenter_decision_is_split:
            self.states.src_segments.append([])
            self.states.tgt_segments.append([])
            self.states.filter_segments_to_max_len(src_max_len=self.src_history_max_len,
                                                   tgt_max_len=self.tgt_history_max_len)
            self.states.last_segmenter_decision_is_split = False
        return words_to_write

    def reset(self):
        self.states = TranslationState()
        self.segmenter.reset()


class OracleSegmenter(DsSegmenter):
    def __init__(self, sample_window_size: int):
        self.unprocessed_words: List[str] = []
        self.sample_window_size = sample_window_size

    def step(self, new_word: str) -> Tuple[Optional[str], bool]:
        """
        Input:
            - new_word: Word given to the model. It will be processed once enough context is available.

        Output: (output_word, is_end_of_segment)
            - output_word: Word for which we have taken a decision. This is different from new_word if future_window> 0.
                Can be None if we don't have enough future words
            - is_end_of_segment: If True, output_word is the word that ends the segment i.e. typically we would
                then append /n

        Main method. Should be called each time a new_word is read.

        Note that when the whole stream has been read, there are some unprocesed words remaining
        in self.unprocessed_words
        """
        self.unprocessed_words.append(new_word)

        current_word = self.unprocessed_words[0]
        if len(self.unprocessed_words) >= self.sample_window_size + 1:
            self.unprocessed_words.pop(0)

        decision = current_word.endswith("\n")

        return current_word.strip(), decision

    def reset(self):
        self.unprocessed_words = []


class DsSegmenterOracleAgent(DsSegmenterAgent):
    name = "ds_segmenter_oracle_agent"

    def __init__(self, segmenter: OracleSegmenter, *args, **kwargs):
        super(DsSegmenterOracleAgent, self).__init__(segmenter=segmenter, *args, **kwargs)

    @staticmethod
    def add_args(parser: ArgumentParser):
        parser.add_argument("--oracle_segmenter_window", type=int, required=True)

    def read_action(self, word: str) -> None:
        processed_word, is_split = self.segmenter.step(word)
        if processed_word is not None:
            self.states.src_segments[-1].append(processed_word)
            self.states.last_segmenter_decision_is_split = is_split

    def process_finished_read(self) -> None:
        # When we have reached the end of the source stream, there are still some words to be processed in the segmenter
        # buffer. We will now extract those words so that they are all translated.
        if len(self.segmenter.unprocessed_words) > 0:
            # We strip words because they might contain \n in the Oracle case
            # Note that this is not the exact "Oracle" behaviour, becase if there are two \n inside the future window
            # only the last one will be taken into account
            stripped_words = [x.strip() for x in self.segmenter.unprocessed_words]
            self.states.src_segments[-1].extend(stripped_words)

        super().process_finished_read()

