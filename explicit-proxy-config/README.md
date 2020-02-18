# Tutorial

**This was tested on Ubuntu 18.04.3 LTS**

This example uses the same container as the Envoy Forward Proxy example but instead of using IPTables to redirect packets, we set HTTP Proxy environment variables.

Reference for [Ubuntu Proxy settings](https://askubuntu.com/questions/175172/how-do-i-configure-proxies-without-gui)

## 1. Network Diagram

In this tutorial we use a single host where we run the HTTP client and Envoy Proxy. The Web Server can be any accessible Internet web site.

## 2. Envoy Docker

Go to the [forward-proxy](../forward-proxy) directory, build and run the envoy container:

```
./build_envoy_docker.sh
```

Make sure you are still able to access the Internet unhindered

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
< Server: Varnish
< Retry-After: 0
< Content-Length: 0
< Cache-Control: public, max-age=600
< Location: https://www.cnn.com/
< Accept-Ranges: bytes
< Date: Tue, 18 Feb 2020 06:11:20 GMT
< Via: 1.1 varnish
< Connection: close
< Set-Cookie: countryCode=US; Domain=.cnn.com; Path=/; SameSite=Lax
< Set-Cookie: geoData=san jose|CA|95123|US|NA|-800|broadband; Domain=.cnn.com; Path=/; SameSite=Lax
< X-Served-By: cache-sjc10048-SJC
< X-Cache: HIT
< X-Cache-Hits: 0
<
* Closing connection 0
```

## 3. Environment variables

Now execute the script to set the environment variables

```
source ./set_proxy.sh
```

## 4. HTTP Request

Access to websites on ports 80 and 443 should go through the envoy proxy. Noticed the *x-envoy-upstream-service-time: 3* HTTP header

```
ubuntu$ curl -v www.cnn.com
* Rebuilt URL to: www.cnn.com/
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 4999 (#0)
> GET http://www.cnn.com/ HTTP/1.1
> Host: www.cnn.com
> User-Agent: curl/7.58.0
> Accept: */*
> Proxy-Connection: Keep-Alive
>
< HTTP/1.1 301 Moved Permanently
< server: envoy
< retry-after: 0
< content-length: 0
< cache-control: public, max-age=600
< location: https://www.cnn.com/
< accept-ranges: bytes
< date: Tue, 18 Feb 2020 06:15:48 GMT
< via: 1.1 varnish
< set-cookie: countryCode=US; Domain=.cnn.com; Path=/; SameSite=Lax
< set-cookie: geoData=san jose|CA|95123|US|NA|-800|broadband; Domain=.cnn.com; Path=/; SameSite=Lax
< x-served-by: cache-pao17446-PAO
< x-cache: HIT
< x-cache-hits: 0
< x-envoy-upstream-service-time: 3
<
* Connection #0 to host localhost left intact
```

## 5. Envoy Logs

Envoy Logs for successful run.

```
[2020-02-18 06:15:49.072][13][debug][conn_handler] [source/server/connection_handler_impl.cc:353] [C0] new connection
[2020-02-18 06:15:49.073][13][debug][http] [source/common/http/conn_manager_impl.cc:263] [C0] new stream
[2020-02-18 06:15:49.074][13][debug][http] [source/common/http/conn_manager_impl.cc:731] [C0][S12400113964677374341] request headers complete (end_stream=true):
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'proxy-connection', 'Keep-Alive'

[2020-02-18 06:15:49.074][13][debug][http] [source/common/http/conn_manager_impl.cc:1276] [C0][S12400113964677374341] request end stream
[2020-02-18 06:15:49.074][13][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:47] thread local lookup for host 'www.cnn.com'
[2020-02-18 06:15:49.074][13][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:61] thread local miss for host 'www.cnn.com', posting to main thread
[2020-02-18 06:15:49.074][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:133] starting main thread resolve for host='www.cnn.com' dns='www.cnn.com' port='80'
[2020-02-18 06:15:49.074][13][debug][forward_proxy] [source/extensions/filters/http/dynamic_forward_proxy/proxy_filter.cc:113] [C0][S12400113964677374341] waiting to load DNS cache entry
[2020-02-18 06:15:49.078][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:146] main thread resolve complete for host 'www.cnn.com'. 1 results
[2020-02-18 06:15:49.078][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:176] host 'www.cnn.com' address has changed
[2020-02-18 06:15:49.078][7][debug][upstream] [source/extensions/clusters/dynamic_forward_proxy/cluster.cc:101] adding new dfproxy cluster host 'www.cnn.com'
[2020-02-18 06:15:49.078][7][debug][upstream] [source/common/upstream/upstream_impl.cc:262] transport socket match, socket default selected for host with address 151.101.189.67:80
[2020-02-18 06:15:49.078][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1084] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2020-02-18 06:15:49.078][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1091] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2020-02-18 06:15:49.079][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1084] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2020-02-18 06:15:49.079][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1091] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2020-02-18 06:15:49.079][13][debug][forward_proxy] [source/extensions/filters/http/dynamic_forward_proxy/proxy_filter.cc:130] [C0][S12400113964677374341] load DNS cache complete, continuing
[2020-02-18 06:15:49.079][13][debug][router] [source/common/router/router.cc:474] [C0][S12400113964677374341] cluster 'dynamic_forward_proxy_cluster' match for URL '/'
[2020-02-18 06:15:49.079][13][debug][router] [source/common/router/router.cc:614] [C0][S12400113964677374341] router decoding headers:
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '51f89076-5172-464e-b3d9-d98605c17ecb'
'x-envoy-expected-rq-timeout-ms', '15000'

[2020-02-18 06:15:49.079][13][debug][pool] [source/common/http/http1/conn_pool.cc:95] creating a new connection
[2020-02-18 06:15:49.079][13][debug][client] [source/common/http/codec_client.cc:34] [C1] connecting
[2020-02-18 06:15:49.079][13][debug][connection] [source/common/network/connection_impl.cc:691] [C1] connecting to 151.101.189.67:80
[2020-02-18 06:15:49.079][13][debug][connection] [source/common/network/connection_impl.cc:700] [C1] connection in progress
[2020-02-18 06:15:49.079][13][debug][pool] [source/common/http/conn_pool_base.cc:55] queueing request due to no available connections
[2020-02-18 06:15:49.081][13][debug][connection] [source/common/network/connection_impl.cc:563] [C1] connected
[2020-02-18 06:15:49.081][13][debug][client] [source/common/http/codec_client.cc:72] [C1] connected
[2020-02-18 06:15:49.081][13][debug][pool] [source/common/http/http1/conn_pool.cc:244] [C1] attaching to next request
[2020-02-18 06:15:49.081][13][debug][router] [source/common/router/router.cc:1711] [C0][S12400113964677374341] pool ready
[2020-02-18 06:15:49.083][13][debug][client] [source/common/http/codec_client.cc:104] [C1] response complete
[2020-02-18 06:15:49.083][13][debug][router] [source/common/router/router.cc:1115] [C0][S12400113964677374341] upstream headers complete: end_stream=true
[2020-02-18 06:15:49.083][13][debug][http] [source/common/http/conn_manager_impl.cc:1615] [C0][S12400113964677374341] encoding headers via codec (end_stream=true):
':status', '301'
'server', 'envoy'
'retry-after', '0'
'content-length', '0'
'cache-control', 'public, max-age=600'
'location', 'https://www.cnn.com/'
'accept-ranges', 'bytes'
'date', 'Tue, 18 Feb 2020 06:15:48 GMT'
'via', '1.1 varnish'
'set-cookie', 'countryCode=US; Domain=.cnn.com; Path=/; SameSite=Lax'
'set-cookie', 'geoData=san jose|CA|95123|US|NA|-800|broadband; Domain=.cnn.com; Path=/; SameSite=Lax'
'x-served-by', 'cache-pao17446-PAO'
'x-cache', 'HIT'
'x-cache-hits', '0'
'x-envoy-upstream-service-time', '3'

[2020-02-18 06:15:49.083][13][debug][pool] [source/common/http/http1/conn_pool.cc:201] [C1] response complete
[2020-02-18 06:15:49.084][13][debug][pool] [source/common/http/http1/conn_pool.cc:206] [C1] saw upstream close connection
[2020-02-18 06:15:49.084][13][debug][connection] [source/common/network/connection_impl.cc:101] [C1] closing data_to_write=0 type=1
[2020-02-18 06:15:49.084][13][debug][connection] [source/common/network/connection_impl.cc:192] [C1] closing socket: 1
[2020-02-18 06:15:49.084][13][debug][client] [source/common/http/codec_client.cc:91] [C1] disconnect. resetting 0 pending requests
[2020-02-18 06:15:49.084][13][debug][pool] [source/common/http/http1/conn_pool.cc:136] [C1] client disconnected, failure reason:
[2020-02-18 06:15:49.084][13][debug][connection] [source/common/network/connection_impl.cc:531] [C1] remote close
[2020-02-18 06:15:49.085][13][debug][connection] [source/common/network/connection_impl.cc:531] [C0] remote close
[2020-02-18 06:15:49.085][13][debug][connection] [source/common/network/connection_impl.cc:192] [C0] closing socket: 0
[2020-02-18 06:15:49.085][13][debug][conn_handler] [source/server/connection_handler_impl.cc:86] [C0] adding to cleanup list
```

## 6. Cleaning

```
source ./unset_proxy.sh
```

Go to the [forward-proxy](../forward-proxy) directory and execute

```
./clean_envoy_docker.sh
```



