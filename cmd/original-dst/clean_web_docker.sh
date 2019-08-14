# Enable exit on non 0
set -e

CONTAINER_NAME=httpbin
IMAGE_NAME=kennethreitz/httpbin

docker stop ${CONTAINER_NAME} || true
docker rm ${CONTAINER_NAME} || true
# docker rmi -f ${IMAGE_NAME} || true