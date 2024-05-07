from segfreetk.features.load_utils import load_from_json
from segfreetk.features.fairseq_translation_model_scorer_feature import FairseqReverseTranslationModelScorerFeatureWrapper
from segfreetk.common.states import TranslationState
import numpy as np


def test_1():
    feature: FairseqReverseTranslationModelScorerFeatureWrapper = load_from_json("/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/features/fairseq_reverse_scorer/reverse_model_feature.json")

    src = "This is an English sentence"
    tgt = "Dies ist ein englischer Satz."

    states = TranslationState(src_segments=[src.split()], tgt_segments=[tgt.split()])

    results_orig = feature.my_old_score(states=states, helper_states=None)

    result_improved = feature.my_score(states=states, helper_states=None)

    np.testing.assert_allclose(results_orig, result_improved,rtol=0,atol=1e-4)