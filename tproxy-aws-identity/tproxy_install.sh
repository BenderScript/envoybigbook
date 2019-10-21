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

# LOAD module

sudo modprobe -v xt_TPROXY

# Check if Module is loaded

lsmod | grep -i tproxy

# check for iptables extension 'socket'


if sudo iptables -m socket --help | grep -q "socket match options"; then
    printf "%s\n" "IPTables Socket option is present"
else
    printf "%s\n" "IPTables Socket option not found"
    exit 1
fi

#
# ...
# socket match options:
#  --nowildcard     Do not ignore LISTEN sockets bound on INADDR_ANY
#  --transparent    Ignore non-transparent sockets
#  --restore-skmark Set the packet mark to the socket mark if
#                   the socket matches and transparent /
#                   nowildcard conditions are satisfied

if sudo iptables -j TPROXY --help | grep -q "TPROXY target options"; then
    printf "%s\n" "IPTables TPROXY option is present"
else
    printf "%s\n" "IPTables TPROXY option not found"
    exit 1
fi

