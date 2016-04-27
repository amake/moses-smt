#!/bin/sh

mkdir -p ${WORKING_DIR}/tune
cd ${WORKING_DIR}/tune
tmx2corpus ${TUNE_TMX_DIR}

# # Tokenize
# /mosesdecoder/scripts/tokenizer/tokenizer.perl -l ${SOURCE_LANG} \
# 	< ${WORKING_DIR}/tune/bitext.${SOURCE_LANG} \
# 	> ${WORKING_DIR}/tune/bitext.tok.${SOURCE_LANG}
# /mosesdecoder/scripts/tokenizer/tokenizer.perl -l ${TARGET_LANG} \
# 	< ${WORKING_DIR}/tune/bitext.${TARGET_LANG} \
# 	> ${WORKING_DIR}/tune/bitext.tok.${TARGET_LANG}

# Tune
/mosesdecoder/scripts/training/mert-moses.pl \
	${WORKING_DIR}/tune/bitext.tok.${SOURCE_LANG} \
    ${WORKING_DIR}/tune/bitext.tok.${TARGET_LANG} \
	/mosesdecoder/bin/moses ${WORKING_DIR}/train/model/moses.ini \
    --mertdir /mosesdecoder/bin/ \
	--decoder-flags="-threads $(nproc)" > mert.out

