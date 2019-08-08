if [[ -z "${SIMPLE_PORT}" ]]; then
  PORT=5000
else
  PORT="${SIMPLE_PORT}"
fi

CONTAINER_NAME=simple-server
DOCKERFILE=server.Dockerfile

docker stop ${CONTAINER_NAME} || true
docker rm ${CONTAINER_NAME} || true
docker rmi -f ${CONTAINER_NAME} || true
docker build -f ${DOCKERFILE} -t ${CONTAINER_NAME} .
docker run -d -p "${PORT}":"${PORT}" -p 19000:19000 --name ${CONTAINER_NAME} ${CONTAINER_NAME}