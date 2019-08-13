# Enable exit on non 0
set -e

sudo iptables -t nat -D OUTPUT 2
