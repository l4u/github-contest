# see: http://cs.indiana.edu/classes/c304/Makefiles.html

# The following two lines force the standard make to recognize the 
# Objective-C .m suffix.

.SUFFIXES: .o .m
.m.o:
	$(CC) -c $(CFLAGS) $< 


# Macro declarations

CC = gcc
CFLAGS = -g
LIBS = -lobjc -L /System/Library/Frameworks/Foundation.framework/Foundation
SRC=main.m User.m Repository.m Model.m Strategy.m Counter.m
OBJ=main.o User.o Repository.o Model.o Strategy.o Counter.o


# Explicit rules

hist: $(OBJ)
	$(CC) $(CFLAGS) -o main $(OBJ) $(LIBS)

clean:
	rm -f *.o main



