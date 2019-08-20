# Tutorial

**This was tested on Ubuntu 18.04**

In this example of we run a Forward Envoy Proxy that listens on port 4999 and directs requests to their original destination. 

The practical use-case is to confine applications running on the same host as the envoy proxy by using it as a forward proxy. Applications can not communicate directly out due IPTables rules.

## 1. Network Diagram

The HTTP Client (cURL) and Envoy proxy share the same host. cURL runs as a native application and Envoy runs in a docker container

A second host runs the web server

![You need to see the network diagram][./img/envoy_network.png]

## 2. Envoy Docker

Build and run the envoy container:

```
./build_envoy_docker.sh
```

Make sure you are still able to access the Internet unhindered

```
ubuntu$ curl -v www.cnn.com
* Rebuilt URL to: www.cnn.com/
*   Trying 151.101.189.67...
* TCP_NODELAY set
* Connected to www.cnn.com (151.101.189.67) port 80 (#0)
> GET / HTTP/1.1
> Host: www.cnn.com
> User-Agent: curl/7.58.0
> Accept: */*
>
< HTTP/1.1 301 Moved Permanently
< Server: Varnish
< Retry-After: 0
< Content-Length: 0
< Cache-Control: public, max-age=600
< Location: https://www.cnn.com/
< Accept-Ranges: bytes
< Date: Fri, 09 Aug 2019 15:39:41 GMT
< Via: 1.1 varnish
< Connection: close
< Set-Cookie: countryCode=US; Domain=.cnn.com; Path=/
< Set-Cookie: geoData=san jose|CA|95123|US|NA|-700|broadband; Domain=.cnn.com; Path=/
< X-Served-By: cache-pao17426-PAO
< X-Cache: HIT
< X-Cache-Hits: 0
<
* Closing connection 0
```

## 3. IPTables

Now install the IPtables redirect rules

```
./create_iptables.sh
```

## 4. HTTP Request

Access to websites on ports 80 and 443 should go through the envoy proxy. Noticed the *x-envoy-upstream-service-time: 1* HTTP header

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
< date: Fri, 09 Aug 2019 15:59:20 GMT
< via: 1.1 varnish
< set-cookie: countryCode=US; Domain=.cnn.com; Path=/
< set-cookie: geoData=san jose|CA|95123|US|NA|-700|broadband; Domain=.cnn.com; Path=/
< x-served-by: cache-sjc3131-SJC
< x-cache: HIT
< x-cache-hits: 0
< x-envoy-upstream-service-time: 1
<
* Connection #0 to host www.cnn.com left intact
```

## 5. IPTables Stats

IPTables statistics should show the redirected packets

```
ubuntu@ip-172-31-22-139:~/identity/cmd/forward-proxy$ sudo iptables -t nat -nvL OUTPUT
Chain OUTPUT (policy ACCEPT 17 packets, 1366 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER     all  --  *      *       0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
    1    60 REDIRECT   tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80 redir ports 4999
    0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443 redir ports 8443
```

## 6. Envoy Logs

Envoy Logs for successful run.

```
[2019-08-09 15:59:20.598][14][debug][main] [source/server/connection_handler_impl.cc:280] [C0] new connection
[2019-08-09 15:59:20.598][14][debug][http] [source/common/http/conn_manager_impl.cc:246] [C0] new stream
[2019-08-09 15:59:20.600][14][debug][http] [source/common/http/conn_manager_impl.cc:600] [C0][S8483825399140545134] request headers complete (end_stream=true):
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2019-08-09 15:59:20.600][14][debug][http] [source/common/http/conn_manager_impl.cc:1092] [C0][S8483825399140545134] request end stream
[2019-08-09 15:59:20.600][14][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:44] thread local lookup for host 'www.cnn.com'
[2019-08-09 15:59:20.600][14][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:58] thread local miss for host 'www.cnn.com', posting to main thread
[2019-08-09 15:59:20.600][14][debug][forward_proxy] [source/extensions/filters/http/dynamic_forward_proxy/proxy_filter.cc:83] [C0][S8483825399140545134] waiting to load DNS cache entry
[2019-08-09 15:59:20.600][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:135] starting main thread resolve for host='www.cnn.com' dns='www.cnn.com' port='80'
[2019-08-09 15:59:20.600][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:148] main thread resolve complete for host 'www.cnn.com'. 1 results
[2019-08-09 15:59:20.600][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:181] host 'www.cnn.com' address has changed
[2019-08-09 15:59:20.600][7][debug][upstream] [source/extensions/clusters/dynamic_forward_proxy/cluster.cc:84] adding new dfproxy cluster host 'www.cnn.com'
[2019-08-09 15:59:20.600][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2019-08-09 15:59:20.600][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-09 15:59:20.600][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2019-08-09 15:59:20.600][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-09 15:59:20.600][14][debug][forward_proxy] [source/extensions/filters/http/dynamic_forward_proxy/proxy_filter.cc:100] [C0][S8483825399140545134] load DNS cache complete, continuing
[2019-08-09 15:59:20.600][14][debug][router] [source/common/router/router.cc:401] [C0][S8483825399140545134] cluster 'dynamic_forward_proxy_cluster' match for URL '/'
[2019-08-09 15:59:20.600][14][debug][router] [source/common/router/router.cc:514] [C0][S8483825399140545134] router decoding headers:
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '3dd0b17b-6e17-40a7-963c-788c0a38cd35'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-08-09 15:59:20.600][14][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-08-09 15:59:20.600][14][debug][client] [source/common/http/codec_client.cc:26] [C1] connecting
[2019-08-09 15:59:20.600][14][debug][connection] [source/common/network/connection_impl.cc:702] [C1] connecting to 151.101.41.67:80
[2019-08-09 15:59:20.600][14][debug][connection] [source/common/network/connection_impl.cc:711] [C1] connection in progress
[2019-08-09 15:59:20.600][14][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-08-09 15:59:20.600][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2019-08-09 15:59:20.601][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-09 15:59:20.601][14][debug][connection] [source/common/network/connection_impl.cc:550] [C1] connected
[2019-08-09 15:59:20.601][14][debug][client] [source/common/http/codec_client.cc:64] [C1] connected
[2019-08-09 15:59:20.601][14][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C1] attaching to next request
[2019-08-09 15:59:20.601][14][debug][router] [source/common/router/router.cc:1503] [C0][S8483825399140545134] pool ready
[2019-08-09 15:59:20.602][14][debug][client] [source/common/http/codec_client.cc:95] [C1] response complete
[2019-08-09 15:59:20.602][14][debug][router] [source/common/router/router.cc:994] [C0][S8483825399140545134] upstream headers complete: end_stream=true
[2019-08-09 15:59:20.602][14][debug][http] [source/common/http/conn_manager_impl.cc:1359] [C0][S8483825399140545134] encoding headers via codec (end_stream=true):
':status', '301'
'server', 'envoy'
'retry-after', '0'
'content-length', '0'
'cache-control', 'public, max-age=600'
'location', 'https://www.cnn.com/'
'accept-ranges', 'bytes'
'date', 'Fri, 09 Aug 2019 15:59:20 GMT'
'via', '1.1 varnish'
'set-cookie', 'countryCode=US; Domain=.cnn.com; Path=/'
'set-cookie', 'geoData=san jose|CA|95123|US|NA|-700|broadband; Domain=.cnn.com; Path=/'
'x-served-by', 'cache-sjc3131-SJC'
'x-cache', 'HIT'
'x-cache-hits', '0'
'x-envoy-upstream-service-time', '1'

[2019-08-09 15:59:20.602][14][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C1] response complete
[2019-08-09 15:59:20.602][14][debug][pool] [source/common/http/http1/conn_pool.cc:203] [C1] saw upstream close connection
[2019-08-09 15:59:20.602][14][debug][connection] [source/common/network/connection_impl.cc:101] [C1] closing data_to_write=0 type=1
[2019-08-09 15:59:20.602][14][debug][connection] [source/common/network/connection_impl.cc:188] [C1] closing socket: 1
[2019-08-09 15:59:20.602][14][debug][client] [source/common/http/codec_client.cc:82] [C1] disconnect. resetting 0 pending requests
[2019-08-09 15:59:20.602][14][debug][pool] [source/common/http/http1/conn_pool.cc:129] [C1] client disconnected, failure reason:
[2019-08-09 15:59:20.603][14][debug][connection] [source/common/network/connection_impl.cc:518] [C0] remote close
[2019-08-09 15:59:20.603][14][debug][connection] [source/common/network/connection_impl.cc:188] [C0] closing socket: 0
[2019-08-09 15:59:20.603][14][debug][main] [source/server/connection_handler_impl.cc:80] [C0] adding to cleanup list
```

## 7. Cleaning

```
./clean_envoy_docker.sh
./clean_iptables.sh
```



