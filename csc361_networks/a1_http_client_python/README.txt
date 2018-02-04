h2 module is used.

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