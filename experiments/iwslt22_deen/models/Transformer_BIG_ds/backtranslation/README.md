# Backtranslations

This directory contains various scripts that implement a basic backtranslation pipeline. 


## Steps
The process of obtaining a backtranslated corpora out of monolingual data is the following:

0. Obtain and filter the monolingual data to your liking. This step is left up to you, and the scripts expect the full monolingual corpus to be in a single file, each sequence in one line.

1. Chunk the monolingual corpus into smaller splits for parallelization.

2. Apply the same preprocessing steps (those that were applied to the parallel corpus) to each split.

3. Translate the contents of each split to obtain synthetic source phrases.

4. Build the corpus in the standard moses format

Here you will find scripts that implement all but the first step. Once the `config_bt.sh` file has been modified simply run each of the steps to obtain the synthetic parallel corpus.

## Important note
The scripts are implemented to produce a backtranslation corpus that will be used to improve
a model in the direction $SOURCE_LANG_PREFIX -> $TARGET_LANG_PREFIX, i.e. if one wishes to
obtain a backtranslation corpus for the French-English pair, using monolingual data in English,
the source and target to be specified in `config_bt.sh` are French and English.
