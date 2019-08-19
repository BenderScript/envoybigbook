# Tutorial

In this simple example of we run a Web Server on port 5000 and add an IPTable rule to redirect port 4999 to port 5000.

Build the code with:

```
go build
``` 

Run the server:

```
./identity
```

Then we install an IPtables rule to redirect port 4999 to 5000

```
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 4999 -j REDIRECT --to-port 5000
```

Test to see if everything is working

```
curl http://"$HOST":4999/
Hello, World!
```

We can list the IPTables rules

```
sudo iptables -t nat -L -n -v

Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    8  2063 DOCKER     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
    0     0 REDIRECT   tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:4999 redir ports 5000
```

## Docker Image

Build docker image

```
docker build -t identity-simple .
```
Run container

```
docker run -p 5000:5000 identity-simple
```

