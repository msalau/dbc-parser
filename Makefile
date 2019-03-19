CFLAGS:=-g3 -O0 -Wall -Wextra -Wformat -Wformat-security -Warray-bounds -Werror -fsanitize=leak $(shell pkg-config --cflags glib-2.0)
LDFLAGS:=-fsanitize=leak
LIBS=-llsan $(shell pkg-config --libs glib-2.0)

.PHONY: all test fuzz clean

all: parse

#all: parser.png parser.html

test: parse test.dbc
		./$< ./test.dbc

fuzz: parse
		./fuzz.sh ./test.dbc

clean:
		-rm -f parse *.tab.c *.tab.h *.yy.c *.yy.h *.o *.png *.dot *.html *.xml *.output

.PRECIOUS: %.yy.c %.yy.h %.tab.c %.tab.h %.xml %.dot

scanner.yy.o: parser.tab.h

parse: scanner.yy.o parser.tab.o
		$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

%.yy.c %.yy.h: %.l
		flex --outfile=$*.yy.c --header-file=$*.yy.h  $<

%.tab.c %.tab.h %.xml: %.y
		bison -x -v -d $<

%.dot: %.xml
		xsltproc $(shell bison --print-datadir)/xslt/xml2dot.xsl $< >$@

%.html: %.xml
		xsltproc $(shell bison --print-datadir)/xslt/xml2xhtml.xsl $< >$@

%.png: %.dot
		dot -Tpng $< >$@
