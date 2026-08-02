%option noyywrap nounput noinput
%{
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

void yyerror(const char *message);

static char *copy_string(const char *text) {
  size_t length = strlen(text) + 1;
  char *copy = malloc(length);
  if (!copy) {
    fprintf(stderr, "Out of memory\n");
    exit(1);
  }
  memcpy(copy, text, length);
  return copy;
}

static char *copy_quoted_string(const char *text) {
  size_t len = strlen(text);
  if (len < 2) return copy_string("");
  char *copy = malloc(len - 1);
  if (!copy) {
    fprintf(stderr, "Out of memory\n");
    exit(1);
  }
  memcpy(copy, text + 1, len - 2);
  copy[len - 2] = '\0';
  return copy;
}
%}

%%
"dhoro"|"morphe"|"let"|"int"       { return DHORO; }
"dekha"|"manifest"|"show"|"print"  { return DEKHA; }
"ne"|"absorb"|"input"              { return NE; }
"jodi"|"perchance"|"if"            { return JODI; }
"naile"|"otherwise"|"else"         { return NAILE; }
"ghuro"|"persist"|"while"          { return GHURO; }
"ghur"|"for"                       { return GHUR; }

"hasa"|"true"                      { yylval.int_value = 1; return INTEGER; }
"misa"|"false"                     { yylval.int_value = 0; return INTEGER; }

"ar"|"&&"                          { return AR; }
"ernay"|"||"                       { return ERNAY; }
"na be"|"nabe"|"!"                 { return NABE; }

"=="        { return EQ; }
"!="        { return NEQ; }
"<="        { return LE; }
">="        { return GE; }
"^"         { return POW; }
"+"         { return '+'; }
"-"         { return '-'; }
"*"         { return '*'; }
"/"         { return '/'; }
"="         { return '='; }
"<"         { return '<'; }
">"         { return '>'; }
";"         { return ';'; }
"("         { return '('; }
")"         { return ')'; }
"{"         { return '{'; }
"}"         { return '}'; }

\"([^\"\\\n]|\\.)*\" {
              yylval.string_value = copy_quoted_string(yytext);
              return STRING;
            }

[0-9]+      { yylval.int_value = atoi(yytext); return INTEGER; }

[a-zA-Z_][a-zA-Z0-9_]* {
              yylval.string_value = copy_string(yytext);
              return IDENTIFIER;
            }

[ \t\r\n]+ ;
"//".*      ;

.           { fprintf(stderr, "Unexpected character: %c\n", yytext[0]); return yytext[0]; }
%%
