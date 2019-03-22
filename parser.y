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
  unsigned uval;
  long long llval;
  double fval;
  char  *sval;
  char   cval;

  GSList *list;
  GArray *array;
  value_string value;
}

%locations
%define parse.error verbose

%token VERSION NS BS BU BO SG CM BA_DEF BA_DEF_DEF BA VAL VAL_TABLE
%token ATTR_INT ATTR_HEX ATTR_ENUM ATTR_FLOAT ATTR_STRING

%token <ival> INT
%token <uval> UINT
%token <fval> FLOAT
%token <sval> TEXT NAME
%token <cval> SIGN
%token <mux>  MUX

%type <sval> name
%type <fval> float
%type <llval> int
%type <mux>  mux

%type <list> names maybe_names enum_values
%type <array> values
%type <value> value

%destructor { g_free($$); } <sval>
%destructor { g_free($$.sval); } <mux>
%destructor { g_slist_free_full($$, g_free); } names maybe_names enum_values
%destructor { g_free($$.strptr); } value
%destructor { g_array_free($$, TRUE); } values

%%

file:           version
                symbols
                bus_speed
                ecus
                value_tables
                frames
                comments
                attribute_definitions
                attribute_defaults
                attribute_values
                signal_values
                ;

version:        VERSION TEXT
                {
                  printf("VERSION \"%s\"\n\n\n", $2);
                  g_free($2);
                };

symbols:        NS ':'
                {
                  printf("NS_ :\n");
                }
                tags_or_names
                {
                  printf("\n");
                };

bus_speed:      BS ':' { printf("BS_:\n\n"); };
        |       BS ':' UINT { printf("BS_: %u\n\n", $3); };
        ;

tags_or_names:  %empty
        |       tag_or_name tags_or_names
        ;

tag_or_name:    name { printf("\t%s\n", $1); g_free($1); }
        |       CM { printf("\tCM_\n"); }
        |       VAL { printf("\tVAL_\n"); }
        |       VAL_TABLE { printf("\tVAL_TABLE_\n"); }
        |       BA { printf("\tBA_\n"); }
        |       BA_DEF { printf("\tBA_DEF_\n"); }
        |       BA_DEF_DEF { printf("\tBA_DEF_DEF_\n"); }
        ;

ecus:           %empty
        |       BU ':' maybe_names
                {
                    printf("BU_:");
                    for (GSList *elem = $3; elem; elem = g_slist_next(elem))
                    {
                        printf(" %s", (char *)elem->data);
                    }
                    printf("\n\n");
                    g_slist_free_full($3, g_free);
                };

value_tables:   %empty
        |       value_table value_tables
                ;

value_table:    VAL_TABLE name values ';'
                {
                  printf("VAL_TABLE_ %s", $2);
                  for (value_string *v = (value_string *)$3->data; v->strptr; v++)
                  {
                    printf(" %i \"%s\"", v->value, v->strptr);
                  }
                  printf(" ;\n");
                  g_free($2);
                  g_array_free($3, TRUE);
                };

frames:         %empty
        |       frame_with_signals frames
        ;

frame_with_signals:
                frame signals
                {
                  printf("\n");
                };

signals:        %empty
        |       signal signals
        ;

name:           NAME { $$ = $1; }
        |       MUX  { $$ = $1.sval; }
        ;

frame:          BO UINT name ':' UINT name
                {
                  printf("BO_ %u %s: %u %s\n", $2, $3, $5, $6);
                  g_free($3);
                  g_free($6);
                };

signal:         SG name mux ':' UINT '|' UINT '@' UINT SIGN '(' float ',' float ')' '[' float '|' float ']' TEXT names
                {
                  char muxstr[16] = "";
                  if ($3.type == MULTIPLEXED_SIGNAL)
                    sprintf(muxstr, "m%u ", $3.num);
                  if ($3.type == MULTIPLEXER_SIGNAL)
                    sprintf(muxstr, "M ");
                  printf(" SG_ %s %s: %u|%u@%u%c (%g,%g) [%g|%g] \"%s\" ",
                         $2, muxstr,
                         $5, $7, $9, $10,
                         $12, $14, $17, $19, $21);
                  g_free($2);
                  g_free($21);
                  for (GSList *elem = $22; elem; elem = g_slist_next(elem))
                  {
                    printf(" %s", (char *)elem->data);
                  }
                  printf("\n");
                  g_slist_free_full($22, g_free);
                };

mux:            %empty { $$.sval = NULL; $$.type = SIGNAL; }
        |       MUX { $$ = $1; $$.sval = NULL; $$.type = ($1.num < 0) ? MULTIPLEXER_SIGNAL : MULTIPLEXED_SIGNAL; g_free($1.sval); }
        ;

maybe_names:    %empty { $$ = NULL; }
        |       names { $$ = $1; }
        ;

names:          name names { $$ = g_slist_prepend($2, $1); }
        |       name       { $$ = g_slist_prepend(NULL, $1); }
        ;

float:          FLOAT { $$ = $1; }
        |       INT   { $$ = (double)$1; }
        |       UINT  { $$ = (double)$1; }
        ;

comments:       %empty
        |       comment comments
        ;

comment:        comment_net
        |       comment_frame
        |       comment_signal
        ;

comment_net:    CM TEXT ';'
                {
                  printf("CM_ \"%s\";\n", $2);
                  g_free($2);
                };

comment_frame:  CM BO UINT TEXT ';'
                {
                  printf("CM_ BO_ %u \"%s\";\n", $3, $4);
                  g_free($4);
                };

comment_signal: CM SG UINT name TEXT ';'
                {
                  printf("CM_ SG_ %u %s \"%s\";\n", $3, $4, $5);
                  g_free($4);
                  g_free($5);
                };

attribute_definitions:
                %empty
        |       attribute_definition attribute_definitions
        ;

attribute_definition:
                attribute_definition_net
        |       attribute_definition_ecu
        |       attribute_definition_frame
        |       attribute_definition_signal
        ;

attribute_definition_net:
                BA_DEF TEXT
                {
                  printf("BA_DEF_ \"%s\" ", $2);
                  g_free($2);
                }
                attr_type ';';

attribute_definition_ecu:
                BA_DEF BU TEXT
                {
                  printf("BA_DEF_ BU_ \"%s\" ", $3);
                  g_free($3);
                }
                attr_type ';';

attribute_definition_frame:
                BA_DEF BO TEXT
                {
                  printf("BA_DEF_ BO_ \"%s\" ", $3);
                  g_free($3);
                }
                attr_type ';';

attribute_definition_signal:
                BA_DEF SG TEXT
                {
                  printf("BA_DEF_ SG_ \"%s\" ", $3);
                  g_free($3);
                }
                attr_type ';';

attr_type:      ATTR_INT int int { printf("INT %lli %lli;\n", $2, $3); }
        |       ATTR_HEX int int { printf("HEX %lli %lli;\n", $2, $3); }
        |       ATTR_FLOAT float float { printf("FLOAT %g %g;\n", $2, $3); }
        |       ATTR_STRING      { printf("STRING ;\n"); }
        |       ATTR_ENUM enum_values
                {
                  printf("ENUM ");
                  for (GSList *elem = $2; elem; elem = g_slist_next(elem))
                  {
                    printf("\"%s\"%s", (char *)elem->data, (g_slist_next(elem) ? "," : ""));
                  }
                  printf(";\n");
                  g_slist_free_full($2, g_free);
                };

enum_values:    TEXT ',' enum_values { $$ = g_slist_prepend($3, $1); }
        |       TEXT                 { $$ = g_slist_prepend(NULL, $1); }
        ;

attribute_defaults:
                %empty
        |       attribute_default attribute_defaults
        ;

attribute_default:
                BA_DEF_DEF TEXT int ';'
                {
                  printf("BA_DEF_DEF_ \"%s\" %lli;\n", $2, $3);
                  g_free($2);
                }
        |       BA_DEF_DEF TEXT TEXT ';'
                {
                  printf("BA_DEF_DEF_ \"%s\" \"%s\";\n", $2, $3);
                  g_free($2);
                  g_free($3);
                };

attribute_values:
                %empty
        |       attribute_value attribute_values
        ;

attribute_value:
                BA TEXT int ';'
                {
                  printf("BA_ \"%s\" %lli;\n", $2, $3);
                  g_free($2);
                }
        |       BA TEXT FLOAT ';'
                {
                  printf("BA_ \"%s\" %g;\n", $2, $3);
                  g_free($2);
                }
        |       BA TEXT TEXT ';'
                {
                  printf("BA_ \"%s\" \"%s\";\n", $2, $3);
                  g_free($2);
                  g_free($3);
                }
        |       BA TEXT BU name int ';'
                {
                  printf("BA_ \"%s\" BU_ %s %lli;\n", $2, $4, $5);
                  g_free($2);
                  g_free($4);
                }
        |       BA TEXT BU name FLOAT ';'
                {
                  printf("BA_ \"%s\" BU_ %s %g;\n", $2, $4, $5);
                  g_free($2);
                  g_free($4);
                }
        |       BA TEXT BU name TEXT ';'
                {
                  printf("BA_ \"%s\" BU_ %s \"%s\";\n", $2, $4, $5);
                  g_free($2);
                  g_free($4);
                  g_free($5);
                }
        |       BA TEXT BO UINT int ';'
                {
                  printf("BA_ \"%s\" BO_ %u %lli;\n", $2, $4, $5);
                  g_free($2);
                }
        |       BA TEXT BO UINT FLOAT ';'
                {
                  printf("BA_ \"%s\" BO_ %u %g;\n", $2, $4, $5);
                  g_free($2);
                }
        |       BA TEXT BO UINT TEXT ';'
                {
                  printf("BA_ \"%s\" BO_ %u \"%s\";\n", $2, $4, $5);
                  g_free($2);
                  g_free($5);
                }
        |       BA TEXT SG UINT name int ';'
                {
                  printf("BA_ \"%s\" SG_ %u %s %lli;\n", $2, $4, $5, $6);
                  g_free($2);
                  g_free($5);
                }
        |       BA TEXT SG UINT name FLOAT ';'
                {
                  printf("BA_ \"%s\" SG_ %u %s %g;\n", $2, $4, $5, $6);
                  g_free($2);
                  g_free($5);
                }
        |       BA TEXT SG UINT name TEXT ';'
                {
                  printf("BA_ \"%s\" SG_ %u %s \"%s\";\n", $2, $4, $5, $6);
                  g_free($2);
                  g_free($5);
                  g_free($6);
                }
        ;

signal_values:  %empty
        |       signal_value signal_values
        ;

signal_value:   VAL UINT name values ';'
                {
                  printf("VAL_ %u %s", $2, $3);
                  for (value_string *v = (value_string *)$4->data; v->strptr; v++)
                  {
                    printf(" %i \"%s\"", v->value, v->strptr);
                  }
                  printf(" ;\n");
                  g_free($3);
                  g_array_free($4, TRUE);
                };

values:         values value
                {
                  $$ = g_array_append_val($1, $2);
                }
        |       value
                {
                  $$ = g_array_new(TRUE, TRUE, sizeof(value_string));
                  g_array_set_clear_func($$, free_value_string);
                  g_array_append_val($$, $1);
                };

int:            UINT { $$ = $1; }
        |       INT  { $$ = $1; }
        ;

value:          int TEXT
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
            fprintf(stderr, "Usage: %s [-f] <file> [<file> [<file> ...]]\n", argv[0]);
            return 1;
        }
    }

    if (optind == argc)
    {
        fprintf(stderr, "Usage: %s [-f] <file> [<file> [<file> ...]]\n", argv[0]);
        return 1;
    }

    while (optind < argc && !ret_code)
    {
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

        optind++;
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
