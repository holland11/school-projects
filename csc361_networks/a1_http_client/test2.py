"""
A simple example of using Python sockets for a client HTTPS connection.
"""

import ssl
import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('www.uvic.ca', 443))
s = ssl.wrap_socket(s)
msg = "HEAD / HTTP/1.1\r\nHost: www.uvic.ca\r\nConnection: close\r\n\r\n"
s.sendall(str.encode(msg))

while True:

    new = bytes.decode(s.recv(4096))
    if not new:
      s.close()
      break
    print(new)