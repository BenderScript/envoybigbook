# Enable exit on non 0
set -e

CONTAINER_NAME=ubuntu-base

docker stop ${CONTAINER_NAME} 2> /dev/null || true
docker rm ${CONTAINER_NAME} 2> /dev/null || true
docker rmi -f ${CONTAINER_NAME} 2> /dev/null || true