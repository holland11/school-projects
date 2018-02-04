import socket
import ssl

buffer = 1028

def main():
	host = 'www.google.ca'
	port = 80
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.connect((host,port))
	#s = ssl.wrap_socket(s)
	#s.settimeout(2.5)
	message = "GET / HTTP/1.1\r\nHost: "+host+"\r\n\r\n"
	s.sendall(str.encode(message))
	while True:
		try:
			response = s.recv(buffer)
		except socket.timeout:
			break
		if (response == b'') or (not response):
			break
		print(response.decode('latin-1'))
	s.close()

if __name__ == "__main__":
	main()