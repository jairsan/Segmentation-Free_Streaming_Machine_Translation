import math

import numpy as np
import pytest

from segfreetk.common.states import TranslationState
from segfreetk.features.direct_count_feature import DirectCountFeature, train_direct_count_feature
from segfreetk.features.fixed_ratio_feature import train_fixed_ratio_feature
from segfreetk.features.length_feature import LengthFeature
from segfreetk.features.normal_regression_feature import NormalRegressionFeature, SimpleLinearRegressionFeature, \
    train_simple_linear_regression
from segfreetk.features.normal_regression_linear_models_feature import NormalRegressionLinearModelsFeature
from segfreetk.features.load_utils import load_from_json


def test_direct_count_feature(tmp_path):
    count_matrix = [[4, 1, 0, 0, 0],
                    [1, 3, 1, 0, 0],
                    [0, 0, 5, 0, 0],
                    [0, 0, 0, 4, 1],
                    [0, 0, 0, 0, 5]]
    count_array = np.array(count_matrix)
    np.save(file=str(tmp_path / "array.npy"), arr=count_array)

    feature = DirectCountFeature(count_matrix_path=str(tmp_path / "array.npy"), smoothing_alpha=0.1)

    states = [TranslationState(src_segments=[["1", "2"]], tgt_segments=[["1"]]),
              TranslationState(src_segments=[["1", "2", "3", "4", "5"]], tgt_segments=[["1"]]),
              TranslationState(src_segments=[["1", "2", "3", "4", "5", "6"]], tgt_segments=[["1", "2", "3"]])]

    expected = [[math.log(x) for x in [3 / 4, 1 / 4]],
                [math.log(x) for x in [0.6, 0.2, 0.1 * 2 / 3, 0.1 * 2 / 3, 0.1 * 2 / 3]],
                [math.log(x) for x in [0.0625, 0.0625, 0.6875, 0.0625, 0.0625, 0.0625]]]

    for state, result in zip(states, expected):
        assert feature.score(states=state, helper_states=None) == pytest.approx(result)


def test_count_feature_train(tmp_path):
    src_file = ["1 " * 2,
                "1 " * 5,
                "1 " * 3,
                "1 " * 10]
    tgt_file = ["1 " * 1,
                "1 " * 1,
                "1 " * 2,
                "1 " * 2]

    with open(tmp_path / "src_file.src", "w") as src_f, open(str(tmp_path / "tgt_file.tgt"), "w") as tgt_f:
        for s, t in zip(src_file, tgt_file):
            print(s, file=src_f)
            print(t, file=tgt_f)

    train_direct_count_feature(src_file_fp=str(tmp_path / "src_file.src"), tgt_file_fp=str(tmp_path / "tgt_file.tgt"),
                               max_positions=5,
                               artefacts_output_folder=str(tmp_path))

    output_json_path = str(tmp_path) + "/feature.json"

    feature = load_from_json(output_json_path)

    # noinspection PyUnresolvedReferences
    counts = feature.count_matrix

    expected = np.array([[0, 1, 0, 0, 1],
                         [0, 0, 1, 0, 0],
                         [0, 0, 0, 0, 0],
                         [0, 0, 0, 0, 0],
                         [0, 0, 0, 0, 0]])

    np.testing.assert_allclose(actual=counts, desired=expected)


def test_train_fixed_ratio_feature(tmp_path):
    src_file = ["1 " * 2,
                "1 " * 4,
                "1 " * 5]
    tgt_file = ["1 " * 2,
                "1 " * 5,
                "1 " * 8]

    with open(tmp_path / "src_file.src", "w") as src_f, open(str(tmp_path / "tgt_file.tgt"), "w") as tgt_f:
        for s, t in zip(src_file, tgt_file):
            print(s, file=src_f)
            print(t, file=tgt_f)

    train_fixed_ratio_feature(src_file_fp=str(tmp_path / "src_file.src"), tgt_file_fp=str(tmp_path / "tgt_file.tgt"),
                              artefacts_output_folder=str(tmp_path))

    feature = load_from_json(str(tmp_path) + "/feature.json")

    # noinspection PyUnresolvedReferences
    assert feature.tgt_src_ratio == 1.25


def test_train_fixed_ratio_feature_even(tmp_path):
    src_file = ["1 " * 5,
                "1 " * 5,
                "1 " * 5,
                "1 " * 5]
    tgt_file = ["1 " * 4,
                "1 " * 5,
                "1 " * 6,
                "1 " * 7]

    with open(tmp_path / "src_file.src", "w") as src_f, open(str(tmp_path / "tgt_file.tgt"), "w") as tgt_f:
        for s, t in zip(src_file, tgt_file):
            print(s, file=src_f)
            print(t, file=tgt_f)

    train_fixed_ratio_feature(src_file_fp=str(tmp_path / "src_file.src"), tgt_file_fp=str(tmp_path / "tgt_file.tgt"),
                              artefacts_output_folder=str(tmp_path))

    feature = load_from_json(str(tmp_path) + "/feature.json")

    # noinspection PyUnresolvedReferences
    assert feature.tgt_src_ratio == 0.5 + 0.5 * 6/5


def test_length_feature_src():
    feature = LengthFeature(length_of="src", do_exp=False)
    states = TranslationState(src_segments=[["1", "2", "3"]], tgt_segments=[["1", "2", "3"]])

    expected = [math.log(x) for x in range(1, 4)]

    actual = feature.score(states=states, helper_states=None)

    assert actual == expected


def test_length_feature_src_exp():
    feature = LengthFeature(length_of="src", do_exp=True)
    states = TranslationState(src_segments=[["1", "2", "3"]], tgt_segments=[["1", "2", "3"]])

    expected = [x for x in range(1, 4)]

    actual = feature.score(states=states, helper_states=None)

    assert actual == expected


def test_length_feature_src2tgt():
    feature = LengthFeature(length_of="src2tgt", do_exp=False)
    states = TranslationState(src_segments=[["1", "2", "3"]], tgt_segments=[["1", "2", "3"]])

    expected = [math.log(x) for x in [1/3, 2/3, 3/3]]

    actual = feature.score(states=states, helper_states=None)

    assert actual == expected


def test_length_feature_tgt2src():
    feature = LengthFeature(length_of="tgt2src", do_exp=False)
    states = TranslationState(src_segments=[["1", "2", "3"]], tgt_segments=[["1", "2", "3"]])

    expected = [math.log(x) for x in [3/1, 3/2, 3/3]]

    actual = feature.score(states=states, helper_states=None)

    assert actual == expected


def test_log_prob():
    expected_prob = [math.log(0.241970724519)]
    computed_prob = NormalRegressionFeature.mean_std_to_logprob(mean=0.0, std=1.0, value=1).tolist()

    np.testing.assert_allclose(expected_prob, computed_prob, rtol=1e-5)


def test_input_feature_generation():
    cases = [
        # order, value, expected
        (1, 5, [1, 5]),
        (2, 5, [1, 5, 25]),
        (1, 2, [1, 2]),
        (3, 2, [1, 2, 4, 8])
    ]

    for order, value, expected in cases:
        computed = SimpleLinearRegressionFeature.get_input_feas(value=value, order=order)
        np.testing.assert_allclose(computed, np.array(expected))


def test_simple_regression():
    feature = SimpleLinearRegressionFeature(coefficients=[0.0, 1.0], std=1)

    states = TranslationState(src_segments=[["1", "2", "3"]], tgt_segments=[["1", "2", "3"]])

    scores = feature.score(states=states, helper_states=None)

    expected = [math.log(x) for x in [0.053991, 0.241971, 0.398942]]

    np.testing.assert_allclose(scores, expected, rtol=1e-3)


def test_estimate_simple_regression_std(tmp_path):
    # Train linear regression with tgt, src points {2,3},{4,5},{9,11}
    # Result should be 1.15385x + 0.5641030

    src_file = ["1 " * 3,
               "1 " * 5,
               "1 " * 11]

    tgt_file = ["1 " * 2,
                "1 " * 4,
                "1 " * 9]

    with open(tmp_path / "src_file.src", "w") as src_f, open(str(tmp_path / "tgt_file.tgt"), "w") as tgt_f:
        for s, t in zip(src_file, tgt_file):
            print(s, file=src_f)
            print(t, file=tgt_f)

    train_simple_linear_regression(src_file_fp=str(tmp_path / "src_file.src"),
                                   tgt_file_fp=str(tmp_path / "tgt_file.tgt"),
                                   artefacts_output_folder=str(tmp_path), order=1, fit_intecept=True, std=None)

    feature = load_from_json(str(tmp_path) + "/feature.json")

    np.testing.assert_allclose(feature.coef, np.array([0.5641030, 1.15385]), rtol=1e-3)
    np.testing.assert_allclose(feature.std, [0.130744092])

def test_train_simple_linear_feature(tmp_path):
    src_file = ["1 " * 6,
                "1 " * 6,
                "1 " * 7,
                "1 " * 7]
    tgt_file = ["1 " * 5,
                "1 " * 5,
                "1 " * 6,
                "1 " * 6]

    with open(tmp_path / "src_file.src", "w") as src_f, open(str(tmp_path / "tgt_file.tgt"), "w") as tgt_f:
        for s, t in zip(src_file, tgt_file):
            print(s, file=src_f)
            print(t, file=tgt_f)

    for std, raw_probs in [(1.0, [0.053991, 0.241971, 0.398942]),
                           (2.0, [0.120985, 0.176033, 0.199471])]:

        train_simple_linear_regression(src_file_fp=str(tmp_path / "src_file.src"), tgt_file_fp=str(tmp_path / "tgt_file.tgt"),
                                  artefacts_output_folder=str(tmp_path), order=1, fit_intecept=True, std=std)

        feature = load_from_json(str(tmp_path) + "/feature.json")

        states = TranslationState(src_segments=[["1", "2", "3"]], tgt_segments=[["1", "2"]])
        # tgt_len = 2, so |x| \sim N(3, std)

        scores = feature.score(states=states, helper_states=None)

        expected = [math.log(x) for x in raw_probs]

        np.testing.assert_allclose(scores, expected, rtol=1e-3)


def test_linear_regression_with_models_mean_std():
    feature = NormalRegressionLinearModelsFeature(mean_order=1, std_order=1)
    feature.model.mean_layer.weight.data.fill_(1.0)
    feature.model.mean_layer.bias.data.fill_(0)
    feature.model.std_layer.weight.data.fill_(0.5)
    feature.model.std_layer.bias.data.fill_(0)

    src_sents = ["1 2 3"]
    tgt_sents = ["1 2"]

    expected_mean = 2.0
    expected_std = 1.3133

    mean_hat, std_hat = feature.model.forward(X=src_sents, Y=tgt_sents, device="cpu")
    np.testing.assert_allclose(np.array(expected_mean), mean_hat.tolist(), rtol=1e-3)
    np.testing.assert_allclose(np.array(expected_std), std_hat.tolist(), rtol=1e-3)


def test_linear_regression_with_models():
    feature = NormalRegressionLinearModelsFeature(mean_order=1, std_order=1)
    feature.model.mean_layer.weight.data.fill_(1.0)
    feature.model.mean_layer.bias.data.fill_(0)
    feature.model.std_layer.weight.data.fill_(0.5)
    feature.model.std_layer.bias.data.fill_(0)

    states = TranslationState(src_segments=[["1", "2", "3"]], tgt_segments=[["1", "2"]])

    raw_probs = [0.227324, 0.303771, 0.227324]
    expected = [math.log(x) for x in raw_probs]

    scores = feature.score(states=states, helper_states=None)
    np.testing.assert_allclose(scores, expected, rtol=1e-3)

