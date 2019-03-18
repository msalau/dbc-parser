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

%token VERSION BO SG CM VAL

%token <ival> INT UINT
%token <fval> FLOAT
%token <sval> TEXT NAME
%token <cval> SIGN
%token <mux>  MUX

%type <sval> name
%type <fval> float
%type <mux>  mux

%destructor { free($$); } <sval>
%destructor { if ($$.sval) free($$.sval); } <mux>

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

version:        VERSION TEXT
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

frame:          BO UINT name ':' UINT name
                {
                  printf("Frame: %s with id %i, length %i, sender %s\n", $3, $2, $5, $6);
                  free($3);
                  free($6);
                };

signal:         SG name mux ':' UINT '|' UINT '@' UINT SIGN '(' float ',' float ')' '[' float '|' float ']' TEXT names
                {
                  printf("%s: %s %i|%i@%i%c (%f,%f) [%f.%f] %s\n",
                         $3.type == SIGNAL ? "Signal" : $3.type == MULTIPLEXER_SIGNAL ? "Multiplexer signal" : "Multiplexed signal",
                         $2,
                         $5, $7, $9, $10,
                         $12, $14, $17, $19, $21);
                  free($2);
                  free($21);
                };

mux:            %empty { $$.sval = NULL; $$.type = SIGNAL; }
        |       MUX { $$ = $1; $$.sval = NULL; $$.type = ($1.num < 0) ? MULTIPLEXER_SIGNAL : MULTIPLEXED_SIGNAL; free($1.sval); }
        ;

names:          name names { free($1); }
        |       name       { free($1); }
        ;

float:          FLOAT { $$ = $1; }
        |       INT   { $$ = (double)$1; }
        |       UINT  { $$ = (double)$1; }
        ;

comment:        CM TEXT ';'
                {
                  printf("Comment: %s\n", $2);
                  free($2);
                };

comment_frame:  CM BO UINT TEXT ';'
                {
                  printf("Comment for frame %i: %s\n", $3, $4);
                  free($4);
                };

comment_signal: CM SG UINT name TEXT ';'
                {
                  printf("Comment for signal %s in frame %i: %s\n", $4, $3, $5);
                  free($4);
                  free($5);
                };

signal_values:  VAL UINT name {
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

#include <unistd.h>

static int   ret_code = 0;
static char *filename = NULL;

int main(int argc, char** argv)
{
    FILE *in;
    int   opt;
    int   force = 0;

    while ((opt = getopt(argc, argv, "hf")) != -1)
    {
        switch (opt)
        {
        case 'f':
            force = 1;
            break;
        default:
            fprintf(stderr, "Unknown argument: %c\n", opt);
            /* fall-through */
        case 'h':
            fprintf(stderr, "Usage: %s [-f] <file>\n", argv[0]);
            return 1;
        }
    }

    if ((optind + 1) != argc)
    {
        fprintf(stderr, "Too many files specified\n");
        return 1;
    }

    if (strcmp(argv[optind], "-"))
    {
        filename = argv[optind];
        in = fopen(filename, "r");
    }
    else
    {
        filename = "<stdin>";
        in = stdin;
    }

    if (!in)
    {
        perror(filename);
        return 2;
    }

    yyset_in(in);
    yyparse();
    yylex_destroy();

    if (in != stdin)
    {
        fclose(in);
    }

    if (force)
        ret_code = 0;

    return ret_code;
}

void yyerror(const char *s)
{
    fprintf(stderr, "%s:%i:%i: %s\n", filename, yylloc.first_line, yylloc.first_column, s);
    ret_code = 1;
}
