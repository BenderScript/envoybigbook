# Enable exit on non 0
set -e

printf "%s\n" "Building and running Envoy Docker"

. build_envoy_docker.sh

printf "%s\n" "Starting Web Server"

. run_web_docker.sh