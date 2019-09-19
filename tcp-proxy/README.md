# Tutorial

**Tested on Ubuntu 18.04**

In this example of we run a Envoy Proxy as a **plain TCP Proxy** that listens on port 4999 and directs to a server running on port 5000.
 
 The web server runs as a separate container from Envoy so any web server will do as long as it is listening on port 5000. 

## Envoy Docker

Build and run the envoy container. The container runs with *--network host* in order to reach the web server running on the host.

```
./build_envoy_docker.sh
``` 

## Web Server

I normally use [httpbin](http://httpbin.org/) as the Web Server. A reliable, no-hassle, perfect-for-testing web server.

```
./run_web_docker.sh
```

## HTTP Request

Now with the Web Server running repeat the request. It will be processed by the Envoy Proxy container and directed to the web Server

```
curl -v localhost:4999
* Rebuilt URL to: localhost:4999/
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 4999 (#0)
> GET / HTTP/1.1
> Host: localhost:4999
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: gunicorn/19.9.0
< Date: Thu, 19 Sep 2019 17:39:48 GMT
< Connection: keep-alive
< Content-Type: text/html; charset=utf-8
< Content-Length: 9593
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Credentials: true
<
<!DOCTYPE html>
<html lang="en">
```

## Envoy Logs

Envoy Logs from a successful run.

```
[2019-09-19 17:39:39.543][8][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-19 17:39:44.537][8][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-19 17:39:48.513][14][debug][filter] [source/common/tcp_proxy/tcp_proxy.cc:201] [C2] new tcp proxy session
[2019-09-19 17:39:48.513][14][debug][filter] [source/common/tcp_proxy/tcp_proxy.cc:344] [C2] Creating connection to cluster cluster1
[2019-09-19 17:39:48.513][14][debug][pool] [source/common/tcp/conn_pool.cc:82] creating a new connection
[2019-09-19 17:39:48.513][14][debug][pool] [source/common/tcp/conn_pool.cc:362] [C3] connecting
[2019-09-19 17:39:48.513][14][debug][connection] [source/common/network/connection_impl.cc:704] [C3] connecting to 192.168.65.2:5000
[2019-09-19 17:39:48.513][14][debug][connection] [source/common/network/connection_impl.cc:713] [C3] connection in progress
[2019-09-19 17:39:48.513][14][debug][pool] [source/common/tcp/conn_pool.cc:108] queueing request due to no available connections
[2019-09-19 17:39:48.513][14][debug][main] [source/server/connection_handler_impl.cc:280] [C2] new connection
[2019-09-19 17:39:48.514][14][debug][connection] [source/common/network/connection_impl.cc:552] [C3] connected
[2019-09-19 17:39:48.514][14][debug][pool] [source/common/tcp/conn_pool.cc:283] [C3] assigning connection
[2019-09-19 17:39:48.514][14][debug][filter] [source/common/tcp_proxy/tcp_proxy.cc:544] TCP:onUpstreamEvent(), requestedServerName:
[2019-09-19 17:39:48.542][14][debug][connection] [source/common/network/connection_impl.cc:520] [C3] remote close
[2019-09-19 17:39:48.542][14][debug][connection] [source/common/network/connection_impl.cc:190] [C3] closing socket: 0
[2019-09-19 17:39:48.542][14][debug][pool] [source/common/tcp/conn_pool.cc:123] [C3] client disconnected
[2019-09-19 17:39:48.542][14][debug][connection] [source/common/network/connection_impl.cc:101] [C2] closing data_to_write=0 type=0
[2019-09-19 17:39:48.542][14][debug][connection] [source/common/network/connection_impl.cc:190] [C2] closing socket: 1
[2019-09-19 17:39:48.543][14][debug][main] [source/server/connection_handler_impl.cc:80] [C2] adding to cleanup list
[2019-09-19 17:39:48.543][14][debug][pool] [source/common/tcp/conn_pool.cc:236] [C3] connection destroyed
[2019-09-19 17:39:49.543][8][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-19 17:39:54.511][8][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-19T17:39:48.513Z] "- - -" 0 - 78 9832 30 - "-" "-" "-" "-" "192.168.65.2:5000"
[2019-09-19 17:39:59.517][8][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-19 17:40:04.516][8][debug][main] [source/server/server.cc:170] flushing stats
```
## Cleaning

```
./clean_envoy_docker.sh
./clean_web_docker.sh
```

## Ramblings and Good Thoughts

A simple TCP Proxy can be used for HTTP traffic if there is no interest in HTTP specific functionality. Based on the logs we can see the amount of processing is much lower and therefore performance should be much higher.

