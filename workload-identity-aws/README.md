# Tutorial

This example demonstrates how to use Envoy Proxy and Authz server to create a soft boundary around an application in order to create or provide **workload identity** within an AWS EC2 deployment.

More specifically, it integrates AWS EC2 information into the application identity. It seems clear to me that any serious workload identity solution needs to incorporate a cloud's provider information in order to be deployed everywhere.

A similar example could be done for Microsoft Azure or Google Cloud.


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
./workload-identity-aws
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
curl -v localhost:4999
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
< x-request-id: 0374a015-736e-4e7b-9f46-c1d239d5e91b
< date: Mon, 16 Sep 2019 22:27:31 GMT
< content-length: 14
< x-envoy-upstream-service-time: 0
< server: envoy
<
Hello, World!
* Connection #0 to host localhost left intact
```

## 6. WorkLoad Identity

The external server identifies the application through its source port. In this case *curl* with path */usr/bin*. Furthermore, it gets AWS EC2 **instance and user metadata** through HTTP using the procedure described [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)

```
ubuntu$ ./workload-identity-aws
2019/09/16 22:25:54 listening on [::]:5010
Source IP:port 127.0.0.1:51884
Process name: Curl
Process Exe: /usr/bin/curl
Process User: ubuntu
Process State: ESTABLISHED
{
  "id": "10533231379980244848",
  "method": "GET",
  "headers": {
    ":authority": "localhost:4999",
    ":method": "GET",
    ":path": "/",
    "accept": "*/*",
    "user-agent": "curl/7.58.0",
    "x-envoy-internal": "true",
    "x-forwarded-for": "172.31.24.143",
    "x-forwarded-proto": "http",
    "x-request-id": "0374a015-736e-4e7b-9f46-c1d239d5e91b"
  },
  "path": "/",
  "host": "localhost:4999",
  "protocol": "HTTP/1.1"
}
```

Finally, the external authorization server will inject five headers on the response that should be added to the request by Envoy. Notice the headers that are specific to AWS EC2

```
X-Workload-Id                           : Curl
X-Workload-User                         : ubuntu
X-Workload-Local-Hostname               : ip-172-0-0-2.us-west-1.compute.internal
X-Workload-Instance-Id                  : i-0a905f49550452adb
X-Workload-Zone                         : us-west-1c
```

## 7. Web Server

We can see that the five headers that the external server injected were received by the web server.

```
HTTP Headers Received:
======================
X-Forwarded-Proto                       : http
X-Envoy-Expected-Rq-Timeout-Ms          : 15000
Content-Length                          : 0
X-Workload-Local-Hostname               : ip-172-31-24-143.us-west-1.compute.internal
X-Workload-Instance-Id                  : i-0a905f49550452adb
X-Workload-Zone                         : us-west-1c
User-Agent                              : curl/7.58.0
X-Forwarded-For                         : 172.31.24.143
X-Envoy-Internal                        : true
X-Workload-Id                           : Curl
Accept                                  : */*
X-Request-Id                            : 0374a015-736e-4e7b-9f46-c1d239d5e91b
X-Workload-User                         : ubuntu

http: 2019/09/16 22:27:31 0374a015-736e-4e7b-9f46-c1d239d5e91b GET / [::1]:60092 curl/7.58.0

```

## 7.Authorized Request Envoy Logs

Envoy logs from a request that was authorized

```
[2019-09-16 22:27:31.464][13][debug][main] [source/server/connection_handler_impl.cc:280] [C0] new connection
[2019-09-16 22:27:31.464][13][debug][http] [source/common/http/conn_manager_impl.cc:246] [C0] new stream
[2019-09-16 22:27:31.465][13][debug][http] [source/common/http/conn_manager_impl.cc:619] [C0][S10533231379980244848] request headers complete (end_stream=true):
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2019-09-16 22:27:31.465][13][debug][http] [source/common/http/conn_manager_impl.cc:1111] [C0][S10533231379980244848] request end stream
[2019-09-16 22:27:31.465][13][debug][router] [source/common/router/router.cc:401] [C0][S10351351742544702498] cluster 'ext-authz' match for URL '/envoy.service.auth.v2.Authorization/Check'
[2019-09-16 22:27:31.465][13][debug][router] [source/common/router/router.cc:514] [C0][S10351351742544702498] router decoding headers:
':method', 'POST'
':path', '/envoy.service.auth.v2.Authorization/Check'
':authority', 'ext-authz'
':scheme', 'http'
'te', 'trailers'
'grpc-timeout', '200m'
'content-type', 'application/grpc'
'x-envoy-internal', 'true'
'x-forwarded-for', '172.31.24.143'
'x-envoy-expected-rq-timeout-ms', '200'

[2019-09-16 22:27:31.465][13][debug][client] [source/common/http/codec_client.cc:26] [C1] connecting
[2019-09-16 22:27:31.465][13][debug][connection] [source/common/network/connection_impl.cc:704] [C1] connecting to [::1]:5010
[2019-09-16 22:27:31.465][13][debug][connection] [source/common/network/connection_impl.cc:713] [C1] connection in progress
[2019-09-16 22:27:31.466][13][debug][http2] [source/common/http/http2/codec_impl.cc:899] [C1] setting stream-level initial window size to 268435456
[2019-09-16 22:27:31.466][13][debug][http2] [source/common/http/http2/codec_impl.cc:921] [C1] updating connection-level initial window size to 268435456
[2019-09-16 22:27:31.466][13][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-09-16 22:27:31.466][13][debug][connection] [source/common/network/connection_impl.cc:552] [C1] connected
[2019-09-16 22:27:31.466][13][debug][client] [source/common/http/codec_client.cc:64] [C1] connected
[2019-09-16 22:27:31.466][13][debug][pool] [source/common/http/http2/conn_pool.cc:96] [C1] creating stream
[2019-09-16 22:27:31.466][13][debug][router] [source/common/router/router.cc:1503] [C0][S10351351742544702498] pool ready
[2019-09-16 22:27:31.498][13][debug][router] [source/common/router/router.cc:994] [C0][S10351351742544702498] upstream headers complete: end_stream=false
[2019-09-16 22:27:31.498][13][debug][http] [source/common/http/async_client_impl.cc:91] async http request response headers (end_stream=false):
':status', '200'
'content-type', 'application/grpc'
'x-envoy-upstream-service-time', '32'

[2019-09-16 22:27:31.498][13][debug][client] [source/common/http/codec_client.cc:95] [C1] response complete
[2019-09-16 22:27:31.498][13][debug][pool] [source/common/http/http2/conn_pool.cc:233] [C1] destroying stream: 0 remaining
[2019-09-16 22:27:31.498][13][debug][http] [source/common/http/async_client_impl.cc:106] async http request response trailers:
'grpc-status', '0'
'grpc-message', ''

[2019-09-16 22:27:31.499][13][debug][router] [source/common/router/router.cc:401] [C0][S10533231379980244848] cluster 'simple-server' match for URL '/'
[2019-09-16 22:27:31.499][13][debug][router] [source/common/router/router.cc:514] [C0][S10533231379980244848] router decoding headers:
':authority', 'localhost:4999'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-for', '172.31.24.143'
'x-forwarded-proto', 'http'
'x-envoy-internal', 'true'
'x-request-id', '0374a015-736e-4e7b-9f46-c1d239d5e91b'
'x-workload-id', 'Curl'
'x-workload-user', 'ubuntu'
'x-workload-local-hostname', 'ip-172-0-0-2.us-west-1.compute.internal'
'x-workload-instance-id', 'i-0a905f49550452adb'
'x-workload-zone', 'us-west-1c'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-09-16 22:27:31.499][13][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-09-16 22:27:31.499][13][debug][client] [source/common/http/codec_client.cc:26] [C2] connecting
[2019-09-16 22:27:31.499][13][debug][connection] [source/common/network/connection_impl.cc:704] [C2] connecting to [::1]:5000
[2019-09-16 22:27:31.499][13][debug][connection] [source/common/network/connection_impl.cc:713] [C2] connection in progress
[2019-09-16 22:27:31.499][13][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-09-16 22:27:31.499][13][debug][http2] [source/common/http/http2/codec_impl.cc:732] [C1] stream closed: 0
[2019-09-16 22:27:31.499][13][debug][connection] [source/common/network/connection_impl.cc:552] [C2] connected
[2019-09-16 22:27:31.499][13][debug][client] [source/common/http/codec_client.cc:64] [C2] connected
[2019-09-16 22:27:31.499][13][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C2] attaching to next request
[2019-09-16 22:27:31.499][13][debug][router] [source/common/router/router.cc:1503] [C0][S10533231379980244848] pool ready
[2019-09-16 22:27:31.499][13][debug][router] [source/common/router/router.cc:994] [C0][S10533231379980244848] upstream headers complete: end_stream=false
[2019-09-16 22:27:31.499][13][debug][http] [source/common/http/conn_manager_impl.cc:1378] [C0][S10533231379980244848] encoding headers via codec (end_stream=false):
':status', '200'
'content-type', 'text/plain; charset=utf-8'
'x-content-type-options', 'nosniff'
'x-request-id', '0374a015-736e-4e7b-9f46-c1d239d5e91b'
'date', 'Mon, 16 Sep 2019 22:27:31 GMT'
'content-length', '14'
'x-envoy-upstream-service-time', '0'
'server', 'envoy'

[2019-09-16 22:27:31.499][13][debug][client] [source/common/http/codec_client.cc:95] [C2] response complete
[2019-09-16 22:27:31.500][13][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C2] response complete
[2019-09-16 22:27:31.500][13][debug][pool] [source/common/http/http1/conn_pool.cc:236] [C2] moving to ready
[2019-09-16 22:27:31.500][13][debug][connection] [source/common/network/connection_impl.cc:520] [C0] remote close
[2019-09-16 22:27:31.500][13][debug][connection] [source/common/network/connection_impl.cc:190] [C0] closing socket: 0
[2019-09-16 22:27:31.500][13][debug][main] [source/server/connection_handler_impl.cc:80] [C0] adding to cleanup list
[2019-09-16 22:27:34.672][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-16 22:27:39.676][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-16 22:27:44.679][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-16 22:27:46.502][13][debug][connection] [source/common/network/connection_impl.cc:520] [C2] remote close
[2019-09-16 22:27:46.502][13][debug][connection] [source/common/network/connection_impl.cc:190] [C2] closing socket: 0
[2019-09-16 22:27:46.502][13][debug][client] [source/common/http/codec_client.cc:82] [C2] disconnect. resetting 0 pending requests
[2019-09-16 22:27:46.502][13][debug][pool] [source/common/http/http1/conn_pool.cc:129] [C2] client disconnected, failure reason:
[2019-09-16 22:27:49.683][7][debug][main] [source/server/server.cc:170] flushing stats
```

## 8. Ramblings and Good thoughts

Creating a soft boundary and capture application name, path, instance-id, zone and many others is just ridiculously good. Since the this is a soft boundary, the application is not disturbed but at the same time you get audit, telemetry, stats, you name it.





