%{

#include <stdio.h>
#include "parser.tab.h"
#include "scanner.yy.h"

void yyerror(const char *s);

%}

%union {
  int    ival;
  double fval;
  char  *sval;
  char   cval;
}

%locations
%define parse.error verbose

%token TAG_VERSION TAG_BO TAG_SG TAG_CM TAG_CM_BO TAG_CM_SG TAG_VAL

%token <ival> INT UINT
%token <fval> FLOAT
%token <sval> TEXT NAME
%token <cval> SIGN

%type <fval> float

%%

file:           entries;

entries:        entry entries
        |       entry;

entry:          version
        |       frame_with_signals
        |       comment
        |       comment_frame
        |       comment_signal
        |       signal_values
                ;

version:        TAG_VERSION TEXT
                {
                  printf("Version: %s\n", $2);
                  free($2);
                };

frame_with_signals:
                frame signals
        ;

signals:        signal signals
        |       signal
        ;

frame:          TAG_BO UINT NAME ':' UINT NAME
                {
                  printf("Frame: %s with id %i, length %i, sender %s\n", $3, $2, $5, $6);
                  free($3);
                  free($6);
                };

signal:         TAG_SG NAME ':' UINT '|' UINT '@' UINT SIGN '(' float ',' float ')' '[' float '|' float ']' TEXT names
                {
                  printf("Signal: %s %i|%i@%i%c (%f,%f) [%f.%f] %s\n",
                         $2,
                         $4, $6, $8, $9,
                         $11, $13, $16, $18, $20);
                  free($2);
                  free($20);
                };

names:          NAME names { free($1); }
        |       NAME       { free($1); }
        ;

float:          FLOAT { $$ = $1; }
        |       INT   { $$ = (double)$1; }
        |       UINT  { $$ = (double)$1; }
        ;

comment:        TAG_CM TEXT ';'
                {
                  printf("Comment: %s\n", $2);
                  free($2);
                };

comment_frame:  TAG_CM_BO UINT TEXT ';'
                {
                  printf("Comment for frame %i: %s\n", $2, $3);
                  free($3);
                };

comment_signal: TAG_CM_SG UINT NAME TEXT ';'
                {
                  printf("Comment for signal %s in frame %i: %s\n", $3, $2, $4);
                  free($3);
                  free($4);
                };

signal_values:  TAG_VAL UINT NAME {
                  printf("Values for signal %s in frame %i\n", $3, $2);
                  free($3);
                } values ';' {
                  printf("end of values\n");
                };

values:         value values
        |       value;

value:          UINT TEXT
                {
                  printf("Value: %i = %s\n", $1, $2);
                  free($2);
                };

%%

int main(int argc, char** argv)
{
    (void)argc;
    (void)argv;

    yyparse();

    return 0;
}

void yyerror(const char *s)
{
    printf("EEK, parse error in line %i column %i!  Message: '%s'\n", yylloc.first_line, yylloc.first_column, s);
    // might as well halt now:
    exit(-1);
}
