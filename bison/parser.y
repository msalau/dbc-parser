%{

#include <gmodule.h>
#include <stdio.h>
#include <stdbool.h>
#include "dbc-info.h"
#include "value_string.h"
#include "parser.tab.h"
#include "scanner.yy.h"

void yyerror(dbc_file_t *dbc, const char *s);

typedef enum attr_obj_type
{
    ATTR_OBJ_TYPE_NET = 0,
    ATTR_OBJ_TYPE_ECU,
    ATTR_OBJ_TYPE_FRAME,
    ATTR_OBJ_TYPE_SIGNAL,
    ATTR_OBJ_TYPE_ENV,
    ATTR_OBJ_TYPE_ECU_FRAME_REL,
    ATTR_OBJ_TYPE_ECU_SIGNAL_REL,
    ATTR_OBJ_TYPE_ECU_ENV_REL,
} attr_obj_type_t;

typedef enum cat_obj_type
{
    CAT_OBJ_TYPE_ECU,
    CAT_OBJ_TYPE_FRAME,
    CAT_OBJ_TYPE_ENV,
} cat_obj_type_t;

typedef enum attr_value_type
{
    ATTR_VALUE_TYPE_INT = 0,
    ATTR_VALUE_TYPE_HEX,
    ATTR_VALUE_TYPE_ENUM,
    ATTR_VALUE_TYPE_FLOAT,
    ATTR_VALUE_TYPE_STRING,
} attr_value_type_t;

static int compare_value_strings(gconstpointer a, gconstpointer b)
{
    return ((const value_string *)a)->value - ((const value_string *)b)->value;
}

typedef struct { unsigned val[2]; } mul_val_t;

%}

%union {

    struct
    {
        unsigned  value;
        bool      is_muxed;
        bool      is_muxer;
        char     *sval;
    } mux;

    struct
    {
        int type;
        union
        {
            GSList     *list;
            long long   ival[2];
            double      fval[2];
        };
    } attr_value_type;

    struct
    {
        int        type;
        long long  id;
        char      *name;
    } attr_obj;

    struct
    {
        int       type;
        unsigned  id;
        char     *name;
    } cat_obj;

    struct
    {
        int       type;
        unsigned  frame_id;
        char     *ecu_name;
        char     *obj_name;
    } attr_rel_obj;

    struct
    {
        int type;
        union
        {
            long long  ival;
            double     fval;
            char      *sval;
        };
    } attr_obj_value;

    int        ival;
    unsigned   uval;
    long long  llval;
    unsigned   mval[2];
    double     fval;
    char      *sval;
    char       cval;

    GSList       *list;
    GArray       *array;
    value_string  value;
    dbc_frame_t  *frame;
    dbc_signal_t *signal;
}

%expect 0
%locations
%define parse.error verbose
%parse-param {dbc_file_t *dbc}

%token VERSION NS BS BU VAL_TABLE BO SG BO_TX_BU EV EV_DATA ENVVAR_DATA CM VAL SIG_GROUP SIG_VALTYPE SG_MUL_VAL SGTYPE SIG_TYPE_REF
%token BA_DEF BA_DEF_REL BA_DEF_DEF BA_DEF_DEF_REL BA BA_REL BU_BO_REL BU_SG_REL BU_EV_REL BA_DEF_SGTYPE BA_SGTYPE
%token ATTR_INT ATTR_HEX ATTR_ENUM ATTR_FLOAT ATTR_STRING
%token CAT_DEF CAT FILTER
%token NS_DESC SGTYPE_VAL SIGTYPE_VALTYPE

%token <ival> INT
%token <uval> UINT
%token <fval> FLOAT
%token <sval> TEXT NAME
%token <cval> SIGN
%token <mux>  MUX
%token <mval> MUL_VAL

%type <uval> endianess
%type <sval> name maybe_name
%type <fval> float
%type <llval> int
%type <mux>  mux

%type <list> names maybe_names enum_values comma_separated_names
%type <list> maybe_uints uints
%type <array> values mul_values
%type <value> value
%type <ival> attr_obj_type attr_rel_obj_type attr_def_with_obj_type
%type <attr_value_type> attr_value_type
%type <attr_obj> attr_obj
%type <attr_rel_obj> attr_rel_obj
%type <attr_obj_value> attr_obj_value
%type <cat_obj> category_object
%type <frame> frame
%type <signal> signal
%type <list> signals

%destructor { g_free($$); } <sval>
%destructor { g_free($$.sval); } <mux>
%destructor { g_free($$.name); } attr_obj
%destructor { g_free($$.ecu_name); g_free($$.obj_name); } attr_rel_obj
%destructor { g_slist_free_full($$, g_free); } names maybe_names enum_values comma_separated_names
%destructor { g_slist_free($$); } maybe_uints uints
%destructor { g_free($$.strptr); } value
%destructor { g_array_free($$, TRUE); } values mul_values
%destructor { if ($$.type == ATTR_VALUE_TYPE_ENUM) g_slist_free_full($$.list, g_free); } attr_value_type
%destructor { if ($$.type == ATTR_VALUE_TYPE_STRING) g_free($$.sval); } attr_obj_value
%destructor { g_free($$.name); } category_object
%destructor { dbc_free_frame($$); } frame
%destructor { dbc_free_signal($$); } signal
%destructor { g_slist_free_full($$, (GDestroyNotify)dbc_free_signal); } signals

%%

file:           version
                symbols
                bus_speed
                ecus
                value_tables
                frames
                frame_transmitter_lists
                env_variables
                env_variables_data
                signal_types
                comments
                attr_definitions
                attr_sgtype_definitions
                attr_defaults
                attr_values
                value_definitions
                category_definitions
                categories
                filter
                signal_type_refs
                signal_groups
                signal_value_types
                signal_mul_values
                ;

version:        %empty
        |       VERSION TEXT[version_string]
                {
                    dbc->version = $version_string;
                };

symbols:        %empty
        |       NS ':' tags_or_names;

tags_or_names:  %empty
        |       tag_or_name tags_or_names
        ;

tag_or_name:    name { g_free($1); }
        |       NS_DESC
        |       CM
        |       VAL
        |       VAL_TABLE
        |       BA
        |       BA_REL
        |       BA_DEF
        |       BA_DEF_REL
        |       BA_DEF_DEF
        |       BA_DEF_DEF_REL
        |       BU_BO_REL
        |       BU_SG_REL
        |       BU_EV_REL
        |       SIG_VALTYPE
        |       SIG_GROUP
        |       SG_MUL_VAL
        |       BO_TX_BU
        |       EV
        |       EV_DATA
        |       ENVVAR_DATA
        |       SGTYPE
        |       SIG_TYPE_REF
        |       SGTYPE_VAL
        |       SIGTYPE_VALTYPE
        |       BA_DEF_SGTYPE
        |       BA_SGTYPE
        |       CAT_DEF
        |       CAT
        |       FILTER
        ;

bus_speed:      BS ':'
        |       BS ':' UINT
        |       BS ':' UINT ':' UINT ',' UINT
        ;

ecus:           BU ':' maybe_names[ecu_names]
                {
                    g_slist_free_full($ecu_names, g_free);
                };

value_tables:   %empty
        |       value_table value_tables
                ;

value_table:    VAL_TABLE name[table_name] values[table_values] ';'
                {
                    g_free($table_name);
                    g_array_free($table_values, TRUE);
                };

frames:         %empty
        |       frame_with_signals frames
        ;

frame_with_signals:
                frame signals
                {
                    $frame->signals = $signals;
                    dbc->frames = g_slist_prepend(dbc->frames, $frame);
                };

signals:        %empty         { $$ = NULL; }
        |       signal signals { $$ = g_slist_prepend($2, $1); }
        ;

maybe_name:     %empty { $$ = NULL; }
        |       name   { $$ = $1; }
        ;

name:           NAME { $$ = $1; }
        |       MUX  { $$ = $1.sval; }
        ;

frame:          BO UINT[frame_id] name[frame_name] ':' UINT[frame_length] name[frame_sender]
                {
                    $$ = g_new0(dbc_frame_t, 1);

                    $$->id      = $frame_id;
                    $$->name    = $frame_name;
                    $$->length  = $frame_length;
                    $$->senders = $frame_sender;
                    $$->type    = DBC_FRAME_TYPE_GENERIC;
                };

endianess:      UINT
                {
                    if ($1 != DBC_SIGNAL_ENDIANESS_MOTOROLA &&
                        $1 != DBC_SIGNAL_ENDIANESS_INTEL)
                    {
                        yyerror(dbc, "Invalid signal endianess");
                        YYERROR;
                    }

                    $$ = $1;
                }
        ;

signal:         SG name[signal_name] mux[signal_mux] ':'
                UINT[signal_start] '|' UINT[signal_length] '@' endianess[signal_endianess] SIGN[signal_signess]
                '(' float[signal_factor] ',' float[signal_offset] ')'
                '[' float[signal_min] '|' float[signal_max] ']'
                TEXT[signal_unit] comma_separated_names[signal_receivers]
                {
                    $$ = g_new0(dbc_signal_t, 1);

                    $$->name      = $signal_name;
                    $$->start     = $signal_start;
                    $$->length    = $signal_length;
                    $$->endianess = $signal_endianess;
                    $$->signess   = ($signal_signess == '+') ? DBC_SIGNAL_SIGNESS_UNSIGNED : DBC_SIGNAL_SIGNESS_SIGNED;
                    $$->factor    = $signal_factor;
                    $$->offset    = $signal_offset;
                    $$->min       = $signal_min;
                    $$->max       = $signal_max;
                    $$->unit      = $signal_unit;

                    // TODO: Handle muxing
                    (void)$signal_mux;
                    g_slist_free_full($signal_receivers, g_free);
                };

mux:            %empty
                {
                    $$.sval     = NULL;
                    $$.is_muxed = false;
                    $$.is_muxer = false;
                }
        |       MUX
                {
                    $$      = $1;
                    $$.sval = NULL;
                    g_free($1.sval);
                }
        ;

comma_separated_names:
                name ',' comma_separated_names { $$ = g_slist_prepend($3, $1); }
        |       name                           { $$ = g_slist_prepend(NULL, $1); }
        ;

maybe_names:    %empty { $$ = NULL; }
        |       names  { $$ = $1; }
        ;

names:          name names { $$ = g_slist_prepend($2, $1); }
        |       name       { $$ = g_slist_prepend(NULL, $1); }
        ;

float:          FLOAT { $$ = $1; }
        |       INT   { $$ = (double)$1; }
        |       UINT  { $$ = (double)$1; }
        ;

frame_transmitter_lists:
                %empty
        |       frame_transmitter_list frame_transmitter_lists
        ;

frame_transmitter_list:
                BO_TX_BU UINT[frame_id] ':' comma_separated_names[senders] ';'
                {
                    dbc_frame_t *frame = dbc_find_frame(dbc, $frame_id);
                    if (frame)
                    {
                        GArray   *arr = g_array_sized_new(TRUE, TRUE, sizeof(gchar *), g_slist_length($senders));
                        unsigned  i   = 0;
                        gchar    *senders_str;

                        // TODO: Check is we need to keep the original sender name
                        for (GSList *elem = $senders; elem; i++, elem = g_slist_next(elem))
                            g_array_insert_val(arr, i, elem->data);

                        senders_str = g_strjoinv("|", (gchar **)arr->data);
                        g_array_free(arr, TRUE);
                        g_free(frame->senders);
                        frame->senders = senders_str;
                    }

                    g_slist_free_full($senders, g_free);
                }
        ;

env_variables:  %empty
        |       env_variable env_variables
        ;

env_variable:   EV name[ev_name] ':' int[ev_type]
                '[' float[ev_min] '|' float[ev_max] ']'
                TEXT[ev_unit] float[ev_initial] int[ev_id] name[ev_mode] comma_separated_names[ev_ecus] ';'
                {
                    g_free($ev_name);
                    g_free($ev_unit);
                    g_free($ev_mode);
                    g_slist_free_full($ev_ecus, g_free);
                }
        ;

env_variables_data:
                %empty
        |       env_data env_variables_data
        ;

env_data:       ENVVAR_DATA name[ev_name] ':' UINT ';'
                {
                    g_free($ev_name);
                }
        |       EV_DATA name[ev_name] ':' UINT ';'
                {
                    g_free($ev_name);
                }
        ;

signal_types:   %empty
        |       signal_type signal_types
        ;

signal_type:    SGTYPE name[sigtype_name] ':'
                UINT[sigtype_length] '@' UINT[sigtype_endianess] SIGN[sigtype_signess]
                '(' float[sigtype_factor] ',' float[sigtype_offset] ')'
                '[' float[sigtype_min] '|' float[sigtype_max] ']'
                TEXT[sigtype_unit] float[sigtype_defaultvalue] maybe_name[sigtype_valtable] ';'
                {
                    g_free($sigtype_name);
                    g_free($sigtype_unit);
                    g_free($sigtype_valtable);
                }
        ;

comments:       %empty
        |       comment comments
        ;

comment:        comment_net
        |       comment_ecu
        |       comment_frame
        |       comment_signal
        |       comment_env
        ;

comment_net:    CM TEXT[text] ';'
                {
                    g_free(dbc->comment);
                    dbc->comment = $text;
                };

comment_ecu:    CM BU name[ecu_name] TEXT[text] ';'
                {
                    g_free($ecu_name);
                    g_free($text);
                };

comment_frame:  CM BO UINT[frame_id] TEXT[text] ';'
                {
                    dbc_frame_t *frame = dbc_find_frame(dbc, $frame_id);
                    if (frame)
                    {
                        g_free(frame->comment);
                        frame->comment = $text;
                    }
                    else
                    {
                        g_free($text);
                    }
                };

comment_signal: CM SG UINT[frame_id] name[signal_name] TEXT[text] ';'
                {
                    dbc_signal_t *signal = dbc_find_signal(dbc, $frame_id, $signal_name);
                    if (signal)
                    {
                        g_free(signal->comment);
                        signal->comment = $text;
                    }
                    else
                    {
                        g_free($text);
                    }
                    g_free($signal_name);
                };

comment_env: CM EV name[ev_name] TEXT[text] ';'
                {
                    g_free($ev_name);
                    g_free($text);
                };

attr_definitions:
                %empty
        |       attr_definition attr_definitions
        ;

attr_definition:
                attr_def_with_obj_type[attr_type] TEXT[attr_name] attr_value_type[attr_value] ';'
                {
                    switch ($attr_value.type)
                    {
                    case ATTR_VALUE_TYPE_INT:
                    case ATTR_VALUE_TYPE_HEX:
                    case ATTR_VALUE_TYPE_FLOAT:
                    case ATTR_VALUE_TYPE_STRING:
                        /* Nothing to do for simple types */
                        break;
                    case ATTR_VALUE_TYPE_ENUM:
                        if (g_strcmp0($attr_name, FRAME_TYPE_ATTRIBUTE_NAME) == 0)
                        {
                            int type_num = 0;

                            for (GSList *elem = $attr_value.list; elem; elem = g_slist_next(elem))
                            {
                                if (g_strcmp0(elem->data, FRAME_TYPE_J1939_VALUE) == 0)
                                {
                                    dbc->j1939_type_num = type_num;
                                    break;
                                }
                                type_num++;
                            }
                        }
                        g_slist_free_full($attr_value.list, g_free);
                        break;
                    }
                    g_free($attr_name);
                }
        ;

attr_def_with_obj_type:
                BA_DEF attr_obj_type         { $$ = $2; }
        |       BA_DEF_REL attr_rel_obj_type { $$ = $2; }
        ;

attr_obj_type:  %empty { $$ = ATTR_OBJ_TYPE_NET; }
        |       BU     { $$ = ATTR_OBJ_TYPE_ECU; }
        |       BO     { $$ = ATTR_OBJ_TYPE_FRAME; }
        |       SG     { $$ = ATTR_OBJ_TYPE_SIGNAL; }
        |       EV     { $$ = ATTR_OBJ_TYPE_ENV; }
        ;

attr_rel_obj_type:
                BU_BO_REL { $$ = ATTR_OBJ_TYPE_ECU_FRAME_REL; }
        |       BU_SG_REL { $$ = ATTR_OBJ_TYPE_ECU_SIGNAL_REL; }
        |       BU_EV_REL { $$ = ATTR_OBJ_TYPE_ECU_ENV_REL; }
        ;

attr_value_type:
                ATTR_INT int int
                {
                    $$.type    = ATTR_VALUE_TYPE_INT;
                    $$.ival[0] = $2;
                    $$.ival[1] = $3;
                }
        |       ATTR_HEX int int
                {
                    $$.type    = ATTR_VALUE_TYPE_HEX;
                    $$.ival[0] = $2;
                    $$.ival[1] = $3;
                }
        |       ATTR_FLOAT float float
                {
                    $$.type    = ATTR_VALUE_TYPE_FLOAT;
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


attr_sgtype_definitions:
                %empty
        |       attr_sgtype_definition attr_sgtype_definitions
        ;

attr_sgtype_definition:
                BA_DEF_SGTYPE TEXT[attr_name] ';'
                {
                    g_free($attr_name);
                }
        ;

attr_defaults:
                %empty
        |       attr_default attr_defaults
        ;

attr_default:
                BA_DEF_DEF TEXT[attr_name] int ';'
                {
                    g_free($attr_name);
                }
        |       BA_DEF_DEF TEXT[attr_name] TEXT[attr_value] ';'
                {
                    g_free($attr_name);
                    g_free($attr_value);
                }
        |       BA_DEF_DEF_REL TEXT[attr_name] int ';'
                {
                    g_free($attr_name);
                }
        |       BA_DEF_DEF_REL TEXT[attr_name] TEXT[attr_value] ';'
                {
                    g_free($attr_name);
                    g_free($attr_value);
                }
        ;

attr_values:
                %empty
        |       attr_value attr_values
        ;

attr_value:
                BA TEXT[attr_name] attr_obj attr_obj_value ';'
                {
                    if (g_strcmp0($attr_name, FRAME_TYPE_ATTRIBUTE_NAME) == 0 &&
                        $attr_obj.type == ATTR_OBJ_TYPE_FRAME &&
                        $attr_obj_value.type == ATTR_VALUE_TYPE_INT &&
                        $attr_obj_value.ival == dbc->j1939_type_num)
                    {
                        dbc_frame_t *frame = dbc_find_frame(dbc, $attr_obj.id);
                        if (frame)
                            frame->type = DBC_FRAME_TYPE_J1939;
                    }
                    g_free($attr_name);
                    g_free($attr_obj.name);
                    if ($attr_obj_value.type == ATTR_VALUE_TYPE_STRING)
                        g_free($attr_obj_value.sval);
                }
        |       BA_REL TEXT attr_rel_obj attr_obj_value ';'
                {
                    g_free($2);
                    g_free($3.ecu_name);
                    g_free($3.obj_name);
                    switch ($4.type)
                    {
                    case ATTR_VALUE_TYPE_INT:
                    case ATTR_VALUE_TYPE_FLOAT:
                        break;
                    case ATTR_VALUE_TYPE_STRING:
                        g_free($4.sval);
                        break;
                    }
                }
        |       BA_SGTYPE TEXT SGTYPE name attr_obj_value ';'
                {
                    g_free($2);
                    g_free($4);
                    switch ($5.type)
                    {
                    case ATTR_VALUE_TYPE_INT:
                    case ATTR_VALUE_TYPE_FLOAT:
                        break;
                    case ATTR_VALUE_TYPE_STRING:
                        g_free($5.sval);
                        break;
                    }
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
                    $$.id   = $2;
                    $$.name = NULL;
                }
        |       SG UINT name
                {
                    $$.type = ATTR_OBJ_TYPE_SIGNAL;
                    $$.id   = $2;
                    $$.name = $3;
                }
        |       EV name
                {
                    $$.type = ATTR_OBJ_TYPE_ENV;
                    $$.name = $2;
                }
        ;

attr_rel_obj:
                BU_BO_REL name UINT
                {
                    $$.type     = ATTR_OBJ_TYPE_ECU_FRAME_REL;
                    $$.ecu_name = $2;
                    $$.frame_id = $3;
                    $$.obj_name = NULL;
                }
        |       BU_SG_REL name SG UINT name
                {
                    $$.type     = ATTR_OBJ_TYPE_ECU_SIGNAL_REL;
                    $$.ecu_name = $2;
                    $$.frame_id = $4;
                    $$.obj_name = $5;
                }
        |       BU_EV_REL name name
                {
                    $$.type     = ATTR_OBJ_TYPE_ECU_ENV_REL;
                    $$.ecu_name = $2;
                    $$.obj_name = $3;
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

value_definitions:
                %empty
        |       value_definition value_definitions
        ;

value_definition:
                VAL UINT[frame_id] name[signal_name] values[signal_values] ';'
                {
                    dbc_signal_t *signal = dbc_find_signal(dbc, $frame_id, $signal_name);
                    if (signal)
                    {
                        for (value_string *v = signal->values; v->strptr; v++)
                            free_value_string(v);
                        g_free(signal->values);
                        g_array_sort($signal_values, compare_value_strings);
                        signal->values = (value_string *)g_array_free($signal_values, FALSE);
                    }
                    else
                    {
                        g_array_free($signal_values, TRUE);
                    }
                    g_free($signal_name);
                }
        |       VAL name[ev_name] values[ev_values] ';'
                {
                    g_free($ev_name);
                    g_array_free($ev_values, TRUE);
                }
        ;

values:         %empty
                {
                    $$ = g_array_new(TRUE, TRUE, sizeof(value_string));
                    g_array_set_clear_func($$, free_value_string);
                }
        |       values value
                {
                    $$ = g_array_append_val($1, $2);
                };

uints:          UINT uints { $$ = g_slist_prepend($2, GUINT_TO_POINTER($1)); }
        |       UINT       { $$ = g_slist_prepend(NULL, GUINT_TO_POINTER($1)); }


maybe_uints:    %empty { $$ = NULL; }
        |       uints  { $$ = $1; }
        ;

int:            UINT { $$ = $1; }
        |       INT  { $$ = $1; }
        ;

value:          int TEXT
                {
                    $$.value  = $1;
                    $$.strptr = $2;
                };

category_definitions:
                %empty
        |       category_definition category_definitions
        ;

category_definition:
                CAT_DEF UINT name[category_name] UINT ';'
                {
                    g_free($category_name);
                }
        ;

categories:
                %empty
        |       category categories
        ;

category:       CAT category_object UINT ';'
                {
                    g_free($category_object.name);
                }
        ;

category_object:
                EV name { $$.type = CAT_OBJ_TYPE_ENV; $$.name = $2; }
        |       BU name { $$.type = CAT_OBJ_TYPE_ECU; $$.name = $2; }
        |       BO UINT { $$.type = CAT_OBJ_TYPE_FRAME; $$.name = NULL; $$.id = $2; }
        ;

filter:         %empty
        |       FILTER UINT CAT maybe_uints[category_ids] BU maybe_names[ecu_names] ';'
                {
                    g_slist_free($category_ids);
                    g_slist_free_full($ecu_names, g_free);
                }
        ;

signal_type_refs:
                %empty
        |       signal_type_ref signal_type_refs
        ;

signal_type_ref:
                SIG_TYPE_REF UINT[frame_id] name[signal_name] ':' name[sigtype_name] ';'
                {
                    g_free($signal_name);
                    g_free($sigtype_name);
                }
        ;

signal_groups:  %empty
        |       signal_group signal_groups
        ;

signal_group:   SIG_GROUP UINT[frame_id] name[group_name] UINT[repetitions] ':' names[signals] ';'
                {
                    g_free($group_name);
                    g_slist_free_full($signals, g_free);
                }
        ;

signal_value_types:
                %empty
        |       signal_value_type signal_value_types
        ;

signal_value_type:
                SIG_VALTYPE UINT[frame_id] name[signal_name] ':' UINT[signal_type] ';'
                {
                    dbc_signal_t *signal = dbc_find_signal(dbc, $frame_id, $signal_name);
                    if (signal)
                        signal->type = $signal_type;
                    g_free($signal_name);
                }
        ;

signal_mul_values:
                %empty
        |       signal_mul_value signal_mul_values
        ;

signal_mul_value:
                SG_MUL_VAL UINT[frame_id] name[muxed_signal] name[muxer_signal] mul_values ';'
                {
                    // TODO: Handle extended multiplexing
                    g_free($muxed_signal);
                    g_free($muxer_signal);
                    g_array_free($mul_values, TRUE);
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

static int ret_code = 0;

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
        char *filename;

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
        dbc_file_t *dbc = dbc_new(filename);
        yyparse(dbc);
        dbc_free(dbc);
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

void yyerror(dbc_file_t *dbc, const char *s)
{
    fprintf(stderr, "%s:%i:%i: %s\n", dbc->filepath, yylloc.first_line, yylloc.first_column, s);
    ret_code = 1;
}
