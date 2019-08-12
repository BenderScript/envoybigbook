# Logs from Successful Test

Client (cURL) makes a request to http://httpbin.org that is redirect to Envoy Proxy running inside container.

Envoy Proxy proxies the connection and sends response to client.


## CONNECTION FROM HOST

First we test a direct connection from host without IPTables redirection in place

```
ubuntu:~$ curl -v http://httpbin.org
* Rebuilt URL to: http://httpbin.org/
*   Trying 3.223.234.9...
* TCP_NODELAY set
* Connected to httpbin.org (3.223.234.9) port 80 (#0)
> GET / HTTP/1.1
> Host: httpbin.org
> User-Agent: curl/7.58.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Access-Control-Allow-Credentials: true
< Access-Control-Allow-Origin: *
< Content-Type: text/html; charset=utf-8
< Date: Mon, 12 Aug 2019 00:17:00 GMT
< Referrer-Policy: no-referrer-when-downgrade
< Server: nginx
< X-Content-Type-Options: nosniff
< X-Frame-Options: DENY
< X-XSS-Protection: 1; mode=block
< Content-Length: 9593
< Connection: keep-alive
```

## CONNECTION FROM INSIDE CONTAINER

Now we test a direct connection from inside container without IPtables redirection in place

```
root@7919a9a0f577:/# curl -v httpbin.org
* Rebuilt URL to: httpbin.org/
*   Trying 3.223.234.9...
* Connected to httpbin.org (3.223.234.9) port 80 (#0)
> GET / HTTP/1.1
> Host: httpbin.org
> User-Agent: curl/7.47.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Access-Control-Allow-Credentials: true
< Access-Control-Allow-Origin: *
< Content-Type: text/html; charset=utf-8
< Date: Mon, 12 Aug 2019 00:17:43 GMT
< Referrer-Policy: no-referrer-when-downgrade
< Server: nginx
< X-Content-Type-Options: nosniff
< X-Frame-Options: DENY
< X-XSS-Protection: 1; mode=block
< Content-Length: 9593
< Connection: keep-alive
<
```

## ENVOY LOGS FROM REDIRECTED CONNECTION

We add IPTables rules in place and resend request. These are the captured Envoy logs.

```
[2019-08-12 00:25:31.349][13][debug][main] [source/server/connection_handler_impl.cc:280] [C0] new connection
[2019-08-12 00:25:31.349][13][debug][http] [source/common/http/conn_manager_impl.cc:246] [C0] new stream
[2019-08-12 00:25:31.350][13][debug][http] [source/common/http/conn_manager_impl.cc:600] [C0][S12139966976849869367] request headers complete (end_stream=true):
':authority', 'httpbin.org'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2019-08-12 00:25:31.350][13][debug][http] [source/common/http/conn_manager_impl.cc:1092] [C0][S12139966976849869367] request end stream
[2019-08-12 00:25:31.350][13][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:44] thread local lookup for host 'httpbin.org'
[2019-08-12 00:25:31.350][13][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:58] thread local miss for host 'httpbin.org', posting to main thread
[2019-08-12 00:25:31.350][13][debug][forward_proxy] [source/extensions/filters/http/dynamic_forward_proxy/proxy_filter.cc:83] [C0][S12139966976849869367] waiting to load DNS cache entry
[2019-08-12 00:25:31.350][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:135] starting main thread resolve for host='httpbin.org' dns='httpbin.org' port='80'
[2019-08-12 00:25:31.351][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:148] main thread resolve complete for host 'httpbin.org'. 2 results
[2019-08-12 00:25:31.351][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:181] host 'httpbin.org' address has changed
[2019-08-12 00:25:31.351][7][debug][upstream] [source/extensions/clusters/dynamic_forward_proxy/cluster.cc:84] adding new dfproxy cluster host 'httpbin.org'
[2019-08-12 00:25:31.351][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2019-08-12 00:25:31.351][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-12 00:25:31.351][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2019-08-12 00:25:31.351][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-12 00:25:31.351][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2019-08-12 00:25:31.351][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-12 00:25:31.351][13][debug][forward_proxy] [source/extensions/filters/http/dynamic_forward_proxy/proxy_filter.cc:100] [C0][S12139966976849869367] load DNS cache complete, continuing
[2019-08-12 00:25:31.351][13][debug][router] [source/common/router/router.cc:401] [C0][S12139966976849869367] cluster 'dynamic_forward_proxy_cluster' match for URL '/'
[2019-08-12 00:25:31.351][13][debug][router] [source/common/router/router.cc:514] [C0][S12139966976849869367] router decoding headers:
':authority', 'httpbin.org'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', 'e2f8dd39-fdba-4b05-9118-0ab24fa9e2b4'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-08-12 00:25:31.351][13][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-08-12 00:25:31.351][13][debug][client] [source/common/http/codec_client.cc:26] [C1] connecting
[2019-08-12 00:25:31.351][13][debug][connection] [source/common/network/connection_impl.cc:702] [C1] connecting to 52.22.188.80:80
[2019-08-12 00:25:31.351][13][debug][connection] [source/common/network/connection_impl.cc:711] [C1] connection in progress
[2019-08-12 00:25:31.351][13][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-08-12 00:25:31.410][13][debug][connection] [source/common/network/connection_impl.cc:550] [C1] connected
[2019-08-12 00:25:31.410][13][debug][client] [source/common/http/codec_client.cc:64] [C1] connected
[2019-08-12 00:25:31.410][13][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C1] attaching to next request
[2019-08-12 00:25:31.410][13][debug][router] [source/common/router/router.cc:1503] [C0][S12139966976849869367] pool ready
[2019-08-12 00:25:31.474][13][debug][router] [source/common/router/router.cc:994] [C0][S12139966976849869367] upstream headers complete: end_stream=false
[2019-08-12 00:25:31.474][13][debug][http] [source/common/http/conn_manager_impl.cc:1359] [C0][S12139966976849869367] encoding headers via codec (end_stream=false):
':status', '200'
'access-control-allow-credentials', 'true'
'access-control-allow-origin', '*'
'content-type', 'text/html; charset=utf-8'
'date', 'Mon, 12 Aug 2019 00:25:31 GMT'
'referrer-policy', 'no-referrer-when-downgrade'
'server', 'envoy'
'x-content-type-options', 'nosniff'
'x-frame-options', 'DENY'
'x-xss-protection', '1; mode=block'
'content-length', '9593'
'x-envoy-upstream-service-time', '122'

[2019-08-12 00:25:31.474][13][debug][client] [source/common/http/codec_client.cc:95] [C1] response complete
[2019-08-12 00:25:31.474][13][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C1] response complete
[2019-08-12 00:25:31.474][13][debug][pool] [source/common/http/http1/conn_pool.cc:236] [C1] moving to ready
[2019-08-12 00:25:31.475][13][debug][connection] [source/common/network/connection_impl.cc:518] [C0] remote close
[2019-08-12 00:25:31.475][13][debug][connection] [source/common/network/connection_impl.cc:188] [C0] closing socket: 0
[2019-08-12 00:25:31.475][13][debug][main] [source/server/connection_handler_impl.cc:80] [C0] adding to cleanup list
[2019-08-12 00:25:35.116][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:25:40.119][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:25:45.124][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:25:50.128][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:25:55.132][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:00.136][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:05.139][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:10.143][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:15.148][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:20.152][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:25.155][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:30.159][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:31.352][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:122] host='httpbin.org' TTL check: now=274266548494774 last_used=274206547823044
[2019-08-12 00:26:31.352][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:135] starting main thread resolve for host='httpbin.org' dns='httpbin.org' port='80'
[2019-08-12 00:26:31.370][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:148] main thread resolve complete for host 'httpbin.org'. 2 results
[2019-08-12 00:26:35.163][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:40.168][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:45.171][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:50.175][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:26:55.180][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:00.184][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:05.187][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:10.191][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:15.195][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:20.200][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:25.204][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:30.207][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:31.371][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:122] host='httpbin.org' TTL check: now=274326568191110 last_used=274206547823044
[2019-08-12 00:27:31.371][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:135] starting main thread resolve for host='httpbin.org' dns='httpbin.org' port='80'
[2019-08-12 00:27:31.375][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:148] main thread resolve complete for host 'httpbin.org'. 2 results
[2019-08-12 00:27:35.211][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:40.216][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:45.219][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:50.223][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:27:55.225][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:00.231][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:05.236][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:10.239][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:15.241][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:20.247][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:25.252][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:30.253][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:31.377][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:122] host='httpbin.org' TTL check: now=274386574115388 last_used=274206547823044
[2019-08-12 00:28:31.377][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:135] starting main thread resolve for host='httpbin.org' dns='httpbin.org' port='80'
[2019-08-12 00:28:31.379][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:148] main thread resolve complete for host 'httpbin.org'. 2 results
[2019-08-12 00:28:31.379][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:181] host 'httpbin.org' address has changed
[2019-08-12 00:28:31.379][7][debug][upstream] [source/extensions/clusters/dynamic_forward_proxy/cluster.cc:79] updating dfproxy cluster host address 'httpbin.org'
[2019-08-12 00:28:35.257][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:40.264][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:45.267][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:50.272][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:28:55.276][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:00.277][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:05.284][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:10.288][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:15.289][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:20.296][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:25.300][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:30.301][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:31.381][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:122] host='httpbin.org' TTL check: now=274446578141831 last_used=274206547823044
[2019-08-12 00:29:31.381][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:135] starting main thread resolve for host='httpbin.org' dns='httpbin.org' port='80'
[2019-08-12 00:29:31.403][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:148] main thread resolve complete for host 'httpbin.org'. 2 results
[2019-08-12 00:29:35.308][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:40.309][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:45.313][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:50.317][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:29:55.321][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:30:00.325][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:30:05.331][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:30:10.333][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:30:15.339][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:30:20.344][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:30:25.348][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:30:30.349][7][debug][main] [source/server/server.cc:170] flushing stats
[2019-08-12 00:30:31.408][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:122] host='httpbin.org' TTL check: now=274506604781297 last_used=274206547823044
[2019-08-12 00:30:31.408][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:124] host='httpbin.org' TTL expired, removing
[2019-08-12 00:30:31.408][7][debug][upstream] [source/extensions/clusters/dynamic_forward_proxy/cluster.cc:125] removing dfproxy cluster host 'httpbin.org'
[2019-08-12 00:30:31.408][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 0 removed 1
[2019-08-12 00:30:31.408][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-12 00:30:31.408][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster dynamic_forward_proxy_cluster removed 1
[2019-08-12 00:30:31.408][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 0 removed 1
[2019-08-12 00:30:31.408][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-12 00:30:31.408][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster dynamic_forward_proxy_cluster removed 1
[2019-08-12 00:30:31.408][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 0 removed 1
[2019-08-12 00:30:31.408][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-12 00:30:31.408][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:981] removing hosts for TLS cluster dynamic_forward_proxy_cluster removed 1
[2019-08-12 00:30:31.408][13][debug][connection] [source/common/network/connection_impl.cc:101] [C1] closing data_to_write=0 type=1
[2019-08-12 00:30:31.408][13][debug][connection] [source/common/network/connection_impl.cc:188] [C1] closing socket: 1
[2019-08-12 00:30:31.408][13][debug][client] [source/common/http/codec_client.cc:82] [C1] disconnect. resetting 0 pending requests
[2019-08-12 00:30:31.408][13][debug][pool] [source/common/http/http1/conn_pool.cc:129] [C1] client disconnected, failure reason:
```
## IPTables Statistics

```
</html>ubuntu@ip-172-31-22-139:~$ sudo iptables -t nat -nvL OUTPUT
Chain OUTPUT (policy ACCEPT 9 packets, 764 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER     all  --  *      *       0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
    1    60 REDIRECT   tcp  --  *      *       0.0.0.0/0            3.223.234.9          mark match 0x0 tcp dpt:80 redir ports 4999
    0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            52.22.188.80         mark match 0x0 tcp dpt:80 redir ports 4999
 ```
