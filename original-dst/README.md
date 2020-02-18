# Tutorial

This was tested on **AWS Ubuntu 18.04**


This tutorial shows how to use a [original destination cluster](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#arch-overview-service-discovery-types-original-destination) to run Envoy Proxy as a forward proxy. There is no need to explicitly configure cluster IP addresses and ports since Envoy will proxy connections to the original destination IP:port  

In this example the client making HTTP requests resides on the same host as the Envoy Proxy. A practical use of such deployment is to apply security policy to the client (or application) before proxying the connection.

## 1. Network Diagram

The HTTP Client (cURL) and Envoy proxy share the same host. cURL runs as a native application and Envoy runs in a docker container

A second host runs the web server

![You need to see the network diagram](./img/envoy_network_original_dst.png)

## 2. Envoy Docker

Build and run Envoy Docker

```
./build_envoy_docker.sh
```

Envoy docker needs to run with *--network host* because it needs access to the original destination IP:port of the packet. This is done by using the socket option **SO_ORIGINAL_DST**. Check Envoy's specific documentation on [original destination filter](https://www.envoyproxy.io/docs/envoy/v1.13.0/configuration/listeners/listener_filters/original_dst_filter)

Finally, the Envoy container **must** be run under root in order for the IPTables redirection to work properly as we will see later. You should see an output similar to this one.

```
ubuntu$ ps aux | grep envoy
ubuntu     315  0.0  0.0  14660  1024 pts/0    S+   04:23   0:00 grep --color=auto envoy
root     32726  2.8  0.0   4504   700 ?        Ss   04:23   0:00 /bin/sh -c ./start_envoy.sh
root     32756  0.0  0.0   4504   780 ?        S    04:23   0:00 /bin/sh ./start_envoy.sh
root     32757  0.2  0.5 118568 21872 ?        Sl   04:23   0:00 envoy -c /etc/service-envoy.yaml --log-level debug
```

### 2.1 Socket Option SO_ORIGINAL_DST

A small [python script](./original_destination.py) is included to demonstrate how proxies get the original IP:port from redirected connections. Assuming the IPTables rule below is in place, start this script as root instead of Envoy to get a deeper understanding of this socket option.

## 3. IPTables

We redirect HTTP requests to Envoy's port, in this case 4999. It is important to notice that in order to avoid **infinite redirection loops**, we match on non-root user IDs. This assumes Envoy Proxy is run under the root user.

Add the IPTables rule. 

```
./create_ip_tables.sh
```

## 4. Web Server

For this example you can use any web server on the Internet. I used 172.31.24.143 as an example in the diagram but capture logs accessing *www.cnn.com*

## 5. HTTP Request

Use cURL or your preferred HTTP client to perform a request to the web server

```
ubuntu$ curl -v www.cnn.com
* Rebuilt URL to: www.cnn.com/
*   Trying 151.101.41.67...
* TCP_NODELAY set
* Connected to www.cnn.com (151.101.41.67) port 80 (#0)
> GET / HTTP/1.1
> Host: www.cnn.com
> User-Agent: curl/7.58.0
> Accept: */*
>
< HTTP/1.1 301 Moved Permanently
< server: envoy
< retry-after: 0
< content-length: 0
< cache-control: public, max-age=600
< location: https://www.cnn.com/
< accept-ranges: bytes
< date: Thu, 19 Sep 2019 16:41:44 GMT
< via: 1.1 varnish
< set-cookie: countryCode=US; Domain=.cnn.com; Path=/
< set-cookie: geoData=san jose|CA|95123|US|NA|-700|broadband; Domain=.cnn.com; Path=/
< x-served-by: cache-sjc3128-SJC
< x-cache: HIT
< x-cache-hits: 0
< x-envoy-upstream-service-time: 1
<
* Connection #0 to host www.cnn.com left intact
```

## 7. IPTables Statistics

It can seen that only the first HTTP request (one packet) is redirected and that the proxied Envoy request does not match the IPTables.

```
ubuntu$ ./show_iptables.sh
Chain OUTPUT (policy ACCEPT 9 packets, 966 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER     all  --  *      *       0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
    1    60 REDIRECT   tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80 ! owner UID match 0 redir ports 4999
```


## 8. Envoy Logs

Envoy Logs for successful run.

```
[2019-09-19 16:41:45.115][14][debug][filter] [source/extensions/filters/listener/original_dst/original_dst.cc:18] original_dst: New connection accepted
[2019-09-19 16:41:45.115][14][debug][main] [source/server/connection_handler_impl.cc:280] [C0] new connection
[2019-09-19 16:41:45.115][14][debug][http] [source/common/http/conn_manager_impl.cc:246] [C0] new stream
[2019-09-19 16:41:45.116][14][debug][http] [source/common/http/conn_manager_impl.cc:619] [C0][S5387317192340225778] request headers complete (end_stream=true):
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2019-09-19 16:41:45.116][14][debug][http] [source/common/http/conn_manager_impl.cc:1111] [C0][S5387317192340225778] request end stream
[2019-09-19 16:41:45.116][14][debug][router] [source/common/router/router.cc:401] [C0][S5387317192340225778] cluster 'cluster1' match for URL '/'
[2019-09-19 16:41:45.116][14][debug][upstream] [source/common/upstream/original_dst_cluster.cc:87] Created host 151.101.41.67:80.
[2019-09-19 16:41:45.116][14][debug][router] [source/common/router/router.cc:514] [C0][S5387317192340225778] router decoding headers:
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', 'f1a14007-ea40-43b0-ac37-ed1c5d9d335a'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-09-19 16:41:45.117][14][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-09-19 16:41:45.117][14][debug][client] [source/common/http/codec_client.cc:26] [C1] connecting
[2019-09-19 16:41:45.117][14][debug][connection] [source/common/network/connection_impl.cc:704] [C1] connecting to 151.101.41.67:80
[2019-09-19 16:41:45.117][14][debug][connection] [source/common/network/connection_impl.cc:713] [C1] connection in progress
[2019-09-19 16:41:45.117][14][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-09-19 16:41:45.117][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 1 removed 0
[2019-09-19 16:41:45.117][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:41] Adding host 151.101.41.67:80.
[2019-09-19 16:41:45.117][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 1 removed 0
[2019-09-19 16:41:45.117][13][debug][upstream] [source/common/upstream/original_dst_cluster.cc:41] Adding host 151.101.41.67:80.
[2019-09-19 16:41:45.117][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 1 removed 0
[2019-09-19 16:41:45.117][14][debug][connection] [source/common/network/connection_impl.cc:552] [C1] connected
[2019-09-19 16:41:45.117][14][debug][client] [source/common/http/codec_client.cc:64] [C1] connected
[2019-09-19 16:41:45.117][14][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C1] attaching to next request
[2019-09-19 16:41:45.117][14][debug][router] [source/common/router/router.cc:1503] [C0][S5387317192340225778] pool ready
[2019-09-19 16:41:45.118][14][debug][client] [source/common/http/codec_client.cc:95] [C1] response complete
[2019-09-19 16:41:45.118][14][debug][router] [source/common/router/router.cc:994] [C0][S5387317192340225778] upstream headers complete: end_stream=true
[2019-09-19 16:41:45.118][14][debug][http] [source/common/http/conn_manager_impl.cc:1378] [C0][S5387317192340225778] encoding headers via codec (end_stream=true):
':status', '301'
'server', 'envoy'
'retry-after', '0'
'content-length', '0'
'cache-control', 'public, max-age=600'
'location', 'https://www.cnn.com/'
'accept-ranges', 'bytes'
'date', 'Thu, 19 Sep 2019 16:41:44 GMT'
'via', '1.1 varnish'
'set-cookie', 'countryCode=US; Domain=.cnn.com; Path=/'
'set-cookie', 'geoData=san jose|CA|95123|US|NA|-700|broadband; Domain=.cnn.com; Path=/'
'x-served-by', 'cache-sjc3128-SJC'
'x-cache', 'HIT'
'x-cache-hits', '0'
'x-envoy-upstream-service-time', '1'

[2019-09-19 16:41:45.118][14][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C1] response complete
[2019-09-19 16:41:45.118][14][debug][pool] [source/common/http/http1/conn_pool.cc:203] [C1] saw upstream close connection
[2019-09-19 16:41:45.118][14][debug][connection] [source/common/network/connection_impl.cc:101] [C1] closing data_to_write=0 type=1
[2019-09-19 16:41:45.118][14][debug][connection] [source/common/network/connection_impl.cc:190] [C1] closing socket: 1
[2019-09-19 16:41:45.118][14][debug][client] [source/common/http/codec_client.cc:82] [C1] disconnect. resetting 0 pending requests
[2019-09-19 16:41:45.118][14][debug][pool] [source/common/http/http1/conn_pool.cc:129] [C1] client disconnected, failure reason:
[2019-09-19 16:41:45.119][14][debug][connection] [source/common/network/connection_impl.cc:520] [C0] remote close
[2019-09-19 16:41:45.119][14][debug][connection] [source/common/network/connection_impl.cc:190] [C0] closing socket: 0
[2019-09-19 16:41:45.119][14][debug][main] [source/server/connection_handler_impl.cc:80] [C0] adding to cleanup list
[2019-09-19 16:41:49.688][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-19 16:41:49.688][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:170] Cleaning up stale original dst hosts.
[2019-09-19 16:41:49.688][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:173] Keeping active host 151.101.41.67:80.
[2019-09-19 16:41:54.692][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:170] Cleaning up stale original dst hosts.
[2019-09-19 16:41:54.692][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:177] Removing stale host 151.101.41.67:80.
[2019-09-19 16:41:54.692][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 0 removed 1
[2019-09-19 16:41:54.692][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 0 removed 1
[2019-09-19 16:41:54.692][14][debug][upstream] [source/common/upstream/original_dst_cluster.cc:36] Removing host 151.101.41.67:80.
[2019-09-19 16:41:54.692][7][debug][upstream] [source/common/upstream/original_dst_cluster.cc:36] Removing host 151.101.41.67:80.
[2019-09-19 16:41:54.692][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster cluster1 removed 1
[2019-09-19 16:41:54.692][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-09-19 16:41:54.692][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster cluster1 removed 1
[2019-09-19 16:41:54.692][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 0 removed 1
[2019-09-19 16:41:54.692][13][debug][upstream] [source/common/upstream/original_dst_cluster.cc:36] Removing host 151.101.41.67:80.
[2019-09-19 16:41:54.692][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster cluster1 removed 1
[2019-09-19 16:41:59.700][7][debug][main] [source/server/server.cc:170] flushing stats
```

## 9. Cleaning

```
./clean_envoy_docker.sh
./clean_iptables.sh
```