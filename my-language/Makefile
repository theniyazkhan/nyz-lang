CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -D_POSIX_C_SOURCE=200809L
BISON = bison
FLEX = flex

all: nyz

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d -o parser.tab.c parser.y

lex.yy.c: lexer.l parser.tab.h
	$(FLEX) -o lex.yy.c lexer.l

nyz: parser.tab.c lex.yy.c
	$(CC) $(CFLAGS) -o nyz parser.tab.c lex.yy.c -lfl

clean:
	rm -f nyz parser.tab.c parser.tab.h lex.yy.c

.PHONY: all clean
