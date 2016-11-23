#!/usr/bin/env bash
# Build and compose docker images

function gen_ssl_cert {
  # ref: http://crohr.me/journal/2014/generate-self-signed-ssl-certificate-without-prompt-noninteractive-mode.html
  openssl genrsa -des3 -passout pass:x -out server.pass.key 2048
  openssl rsa -passin pass:x -in server.pass.key -out server.key
  rm server.pass.key
  openssl req -new -key server.key -out server.csr \
    -subj "/C=UK/ST=Warwickshire/L=Leamington/O=OrgName/OU=IT Department/CN=example.com"
  openssl x509 -req -days 365 -in server.csr -signkey client-key.pem -out client-cert.pem
}

# 1. Build the images
# 2. Run docker-compose
# 3. Open the browser


# 1. Build the images
# Sim
cd sim
if [[ ! -f "client-key.pem" && ! -f "client-cert.pem" ]]; then
  echo "=> Generating SSL Certificate for sim"
  gen_ssl_cert >/dev/null 2>&1
fi
echo "=> Building docker image for sim"
docker build -t divination-software/sim:dev . >/dev/null 2>&1
cd ..

# Server
cd server
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

echo "=> Building docker image for server"
docker build -t divination-software/server:dev . >/dev/null 2>&1


# 2. Run docker-compose
echo "=> Composing server and sim docker images"
docker-compose -f docker-compose.dev.yml up -d >/dev/null 2>&1
cd ..


# 3. Open the browser
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
echo "Docker images are composed and running!"
echo ""
echo "Check it out at: $LOCALDEV_URL"
echo ""
echo "Useful Docker commands:"
echo "  Stop the cluster:"
echo "    docker-compose -f server/docker-compose.dev.yml stop"
echo ""
echo "  Remove the cluster:"
echo "    docker-compose -f server/docker-compose.dev.yml down"
echo ""
echo "  Show the containers' log data:"
echo "    docker-compose -f server/docker-compose.dev.yml logs"
echo ""
echo "  Show the containers' status:"
echo "    docker-compose -f server/docker-compose.dev.yml ps"

