FROM ubuntu:14.04
MAINTAINER aaron@madlon-kay.com

ENV BIN_HOME=/opt/bin
ENV MOSES_HOME=$BIN_HOME/moses

WORKDIR $MOSES_HOME

ENV PACKAGES="build-essential \
    git-core \
    pkg-config \
    automake \
    libtool \
    wget \
    zlib1g-dev \
    python-dev \
    libbz2-dev"

RUN apt-get update && apt-get install -q -y $PACKAGES \
    && git clone --depth 1 https://github.com/moses-smt/mosesdecoder.git \
    && cd mosesdecoder \
    && make -f contrib/Makefiles/install-dependencies.gmake \
       PREFIX=${BIN_HOME}/opt \
    && OPT=${BIN_HOME}/opt ./compile.sh --prefix=${MOSES_HOME} \
       --install-scripts \
    && cd - \
    && rm -rf mosesdecoder \
    && git clone --depth 1 https://github.com/moses-smt/giza-pp.git \
    && cd giza-pp \
    && make \
    && mkdir ${BIN_HOME}/tools \
    && cp GIZA++-v2/GIZA++ GIZA++-v2/snt2cooc.out mkcls-v2/mkcls \
       ${BIN_HOME}/tools \
    && cd - \
    && rm -rf giza-pp \
    && apt-get remove -q -y $PACKAGES \
    && apt-get autoremove -q -y

ENV LD_LIBRARY_PATH $BIN_HOME/opt/lib
