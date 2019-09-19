# Enable exit on non 0
set -e

sudo iptables -t nat -D OUTPUT -p tcp -m tcp --dport 80 -m owner ! --uid-owner 0 -j REDIRECT --to-port 4999
sudo iptables -t nat -D OUTPUT -p tcp -m tcp --dport 443 -m owner ! --uid-owner 0 -j REDIRECT --to-ports 8443