# Tutorial

**Tested on Ubuntu 18.04**


In this example of we run a Envoy Proxy on that listens on port 4999 and directs to a server running on port 5000.
 
 The web server runs as a separate container from Envoy so any web server will do as long as it is listening on port 5000. This also helped me debug issues and make the example more realistic.

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
ubuntu$ curl -v localhost:4999
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
< date: Tue, 13 Aug 2019 21:33:24 GMT
< content-type: text/html; charset=utf-8
< content-length: 9593
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 2
```

## Envoy Logs

Envoy Logs from a successful run.

```
2019-08-13 21:36:29.305][14][debug][main] [source/server/connection_handler_impl.cc:280] [C2] new connection
[2019-08-13 21:36:29.306][14][debug][http] [source/common/http/conn_manager_impl.cc:246] [C2] new stream
[2019-08-13 21:36:29.306][14][debug][http] [source/common/http/conn_manager_impl.cc:600] [C2][S13054348570146873427] request headers complete (end_stream=true):
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2019-08-13 21:36:29.306][14][debug][http] [source/common/http/conn_manager_impl.cc:1092] [C2][S13054348570146873427] request end stream
[2019-08-13 21:36:29.306][14][debug][router] [source/common/router/router.cc:401] [C2][S13054348570146873427] cluster 'simple-server' match for URL '/'
[2019-08-13 21:36:29.306][14][debug][router] [source/common/router/router.cc:514] [C2][S13054348570146873427] router decoding headers:
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '2a2bbd16-e659-40f6-a718-ac1e446c4a47'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-08-13 21:36:29.306][14][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-08-13 21:36:29.306][14][debug][client] [source/common/http/codec_client.cc:26] [C3] connecting
[2019-08-13 21:36:29.306][14][debug][connection] [source/common/network/connection_impl.cc:702] [C3] connecting to [::1]:5000
[2019-08-13 21:36:29.307][14][debug][connection] [source/common/network/connection_impl.cc:711] [C3] connection in progress
[2019-08-13 21:36:29.307][14][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-08-13 21:36:29.307][14][debug][connection] [source/common/network/connection_impl.cc:550] [C3] connected
[2019-08-13 21:36:29.307][14][debug][client] [source/common/http/codec_client.cc:64] [C3] connected
[2019-08-13 21:36:29.307][14][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C3] attaching to next request
[2019-08-13 21:36:29.307][14][debug][router] [source/common/router/router.cc:1503] [C2][S13054348570146873427] pool ready
[2019-08-13 21:36:29.309][14][debug][router] [source/common/router/router.cc:994] [C2][S13054348570146873427] upstream headers complete: end_stream=false
[2019-08-13 21:36:29.309][14][debug][http] [source/common/http/conn_manager_impl.cc:1359] [C2][S13054348570146873427] encoding headers via codec (end_stream=false):
':status', '200'
'server', 'envoy'
'date', 'Tue, 13 Aug 2019 21:36:29 GMT'
'content-type', 'text/html; charset=utf-8'
'content-length', '9593'
'access-control-allow-origin', '*'
'access-control-allow-credentials', 'true'
'x-envoy-upstream-service-time', '2'

[2019-08-13 21:36:29.309][14][debug][client] [source/common/http/codec_client.cc:95] [C3] response complete
[2019-08-13 21:36:29.309][14][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C3] response complete
[2019-08-13 21:36:29.309][14][debug][pool] [source/common/http/http1/conn_pool.cc:236] [C3] moving to ready
[2019-08-13 21:36:29.311][14][debug][connection] [source/common/network/connection_impl.cc:518] [C2] remote close
[2019-08-13 21:36:29.311][14][debug][connection] [source/common/network/connection_impl.cc:188] [C2] closing socket: 0
[2019-08-13 21:36:29.311][14][debug][main] [source/server/connection_handler_impl.cc:80] [C2] adding to cleanup list
[2019-08-13 21:36:31.310][14][debug][connection] [source/common/network/connection_impl.cc:518] [C3] remote close
[2019-08-13 21:36:31.310][14][debug][connection] [source/common/network/connection_impl.cc:188] [C3] closing socket: 0
[2019-08-13 21:36:31.310][14][debug][client] [source/common/http/codec_client.cc:82] [C3] disconnect. resetting 0 pending requests
[2019-08-13 21:36:31.310][14][debug][pool] [source/common/http/http1/conn_pool.cc:129] [C3] client disconnected, failure reason:
[2019-08-13 21:36:31.478][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-13 21:36:36.482][7][debug][main] [source/server/server.cc:170] flushing stats
```
## Cleaning

```
./clean_envoy_docker.sh
./clean_web_docker.sh
```

