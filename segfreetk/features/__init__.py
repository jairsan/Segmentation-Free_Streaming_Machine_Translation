from segfreetk.features.fairseq_translation_model_scorer_feature import FairseqReverseTranslationModelScorerFeatureWrapper
from segfreetk.features.fixed_ratio_feature import FixedRatioFeature
from segfreetk.features.direct_count_feature import DirectCountFeature
from segfreetk.features.direct_normal_feature import DirectNormalFeature
from segfreetk.features.length_feature import LengthFeature
from segfreetk.features.normal_regression_feature import SimpleLinearRegressionFeature
from segfreetk.features.normal_regression_linear_models_feature import NormalRegressionLinearModelsFeature
from segfreetk.features.normal_regression_xlm_roberta_feature import XLMRobertaRegressionFeature

STR_TO_CLASS = {
    FairseqReverseTranslationModelScorerFeatureWrapper.name: FairseqReverseTranslationModelScorerFeatureWrapper,
    FixedRatioFeature.name: FixedRatioFeature,
    DirectCountFeature.name: DirectCountFeature,
    DirectNormalFeature.name: DirectNormalFeature,
    LengthFeature.name: LengthFeature,
    SimpleLinearRegressionFeature.name: SimpleLinearRegressionFeature,
    NormalRegressionLinearModelsFeature.name: NormalRegressionLinearModelsFeature,
    XLMRobertaRegressionFeature.name: XLMRobertaRegressionFeature
}
