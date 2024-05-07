import math
from typing import List, Optional
import argparse
import os
import json

import numpy as np

from segfreetk.common.states import TranslationState, HelperStates
from segfreetk.features.feature import Feature
from segfreetk.features.utils import smooth_probabilities


class DirectCountFeature(Feature):
    name: str = "DIRECT_COUNT"

    def __init__(self, count_matrix_path: str, smoothing_alpha: float = 1e-2):
        """
        Estimates the chance of splitting directly, p(y|x), where y is the src position and x is the target position.

        This is done by collecting statistics of p(y|x) for each x from a pair of text files. The probabilities are
        smoothed before being returned.

        :param count_matrix_path: Path to the array containing the raw counts.
        :param smoothing_alpha: Smoothing constant added on a per-prob basis
        """
        # Array of shape (n_target_position, n_src_positions)
        # Thus, prob_matrix[n-1] directly gives us the raw counts for each source position, for a sentence of n src toks
        self.count_matrix: np.ndarray = np.load(file=count_matrix_path)
        self.smoothing_alpha = smoothing_alpha

    def my_score(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        num_src_positions = len(states.src_segments[-1])
        num_tgt_positions = min(len(states.tgt_segments[-1]), self.count_matrix.shape[0])
        raw_counts = [0] * num_src_positions

        stored_counts: List[int] = self.count_matrix[num_tgt_positions - 1].tolist()
        max_stored_counts = len(stored_counts)
        raw_counts[:min(len(raw_counts), max_stored_counts)] = stored_counts[:min(len(raw_counts), max_stored_counts)]
        denominator = sum(raw_counts)
        raw_probs = [x/denominator for x in raw_counts]
        smoothed_probs = smooth_probabilities(raw_probs=raw_probs, smoothing_factor=self.smoothing_alpha)
        log_probs = [math.log(x) for x in smoothed_probs]
        return log_probs


def train_direct_count_feature(src_file_fp: str, tgt_file_fp: str, max_positions: int, artefacts_output_folder: str):
    """
    Trains a direct count Feature by computing the counts from two paired text files

    :param src_file_fp:
    :param tgt_file_fp:
    :param max_positions: Lines containing more words than max_positions are skipped
    :param artefacts_output_folder:
    :return:
    """
    counts = np.zeros((max_positions, max_positions))
    with open(src_file_fp) as src_file, open(tgt_file_fp) as tgt_file:
        for src_line, tgt_line in zip(src_file, tgt_file):
            src_words = src_line.strip().split()
            tgt_words = tgt_line.strip().split()
            if 0 < len(src_words) <= max_positions and 0 < len(tgt_words) <= max_positions:
                counts[len(tgt_words) - 1][len(src_words)-1] += 1
    os.makedirs(artefacts_output_folder, exist_ok=True)
    np.save(file=artefacts_output_folder + "/counts.npy", arr=counts)
    with open(artefacts_output_folder + "/feature.json", "w") as json_f:
        json_obj = {"MODEL_TYPE": DirectCountFeature.name,
                    "count_matrix_path": os.path.abspath(artefacts_output_folder + "/counts.npy")}
        json.dump(obj=json_obj, fp=json_f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--src_file", required=True, type=str)
    parser.add_argument("--tgt_file", required=True, type=str)
    parser.add_argument("--artefacts_output_folder", required=True, type=str)
    parser.add_argument("--max_positions", type=int, default=100)

    args = parser.parse_args()

    train_direct_count_feature(src_file_fp=args.src_file, tgt_file_fp=args.tgt_file,
                               artefacts_output_folder=args.artefacts_output_folder,
                               max_positions=args.max_positions)
