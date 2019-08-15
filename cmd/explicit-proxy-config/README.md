# Tutorial

**This was tested on Ubuntu 18.04**

This example uses the same container as the Envoy Forward Proxy example but instead of using IPTables to redirect packets, we set HTTP Proxy environment variables.

Reference for [Ubuntu Proxy settings](https://askubuntu.com/questions/175172/how-do-i-configure-proxies-without-gui)

## Envoy Docker

Go to the [forward-proxy](../forward-proxy) directory, build and run the envoy container:

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

## Environment variables

Now execute the script to set the environment variables

```
source ./set_proxy.sh
```

## HTTP Request

Access to websites on ports 80 and 443 should go through the envoy proxy. Noticed the *x-envoy-upstream-service-time: 1* HTTP header

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
< date: Thu, 15 Aug 2019 05:10:24 GMT
< via: 1.1 varnish
< set-cookie: countryCode=US; Domain=.cnn.com; Path=/
< set-cookie: geoData=san jose|CA|95123|US|NA|-700|broadband; Domain=.cnn.com; Path=/
< x-served-by: cache-pao17436-PAO
< x-cache: HIT
< x-cache-hits: 0
< x-envoy-upstream-service-time: 1
<
* Connection #0 to host localhost left intact
```

## Envoy Logs

Envoy Logs for successful run.

```
2019-08-15 05:10:24.424][14][debug][main] [source/server/connection_handler_impl.cc:280] [C2] new connection
[2019-08-15 05:10:24.424][14][debug][http] [source/common/http/conn_manager_impl.cc:246] [C2] new stream
[2019-08-15 05:10:24.424][14][debug][http] [source/common/http/conn_manager_impl.cc:600] [C2][S7378197138069735321] request headers complete (end_stream=true):
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'proxy-connection', 'Keep-Alive'

[2019-08-15 05:10:24.424][14][debug][http] [source/common/http/conn_manager_impl.cc:1092] [C2][S7378197138069735321] request end stream
[2019-08-15 05:10:24.424][14][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:44] thread local lookup for host 'www.cnn.com'
[2019-08-15 05:10:24.424][14][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:58] thread local miss for host 'www.cnn.com', posting to main thread
[2019-08-15 05:10:24.424][14][debug][forward_proxy] [source/extensions/filters/http/dynamic_forward_proxy/proxy_filter.cc:83] [C2][S7378197138069735321] waiting to load DNS cache entry
[2019-08-15 05:10:24.424][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:135] starting main thread resolve for host='www.cnn.com' dns='www.cnn.com' port='80'
[2019-08-15 05:10:24.427][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:148] main thread resolve complete for host 'www.cnn.com'. 1 results
[2019-08-15 05:10:24.427][7][debug][forward_proxy] [source/extensions/common/dynamic_forward_proxy/dns_cache_impl.cc:181] host 'www.cnn.com' address has changed
[2019-08-15 05:10:24.427][7][debug][upstream] [source/extensions/clusters/dynamic_forward_proxy/cluster.cc:84] adding new dfproxy cluster host 'www.cnn.com'
[2019-08-15 05:10:24.427][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2019-08-15 05:10:24.427][7][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-15 05:10:24.427][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2019-08-15 05:10:24.427][13][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-15 05:10:24.427][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:999] membership update for TLS cluster dynamic_forward_proxy_cluster added 1 removed 0
[2019-08-15 05:10:24.427][14][debug][upstream] [source/common/upstream/cluster_manager_impl.cc:1006] re-creating local LB for TLS cluster dynamic_forward_proxy_cluster
[2019-08-15 05:10:24.427][14][debug][forward_proxy] [source/extensions/filters/http/dynamic_forward_proxy/proxy_filter.cc:100] [C2][S7378197138069735321] load DNS cache complete, continuing
[2019-08-15 05:10:24.427][14][debug][router] [source/common/router/router.cc:401] [C2][S7378197138069735321] cluster 'dynamic_forward_proxy_cluster' match for URL '/'
[2019-08-15 05:10:24.427][14][debug][router] [source/common/router/router.cc:514] [C2][S7378197138069735321] router decoding headers:
':authority', 'www.cnn.com'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.58.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '561e228d-2d09-49ae-93b5-f461ea48e476'
'x-envoy-expected-rq-timeout-ms', '15000'

[2019-08-15 05:10:24.427][14][debug][pool] [source/common/http/http1/conn_pool.cc:88] creating a new connection
[2019-08-15 05:10:24.427][14][debug][client] [source/common/http/codec_client.cc:26] [C3] connecting
[2019-08-15 05:10:24.427][14][debug][connection] [source/common/network/connection_impl.cc:702] [C3] connecting to 151.101.189.67:80
[2019-08-15 05:10:24.427][14][debug][connection] [source/common/network/connection_impl.cc:711] [C3] connection in progress
[2019-08-15 05:10:24.427][14][debug][pool] [source/common/http/conn_pool_base.cc:20] queueing request due to no available connections
[2019-08-15 05:10:24.428][14][debug][connection] [source/common/network/connection_impl.cc:550] [C3] connected
[2019-08-15 05:10:24.428][14][debug][client] [source/common/http/codec_client.cc:64] [C3] connected
[2019-08-15 05:10:24.428][14][debug][pool] [source/common/http/http1/conn_pool.cc:241] [C3] attaching to next request
[2019-08-15 05:10:24.428][14][debug][router] [source/common/router/router.cc:1503] [C2][S7378197138069735321] pool ready
[2019-08-15 05:10:24.429][14][debug][client] [source/common/http/codec_client.cc:95] [C3] response complete
[2019-08-15 05:10:24.429][14][debug][router] [source/common/router/router.cc:994] [C2][S7378197138069735321] upstream headers complete: end_stream=true
[2019-08-15 05:10:24.429][14][debug][http] [source/common/http/conn_manager_impl.cc:1359] [C2][S7378197138069735321] encoding headers via codec (end_stream=true):
':status', '301'
'server', 'envoy'
'retry-after', '0'
'content-length', '0'
'cache-control', 'public, max-age=600'
'location', 'https://www.cnn.com/'
'accept-ranges', 'bytes'
'date', 'Thu, 15 Aug 2019 05:10:24 GMT'
'via', '1.1 varnish'
'set-cookie', 'countryCode=US; Domain=.cnn.com; Path=/'
'set-cookie', 'geoData=san jose|CA|95123|US|NA|-700|broadband; Domain=.cnn.com; Path=/'
'x-served-by', 'cache-pao17436-PAO'
'x-cache', 'HIT'
'x-cache-hits', '0'
'x-envoy-upstream-service-time', '1'

[2019-08-15 05:10:24.429][14][debug][pool] [source/common/http/http1/conn_pool.cc:198] [C3] response complete
[2019-08-15 05:10:24.429][14][debug][pool] [source/common/http/http1/conn_pool.cc:203] [C3] saw upstream close connection
[2019-08-15 05:10:24.429][14][debug][connection] [source/common/network/connection_impl.cc:101] [C3] closing data_to_write=0 type=1
[2019-08-15 05:10:24.429][14][debug][connection] [source/common/network/connection_impl.cc:188] [C3] closing socket: 1
[2019-08-15 05:10:24.429][14][debug][client] [source/common/http/codec_client.cc:82] [C3] disconnect. resetting 0 pending requests
[2019-08-15 05:10:24.429][14][debug][pool] [source/common/http/http1/conn_pool.cc:129] [C3] client disconnected, failure reason:
[2019-08-15 05:10:24.429][14][debug][connection] [source/common/network/connection_impl.cc:518] [C3] remote close
[2019-08-15 05:10:24.430][14][debug][connection] [source/common/network/connection_impl.cc:518] [C2] remote close
[2019-08-15 05:10:24.430][14][debug][connection] [source/common/network/connection_impl.cc:188] [C2] closing socket: 0
[2019-08-15 05:10:24.430][14][debug][main] [source/server/connection_handler_impl.cc:80] [C2] adding to cleanup list
```

## Cleaning

```
source ./unset_proxy.sh
```

Go to the [forward-proxy](../forward-proxy) directory and execute

```
./clean_envoy_proxy
```



