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

RUN git clone https://github.com/moses-smt/mosesdecoder.git \
    && cd mosesdecoder \
    && make -f contrib/Makefiles/install-dependencies.gmake \
    && ./compile.sh

RUN git clone https://github.com/moses-smt/giza-pp.git \
    && cd giza-pp \
    && make \
    && mkdir /mosesdecoder/tools \
    && cp GIZA++-v2/GIZA++ GIZA++-v2/snt2cooc.out mkcls-v2/mkcls \
       /mosesdecoder/tools

ENV MOSES_TOOLS /mosesdecoder/tools
ENV LD_LIBRARY_PATH /mosesdecoder/opt/lib

RUN pip install git+https://github.com/amake/tmx2corpus.git

ENV SOURCE_LANG ja
ENV TARGET_LANG en
ENV WORKING_DIR /machinetranslation-${SOURCE_LANG}-${TARGET_LANG}

COPY train.sh /
COPY train /train
ENV TRAIN_TMX_DIR /train
RUN /train.sh

COPY tune.sh /
COPY tune /tune
ENV TUNE_TMX_DIR /tune
RUN /tune.sh

COPY binarize.sh /
RUN /binarize.sh

