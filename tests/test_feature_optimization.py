from segfreetk.features.feature_weight_optimization import generate_data_from_files
from segfreetk.features.utils import smooth_probabilities

def test_data_generation(tmp_path):
    # tmp_path is automatically filled by Pytest
    src_fp = tmp_path / "data.src"
    tgt_fp = tmp_path / "data.tgt"

    with open(src_fp, "w") as src_f:
        src_f.writelines(["1 2\n", "3 4 5\n", "6 7 8\n"])

    with open(tgt_fp, "w") as tgt_f:
        tgt_f.writelines(["1 2\n", "3 4 5\n", "6 7 8\n"])

    data = generate_data_from_files(src_file=src_fp, tgt_file=tgt_fp, include_next_sentence_prob=0.0,
                                    src_window_size=5, tgt_window_size=5, do_shuffle=False)

    src_segments = [datum[0].src_segments for datum in data]
    tgt_segments = [datum[0].tgt_segments for datum in data]
    labels = [datum[1] for datum in data]

    assert src_segments == [[["1", "2"]], [["1", "2"], ["3", "4", "5"]], [["6", "7", "8"]]]
    assert tgt_segments == [[["1", "2"]], [["1", "2"], ["3", "4", "5"]], [["6", "7", "8"]]]
    assert labels == [1, 2, 2]


def test_smooth_probabilities():
    input_probs = [1.0, 0.0, 0.0]

    result = smooth_probabilities(input_probs, smoothing_factor=0.5)

    assert result == [3/5, 1/5, 1/5]
