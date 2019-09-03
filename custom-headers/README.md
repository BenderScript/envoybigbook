# Tutorial

**Tested on Ubuntu 18.04**

In this example we will demonstrate how to add custom HTTP headers to a request. For that we run a Envoy Proxy on that listens on port 4999 and directs to a local server running on port 5000.
 
 We will use simple-go-server for this example since we want to show the HTTP headers received. 
 
 ## 1. Network Diagram

The HTTP Client (cURL), Envoy proxy and Web Server share the same host. cURL and Web Server run as a native applications while Envoy runs in a docker container

![You need to see the network diagram](./img/envoy_network.png)

## Envoy Docker

Build and run the envoy container. The container runs with *--network host* in order to reach the web server running on the host.

```
./build_envoy_docker.sh
``` 

## Web Server

In this example we used the simple-go-server because we want to show the HTTP headers received. 

Go to *simple-go-server* directory:

```
go build
./simple-go-server
```

## HTTP Request

Now with the Web Server running issue the request. It will be processed by the Envoy Proxy container and directed to the web Server

```
curl -v 127.0.0.1:4999                                                   
* Rebuilt URL to: 127.0.0.1:4999/
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to 127.0.0.1 (127.0.0.1) port 4999 (#0)
> GET / HTTP/1.1
> Host: 127.0.0.1:4999
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< content-type: text/plain; charset=utf-8
< x-content-type-options: nosniff
< x-request-id: 3a99a750-606e-4316-b4bb-7e0d6c13ab81
< date: Tue, 03 Sep 2019 16:52:39 GMT
< content-length: 14
< x-envoy-upstream-service-time: 1
< server: envoy
<
Hello, World!
* Connection #0 to host 127.0.0.1 left intact
```

## Web Server Logs

These are the headers received by the web server. Notice the headers we added. You might have noticed that X-Request-Upstream is missing. Unfortunately I do not know why and opened a [bug](https://github.com/envoyproxy/envoy/issues/8127) for it. 

```
HTTP Headers Received:
======================
X-Request-Downstream-Combo              : 172.17.0.2:4999
X-Request-Downstream-Combo              : 2019/09/03T16:52:39+0000 1567529559
X-Envoy-Expected-Rq-Timeout-Ms          : 15000
X-Forwarded-Proto                       : http
X-Request-Id                            : 3a99a750-606e-4316-b4bb-7e0d6c13ab81
Content-Length                          : 0
User-Agent                              : curl/7.54.0
Accept                                  : */*

http: 2019/09/03 09:52:39 3a99a750-606e-4316-b4bb-7e0d6c13ab81 GET / 127.0.0.1:50240 curl/7.54.0

```

## Envoy Logs

Envoy Logs from a successful run.

```
[2019-09-03 17:20:28.087][16][debug][filter] [source/extensions/filters/listener/original_dst/original_dst.cc:18] original_dst: New connection accepted
[2019-09-03 17:20:28.087][16][debug][main] [source/server/connection_handler_impl.cc:280] [C2] new connection
[2019-09-03 17:20:28.087][16][debug][http] [source/common/http/conn_manager_impl.cc:246] [C2] new stream
[2019-09-03 17:20:28.087][16][debug][http] [source/common/http/conn_manager_impl.cc:619] [C2][S6381331825639295381] request headers complete (end_stream=true):
':authority', '127.0.0.1:4999'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.54.0'
'accept', '*/*'

[2019-09-03 17:20:28.087][16][debug][http] [source/common/http/conn_manager_impl.cc:1111] [C2][S6381331825639295381] request end stream
[2019-09-03 17:20:28.088][16][debug][router] [source/common/router/router.cc:401] [C2][S6381331825639295381] cluster 'cluster1' match for URL '/'
[2019-09-03 17:20:28.088][16][debug][router] [source/common/router/router.cc:514] [C2][S6381331825639295381] router decoding headers:
':authority', '127.0.0.1:4999'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.54.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '984b6858-8811-46ab-9fd3-933a14d727ee'
'x-envoy-expected-rq-timeout-ms', '15000'
'x-request-downstream-combo', '172.17.0.2:4999'
'x-request-downstream-combo', '2019/09/03T17:20:28+0000 1567531228'

[2019-09-03 17:20:28.088][16][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-09-03 17:20:28.088][16][debug][client] [source/common/http/codec_client.cc:26] [C3] connecting
[2019-09-03 17:20:28.088][16][debug][connection] [source/common/network/connection_impl.cc:704] [C3] connecting to 192.168.65.2:5000
[2019-09-03 17:20:28.088][16][debug][connection] [source/common/network/connection_impl.cc:713] [C3] connection in progress
[2019-09-03 17:20:28.088][16][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-09-03 17:20:28.089][16][debug][connection] [source/common/network/connection_impl.cc:552] [C3] connected
[2019-09-03 17:20:28.089][16][debug][client] [source/common/http/codec_client.cc:64] [C3] connected
[2019-09-03 17:20:28.089][16][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C3] attaching to next request
[2019-09-03 17:20:28.089][16][debug][router] [source/common/router/router.cc:1503] [C2][S6381331825639295381] pool ready
[2019-09-03 17:20:28.090][16][debug][router] [source/common/router/router.cc:994] [C2][S6381331825639295381] upstream headers complete: end_stream=false
[2019-09-03 17:20:28.090][16][debug][http] [source/common/http/conn_manager_impl.cc:1378] [C2][S6381331825639295381] encoding headers via codec (end_stream=false):
':status', '200'
'content-type', 'text/plain; charset=utf-8'
'x-content-type-options', 'nosniff'
'x-request-id', '984b6858-8811-46ab-9fd3-933a14d727ee'
'date', 'Tue, 03 Sep 2019 17:20:27 GMT'
'content-length', '14'
'x-envoy-upstream-service-time', '2'
'server', 'envoy'

[2019-09-03 17:20:28.090][16][debug][client] [source/common/http/codec_client.cc:95] [C3] response complete
[2019-09-03 17:20:28.091][16][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C3] response complete
[2019-09-03 17:20:28.091][16][debug][pool] [source/common/http/http1/conn_pool.cc:236] [C3] moving to ready
[2019-09-03 17:20:28.092][16][debug][connection] [source/common/network/connection_impl.cc:520] [C2] remote close
[2019-09-03 17:20:28.093][16][debug][connection] [source/common/network/connection_impl.cc:190] [C2] closing socket: 0
[2019-09-03 17:20:28.093][16][debug][main] [source/server/connection_handler_impl.cc:80] [C2] adding to cleanup list
[2019-09-03 17:20:28.726][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-03 17:20:33.724][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-03 17:20:38.719][7][debug][main] [source/server/server.cc:170] flushing stats

```
## Cleaning

```
./clean_envoy_docker.sh
```

Stop *simple-go-server*. CTRL-C will do (;-)