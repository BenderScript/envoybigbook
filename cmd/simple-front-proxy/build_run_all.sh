# Enable exit on non 0
set -e

printf "%s\n" "Building and running Envoy Docker"
printf "%s\n" "================================="

. build_envoy_docker.sh

printf "%s\n" "Starting Web Server"
printf "%s\n" "==================="

. run_web_docker.sh

printf "\n\n"
