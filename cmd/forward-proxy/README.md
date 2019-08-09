# Tutorial

**This was tested on Ubuntu 18.04**

In this example of we run a Forward Envoy Proxy that listens on port 4999 and after processing directs requests to their original destination. 

The use-case is applications running on the same host as the envoy proxy using it as a forward proxy. Applications can not communicate directly out to due IPTables rules.

Make sure you are able to access the Internet unhindered

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

Now install the IPtables redirect rules

```
./create_iptables.sh
```

Access to websites on ports 80 and 443 should fail

```
ubuntu$ curl -v www.cnn.com
* Rebuilt URL to: www.cnn.com/
*   Trying 151.101.189.67...
* TCP_NODELAY set
* connect to 151.101.189.67 port 80 failed: Connection refused
*   Trying 2a04:4e42:a::323...
* TCP_NODELAY set
* Immediate connect fail for 2a04:4e42:a::323: Network is unreachable
*   Trying 2a04:4e42:a::323...
* TCP_NODELAY set
* Immediate connect fail for 2a04:4e42:a::323: Network is unreachable
* Failed to connect to www.cnn.com port 80: Connection refused
* Closing connection 0
curl: (7) Failed to connect to www.cnn.com port 80: Connection refused
```

Build and run the envoy container:

```
./build_docker.sh
``` 




