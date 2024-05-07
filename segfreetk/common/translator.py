import os
from argparse import ArgumentParser
from typing import List, Tuple
import logging
import json
import torch
import time

from segfreetk.agents.agent import Agent
from segfreetk.agents.sliding_window_agent import SlidingWindowAgent
from segfreetk.common.constants import READ_ACTION, WRITE_ACTION
from segfreetk.common.states import TranslationState
from segfreetk.features.load_utils import load_feature_score_from_json
from segfreetk.models.fairseq_translation_model import FairseqTranslationModel
from segfreetk.agents.translate_then_realign_agent import TranslateThenRealignAgent
from segfreetk.agents.ds_segmenter_agent import DsSegmenter, OracleSegmenter, DsSegmenterAgent, DsSegmenterOracleAgent
from segfreetk.common.subword_splitters import SentencePieceModelWordSplitterPieceInput, \
    SentencePieceModelWordSplitterIdInput
from segfreetk.common.special_tokens import SpecialTokens

from segmenter.utils import load_text_model

logger = logging.getLogger(__name__)


class Translator:
    def __init__(self, agent: Agent):
        self.agent = agent

    def translate_main(self, src_files: List[str], output_dir: str, use_sliding_windows: bool = False):
        all_words: List[str] = []
        all_actions: List[int] = []
        all_lags: List[float] = []
        all_valid_lags: List[float] = []

        extensions = [os.path.splitext(file_path) for file_path in src_files]
        num_json_files = len([ext for ext in extensions if ext == ".json"])
        if num_json_files > 0 and num_json_files != len(src_files):
            raise Exception("You should provide timestamps for all or none of the input files.")

        for i, file_path in enumerate(src_files):
            self.agent.reset()
            _, extension = os.path.splitext(file_path)
            compute_lag = extension == ".json"
            with open(file_path) as src_file:
                words_to_translate: List[str] = []
                timestamps: List[float] = []
                if compute_lag:
                    if isinstance(self.agent, DsSegmenterOracleAgent):
                        raise Exception("It is not clear how to TranslationLag with Oracle Segmenter")
                    obj = json.load(src_file)
                    for segment in obj:
                        for word_dict in segment["wl"]:
                            end = word_dict["e"]
                            word = word_dict["w"]
                            words_to_translate.append(word)
                            timestamps.append(end)

                else:
                    for line in src_file:
                        words = line.strip().split()

                        # If using the Oracle segmenter, we provide EOS information
                        if isinstance(self.agent, DsSegmenterOracleAgent) and len(words) > 0:
                            words[-1] = words[-1] + "\n"

                        words_to_translate.extend(words)

                if not use_sliding_windows:
                    output_words, actions, lags, valid_lags = self.translate_document(src_words=words_to_translate,
                                                                    document_name=os.path.basename(file_path),
                                                                       timestamps=timestamps)
                else:
                    output_words, actions, lags, valid_lags = self.translate_document_sliding(src_words=words_to_translate,
                                                                                      document_name=os.path.basename(
                                                                                          file_path),
                                                                                      timestamps=timestamps)
                all_words.extend(output_words)
                all_actions.extend(actions)
                all_lags.extend(lags)
                all_valid_lags.extend(valid_lags)
            with open(output_dir + f"/{i}.out", "w") as output_f:
                print(" ".join(output_words), file=output_f)
            with open(output_dir + f"/{i}.actions", "w") as output_actions_f:
                print(" ".join([str(x) for x in actions]), file=output_actions_f)
            if len(lags) > 0:
                if len(lags) != len(output_words):
                    raise Exception
                with open(output_dir + f"/{i}.out_lags", "w") as output_timestamps_f:
                    print(" ".join([str(x) for x in lags]), file=output_timestamps_f)
                with open(output_dir + f"/{i}.out_valid_lags", "w") as output_valid_timestamps_f:
                    print(" ".join([str(x) for x in valid_lags]), file=output_valid_timestamps_f)

        with open(output_dir + f"/all.out", "w") as output_f:
            print(" ".join(all_words), file=output_f)
        with open(output_dir + f"/all.actions", "w") as output_actions_f:
            print(" ".join([str(x) for x in all_actions]), file=output_actions_f)
        with open(output_dir + f"/all.out_lags", "w") as output_timestamps_f:
            print(" ".join([str(x) for x in all_lags]), file=output_timestamps_f)
        with open(output_dir + f"/all.out_valid_lags", "w") as output_valid_timestamps_f:
            print(" ".join([str(x) for x in all_valid_lags]), file=output_valid_timestamps_f)

    def translate_document(self, src_words: List[str], document_name: str,
                           timestamps: List[float]) -> Tuple[List[str], List[int], List[float], List[float]]:
        logger.info(f"Started translation of document {document_name}")

        num_words_processed = 0
        output_words: List[str] = []
        actions: List[int] = []
        output_lags: List[float] = []
        output_valid_lags: List[float] = []

        compute_lag = len(timestamps) > 0

        current_read_time = 0
        current_cost = 0

        while not self.agent.states.finished_write:
            action_tuple, optional = self.agent.policy()

            if action_tuple[0] == READ_ACTION:

                self.agent.read_action(src_words[num_words_processed])
                if compute_lag:
                    current_read_time = timestamps[num_words_processed]
                logger.debug(f"READ ACTION: {src_words[num_words_processed]}")

                actions.append(READ_ACTION)
                num_words_processed += 1
                if num_words_processed == len(src_words):
                    self.agent.process_finished_read()

            elif action_tuple[0] == WRITE_ACTION:
                if compute_lag:
                    # We recompute the hypothesis so that we dont cheat
                    start_t = time.time()
                    words_emitted = self.agent.write_action(action_tuple[1])
                    end_t = time.time()
                    cost = end_t - start_t
                    current_cost = max(current_read_time, current_cost + cost)
                else:
                    words_emitted = self.agent.write_action(action_tuple[1], optional)
                output_words.extend(words_emitted)
                output_lags.extend([current_cost] * len(words_emitted))
                logger.debug(f"WRITE ACTION: {words_emitted}")

                # We do NOT record special tokens as WRITE_ACTIONS
                valid_words = [word for word in words_emitted if
                               word not in self.agent.translation_model.special_tokens.all_special_tokens]
                actions.extend([WRITE_ACTION] * len(valid_words))
                output_valid_lags.extend([current_cost] * len(valid_words))
            else:
                raise Exception

        return output_words, actions, output_lags, output_valid_lags

    def translate_document_sliding(self, src_words: List[str], document_name: str,
                           timestamps: List[float]) -> Tuple[List[str], List[int], List[float], List[float]]:
        self.agent: SlidingWindowAgent #inform the linter

        num_words_processed = 0
        output_words: List[str] = []
        actions: List[int] = []
        num_read_words_at_each_output_word: List[int] = []
        output_lags: List[float] = []
        output_valid_lags: List[float] = []

        compute_lag = len(timestamps) > 0

        current_cost = 0
        current_read_time = 0

        for word in src_words:
            self.agent.read_action(word)

            if compute_lag:
                current_read_time = timestamps[num_words_processed]
            num_words_processed += 1

            start_t = time.time()
            len_s, i, j, tt, len_tgt_window = self.agent.translate_and_get_merge_indices()

            if len_tgt_window < len(self.agent.states.tgt_segments[-1]):
                i+= len(self.agent.states.tgt_segments[-1]) - len_tgt_window
            logger.debug(f"Merging windows, len(s):{len_s}  i: {i} j:{j} ")

            end_t = time.time()
            cost = end_t - start_t
            if compute_lag:
                current_cost = max(current_read_time, current_cost + cost)

            logger.debug(f"Tgt stream before window update: {self.agent.states.tgt_segments[-1]}")
            self.agent.states.tgt_segments[-1] = self.agent.apply_merge_indices(i=i, j=j, old_sequence=self.agent.states.tgt_segments[-1], new_sequence=tt, match_len=len_s)
            logger.debug(f"Tgt stream after window update: {self.agent.states.tgt_segments[-1]}")

            #tt[j:]
            num_read_words_at_each_output_word = self.agent.apply_merge_indices(i=i, j=j, old_sequence=num_read_words_at_each_output_word, new_sequence=[num_words_processed] * len(tt), match_len=len_s)

            output_words = self.agent.states.tgt_segments[-1]

            if compute_lag:
                output_lags = self.agent.apply_merge_indices(i=i, j=j, old_sequence=output_lags, new_sequence=[current_cost] * len(tt), match_len=len_s)
                output_valid_lags = self.agent.apply_merge_indices(i=i, j=j, old_sequence=output_valid_lags, new_sequence=[current_cost] * len(tt), match_len=len_s)


        # Reconstruct action sequence
        current_num_read_actions = 0
        for num_r in num_read_words_at_each_output_word:
            extra_read_actions = num_r - current_num_read_actions
            if extra_read_actions > 0:
                actions.extend([READ_ACTION] * extra_read_actions)
                current_num_read_actions = num_r
            actions.append(WRITE_ACTION)
        assert len(actions) == len(src_words) + len(output_words)

        return output_words, actions, output_lags, output_valid_lags

def main_cli():
    parser = ArgumentParser()

    agent_names = [TranslateThenRealignAgent.name, DsSegmenterAgent.name, DsSegmenterOracleAgent.name, SlidingWindowAgent.name]

    parser.add_argument("--agent_type", type=str, choices=agent_names, default=TranslateThenRealignAgent.name)

    known_args, unknown_args = parser.parse_known_args()

    if known_args.agent_type == TranslateThenRealignAgent.name:
        TranslateThenRealignAgent.add_args(parser)
    elif known_args.agent_type == DsSegmenterAgent.name:
        DsSegmenterAgent.add_args(parser)
    elif known_args.agent_type == DsSegmenterOracleAgent.name:
        DsSegmenterOracleAgent.add_args(parser)
    elif known_args.agent_type == SlidingWindowAgent.name:
        SlidingWindowAgent.add_args(parser)
    else:
        raise Exception

    parser.add_argument("--input_files", type=str, nargs="+", required=True)
    parser.add_argument("--output_folder", type=str, required=True)
    parser.add_argument("--translator_checkpoint", type=str, required=True)
    parser.add_argument("--translator_dict_folder", type=str, required=True)
    parser.add_argument("--translator_splitter", type=str, required=True)
    parser.add_argument("--translator_splitter_type", type=str, choices=["id", "str"], default="str")
    parser.add_argument("--search_length_penalty_alpha", type=float, default=1.0)
    parser.add_argument("--model_special_token_src_end_prefix", type=str, default="[endprefix]")
    parser.add_argument("--model_special_token_src_brk", type=str, default="[BRK]")
    parser.add_argument("--model_special_token_src_sep", type=str, default="")
    parser.add_argument("--model_special_token_src_doc", type=str, default="[DOC]")
    parser.add_argument("--model_special_token_src_cont", type=str, default="[CONT]")
    parser.add_argument("--model_special_token_src_end", type=str, default="[END]")

    parser.add_argument("--model_special_token_tgt_doc", type=str, default="[DOC]")
    parser.add_argument("--model_special_token_tgt_cont", type=str, default="[CONT]")

    parser.add_argument("--max_forced_read_actions_before_fallback", type=int, default=-1,
                        help="The model fallbacks to sentence level translation if this consecutive number of forced"
                             "read operation is exceed. Values <= 0 disables this behaviour.")
    parser.add_argument("--block_repeated_ngrams_order", type=int, default=0,
                        help="If > 0, n-grams that have already appeared on the hypothesis have their score set to 0."
                             "If activated, blocks ngrams of order [block_repeated_ngrams_order]."
                             "Therefore, the lower the n-gram order, the more aggressive the pruning.")
    parser.add_argument("--beam_size", type=int, default=4,
                        help="Beam size for speculative beam search.")
    parser.add_argument("--src_history_max_len", type=int, default=60)
    parser.add_argument("--tgt_history_max_len", type=int, default=60)
    parser.add_argument("--k", type=int, default=4)
    parser.add_argument("--catchup", type=float, default=1.0)
    parser.add_argument("--log", type=str, default="INFO", choices=["INFO", "DEBUG", "WARNING", "ERROR", "CRITICAL"])

    args = parser.parse_args(unknown_args)

    os.makedirs(args.output_folder, exist_ok=False)

    numeric_log_level = getattr(logging, args.log.upper())
    logging.basicConfig(filename=args.output_folder + "/translation.log", level=numeric_log_level)

    special_tokens = SpecialTokens(src_end_of_prefix=args.model_special_token_src_end_prefix,
                                   src_brk=args.model_special_token_src_brk, src_sep=args.model_special_token_src_sep,
                                   src_doc=args.model_special_token_src_doc,
                                   src_cont=args.model_special_token_src_cont,
                                   src_end=args.model_special_token_src_end,
                                   tgt_doc=args.model_special_token_tgt_doc, tgt_cont=args.model_special_token_tgt_cont)

    translation_model = FairseqTranslationModel(model_path=args.translator_checkpoint,
                                                data_bin_path=args.translator_dict_folder,
                                                search_length_penalty_alpha=args.search_length_penalty_alpha,
                                                block_ngrams_order=args.block_repeated_ngrams_order,
                                                special_tokens=special_tokens,
                                                beam_size=args.beam_size)

    if args.translator_splitter_type == "str":
        splitter_model = SentencePieceModelWordSplitterPieceInput(args.translator_splitter)
    elif args.translator_splitter_type == "id":
        splitter_model = SentencePieceModelWordSplitterIdInput(args.translator_splitter)
    else:
        raise Exception

    if known_args.agent_type == TranslateThenRealignAgent.name:
        feature_scorer = load_feature_score_from_json(json_path=args.feature_scorer)
        o_agent = TranslateThenRealignAgent(states=TranslationState(), translation_model=translation_model,
                                            feature_scorer=feature_scorer, src_splitter=splitter_model,
                                            tgt_splitter=splitter_model,
                                            src_history_max_len=args.src_history_max_len,
                                            tgt_history_max_len=args.tgt_history_max_len, k=args.k,
                                            catchup=args.catchup,
                                            max_forced_read_actions_before_fallback=args.max_forced_read_actions_before_fallback)
    elif known_args.agent_type == DsSegmenterAgent.name:

        segmenter_model, segmenter_vocab, loaded_model_args = load_text_model(args.segmenter_checkpoint)
        assert loaded_model_args.n_classes == 2

        segmenter_sample_max_len = loaded_model_args.sample_max_len
        segmenter_sample_window_size = loaded_model_args.sample_window_size

        segmenter_model = segmenter_model.to(torch.device('cuda'))

        segmenter = DsSegmenter(segmenter_model=segmenter_model, segmenter_vocab_dictionary=segmenter_vocab,
                                max_segment_length=85, sample_max_len=segmenter_sample_max_len,
                                sample_window_size=segmenter_sample_window_size)
        o_agent = DsSegmenterAgent(states=TranslationState(), translation_model=translation_model,
                                   segmenter=segmenter, src_splitter=splitter_model,
                                   tgt_splitter=splitter_model,
                                   src_history_max_len=args.src_history_max_len,
                                   tgt_history_max_len=args.tgt_history_max_len, k=args.k,
                                   catchup=args.catchup,
                                   max_forced_read_actions_before_fallback=args.max_forced_read_actions_before_fallback)

    elif known_args.agent_type == DsSegmenterOracleAgent.name:
        oracle_segmenter = OracleSegmenter(sample_window_size=args.oracle_segmenter_window)
        o_agent = DsSegmenterOracleAgent(states=TranslationState(), translation_model=translation_model,
                                         segmenter=oracle_segmenter, src_splitter=splitter_model,
                                         tgt_splitter=splitter_model,
                                         src_history_max_len=args.src_history_max_len,
                                         tgt_history_max_len=args.tgt_history_max_len, k=args.k,
                                         catchup=args.catchup,
                                         max_forced_read_actions_before_fallback=args.max_forced_read_actions_before_fallback)

    elif known_args.agent_type == SlidingWindowAgent.name:
        o_agent = SlidingWindowAgent(states=TranslationState(), translation_model=translation_model,
                                   src_splitter=splitter_model,
                                   tgt_splitter=splitter_model,
                                   window_length=args.window_length,
                                   threshold=args.threshold,
                                     k=None,
                                     catchup=None,
                                     max_forced_read_actions_before_fallback=None,
                                     src_history_max_len=None,
                                     tgt_history_max_len=None)
    else:
        raise Exception

    translator = Translator(o_agent)

    if known_args.agent_type == SlidingWindowAgent.name:
        translator.translate_main(src_files=args.input_files, output_dir=args.output_folder, use_sliding_windows=True)
    else:
        translator.translate_main(src_files=args.input_files, output_dir=args.output_folder, use_sliding_windows=False)


if __name__ == "__main__":
    main_cli()
