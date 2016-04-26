#!/bin/sh

WORKING_DIR=/machinetranslation-${SOURCE_LANG}-${TARGET_LANG}
SCRIPT_DIR=$(dirname $(readlink -f $0))
MT_TMX_DIR=/tmx

if [ ! -d ${MT_TMX_DIR} ]; then
	echo "Place some training TMXs in ${MT_TMX_DIR} and try again."
	echo "Remember to leave at least one out for tuning."
	exit 1
fi

# Generate corpus
mkdir -p ${WORKING_DIR}/corpus

cd ${WORKING_DIR}/corpus
tmx2corpus ${MT_TMX_DIR}
if [ -f bitext.tok.${TARGET_LANG} ]; then
	mv bitext.${TARGET_LANG} bitext.${TARGET_LANG}-raw
	mv bitext.tok.${TARGET_LANG} bitext.${TARGET_LANG}
fi

# Tokenize
/mosesdecoder/scripts/tokenizer/tokenizer.perl -l ${SOURCE_LANG} \
	< ${WORKING_DIR}/corpus/bitext.${SOURCE_LANG} \
	> ${WORKING_DIR}/corpus/bitext.tok.${SOURCE_LANG}
/mosesdecoder/scripts/tokenizer/tokenizer.perl -l ${TARGET_LANG} \
	< ${WORKING_DIR}/corpus/bitext.${TARGET_LANG} \
	> ${WORKING_DIR}/corpus/bitext.tok.${TARGET_LANG}

# Clean
/mosesdecoder/scripts/training/clean-corpus-n.perl \
	${WORKING_DIR}/corpus/bitext.tok ${TARGET_LANG} ${SOURCE_LANG} \
	${WORKING_DIR}/corpus/bitext.clean 1 80

# Make language model
mkdir ${WORKING_DIR}/lm
/mosesdecoder/bin/lmplz -o 3 \
                        < ${WORKING_DIR}/corpus/bitext.clean.${TARGET_LANG} \
                        > ${WORKING_DIR}/lm/bitext.arpa.${TARGET_LANG}
/mosesdecoder/bin/build_binary \
	${WORKING_DIR}/lm/bitext.arpa.${TARGET_LANG} \
	${WORKING_DIR}/lm/bitext.blm.${TARGET_LANG}

# Train
mkdir ${WORKING_DIR}/train
/mosesdecoder/scripts/training/train-model.perl -root-dir ${WORKING_DIR}/train \
	-corpus ${WORKING_DIR}/corpus/bitext.clean \
	-f ${SOURCE_LANG} -e ${TARGET_LANG} -alignment grow-diag-final-and -reordering msd-bidirectional-fe \
	-lm 0:3:${WORKING_DIR}/lm/bitext.blm.${TARGET_LANG}:8 \
	-external-bin-dir /mosesdecoder/tools -cores $(nproc) > ${WORKING_DIR}/train/training.out

if [ "${TARGET_LANG}" = "ja" ] || [ "${TARGET_LANG}" = "zh" ] || \
	[ "${SOURCE_LANG}" = "ja" ] || [ "${SOURCE_LANG}" = "zh" ]; then
	echo "For ja or zh: Changing [distortion-limit] to -1 in train/model/moses.ini"
	INI=${WORKING_DIR}/train/model/moses.ini
	sed -r '/^\[distortion-limit\]$/{n;s/\S+/-1/}' < ${INI} > ${INI}-temp
	mv ${INI}-temp ${INI}
fi

