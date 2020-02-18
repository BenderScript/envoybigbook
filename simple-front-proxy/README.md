# Tutorial

**Tested on Ubuntu 18.04.3 LTS**

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

* Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 4999 (#0)
> GET / HTTP/1.1
> Host: localhost:4999
> User-Agent: curl/7.58.0
> Accept: */*
>
< HTTP/1.1 503 Service Unavailable
< content-length: 91
< content-type: text/plain
< date: Tue, 18 Feb 2020 19:22:52 GMT
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
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 4999 (#0)
> GET / HTTP/1.1
> Host: localhost:4999
> User-Agent: curl/7.58.0
> Accept: */*
>
< HTTP/1.1 200 OK
< server: envoy
< date: Tue, 18 Feb 2020 19:24:03 GMT
< content-type: text/html; charset=utf-8
< content-length: 9593
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 30
<
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>httpbin.org</title>
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:400,700|Source+Code+Pro:300,600|Titillium+Web:400,600,700"
        rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="/flasgger_static/swagger-ui.css">
    <link rel="icon" type="image/png" href="/static/favicon.ico" sizes="64x64 32x32 16x16" />
    <style>
        html {

...<snip>...
```

## Envoy Logs

Envoy Logs from a successful run.

```
[2020-02-18 19:24:03.595][13][debug][conn_handler] [source/server/connection_handler_impl.cc:353] [C2] new connection
[2020-02-18 19:24:03.597][13][debug][http] [source/common/http/conn_manager_impl.cc:263] [C2] new stream
[2020-02-18 19:24:03.601][13][debug][http] [source/common/http/conn_manager_impl.cc:731] [C2][S11916074562231574437] request headers complete (end_stream=true):
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2020-02-18 19:24:03.601][13][debug][http] [source/common/http/conn_manager_impl.cc:1276] [C2][S11916074562231574437] request end stream
[2020-02-18 19:24:03.601][13][debug][router] [source/common/router/router.cc:474] [C2][S11916074562231574437] cluster 'simple-server' match for URL '/'
[2020-02-18 19:24:03.603][13][debug][router] [source/common/router/router.cc:614] [C2][S11916074562231574437] router decoding headers:
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '5d13c7c0-13e9-4190-b9c4-5ed61cfd39d0'
'x-envoy-expected-rq-timeout-ms', '15000'

[2020-02-18 19:24:03.603][13][debug][pool] [source/common/http/http1/conn_pool.cc:95] creating a new connection
[2020-02-18 19:24:03.603][13][debug][client] [source/common/http/codec_client.cc:34] [C3] connecting
[2020-02-18 19:24:03.603][13][debug][connection] [source/common/network/connection_impl.cc:691] [C3] connecting to 127.0.0.1:5000
[2020-02-18 19:24:03.603][13][debug][connection] [source/common/network/connection_impl.cc:700] [C3] connection in progress
[2020-02-18 19:24:03.603][13][debug][pool] [source/common/http/conn_pool_base.cc:55] queueing request due to no available connections
[2020-02-18 19:24:03.603][13][debug][connection] [source/common/network/connection_impl.cc:563] [C3] connected
[2020-02-18 19:24:03.603][13][debug][client] [source/common/http/codec_client.cc:72] [C3] connected
[2020-02-18 19:24:03.603][13][debug][pool] [source/common/http/http1/conn_pool.cc:244] [C3] attaching to next request
[2020-02-18 19:24:03.603][13][debug][router] [source/common/router/router.cc:1711] [C2][S11916074562231574437] pool ready
[2020-02-18 19:24:03.634][13][debug][router] [source/common/router/router.cc:1115] [C2][S11916074562231574437] upstream headers complete: end_stream=false
[2020-02-18 19:24:03.634][13][debug][http] [source/common/http/conn_manager_impl.cc:1615] [C2][S11916074562231574437] encoding headers via codec (end_stream=false):
':status', '200'
'server', 'envoy'
'date', 'Tue, 18 Feb 2020 19:24:03 GMT'
'content-type', 'text/html; charset=utf-8'
'content-length', '9593'
'access-control-allow-origin', '*'
'access-control-allow-credentials', 'true'
'x-envoy-upstream-service-time', '30'

[2020-02-18 19:24:03.635][13][debug][client] [source/common/http/codec_client.cc:104] [C3] response complete
[2020-02-18 19:24:03.635][13][debug][pool] [source/common/http/http1/conn_pool.cc:201] [C3] response complete
[2020-02-18 19:24:03.635][13][debug][pool] [source/common/http/http1/conn_pool.cc:239] [C3] moving to ready
[2020-02-18 19:24:03.636][13][debug][connection] [source/common/network/connection_impl.cc:531] [C2] remote close
[2020-02-18 19:24:03.642][13][debug][connection] [source/common/network/connection_impl.cc:192] [C2] closing socket: 0
[2020-02-18 19:24:03.642][13][debug][conn_handler] [source/server/connection_handler_impl.cc:86] [C2] adding to cleanup list
[2020-02-18 19:24:04.787][7][debug][main] [source/server/server.cc:174] flushing stats
[2020-02-18 19:24:04.787][7][debug][upstream] [source/common/upstream/upstream_impl.cc:262] transport socket match, socket default selected for host with address 127.0.0.1:5000
[2020-02-18 19:24:05.637][13][debug][connection] [source/common/network/connection_impl.cc:531] [C3] remote close
[2020-02-18 19:24:05.637][13][debug][connection] [source/common/network/connection_impl.cc:192] [C3] closing socket: 0
[2020-02-18 19:24:05.637][13][debug][client] [source/common/http/codec_client.cc:91] [C3] disconnect. resetting 0 pending requests
[2020-02-18 19:24:05.637][13][debug][pool] [source/common/http/http1/conn_pool.cc:136] [C3] client disconnected, failure reason:
[2020-02-18 19:24:09.795][7][debug][main] [source/server/server.cc:174] flushing stats
```
## Cleaning

```
./clean_envoy_docker.sh
./clean_web_docker.sh
```

