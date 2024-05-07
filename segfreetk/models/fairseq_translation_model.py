from typing import List, Tuple
import logging

import torch
from fairseq import checkpoint_utils, tasks
from segfreetk.models.model import Model
from segfreetk.common.incremental_simultaneous_beam_search_V2 import IncrementalSimultaneousBeamSearchV2
from segfreetk.common.subword_splitters import Splitter
from segfreetk.common.special_tokens import SpecialTokens
from segfreetk.common.states import TranslationState, TranslationHypothesis

logger = logging.getLogger(__name__)


class FairseqTranslationModel(Model):

    def __init__(self, model_path: str, data_bin_path: str, search_length_penalty_alpha: float = 1.0,
                 block_ngrams_order: int = 0,
                 beam_size: int = 4,
                 special_tokens: SpecialTokens = None):
        super(FairseqTranslationModel, self).__init__(special_tokens=special_tokens)
        self.load_model(model_path, data_bin_path)
        self.hypo_generator = IncrementalSimultaneousBeamSearchV2(self.model, self.dict["tgt"],
                                                                  block_ngram_repeat_order=block_ngrams_order,
                                                                  length_penalty_alpha=search_length_penalty_alpha,
                                                                  beam_size=beam_size)

    def load_dictionary(self, task):
        self.dict["tgt"] = task.target_dictionary
        self.dict["src"] = task.source_dictionary

    def load_model(self, filename, data_bin):
        state = checkpoint_utils.load_checkpoint_to_cpu(filename)

        saved_args = state["args"]
        saved_args.data = data_bin

        task = tasks.setup_task(saved_args)

        # build model for ensemble
        self.model = task.build_model(saved_args)
        self.model.load_state_dict(state["model"], strict=True)

        use_cuda = torch.cuda.is_available()

        if use_cuda:
            self.model.cuda()

        logger.debug(
            f"Translation model has been loaded. CUDA available: {use_cuda}")

        # Set dictionary
        self.load_dictionary(task)
        self.model.eval()

    def get_indexes_from_states(self, states: TranslationState, src_splitter: Splitter, tgt_splitter: Splitter, use_history: bool = True)\
            -> Tuple[List[int], List[int]]:

        src_str = ""
        tgt_str = ""

        if use_history:
            if states.activate_cont:
                src_str = self.special_tokens.src_cont + " "
            else:
                src_str = self.special_tokens.src_doc + " "

            if states.activate_cont:
                tgt_str = self.special_tokens.tgt_cont + " "
            else:
                tgt_str = self.special_tokens.tgt_doc + " "

        for i, pair in enumerate(zip(states.src_segments, states.tgt_segments)):
            src_sentence, tgt_sentence = pair

            if len(src_sentence) > 0:
                src_str += " ".join(src_sentence)

                if i != len(states.src_segments) - 1:
                    src_str += " " + self.special_tokens.src_sep + " "
                # [SEP] is only added to the open src_sentence if we are using a system with a segmenter,
                # and it detected an end-of-chunk event
                elif states.last_segmenter_decision_is_split:
                    src_str += " " + self.special_tokens.src_sep + " "

            if len(tgt_sentence) > 0:
                tgt_str += " ".join(tgt_sentence)
                # [SEP] is not added to the open tgt sentence
                if not i == len(states.tgt_segments) - 1:
                    tgt_str += " " + self.special_tokens.tgt_sep + " "

        if states.finished_read:
            src_str += " " + self.special_tokens.src_end
        else:
            if self.special_tokens.src_end_of_prefix != "":
                src_str += " " + self.special_tokens.src_end_of_prefix

        src_idx = []
        for piece in src_splitter.split(src_str):
            src_idx.append(self.dict["src"].index(piece))

        tgt_idx = []
        for piece in tgt_splitter.split(tgt_str):
            tgt_idx.append(self.dict["tgt"].index(piece))

        logger.debug(f"Preparing hypothesis for model using states {states}, produced src_string: #{src_str}# and  tgt_string #{tgt_str}#")
        return src_idx, tgt_idx

    def get_translation_hypothesis(self, src_indices: List[int], tgt_indices: List[int], max_len: int) \
            -> List[TranslationHypothesis]:

        # TODO allow CPU
        device = torch.device('cuda')

        sample = {"net_input": {"src_tokens": torch.LongTensor([src_indices]).to(device)}}
        prefix_tokens = torch.LongTensor([tgt_indices]).to(device)

        hypos = self.hypo_generator.generate(sample, prefix_tokens, force_eos=True, max_len=max_len)
        return hypos
