FROM alpine:3.1
MAINTAINER aaron@madlon-kay.com

ENV BIN_HOME=/opt/bin
ENV MOSES_HOME=$BIN_HOME/moses

WORKDIR $MOSES_HOME

ENV PACKAGES="build-base \
    git \
    pkgconfig \
    automake \
    autoconf \
    libtool \
    wget \
    zlib-dev \
    python-dev \
    bzip2-dev \
    cmake"

RUN apk add ${PACKAGES} python \
    && git clone --depth 1 https://github.com/moses-smt/mosesdecoder.git \
    && cd mosesdecoder \
    && make -f contrib/Makefiles/install-dependencies.gmake PREFIX=/opt \
    && OPT=/opt ./compile.sh --prefix=${MOSES_HOME} --install-scripts \
    && cd - \
    && rm -rf mosesdecoder \
    && git clone --depth 1 https://github.com/moses-smt/mgiza.git \
    && cd mgiza/mgizapp \
    && cmake . \
    && make \
    && make install \
    && mkdir -p ${BIN_HOME}/tools \
    && cp bin/* scripts/merge_alignment.py ${BIN_HOME}/tools \
    && cd - \
    && rm -rf mgiza \
    && apk del ${PACKAGES}

ENV LD_LIBRARY_PATH /opt/lib
