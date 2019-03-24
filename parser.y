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

typedef enum attr_obj_type
{
  ATTR_OBJ_TYPE_NET = 0,
  ATTR_OBJ_TYPE_ECU,
  ATTR_OBJ_TYPE_FRAME,
  ATTR_OBJ_TYPE_SIGNAL,
} attr_obj_type_t;

typedef enum attr_value_type
{
  ATTR_VALUE_TYPE_INT = 0,
  ATTR_VALUE_TYPE_HEX,
  ATTR_VALUE_TYPE_ENUM,
  ATTR_VALUE_TYPE_FLOAT,
  ATTR_VALUE_TYPE_STRING,
} attr_value_type_t;

void free_value_string(gpointer data)
{
  g_free(((value_string *)data)->strptr);
}

typedef struct { unsigned val[2]; } mul_val_t;

%}

%union {

  struct
  {
    int   type;
    int   num;
    char *sval;
  } mux;

  struct
  {
    int type;
    union
    {
      GSList   *list;
      long long ival[2];
      double    fval[2];
    };
  } attr_value_type;

  struct
  {
    int       type;
    long long id;
    char     *name;
  } attr_obj;

  struct
  {
    int   type;
    union
    {
      long long ival;
      double    fval;
      char     *sval;
    };
  } attr_obj_value;

  int    ival;
  unsigned uval;
  long long llval;
  unsigned mval[2];
  double fval;
  char  *sval;
  char   cval;

  GSList *list;
  GArray *array;
  value_string value;
}

%locations
%define parse.error verbose

%token VERSION NS BS BU VAL_TABLE BO SG CM BA_DEF BA_DEF_DEF BA VAL SIG_GROUP SIG_VALTYPE SG_MUL_VAL
%token ATTR_INT ATTR_HEX ATTR_ENUM ATTR_FLOAT ATTR_STRING

%token <ival> INT
%token <uval> UINT
%token <fval> FLOAT
%token <sval> TEXT NAME
%token <cval> SIGN
%token <mux>  MUX
%token <mval> MUL_VAL

%type <sval> name
%type <fval> float
%type <llval> int
%type <mux>  mux

%type <list> names maybe_names enum_values
%type <array> values mul_values
%type <value> value
%type <ival> attr_obj_type
%type <attr_value_type> attr_value_type
%type <attr_obj> attr_obj
%type <attr_obj_value> attr_obj_value

%destructor { g_free($$); } <sval>
%destructor { g_free($$.sval); } <mux>
%destructor { g_slist_free_full($$, g_free); } names maybe_names enum_values
%destructor { g_free($$.strptr); } value
%destructor { g_array_free($$, TRUE); } values mul_values
%destructor { if ($$.type == ATTR_VALUE_TYPE_ENUM) g_slist_free_full($$.list, g_free); } attr_value_type
%destructor { if ($$.type == ATTR_VALUE_TYPE_STRING) g_free($$.sval); } attr_obj_value

%%

file:           version
                symbols
                bus_speed
                ecus
                value_tables
                frames
                comments
                attr_definitions
                attr_defaults
                attr_values
                signal_values
                signal_groups
                signal_value_types
                signal_mul_values
                ;

version:        VERSION TEXT
                {
                  printf("VERSION \"%s\"\n\n\n", $2);
                  g_free($2);
                };

symbols:        %empty
        |       NS ':'
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
        |       SIG_VALTYPE { printf("\tSIG_VALTYPE_\n"); }
        |       SIG_GROUP { printf("\tSIG_GROUP_\n"); }
        |       SG_MUL_VAL { printf("\tSG_MUL_VAL_\n"); }
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
        |       comment_ecu
        |       comment_frame
        |       comment_signal
        ;

comment_net:    CM TEXT ';'
                {
                  printf("CM_ \"%s\";\n", $2);
                  g_free($2);
                };

comment_ecu:    CM BU name TEXT ';'
                {
                  printf("CM_ BU_ %s \"%s\";\n", $3, $4);
                  g_free($3);
                  g_free($4);
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

attr_definitions:
                %empty
        |       attr_definition attr_definitions
        ;

attr_definition:
                BA_DEF attr_obj_type TEXT attr_value_type ';'
                {
                  static const char * attr_obj_type_str[] = {
                    [ATTR_OBJ_TYPE_NET] = "",
                    [ATTR_OBJ_TYPE_ECU] = " BU_",
                    [ATTR_OBJ_TYPE_FRAME] = " BO_",
                    [ATTR_OBJ_TYPE_SIGNAL] = " SG_",
                  };
                  printf("BA_DEF_%s  \"%s\" ", attr_obj_type_str[$2], $3);
                  g_free($3);
                  switch ($4.type)
                  {
                  case ATTR_VALUE_TYPE_INT:
                    printf("INT %lli %lli;\n", $4.ival[0], $4.ival[0]);
                    break;
                  case ATTR_VALUE_TYPE_HEX:
                    printf("HEX %lli %lli;\n", $4.ival[0], $4.ival[0]);
                    break;
                  case ATTR_VALUE_TYPE_ENUM:
                    printf("ENUM  ");
                    for (GSList *elem = $4.list; elem; elem = g_slist_next(elem))
                    {
                      printf("\"%s\"%s", (char *)elem->data, (g_slist_next(elem) ? "," : ""));
                    }
                    printf(";\n");
                    g_slist_free_full($4.list, g_free);
                    break;
                  case ATTR_VALUE_TYPE_FLOAT:
                    printf("FLOAT %g %g;\n", $4.fval[0], $4.fval[0]);
                    break;
                  case ATTR_VALUE_TYPE_STRING:
                    printf("STRING ;\n");
                    break;
                  }
                }
        ;

attr_obj_type:  %empty { $$ = ATTR_OBJ_TYPE_NET; }
        |       BU { $$ = ATTR_OBJ_TYPE_ECU; }
        |       BO { $$ = ATTR_OBJ_TYPE_FRAME; }
        |       SG { $$ = ATTR_OBJ_TYPE_SIGNAL; }
        ;

attr_value_type:
                ATTR_INT int int
                {
                  $$.type = ATTR_VALUE_TYPE_INT;
                  $$.ival[0] = $2;
                  $$.ival[1] = $3;
                }
        |       ATTR_HEX int int
                {
                  $$.type = ATTR_VALUE_TYPE_HEX;
                  $$.ival[0] = $2;
                  $$.ival[1] = $3;
                }
        |       ATTR_FLOAT float float
                {
                  $$.type = ATTR_VALUE_TYPE_FLOAT;
                  $$.fval[0] = $2;
                  $$.fval[1] = $3;
                }
        |       ATTR_STRING
                {
                  $$.type = ATTR_VALUE_TYPE_STRING;
                }
        |       ATTR_ENUM enum_values
                {
                  $$.type = ATTR_VALUE_TYPE_ENUM;
                  $$.list = $2;
                }
        ;

enum_values:    TEXT ',' enum_values { $$ = g_slist_prepend($3, $1); }
        |       TEXT                 { $$ = g_slist_prepend(NULL, $1); }
        ;

attr_defaults:
                %empty
        |       attr_default attr_defaults
        ;

attr_default:
                BA_DEF_DEF TEXT int ';'
                {
                  printf("BA_DEF_DEF_  \"%s\" %lli;\n", $2, $3);
                  g_free($2);
                }
        |       BA_DEF_DEF TEXT TEXT ';'
                {
                  printf("BA_DEF_DEF_  \"%s\" \"%s\";\n", $2, $3);
                  g_free($2);
                  g_free($3);
                };

attr_values:
                %empty
        |       attr_value attr_values
        ;

attr_value:
                BA TEXT attr_obj attr_obj_value ';'
                {
                  printf("BA_ \"%s\" ", $2);
                  g_free($2);
                  switch ($3.type)
                  {
                  case ATTR_OBJ_TYPE_ECU:
                    printf("BU_ %s ", $3.name);
                    break;
                  case ATTR_OBJ_TYPE_FRAME:
                    printf("BO_ %lli ", $3.id);
                    break;
                  case ATTR_OBJ_TYPE_SIGNAL:
                    printf("SG_ %lli %s ", $3.id, $3.name);
                    break;
                  }
                  g_free($3.name);
                  switch ($4.type)
                  {
                  case ATTR_VALUE_TYPE_INT:
                    printf("%lli", $4.ival);
                    break;
                  case ATTR_VALUE_TYPE_FLOAT:
                    printf("%g", $4.fval);
                    break;
                  case ATTR_VALUE_TYPE_STRING:
                    printf("\"%s\"", $4.sval);
                    g_free($4.sval);
                    break;
                  }
                  printf(";\n");
                }
        ;

attr_obj:       %empty
                {
                  $$.type = ATTR_OBJ_TYPE_NET;
                  $$.name = NULL;
                }
        |       BU name
                {
                  $$.type = ATTR_OBJ_TYPE_ECU;
                  $$.name = $2;
                }
        |       BO UINT
                {
                  $$.type = ATTR_OBJ_TYPE_FRAME;
                  $$.id = $2;
                  $$.name = NULL;
                }
        |       SG UINT name
                {
                  $$.type = ATTR_OBJ_TYPE_SIGNAL;
                  $$.id = $2;
                  $$.name = $3;
                }
        ;

attr_obj_value: int
                {
                  $$.type = ATTR_VALUE_TYPE_INT;
                  $$.ival = $1;
                }
        |       FLOAT
                {
                  $$.type = ATTR_VALUE_TYPE_FLOAT;
                  $$.fval = $1;
                }
        |       TEXT
                {
                  $$.type = ATTR_VALUE_TYPE_STRING;
                  $$.sval = $1;
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

signal_groups:  %empty
        |       signal_group signal_groups
        ;

signal_group:   SIG_GROUP UINT name UINT ':' names ';'
                {
                  printf("SIG_GROUP_ %u %s %u :", $2, $3, $4);
                  for (GSList *elem = $6; elem; elem = g_slist_next(elem))
                    printf(" %s", (char *)elem->data);
                  printf(";\n");
                  g_free($3);
                  g_slist_free_full($6, g_free);
                }
        ;

signal_value_types:
                %empty
        |       signal_value_type signal_value_types
        ;

signal_value_type:
                SIG_VALTYPE UINT name ':' UINT ';'
                {
                  printf("SIG_VALTYPE_ %u %s : %u;\n", $2, $3, $5);
                  g_free($3);
                }
        ;

signal_mul_values:
                %empty
        |       signal_mul_value signal_mul_values
        ;

signal_mul_value:
                SG_MUL_VAL UINT name name mul_values ';'
                {
                  printf("SG_MUL_VAL_ %u %s %s", $2, $3, $4);
                  unsigned i;
                  mul_val_t v;
                  for (i = 0; i < ($5->len - 1); i++)
                  {
                    v = g_array_index($5, mul_val_t, i);
                    printf(" %u-%u,", v.val[0], v.val[1]);
                  }
                  v = g_array_index($5, mul_val_t, i);
                  printf(" %u-%u;\n", v.val[0], v.val[1]);

                  g_free($3);
                  g_free($4);
                  g_array_free($5, TRUE);
                }
        ;

mul_values:     mul_values ',' MUL_VAL
                {
                  $$ = g_array_append_val($1, $3);
                }
        |       MUL_VAL
                {
                  $$ = g_array_new(FALSE, FALSE, sizeof(mul_val_t));
                  g_array_append_val($$, $1);
                }
        ;

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
        yylloc.last_line = 1;
        yylloc.last_column = 0;
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
