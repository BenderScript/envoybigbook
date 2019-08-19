#!/usr/bin/env python3

# Small program to demonstrate how to get original IP:port from redirected connections
# https://tor.stackexchange.com/questions/16654/how-can-i-verify-that-transport-is-working-correctly

import socket
from struct import unpack
if __name__ == '__main__':
    print("Starting")
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0',4999))
    s.listen(1)
    conn, addr = s.accept()
    orig = conn.getsockopt(socket.SOL_IP, 80, 16) # 80 is socket.SO_ORIGINAL_DST but python doesn't define it.
    port, ip = unpack("!2xH4s8x", orig)
    print('{}:{}'.format(socket.inet_ntoa(ip), port))