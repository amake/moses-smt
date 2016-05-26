#!/bin/sh

export SOURCE_LANG=en
export TARGET_LANG=ja
export LABEL=test
WORK_DIR=work/$LABEL-$SOURCE_LANG-$TARGET_LANG

for CORPUS in train tune; do
    mkdir -p $WORK_DIR/corpus-$CORPUS
    echo "foo bar baz" > $WORK_DIR/corpus-$CORPUS/bitext.tok.$SOURCE_LANG
    echo "ほげ ふが ぴよ" > $WORK_DIR/corpus-$CORPUS/bitext.tok.$TARGET_LANG
done

make build run TEST_MODE=true
