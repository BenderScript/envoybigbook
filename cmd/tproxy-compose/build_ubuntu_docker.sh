# Enable exit on non 0
set -e

CONTAINER_NAME=ubuntu-base
DOCKERFILE=ubuntu.Dockerfile

docker build -f ${DOCKERFILE} -t ${CONTAINER_NAME} .
