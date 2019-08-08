# Enable exit on non 0
set -e

if [ -z "${ENVOY_PORT}" ]; then
  PORT=4999
else
  PORT="${ENVOY_PORT}"
fi

if [ -z "${ENVOY_HTTPS_PORT}" ]; then
  HTTPS_PORT=8443
else
  HTTPS_PORT="${ENVOY_HTTPS_PORT}"
fi

CONTAINER_NAME=envoy-redirect
DOCKERFILE=envoy.Dockerfile

docker stop ${CONTAINER_NAME} || true
docker rm ${CONTAINER_NAME} || true
docker rmi -f ${CONTAINER_NAME} || true
docker build -f ${DOCKERFILE} -t ${CONTAINER_NAME} .
docker run -d --network host --cap-add NET_ADMIN -p "${PORT}":"${PORT}" -p "${HTTPS_PORT}":"${HTTPS_PORT}" -p 19000:19000 --name ${CONTAINER_NAME} ${CONTAINER_NAME}