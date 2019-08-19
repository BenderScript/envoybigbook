# Tutorial

This tutorial shows how to use Envoy in [Transparent Proxy](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/lds.proto#envoy-api-field-listener-transparent) mode. The distinguishing feature in this scenario is that there is no NAT.

Transparent Proxy or TPROXY is a Linux Kernel feature without a lot of documentation. The common referenced documentation is the [original feature write-up](https://www.kernel.org/doc/Documentation/networking/tproxy.txt)

This was tested on **AWS** Ubuntu 18.04


## 1. Network Diagram

 
![You need to see the network diagram][./img/envoy_network.png]


## 2. Router

The router host performs the following functions:

* Forwards packets between client and server
* Runs Envoy Proxy
* Transparently redirect packets to Envoy Proxy


### 2.1 Forwarding

Enable forwarding on the host. There are many good tutorials on the web on how to enable forwarding on a Linux host. 

### 2.2 Envoy Docker

Build and run Envoy Docker

```
./build_ubuntu_docker.sh
./build_envoy_docker_net_admin.sh
```

Envoy docker needs to run with **--network host** and **--cap-add=NET_ADMIN** because it needs access to the original destination IP:port of the packet. This is done by using the socket option **SO_ORIGINAL_DST**. Check Envoy's specific documentation on [original destination filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/listener_filters/original_dst_filter)

Finally, the Envoy container **must** be run under root in order for the IPTables redirection to work properly as we will see later. You should see an output similar to this one.

```
ubuntu$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
2cdeadaf09d1        envoy-tproxy        "/bin/sh -c ./start_…"   10 hours ago        Up 10 hours                             envoy-tproxy
ubuntu$ ps aux | grep envoy
root      4185  0.0  0.0   4628   812 ?        Ss   Aug17   0:00 /bin/sh -c ./start_envoy.sh
root      4214  0.0  0.0   4628   796 ?        S    Aug17   0:00 /bin/sh ./start_envoy.sh
root      4215  0.1  0.6 129688 24380 ?        Sl   Aug17   0:42 envoy -c /etc/service-envoy.yaml --log-level debug
ubuntu    5802  0.0  0.0  14660  1148 pts/0    S+   09:32   0:00 grep --color=auto envoy
```


#### 2.2.1 Socket Option SO_ORIGINAL_DST

A small [python script](./original_destination.py) is included to demonstrate how proxies get the original IP:port from redirected connections. Assuming the IPTables rule below is in place, start this script as root instead of Envoy to get a deeper understanding of this socket option.

### 2.3 TPROXY

Installing TPROXY kernel module is tricky and there are many unanswered question from people on the net. If it *just works* when you try consider yourself lucky. Again, this tutorial was tested on AWS Ubuntu 18.04

I created this simple step-by-step script to help install TPROXY. If you get errors  just open the file ans execute each command in order.

```
./tproxy_install.sh
```

### 2.4 IPTables, Route and Rule

In order for transparent proxy to work a set of IPTables rules, routes and rules need to be created. 

```
./create_ip_tables.sh
```

## 3. Web Server

The Web Server for this example was running on *172.31.24.143*

I normally use [httpbin](http://httpbin.org/) as the Web Server. A reliable, no-hassle, perfect-for-testing web server.

```
./run_web_docker.sh
```

## 4. Client Host

### 4.1 Route

Add a route to the web server through the router host.

```
ubuntu$ sudo ip route show

...snip...

172.31.24.143 via 172.31.20.57 dev eth0
```

### 4.2 HTTP Request

Use cURL or your preferred HTTP client to perform a request to the web server. 

```
ubuntu$ curl -v 172.31.24.143
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
< date: Sat, 17 Aug 2019 23:34:22 GMT
< content-type: text/html; charset=utf-8
< content-length: 9593
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 2
```
## 5. Envoy Logs

Envoy Logs for successful run.

```
[2019-08-17 22:50:37.044][13][debug][filter] [external/envoy/source/extensions/filters/listener/original_dst/original_dst.cc:18] original_dst: New connection accepted
[2019-08-17 22:50:37.044][13][debug][main] [external/envoy/source/server/connection_handler_impl.cc:280] [C0] new connection
[2019-08-17 22:50:37.044][13][debug][http] [external/envoy/source/common/http/conn_manager_impl.cc:246] [C0] new stream
[2019-08-17 22:50:37.052][13][debug][http] [external/envoy/source/common/http/conn_manager_impl.cc:619] [C0][S4390330287188786749] request headers complete (end_stream=true):
':authority', '172.31.24.143'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2019-08-17 22:50:37.052][13][debug][http] [external/envoy/source/common/http/conn_manager_impl.cc:1111] [C0][S4390330287188786749] request end stream
[2019-08-17 22:50:37.052][13][debug][router] [external/envoy/source/common/router/router.cc:401] [C0][S4390330287188786749] cluster 'cluster1' match for URL '/'
[2019-08-17 22:50:37.053][13][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:87] Created host 172.31.24.143:80.
[2019-08-17 22:50:37.053][13][debug][router] [external/envoy/source/common/router/router.cc:514] [C0][S4390330287188786749] router decoding headers:
':authority', '172.31.24.143'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', 'b4d17279-fa24-4b6f-8377-c41548213752'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-08-17 22:50:37.053][13][debug][pool] [external/envoy/source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-08-17 22:50:37.053][13][debug][client] [external/envoy/source/common/http/codec_client.cc:26] [C1] connecting
[2019-08-17 22:50:37.053][13][debug][connection] [external/envoy/source/common/network/connection_impl.cc:704] [C1] connecting to 172.31.24.143:80
[2019-08-17 22:50:37.053][13][debug][connection] [external/envoy/source/common/network/connection_impl.cc:713] [C1] connection in progress
[2019-08-17 22:50:37.053][13][debug][pool] [external/envoy/source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-08-17 22:50:37.053][13][debug][connection] [external/envoy/source/common/network/connection_impl.cc:552] [C1] connected
[2019-08-17 22:50:37.053][13][debug][client] [external/envoy/source/common/http/codec_client.cc:64] [C1] connected
[2019-08-17 22:50:37.053][13][debug][pool] [external/envoy/source/common/http/http1/conn_pool.cc:241] [C1] attaching to next request
[2019-08-17 22:50:37.053][13][debug][router] [external/envoy/source/common/router/router.cc:1503] [C0][S4390330287188786749] pool ready
[2019-08-17 22:50:37.054][13][debug][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 1 removed 0
[2019-08-17 22:50:37.054][14][debug][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 1 removed 0
[2019-08-17 22:50:37.054][14][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:41] Adding host 172.31.24.143:80.
[2019-08-17 22:50:37.054][7][debug][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 1 removed 0
[2019-08-17 22:50:37.054][7][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:41] Adding host 172.31.24.143:80.
[2019-08-17 22:50:37.056][13][debug][router] [external/envoy/source/common/router/router.cc:994] [C0][S4390330287188786749] upstream headers complete: end_stream=false
[2019-08-17 22:50:37.056][13][debug][http] [external/envoy/source/common/http/conn_manager_impl.cc:1378] [C0][S4390330287188786749] encoding headers via codec (end_stream=false):
':status', '200'
'server', 'envoy'
'date', 'Sat, 17 Aug 2019 22:50:36 GMT'
'content-type', 'text/html; charset=utf-8'
'content-length', '9593'
'access-control-allow-origin', '*'
'access-control-allow-credentials', 'true'
'x-envoy-upstream-service-time', '2'

[2019-08-17 22:50:37.056][13][debug][client] [external/envoy/source/common/http/codec_client.cc:95] [C1] response complete
[2019-08-17 22:50:37.056][13][debug][pool] [external/envoy/source/common/http/http1/conn_pool.cc:198] [C1] response complete
[2019-08-17 22:50:37.056][13][debug][pool] [external/envoy/source/common/http/http1/conn_pool.cc:236] [C1] moving to ready
[2019-08-17 22:50:37.057][13][debug][connection] [external/envoy/source/common/network/connection_impl.cc:520] [C0] remote close
[2019-08-17 22:50:37.057][13][debug][connection] [external/envoy/source/common/network/connection_impl.cc:190] [C0] closing socket: 0
[2019-08-17 22:50:37.057][13][debug][main] [external/envoy/source/server/connection_handler_impl.cc:80] [C0] adding to cleanup list
[2019-08-17 22:50:37.270][7][debug][main] [external/envoy/source/server/server.cc:170] flushing stats
[2019-08-17 22:50:37.270][7][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:170] Cleaning up stale original dst hosts.
[2019-08-17 22:50:37.270][7][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:173] Keeping active host 172.31.24.143:80.
[2019-08-17 22:50:39.057][13][debug][connection] [external/envoy/source/common/network/connection_impl.cc:520] [C1] remote close
[2019-08-17 22:50:39.057][13][debug][connection] [external/envoy/source/common/network/connection_impl.cc:190] [C1] closing socket: 0
[2019-08-17 22:50:39.057][13][debug][client] [external/envoy/source/common/http/codec_client.cc:82] [C1] disconnect. resetting 0 pending requests
[2019-08-17 22:50:39.057][13][debug][pool] [external/envoy/source/common/http/http1/conn_pool.cc:129] [C1] client disconnected, failure reason:
[2019-08-17 22:50:42.267][7][debug][main] [external/envoy/source/server/server.cc:170] flushing stats
[2019-08-17 22:50:42.267][7][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:170] Cleaning up stale original dst hosts.
[2019-08-17 22:50:42.267][7][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:177] Removing stale host 172.31.24.143:80.
[2019-08-17 22:50:42.267][7][debug][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 0 removed 1
[2019-08-17 22:50:42.267][7][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:36] Removing host 172.31.24.143:80.
[2019-08-17 22:50:42.267][14][debug][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 0 removed 1
[2019-08-17 22:50:42.267][14][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:36] Removing host 172.31.24.143:80.
[2019-08-17 22:50:42.267][13][debug][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster cluster1 added 0 removed 1
[2019-08-17 22:50:42.267][14][debug][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster cluster1 removed 1
[2019-08-17 22:50:42.267][7][debug][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster cluster1 removed 1
[2019-08-17 22:50:42.267][13][debug][upstream] [external/envoy/source/common/upstream/original_dst_cluster.cc:36] Removing host 172.31.24.143:80.
[2019-08-17 22:50:42.267][13][debug][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster cluster1 removed 1
```

## 6. Cleaning

### 6.1 Router

```
./clean_envoy_docker.sh
./clean_iptables.sh
```

### 6.2 Web Server

```
./clean_web_docker.sh
```