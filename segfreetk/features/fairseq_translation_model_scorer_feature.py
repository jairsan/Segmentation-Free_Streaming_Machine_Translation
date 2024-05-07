import math
from typing import List, Optional, Literal
import torch
import logging
import time
from fairseq.sequence_scorer import SequenceScorer

from segfreetk.common.states import TranslationState, HelperStates
from segfreetk.features.feature import Feature
from segfreetk.models.fairseq_translation_model import FairseqTranslationModel
from segfreetk.common.subword_splitters import SentencePieceModelWordSplitterIdInput,\
    SentencePieceModelWordSplitterPieceInput

logger = logging.getLogger(__name__)


class FairseqReverseTranslationModelScorerFeatureWrapper(Feature):
    name: str = "FAIRSEQ_REVERSE"

    def __init__(self, model_path: str, data_bin_path: str, reverse_model_src_splitter_path: str,
                 reverse_model_tgt_splitter_path: str, splitter_type: Literal["id", "str"] = "str"):
        self.my_fairseq_model = FairseqTranslationModel(model_path, data_bin_path)
        self.fairseq_scorer = SequenceScorer(tgt_dict=self.my_fairseq_model.dict["tgt"])

        assert splitter_type in ["id", "str"]
        if splitter_type == "id":
            self.reverse_model_src_splitter = \
                SentencePieceModelWordSplitterIdInput(model_path=reverse_model_src_splitter_path)
            self.reverse_model_tgt_splitter = \
                SentencePieceModelWordSplitterIdInput(model_path=reverse_model_tgt_splitter_path)
        else:
            self.reverse_model_src_splitter = SentencePieceModelWordSplitterPieceInput(model_path=reverse_model_src_splitter_path)
            self.reverse_model_tgt_splitter = SentencePieceModelWordSplitterPieceInput(model_path=reverse_model_tgt_splitter_path)

    def my_old_score(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        results = []
        # TODO allow CPU
        device = torch.device('cuda')

        splitted_original_tgt = " ".join(self.reverse_model_src_splitter.split(" ".join(states.tgt_segments[-1])))

        original_tgt_idx = self.my_fairseq_model.dict["src"].encode_line(splitted_original_tgt,
                                                                         append_eos=True).to(device)

        splitted_tokens: List[str] = []
        split_indexes: List[int] = []
        for word in states.src_segments[-1]:
            splitted_tokens.extend(self.reverse_model_tgt_splitter.split(word))
            split_indexes.append(len(splitted_tokens))

        start_t = time.time()

        for i in range(len(states.src_segments[-1])):
            # First, we need to know how many subwords/splitted units correspond to each word
            words_to_consider = splitted_tokens[:split_indexes[i]]
            # Note the reverse direction: The src words belong to the target language of the reverse model
            candidate = self.my_fairseq_model.dict["tgt"].encode_line(" ".join(words_to_consider),
                                                                      append_eos=False).to(device)

            eos_t = torch.tensor([self.my_fairseq_model.dict["tgt"].eos()]).to(device)
            target = torch.cat((candidate, eos_t)).to(device).long()
            prev_out_tokens = torch.cat((eos_t, candidate)).to(device)

            sample = {'net_input': {
                'src_tokens': torch.reshape(original_tgt_idx, (1, -1)).long(),
                'src_lengths': torch.tensor([original_tgt_idx.shape]).long(),
                'prev_output_tokens': torch.reshape(prev_out_tokens, (1, -1))},
                'target': torch.reshape(target, (1, -1))
            }

            hypos = self.fairseq_scorer.generate([self.my_fairseq_model.model], sample)

            results.append(hypos[0][0]["score"].item())


        # Ensure feature returns a valid logprob-like value
        # TODO: What about modifications to the beam search such as length-penalty?
        # for score in results:
        #    assert score <= 0.0, f"{score}"

        end_t = time.time()
        cost = end_t - start_t
        logger.debug(f"Called reverse-MT model, cost: {cost}")

        return results

    def my_score(self, states: TranslationState, helper_states: Optional[HelperStates]) -> List[float]:
        start_t = time.time()

        results = []
        # TODO allow CPU
        device = torch.device('cuda')

        splitted_original_tgt = " ".join(self.reverse_model_src_splitter.split(" ".join(states.tgt_segments[-1])))

        original_tgt_idx = self.my_fairseq_model.dict["src"].encode_line(splitted_original_tgt,
                                                                         append_eos=True).to(device)

        splitted_tokens: List[str] = []
        split_indexes: List[int] = []
        for word in states.src_segments[-1]:
            splitted_tokens.extend(self.reverse_model_tgt_splitter.split(word))
            split_indexes.append(len(splitted_tokens))


        # setup tensors
        original_tgt_idx_t = torch.reshape(original_tgt_idx, (1, -1)).long().to(device)
        eos_t_t = torch.full((1, 1), self.my_fairseq_model.dict["tgt"].eos(), dtype=torch.int64).long().cuda()
        pseudo_src = original_tgt_idx_t
        num_orig_tokens = pseudo_src.shape[1]
        pseudo_src_lengths = torch.cuda.LongTensor([num_orig_tokens]).to(device)

        # run encoder
        encoder_output = self.my_fairseq_model.model.encoder(pseudo_src, pseudo_src_lengths)

        probs_eos = []
        probs_token = []

        i=len(splitted_tokens)+1
        prefix_tokens = splitted_tokens[:i]
        prefix_tokens_indices = [self.my_fairseq_model.dict["tgt"].index(t) for t in prefix_tokens]
        prefix_tokens_t = torch.LongTensor([prefix_tokens_indices]).to(device)

        # We append eos at the start
        prev_output_tokens = torch.cat((eos_t_t, prefix_tokens_t), 1)

        net_output, _ = self.my_fairseq_model.model.decoder(prev_output_tokens, encoder_output)
        l_probs = torch.nn.functional.log_softmax(net_output, dim=2)

        for i in range(len(splitted_tokens) + 1):
            this_probs = l_probs[:, i, :]
            score_eos = this_probs[:, self.my_fairseq_model.dict["tgt"].eos()]
            probs_eos.append(score_eos.tolist()[0])

            if i < len(splitted_tokens):
                score_token = this_probs[:, self.my_fairseq_model.dict["tgt"].index(splitted_tokens[i])]
                probs_token.append(score_token.tolist()[0])
            else:
                probs_token.append(-math.inf)


        # Ensure feature returns a valid logprob-like value
        # TODO: What about modifications to the beam search such as length-penalty?
        # for score in results:
        #    assert score <= 0.0, f"{score}"

        results = []
        for i in range(len(states.src_segments[-1])):
            score_hypo = sum(probs_token[:split_indexes[i]])
            score_eos = probs_eos[split_indexes[i]]
            results.append((score_hypo + score_eos) / (split_indexes[i] + 1))

        end_t = time.time()
        cost = end_t - start_t
        logger.debug(f"Called reverse-MT model, cost: {cost}")

        return results