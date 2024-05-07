import sys
from subprocess import Popen, PIPE
import logging
import os
from fairseq import search, sequence_generator
from fairseq import checkpoint_utils, utils, tasks
import torch

logging.basicConfig(level=logging.CRITICAL)

os.environ["PYTHONUNBUFFERED"] = "1"

def compute_length_buffer(buf):
    length=0
    for s in buf:
        length+= len(s.split(" "))
    return length

def filter_length( s_buf,t_buf, length_limit):
    while compute_length_buffer(s_buf) > length_limit or compute_length_buffer(t_buf) > length_limit:
        if len(s_buf) > 1:
            s_buf.pop(0)
            t_buf.pop(0)
        else:
            break
    
    return compute_length_buffer(s_buf), compute_length_buffer(t_buf)

def truncate_history(src_buffer, tgt_buffer, max_history_size, history_mode):
    if history_mode == 'strict':
        return [],[]

    elif history_mode == 'truncate':
        return [" ".join(src_buffer[0].split(" ")[-max_history_size:])], [" ".join(tgt_buffer[0].split(" ")[-max_history_size:])]

    else:
        return src_buffer[-1], tgt_buffer[-1]
   
def prepare_buffers(src_buffer, tgt_buffer):
    s_buf_len, t_buf_len = filter_length(src_buffer, tgt_buffer, MAX_HISTORY_SIZE)
    
    if s_buf_len > MAX_HISTORY_SIZE or t_buf_len > MAX_HISTORY_SIZE:
        src_buffer, tgt_buffer = truncate_history(src_buffer, tgt_buffer, MAX_HISTORY_SIZE, HISTORY_MODE)

    return src_buffer, tgt_buffer

def make_history_strings(src_buffer, tgt_buffer, is_start):
    if is_start:
        if ESCAPE_TAGS:
            src_string="&lt;DOC&gt; "
        else:
            src_string="<DOC> "
        tgt_string="&lt;DOC&gt; "
    else:
        if ESCAPE_TAGS:
            src_string="&lt;DOC&gt; "
        else:
            src_string="<CONT> "
        tgt_string="&lt;CONT&gt; "

    src_string = src_string + " ".join(src_buffer)
    tgt_string = tgt_string + " ".join(tgt_buffer)

    return src_string, tgt_string

def get_max_ngram_repeat(sentence):
    """ Return the maximum times an n-gram is repeated"""
    if len(sentence) == 0:
        return 0

    else:
        last_ngram = sentence[0]
        repetitions = 1
        for ngram in sentence[1:]:
            if ngram == last_ngram:
                repetitions += 1

            else:
                last_ngram = ngram
                repetitions = 1

        return repetitions

def reset_history(last_source_sentence, last_target_sentence):
    """Return value: bool. Checks to see if it is needed to reset history"""
    detok_src = last_source_sentence.replace("@@ ", "")
    detok_tgt =  last_target_sentence.replace("@@ ", "")

    MAX_NGRAM_REPEAT = 4

    MIN_SENTENCE_LENGTH_FOR_FILTER = 10
    MIN_CHARACTER_LENGTH_FOR_FILTER = 30
    MIN_LEN_RATIO = 0.4
    MAX_LEN_RATIO = 3


    if get_max_ngram_repeat(last_target_sentence.split()) > MAX_NGRAM_REPEAT or get_max_ngram_repeat(detok_tgt.split()) > MAX_NGRAM_REPEAT:
        return True
    elif len(detok_src.split()) >= MIN_SENTENCE_LENGTH_FOR_FILTER and len(detok_tgt.split())/len(detok_src.split()) < MIN_LEN_RATIO or len(detok_tgt.split())/len(detok_src.split()) > MAX_LEN_RATIO:
        return True
    elif len(list(detok_tgt)) > MIN_CHARACTER_LENGTH_FOR_FILTER and len(list(detok_tgt))/len(list(detok_src)) > MAX_LEN_RATIO or len(list(detok_tgt))/len(list(detok_src)) < MIN_LEN_RATIO:
        return True
    else:
        return False

def load_model(filename, dictionary_folder):
    #args.user_dir = os.path.join(os.path.dirname(__file__), '..', '..')
    #utils.import_user_module(args)
    #filename = args.model_path
    if not os.path.exists(filename):
        raise IOError("Model file not found: {}".format(filename))

    #state = checkpoint_utils.load_checkpoint_to_cpu(filename, json.loads(args.model_overrides))
    state = checkpoint_utils.load_checkpoint_to_cpu(filename)

    saved_args = state["args"]
    saved_args.data = dictionary_folder

    task = tasks.setup_task(saved_args)

    # build model for ensemble
    model = task.build_model(saved_args)
    model.load_state_dict(state["model"], strict=True)
    
    use_cuda = torch.cuda.is_available() #and not args.cpu
    if use_cuda:
        model.cuda()
        #print("Using CUDA")

    # Set dictionary
    dict_src = task.source_dictionary
    dict_tgt = task.target_dictionary

    return model, dict_src, dict_tgt


def generate_sample(source_string, target_string, src_dict, tgt_dict, model):

    src_indices =  torch.reshape(src_dict.encode_line(source_string.split(" "), line_tokenizer=lambda x: x, add_if_not_exist=False, append_eos=True).long(), (1,-1))
    src_lengths = torch.LongTensor([src_indices.shape[1]])
    
    prefix_tokens = torch.reshape(tgt_dict.encode_line(target_string.split(" "), line_tokenizer=lambda x: x, add_if_not_exist=False, append_eos=False).long(), (1,-1))

    use_cuda = torch.cuda.is_available() #and not args.cpu
    if use_cuda:
        src_indices = src_indices.cuda()
        src_lengths = src_lengths.cuda()

    return {'net_input': {
                'src_tokens': src_indices,
                'src_lengths': src_lengths,
            }}, prefix_tokens


def translate(model_checkpoint, dictionary_folder,input_prepro_file, output_file):
    model, src_dict, tgt_dict = load_model(model_checkpoint, dictionary_folder)    



    search_strategy = search.BeamSearch(tgt_dict)

    args={}
    generator = sequence_generator.SequenceGenerator(
    [model],
    tgt_dict,
    beam_size=getattr(args, "beam", 4),
    max_len_a=getattr(args, "max_len_a", 0),
    max_len_b=getattr(args, "max_len_b", 150),
    min_len=getattr(args, "min_len", 1),
    normalize_scores=(not getattr(args, "unnormalized", False)),
    len_penalty=getattr(args, "lenpen", 1),
    unk_penalty=getattr(args, "unkpen", 0),
    temperature=getattr(args, "temperature", 1.0),
    match_source_len=getattr(args, "match_source_len", False),
    no_repeat_ngram_size=getattr(args, "no_repeat_ngram_size", 0),
    search_strategy=search_strategy,
)



    with open(input_prepro_file) as f:
        src_sentences = [r.strip() for r in f]

        
    init_src_history = " ".join(src_sentences[0].split(" ")[:-1])
    source_history = [ init_src_history ]

    sample, _ = generate_sample( "<DOC> " + src_sentences[0], "&lt;DOC&gt;" , src_dict, tgt_dict, model)
    hypos = generator.generate([model], sample)
    #We leave out the EOS and BRK, as well as initial DOC
    translated_string = " ".join( tgt_dict.__getitem__(x) for x in hypos[0][0]["tokens"].tolist()[1:-2])    
    target_history = [translated_string]

    translated_sentences = [translated_string]

    for i in range(1,len(src_sentences)):
        source_history, target_history = prepare_buffers(src_buffer=source_history, tgt_buffer=target_history)
        try:
            start_doc = source_history[0] == init_src_history
        except:
            start_doc = False

        src_context, tgt_context = make_history_strings(source_history, target_history, start_doc)
        sample, prefix_tokens = generate_sample(src_context.strip() + " " + src_sentences[i], tgt_context.strip(), src_dict, tgt_dict, model)
        
        
        

        #hypos = generator.generate([model], sample, prefix_tokens=prefix_tokens)
        hypos = generator.generate([model], sample)

        #We leave out the BRK and EOS
        translated_string = " ".join( tgt_dict.__getitem__(x) for x in hypos[0][0]["tokens"].tolist()[prefix_tokens.shape[1]:-2])
        
        #print(src_context, src_sentences[i], tgt_context, translated_string,sep='\t')       
        #print(translated_string)

        translated_sentences.append(translated_string)

        source_history.append(" ".join(src_sentences[i].split(" ")[:-1]))
        target_history.append(translated_string)
        #print(src_dict.string(sample["net_input"]["src_tokens"],bpe_symbol="@@"), src_dict.string(hypos[0][0]["tokens"], bpe_symbol="@@"))
        #token_indices=hypos[0][0]["tokens"]   
        #print(tgt_dict.string(token_indices))

    with open(output_file, "w") as vf:
        for translation in translated_sentences:
            vf.write(translation+"\n")
if __name__ == "__main__":
    MAX_HISTORY_SIZE=40 #sysarg
    HISTORY_MODE="strict"
    ESCAPE_TAGS=False
    translate(sys.argv[1],sys.argv[2],sys.argv[3], sys.argv[4])
