FROM ubuntu:14.04

RUN apt-get update && apt-get install -q -y build-essential \
    git-core \
    pkg-config \
    automake \
    libtool \
    wget \
    zlib1g-dev \
    python-dev \
    libbz2-dev

RUN git clone https://github.com/moses-smt/mosesdecoder.git \
    && cd mosesdecoder \
    && make -f contrib/Makefiles/install-dependencies.gmake \
    && ./compile.sh

RUN git clone https://github.com/moses-smt/giza-pp.git \
    && cd giza-pp \
    && make \
    && cd /mosesdecoder \
    && mkdir tools \
    && cp /giza-pp/GIZA++-v2/GIZA++ /giza-pp/GIZA++-v2/snt2cooc.out \
       /giza-pp/mkcls-v2/mkcls tools
