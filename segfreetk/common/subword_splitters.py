from typing import List
import sentencepiece as spm


class Splitter(object):
    def split(self, string: str) -> List[str]:
        raise NotImplementedError

    def is_end_word(self, token: str) -> bool:
        raise NotImplementedError

    def merge(self, list_of_string: List[str]) -> str:
        raise NotImplementedError


class SentencePieceModel(Splitter):
    def __init__(self, model_path, vocab_path=None, vocab_th=0):
        self.model = spm.SentencePieceProcessor()
        self.model.Load(model_path)
        if vocab_path is not None and vocab_th > 0:
            self.model.LoadVocabulary(vocab_path, vocab_th)

    def split(self, string: str) -> List[str]:
        raise NotImplementedError

    def is_end_word(self, token: str) -> bool:
        raise NotImplementedError

    def merge(self, list_of_string: List[str]) -> str:
        raise NotImplementedError


class SentencePieceModelWordSplitterIdInput(SentencePieceModel):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def split(self, string: str) -> List[str]:
        units = string.split()
        results = []
        for unit in units:
            if unit == '</s>' or unit == "<unk>":
                results.append(unit)
            else:
                unit = unit + " "
                ids = [str(x) for x in self.model.EncodeAsIds(unit)]
                results.extend(ids)
        return results

    def is_end_word(self, token: str) -> bool:
        piece = self.model.IdToPiece(int(token))

        # Assume whitespace as suffix
        return piece[-1] == '\u2581'

    def merge(self, list_of_string: List[str]) -> str:

        pieces = []

        for ind in list_of_string:
            # TODO check if this is correct
            if ind == self.model['<unk>']:
                pieces.append('<unk>▁')
            else:
                pieces.append(self.model.IdToPiece(int(ind)))

        return "".join(pieces).replace("▁", " ")


class SentencePieceModelWordSplitterPieceInput(SentencePieceModel):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def split(self, string: str) -> List[str]:
        units = string.split()
        results = []
        for unit in units:
            if unit == '</s>' or unit == "<unk>":
                results.append(unit)
            else:
                unit = unit + " "
                pieces = [x for x in self.model.EncodeAsPieces(unit)]
                results.extend(pieces)
        return results

    def is_end_word(self, token: str) -> bool:
        # Assume whitespace as suffix
        return token[-1] == '\u2581'

    def merge(self, list_of_string: List[str]) -> str:
        post_pieces = []

        for piece in list_of_string:
            if piece == "<unk>":
                post_pieces.append('<unk>▁')
            else:
                post_pieces.append(piece)

        return "".join(post_pieces).replace("▁", " ")
