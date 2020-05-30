FROM alpine:edge

COPY 0001-fix-alpine-linux-stack-size.patch .
COPY 0001-fix-aarch64.patch .

RUN apk add --virtual .fetch --no-cache curl && \
    curl https://ftp.travitia.xyz/alpine/jens@troet.org-5ea01144.rsa.pub -o /etc/apk/keys/jens@troet.org-5ea01144.rsa.pub && \
    echo "https://ftp.travitia.xyz/alpine" >> /etc/apk/repositories && \
    apk add --virtual .deps --no-cache git make gcc g++ && \
    git config --global user.name "Jens Reidel " && \
    git config --global user.email "jens@troet.org" && \
    git clone https://github.com/official-stockfish/Stockfish.git && \
    cd Stockfish/src && \
    git am < /0001-fix-alpine-linux-stack-size.patch && \
    git am < /0001-fix-aarch64.patch && \
    export LDFLAGS="-static" && \
    make profile-build ARCH=aarch64 -j $(nproc) && \
    mv stockfish / && \
    cd .. && \
    rm -rf Stockfish && \
    apk del --no-network .deps .fetch && \
    apk add --no-cache netcat-openbsd bash

WORKDIR /

COPY entrypoint .

RUN chmod +x entrypoint

ENTRYPOINT ./entrypoint
