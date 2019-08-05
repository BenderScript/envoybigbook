if [[ -z "${ENVOY_PORT}" ]]; then
  PORT=4999
else
  PORT="${ENVOY_PORT}"
fi
docker build -t ext-auth-proxy .
docker run -d -p "${PORT}":"${PORT}" -p 19000:19000 ext-auth-proxy