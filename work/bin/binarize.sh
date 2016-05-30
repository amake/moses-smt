#!/bin/bash -exu

[ -d ${WORK_HOME}/binary ] && rm -rf ${WORK_HOME}/binary
mkdir -p ${WORK_HOME}/binary
cd ${WORK_HOME}/binary

${MOSES_HOME}/bin/processPhraseTableMin \
	-in ${WORK_HOME}/train/model/phrase-table.gz -nscores 4 \
    -out phrase-table
${MOSES_HOME}/bin/processLexicalTableMin \
	-in ${WORK_HOME}/train/model/reordering-table.wbe-msd-bidirectional-fe.gz \
	-out reordering-table

sed -r -e 's/(PhraseDictionary)Memory/\1Compact/' \
	-e "s|(path=).*phrase-table\.gz|\1${WORK_HOME}/binary/phrase-table.minphr|" \
	-e "s|(path=).*reordering-table.*\.gz|\1${WORK_HOME}/binary/reordering-table|" \
	< ${WORK_HOME}/tune/mert-work/moses.ini \
	> moses.ini
