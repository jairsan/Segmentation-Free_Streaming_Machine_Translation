import math
from typing import Tuple, Optional

from segfreetk.common.states import TranslationState, HelperStates

from segfreetk.common.constants import READ_ACTION, WRITE_ACTION


def waitk_policy(states: TranslationState, gamma: float, k: int) -> Tuple[int, int]:

    # Waitk policy
    t = len(states.tgt_segments[-1]) + 1
    g_t = math.ceil(k + (t - 1) / gamma)

    words_to_write = 0

    if g_t > len(states.src_segments[-1]):
        # TODO if we detect it is necessary to read more, change return type and update the
        #  Translator.translate_document method
        return READ_ACTION, 1
    else:
        words_to_write += 1

        t += 1
        g_t = math.ceil(k + (t - 1) / gamma)

        while len(states.src_segments[-1]) >= g_t:
            words_to_write += 1
            t += 1
            g_t = math.ceil(k + (t - 1) / gamma)

        return WRITE_ACTION, words_to_write


