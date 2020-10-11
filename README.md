# Stockfish image

This is a cluster of files to build a special Docker image for running Stockfish 12.

It ships based on Alpine Linux, has cross compiling support and features a TCP server running on port 4000 that will spawn a new stockfish process for each incoming connection and relay input and output. This allows for a scalable chess engine backend.

Prebuilt images for x86_64 and aarch64 can be found on [quay.io](https://quay.io/repository/gelbpunkt/stockfish).