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
< Date: Sat, 29 Feb 2020 06:01:58 GMT
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
[2020-02-29 06:01:56.955][7][debug][upstream] [source/common/upstream/upstream_impl.cc:262] transport socket match, socket default selected for host with address 192.168.65.2:5000
[2020-02-29 06:01:58.385][17][debug][filter] [source/common/tcp_proxy/tcp_proxy.cc:233] [C0] new tcp proxy session
[2020-02-29 06:01:58.385][17][debug][filter] [source/common/tcp_proxy/tcp_proxy.cc:378] [C0] Creating connection to cluster cluster1
[2020-02-29 06:01:58.385][17][debug][pool] [source/common/tcp/conn_pool.cc:83] creating a new connection
[2020-02-29 06:01:58.385][17][debug][pool] [source/common/tcp/conn_pool.cc:364] [C1] connecting
[2020-02-29 06:01:58.385][17][debug][connection] [source/common/network/connection_impl.cc:691] [C1] connecting to 192.168.65.2:5000
[2020-02-29 06:01:58.385][17][debug][connection] [source/common/network/connection_impl.cc:700] [C1] connection in progress
[2020-02-29 06:01:58.385][17][debug][pool] [source/common/tcp/conn_pool.cc:109] queueing request due to no available connections
[2020-02-29 06:01:58.385][17][debug][conn_handler] [source/server/connection_handler_impl.cc:353] [C0] new connection
[2020-02-29 06:01:58.386][17][debug][connection] [source/common/network/connection_impl.cc:563] [C1] connected
[2020-02-29 06:01:58.386][17][debug][pool] [source/common/tcp/conn_pool.cc:285] [C1] assigning connection
[2020-02-29 06:01:58.386][17][debug][filter] [source/common/tcp_proxy/tcp_proxy.cc:572] TCP:onUpstreamEvent(), requestedServerName: 
[2020-02-29 06:01:58.518][17][debug][connection] [source/common/network/connection_impl.cc:531] [C1] remote close
[2020-02-29 06:01:58.518][17][debug][connection] [source/common/network/connection_impl.cc:192] [C1] closing socket: 0
[2020-02-29 06:01:58.518][17][debug][pool] [source/common/tcp/conn_pool.cc:124] [C1] client disconnected
[2020-02-29 06:01:58.518][17][debug][connection] [source/common/network/connection_impl.cc:101] [C0] closing data_to_write=0 type=0
[2020-02-29 06:01:58.518][17][debug][connection] [source/common/network/connection_impl.cc:192] [C0] closing socket: 1
[2020-02-29 06:01:58.518][17][debug][conn_handler] [source/server/connection_handler_impl.cc:86] [C0] adding to cleanup list
[2020-02-29 06:01:58.519][17][debug][pool] [source/common/tcp/conn_pool.cc:238] [C1] connection destroyed
[2020-02-29T06:01:58.385Z] "- - -" 0 - 78 9832 134 - "-" "-" "-" "-" "192.168.65.2:5000"
[2020-02-29 06:02:01.805][7][debug][main] [source/server/server.cc:174] flushing stats
```
## Cleaning

```
./clean_envoy_docker.sh
./clean_web_docker.sh
```

## Ramblings and Good Thoughts

A simple TCP Proxy can be used for HTTP traffic if there is no interest in HTTP specific functionality. Based on the logs we can see the amount of processing is much lower and therefore performance should be much higher.

