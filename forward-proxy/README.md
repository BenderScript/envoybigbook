# Tutorial

**This was tested on Ubuntu 18.04.3 LTS**

In this example of we run a [Dynamic Forward Envoy Proxy](https://www.envoyproxy.io/docs/envoy/v1.13.0/configuration/http/http_filters/dynamic_forward_proxy_filter) that listens on port 4999 and directs requests to their original destination. 

The practical use-case is to confine applications running on the same host as the envoy proxy by using it as a forward proxy. Applications can not communicate directly out due IPTables rules.

## 1. Network Diagram

The HTTP Client (cURL) and Envoy proxy share the same host. cURL runs as a native application and Envoy runs in a docker container

An optional second host could run a web server in case of a self-contained example. 

![You need to see the network diagram](./img/envoy_network.png)

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
< Date: Tue, 18 Feb 2020 06:44:10 GMT
< Via: 1.1 varnish
< Connection: close
< Set-Cookie: countryCode=US; Domain=.cnn.com; Path=/; SameSite=Lax
< Set-Cookie: geoData=san jose|CA|95123|US|NA|-800|broadband; Domain=.cnn.com; Path=/; SameSite=Lax
< X-Served-By: cache-pao17442-PAO
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

Access to websites on ports 80 and 443 should go through the envoy proxy. Noticed the *x-envoy-upstream-service-time: 3* HTTP header

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
< server: envoy
< retry-after: 0
< content-length: 0
< cache-control: public, max-age=600
< location: https://www.cnn.com/
< accept-ranges: bytes
< date: Tue, 18 Feb 2020 06:47:14 GMT
< via: 1.1 varnish
< set-cookie: countryCode=US; Domain=.cnn.com; Path=/; SameSite=Lax
< set-cookie: geoData=san jose|CA|95123|US|NA|-800|broadband; Domain=.cnn.com; Path=/; SameSite=Lax
< x-served-by: cache-pao17421-PAO
< x-cache: HIT
< x-cache-hits: 0
< x-envoy-upstream-service-time: 3
<
* Connection #0 to host www.cnn.com left intact
```

## 5. IPTables Stats

IPTables statistics should show the redirected packets

```
ubuntu$ ./show_iptables.sh
Chain OUTPUT (policy ACCEPT 13 packets, 1013 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER     all  --  *      *       0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
    2   120 REDIRECT   tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80 ! owner UID match 0 redir ports 4999
    0     0 REDIRECT   tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443 ! owner UID match 0 redir ports 8443
```

## 6. Envoy Logs

Envoy Logs for successful run.

```
[2020-02-18 06:48:12.588][13][debug][conn_handler] [source/server/connection_handler_impl.cc:353] [C2] new connection
[2020-02-18 06:48:12.588][13][debug][http] [source/common/http/conn_manager_impl.cc:263] [C2] new stream
[2020-02-18 06:48:12.588][13][debug][http] [source/common/http/conn_manager_impl.cc:731] [C2][S4358495654629944488] request headers complete (end_stream=true):
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'

[2020-02-18 06:48:12.588][13][debug][http] [source/common/http/conn_manager_impl.cc:1276] [C2][S4358495654629944488] request end stream
[2020-02-18 06:48:12.588][13][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:47] thread local lookup for host 'www.cnn.com'
[2020-02-18 06:48:12.588][13][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:51] thread local hit for host 'www.cnn.com'
[2020-02-18 06:48:12.588][13][debug][forward_proxy] [source/extensions/filters/http/dynamic_forward_proxy/proxy_filter.cc:108] [C2][S4358495654629944488] DNS cache entry already loaded, continuing
[2020-02-18 06:48:12.588][13][debug][router] [source/common/router/router.cc:474] [C2][S4358495654629944488] cluster 'dynamic_forward_proxy_cluster' match for URL '/'
[2020-02-18 06:48:12.589][13][debug][router] [source/common/router/router.cc:614] [C2][S4358495654629944488] router decoding headers:
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '2dc75550-e63e-4a61-922c-fa71b3411392'
'x-envoy-expected-rq-timeout-ms', '15000'

[2020-02-18 06:48:12.589][13][debug][pool] [source/common/http/http1/conn_pool.cc:95] creating a new connection
[2020-02-18 06:48:12.589][13][debug][client] [source/common/http/codec_client.cc:34] [C3] connecting
[2020-02-18 06:48:12.589][13][debug][connection] [source/common/network/connection_impl.cc:691] [C3] connecting to 151.101.189.67:80
[2020-02-18 06:48:12.589][13][debug][connection] [source/common/network/connection_impl.cc:700] [C3] connection in progress
[2020-02-18 06:48:12.589][13][debug][pool] [source/common/http/conn_pool_base.cc:55] queueing request due to no available connections
[2020-02-18 06:48:12.590][13][debug][connection] [source/common/network/connection_impl.cc:563] [C3] connected
[2020-02-18 06:48:12.590][13][debug][client] [source/common/http/codec_client.cc:72] [C3] connected
[2020-02-18 06:48:12.590][13][debug][pool] [source/common/http/http1/conn_pool.cc:244] [C3] attaching to next request
[2020-02-18 06:48:12.590][13][debug][router] [source/common/router/router.cc:1711] [C2][S4358495654629944488] pool ready
[2020-02-18 06:48:12.592][13][debug][client] [source/common/http/codec_client.cc:104] [C3] response complete
[2020-02-18 06:48:12.592][13][debug][router] [source/common/router/router.cc:1115] [C2][S4358495654629944488] upstream headers complete: end_stream=true
[2020-02-18 06:48:12.592][13][debug][http] [source/common/http/conn_manager_impl.cc:1615] [C2][S4358495654629944488] encoding headers via codec (end_stream=true):
':status', '301'
'server', 'envoy'
'retry-after', '0'
'content-length', '0'
'cache-control', 'public, max-age=600'
'location', 'https://www.cnn.com/'
'accept-ranges', 'bytes'
'date', 'Tue, 18 Feb 2020 06:48:12 GMT'
'via', '1.1 varnish'
'set-cookie', 'countryCode=US; Domain=.cnn.com; Path=/; SameSite=Lax'
'set-cookie', 'geoData=san jose|CA|95123|US|NA|-800|broadband; Domain=.cnn.com; Path=/; SameSite=Lax'
'x-served-by', 'cache-pao17438-PAO'
'x-cache', 'HIT'
'x-cache-hits', '0'
'x-envoy-upstream-service-time', '3'

[2020-02-18 06:48:12.592][13][debug][pool] [source/common/http/http1/conn_pool.cc:201] [C3] response complete
[2020-02-18 06:48:12.592][13][debug][pool] [source/common/http/http1/conn_pool.cc:206] [C3] saw upstream close connection
[2020-02-18 06:48:12.592][13][debug][connection] [source/common/network/connection_impl.cc:101] [C3] closing data_to_write=0 type=1
[2020-02-18 06:48:12.592][13][debug][connection] [source/common/network/connection_impl.cc:192] [C3] closing socket: 1
[2020-02-18 06:48:12.592][13][debug][client] [source/common/http/codec_client.cc:91] [C3] disconnect. resetting 0 pending requests
[2020-02-18 06:48:12.592][13][debug][pool] [source/common/http/http1/conn_pool.cc:136] [C3] client disconnected, failure reason:
[2020-02-18 06:48:12.593][13][debug][connection] [source/common/network/connection_impl.cc:531] [C2] remote close
[2020-02-18 06:48:12.593][13][debug][connection] [source/common/network/connection_impl.cc:192] [C2] closing socket: 0
[2020-02-18 06:48:12.593][13][debug][conn_handler] [source/server/connection_handler_impl.cc:86] [C2] adding to cleanup list
[2020-02-18 06:48:14.398][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:120] host='www.cnn.com' TTL check: now=45270372276985 last_used=45268562464739
[2020-02-18 06:48:14.398][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:133] starting main thread resolve for host='www.cnn.com' dns='www.cnn.com' port='80'
[2020-02-18 06:48:14.417][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:146] main thread resolve complete for host 'www.cnn.com'. 1 results
[2020-02-18 06:48:17.076][7][debug][main] [source/server/server.cc:174] flushing stats
```

## 7. Cleaning

```
./clean_envoy_docker.sh
./clean_iptables.sh
```



