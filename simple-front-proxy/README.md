# Tutorial

**Tested on Ubuntu 18.04**

In this example of we run a Envoy Proxy on that listens on port 4999 and directs to a server running on port 5000.
 
 The web server runs as a separate container from Envoy so any web server will do as long as it is listening on port 5000. 

## Envoy Docker

Build and run the envoy container. The container runs with *--network host* in order to reach the web server running on the host.

```
./build_envoy_docker.sh
``` 

Without a web server a request would look like this:

```
curl -v http://localhost:4999/

*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 4999 (#0)
> GET / HTTP/1.1
> Host: localhost:4999
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 503 Service Unavailable
< content-length: 57
< content-type: text/plain
< date: Mon, 05 Aug 2019 06:40:42 GMT
< server: envoy
<
* Connection #0 to host localhost left intact
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
< server: envoy
< date: Thu, 19 Sep 2019 17:10:06 GMT
< content-type: text/html; charset=utf-8
< content-length: 9593
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 25
<
<!DOCTYPE html>
<html lang="en">

...<snip>...
```

## Envoy Logs

Envoy Logs from a successful run.

```
[2019-09-19 17:10:03.744][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-19 17:10:06.167][16][debug][main] [source/server/connection_handler_impl.cc:280] [C0] new connection
[2019-09-19 17:10:06.168][16][debug][http] [source/common/http/conn_manager_impl.cc:246] [C0] new stream
[2019-09-19 17:10:06.170][16][debug][http] [source/common/http/conn_manager_impl.cc:619] [C0][S6190076214353030250] request headers complete (end_stream=true):
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.54.0'
'accept', '*/*'

[2019-09-19 17:10:06.170][16][debug][http] [source/common/http/conn_manager_impl.cc:1111] [C0][S6190076214353030250] request end stream
[2019-09-19 17:10:06.170][16][debug][router] [source/common/router/router.cc:401] [C0][S6190076214353030250] cluster 'simple-server' match for URL '/'
[2019-09-19 17:10:06.170][16][debug][router] [source/common/router/router.cc:514] [C0][S6190076214353030250] router decoding headers:
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.54.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '091a2a17-acd8-42da-8164-ebebc140e5c8'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-09-19 17:10:06.170][16][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-09-19 17:10:06.171][16][debug][client] [source/common/http/codec_client.cc:26] [C1] connecting
[2019-09-19 17:10:06.171][16][debug][connection] [source/common/network/connection_impl.cc:704] [C1] connecting to 192.168.65.2:5000
[2019-09-19 17:10:06.171][16][debug][connection] [source/common/network/connection_impl.cc:713] [C1] connection in progress
[2019-09-19 17:10:06.171][16][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-09-19 17:10:06.172][16][debug][connection] [source/common/network/connection_impl.cc:552] [C1] connected
[2019-09-19 17:10:06.172][16][debug][client] [source/common/http/codec_client.cc:64] [C1] connected
[2019-09-19 17:10:06.172][16][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C1] attaching to next request
[2019-09-19 17:10:06.172][16][debug][router] [source/common/router/router.cc:1503] [C0][S6190076214353030250] pool ready
[2019-09-19 17:10:06.196][16][debug][router] [source/common/router/router.cc:994] [C0][S6190076214353030250] upstream headers complete: end_stream=false
[2019-09-19 17:10:06.196][16][debug][http] [source/common/http/conn_manager_impl.cc:1378] [C0][S6190076214353030250] encoding headers via codec (end_stream=false):
':status', '200'
'server', 'envoy'
'date', 'Thu, 19 Sep 2019 17:10:06 GMT'
'content-type', 'text/html; charset=utf-8'
'content-length', '9593'
'access-control-allow-origin', '*'
'access-control-allow-credentials', 'true'
'x-envoy-upstream-service-time', '25'

[2019-09-19 17:10:06.197][16][debug][client] [source/common/http/codec_client.cc:95] [C1] response complete
[2019-09-19 17:10:06.197][16][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C1] response complete
[2019-09-19 17:10:06.197][16][debug][pool] [source/common/http/http1/conn_pool.cc:236] [C1] moving to ready
[2019-09-19 17:10:06.199][16][debug][connection] [source/common/network/connection_impl.cc:520] [C0] remote close
[2019-09-19 17:10:06.199][16][debug][connection] [source/common/network/connection_impl.cc:190] [C0] closing socket: 0
[2019-09-19 17:10:06.199][16][debug][main] [source/server/connection_handler_impl.cc:80] [C0] adding to cleanup list
[2019-09-19 17:10:08.197][16][debug][connection] [source/common/network/connection_impl.cc:520] [C1] remote close
[2019-09-19 17:10:08.197][16][debug][connection] [source/common/network/connection_impl.cc:190] [C1] closing socket: 0
[2019-09-19 17:10:08.197][16][debug][client] [source/common/http/codec_client.cc:82] [C1] disconnect. resetting 0 pending requests
[2019-09-19 17:10:08.197][16][debug][pool] [source/common/http/http1/conn_pool.cc:129] [C1] client disconnected, failure reason:
```
## Cleaning

```
./clean_envoy_docker.sh
./clean_web_docker.sh
```

