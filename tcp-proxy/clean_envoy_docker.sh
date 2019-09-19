# Enable exit on non 0
set -e

CONTAINER_NAME=tcp-proxy

docker stop ${CONTAINER_NAME} 2> /dev/null || true
docker rm ${CONTAINER_NAME} 2> /dev/null || true
docker rmi -f ${CONTAINER_NAME} 2> /dev/null || true

# https://stackoverflow.com/questions/15678796/suppress-shell-script-error-messages