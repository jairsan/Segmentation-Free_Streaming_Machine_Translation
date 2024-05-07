import logging
from typing import List
from argparse import ArgumentParser
from segfreetk.agents.agent import Agent
from segfreetk.common.states import TranslationState, HelperStates

from segfreetk.features.feature_scorer import FeatureScorer

logger = logging.getLogger(__name__)


class TranslateThenRealignAgent(Agent):
    name: str = "realign_segmentation_free_agent"

    def __init__(self, feature_scorer: FeatureScorer,
                 force_realign_after_n_tgt_words: int = 100, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.feature_scorer = feature_scorer

        self.force_realign_after_n_tgt_words = force_realign_after_n_tgt_words

    @staticmethod
    def add_args(parser: ArgumentParser):
        parser.add_argument("--feature_scorer", type=str, required=True)

    def read_action(self, word: str):
        self.states.src_segments[-1].append(word)

    def write_action(self, num_words: int = 1, extra_items: HelperStates = None) -> List[str]:

        if extra_items is None:
            hypos, num_prefix_tokens = self.get_translation_hypotheses()
            extra_items = HelperStates(hypos, num_prefix_tokens)

        hypos = extra_items.sorted_translation_hypotheses
        num_prefix_tokens = extra_items.num_prefix_tokens
        top_hypo = hypos[0]

        # TODO check that the hypo contains an actual word, which might require a while loop
        # TODO write until end
        merged_toks_to_write = self.get_merged_tokens_to_write_from_hypo(hypo=top_hypo,  num_prefix_tokens=num_prefix_tokens)

        # Only write the first num_words, unless num_words=-1, on which case we write all
        if num_words == -1:
            num_words = len(merged_toks_to_write)

        words_to_write = []

        if self.states.finished_read:
            for segment in merged_toks_to_write:
                if segment not in self.translation_model.special_tokens.all_special_tokens:
                    self.states.tgt_segments[-1].append(segment)
                    words_to_write.append(segment)
                elif segment == self.translation_model.special_tokens.tgt_sep:
                    # Notice how the special token is NOT added to the states, unlike the previous case
                    words_to_write.append(segment)

            # TODO check if some other test should be done
            self.states.finished_write = True
        else:
            need_to_align = False
            for segment in merged_toks_to_write[:num_words]:
                if segment not in self.translation_model.special_tokens.all_special_tokens:
                    self.states.tgt_segments[-1].append(segment)
                    words_to_write.append(segment)
                elif segment == self.translation_model.special_tokens.tgt_sep:
                    # Notice how the special token is NOT added to the states, unlike the previous case
                    words_to_write.append(segment)
                    need_to_align = True
                    break

            if len(self.states.tgt_segments[-1]) > self.force_realign_after_n_tgt_words:
                need_to_align = True

            if need_to_align:
                self.update_states()

        return words_to_write

    def update_states(self, helper_states: HelperStates = None):
        """
        Updates self.states.

        This method is called when we want to re-align after having produced a hypothesis that ends in [SEP]

        :param helper_states:
        :return:
        """
        # First, we split the last translation
        # Then, remove sentence pairs if capacity has been exceeded
        logger.debug(f"Re-alignment src {self.states.src_segments} "
                     f"tgt {self.states.tgt_segments}")
        logger.debug(f"Re-alignment between {self.states.src_segments[-1]} "
                     f"and {self.states.tgt_segments[-1]}")
        scores = self.feature_scorer.score_states(self.states, helper_states=helper_states)

        # TODO replace this by a simple argmax
        # 0 -> position
        # 1 -> score
        enum_scores = list(enumerate(scores))
        sorted_scores = sorted(enum_scores, key=lambda x: x[1], reverse=True)

        split_position, split_score = sorted_scores[0]
        logger.debug(f"Will split in position {split_position} with score {split_score}")

        new_src_sentence = self.states.src_segments[-1][split_position+1:]

        # Add the non-translated segments to a new sentence-pair,
        # then remove them from the previous sentence-pair
        self.states.src_segments.append(new_src_sentence)
        self.states.tgt_segments.append([])
        for _ in self.states.src_segments[-1]:
            self.states.src_segments[-2].pop()

        assert len(self.states.src_segments) == len(self.states.tgt_segments)

        logger.debug(f"After re-alignment src {self.states.src_segments} "
                     f"tgt {self.states.tgt_segments}")

        self.states.filter_segments_to_max_len(src_max_len=self.src_history_max_len,
                                               tgt_max_len=self.tgt_history_max_len)

        logger.debug(f"After filtering src {self.states.src_segments} "
                     f"tgt {self.states.tgt_segments}")
        assert len(self.states.src_segments) == len(self.states.tgt_segments)

    def reset(self):
        self.states = TranslationState()


