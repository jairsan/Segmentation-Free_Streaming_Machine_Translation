from typing import List, Optional

from segfreetk.common.states import TranslationState, HelperStates


class Feature:
    def score(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        """
        Compute EOS probability for each position of the last src sentence
        :param helper_states:
        :param states:
        :return:
        """

        intermediate_scores = self.my_score(states, helper_states)

        assert len(intermediate_scores) == len(states.src_segments[-1])

        return intermediate_scores

    def my_score(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        raise NotImplementedError
