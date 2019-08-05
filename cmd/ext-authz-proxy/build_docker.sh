if [[ -z "${AUTHZ_PORT}" ]]; then
  PORT=5010
else
  PORT="${AUTHZ_PORT}"
fi
docker build -t ext-auth-proxy .
docker run -d -p "${PORT}":"${PORT}" -p 19000:19000 ext-auth-proxy