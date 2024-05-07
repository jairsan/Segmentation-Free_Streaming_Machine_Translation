# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

import math
import torch
from typing import List, Tuple, Any, Set
from fairseq.models.fairseq_encoder import EncoderOut
from fairseq.data.dictionary import Dictionary
from fairseq.models.fairseq_model import FairseqModel
from nltk.util import ngrams

from segfreetk.common.states import TranslationHypothesis


class IncrementalSimultaneousBeamSearchV2:

    def __init__(
            self,
            model: FairseqModel,
            tgt_dict: Dictionary,
            beam_size: int = 4,
            length_penalty_alpha: float = 1.0,
            block_ngram_repeat_order: int = 0,
            search_mode: str = "classic_nmt",
            encoder_returns: str = "EncoderOut"):
        """

        :param model: Fairseq model used for beam-search
        :param tgt_dict: Tgt_dictionary of the fairseq model
        :param beam_size: Beam size to carry out beam search
        :param length_penalty_alpha: Values > 1.0 favor longer sentence, values < 1.0 favor shorter sentences
        :param block_ngram_repeat: If > 0, blocks n_grams of order [block_ngram_repeat] from appearing more than once in
            in the hypothesis, by setting the score of the offending beam to a very low value.
        :param search_mode: classic_nmt: When we select hypo with eos, reduce beam width by 1
        :param encoder_returns: Type of the object returned by the encoder's forward()
        """
        self.model = model
        self.model.eval()
        self.tgt_dict = tgt_dict
        self.beam_size = beam_size
        self.length_penalty_alpha = length_penalty_alpha
        self.block_ngram_repeat_order = block_ngram_repeat_order
        self.search_mode = search_mode
        assert search_mode in ["classic_nmt", "full"]
        self.encoder_returns = encoder_returns
        assert encoder_returns in ["EncoderOut", "dict"]

    def generate(self, sample, prefix_tokens, force_eos: bool, max_len: int, min_len: int = 0) \
            -> List[TranslationHypothesis]:

        # Each constraint is a tuple of (previous_token, forced_next_token)

        result = self.search(sample, prefix_tokens, max_len, force_eos, min_len)

        n_prefix_tokens = prefix_tokens.shape[1]

        results = sorted(result, key=lambda x: x.score / (len(x.translation_indexes) - n_prefix_tokens)
                                                ** self.length_penalty_alpha, reverse=True)
        return results

    def search(self, sample, prefix_tokens, max_len: int, force_eos: bool, min_len: int) -> List[TranslationHypothesis]:
        # Note: If force_eos = True, returns a hypo where the last tokens is forced to be EOS.
        # This EOS token is included in the computations.
        # If you want to produce 6 real words, you must use max_len=6+1, to account for EOS
        assert max_len >= min_len
        with torch.no_grad():
            # shape (1 x src_length)
            orig_input_tokens = sample["net_input"]["src_tokens"]

            current_beam = self.beam_size

            n_prefix_tokens = prefix_tokens.shape[1]

            assert max_len > n_prefix_tokens
            # We repeat the input so that it matches the "batch" of the current beam
            # In the future, it might be slightly efficient to carry out the encoding first,
            # and then expand to the correct shape

            # (1 x src_length) -> (beam x src_length)
            input_tokens = orig_input_tokens.expand((current_beam, orig_input_tokens.shape[1]))
            # (1) -> (beam)
            src_lengths = torch.cuda.LongTensor([orig_input_tokens.shape[1]]).expand(current_beam)
            # (1 x n_prefix_tokens) -> (beam x n_prefix_tokens)
            target_tokens = prefix_tokens.expand((current_beam, prefix_tokens.shape[1]))

            # We append eos at the start
            eos_t = torch.full((current_beam, 1), self.tgt_dict.eos(), dtype=torch.int64).long().cuda()
            prev_output_tokens = torch.cat((eos_t, target_tokens), 1)

            encoder_output = self.model.encoder(input_tokens, src_lengths)

            # (beam x max_len)
            # scores holds the cumulative score of each hypothesis at each step
            scores = torch.zeros((self.beam_size, max_len), dtype=torch.float).cuda()

            finalized_sents: List[TranslationHypothesis] = []

            # Prefix tokens are fixed, we start decoding only for new part
            for i in range(n_prefix_tokens, max_len):
                apply_force_eos_this_step = force_eos and i == max_len - 1

                prev_output_tokens, \
                encoder_output, \
                scores, current_beam, \
                finalized_sents = \
                    self.step(i, prev_output_tokens, encoder_output, scores,
                              current_beam, finalized_sents, n_prefix_tokens, apply_force_eos_this_step, min_len,
                              max_len)

                if current_beam == 0:
                    break

        return finalized_sents

    def step(self, i, prev_output_tokens, encoder_output, scores, current_beam,
             finalized_sents: List[TranslationHypothesis], n_prefix_tokens, force_eos, min_len, max_len)\
            -> Tuple[Any, Any, Any, Any, List[TranslationHypothesis]]:

        # In step i we generate the (i+1)th word

        if force_eos:
            # For last iteration, we force to decode EOS
            net_output, _ = self.model.decoder(prev_output_tokens, encoder_output)
            l_probs = torch.nn.functional.log_softmax(net_output, dim=2)

            # (beam x vocab_size)
            last_l_probs = l_probs[:, -1, :]

            # Add l_probs to the scores
            last_l_probs = last_l_probs + scores[:, -1].reshape(current_beam, 1)

            probs_eos = last_l_probs[:, self.tgt_dict.eos()]
            sentences = torch.cat(
                (prev_output_tokens, torch.cuda.LongTensor([self.tgt_dict.eos()]).expand((current_beam, 1))), dim=1)
            for sentence, score in zip(sentences.tolist(), probs_eos.tolist()):
                finalized_sents.append(TranslationHypothesis(translation_indexes=sentence[1:], score=score))

            return prev_output_tokens, encoder_output, scores, current_beam, finalized_sents

        else:
            # (beam x target_length x vocab_size)
            net_output, _ = self.model.decoder(prev_output_tokens, encoder_output)
            l_probs = torch.nn.functional.log_softmax(net_output, dim=2)

            # (beam x vocab_size)
            last_l_probs = l_probs[:, -1, :]

            if i + 1 < min_len:
                last_l_probs[:, self.tgt_dict.eos()] = -math.inf
            last_l_probs[:, self.tgt_dict.pad()] = -math.inf

            if self.block_ngram_repeat_order > 0:
                self.block_ngram_repeat(prev_output_tokens=prev_output_tokens, last_l_probs=last_l_probs)

            # Add l_probs to the scores
            last_l_probs = last_l_probs + scores[:, -1].reshape(current_beam, 1)

            k = current_beam * 2

            # Combine scores into continuous array, then select top k hypotheses

            if i == n_prefix_tokens:
                top_prediction = torch.topk(last_l_probs[0, :].view(-1), k)
            else:
                top_prediction = torch.topk(last_l_probs.view(-1), k)

            # score of each of the top k hypothesis
            scores_buf = top_prediction[0]
            # index (in continuous array) of each hypothesis
            indices_buf = top_prediction[1]

            # for each hypothesis, the index of the father beam
            beams_buf = torch.floor_divide(indices_buf, torch.cuda.LongTensor([len(self.tgt_dict)]))

            # for each hypothesis, the index(in vocab) of the token
            token_idx_buf = torch.fmod(indices_buf, torch.cuda.LongTensor([len(self.tgt_dict)]))

            # hypothesis with eos are considered to have finished
            eos_mask = token_idx_buf.eq(torch.cuda.LongTensor([self.tgt_dict.eos()]))
            top_hypos = torch.arange(0, k) < current_beam
            top_hypos = top_hypos.cuda()
            valid_eos_mask = eos_mask & top_hypos
            active_mask = torch.bitwise_not(eos_mask)

            # EOS hypothesis processing

            eos_beams = beams_buf[valid_eos_mask]
            eos_indices = token_idx_buf[valid_eos_mask]

            # add eos
            eos_tokens = prev_output_tokens[eos_beams]
            eos_tokens = torch.cat((eos_tokens, eos_indices.reshape(-1, 1)), dim=1)
            eos_scores = scores_buf[eos_mask]

            for sentence, score, parent_beam in zip(eos_tokens.tolist(), eos_scores.tolist(), eos_beams.tolist()):
                finalized_sents.append(TranslationHypothesis(translation_indexes=sentence[1:], score=score))

                if self.search_mode == "classic_nmt":
                    current_beam -= 1
                # hypos of same beam
                same_beam = beams_buf.eq(torch.cuda.LongTensor([parent_beam]))

                # hypos with lower score
                lower_score = scores_buf < torch.cuda.LongTensor([score])

                to_remove = same_beam & lower_score

                if self.search_mode == "classic_nmt":
                    active_mask = active_mask & torch.bitwise_not(to_remove)

            active_hypos = torch.sum(active_mask.long()).item()

            if current_beam == 0:
                return prev_output_tokens, encoder_output, scores, current_beam, finalized_sents

            # Active hypothesis processing
            new_prev_output_tokens = prev_output_tokens[beams_buf[active_mask], :]
            prev_output_tokens = torch.cat((new_prev_output_tokens, token_idx_buf[active_mask].reshape(-1, 1)), dim=1)[
                                 :min(current_beam, active_hypos), :]

            new_scores = scores[beams_buf[active_mask], :]
            scores = torch.cat((new_scores, scores_buf[active_mask].reshape(-1, 1)), dim=1)[
                     :min(current_beam, active_hypos), :]

            current_beam = min(current_beam, active_hypos)

            if self.encoder_returns == "EncoderOut":
                encoder_output = EncoderOut(encoder_out=encoder_output.encoder_out[:, :current_beam, :],
                                            encoder_padding_mask=encoder_output.encoder_padding_mask[:current_beam, :],
                                            encoder_embedding=encoder_output.encoder_embedding[:current_beam, :, :],
                                            encoder_states=None, src_tokens=None, src_lengths=None)
            elif self.encoder_returns == "dict":
                enc_pad = None
                if encoder_output["encoder_padding_mask"] is not None:
                    enc_pad = encoder_output["encoder_padding_mask"][:current_beam, :]
                encoder_output = {
                    "encoder_out": encoder_output["encoder_out"][:, :current_beam, :],
                    "encoder_padding_mask": enc_pad
                }
            else:
                raise Exception

            # For last iteration, take all active hypos too
            if i == max_len - 1:
                tokins = prev_output_tokens.tolist()
                scoris = scores_buf[active_mask].reshape(-1)[:current_beam].tolist()
                assert len(tokins) == len(scoris)
                for sentence, score in zip(tokins, scoris):
                    finalized_sents.append(TranslationHypothesis(translation_indexes=sentence[1:], score=score))

            return prev_output_tokens, encoder_output, scores, current_beam, finalized_sents

    def block_ngram_repeat(self, prev_output_tokens: torch.Tensor, last_l_probs: torch.Tensor):
        """
        Blocks repeated ngrams. This is done by updating (in-place) last_l_probs and setting the probs of tokens that
        would generate a repeated n-gram to a very small value. Note that this method only check if the last token
        would create a repeated n-gram. Repeated n-gram that already exist in the hypothesis do not set the prob to 0.

        :param prev_output_tokens: (beam x num_tokens)
        :param last_l_probs: (beam x vocab_size)
        """

        beam_size = prev_output_tokens.size()[0]
        num_tokens = prev_output_tokens.size()[1]

        if num_tokens >= self.block_ngram_repeat_order:
            for i in range(beam_size):
                out_tokens_list = prev_output_tokens[i].tolist()
                n_grams: List[Tuple[int]] = ngrams(sequence=out_tokens_list,
                                                   n=self.block_ngram_repeat_order)
                # next generated n_gram:  last [ngram_order - 1] tokens plus the newly generated one
                # we are interested in the first part

                prev_ngram_tokens = self.block_ngram_repeat_order-1
                if prev_ngram_tokens > 0:
                    next_ngram_common_history = out_tokens_list[-(self.block_ngram_repeat_order-1):]
                else:
                    next_ngram_common_history = []

                # we now search if any of the previously existing ngrams share the history
                banned_tokens: List[int] = []
                for ngram in n_grams:
                    if ngram[:-1] == tuple(next_ngram_common_history):
                        banned_tokens.append(ngram[-1])
                for tok in banned_tokens:
                    last_l_probs[i][tok] = -math.inf



