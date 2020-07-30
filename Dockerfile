FROM docker.io/library/alpine:edge

COPY 0001-fix-alpine-linux-stack-size.patch .
COPY server.rs .

RUN apk upgrade --no-cache && \
    apk add --virtual .fetch --no-cache curl && \
    curl https://ftp.travitia.xyz/alpine/jens@troet.org-5ea01144.rsa.pub -o /etc/apk/keys/jens@troet.org-5ea01144.rsa.pub && \
    echo "https://ftp.travitia.xyz/alpine" >> /etc/apk/repositories && \
    apk add --virtual .deps --no-cache git make gcc g++ rust && \
    git config --global user.name "Jens Reidel " && \
    git config --global user.email "jens@troet.org" && \
    git clone https://github.com/official-stockfish/Stockfish.git && \
    cd Stockfish/src && \
    git am < /0001-fix-alpine-linux-stack-size.patch && \
    make profile-build ARCH=x86-64-modern -j $(nproc) && \
    mv stockfish / && \
    cd .. && \
    rm -rf Stockfish && \
    cd / && \
    rustc -C opt-level=3 server.rs && \
    apk del --no-network .deps && \
    apk add --no-cache libgcc libstdc++ && \
    apk del --no-network .fetch

WORKDIR /

CMD /server
