# Musl target, either x86_64-linux-musl, aarch64-linux-musl, arm-linux-musleabi, etc.
ARG MUSL_TARGET="x86_64-linux-musl"
# Stockfish target, e.g. x86-64-modern or armv8
ARG STOCKFISH_TARGET="x86-64-avx2"

FROM docker.io/amd64/alpine:edge AS builder
ARG MUSL_TARGET
ARG STOCKFISH_TARGET

COPY 0001-fix-alpine-linux-stack-size.patch .
COPY server.c .

ENV CXXFLAGS "-static -static-libstdc++ -static-libgcc"
ENV CFLAGS "-static -static-libstdc++ -static-libgcc"

RUN apk upgrade && \
    apk add git make curl

RUN if [ "$MUSL_TARGET" != "x86_64-linux-musl" ]; then \
        curl -L "https://musl.cc/$MUSL_TARGET-cross.tgz" -o /toolchain.tgz && \
        tar xf toolchain.tgz && \
        ln -s "/$MUSL_TARGET-cross/bin/$MUSL_TARGET-g++" "/usr/bin/g++" && \
        ln -s "/$MUSL_TARGET-cross/bin/$MUSL_TARGET-gcc" "/usr/bin/gcc" && \
        ln -s "/$MUSL_TARGET-cross/bin/$MUSL_TARGET-ld" "/usr/bin/$MUSL_TARGET-ld" && \
        ln -s "/$MUSL_TARGET-cross/bin/$MUSL_TARGET-strip" "/usr/bin/actual-strip"; \
    else \
        echo "skipping toolchain as we are native" && \
        apk add gcc g++ musl-dev && \
        ln -s /usr/bin/strip /usr/bin/actual-strip && \
        ln -s /usr/bin/ld "/usr/bin/$MUSL_TARGET-ld" && \
        ln -s /usr/bin/gcc "/usr/bin/$MUSL_TARGET-gcc"; \
    fi

RUN git config --global user.name "Jens Reidel " && \
    git config --global user.email "jens@troet.org" && \
    git clone https://github.com/official-stockfish/Stockfish.git && \
    cd Stockfish/src && \
    git am < /0001-fix-alpine-linux-stack-size.patch && \
    if [ "$MUSL_TARGET" != "x86_64-linux-musl" ]; then \
        make build ARCH=${STOCKFISH_TARGET} -j $(nproc); \
    else \
        make profile-build ARCH=${STOCKFISH_TARGET} -j $(nproc); \
    fi && \
    mv stockfish / && \
    cd .. && \
    rm -rf Stockfish && \
    cd / && \
    ${MUSL_TARGET}-gcc server.c -o run-server -O3 -Ofast -Wno-write-strings -static -flto && \
    actual-strip /run-server && \
    actual-strip /stockfish

FROM scratch

COPY --from=builder /run-server /server
COPY --from=builder /stockfish /stockfish

CMD ["/server"]
