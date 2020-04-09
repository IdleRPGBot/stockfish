FROM alpine:edge

COPY 0001-fix-alpine-linux-stack-size.patch .
COPY 0001-fix-aarch64.patch .

RUN apk add --virtual .deps git make gcc g++ && \
    git config --global user.name "Jens Reidel " && \
    git config --global user.email "jens@troet.org" && \
    git clone https://github.com/official-stockfish/Stockfish.git && \
    cd Stockfish/src && \
    git am < /0001-fix-alpine-linux-stack-size.patch && \
    git am < /0001-fix-aarch64.patch && \
    make profile-build ARCH=aarch64 -j $(nproc)

WORKDIR /Stockfish/src

CMD sleep 20
