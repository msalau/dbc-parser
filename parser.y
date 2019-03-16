%{

#include <stdio.h>
#include "parser.tab.h"
#include "scanner.yy.h"

void yyerror(const char *s);

typedef enum signal_type
{
  SIGNAL,
  MULTIPLEXER_SIGNAL,
  MULTIPLEXED_SIGNAL
} signal_type_t;

%}

%union {

  struct
  {
    int   type;
    int   num;
    char *sval;
  } mux;

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
%token <mux>  MUX

%type <sval> name
%type <fval> float
%type <mux>  mux

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

name:           NAME { $$ = $1; }
        |       MUX  { $$ = $1.sval; }
        ;

frame:          TAG_BO UINT name ':' UINT name
                {
                  printf("Frame: %s with id %i, length %i, sender %s\n", $3, $2, $5, $6);
                  free($3);
                  free($6);
                };

signal:         TAG_SG name mux ':' UINT '|' UINT '@' UINT SIGN '(' float ',' float ')' '[' float '|' float ']' TEXT names
                {
                  printf("%s: %s %i|%i@%i%c (%f,%f) [%f.%f] %s\n",
                         $3.type == SIGNAL ? "Signal" : $3.type == MULTIPLEXER_SIGNAL ? "Multiplexer signal" : "Multiplexed signal",
                         $2,
                         $5, $7, $9, $10,
                         $12, $14, $17, $19, $21);
                  free($2);
                  free($21);
                };

mux:            %empty { $$.type = SIGNAL; }
        |       MUX { $$ = $1; $$.type = ($1.num < 0) ? MULTIPLEXER_SIGNAL : MULTIPLEXED_SIGNAL; free($1.sval); }
        ;

names:          name names { free($1); }
        |       name       { free($1); }
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

comment_signal: TAG_CM_SG UINT name TEXT ';'
                {
                  printf("Comment for signal %s in frame %i: %s\n", $3, $2, $4);
                  free($3);
                  free($4);
                };

signal_values:  TAG_VAL UINT name {
                  printf("Values for signal %s in frame %i:", $3, $2);
                  free($3);
                } values ';' {
                  printf(";\n");
                };

values:         value values
        |       value;

value:          UINT TEXT
                {
                  printf(" %i=%s", $1, $2);
                  free($2);
                };

%%

int main(int argc, char** argv)
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <file>\n", argv[0]);
        return 1;
    }

    FILE *in = fopen(argv[1], "r");

    if (!in)
    {
        perror(argv[1]);
        return 2;
    }

    yyset_in(in);
    yyparse();
    yylex_destroy();

    fclose(in);

    return 0;
}

void yyerror(const char *s)
{
    printf("EEK, parse error in line %i column %i!  Message: '%s'\n", yylloc.first_line, yylloc.first_column, s);
    // might as well halt now:
    exit(-1);
}
