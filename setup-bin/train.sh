#!/bin/bash -exu

mkdir -p ${WORK_HOME}/corpus
cd ${WORK_HOME}/corpus

# Clean
${MOSES_HOME}/scripts/training/clean-corpus-n.perl \
	${DATA_HOME}/train/bitext.tok ${TARGET_LANG} ${SOURCE_LANG} \
	${WORK_HOME}/corpus/bitext.clean 1 80

# Make language model
mkdir ${WORK_HOME}/lm
cd ${WORK_HOME}/lm
${MOSES_HOME}/bin/lmplz -o 3 \
             < ${WORK_HOME}/corpus/bitext.clean.${TARGET_LANG} \
             > ${WORK_HOME}/lm/bitext.arpa.${TARGET_LANG}
${MOSES_HOME}/bin/build_binary \
	${WORK_HOME}/lm/bitext.arpa.${TARGET_LANG} \
	${WORK_HOME}/lm/bitext.blm.${TARGET_LANG}

# Train
mkdir ${WORK_HOME}/train
cd ${WORK_HOME}/train
${MOSES_HOME}/scripts/training/train-model.perl -root-dir ${WORK_HOME}/train \
	-corpus ${WORK_HOME}/corpus/bitext.clean \
	-f ${SOURCE_LANG} -e ${TARGET_LANG} -alignment grow-diag-final-and -reordering msd-bidirectional-fe \
	-lm 0:3:${WORK_HOME}/lm/bitext.blm.${TARGET_LANG}:8 \
	-external-bin-dir ${BIN_HOME}/tools -cores $(nproc) > ${WORK_HOME}/train/training.out

if [ "${TARGET_LANG}" = "ja" ] || [ "${TARGET_LANG}" = "zh" ] || \
	[ "${SOURCE_LANG}" = "ja" ] || [ "${SOURCE_LANG}" = "zh" ]; then
	echo "For ja or zh: Changing [distortion-limit] to -1 in train/model/moses.ini"
	INI=${WORK_HOME}/train/model/moses.ini
	sed -r '/^\[distortion-limit\]$/{n;s/\S+/-1/}' < ${INI} > ${INI}-temp
	mv ${INI}-temp ${INI}
fi
