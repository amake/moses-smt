FROM ubuntu:14.04

RUN apt-get update && apt-get install -q -y build-essential \
    git-core \
    pkg-config \
    automake \
    libtool \
    wget \
    zlib1g-dev \
    python-dev \
    libbz2-dev \
    python-pip

RUN useradd --user-group --create-home --shell /bin/false moses

ENV HOME=/home/moses

ENV BIN_HOME=$HOME/bin
ENV MOSES_HOME=$BIN_HOME/moses
ENV DATA_HOME=$HOME/data
ENV WORK_HOME=$HOME/work

WORKDIR $MOSES_HOME
RUN chown -R moses:moses $HOME

USER moses

# Build uses multiple cores if available, but this requires
# extra RAM (4 cores: 2 GB)
RUN git clone --depth 1 https://github.com/amake/mosesdecoder.git \
    && cd mosesdecoder \
    && make -f contrib/Makefiles/install-dependencies.gmake \
       PREFIX=${BIN_HOME}/opt \
    && OPT=${BIN_HOME}/opt ./compile.sh --prefix=${MOSES_HOME} \
       --install-scripts \
    && cd - \
    && rm -rf mosesdecoder

RUN git clone --depth 1 https://github.com/moses-smt/giza-pp.git \
    && cd giza-pp \
    && make \
    && mkdir ${BIN_HOME}/tools \
    && cp GIZA++-v2/GIZA++ GIZA++-v2/snt2cooc.out mkcls-v2/mkcls \
       ${BIN_HOME}/tools \
    && cd - \
    && rm -rf giza-pp

RUN pip install --user git+https://github.com/amake/tmx2corpus.git

ENV PATH $HOME/.local/bin:$PATH

ENV LD_LIBRARY_PATH $BIN_HOME/opt/lib

ARG source
ARG target
ENV SOURCE_LANG $source
ENV TARGET_LANG $target

COPY train.sh $DATA_HOME/
COPY train $DATA_HOME/train/
ENV TRAIN_TMX_DIR $DATA_HOME/train

USER root
RUN chown -R moses:moses $DATA_HOME
USER moses

RUN $DATA_HOME/train.sh

COPY tune.sh $DATA_HOME/
COPY tune $DATA_HOME/tune/
ENV TUNE_TMX_DIR $DATA_HOME/tune

USER root
RUN chown -R moses:moses $DATA_HOME
USER moses

RUN $DATA_HOME/tune.sh

COPY binarize.sh $DATA_HOME/

USER root
RUN chown -R moses:moses $DATA_HOME
USER moses

RUN $DATA_HOME/binarize.sh

EXPOSE 8080
CMD exec ${MOSES_HOME}/bin/mosesserver \
    -f ${WORK_HOME}/binary/moses.ini
