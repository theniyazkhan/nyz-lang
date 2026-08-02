CC = gcc
CFLAGS = -Wall -Wextra -std=c99
BISON ?= bison
FLEX ?= flex
TARGET = sylheti

ifeq ($(OS),Windows_NT)
    TARGET_EXE = $(TARGET).exe
    CLEAN_CMDS = -del /Q /F $(TARGET_EXE) parser.tab.c parser.tab.h lex.yy.c *.o 2>NUL
else
    TARGET_EXE = $(TARGET)
    CLEAN_CMDS = -rm -f $(TARGET_EXE) parser.tab.c parser.tab.h lex.yy.c *.o
endif

all: $(TARGET_EXE)

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d -o parser.tab.c parser.y

lex.yy.c: lexer.l parser.tab.h
	$(FLEX) -o lex.yy.c lexer.l

$(TARGET_EXE): parser.tab.c lex.yy.c
	$(CC) $(CFLAGS) -o $(TARGET_EXE) parser.tab.c lex.yy.c

clean:
	$(CLEAN_CMDS)

.PHONY: all clean
