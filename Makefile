CFLAGS:=-Wall -Wextra

all: parse

clean:
		-rm -f parse *.tab.c *.tab.h *.yy.c *.yy.h *.o

.PRECIOUS: %.yy.c %.yy.h %.tab.c %.tab.h

scanner.yy.o: parser.tab.h

parse: scanner.yy.o parser.tab.o
		$(CC) -o $@ $^

%.yy.c %.yy.h: %.l
		flex --outfile=$*.yy.c --header-file=$*.yy.h  $<

%.tab.c %.tab.h: %.y
		bison -d $<
