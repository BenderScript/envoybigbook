docker build -t simple-server .
docker run -d -p 5000:5000 -name simple-server