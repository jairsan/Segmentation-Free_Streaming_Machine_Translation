from argparse import ArgumentParser
from typing import List, Tuple
import logging

from segfreetk.agents.agent import Agent

from segfreetk.common.states import TranslationState, HelperStates, TranslationHypothesis
from segfreetk.common.constants import READ_ACTION

logger = logging.getLogger(__name__)


class SlidingWindowAgent(Agent):
    name = "sliding_window_agent"

    def __init__(self, window_length: int, threshold: int, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.window_length = window_length
        self.threshold = threshold

    @staticmethod
    def add_args(parser: ArgumentParser):
        parser.add_argument("--window_length", type=int)
        parser.add_argument("--threshold", type=float)

    def reset(self):
        self.states = TranslationState()

    def read_action(self, word: str):
        self.states.src_segments[-1].append(word)

    def translate_and_get_merge_indices(self) -> Tuple[int, int, int, List[str], int]:
        k = 0
        while True:
            src_window = self.states.src_segments[-1][max(0, len(self.states.src_segments[-1]) - (self.window_length + k)):]
            states = TranslationState(src_segments=[src_window])
            src_idx, tgt_idx = self.translation_model.get_indexes_from_states(states, self.src_splitter,
                                                                              self.tgt_splitter, use_history=False)
            if self.translation_model.append_eos:
                src_idx.append(self.translation_model.dict["src"].eos_index)
            #logger.debug(f" Generating translation with the following indeces. Src: {src_idx} ### Tgt: {tgt_idx}")

            hypos = self.translation_model.get_translation_hypothesis(src_idx, tgt_idx,
                                                                      max_len=500)
            top_hypo = hypos[0]
            num_prefix_tokens = len(tgt_idx)

            merged_toks_to_write = self.get_merged_tokens_to_write_from_hypo(hypo=top_hypo,
                                                                             num_prefix_tokens=num_prefix_tokens)
            logger.debug(f"Translation of src window {src_window} ###: {merged_toks_to_write}")

            tgt_window = self.states.tgt_segments[-1][max(0, len(self.states.tgt_segments[-1]) - len(merged_toks_to_write)):]
            s, i, j = self.longest_common_substring_location(text1=tgt_window, text2=merged_toks_to_write)
            k+=1
            if len(s) >= len(merged_toks_to_write) * self.threshold or k > 5:
                break

        logger.debug(f"Longest substring {s}")
        return len(s), i, j, merged_toks_to_write, len(tgt_window)

    @staticmethod
    def apply_merge_indices(i: int, j: int, new_sequence: List, old_sequence: List, match_len: int):
        if match_len == 0:
            return old_sequence + new_sequence
        else:
            return old_sequence[0:i] + new_sequence[j:]

    @staticmethod
    def longest_common_substring_location(text1: List[str], text2: List[str]) -> Tuple[List[str], int, int]:
        """
        Given two texts, returns the longest common substring, the starting index at text1, and the starting index at
          text2.
        :param text1:
        :param text2:
        :return:
        """
        # Starting point: https://leetcode.com/problems/longest-common-subsequence/solutions/351689/java-python-3-two-dp-codes-of-o-mn-o-min-m-n-spaces-w-picture-and-analysis/
        dp = [[0] * (len(text2)) for _ in range(len(text1))]
        for i, c in enumerate(text1):
            for j, d in enumerate(text2):
                if i == 0 or j == 0:
                    dp[i][j] = 1 if c == d else 0
                else:
                    dp[i][j] = 1 + dp[i-1][j-1] if c == d else 0

        iend = jend = 0
        max_len_substring = 0
        for i, c in enumerate(text1):
            for j, d in enumerate(text2):
                if dp[i][j] > max_len_substring:
                    max_len_substring = dp[i][j]
                    iend = i
                    jend = j

        # the variables contain the index of the end of the substring, need to convert to the start
        i = iend - max_len_substring + 1
        j = jend - max_len_substring + 1
        return text1[i:iend + 1], i, j

