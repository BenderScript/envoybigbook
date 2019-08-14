# Enable exit on non 0
set -e

printf "%s\n\n" "Building and running Envoy Docker"
printf "%s"     "================================="

. build_envoy_docker.sh

printf "%s\n" "Starting Web Server"
printf "%s"   "==================="

. run_web_docker.sh

printf "\n\n"
