This assignment was to create a simple shell interpreter that would run in the linux environment.

It displays your current directory and has normal "cd" functionality to change directories. 
	.. can be used to go up one directory level
	~ is substituted for your home path
	quotation marks are not allowed, but pathnames with spaces can be accessed by typing the path without the usual quotation marks

All normal external bash commands should work, such as sleep and ls.

A process can be executed in the background by typing "bg" (without the quotation marks) as the first argument.
	ex: "bg sleep 10"

Background processes still have access to stdout, so a command such as "bg ls" will still print directory information to the terminal.

"bglist" can be used to show a list of all the currently running background processes.

When a background process terminates, the next time ENTER is pressed, a message will be shown indicating that the process terminated.