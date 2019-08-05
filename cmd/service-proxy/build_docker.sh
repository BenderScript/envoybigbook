docker build -t service-envoy .
docker run -d -p 4999:4999 -p 19000:19000 service-envoy