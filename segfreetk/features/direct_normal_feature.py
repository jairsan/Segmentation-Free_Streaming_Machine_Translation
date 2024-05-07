import math
import os
import json
import argparse
from typing import Optional, List, Tuple

from scipy.stats import norm

from segfreetk.common.states import TranslationState, HelperStates
from segfreetk.features.feature import Feature
from segfreetk.features.utils import renorm_probs


class DirectNormalFeature(Feature):
    name: str = "DIRECT_NORMAL"
    epsilon: float = 1e-32

    def __init__(self, mean_std_file: str, renormalize_probs: bool):
        """
        Estimates the chance of splitting directly, p(y|x), where y is the src position and x is the target position.

        This feature assumes that the variable y follows a normal distribution. One distribution is estimated for
        each target position x.

        :param mean_std_file: File containing the mean and standard deviations.
        :param renormalize_probs: Renormalize the probs of the src positions instead of returning the raw probabilities.
        """
        self.distributions: List[Tuple[float, float]] = []
        self.renormalize_probs = renormalize_probs
        with open(mean_std_file, "r") as mf:
            for line in mf:
                fields = line.strip().split()
                assert len(fields) == 2
                self.distributions.append((float(fields[0]), float(fields[1])))

    def my_score(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        # index of the distribution to be used
        di = min(len(states.tgt_segments[-1]), len(self.distributions)) - 1

        raw_probs = [norm.cdf(i + 1, loc=self.distributions[di][0], scale=self.distributions[di][1])
                     - norm.cdf(i, loc=self.distributions[di][0], scale=self.distributions[di][1]) + self.epsilon
                     for i in range(len(states.src_segments[-1]))]
        probs = raw_probs
        if self.renormalize_probs:
            probs = renorm_probs(raw_probs=probs)

        log_probs = [math.log(x) for x in probs]

        return log_probs


def train_direct_normal_feature(src_file_fp: str, tgt_file_fp: str, max_positions: int, artefacts_output_folder: str,
                                json_renorm: bool):
    """
    Trains a direct normal Feature by estimating the distributions from two paired text files
    :param src_file_fp:
    :param tgt_file_fp:
    :param max_positions: Lines containing more words than max_positions are skipped
    :param artefacts_output_folder:
    :param json_renorm: The value of this parameter is stored as "norm" in the json file
    :return:
    """
    lens: List[List[float]] = [[] for x in range(max_positions)]
    distributions: List[Tuple[float, float]] = []
    with open(src_file_fp) as src_file, open(tgt_file_fp) as tgt_file:
        for src_line, tgt_line in zip(src_file, tgt_file):
            src_words = src_line.strip().split()
            tgt_words = tgt_line.strip().split()
            if 0 < len(src_words) <= max_positions and 0 < len(tgt_words) <= max_positions:
                lens[len(tgt_words) - 1].append(len(src_words)-1)

    for i in range(max_positions):
        mean, std = norm.fit(lens[i])
        distributions.append((mean, std))

    os.makedirs(artefacts_output_folder, exist_ok=True)
    with open(artefacts_output_folder + "/mean_and_std.lst", "w") as out_f:
        for mean, std in distributions:
            print(mean, std, file=out_f)
    with open(artefacts_output_folder + "/feature.json", "w") as json_f:
        json_obj = {"MODEL_TYPE": DirectNormalFeature.name,
                    "mean_std_file": os.path.abspath(artefacts_output_folder + "/mean_and_std.lst"),
                    "renormalize_probs": json_renorm}
        json.dump(obj=json_obj, fp=json_f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--src_file", required=True, type=str)
    parser.add_argument("--tgt_file", required=True, type=str)
    parser.add_argument("--artefacts_output_folder", required=True, type=str)
    parser.add_argument("--max_positions", type=int, default=100)
    parser.add_argument("--json_store_renorm_probs", action="store_true")

    args = parser.parse_args()

    train_direct_normal_feature(src_file_fp=args.src_file, tgt_file_fp=args.tgt_file,
                               artefacts_output_folder=args.artefacts_output_folder,
                               max_positions=args.max_positions, json_renorm=args.json_store_renorm_probs)
