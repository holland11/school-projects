'''
Patrick Holland
CSC 361 Assignment 1
Spring 2018

This assignment is to create a simple HTTP client.
The program makes a GET request to the webserver and retrieves the response.
It handles response codes 200, 301, 302, 307, 404, 505.
It also handles HTTP 2.0, 1.1, 1.0 and HTTPS.
With a 301, 302, or 307 it will redirect to the appropriate URL.
Cookies are displayed (just the key and domain, not the key's value).
It also displays whether HTTPS is supported and what the highest version of HTTP is supported by the webserver.

Example usage of program:
	**input**
$ python3 SmartClient.py www.google.ca
	**output**
website: www.google.ca
1. Support of HTTPS: yes
2. The newest HTTP version that the web ser
3. List of Cookies:
name: -, key: 1P_JAR, domain name: .google.
name: -, key: NID, domain name: .google.ca
'''

import socket
import ssl
import sys
import h2

test_sites = ['www.cbc.ca', 'www.uvic.ca', 'www.google.ca', 'www.mcgill.ca', 'www.youtube.com',
			  'www.akamai.com', 'www2.gov.bc.ca', 'www.python.org', 'www.aircanada.com', 'www.bbc.com']
'''
cbc: (1.1 http) 1
uvic: (1.1 https) 6
google: (1.1 http) (1.1 https) (2.0 https) 2
mcgill: (1.1 http) (1.1 https) (http2 ssl error) 3
youtube: (1.1 https) (2.0 https) 3
akamai: (1.1 https) (2.0 https) 0
gov: (1.1 https) (http2 ssl error) 1
python: (1.1 https) (2.0 https) 0
aircanada: (1.1 https redirect) 4
bbc: (1.1 http) (2.0 http) 1
'''
buffer = 2048

def main():
	'''
	program flow:
		using http 1.1, check if https is supported (if it is, get the cookies)
		using h2 module, check if http 2.0 is supported (establish connection but dont send any message)
		if we were unable to get an https connection, try regular http 1.1 connection (get cookies if successful)
		if we were unable to get https or http 1.1 connection, get cookies from http 1.0 connection
		
	notes:
		-when receiving data from server, <if (response == b'')> doesn't reliably signify the end of the data stream
			this causes some requests to stall indefinitely
			to counter this, i use socket.settimeout(3) to 'timeout' after 3 seconds without a response
			this doesn't seem ideal since maybe a webserver will respond after more than 3 seconds, but certain 
			requests were leaving me blocked by socket.recv() forever and this seemed like the simplest/only workaround
			(for example, a "GET / HTTP/1.1\r\nHost: www.google.ca\r\n\r\n" when connected to (www.google.ca, 80) causes
			this infinite wait/block unless i use socket.settimeout() )
			I tried checking each response size and breaking if it was less than my buffer size, but many responses which
			are not the final response don't use the entire buffer size so this didn't work.
			
		-when decoding the bytes that returned from socket.recv(), https://www.google.ca gives me this error:
			'utf-8' codec can't decode byte 0xe7
			to counter this, i changed response.decode() to response.decode('latin-1')
			
		-404 and 505 handling involves checking status codes whenever making a request. when these codes are found, 
			a message is printed to stdout specifying which code it was and which protocol was used.
	'''
	if (len(sys.argv) != 2):
		print("There must be exactly two command line arguments including SmartClient.py\nFor example: python SmartClient.py http://www.google.ca")
		sys.exit()
	host = truncate_hostname(sys.argv[1])

	https_success, cookies, http_1_1 = test_https(host, "/")
	http2_success = test_http2(host)
	http1_1_success = http2_success
	if (not http2_success):
		http1_1_success, backup_cookies = test_http1_1(host, "/")
		if (backup_cookies and not cookies):
			cookies = backup_cookies
	if (not cookies):
		cookies = get_cookies_http_1(host, "/")
	print("website: "+host)
	if (https_success):
		print("1. Support of HTTPS: yes")
	else:
		print("1. Support of HTTPS: no")
	if (http2_success):
		print("2. The newest HTTP version that the web server supports: HTTP/2.0")
	elif (http1_1_success or http_1_1):
		print("2. The newest HTTP version that the web server supports: HTTP/1.1")
	else:
		print("2. The newest HTTP version that the web server supports: HTTP/1.0")
	print("3. List of Cookies:")
	print_cookies(cookies)
	
def get_cookies_http_1(host, path):
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.settimeout(3)
	s.connect((host,80))
	s.sendall(str.encode("GET "+path+" HTTP/1.0\r\nHost: "+host+"\r\n\r\n"))
	response = ""
	while True:
		try:
			reply = s.recv(buffer)
		except socket.timeout:
			break
		if (reply == b''):
			break
		response += reply.decode('latin-1')
	s.close()
	if (response[9:12] == "200"):
		return fetch_cookies(response.split("\r\n\r\n",1)[0])
	elif (response[9:12] == "301" or response[9:12] == "302" or response[9:12] == "307"):
		port, new_host, new_path = get_path(response.split("\r\n\r\n",1)[0])
		if (port == 443):
			return None
		return get_cookies_http_1(s, new_host, new_path)
	elif (response[9:12] == "404" or response[9:12] == "505"):
		print("Received HTTP response code "+response[9:12]+" when trying to access "+host+path+" over HTTP/1.0.")
	return None
	
def test_http1_1(host, path):
	support = False
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.settimeout(3)
	s.connect((host,80))
	s.sendall(str.encode("GET "+path+" HTTP/1.1\r\nHost: "+host+"\r\n\r\n"))
	response = ""
	while True:
		try:
			reply = s.recv(buffer)
		except socket.timeout:
			break
		if (reply == b''):
			break
		response += reply.decode('latin-1')
	s.close()
	if (response[:8] == "HTTP/1.1"):
		support = True
	if (response[9:12] == "200"):
		return support, fetch_cookies(response.split("\r\n\r\n",1)[0])
	elif (response[9:12] == "301" or response[9:12] == "302" or response[9:12] == "307"):
		port, new_host, new_path = get_path(response.split("\r\n\r\n",1)[0])
		if (port == 443):
			return support, None
		return test_http1_1(s, new_host, new_path)
	elif (response[9:12] == "404" or response[9:12] == "505"):
		print("Received HTTP response code "+response[9:12]+" when trying to access "+host+path+" over HTTP/1.1.")
	return support, None
	
def test_http2(host):
	# this function and most of the functions it calls have been copied from https://python-hyper.org/projects/h2/en/stable/negotiating-http2.html
	try:
		context = get_http2_ssl_context()
		connection = socket.create_connection((host, 443))
		tls_connection = negotiate_tls(connection, context, host)
		connection.close()
	except ssl.SSLError:
		return False
	return tls_connection
	
def negotiate_tls(tcp_conn, context, host):
    """
    Given an established TCP connection and a HTTP/2-appropriate TLS context,
    this function:

    1. wraps TLS around the TCP connection.
    2. confirms that HTTP/2 was negotiated and, if it was not, throws an error.
    """
    # Note that SNI is mandatory for HTTP/2, so you *must* pass the
    # server_hostname argument.
    tls_conn = context.wrap_socket(tcp_conn, server_hostname=host)

    # Always prefer the result from ALPN to that from NPN.
    # You can only check what protocol was negotiated once the handshake is
    # complete.
    negotiated_protocol = tls_conn.selected_alpn_protocol()
    if negotiated_protocol is None:
        negotiated_protocol = tls_conn.selected_npn_protocol()

    if negotiated_protocol != "h2":
        return False

    return True
	
def get_http2_ssl_context():
    """
    This function creates an SSLContext object that is suitably configured for
    HTTP/2. If you're working with Python TLS directly, you'll want to do the
    exact same setup as this function does.
    """
    ctx = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH)

    ctx.options |= (
        ssl.OP_NO_SSLv2 | ssl.OP_NO_SSLv3 | ssl.OP_NO_TLSv1 | ssl.OP_NO_TLSv1_1
    )
    ctx.options |= ssl.OP_NO_COMPRESSION
    ctx.set_ciphers("ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20")
    ctx.set_alpn_protocols(["h2", "http/1.1"])

    try:
        ctx.set_npn_protocols(["h2", "http/1.1"])
    except NotImplementedError:
        pass

    return ctx
	
def test_https(host, path):
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.settimeout(3)
	s.connect((host,443))
	s_wrapped = ssl.wrap_socket(s)
	s_wrapped.sendall(str.encode("GET "+path+" HTTP/1.1\r\nHost: "+host+"\r\n\r\n"))
	response = ""
	support_1_1 = False
	while True:
		try:
			reply = s_wrapped.recv(buffer)
		except socket.timeout:
			break
		if (reply == b''):
			break
		response += reply.decode('latin-1')
	#print(response.split("\r\n\r\n",1)[0])
	s_wrapped.close()
	s.close()
	if (response[:8] == "HTTP/1.1"):
		support_1_1 = True
	if (response[9:12] == "200"):
		return True, fetch_cookies(response.split("\r\n\r\n",1)[0]), support_1_1
	elif (response[9:12] == "301" or response[9:12] == "302" or response[9:12] == "307"):
		port, new_host, new_path = get_path(response.split("\r\n\r\n",1)[0])
		if (port == 80):
			return False, None, support_1_1
		return test_https(new_host, new_path)
	elif (response[9:12] == "404" or response[9:12] == "505"):
		print("Received HTTP response code "+response[9:12]+" when trying to access "+host+path+" over HTTPS/1.1.")
	return False, None, support_1_1
		
def print_cookies(cookies):
	if (not cookies):
		return
	for cookie in cookies:
		if (cookie[0] == None):
			cookie[0] = "-"
		if (cookie[1] == None):
			cookie[1] = "-"
		if (cookie[2] == None):
			cookie[2] = "-"
		print("name: "+cookie[0]+", key: "+cookie[1]+", domain name: "+cookie[2])
		
def get_path(input):
	lines = input.split("\r\n")
	for line in lines:
		if (line[:10] == "Location: "):
			path = line.split(' ')[1]
			if (path[:5] == "https"):
				port = 443
			else:
				port = 80
			path = path.split('//')[1]
			host = path.split('/',1)[0]
			path = "/" + path.split('/',1)[1]
			return port, host, path
	print("error getting redirection path from header")
	return None, None, None
			
	
def fetch_cookies(input):
	input = input.split('\r\n')
	result = []
	for line in input:
		if (line[:11].lower() == "set-cookie:"):
			cookie = [None, None, None]
			# cookie line. parse for key=value + domain if exists
			index = line[12:].find("=") + 12
			cookie[1] = line[12:index]
			index = line.lower().find("domain=")
			if (index < 0):
				cookie[2] = "-"
			else:
				index2 = line[index:].find(";")
				cookie[2] = line[index+len("domain="):] if (index2 < 0) else line[index+len("domain="):(index+index2)]
			result += [cookie]
	return result
		
	
def truncate_hostname(hostname):
	if (hostname[:7] == "http://"):
		return truncate_hostname(hostname[7:])
	if (hostname[:8] == "https://"):
		return truncate_hostname(hostname[8:])
	if (hostname[:3] == "www"):
		return hostname
	else:
		return "www."+hostname

if __name__ == "__main__":
	main()