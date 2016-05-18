#!/bin/bash -exu

mkdir -p ${WORK_HOME}/corpus
cd ${WORK_HOME}/corpus

# Truecase
for LANG in $SOURCE_LANG $TARGET_LANG; do
    ${MOSES_HOME}/scripts/recaser/train-truecaser.perl \
                 --model truecase-model.${LANG} \
                 --corpus ${DATA_HOME}/train/bitext.tok.${LANG}
    ${MOSES_HOME}/scripts/recaser/truecase.perl \
                 --model truecase-model.${LANG} \
                 < ${DATA_HOME}/train/bitext.tok.${LANG} \
                 > bitext.true.${LANG}
done

# Clean
${MOSES_HOME}/scripts/training/clean-corpus-n.perl \
	bitext.true ${TARGET_LANG} ${SOURCE_LANG} \
	bitext.clean 1 80

# Make language model
mkdir ${WORK_HOME}/lm
cd ${WORK_HOME}/lm
${MOSES_HOME}/bin/lmplz -o 3 ${TEST_MODE:+--discount_fallback} \
             < ${WORK_HOME}/corpus/bitext.clean.${TARGET_LANG} \
             > bitext.arpa.${TARGET_LANG}
${MOSES_HOME}/bin/build_binary \
	bitext.arpa.${TARGET_LANG} \
	bitext.blm.${TARGET_LANG}

# Train
mkdir ${WORK_HOME}/train
cd ${WORK_HOME}/train
${MOSES_HOME}/scripts/training/train-model.perl -root-dir ${WORK_HOME}/train \
	-corpus ${WORK_HOME}/corpus/bitext.clean \
	-f ${SOURCE_LANG} -e ${TARGET_LANG} \
    -alignment grow-diag-final-and -reordering msd-bidirectional-fe \
	-lm 0:3:${WORK_HOME}/lm/bitext.blm.${TARGET_LANG}:8 \
	-external-bin-dir ${BIN_HOME}/tools -cores $(nproc) > training.out

if [ "${TARGET_LANG}" = "ja" ] || [ "${TARGET_LANG}" = "zh" ] || \
	[ "${SOURCE_LANG}" = "ja" ] || [ "${SOURCE_LANG}" = "zh" ]; then
	echo "For ja or zh: Changing [distortion-limit] to -1 in train/model/moses.ini"
	INI=model/moses.ini
	sed -r '/^\[distortion-limit\]$/{n;s/\S+/-1/}' < ${INI} > ${INI}-temp
	mv ${INI}{-temp,}
fi
