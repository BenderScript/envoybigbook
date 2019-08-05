if [[ -z "${ENVOY_PORT}" ]]; then
  PORT=4999
else
  PORT="${ENVOY_PORT}"
fi
docker build -t simple-proxy .
docker run -d -p "${PORT}":"${PORT}" -p 19000:19000 simple-proxy