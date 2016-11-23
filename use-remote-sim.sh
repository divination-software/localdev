#!/usr/bin/env bash
# Use remote copy of sim instead.

echo "=> Stopping docker"
docker-compose -f server/docker-compose.dev.yml stop

echo "=> Creating symbolic link to remote sim repo"
if [ -L sim ]; then
  rm sim
fi
ln -s remote-sim sim

echo ""
echo "Run build-and-compose-images.sh to restart docker with your new configuration."
