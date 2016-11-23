#!/usr/bin/env bash
# One-click build script for locally-hosted Divination

# ref: http://stackoverflow.com/a/246128
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

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
# 2. Ensure we have a local copy of the server and sim repos
# 3. Build the images
# 4. Open the browser
# 5. Run docker-compose


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

# 2. Ensure we have a local copy of the server and sim repos
cd ..
if [ ! -d "$SOURCE_DIR/../sim" ]; then
  echo "Couldn't find sim repository. Ensure $(pwd)/sim exists."
  exit 1
fi
if [ ! -d "$SOURCE_DIR/../server" ]; then
  echo "Couldn't find server repository. Ensure $(pwd)/server exists."
  exit 1
fi

# 3. Build the images
cd "$SOURCE_DIR/../server"
echo "=> Destroying pre-existing images"
docker-compose -f docker-compose.dev.yml down >/dev/null 2>&1

# Sim
cd "$SOURCE_DIR/../sim"
if [[ ! -f "client-key.pem" && ! -f "client-cert.pem" ]]; then
  echo "=> Generating SSL Certificate for sim"
  gen_ssl_cert >/dev/null 2>&1
fi
echo "=> Building docker image for sim"
docker build -t divinationsoftware/sim:dev . >/dev/null 2>&1

# Server
cd "$SOURCE_DIR/../server"
if [[ ! -f "client-key.pem" && ! -f "client-cert.pem" ]]; then
  echo "=> Generating SSL Certificate for server"
  gen_ssl_cert >/dev/null 2>&1
fi

echo "=> Installing server dependencies (this may take a while)"
yarn >/dev/null 2>&1 || npm install >/dev/null 2>&1

echo "=> Running webpack"
# Disable watch if it's active in the webpack config
sed -i.bak 's/watch: true/watch: false/' webpack.config.js
webpack >/dev/null 2>&1
# Restore webpack config
mv webpack.config.js.bak webpack.config.js

echo "=> Building docker image for server"
docker build -t divinationsoftware/server:dev -f Dockerfile.dev . >/dev/null 2>&1


# 4. Open the browser
echo "=> Opening browser"
LOCALDEV_URL="https://localhost:8080"
if [[ "$(uname -s)" == "Darwin" ]]; then
  # You're running a Mac
  open "$LOCALDEV_URL"
elif [[ "$(uname -s)" == "Linux" ]]; then
  # You're running a some Linux distro
  xdg-open "$LOCALDEV_URL"
fi

echo ""
echo ""
echo "Docker images are being composed now!"
echo ""
echo "Check it out at: $LOCALDEV_URL"
echo ""


# 5. Run docker-compose
echo "=> Composing server and sim docker images"
docker-compose -f docker-compose.dev.yml up
