FROM moses

ARG source
ARG target
ENV SOURCE_LANG $source
ENV TARGET_LANG $target

ENV DATA_HOME=$HOME/data
ENV WORK_HOME=$HOME/work

COPY setup-bin/*.sh $DATA_HOME/
COPY train-corpus $DATA_HOME/train/
COPY tune-corpus $DATA_HOME/tune/

USER root
RUN chown -R moses:moses $DATA_HOME
USER moses

RUN $DATA_HOME/train.sh \
    && $DATA_HOME/tune.sh \
    && $DATA_HOME/binarize.sh \
    && rm -rf $WORK_HOME/{corpus,train,tune}

EXPOSE 8080
CMD exec ${MOSES_HOME}/bin/mosesserver \
    -f ${WORK_HOME}/binary/moses.ini
