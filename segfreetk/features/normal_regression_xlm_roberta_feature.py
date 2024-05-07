import argparse
import os
from typing import List, Tuple, Union, Optional

import torch.nn
from segfreetk.features.utils import train_regression_model
from torch import Tensor
from transformers import XLMRobertaConfig, AutoTokenizer, XLMRobertaForSequenceClassification

from segfreetk.features.normal_regression_feature import NormalRegressionFeature


class MyXLMRobertaModel(torch.nn.Module):
    def __init__(self, model_path: str):
        super().__init__()
        self.rob_model = XLMRobertaForSequenceClassification.from_pretrained(model_path, problem_type="regression", num_labels=2)
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)

    def forward(self, X: List[str], Y: List[str], device: str):
        batch = self.tokenizer(text=X, text_pair=Y, add_special_tokens=True, return_tensors="pt", padding=True)
        joint_model_output = self.rob_model(batch['input_ids'].to(device),
                                      attention_mask=batch['attention_mask'].to(device)).logits

        mean_hat = joint_model_output[:, 0].reshape(-1,1)
        std_hat = joint_model_output[:, 1].reshape(-1,1)

        return mean_hat, torch.nn.functional.softplus(std_hat, threshold=20)

class XLMRobertaRegressionFeature(NormalRegressionFeature):
    name = "REGRESSION_XLM_ROBERTA"

    def __init__(self, model_path, device="cuda"):
        self.regression_model = MyXLMRobertaModel(model_path)

        self.regression_model.rob_model.to(device)


    def get_mean_and_std(self, src_words: List[str], tgt_words: List[str]) -> Tuple[Union[float, Tensor], Union[float, Tensor]]:
        means, stds = self.regression_model(X=[" ".join(src_words)], Y=[" ".join(tgt_words)], device="cuda")
        return means[0], stds[0]


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--src_file", required=True, type=str)
    parser.add_argument("--tgt_file", required=True, type=str)
    parser.add_argument("--artefacts_output_folder", required=True, type=str)
    parser.add_argument("--model_name", required=True, type=str)
    parser.add_argument("--epochs", default=10, type=int)
    parser.add_argument("--batch_size", default=16, type=int)
    parser.add_argument("--learning_rate", default=1e-5, type=float)
    parser.add_argument("--gradient_max_norm", default=None, type=float)
    parser.add_argument("--max_positions", default=100, type=int)
    parser.add_argument("--cpu", action="store_true")
    parser.add_argument("--filter_outside_iqr", default=None, type=float)

    args = parser.parse_args()

    model = MyXLMRobertaModel(model_path=args.model_name)

    os.makedirs(args.artefacts_output_folder, exist_ok=True)

    feature_json_to_store = {
        "MODEL_TYPE": XLMRobertaRegressionFeature.name,
        "model_path": args.artefacts_output_folder,
    }

    if args.cpu:
        device = "cpu"
    else:
        device = "cuda"

    train_regression_model(regression_model=model, epochs=args.epochs, learning_rate=args.learning_rate,
                           src_file=args.src_file, tgt_file=args.tgt_file, artefacts_output_folder=args.artefacts_output_folder,
                           batch_size=args.batch_size, gradient_max_norm=args.gradient_max_norm, feature_json_to_store=feature_json_to_store,
                           max_positions=args.max_positions, filter_outside_iqr=args.filter_outside_iqr, model_type="hf",
                           eval_portion=0.05, log_every=100, device=device)