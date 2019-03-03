%{

#include <stdio.h>
#include "parser.tab.h"
#include "scanner.yy.h"

void yyerror(const char *s);

%}

// Bison fundamentally works by asking flex to get the next token, which it
// returns as an object of type "yystype".  Initially (by default), yystype
// is merely a typedef of "int", but for non-trivial projects, tokens could
// be of any arbitrary data type.  So, to deal with that, the idea is to
// override yystype's default typedef to be a C union instead.  Unions can
// hold all of the types of tokens that Flex could return, and this this means
// we can return ints or floats or strings cleanly.  Bison implements this
// mechanism with the %union directive:
%union {
  int    ival;
  double fval;
  char  *sval;
}

%locations
%define parse.error verbose

%token TAG_VERSION TAG_BO TAG_SG TAG_CM TAG_CM_BO TAG_CM_SG TAG_VAL

// Define the "terminal symbol" token types I'm going to use (in CAPS
// by convention), and associate each with a field of the %union:
%token <ival> INT UINT SIGN
%token <fval> FLOAT
%token <sval> TEXT NAME

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
                         $4, $6, $8, ($9 ? '+' : '-'),
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
