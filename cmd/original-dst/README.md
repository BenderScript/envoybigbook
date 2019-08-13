# Tutorial

This tutorial shows how to use a [original destination cluster](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#arch-overview-service-discovery-types-original-destination) to run Envoy Proxy as a forward proxy. In other words, Envoy will proxy connections created within the sam host it is running.

This was tested on Ubuntu 18.04


## Network Diagram

The HTTP Client (cURL) and Envoy proxy share the same host. cURL runs as a native application and Envoy runs in a  docker container

Another host runs the web server

```

                                                               
```

## Envoy Docker

Build and run Envoy Docker

```
./build_docker_net_admin.sh
```

Envoy docker needs to run with *--network host* because it needs access to the original destination IP:port of the packet. This is done by using the socket option **SO_ORIGINAL_DST**. Check Envoy's specific documentation on [original destination filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/listener_filters/original_dst_filter)


### Socket Option SO_ORIGINAL_DST

A small [python script](./original_destination.py) is included to demonstrate how proxies get the original IP:port from redirected connections. Assuming the IPTables rule below is in place, start this script as root instead of Envoy to get a deeper understanding of this socket option.

## IPTables

We redirect HTTP requests to Envoy's port, in this case 4999. It is important to notice that in order to avoid **infinite redirection loops**, we match on non-root user IDs. This assumes Envoy Proxy was started by the root user, otherwise use the UID of the user that started the envoy process or container.

Add the following IPTable rule. 

```
sudo iptables -t nat -A OUTPUT -p tcp -m tcp --dport 80 -d  172.31.24.143 -m owner ! --uid-owner 0 -j REDIRECT --to-port 4999
```

## Web Server

The Web Server for this example was running on 172.31.24.143

I normally use [httpbin](http://httpbin.org/) as the Web Server. A reliable, no-hassle, perfect-for-testing web server.

```
docker run -p 80:80 kennethreitz/httpbin
```

## HTTP Request

Use cURL or your preferred HTTP client to perform a request to the web server

```
ubuntu@ip-172-31-22-139:~/identity/cmd/original-dst$ curl -v 172.31.24.143
* Rebuilt URL to: 172.31.24.143/
*   Trying 172.31.24.143...
* TCP_NODELAY set
* Connected to 172.31.24.143 (172.31.24.143) port 80 (#0)
> GET / HTTP/1.1
> Host: 172.31.24.143
> User-Agent: curl/7.58.0
> Accept: */*
>
< HTTP/1.1 200 OK
< server: envoy
< date: Tue, 13 Aug 2019 07:02:21 GMT
< content-type: text/html; charset=utf-8
< content-length: 9593
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 2
```
## Envoy Logs

Envoy Logs for successful run.

```
[2019-08-13 07:17:34.772][13][debug][filter] [source/extensions/filters/listener/original_dst/original_dst.cc:18] original_dst: New connection accepted
[2019-08-13 07:17:34.772][13][debug][main] [source/server/connection_handler_impl.cc:280] [C4] new connection
[2019-08-13 07:17:34.772][13][debug][http] [source/common/http/conn_manager_impl.cc:246] [C4] new stream
[2019-08-13 07:17:34.772][13][debug][http] [source/common/http/conn_manager_impl.cc:600] [C4][S4932201214277595902] request headers complete (end_stream=true):
':authority', '172.31.24.143'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2019-08-13 07:17:34.772][13][debug][http] [source/common/http/conn_manager_impl.cc:1092] [C4][S4932201214277595902] request end stream
[2019-08-13 07:17:34.772][13][debug][router] [source/common/router/router.cc:401] [C4][S4932201214277595902] cluster 'cluster1' match for URL '/'
[2019-08-13 07:17:34.772][13][debug][upstream] [source/common/upstream/original_dst_cluster.cc:87] Created host 172.31.24.143:80.
[2019-08-13 07:17:34.772][13][debug][router] [source/common/router/router.cc:514] [C4][S4932201214277595902] router decoding headers:
':authority', '172.31.24.143'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '2434b83e-e425-4304-a7ed-ec87740d1280'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-08-13 07:17:34.772][13][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-08-13 07:17:34.772][13][debug][client] [source/common/http/codec_client.cc:26] [C5] connecting
[2019-08-13 07:17:34.772][13][debug][connection] [source/common/network/connection_impl.cc:702] [C5] connecting to 172.31.24.143:80
[2019-08-13 07:17:34.772][13][debug][connection] [source/common/network/connection_impl.cc:711] [C5] connection in progress
[2019-08-13 07:17:34.772][13][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-08-13 07:17:34.772][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 1 removed 0
[2019-08-13 07:17:34.772][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:41] Adding host 172.31.24.143:80.
[2019-08-13 07:17:34.772][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 1 removed 0
[2019-08-13 07:17:34.772][13][debug][connection] [source/common/network/connection_impl.cc:550] [C5] connected
[2019-08-13 07:17:34.773][13][debug][client] [source/common/http/codec_client.cc:64] [C5] connected
[2019-08-13 07:17:34.773][13][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C5] attaching to next request
[2019-08-13 07:17:34.773][13][debug][router] [source/common/router/router.cc:1503] [C4][S4932201214277595902] pool ready
[2019-08-13 07:17:34.773][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 1 removed 0
[2019-08-13 07:17:34.773][14][debug][upstream] [source/common/upstream/original_dst_cluster.cc:41] Adding host 172.31.24.143:80.
[2019-08-13 07:17:34.775][13][debug][router] [source/common/router/router.cc:994] [C4][S4932201214277595902] upstream headers complete: end_stream=false
[2019-08-13 07:17:34.775][13][debug][http] [source/common/http/conn_manager_impl.cc:1359] [C4][S4932201214277595902] encoding headers via codec (end_stream=false):
':status', '200'
'server', 'envoy'
'date', 'Tue, 13 Aug 2019 07:17:34 GMT'
'content-type', 'text/html; charset=utf-8'
'content-length', '9593'
'access-control-allow-origin', '*'
'access-control-allow-credentials', 'true'
'x-envoy-upstream-service-time', '2'

[2019-08-13 07:17:34.775][13][debug][client] [source/common/http/codec_client.cc:95] [C5] response complete
[2019-08-13 07:17:34.775][13][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C5] response complete
[2019-08-13 07:17:34.775][13][debug][pool] [source/common/http/http1/conn_pool.cc:236] [C5] moving to ready
[2019-08-13 07:17:34.776][13][debug][connection] [source/common/network/connection_impl.cc:518] [C4] remote close
[2019-08-13 07:17:34.776][13][debug][connection] [source/common/network/connection_impl.cc:188] [C4] closing socket: 0
[2019-08-13 07:17:34.776][13][debug][main] [source/server/connection_handler_impl.cc:80] [C4] adding to cleanup list
[2019-08-13 07:17:35.471][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:170] Cleaning up stale original dst hosts.
[2019-08-13 07:17:35.471][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:173] Keeping active host 172.31.24.143:80.
[2019-08-13 07:17:35.502][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-13 07:17:36.776][13][debug][connection] [source/common/network/connection_impl.cc:518] [C5] remote close
[2019-08-13 07:17:36.776][13][debug][connection] [source/common/network/connection_impl.cc:188] [C5] closing socket: 0
[2019-08-13 07:17:36.776][13][debug][client] [source/common/http/codec_client.cc:82] [C5] disconnect. resetting 0 pending requests
[2019-08-13 07:17:36.776][13][debug][pool] [source/common/http/http1/conn_pool.cc:129] [C5] client disconnected, failure reason:
[2019-08-13 07:17:40.478][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:170] Cleaning up stale original dst hosts.
[2019-08-13 07:17:40.478][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:177] Removing stale host 172.31.24.143:80.
[2019-08-13 07:17:40.478][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 0 removed 1
[2019-08-13 07:17:40.478][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:36] Removing host 172.31.24.143:80.
[2019-08-13 07:17:40.478][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster cluster1 removed 1
[2019-08-13 07:17:40.478][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 0 removed 1
[2019-08-13 07:17:40.478][14][debug][upstream] [source/common/upstream/original_dst_cluster.cc:36] Removing host 172.31.24.143:80.
[2019-08-13 07:17:40.478][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster cluster1 removed 1
[2019-08-13 07:17:40.478][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 0 removed 1
[2019-08-13 07:17:40.478][13][debug][upstream] [source/common/upstream/original_dst_cluster.cc:36] Removing host 172.31.24.143:80.
[2019-08-13 07:17:40.478][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster cluster1 removed 1
[2019-08-13 07:17:40.506][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-13 07:17:45.510][7][debug][main] [source/server/server.cc:170] flushing stats
```