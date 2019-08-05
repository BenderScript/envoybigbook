if [[ -z "${SIMPLE_PORT}" ]]; then
  PORT=5000
else
  PORT="${SIMPLE_PORT}"
fi
docker build -t simple-server .
docker run -d -p "${PORT}":"${PORT}" -name simple-server