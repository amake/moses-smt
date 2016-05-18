#!/bin/bash -exu

mkdir -p ${WORK_HOME}/tune
cd ${WORK_HOME}/tune

# Truecase
for LANG in $SOURCE_LANG $TARGET_LANG; do
    ${MOSES_HOME}/scripts/recaser/train-truecaser.perl \
                 --model truecase-model.${LANG} \
                 --corpus ${DATA_HOME}/tune/bitext.tok.${LANG}
    ${MOSES_HOME}/scripts/recaser/truecase.perl \
                 --model truecase-model.${LANG} \
                 < ${DATA_HOME}/tune/bitext.tok.${LANG} \
                 > bitext.true.${LANG}
done

# Clean
${MOSES_HOME}/scripts/training/clean-corpus-n.perl \
	bitext.true ${TARGET_LANG} ${SOURCE_LANG} \
	bitext.clean 1 80


# Tune
${MOSES_HOME}/scripts/training/mert-moses.pl \
	bitext.clean.${SOURCE_LANG} \
    bitext.clean.${TARGET_LANG} \
	${MOSES_HOME}/bin/moses ${WORK_HOME}/train/model/moses.ini \
    --mertdir ${MOSES_HOME}/bin/ \
	--decoder-flags="-threads $(nproc)" > mert.out
