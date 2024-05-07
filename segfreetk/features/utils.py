import json
import math
import os
import random
from typing import List, Tuple, Dict, Optional, Literal

import numpy as np
import torch

from segmenter.models.simple_rnn_text_model import SimpleRNNTextModel
from torch import autograd

from segfreetk.features.normal_regression_feature import NormalRegressionFeature
from torch.utils.data import Dataset


def smooth_probabilities(raw_probs: List[float], smoothing_factor: 1e-3) -> List[float]:
    """
    Applies Laplace smoothing to a list of raw probabilities.

    A smoothing factor is added to each probability, and then they are re-normalized.
    """
    probs_array = np.array(raw_probs)
    probs_array += smoothing_factor
    probs_array /= np.sum(probs_array)

    # noinspection PyTypeChecker
    return probs_array.tolist()


def renorm_probs(raw_probs: List[float]) -> List[float]:
    """
    Renormalizes probabilities so that they sum up to 1.0
    """
    denominator = sum(raw_probs)
    probs = [x / denominator for x in raw_probs]
    return probs

# TODO: no usages, check if this function can be removed
def load_model_ds(model_arch: str, model_path: str):
    """
    Load a direct segmentation model, to be used later in a model or a feature
    :param model_arch: String that identifies the segmenter architecture. Choices: "rnn"
    :param model_path: Path to the checkpoint (.pt) holding the model
    """
    checkpoint = torch.load(model_path)

    saved_model_args = checkpoint['args']

    vocabulary = checkpoint['vocabulary']

    assert model_arch in ["rnn"]

    if model_arch == "rnn":
        model = SimpleRNNTextModel(saved_model_args, vocabulary)
    else:
        raise Exception

    model.load_state_dict(checkpoint['model_state_dict'])
    model.to(torch.device('cuda'))
    return model, vocabulary, saved_model_args


class RegressionDataset(Dataset):
    def __init__(self, src_sentences: List[str], tgt_sentences: List[str]):
        assert len(src_sentences) == len(tgt_sentences)
        self.src = src_sentences
        self.tgt = tgt_sentences

    def __len__(self):
        return len(self.src)

    def __getitem__(self, idx: int) -> Tuple[str, str]:
        return self.src[idx], self.tgt[idx]


def custom_collate_fn(batch: List[Tuple[str, str]]) -> Tuple[List[str], List[str]]:
    return [example[0] for example in batch], [example[1] for example in batch]


def train_regression_model(regression_model: torch.nn.Module, src_file: str, tgt_file: str, batch_size: int, learning_rate: float,
                           epochs: int, artefacts_output_folder: str,
                           feature_json_to_store: Dict,
                           max_positions: int,
                           gradient_max_norm: Optional[float] = None,
                           eval_portion: float = 0.2, device="cpu", tol=1e-7, filter_outside_iqr: float = None,
                           model_type: Literal["torch", "hf"] = "torch", log_every: int = -1):

    src_sentences: List[str] = []
    tgt_sentences: List[str] = []

    #tgt_len
    src_lens = []
    for i in range(max_positions):
        src_lens.append([])

    iqr_min = np.zeros(shape=max_positions)
    iqr_max = np.zeros(shape=max_positions)


    if filter_outside_iqr:
        # TODO this could be collapsed into a single loop
        with open(src_file) as in_f, open(tgt_file) as out_f:
            for lines, linet in zip(in_f, out_f):
                src_len = len(lines.strip().split())
                tgt_len = len(linet.strip().split())
                if src_len <= max_positions and tgt_len <= max_positions:
                    src_lens[tgt_len-1].append(src_len)

        for i in range(max_positions):
            arr = np.array(src_lens[i])
            q25 = np.percentile(arr, 25)
            q75 = np.percentile(arr, 75)
            iqr_exclude = (q75 - q25) * filter_outside_iqr
            iqr_min[i] = q25 - iqr_exclude
            iqr_max[i] = q75 + iqr_exclude
            # print(f"Tgt len {i}, q25 {q25}, q75 {q75}, iqr_exclude {iqr_exclude}, iqr_min {iqr_min[i]}, iqr_max {iqr_max[i]}")



    with open(src_file) as in_f, open(tgt_file) as out_f:
        for lines, linet in zip(in_f, out_f):
            src_len = len(lines.strip().split())
            tgt_len = len(linet.strip().split())
            if src_len <= max_positions and tgt_len <= max_positions:
                if (filter_outside_iqr and src_len < iqr_min[tgt_len-1]) or (filter_outside_iqr and src_len > iqr_max[tgt_len-1]):
                    # print(f"Excluded outlier, src len {src_len} tgt len{tgt_len}")
                    continue
                src_sentences.append(lines.strip())
                tgt_sentences.append(linet.strip())

    assert len(src_sentences) == len(tgt_sentences)

    joint_data = list(zip(src_sentences, tgt_sentences))
    random.shuffle(joint_data)
    src_sentences = [j[0] for j in joint_data]
    tgt_sentences = [j[1] for j in joint_data]

    train_samples = int(len(src_sentences) * (1 - eval_portion))

    train_dataset = RegressionDataset(src_sentences=src_sentences[:train_samples], tgt_sentences=tgt_sentences[:train_samples])
    dev_dataset = RegressionDataset(src_sentences=src_sentences[train_samples:], tgt_sentences=tgt_sentences[train_samples:])
    train_dataloader = torch.utils.data.DataLoader(dataset=train_dataset, batch_size=batch_size, shuffle=True,
                                                   collate_fn=custom_collate_fn, drop_last=True)

    dev_dataloader = torch.utils.data.DataLoader(dataset=train_dataset, batch_size=batch_size, shuffle=False,
                                                   collate_fn=custom_collate_fn, drop_last=False)

    optimizer = torch.optim.Adam(params=regression_model.parameters(), lr=learning_rate)

    best_epoch_cost = math.inf

    regression_model.to(device)

    for i in range(epochs):
        optimizer.zero_grad()
        regression_model.train()

        for src_sents, tgt_sents in train_dataloader:
            means_hat, stds_hat = regression_model(X=src_sents, Y=tgt_sents, device=device)
            targets = torch.tensor([[len(x.strip().split())] for x in src_sents], dtype=torch.float32).to(device)
            logprobs = NormalRegressionFeature.mean_std_to_logprob(mean=means_hat, std=stds_hat, value=targets)
            cost = torch.mean(-logprobs)

            cost.backward()

            # TODO fix me, should use enumarate over dataloader
            #if log_every > 0 and i % log_every == 0:
            #    print(f"Epoch {i}, cost {cost.detach().cpu().numpy()}")

            if gradient_max_norm:
                torch.nn.utils.clip_grad_norm_(parameters=regression_model.parameters(), max_norm=gradient_max_norm)

            optimizer.step()
            optimizer.zero_grad()

        regression_model.eval()
        with torch.no_grad():
            epoch_cost = 0
            for src_sents, tgt_sents in dev_dataloader:
                means_hat, stds_hat = regression_model(X=src_sents, Y=tgt_sents, device=device)
                targets = torch.tensor([[len(x)] for x in src_sents], dtype=torch.float32).to(device)
                logprobs = NormalRegressionFeature.mean_std_to_logprob(mean=means_hat, std=stds_hat, value=targets)

                raw_cost = torch.sum(-logprobs)
                per_sample_cost = raw_cost / len(src_sentences)
                epoch_cost += per_sample_cost

            epoch_cost /= len(dev_dataset)

            print(
                f"End of epoch {i}, cost {epoch_cost}")

            if (epoch_cost + tol) < best_epoch_cost:
                best_epoch_cost = epoch_cost
            else:
                print("Early stopping")
                break


    with open(artefacts_output_folder + "/feature.json", "w") as json_f:
        json.dump(obj=feature_json_to_store, fp=json_f)

    if model_type == "torch":
        print("Saving model...")
        print(f"Mean weights {regression_model.mean_layer.weight}")
        print(f"Mean bias {regression_model.mean_layer.bias}")
        print(f"Std weights {regression_model.std_layer.weight}")
        print(f"Std bias {regression_model.std_layer.bias}")

        torch.save(regression_model.state_dict(), os.path.join(artefacts_output_folder, "model.pt"))

    if model_type == "hf":
        regression_model.rob_model.save_pretrained(artefacts_output_folder)
        regression_model.tokenizer.save_pretrained(artefacts_output_folder)
