import numpy as np
from typing import List, Optional
from segfreetk.features.feature import Feature
from segfreetk.common.states import TranslationState, HelperStates


class FeatureScorer:
    def __init__(self, features: List[Feature], weights: List[float]):
        assert len(features) == len(weights)
        self.features = features
        self.weights = weights

    def score_states(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        int_scores = np.zeros(len(states.src_segments[-1]))

        for feature, weight in zip(self.features, self.weights):
            scores = feature.score(states=states, helper_states=helper_states)
            arr_scores = np.array(scores)
            weighted_scores = arr_scores * weight
            int_scores += weighted_scores

        final_scores = int_scores.tolist()

        # noinspection PyTypeChecker
        assert len(final_scores) == len(states.src_segments[-1])
        # noinspection PyTypeChecker
        return final_scores
