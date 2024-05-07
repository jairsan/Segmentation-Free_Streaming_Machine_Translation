from typing import List, Tuple

from segfreetk.common.subword_splitters import Splitter
from segfreetk.common.special_tokens import SpecialTokens
from segfreetk.common.states import TranslationState, TranslationHypothesis


class Model:
    def __init__(self, special_tokens: SpecialTokens = None):
        self.dict = {}
        self.model = None
        self.hypo_generator = None
        self.src_history_len = 0
        self.tgt_history_len = 0
        self.append_eos: bool = True
        self.special_tokens = special_tokens
        if self.special_tokens is None:
            self.special_tokens: SpecialTokens = SpecialTokens()

    def get_translation_hypothesis(self, src_indices: List[int], tgt_indices: List[int], max_len: int) \
            -> List[TranslationHypothesis]:
        raise NotImplementedError

    def get_indexes_from_states(self, states: TranslationState, src_splitter: Splitter, tgt_splitter: Splitter, use_history: bool = True) \
            -> Tuple[List[int], List[int]]:
        raise NotImplementedError


