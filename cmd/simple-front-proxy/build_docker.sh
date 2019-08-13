# Enable exit on non 0
set -e

if [ -z "${ENVOY_PORT}" ]; then
  PORT=4999
else
  PORT="${ENVOY_PORT}"
fi

CONTAINER_NAME=simple-proxy
DOCKERFILE=envoy.Dockerfile

. clean_docker.sh

docker build -f ${DOCKERFILE} -t ${CONTAINER_NAME} .
docker run -d --network host -p "${PORT}":"${PORT}" -p 19000:19000 --name ${CONTAINER_NAME} ${CONTAINER_NAME}

