import argparse
from typing import Optional, List, Union, Tuple

import os
import json
import torch
from torch import Tensor
import math
import numpy as np
from sklearn.linear_model import LinearRegression
from segfreetk.common.states import TranslationState, HelperStates
from segfreetk.features.feature import Feature


class NormalRegressionFeature(Feature):
    """
    Feature that models source sentence length |x| \sim N(f_{\mu}(x,y;\theta),f_{\sigma}(x,y;\theta))

    This is an abstract class, all actual features need to implement the get_mean_and_std method.
    """
    def my_score(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        mean, std = self.get_mean_and_std(src_words=states.src_segments[-1], tgt_words=states.tgt_segments[-1])
        scores = [self.mean_std_to_logprob(mean=mean, std=std, value=j+1) for j in range(len(states.src_segments[-1]))]
        return [score.tolist()[0] for score in scores]

    @staticmethod
    def mean_std_to_logprob(mean: Union[float, Tensor], std: Union[float, Tensor], value: Union[int, Tensor]) -> Tensor:
        """

        :param mean:
        :param std:
        :param value:
        :return:
        """
        if type(mean) != torch.Tensor:
            mean = torch.tensor([mean], dtype=torch.float32)
        if type(std) != torch.Tensor:
            std = torch.tensor([std], dtype=torch.float32)
        if type(value) != torch.Tensor:
            value = torch.tensor([value], dtype=torch.float32)

        var = std ** 2

        # Assume that the others tensors are on the same GPU/CPU
        device = mean.get_device()

        if device != -1:
            return - torch.log(std) - torch.log(torch.sqrt(2 * torch.tensor([math.pi]).to("cuda:"+str(device)))) - (( value.to("cuda:"+str(device)) - mean) ** 2 / ( 2 * var ))
        else:
            return - torch.log(std) - torch.log(torch.sqrt(2 * torch.tensor([math.pi]))) - (( value - mean) ** 2 / ( 2 * var ))

    def get_mean_and_std(self, src_words: List[str], tgt_words: List[str]) -> Tuple[Union[float, Tensor], Union[float, Tensor]]:
        raise NotImplementedError


class SimpleLinearRegressionFeature(NormalRegressionFeature):
    name = "SIMPLE_LINEAR_REGRESSION"

    def __init__(self, coefficients: List[float], std: float):
        """
        Simple linear regression model that only predicts the mean, the std is fixed.

        |x| \sim N(f_{\mu}(x,y;\theta),f_{\sigma}(x,y;\theta)), with f_{\mu}(x,y;\theta)=\coefficients_0 + |y| * \coefficients_1
         and f_{\sigma}(x,y;\theta)=std
        :param coefficients:
        :param std:
        """
        self.coef = np.array(coefficients)
        self.std = std

    @staticmethod
    def get_input_feas(value: int, order: int) -> np.ndarray:
        """
        Computes the input features for a linear model. This is called in order to support linear,
        quadratic and higher order models.

        :param value: Length of the sentence to be transformed into features
        :param order: Order of the model. 1=linear, 2=quadratic.

        :return np.ndarray with order + 1 values. Term 0 is the independent/bias term, and is always 1.
        """
        return np.array([value ** o for o in range(order+1)])

    def get_mean_and_std(self, src_words: List[str], tgt_words: List[str]):
        input_feas = self.get_input_feas(order=self.coef.shape[0]-1, value=len(tgt_words))
        mean = np.dot(input_feas, self.coef)
        std = self.std

        return mean, std


def train_simple_linear_regression(src_file_fp: str, tgt_file_fp: str, artefacts_output_folder: str, order: int,
                                   fit_intecept: bool,
                                   std: Optional[float]):
    x_l: List[int] = []
    Y_l: List[np.ndarray] = []

    with open(src_file_fp) as src_file, open(tgt_file_fp) as tgt_file:
        for src_line, tgt_line in zip(src_file, tgt_file):
            src_words = src_line.strip().split()
            tgt_words = tgt_line.strip().split()
            x = len(src_words)
            y = len(tgt_words)
            x_l.append(x)
            # Remove the term corresponding to the bias, this is controlled by fit_intercept
            Y_l.append(SimpleLinearRegressionFeature.get_input_feas(value=y, order=order)[1:])

    x = np.array(x_l)
    Y = np.array(Y_l)

    regressor = LinearRegression(fit_intercept=fit_intecept)
    regressor.fit(X=Y, y=x)

    coefs = [0.0] * (order + 1)

    coefs[0] = regressor.intercept_
    coefs[1:] = regressor.coef_.tolist()

    # If we have not provided a value for std, it is computed by MLE
    if not std:
        prediction = regressor.predict(X=Y)
        var = np.mean((x - prediction) ** 2)
        std = math.sqrt(var)

    os.makedirs(artefacts_output_folder, exist_ok=True)
    with open(artefacts_output_folder + "/feature.json", "w") as json_f:
        json_obj = {"MODEL_TYPE": SimpleLinearRegressionFeature.name,
                    "coefficients": coefs,
                    "std": std}
        json.dump(obj=json_obj, fp=json_f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--src_file", required=True, type=str)
    parser.add_argument("--tgt_file", required=True, type=str)
    parser.add_argument("--artefacts_output_folder", required=True, type=str)
    parser.add_argument("--order", default=1, type=int)
    parser.add_argument("--std", default=None, type=float, help="If set, use this fixed value for std instead"
                                                                "of computing it by MLE")
    parser.add_argument("--fit_intercept", action="store_true")

    args = parser.parse_args()

    train_simple_linear_regression(src_file_fp=args.src_file, tgt_file_fp=args.tgt_file,
                               artefacts_output_folder=args.artefacts_output_folder,
                               fit_intecept=args.fit_intercept, order=args.order,
                                   std=args.std)
