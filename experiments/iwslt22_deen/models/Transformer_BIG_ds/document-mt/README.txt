This folder contains useful scripts for doing document-level (AKA streaming) sim MT.

- convert_doc_format_to_sentences_history_length_limited_V2.py: Given documents in doc-level format (a sentence with this exact content "</DOC>\n" acts as document separator), produces
    consistent streaming samples. If you want to do segmentation-free translation, you must post-process the src side of the data later.

Archive:
Misc code that has been used at some point, but that might be outdated
