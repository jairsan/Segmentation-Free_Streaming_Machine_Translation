import argparse
import os
from typing import List, Tuple, Union

import torch
from torch import Tensor
import torch.nn as nn

from segfreetk.features.normal_regression_feature import NormalRegressionFeature, SimpleLinearRegressionFeature
from segfreetk.features.utils import train_regression_model


def weights_init_uniform(m):
    classname = m.__class__.__name__
    # for every Linear layer in a model..
    if classname.find('Linear') != -1:
        # apply a uniform distribution to the weights and a bias=0
        m.weight.data.uniform_(0.1, 1.0)
        m.bias.data.fill_(0)


class LinearRegressionModel(nn.Module):
    def __init__(self, mean_order: int, std_order: int):
        super().__init__()
        self.mean_order = mean_order
        self.std_order = std_order
        self.mean_layer = nn.Linear(in_features=self.mean_order, out_features=1)
        self.std_layer = nn.Linear(in_features=self.std_order, out_features=1)

        self.mean_layer.apply(weights_init_uniform)
        self.std_layer.apply(weights_init_uniform)

    def forward(self, X: List[str], Y: List[str], device: str) -> Tuple[Tensor, Tensor]:
        y_lens = [len(y.strip().split()) for y in Y]

        mean_features = [SimpleLinearRegressionFeature.get_input_feas(value=y_len, order=self.mean_order)[1:] for y_len in y_lens]
        std_features = [SimpleLinearRegressionFeature.get_input_feas(value=y_len, order=self.std_order)[1:] for y_len in y_lens]

        mean_features_t = torch.tensor(mean_features, dtype=torch.float32).to(device)
        std_features_t = torch.tensor(std_features, dtype=torch.float32).to(device)

        assert mean_features_t.size()[1] == self.mean_order
        assert std_features_t.size()[1] == self.std_order

        mean_hat = self.mean_layer(mean_features_t)
        std_hat = self.std_layer(std_features_t)

        return mean_hat, nn.functional.softplus(std_hat, threshold=20)


class NormalRegressionLinearModelsFeature(NormalRegressionFeature):
    name = "LINEAR_REGRESSION_NORMAL"

    def __init__(self, mean_order: int, std_order: int, load_model_from_path: str = None):
        self.model = LinearRegressionModel(mean_order=mean_order, std_order=std_order)
        if load_model_from_path:
            self.model.load_state_dict(torch.load(load_model_from_path))
            print("Loaded LINEAR_REGRESSION_NORMAL model")
            print(f"Mean weights {self.model.mean_layer.weight}")
            print(f"Mean bias {self.model.mean_layer.bias}")
            print(f"Std weights {self.model.std_layer.weight}")
            print(f"Std bias {self.model.std_layer.bias}")

    def get_mean_and_std(self, src_words: List[str], tgt_words: List[str]) -> Tuple[Union[float, Tensor], Union[float, Tensor]]:

        means_hat, stds_hat = self.model.forward(X=[" ".join(src_words)], Y=[" ".join(tgt_words)], device="cpu")

        return means_hat[0], stds_hat[0]


if __name__ == "__main__":
    if __name__ == "__main__":
        parser = argparse.ArgumentParser()

        parser.add_argument("--src_file", required=True, type=str)
        parser.add_argument("--tgt_file", required=True, type=str)
        parser.add_argument("--artefacts_output_folder", required=True, type=str)
        parser.add_argument("--mean_order", default=1, type=int)
        parser.add_argument("--std_order", default=1, type=int)
        parser.add_argument("--epochs", default=800, type=int)
        parser.add_argument("--batch_size", default=32, type=int)
        parser.add_argument("--learning_rate", default=1e-4, type=float)
        parser.add_argument("--gradient_max_norm", default=None, type=float)
        parser.add_argument("--max_positions", default=100, type=int)
        parser.add_argument("--filter_outside_iqr", default=None, type=float)


        args = parser.parse_args()

        model = LinearRegressionModel(mean_order=args.mean_order, std_order=args.std_order)

        os.makedirs(args.artefacts_output_folder, exist_ok=True)

        feature_json_to_store = {
            "MODEL_TYPE": NormalRegressionLinearModelsFeature.name,
            "mean_order": args.mean_order,
            "std_order": args.std_order,
            "load_model_from_path": os.path.join(args.artefacts_output_folder, "model.pt")
        }

        train_regression_model(regression_model=model, epochs=args.epochs, learning_rate=args.learning_rate,
                               src_file=args.src_file, tgt_file=args.tgt_file, artefacts_output_folder=args.artefacts_output_folder,
                               batch_size=args.batch_size, gradient_max_norm=args.gradient_max_norm, feature_json_to_store=feature_json_to_store,
                               max_positions=args.max_positions, filter_outside_iqr=args.filter_outside_iqr)
