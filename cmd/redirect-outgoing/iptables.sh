# Enable exit on non 0
set -e

sudo iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 4999
