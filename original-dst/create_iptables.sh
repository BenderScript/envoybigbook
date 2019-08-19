# Enable exit on non 0
set -e

sudo iptables -t nat -A OUTPUT -p tcp -m tcp --dport 80 -d  172.31.24.143 -m owner ! --uid-owner 0 -j REDIRECT --to-port 4999
