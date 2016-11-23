#!/usr/bin/env bash
# Use local copy of server instead of the cloned repo. Useful for testing new
# features.

echo "=> Stopping docker"
docker-compose -f server/docker-compose.dev.yml stop

echo "=> Creating symbolic link to local server repo"
if [ -L server ]; then
  rm server
fi
ln -s ../server server

echo ""
echo "Run build-and-compose-images.sh to restart docker with your new configuration."
