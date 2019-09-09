# Tutorial

This example shows Envoy proxy using an external authorization server.

This is example is based on the [rate limit example](https://github.com/jbarratt/envoy_ratelimit_example)

## 1. Network Diagram

In this tutorial everything runs on a single host in order to simplify the deployment.

![You need to see the network diagram](./img/envoy_network.png)

## 2. Envoy Docker

Build and run Envoy Docker

```
./build_envoy_docker.sh
```

## 3. External Authorization Server

```
go build
./workload-identity
```

## 4. Simple Web Server

Go to simple-go-server directory

```
go build
./simple-go-server
```

## 5. Client Request

Issue the HTTP request

```
curl localhost:4999
```

Response from Server on successful authorization

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
< content-type: text/plain; charset=utf-8
< x-content-type-options: nosniff
< x-request-id: 833fb02c-3952-4e83-8e7d-f2abc16c6a1c
< date: Mon, 19 Aug 2019 19:47:08 GMT
< content-length: 14
< x-envoy-upstream-service-time: 0
< server: envoy
<
Hello, World!
* Connection #0 to host localhost left intact
```


## 6. External Server

HTTP Headers received by external authorization server. One or more of these could be used together with other sources of data.

```
ubuntu$ ./ext-authz-proxy
2019/08/19 19:46:59 listening on [::]:5010
{
  "id": "13224899753382986542",
  "method": "GET",
  "headers": {
    ":authority": "localhost:4999",
    ":method": "GET",
    ":path": "/",
    "accept": "*/*",
    "user-agent": "curl/7.58.0",
    "x-envoy-internal": "true",
    "x-forwarded-for": "172.31.22.139",
    "x-forwarded-proto": "http",
    "x-request-id": "833fb02c-3952-4e83-8e7d-f2abc16c6a1c"
  },
  "path": "/",
  "host": "localhost:4999",
  "protocol": "HTTP/1.1"
}
```

Finally, the external authorization server will inject two headers on the response that should be added to the request by Envoy.

```
X-Ext-Auth-Id                           : curl
X-Ext-Auth-Id-User                      : bob
```



## 7. Web Server

We can see that the two headers that the external server injected were received by the web server.

```
HTTP Headers Received:
======================
Accept                                  : */*
X-Forwarded-For                         : 172.31.22.139
X-Forwarded-Proto                       : http
X-Envoy-Internal                        : true
X-Request-Id                            : 4832bad3-241d-4c95-9f22-79a539de5a32
X-Envoy-Expected-Rq-Timeout-Ms          : 15000
User-Agent                              : curl/7.58.0
X-Ext-Auth-Id                           : curl
X-Ext-Auth-Id-User                      : bob
Content-Length                          : 0

http: 2019/08/20 03:38:54 4832bad3-241d-4c95-9f22-79a539de5a32 GET / [::1]:57104 curl/7.58.0
```

## 7.Authorized Request Envoy Logs

Envoy logs from a request that was authorized

```
[2019-08-19 19:47:08.653][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-19 19:47:08.916][14][debug][main] [source/server/connection_handler_impl.cc:280] [C4] new connection
[2019-08-19 19:47:08.916][14][debug][http] [source/common/http/conn_manager_impl.cc:246] [C4] new stream
[2019-08-19 19:47:08.917][14][debug][http] [source/common/http/conn_manager_impl.cc:619] [C4][S13224899753382986542] request headers complete (end_stream=true):
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2019-08-19 19:47:08.917][14][debug][http] [source/common/http/conn_manager_impl.cc:1111] [C4][S13224899753382986542] request end stream
[2019-08-19 19:47:08.917][14][debug][router] [source/common/router/router.cc:401] [C0][S7092837421431301450] cluster 'ext-authz' match for URL '/envoy.service.auth.v2.Authorization/Check'
[2019-08-19 19:47:08.917][14][debug][router] [source/common/router/router.cc:514] [C0][S7092837421431301450] router decoding headers:
':method', 'POST'
':path', '/envoy.service.auth.v2.Authorization/Check'
':authority', 'ext-authz'
':scheme', 'http'
'te', 'trailers'
'grpc-timeout', '200m'
'content-type', 'application/grpc'
'x-envoy-internal', 'true'
'x-forwarded-for', '172.31.22.139'
'x-envoy-expected-rq-timeout-ms', '200'

[2019-08-19 19:47:08.917][14][debug][client] [source/common/http/codec_client.cc:26] [C5] connecting
[2019-08-19 19:47:08.917][14][debug][connection] [source/common/network/connection_impl.cc:704] [C5] connecting to [::1]:5010
[2019-08-19 19:47:08.917][14][debug][connection] [source/common/network/connection_impl.cc:713] [C5] connection in progress
[2019-08-19 19:47:08.917][14][debug][http2] [source/common/http/http2/codec_impl.cc:899] [C5] setting stream-level initial window size to 268435456
[2019-08-19 19:47:08.917][14][debug][http2] [source/common/http/http2/codec_impl.cc:921] [C5] updating connection-level initial window size to 268435456
[2019-08-19 19:47:08.917][14][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-08-19 19:47:08.917][14][debug][connection] [source/common/network/connection_impl.cc:552] [C5] connected
[2019-08-19 19:47:08.917][14][debug][client] [source/common/http/codec_client.cc:64] [C5] connected
[2019-08-19 19:47:08.917][14][debug][pool] [source/common/http/http2/conn_pool.cc:96] [C5] creating stream
[2019-08-19 19:47:08.917][14][debug][router] [source/common/router/router.cc:1503] [C0][S7092837421431301450] pool ready
[2019-08-19 19:47:08.918][14][debug][router] [source/common/router/router.cc:994] [C0][S7092837421431301450] upstream headers complete: end_stream=false
[2019-08-19 19:47:08.918][14][debug][http] [source/common/http/async_client_impl.cc:91] async http request response headers (end_stream=false):
':status', '200'
'content-type', 'application/grpc'
'x-envoy-upstream-service-time', '1'

[2019-08-19 19:47:08.918][14][debug][client] [source/common/http/codec_client.cc:95] [C5] response complete
[2019-08-19 19:47:08.918][14][debug][pool] [source/common/http/http2/conn_pool.cc:233] [C5] destroying stream: 0 remaining
[2019-08-19 19:47:08.918][14][debug][http] [source/common/http/async_client_impl.cc:106] async http request response trailers:
'grpc-status', '0'
'grpc-message', ''

[2019-08-19 19:47:08.918][14][debug][router] [source/common/router/router.cc:401] [C4][S13224899753382986542] cluster 'simple-server' match for URL '/'
[2019-08-19 19:47:08.918][14][debug][router] [source/common/router/router.cc:514] [C4][S13224899753382986542] router decoding headers:
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-for', '172.31.22.139'
'x-forwarded-proto', 'http'
'x-envoy-internal', 'true'
'x-request-id', '833fb02c-3952-4e83-8e7d-f2abc16c6a1c'
'x-ext-auth-id', 'curl'
'x-ext-auth-id-user', 'bob'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-08-19 19:47:08.918][14][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-08-19 19:47:08.918][14][debug][client] [source/common/http/codec_client.cc:26] [C6] connecting
[2019-08-19 19:47:08.918][14][debug][connection] [source/common/network/connection_impl.cc:704] [C6] connecting to [::1]:5000
[2019-08-19 19:47:08.918][14][debug][connection] [source/common/network/connection_impl.cc:713] [C6] connection in progress
[2019-08-19 19:47:08.918][14][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-08-19 19:47:08.918][14][debug][http2] [source/common/http/http2/codec_impl.cc:732] [C5] stream closed: 0
[2019-08-19 19:47:08.918][14][debug][connection] [source/common/network/connection_impl.cc:552] [C6] connected
[2019-08-19 19:47:08.918][14][debug][client] [source/common/http/codec_client.cc:64] [C6] connected
[2019-08-19 19:47:08.918][14][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C6] attaching to next request
[2019-08-19 19:47:08.918][14][debug][router] [source/common/router/router.cc:1503] [C4][S13224899753382986542] pool ready
[2019-08-19 19:47:08.919][14][debug][router] [source/common/router/router.cc:994] [C4][S13224899753382986542] upstream headers complete: end_stream=false
[2019-08-19 19:47:08.919][14][debug][http] [source/common/http/conn_manager_impl.cc:1378] [C4][S13224899753382986542] encoding headers via codec (end_stream=false):
':status', '200'
'content-type', 'text/plain; charset=utf-8'
'x-content-type-options', 'nosniff'
'x-request-id', '833fb02c-3952-4e83-8e7d-f2abc16c6a1c'
'date', 'Mon, 19 Aug 2019 19:47:08 GMT'
'content-length', '14'
'x-envoy-upstream-service-time', '0'
'server', 'envoy'

[2019-08-19 19:47:08.919][14][debug][client] [source/common/http/codec_client.cc:95] [C6] response complete
[2019-08-19 19:47:08.919][14][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C6] response complete
[2019-08-19 19:47:08.919][14][debug][pool] [source/common/http/http1/conn_pool.cc:236] [C6] moving to ready
[2019-08-19 19:47:08.920][14][debug][connection] [source/common/network/connection_impl.cc:520] [C4] remote close
[2019-08-19 19:47:08.920][14][debug][connection] [source/common/network/connection_impl.cc:190] [C4] closing socket: 0
[2019-08-19 19:47:08.920][14][debug][main] [source/server/connection_handler_impl.cc:80] [C4] adding to cleanup list
[2019-08-19 19:47:13.657][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-19 19:47:18.660][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-19 19:47:23.665][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-19 19:47:23.919][14][debug][connection] [source/common/network/connection_impl.cc:520] [C6] remote close
[2019-08-19 19:47:23.919][14][debug][connection] [source/common/network/connection_impl.cc:190] [C6] closing socket: 0
[2019-08-19 19:47:23.919][14][debug][client] [source/common/http/codec_client.cc:82] [C6] disconnect. resetting 0 pending requests
[2019-08-19 19:47:23.919][14][debug][pool] [source/common/http/http1/conn_pool.cc:129] [C6] client disconnected, failure reason:
[2019-08-19 19:47:28.668][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-19 19:47:33.670][7][debug][main] [source/server/server.cc:170] flushing stats
```





