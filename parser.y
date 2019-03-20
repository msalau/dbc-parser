%{

#include <gmodule.h>
#include <stdio.h>
#include "value_string.h"
#include "parser.tab.h"
#include "scanner.yy.h"

void yyerror(const char *s);

typedef enum signal_type
{
  SIGNAL,
  MULTIPLEXER_SIGNAL,
  MULTIPLEXED_SIGNAL
} signal_type_t;

void free_value_string(gpointer data)
{
  g_free(((value_string *)data)->strptr);
}

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

  GSList *list;
  GArray *array;
  value_string value;
}

%locations
%define parse.error verbose

%token VERSION BU BO SG CM VAL

%token <ival> INT UINT
%token <fval> FLOAT
%token <sval> TEXT NAME
%token <cval> SIGN
%token <mux>  MUX

%type <sval> name
%type <fval> float
%type <mux>  mux

%type <list> names
%type <array> values
%type <value> value

%destructor { g_free($$); } <sval>
%destructor { g_free($$.sval); } <mux>
%destructor { g_slist_free_full($$, g_free); } names

%%

file:           entries;

entries:        entry entries
        |       entry;

entry:          version
        |       ecus
        |       frame_with_signals
        |       comment
        |       comment_frame
        |       comment_signal
        |       signal_values
                ;

version:        VERSION TEXT
                {
                  printf("Version: \"%s\"\n", $2);
                  g_free($2);
                };

ecus:           BU ':' names
                {
                    printf("Nodes: ");
                    for (GSList *elem = $3; elem; elem = g_slist_next(elem))
                    {
                        printf("%s ", (char *)elem->data);
                    }
                    printf("\n");
                    g_slist_free_full($3, g_free);
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
                  g_free($3);
                  g_free($6);
                };

signal:         SG name mux ':' UINT '|' UINT '@' UINT SIGN '(' float ',' float ')' '[' float '|' float ']' TEXT names
                {
                  printf("%s: %s %i|%i@%i%c (%f,%f) [%f.%f] \"%s\"",
                         $3.type == SIGNAL ? "Signal" : $3.type == MULTIPLEXER_SIGNAL ? "Multiplexer signal" : "Multiplexed signal",
                         $2,
                         $5, $7, $9, $10,
                         $12, $14, $17, $19, $21);
                  g_free($2);
                  g_free($21);
                  printf(" Receivers: ");
                  for (GSList *elem = $22; elem; elem = g_slist_next(elem))
                  {
                    printf("%s ", (char *)elem->data);
                  }
                  printf("\n");
                  g_slist_free_full($22, g_free);
                };

mux:            %empty { $$.sval = NULL; $$.type = SIGNAL; }
        |       MUX { $$ = $1; $$.sval = NULL; $$.type = ($1.num < 0) ? MULTIPLEXER_SIGNAL : MULTIPLEXED_SIGNAL; g_free($1.sval); }
        ;

names:          name names { $$ = g_slist_prepend($2, $1); }
        |       name       { $$ = g_slist_prepend(NULL, $1); }
        ;

float:          FLOAT { $$ = $1; }
        |       INT   { $$ = (double)$1; }
        |       UINT  { $$ = (double)$1; }
        ;

comment:        CM TEXT ';'
                {
                  printf("Comment: \"%s\"\n", $2);
                  g_free($2);
                };

comment_frame:  CM BO UINT TEXT ';'
                {
                  printf("Comment for frame %i: \"%s\"\n", $3, $4);
                  g_free($4);
                };

comment_signal: CM SG UINT name TEXT ';'
                {
                  printf("Comment for signal %s in frame %i: \"%s\"\n", $4, $3, $5);
                  g_free($4);
                  g_free($5);
                };

signal_values:  VAL UINT name values ';'
                {
                  printf("Values for signal %s in frame %i:", $3, $2);
                  for (value_string *v = (value_string *)$4->data; v->strptr; v++)
                  {
                    printf(" %i=\"%s\"", v->value, v->strptr);
                  }
                  printf(";\n");
                  g_free($3);
                  g_array_set_clear_func($4, free_value_string);
                  g_array_free($4, TRUE);
                };

values:         values value
                {
                  $$ = g_array_append_val($1, $2);
                }
        |       value
                {
                  $$ = g_array_new(TRUE, TRUE, sizeof(value_string));
                  g_array_append_val($$, $1);
                };

value:          UINT TEXT
                {
                  $$.value  = $1;
                  $$.strptr = $2;
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
