import numpy as np
import math
from typing import List, Tuple, Optional, Union
import argparse
import random
import copy
import json
import torch
from torch.utils.data import Dataset
from torch.optim import SGD, Adam
from pathlib import Path

from segfreetk.features.feature import Feature
from segfreetk.features.load_utils import load_from_json
from segfreetk.common.states import TranslationState, HelperStates

SGD_str = "sgd"
PERCEPTRON_str = "perceptron"

optimizers_dict = {"adam": Adam, "sgd": SGD}


def generate_data_from_files(src_file: Union[str, Path], tgt_file: Union[str, Path],
                             include_next_sentence_prob: float = 1.0, src_window_size: int = 60,
                             tgt_window_size: int = 60, do_shuffle: bool = True) -> List[Tuple[TranslationState, int, None]]:

    random.seed(42)
    with open(src_file) as src_file_op, open(tgt_file) as tgt_file_op:
        src_sentences: List[List[str]] = []
        tgt_sentences: List[List[str]] = []

        for src_line, tgt_line in zip(src_file_op, tgt_file_op):
            if len(src_line.strip().split()) > 0 and len(tgt_line.strip().split()) > 0:
                src_sentences.append(src_line.strip().split())
                tgt_sentences.append(tgt_line.strip().split())

    output_states: List[TranslationState] = []
    output_labels: List[int] = []

    translation_state = TranslationState()

    translation_state.src_segments.pop(0)
    translation_state.tgt_segments.pop(0)

    for i in range(len(src_sentences)):
        if len(src_sentences[i]) > 1:
            translation_state.src_segments.append(src_sentences[i])
            translation_state.tgt_segments.append(tgt_sentences[i])
            translation_state.filter_segments_to_max_len(src_max_len=src_window_size, tgt_max_len=tgt_window_size)

            tmp_output_state = copy.deepcopy(translation_state)
            tmp_label = len(translation_state.src_segments[-1]) - 1

            # Randomly decide if we want to add the next sentence to make it harder
            add_next_sentence = random.random() < include_next_sentence_prob
            if add_next_sentence and i < len(src_sentences) - 1:
                # Add a random length prefix of the next sentence
                next_sentence_proportion = random.random()
                next_sentence_prefix = src_sentences[i+1][:int(len(src_sentences[i+1]) * next_sentence_proportion)]
                tmp_output_state.src_segments[-1].extend(next_sentence_prefix)

            output_states.append(tmp_output_state)
            output_labels.append(tmp_label)
        else:
            continue
    data = [(state, label, None) for state, label in zip(output_states, output_labels)]
    if do_shuffle:
        random.shuffle(data)
    return data


def precompute_h_store(data: List[Tuple[TranslationState, int, Optional[HelperStates]]], features: List[Feature]) \
        -> List[np.ndarray]:
    """

    :param data:
    :param features:
    :return: A list of ndarrays. Each element is of shape (n_features, n_words)
    """

    precomputed_h_store: List[np.ndarray] = []

    n_features = len(features)

    # initialize h first
    for n in range(len(data)):
        translation_states, _, _ = data[n]
        num_positions_to_consider = len(translation_states.src_segments[-1])
        assert num_positions_to_consider > 1
        scores = np.zeros((n_features, num_positions_to_consider))
        precomputed_h_store.append(scores)

    for i, feature in enumerate(features):
        for n in range(len(data)):
            translation_states, _, helper_states = data[n]
            my_scores = feature.score(states=translation_states, helper_states=helper_states)
            my_scores_array = np.array(my_scores)
            precomputed_h_store[n][i, :] = my_scores_array

    assert len(data) == len(precomputed_h_store)
    return precomputed_h_store


def perceptron(data: List[Tuple[TranslationState, int, Optional[HelperStates]]], max_iterations: int,
               a: float, b: float, precomputed_h_store: List[np.array]) -> Tuple[np.ndarray, int, int]:
    """
    Implements the perceptron algorithm for an specific configuration
    """
    n_feas = precomputed_h_store_o[0].shape[0]

    weights = np.zeros(n_feas)

    assert max_iterations > 0

    number_of_errors = 0
    for k in range(max_iterations):
        number_of_errors = 0
        for n in range(len(data)):
            _, cstar, _ = data[n]

            # (n_feas, n_pos)
            n_scores = precomputed_h_store[n]

            # (n_pos, n_feas) * (n_feas, 1) = (n_pos, 1)
            scores = np.dot(a=n_scores.transpose(), b=weights)

            max_score = - math.inf
            max_c = -1
            for c in range(scores.shape[0]):
                if c == cstar:
                    continue
                else:
                    c_score = scores[c]
                    if c_score > max_score:
                        max_score = c_score
                        max_c = c

            if max_score + b > scores[cstar]:
                weights = weights + a * n_scores[:, cstar] - a * n_scores[:, max_c]
                number_of_errors += 1

        if number_of_errors == 0:
            return weights, number_of_errors, k + 1

    return weights, number_of_errors, max_iterations


def eval_weights(eval_data: List[Tuple[TranslationState, int, Optional[HelperStates]]],
                 eval_h_store: List[np.ndarray], weights: np.ndarray) -> Tuple[int, float]:

    num_errors: int = 0
    mse: float = 0.0
    for n in range(len(eval_h_store)):
        n_scores = eval_h_store[n]
        y = eval_data[n][1]

        # (n_pos, n_feas) * (n_feas, 1) = (n_pos, 1)
        scores = np.dot(a=n_scores.transpose(), b=weights)

        yhat = np.argmax(scores)
        if yhat != y:
            num_errors += 1
            mse += math.pow(yhat - y, 2)

    return num_errors, mse


def optimize_weights_perceptron(data: List[Tuple[TranslationState, int, Optional[HelperStates]]],
                                features: List[Feature], max_iterations: int = 200, a_values: List[float] = 1.0,
                                b_values: List[float] = 0.1, precomputed_h_store: List[np.ndarray] = None,
                                eval_portion: float = 0.2) \
        -> Tuple[np.ndarray, int, int]:
    """
    Optimzes the feature weights for a give set of sentences (represented by states) by using the Perceptron loss.
    Multiple valus of a and b will be tested, and the best one selected.

    :param data: List of (translation_state, split_position, helper_states). split_position is the label, means that we
     split after index split_position (0-indexed) of the last src_segment
    :param features:
    :param max_iterations: The algorithm runs for this max_number of iteration or until convergence
    :param a_values: Values to try for Perceptron learning rate
    :param b_values: Values to try for Perceptron margin
    :param precomputed_h_store:
    :param eval_portion: Uses this portion of the train data for evaluating the performance of the weights
    :return: (weights, E, n_iterations)
        - weights: Final weights
        - E: # errors in eval portion
        - n_iterations: # iterations carried out by the optimization process
    """

    if precomputed_h_store is None:
        precomputed_h_store = precompute_h_store(data=data, features=features)

    train_samples = int(len(data) * (1 - eval_portion))

    best_it = None
    for a in a_values:
        for b in b_values:
            it_weights, e, max_iter = perceptron(data=data[:train_samples], a=a, b=b,
                                                 precomputed_h_store=precomputed_h_store[:train_samples],
                                                 max_iterations=max_iterations)
            eval_e, eval_mse = eval_weights(eval_data=data[train_samples:],
                                            eval_h_store=precomputed_h_store[train_samples:], weights=it_weights)
            if best_it is None:
                best_it = (it_weights, eval_e, eval_mse, max_iter, a, b)
            elif best_it[2] >= eval_mse:
                best_it = (it_weights, eval_e, eval_mse, max_iter, a, b)
            print(f"Tested perceptron config, train errors {e}/{train_samples}, eval errors {eval_e}/"
                  f"{len(data) - train_samples: < 4}, eval MeanSquaredError {eval_mse} a={a} b={b}")

    return best_it[0], best_it[1], best_it[3]


class FeatureModel(torch.nn.Module):
    def __init__(self, num_features):
        super().__init__()
        self.feature_weights_layer = torch.nn.Linear(bias=False, in_features=num_features, out_features=1)

    def forward(self, x):
        return self.feature_weights_layer(x)


class FeatureDataset(Dataset):
    def __init__(self, data: List[Tuple[TranslationState, int, None]], h_store: List[np.ndarray]):
        # Each element of the list is of shape (n_features x n_words)
        self.h_store = h_store

        # Each element is (TranslationState, label, None)
        self.data = data

        assert len(self.h_store) == len(self.data)

    def __len__(self):
        return len(self.h_store)

    def __getitem__(self, idx) -> Tuple[torch.Tensor, torch.Tensor]:
        return torch.tensor(self.h_store[idx]).float(), torch.tensor(self.data[idx][1]).long()


def model_caller_wrapper(model: FeatureModel, x: torch.Tensor) -> torch.Tensor:
    # n_feas, n_words) -> (n_words, n_feas)
    # Words is now acting as the Batch dimension
    x = x.transpose(0, 1)

    # We get back (n_words, 1)
    scores = model(x)

    # Traspose back to get the actual batch size (1)
    # (n_words, 1) -> (1, n_words)
    scores = scores.transpose(0, 1)

    return scores


def optimize_weights_sgd(data: List[Tuple[TranslationState, int, Optional[HelperStates]]],
                                features: List[Feature], batch_size: int, learning_rate: int,
                         epochs: int, optimizer_name: str,
                         precomputed_h_store: List[np.ndarray] = None,
                                eval_portion: float = 0.2):
    """
    Optimzes the feature weights for a give set of sentences (represented by states) by using SGD.

    :param data: List of (translation_state, split_position, helper_states). split_position is the label, means that we
     split after index split_position (0-indexed) of the last src_segment
    :param features:
    :param batch_size:
    :param learning_rate:
    :param epochs
    :param precomputed_h_store:
    :param eval_portion: Uses this portion of the train data for evaluating the performance of the weights
    """
    if precomputed_h_store is None:
        precomputed_h_store = precompute_h_store(data=data, features=features)

    train_samples = int(len(data) * (1 - eval_portion))

    model = FeatureModel(num_features=len(features))

    optimizer_class = optimizers_dict[optimizer_name]

    optimizer = optimizer_class(model.parameters(), lr=learning_rate)

    train_dataset = FeatureDataset(h_store=precomputed_h_store[:train_samples], data=data[:train_samples])
    dev_dataset = FeatureDataset(h_store=precomputed_h_store[train_samples:], data=data[train_samples:])
    loss = torch.nn.CrossEntropyLoss()

    best_epoch_cost = math.inf
    best_weights = None
    epoch_indices = list(range(len(train_dataset)))

    for i in range(epochs):
        optimizer.zero_grad()
        random.shuffle(epoch_indices)
        for n in epoch_indices:
            model.train()
            feature_scores, split_position = train_dataset[n]

            scores = model_caller_wrapper(model=model, x=feature_scores)

            # Batch size acts as gradient acum steps, so we need to divide the cost by the number of steps
            cost = loss(scores, torch.tensor(split_position).reshape((1,))) / batch_size

            cost.backward()

            if (n+1) % batch_size == 0:
                optimizer.step()
                optimizer.zero_grad()

        model.eval()
        with torch.no_grad():
            epoch_cost = 0
            n_errors = 0
            for n in range(len(dev_dataset)):
                feature_scores, split_position = dev_dataset[n]
                scores = model_caller_wrapper(model=model, x=feature_scores)

                epoch_cost += loss(scores, torch.tensor(split_position).reshape((1,)))

                yhat = torch.argmax(scores, dim=1).detach().numpy().tolist()[0]
                if yhat != split_position:
                    n_errors += 1

            epoch_cost /= len(dev_dataset)
            print(
                f"Epoch {i}, cost {epoch_cost / len(dev_dataset)}, accuracy: {(len(dev_dataset) - n_errors) / len(dev_dataset)}")

            if epoch_cost < best_epoch_cost:
                best_epoch_cost = epoch_cost
                best_weights = model.feature_weights_layer.weight.detach().numpy()
            else:
                print("Early stopping")
                break

    return best_weights


def add_arguments_perceptron(parser):
    parser.add_argument("--perceptron_a", type=float, default=[1.0], nargs="+")
    parser.add_argument("--perceptron_b", type=float, default=[0.1], nargs="+")
    parser.add_argument("--max_iterations", type=int, default=200)


def add_arguments_sgd(parser):
    parser.add_argument("--learning_rate", default=1e-4, type=float)
    parser.add_argument("--batch_size", default=64, type=int)
    parser.add_argument("--epochs", default=50, type=int)
    parser.add_argument("--optimizer", choices=optimizers_dict.keys(), type=str)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--src_file", type=str, required=True)
    parser.add_argument("--tgt_file", type=str, required=True)
    parser.add_argument("--features", type=str, nargs="+", required=True)
    parser.add_argument("--method", type=str, choices=[SGD_str, PERCEPTRON_str])
    parser.add_argument("--include_next_sentence_prob", type=float, default=1.0)
    parser.add_argument("--json_output_file", type=str, required=True)
    parser.add_argument("--debug_file", type=str, default=None)


    known_args, unknown_args = parser.parse_known_args()
    model_specific_parser = argparse.ArgumentParser()
    if known_args.method == SGD_str:
        add_arguments_sgd(model_specific_parser)
    elif known_args.method == PERCEPTRON_str:
        add_arguments_perceptron(model_specific_parser)
    else:
        raise Exception
    model_specific_args = model_specific_parser.parse_args(unknown_args)
    args = argparse.Namespace(**vars(known_args), **vars(model_specific_args))

    data_o = generate_data_from_files(src_file=args.src_file, tgt_file=args.tgt_file,
                                      include_next_sentence_prob=args.include_next_sentence_prob)

    features_o: List[Feature] = [load_from_json(json_path=feature_path) for feature_path in args.features]

    precomputed_h_store_o = precompute_h_store(data=data_o, features=features_o)

    if args.method == SGD_str:
        best_weights_2d = optimize_weights_sgd(data=data_o, features=features_o,
                                            precomputed_h_store=precomputed_h_store_o, epochs=args.epochs,
                                            learning_rate=args.learning_rate, batch_size=args.batch_size,
                                            optimizer_name=args.optimizer)
        best_weights = best_weights_2d[0]

    elif args.method == PERCEPTRON_str:
        best_weights, errors, max_iterations_o = optimize_weights_perceptron(data=data_o, features=features_o,
                                                                      precomputed_h_store=precomputed_h_store_o, a_values=args.perceptron_a,
                                                                      b_values=args.perceptron_b, max_iterations=args.max_iterations)

        print(f"Best model: num_errors {errors}, max iterations {max_iterations_o}")
    else:
        raise Exception

    print("Optmization complete")
    for feature_o, weight in zip(args.features, best_weights.tolist()):
        print(feature_o, weight)

    weights_s = best_weights.tolist()
    with open(args.json_output_file, "w") as outf:
        features_s = args.features
        to_store = {"features": features_s,
                    "weights": weights_s}
        json.dump(to_store, fp=outf)

    if args.debug_file:
        """
        Take feature 0 as baseline, store all dev samples for which the rest of the features provide an improvement
        """
        train_samples = int(len(data_o) * (1 - 0.2))

        dev_data_o = data_o[train_samples:]
        dev_h_store = precomputed_h_store_o[train_samples:]

        with open(args.debug_file, "wt") as out_debug:
            for idx in range(len(dev_h_store)):
                baseline_scores = dev_h_store[idx][0] * weights_s[0]
                baseline_decision = np.argmax(baseline_scores)
                dist_to_true = abs(baseline_decision - dev_data_o[idx][1])

                for fea_idx in range(1, len(features_o)):
                    baseline_scores += dev_h_store[idx][fea_idx] * weights_s[fea_idx]
                new_decision = np.argmax(baseline_scores)
                new_dist_to_true = abs(new_decision - dev_data_o[idx][1])

                if new_dist_to_true < dist_to_true:
                    print("################################################", file=out_debug)
                    print(f"Additional features moved the prediction from {baseline_decision} to {new_decision}, {dist_to_true - new_dist_to_true} positions closer to the ground truth", file=out_debug)
                    print(dev_data_o[idx], file=out_debug)
                    for fea_idx in range(len(features_o)):
                        print(f"Feature {fea_idx} raw_scores:", dev_h_store[idx][fea_idx], file=out_debug)
                        print(f"Feature {fea_idx} scores:", dev_h_store[idx][fea_idx] * best_weights.tolist()[fea_idx],
                              file=out_debug)
                    print(f"System scores:", baseline_scores,
                          file=out_debug)

