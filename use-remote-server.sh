#!/usr/bin/env bash
# Use remote copy of sim instead of the cloned repo.

echo "=> Stopping docker"
docker-compose -f server/docker-compose.dev.yml stop

echo "=> Creating symbolic link to remote server repo"
if [ -L server ]; then
  rm server
fi
ln -s remote-server server

echo ""
echo "Run build-and-compose-images.sh to restart docker with your new configuration."
