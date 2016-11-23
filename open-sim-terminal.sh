#!/usr/bin/env bash
# Open a terminal to the sim container

CONTAINER_ID=$(docker ps | grep 'divinationsoftware/sim' | awk '{print $1}')
docker exec -it "$CONTAINER_ID" /bin/bash
