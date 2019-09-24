CFLAGS:=-g3 -O0
CFLAGS+=-Wall -Wextra -Wformat -Wformat-security -Warray-bounds -Werror
CFLAGS:=-Wconversion
CFLAGS+=$(shell pkg-config --cflags glib-2.0)
CFLAGS+=-MMD
LIBS=$(shell pkg-config --libs glib-2.0)

ifneq ($(LSAN),n)
CFLAGS  += -fsanitize=leak
LDFLAGS += -fsanitize=leak
LIBS    += -llsan
endif

.PHONY: all test fuzz clean

all: parse

test: parse ../common/test.dbc
		./$< $(filter %.dbc,$^)

fuzz: parse
		../common/fuzz.sh ./test.dbc

clean:
		-rm -f lemon parse *~ *.out *_parser.c *_parser.h *_scanner.c *_scanner_lex.h *.o *.d

.PRECIOUS: %.c %.h %.out

parse: dbc_scanner.o dbc_parser.o dbc.o
		$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

%.c %_lex.h: %.l
		flex --outfile=$*.c --header-file=$*_lex.h  $<

%.c %.h %.out: %.lemon lemon
		./lemon -Tlempar.c $<
		touch $*.c $*.h $*.out

dbc_scanner.o: dbc_parser.h

lemon: lemon.c
		$(CC) -O3 -s -o $@ $<

ifneq ($(MAKECMDGOALS),clean)
include $(wildcard *.d)
endif
