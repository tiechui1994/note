objects = main.o command.o

edit : $(objects)
	cc -o edit $(objects)

main.o:main.c
command.o: command.c

clean :
	rm -rf edit $(objects)