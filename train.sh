#!/bin/sh

# Generate corpus
mkdir -p ${WORKING_DIR}/corpus
cd ${WORKING_DIR}/corpus
tmx2corpus ${TRAIN_TMX_DIR}

# # Tokenize
# /mosesdecoder/scripts/tokenizer/tokenizer.perl -l ${SOURCE_LANG} \
# 	< ${WORKING_DIR}/corpus/bitext.${SOURCE_LANG} \
# 	> ${WORKING_DIR}/corpus/bitext.tok.${SOURCE_LANG}
# /mosesdecoder/scripts/tokenizer/tokenizer.perl -l ${TARGET_LANG} \
# 	< ${WORKING_DIR}/corpus/bitext.${TARGET_LANG} \
# 	> ${WORKING_DIR}/corpus/bitext.tok.${TARGET_LANG}

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
	-external-bin-dir ${MOSES_TOOLS} -cores $(nproc) > ${WORKING_DIR}/train/training.out

if [ "${TARGET_LANG}" = "ja" ] || [ "${TARGET_LANG}" = "zh" ] || \
	[ "${SOURCE_LANG}" = "ja" ] || [ "${SOURCE_LANG}" = "zh" ]; then
	echo "For ja or zh: Changing [distortion-limit] to -1 in train/model/moses.ini"
	INI=${WORKING_DIR}/train/model/moses.ini
	sed -r '/^\[distortion-limit\]$/{n;s/\S+/-1/}' < ${INI} > ${INI}-temp
	mv ${INI}-temp ${INI}
fi
