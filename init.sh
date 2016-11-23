#!/usr/bin/env bash
# One-click build script for locally-hosted Divination

function gen_ssl_cert {
  # ref: http://crohr.me/journal/2014/generate-self-signed-ssl-certificate-without-prompt-noninteractive-mode.html
  openssl genrsa -des3 -passout pass:x -out server.pass.key 2048
  openssl rsa -passin pass:x -in server.pass.key -out server.key
  rm server.pass.key
  openssl req -new -key server.key -out server.csr \
    -subj "/C=UK/ST=Warwickshire/L=Leamington/O=OrgName/OU=IT Department/CN=example.com"
  openssl x509 -req -days 365 -in server.csr -signkey client-key.pem -out client-cert.pem
}

# 1. Ensure requirements are installed and at the proper version
# 2. Clone (or update our local clone of) the repositories
# 3. Build and compose the images


# 1. Ensure requirements are installed
REQUIREMENTS=(
  'docker'
  'docker-compose'
  'git'
  'openssl'
  'webpack'
  'npm'
)
for req in "${REQUIREMENTS[@]}"; do
  command -v "$req" >/dev/null 2>&1 || { echo >&2 "I require $req but it's not installed.  Aborting."; exit 1; }
done

# 2. Clone (or update our local clone of) the repositories
# Sim
if [ ! -d "sim" ]; then
  echo "=> Cloning sim"
  git clone https://github.com/divination-software/sim.git remote-sim >/dev/null 2>&1
fi
echo "=> Updating sim"
./use-remote-sim.sh
cd sim
git checkout develop >/dev/null 2>&1
git pull origin develop >/dev/null 2>&1
cd ..

# Server
if [ ! -d "server" ]; then
  echo "=> Cloning server"
  git clone https://github.com/divination-software/server.git remote-server >/dev/null 2>&1
fi
./use-remote-server.sh
cd server
echo "=> Updating server"
git checkout develop >/dev/null 2>&1
git pull origin develop >/dev/null 2>&1
cd ..

# 3. Build and compose the images
./build-and-compose-images.sh
