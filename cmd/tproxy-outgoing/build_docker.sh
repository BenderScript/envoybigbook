if [[ -z "${ENVOY_PORT}" ]]; then
  PORT=4999
else
  PORT="${ENVOY_PORT}"
fi

CONTAINER_NAME=simple-proxy
DOCKERFILE=envoy.Dockerfile

docker stop ${CONTAINER_NAME} || true
docker rm ${CONTAINER_NAME} || true
docker rmi -f ${CONTAINER_NAME} || true
docker build -f ${DOCKERFILE} -t ${CONTAINER_NAME} .
docker run -d --network host --cap-add NET_ADMIN -p "${PORT}":"${PORT}" -p 19000:19000 --name ${CONTAINER_NAME} ${CONTAINER_NAME}