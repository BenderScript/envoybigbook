# Tutorial

In this example of we run a Envoy Proxy on that listens on port 4999 and redirects request to a server running on port 5000.
 
 The web server should run as a native application and not inside a container. This was a requirements in order to easily debug request issues.

Build the envoy container:

```
docker build -t simple-proxy .
``` 

Run the container:

```
docker run -d -p 4999:4999 -p 19000:19000 simple-proxy
```

Without a web server a request would look like this:

```
curl -v http://localhost:4999/

*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 4999 (#0)
> GET / HTTP/1.1
> Host: localhost:4999
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 503 Service Unavailable
< content-length: 57
< content-type: text/plain
< date: Mon, 05 Aug 2019 06:40:42 GMT
< server: envoy
<
* Connection #0 to host localhost left intact
```




