from typing import Optional, List, Literal
import math

from segfreetk.common.states import TranslationState, HelperStates
from segfreetk.features.feature import Feature


class LengthFeature(Feature):
    name: str = "LENGTH"

    def __init__(self, length_of: Literal["src", "src2tgt", "tgt2src"], do_exp: bool = True):
        self.length_of = length_of
        self.do_exp = do_exp

    def my_score(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        if self.length_of == "src":
            raw_scores = list(range(1, len(states.src_segments[-1]) + 1))
        elif self.length_of == "src2tgt":
            raw_scores = [x / len(states.tgt_segments[-1]) for x in range(1, len(states.src_segments[-1]) + 1)]
        elif self.length_of == "tgt2src":
            raw_scores = [len(states.tgt_segments[-1]) / x for x in range(1, len(states.src_segments[-1]) + 1)]
        else:
            raise Exception

        if self.do_exp:
            return raw_scores
        else:
            return [math.log(x) for x in raw_scores]
