class SpecialTokens:
    def __init__(self, src_doc: str = "[DOC]", tgt_doc: str = "[DOC]", src_cont: str = "[CONT]",
                 tgt_cont: str = "[CONT]", src_sep: str = "", tgt_sep: str = "[SEP]", src_brk: str = "",
                 tgt_brk: str = "[BRK]", src_end: str = "[END]", tgt_end: str = "[END]",
                 src_end_of_prefix: str = "[endprefix]",
                 tgt_end_of_prefix: str = "[EndPrefix]"
                 ):
        self.src_doc = src_doc
        self.tgt_doc = tgt_doc
        self.src_cont = src_cont
        self.tgt_cont = tgt_cont
        self.src_sep = src_sep
        self.tgt_sep = tgt_sep
        self.src_brk = src_brk
        self.tgt_brk = tgt_brk
        self.src_end = src_end
        self.tgt_end = tgt_end
        self.src_end_of_prefix = src_end_of_prefix
        self.tgt_end_of_prefix = tgt_end_of_prefix

        self.all_special_tokens = [self.src_doc, self.tgt_doc, self.src_cont, self.tgt_cont, self.src_sep, self.tgt_sep,
                                   self.src_brk, self.tgt_brk, self.src_end, self.tgt_end, self.src_end_of_prefix,
                                   self.tgt_end_of_prefix]
