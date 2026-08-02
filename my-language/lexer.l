%option noyywrap
%{
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
%}

%%
"morphe"               { return MORPHE; }
"manifest"             { return MANIFEST; }
"absorb"               { return ABSORB; }
"perchance"            { return PERCHANCE; }
"otherwise"            { return OTHERWISE; }
"persist"              { return PERSIST; }

"int"       { return INT; }
"print"     { return PRINT; }
"while"     { return WHILE; }
"+"         { return '+'; }
"-"         { return '-'; }
"*"         { return '*'; }
"/"         { return '/'; }
"="         { return '='; }
"=="        { return EQ; }
"!="        { return NEQ; }
"<="        { return LE; }
">="        { return GE; }
"<"         { return '<'; }
">"         { return '>'; }
";"         { return ';'; }
"("         { return '('; }
")"         { return ')'; }
"{"         { return '{'; }
"}"         { return '}'; }
[0-9]+      { yylval.int_value = atoi(yytext); return INTEGER; }
[a-zA-Z_][a-zA-Z0-9_]* {
              yylval.string_value = copy_string(yytext);
              return IDENTIFIER;
            }
[ \t\r\n]+ ;
"//".*      ;
.           { fprintf(stderr, "Unexpected character: %c\n", yytext[0]); return yytext[0]; }
%%
