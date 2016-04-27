#!/bin/sh

mkdir -p ${WORKING_DIR}/binary

/mosesdecoder/bin/processPhraseTableMin \
	-in ${WORKING_DIR}/train/model/phrase-table.gz -nscores 4 \
    -out ${WORKING_DIR}/binary/phrase-table
/mosesdecoder/bin/processLexicalTableMin \
	-in ${WORKING_DIR}/train/model/reordering-table.wbe-msd-bidirectional-fe.gz \
	-out ${WORKING_DIR}/binary/reordering-table


ESC_PATH=$(echo ${WORKING_DIR}/binary/ | sed -e 's/\//\\\//g')

sed -r -e 's/(PhraseDictionary)Memory/\1Compact/' \
	-e "s/(path=).*phrase-table\.gz/\1${ESC_PATH}phrase-table/" \
	-e "s/(path=).*reordering-table.*\.gz/\1${ESC_PATH}reordering-table/" \
	< ${WORKING_DIR}/tune/mert-work/moses.ini \
	> ${WORKING_DIR}/binary/moses.ini

