#!/usr/bin/env bash
# Use local copy of sim instead of the cloned repo. Useful for testing new
# features.

echo "=> Stopping docker"
docker-compose -f server/docker-compose.dev.yml stop

echo "=> Creating symbolic link to local sim repo"
if [ -L sim ]; then
  rm sim
fi
ln -s ../sim sim

echo ""
echo "Run build-and-compose-images.sh to restart docker with your new configuration."
