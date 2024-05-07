import math
import argparse
import os
import json
from typing import List, Optional

from segfreetk.common.states import TranslationState, HelperStates
from segfreetk.features.feature import Feature
from segfreetk.features.utils import smooth_probabilities


class FixedRatioFeature(Feature):
    name: str = "FIXED_RATIO"

    def __init__(self, tgt_src_ratio: float = 1.0, smoothing_alpha: float = 1e-2):
        """
        Naive feature that deterministically aligns words based only on a pre-computed length ratio.

        The position predicted by the ratio is assigned probability 1.0, the rest 0.0. This is then smoothed to
        avoid problems.

        This is equivalent to having a sliding window that moves a fixed number of steps every time a [SEP] is
        emitted in the target side (Also known as Naive method).

        :param tgt_src_ratio: Ratio of words between target and source sentences -> len(tgt_st) / len(src_st)
        :param smoothing_alpha: Value to add on a per-prob basis during smoothing
        """
        super(FixedRatioFeature, self).__init__()

        self.tgt_src_ratio = tgt_src_ratio
        self.smoothing_alpha = smoothing_alpha

    def my_score(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        # TODO add test for this method
        num_src_words = len(states.src_segments[-1])
        num_tgt_words = len(states.tgt_segments[-1])

        src_index = int(num_tgt_words / self.tgt_src_ratio - 1)

        if src_index < 0:
            src_index = 0
        elif src_index > num_src_words - 1:
            src_index = num_src_words - 1

        ans = [0.0] * num_src_words
        ans[src_index] = 1.0

        smoothed_ans = smooth_probabilities(raw_probs=ans, smoothing_factor=self.smoothing_alpha)

        ans = [math.log(x) for x in smoothed_ans]

        return ans


def train_fixed_ratio_feature(src_file_fp: str, tgt_file_fp: str, artefacts_output_folder: str):
    ratios: List[float] = []
    with open(src_file_fp) as src_file, open(tgt_file_fp) as tgt_file:
        for src_line, tgt_line in zip(src_file, tgt_file):
            try:
                this_ratio = len(tgt_line.strip().split()) / len(src_line.strip().split())
                ratios.append(this_ratio)
            except ZeroDivisionError:
                continue

    sorted_ratio = sorted(ratios)

    # We return the median
    if len(sorted_ratio) % 2 == 0:
        median = 0.5 * sorted_ratio[int(len(sorted_ratio)/2) - 1] + 0.5 * sorted_ratio[int(len(sorted_ratio)/2)]
    else:
        median = sorted_ratio[math.floor(len(sorted_ratio) / 2)]

    os.makedirs(name=artefacts_output_folder, exist_ok=True)

    with open(artefacts_output_folder + "/feature.json", "w") as json_fp:
        json_obj = {"MODEL_TYPE": FixedRatioFeature.name,
                    "tgt_src_ratio": median}
        json.dump(obj=json_obj, fp=json_fp)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--src_file", required=True, type=str)
    parser.add_argument("--tgt_file", required=True, type=str)
    parser.add_argument("--artefacts_output_folder", required=True, type=str)

    args = parser.parse_args()

    train_fixed_ratio_feature(src_file_fp=args.src_file, tgt_file_fp=args.tgt_file,
                              artefacts_output_folder=args.artefacts_output_folder)
