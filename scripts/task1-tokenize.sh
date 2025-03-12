#!/bin/bash
# export LC_ALL=en_US.UTF_8  # Commented out to avoid locale issue
echo "hello"

# if [ ! -d scripts ]; then
#   echo "You should run this script from the root git folder."
#   exit 1
# fi

# Set path to Moses clone
MOSES="scripts/moses-3a0631a/tokenizer"
export PATH="${MOSES}:$PATH"

# Raw files path
RAW=./data/task1/raw
TOK=./data/task1/tok
PAIRS=./data/task1/pairs
SUFFIX="lc.norm.tok"

# Detect languages from the list of language pairs
LANGS=$(tr '-' '\n' < $PAIRS | sort -u)

# Create the output directory if it doesn't exist
mkdir -p $TOK &> /dev/null

##############################
# Preprocess files in parallel
##############################
for TYPE in "train" "val" "test_2016_flickr" "test_2017_flickr" "test_2017_mscoco"; do
  for LLANG in $LANGS; do
    INP="${RAW}/${TYPE}.${LLANG}.gz"
    OUT="${TOK}/${TYPE}.${SUFFIX}.${LLANG}"
    if [ -f $INP ] && [ ! -f $OUT ]; then
      echo "Processing: ${TYPE}.${LLANG}..."
      zcat $INP | lowercase.perl | normalize-punctuation.perl -l $LLANG | \
          tokenizer.perl -l $LLANG -threads 2 > $OUT &
    fi
  done
done
wait

# Check if all expected output files exist, then display success message
SUCCESS=true
for TYPE in "train" "val" "test_2016_flickr" "test_2017_flickr" "test_2017_mscoco"; do
  for LLANG in $LANGS; do
    OUT="${TOK}/${TYPE}.${SUFFIX}.${LLANG}"
    if [ ! -f $OUT ]; then
      SUCCESS=false
      echo "Error: Missing output file ${OUT}"
    fi
  done
done

if [ "$SUCCESS" = true ]; then
  echo "Tokenization completed successfully!"
else
  echo "Tokenization completed with errors."
fi
