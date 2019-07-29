%option noyywrap
%option noinput
%option nounput
%option batch
%option nodefault

%{
#include <gmodule.h>
#include <stdio.h>
#include <stdbool.h>
#include "value_string.h"
#include "dbc-info.h"
#include "parser.tab.h"

#define YY_USER_ACTION \
    yylloc.first_line = yylloc.last_line; \
    yylloc.first_column = yylloc.last_column; \
    for (const char *c = yytext; *c != '\0'; c++) \
    { \
        if (*c == '\n') \
        { \
            yylloc.last_line++; \
            yylloc.last_column = 0; \
        } \
        else \
        { \
            yylloc.last_column++; \
        } \
    }

%}

SPC [ \r\n\t]
FLOAT [+-]?([0-9]+\.[0-9]+|[0-9]+(\.[0-9]*)?[Ee][+-]?[0-9]+)
NUM [0-9]+
SIGN [+-]

%%

{SPC}                     ;
\/\/.*$                   ;

VERSION                   { return VERSION; }
NS_                       { return NS; }
NS_DESC_                  { return NS_DESC; }
BS_                       { return BS; }
BU_                       { return BU; }
BO_                       { return BO; }
SG_                       { return SG; }
BO_TX_BU_                 { return BO_TX_BU; }
EV_                       { return EV; }
EV_DATA_                  { return EV_DATA; }
ENVVAR_DATA_              { return ENVVAR_DATA; }
CM_                       { return CM; }
BA_DEF_                   { return BA_DEF; }
BA_DEF_REL_               { return BA_DEF_REL; }
BA_DEF_SGTYPE_            { return BA_DEF_SGTYPE; }
BA_DEF_DEF_               { return BA_DEF_DEF; }
BA_DEF_DEF_REL_           { return BA_DEF_DEF_REL; }
BA_                       { return BA; }
BA_REL_                   { return BA_REL; }
BA_SGTYPE_                { return BA_SGTYPE; }
BU_BO_REL_                { return BU_BO_REL; }
BU_SG_REL_                { return BU_SG_REL; }
BU_EV_REL_                { return BU_EV_REL; }
VAL_                      { return VAL; }
VAL_TABLE_                { return VAL_TABLE; }
CAT_DEF_                  { return CAT_DEF; }
CAT_                      { return CAT; }
FILTER                    { return FILTER; }
SIG_VALTYPE_              { return SIG_VALTYPE; }
SIG_GROUP_                { return SIG_GROUP; }
SG_MUL_VAL_               { return SG_MUL_VAL; }
SGTYPE_                   { return SGTYPE; }
SIG_TYPE_REF_             { return SIG_TYPE_REF; }
SGTYPE_VAL_               { return SGTYPE_VAL; }
SIGTYPE_VALTYPE_          { return SIGTYPE_VALTYPE; }
INT                       { return ATTR_INT; }
HEX                       { return ATTR_HEX; }
ENUM                      { return ATTR_ENUM; }
FLOAT                     { return ATTR_FLOAT; }
STRING                    { return ATTR_STRING; }

M                         { yylval.mux.sval = g_strdup(yytext); yylval.mux.is_muxer = true;  yylval.mux.is_muxed = false; return MUX; }
m{NUM}                    { yylval.mux.sval = g_strdup(yytext); yylval.mux.is_muxer = false; yylval.mux.is_muxed = true;  yylval.mux.value = atoi(yytext + 1); return MUX; }
m{NUM}M                   { yylval.mux.sval = g_strdup(yytext); yylval.mux.is_muxer = true;  yylval.mux.is_muxed = true;  yylval.mux.value = atoi(yytext + 1); return MUX; }

[a-zA-Z_][a-zA-Z0-9_]*    { yylval.sval = g_strdup(yytext); return NAME; }
{FLOAT}                   { yylval.fval = strtod(yytext, NULL); return FLOAT; }
{NUM}                     { yylval.uval = strtoul(yytext, NULL, 0); return UINT; }
{SIGN}{NUM}               { yylval.ival = strtol(yytext, NULL, 0); return INT; }
{NUM}-{NUM}               { yylval.mval[0] = strtoul(yytext, NULL, 0); yylval.mval[1] = strtoul(strchr(yytext, '-') + 1, NULL, 0); return MUL_VAL; }

{SIGN}                    { yylval.cval = yytext[0]; return SIGN; }
["]([^"]|\\["])*["]       { yylval.sval = g_strndup(yytext + 1, strlen(yytext) - 2); return TEXT; }
.                         { return yytext[0]; }

%%
