FROM alpine:edge

RUN apk add --virtual .deps git make gcc g++ && \
    git clone https://github.com/official-stockfish/Stockfish.git && \
    cd Stockfish/src && \
    make build ARCH=x86-64-modern -j $(nproc)

WORKDIR /Stockfish/src

CMD sleep 20
