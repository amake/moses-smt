#!/bin/sh

export SOURCE_LANG=en
export TARGET_LANG=ja

CORPI=(train
       tune)

for CORPUS in ${CORPI[@]}; do
    [ -d $CORPUS-corpus ] && mv $CORPUS-corpus{,-tmp}
    mkdir $CORPUS-corpus
    echo "foo bar baz" > $CORPUS-corpus/bitext.tok.$SOURCE_LANG
    echo "ほげ ふが ぴよ" > $CORPUS-corpus/bitext.tok.$TARGET_LANG
done

make train run LABEL=test TEST_MODE=true

for CORPUS in ${CORPI[@]}; do
    rm -rf ./$CORPUS-corpus
    [ -d $CORPUS-corpus-tmp ] && mv $CORPUS-corpus{-tmp,}
done

