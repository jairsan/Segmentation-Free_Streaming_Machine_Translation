from segfreetk.agents.sliding_window_agent import SlidingWindowAgent


def test_substring():
    t1 = ["A", "B", "C", "X", "Y", "Z", "A", "Y"]
    t2 = ["X", "Y", "Z", "A", "B", "C", "B"]

    expected = (["X", "Y", "Z", "A"], 3, 0)
    assert SlidingWindowAgent.longest_common_substring_location(text1=t1, text2=t2) == expected

def test_substring2():
    t1 = ['Frau', 'Präsidentin!', 'Der', 'Präsident', 'der', 'Europäischen', 'Zentralbank,', 'Jean-Claude', 'Trichet,', 'sagte', 'kürzlich,', 'als', 'er']
    t2 = ['Frau', 'Präsidentin!', 'Der', 'Präsident', 'der', 'Europäischen', 'Zentralbank,', 'Jean-Claude', 'Trichet,', 'sagte', 'kürzlich,', 'als', 'die', 'Europäische']

    expected = (['Frau', 'Präsidentin!', 'Der', 'Präsident', 'der', 'Europäischen', 'Zentralbank,', 'Jean-Claude', 'Trichet,', 'sagte', 'kürzlich,', 'als'], 0, 0)
    assert SlidingWindowAgent.longest_common_substring_location(text1=t1, text2=t2) == expected

def test_substring3():
    t1 = ["x", "y", "e", "f", "g"]
    t2 = ["a", "b", "c", "d", "e"]

    expected = (["e"], 2, 4)
    assert SlidingWindowAgent.longest_common_substring_location(text1=t1, text2=t2) == expected


def test_apply_merge_indices():
    i = 3
    j = 0
    old_sequence = ["A", "B", "C", "X", "Y", "Z", "A", "Y"]
    new_sequence = ["X", "Y", "Z", "A", "B", "C", "B"]
    match_len = 4

    result = SlidingWindowAgent.apply_merge_indices(i=i, j=j, old_sequence=old_sequence, new_sequence=new_sequence,
                                                    match_len=match_len)

    assert result == ["A", "B", "C", "X", "Y", "Z", "A", "B", "C", "B"]


def test_merge_substring():
    cases = [
        (["a", "d", "b", "c", "p", "r", "q"],
         ["I", "m", "n", "a", "b", "c", "r", "q"],
         ["I", "m", "n", "a", "b", "c", "p", "r", "q"]),
        (["b", "d", "c", "p", "r", "t", "q", "s"],
         ["I", "m", "n", "a", "b", "c", "p", "r", "q"],
         ["I", "m", "n", "a", "b", "c", "p", "r", "t", "q", "s"]),
        (["1", "2"],
         ["a", "b", "c"],
         ["a", "b", "c", "1", "2"]),
        (["x", "y", "e", "f", "g"],
         ["a", "b", "c", "d", "e"],
         ["a", "b", "c", "d", "e", "f", "g"])
    ]

    for new, old, expected in cases:
        match, i, j = SlidingWindowAgent.longest_common_substring_location(text1=old, text2=new)
        result = SlidingWindowAgent.apply_merge_indices(i=i, j=j, old_sequence=old, new_sequence=new, match_len=len(match))
        assert result == expected