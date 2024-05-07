from typing import List, Tuple


class TranslationHypothesis:
    def __init__(self, translation_indexes: List[float], score: float):
        """
        The output of a translation model.

        :param translation_indexes: Tgt_dict indexes that make up the hypothesis
        :param score: Unnormalized log-prob score that the model assigns to the hypothesis
        """
        self.translation_indexes = translation_indexes
        self.score = score


class TranslationState:
    """
    Object which represents the current translation states.

    The word are held in src_segments and tgt_segments, of type List[List[str]], and  src_segments[i] is considered to
    be aligned with tgt_segments[i].
    """
    def __init__(self, src_segments: List[List[str]] = None, tgt_segments: List[List[str]] = None):
        self.src_segments = src_segments
        self.tgt_segments = tgt_segments
        if src_segments is None:
            self.src_segments = [[]]
        if tgt_segments is None:
            self.tgt_segments = [[]]

        # True if the whole input stream has been read ([END] special tag read)
        self.finished_read: bool = False
        # True if our model has finished writing the translation for a stream (emitted the [END] special tag)
        self.finished_write: bool = False

        # When activate_cont, we use [CONT] instead of [DOC]. This activates when we first delet smth from buffers
        self.activate_cont: bool = False

        # Only for non-seg-free agents that use a segmenter
        self.last_segmenter_decision_is_split = False

    def __repr__(self):
        return f"src_segments: {self.src_segments}, tgt_segments: {self.tgt_segments}"

    def get_states_sizes(self) -> Tuple[int, int]:
        """
        Computes the number of words present in all src and tgt segments

        :returns (n_src_words, n_tgt_words)
        """
        src_h_l = 0
        tgt_h_l = 0

        for s, t in zip(self.src_segments, self.tgt_segments):
            src_h_l += len(s)
            tgt_h_l += len(t)

        return src_h_l, tgt_h_l

    def filter_segments_to_max_len(self, src_max_len, tgt_max_len) -> None:
        """
        Removes enitre pairs of src/tgt sentences until both src/tgt max len is not exceeded. Oldest pairs are
        removed first. This operation is done in-place.

        :param src_max_len: Maximum number of source words
        :param tgt_max_len: Maximum number of target words

        """
        sl, tl = self.get_states_sizes()
        while sl > src_max_len or tl > tgt_max_len:
            if len(self.src_segments) > 1:
                # Remove oldest sentence pairs
                self.src_segments.pop(0)
                self.tgt_segments.pop(0)
                sl, tl = self.get_states_sizes()
            else:
                break


class HelperStates:
    def __init__(self, sorted_translation_hypotheses: List[TranslationHypothesis], num_prefix_tokens: int):
        """
        Helper object which can be used to avoid re-computing system output, either when doing write actions or when
        computing certain feature functions.

        :param sorted_translation_hypotheses: List of TranslationHypothesis, in descending order of likelyhood
        :param num_prefix_tokens: How many tokens/indexes of the hypotheses are fixed.
        """
        self.sorted_translation_hypotheses = sorted_translation_hypotheses
        self.num_prefix_tokens = num_prefix_tokens
