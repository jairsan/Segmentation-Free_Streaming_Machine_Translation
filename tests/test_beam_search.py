import math

import torch
from segfreetk.common.incremental_simultaneous_beam_search_V2 import IncrementalSimultaneousBeamSearchV2


class DummyModel:
    def eval(self):
        pass

def test_block_ngram_repeat():

    prev_output_tokens = torch.tensor([[1, 2, 1],
                                       [1, 2, 3]])
    probs = torch.tensor([[-1.38, -1.38, -1.38, -1.38],
                          [-1.38, -1.38, -1.38, -1.38]])

    bs = IncrementalSimultaneousBeamSearchV2(model=DummyModel(), tgt_dict=None, block_ngram_repeat_order=2)
    this_probs = torch.clone(probs)
    bs.block_ngram_repeat(prev_output_tokens=prev_output_tokens, last_l_probs=this_probs)
    assert torch.equal(this_probs, torch.tensor([[-1.38, -1.38, -math.inf, -1.38],
                          [-1.38, -1.38, -1.38, -1.38]]))

    bs = IncrementalSimultaneousBeamSearchV2(model=DummyModel(), tgt_dict=None, block_ngram_repeat_order=1)
    this_probs = torch.clone(probs)
    bs.block_ngram_repeat(prev_output_tokens=prev_output_tokens, last_l_probs=this_probs)
    assert torch.equal(this_probs, torch.tensor([[-1.38, -math.inf, -math.inf, -1.38],
                          [-1.38, -math.inf, -math.inf, -math.inf]]))
