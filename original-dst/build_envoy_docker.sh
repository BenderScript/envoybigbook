# Enable exit on non 0
set -e

. clean_envoy_docker.sh

if [ -z "${ENVOY_PORT}" ]; then
  PORT=4999
else
  PORT="${ENVOY_PORT}"
fi

if [ -z "${ENVOY_ADMIN_PORT}" ]; then
  ADMIN_PORT=19000
else
  ADMIN_PORT="${ENVOY_ADMIN_PORT}"
fi

CONTAINER_NAME=envoy-original-dest
DOCKERFILE=envoy.Dockerfile
ENVOY_FILE=service-envoy.yaml

if [[ "$OSTYPE" == "darwin"* ]]; then
    printf "%s\n" "IPTables support is needed"
    exit 1
fi

docker build -f ${DOCKERFILE} -t ${CONTAINER_NAME} . --build-arg envoy_file="${ENVOY_FILE}"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    EXTRA_FLAGS="--cap-add=NET_ADMIN --network host"
fi

# NULL expansion
# ${EXTRA_FLAGS:-"${EXTRA_FLAGS}"}

DOCKER_COMMAND="docker run -d ${EXTRA_FLAGS:-${EXTRA_FLAGS}} -p \"${PORT}\":\"${PORT}\" -p \"${ADMIN_PORT}\":\"${ADMIN_PORT}\" --name \"${CONTAINER_NAME}\" \"${CONTAINER_NAME}\""

# printf "%s\n" "${DOCKER_COMMAND}"

eval "${DOCKER_COMMAND}"



