# Enable exit on non 0
set -e

sudo iptables -t nat -A OUTPUT -p tcp -m tcp --dport 80 -j REDIRECT --to-port 4999
sudo iptables -t nat -A OUTPUT -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 8443

sudo iptables -t nat -L --line-numbers
#Chain PREROUTING (policy ACCEPT)
#num  target     prot opt source               destination
#1    DOCKER     all  --  anywhere             anywhere             ADDRTYPE match dst-type LOCAL
#
#Chain INPUT (policy ACCEPT)
#num  target     prot opt source               destination
#
#Chain OUTPUT (policy ACCEPT)
#num  target     prot opt source               destination
#1    DOCKER     all  --  anywhere            !localhost/8          ADDRTYPE match dst-type LOCAL
#2    REDIRECT   tcp  --  anywhere             anywhere             tcp dpt:http redir ports 4999
#
#Chain POSTROUTING (policy ACCEPT)
#num  target     prot opt source               destination
#1    MASQUERADE  all  --  ip-172-17-0-0.us-west-1.compute.internal/16  anywhere
#
#Chain DOCKER (2 references)
#num  target     prot opt source               destination
#1    RETURN     all  --  anywhere             anywhere

# Deleting
# sudo iptables -t nat -D OUTPUT 2