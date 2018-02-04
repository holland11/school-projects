.phony all:
all: sample inf args

sample: sample.c linkedlist.o linkedlist.h
	gcc sample.c linkedlist.o linkedlist.h -lreadline -lhistory -ltermcap -o sample

inf: inf.c
	gcc inf.c -o inf

args: args.c
	gcc args.c -o args
	
linkedlist.o: linkedlist.c
	gcc linkedlist.c -c 

.PHONY clean:
clean:
	-rm -rf *.o *.exe