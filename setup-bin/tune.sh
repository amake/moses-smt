#!/bin/bash -exu

mkdir -p ${WORK_HOME}/tune
cd ${WORK_HOME}/tune

# Tune
${MOSES_HOME}/scripts/training/mert-moses.pl \
	${DATA_HOME}/tune/bitext.tok.${SOURCE_LANG} \
    ${DATA_HOME}/tune/bitext.tok.${TARGET_LANG} \
	${MOSES_HOME}/bin/moses ${WORK_HOME}/train/model/moses.ini \
    --mertdir ${MOSES_HOME}/bin/ \
	--decoder-flags="-threads $(nproc)" > ${WORK_HOME}/tune/mert.out
