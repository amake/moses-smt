#!/bin/sh

set -e

mkdir -p ${WORK_HOME}/binary

${MOSES_HOME}/mosesdecoder/bin/processPhraseTableMin \
	-in ${WORK_HOME}/train/model/phrase-table.gz -nscores 4 \
    -out ${WORK_HOME}/binary/phrase-table
${MOSES_HOME}/mosesdecoder/bin/processLexicalTableMin \
	-in ${WORK_HOME}/train/model/reordering-table.wbe-msd-bidirectional-fe.gz \
	-out ${WORK_HOME}/binary/reordering-table


ESC_PATH=$(echo ${WORK_HOME}/binary/ | sed -e 's/\//\\\//g')

sed -r -e 's/(PhraseDictionary)Memory/\1Compact/' \
	-e "s/(path=).*phrase-table\.gz/\1${ESC_PATH}phrase-table/" \
	-e "s/(path=).*reordering-table.*\.gz/\1${ESC_PATH}reordering-table/" \
	< ${WORK_HOME}/tune/mert-work/moses.ini \
	> ${WORK_HOME}/binary/moses.ini
