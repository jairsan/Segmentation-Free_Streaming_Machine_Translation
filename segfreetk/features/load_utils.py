import json

from segfreetk.features import STR_TO_CLASS
from segfreetk.features.feature import Feature
from segfreetk.features.feature_scorer import FeatureScorer


def load_from_json(json_path: str) -> Feature:
    """
    Loads a Feature from a json file. This json file should a dict containing a "MODEL_TYPE" entry and other attributes.
    The Feature is created by picking the appropiate class from STR_TO_CLASS["MODEL_TYPE"], and the rest of the
    attributes are passed to the class constructor.

    Remember that all the neccessary arguments to create a feature should be able to be stored in a json.

    :param json_path: Path to the .json file which stores the Feature.
    :return: The loaded Feature object
    """
    with open(json_path) as json_file:
        feature_js = json.load(json_file)
        feature_type = feature_js["MODEL_TYPE"]
        feature_class = STR_TO_CLASS[feature_type]
        del feature_js["MODEL_TYPE"]
        feature = feature_class(**feature_js)

        return feature


def load_feature_score_from_json(json_path: str) -> FeatureScorer:
    """
    Loads a FeatureScorer from a json file.

    The json dict should contains a "features" attribute, which is a List of paths pointing to the json files containing
    the Features to be loaded. A "weights" attribute, of the same length as "features", provides the weight for each
    feature.

    :param json_path:
    :return:
    """
    with open(json_path) as json_file:
        json_obj = json.load(json_file)
        features = [load_from_json(feature_path) for feature_path in json_obj["features"]]
        weights = json_obj["weights"]
        fea_scorer = FeatureScorer(features=features, weights=weights)
        return fea_scorer


