# Enable exit on non 0
set -e

. clean_envoy_docker.sh

CONTAINER_NAME=curl-ubuntu
DOCKERFILE=curl.Dockerfile

docker build -f ${DOCKERFILE} -t ${CONTAINER_NAME} .
docker run -d -it --user 1000:1000 --name ${CONTAINER_NAME} ${CONTAINER_NAME}