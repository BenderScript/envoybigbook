# TPROXY on AWS Ubuntu

# https://www.kernel.org/doc/Documentation/networking/tproxy.txt
# https://github.com/tinyproxy/tinyproxy/issues/181



MACHINE=$(uname -r)
# grep TPROXY /boot/config-4.15.0-1044-aws
grep TPROXY /boot/config-"$MACHINE"

ls /lib/modules/"$MACHINE"/kernel/net/netfilter/ | grep TPROXY

# File name is usually xt_TPROXY.ko

# check if module could be loaded

sudo modprobe -v -n xt_TPROXY

# Is module already loaded

lsmod | grep -i tproxy

# LOAD module

sudo modprobe -v xt_TPROXY

# Check if Module is loaded

lsmod | grep -i tproxy

# check for iptables extension 'socket'

sudo iptables -m socket --help

#
# ...
# socket match options:
#  --nowildcard     Do not ignore LISTEN sockets bound on INADDR_ANY
#  --transparent    Ignore non-transparent sockets
#  --restore-skmark Set the packet mark to the socket mark if
#                   the socket matches and transparent /
#                   nowildcard conditions are satisfied

sudo iptables -j TPROXY --help
