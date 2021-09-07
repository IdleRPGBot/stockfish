# Rust syntax target, either x86_64-unknown-linux-musl, aarch64-unknown-linux-musl, arm-unknown-linux-musleabi etc.
ARG RUST_TARGET="x86_64-unknown-linux-musl"
# Musl target, either x86_64-linux-musl, aarch64-linux-musl, arm-linux-musleabi, etc.
ARG MUSL_TARGET="x86_64-linux-musl"
# Stockfish target, e.g. x86-64-modern or armv8
ARG STOCKFISH_TARGET="x86-64-modern"

FROM docker.io/library/alpine:edge AS builder
ARG MUSL_TARGET
ARG RUST_TARGET
ARG STOCKFISH_TARGET
ENV RUSTFLAGS="-Lnative=/usr/lib"

COPY 0001-fix-alpine-linux-stack-size.patch /
COPY ./server/ /server/

ENV CXXFLAGS "-static -static-libstdc++ -static-libgcc"
ENV CFLAGS "-static -static-libstdc++ -static-libgcc"

RUN apk upgrade && \
    apk add curl libgcc git make && \
    curl -sSf https://sh.rustup.rs | sh -s -- --profile minimal --default-toolchain nightly --component rust-src -y

RUN source $HOME/.cargo/env && \
    if [ "$RUST_TARGET" != $(rustup target list --installed) ]; then \
        rustup target add $RUST_TARGET && \
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
        ln -s /usr/bin/ld "/usr/bin/$MUSL_TARGET-ld"; \
    fi

RUN source $HOME/.cargo/env && \
    git config --global user.name "Jens Reidel " && \
    git config --global user.email "jens@troet.org" && \
    git clone https://github.com/official-stockfish/Stockfish.git && \
    cd Stockfish/src && \
    git am < /0001-fix-alpine-linux-stack-size.patch && \
    if [ "2" == $(rustup target list --installed | wc -l) ]; then \
        make build ARCH=${STOCKFISH_TARGET} -j $(nproc); \
    else \
        make profile-build ARCH=${STOCKFISH_TARGET} -j $(nproc); \
    fi && \
    mv stockfish / && \
    cd .. && \
    rm -rf Stockfish && \
    cd /server && \
    cargo build --release --target=$RUST_TARGET && \
    cp target/$RUST_TARGET/release/server /run-server && \
    actual-strip /run-server

FROM scratch

COPY --from=builder /run-server /server
COPY --from=builder /stockfish /stockfish

CMD ["./server"]
