FROM amake/moses-smt:base

RUN useradd --user-group --create-home --shell /bin/false moses

ARG source
ARG target
ENV SOURCE_LANG $source
ENV TARGET_LANG $target

ARG test
ENV TEST_MODE $test

ENV HOME=/home/moses
ENV DATA_HOME=$HOME/data
ENV WORK_HOME=$HOME/work

COPY setup-bin/*.sh $DATA_HOME/
COPY train-corpus $DATA_HOME/train/
COPY tune-corpus $DATA_HOME/tune/

RUN chown -R moses:moses $DATA_HOME
USER moses

RUN $DATA_HOME/train.sh \
    && $DATA_HOME/tune.sh \
    && $DATA_HOME/binarize.sh \
    && /bin/bash -c "rm -rf $WORK_HOME/{corpus,train,tune}"

EXPOSE 8080
CMD exec ${MOSES_HOME}/bin/mosesserver \
    -f ${WORK_HOME}/binary/moses.ini
