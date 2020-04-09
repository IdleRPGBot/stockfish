#!/usr/bin/env bash
podman build -t stockfish:latest . --no-cache
podman run -d --rm --name stockfish stockfish:latest
podman cp --pause=false stockfish:/Stockfish/src/stockfish .
podman cp --pause=false stockfish:/vajolet/Vajolet .
