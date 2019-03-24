%option noyywrap
%option noinput
%option nounput

%{
#include <gmodule.h>
#include <stdio.h>
#include "value_string.h"
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
FLOAT [+-]?([0-9]+\.[0-9]*|[0-9]*\.[0-9]+|[0-9]+\.?[0-9]*[Ee][+-]?[0-9]+)
NUM [0-9]+
SIGN [+-]

%%

{SPC}                     ;
\/\/.*$                   ;

VERSION                   { return VERSION; }
NS_                       { return NS; }
BS_                       { return BS; }
BU_                       { return BU; }
BO_                       { return BO; }
SG_                       { return SG; }
CM_                       { return CM; }
BA_DEF_                   { return BA_DEF; }
BA_DEF_DEF_               { return BA_DEF_DEF; }
BA_                       { return BA; }
VAL_                      { return VAL; }
VAL_TABLE_                { return VAL_TABLE; }
SIG_VALTYPE_              { return SIG_VALTYPE; }
SIG_GROUP_                { return SIG_GROUP; }
SG_MUL_VAL_               { return SG_MUL_VAL; }
INT                       { return ATTR_INT; }
HEX                       { return ATTR_HEX; }
ENUM                      { return ATTR_ENUM; }
FLOAT                     { return ATTR_FLOAT; }
STRING                    { return ATTR_STRING; }

M                         { yylval.mux.sval = g_strdup(yytext); yylval.mux.num = -1; return MUX; }
m{NUM}                    { yylval.mux.sval = g_strdup(yytext); yylval.mux.num = atoi(yytext + 1); return MUX; }

[a-zA-Z_][a-zA-Z0-9_]*    { yylval.sval = g_strdup(yytext); return NAME; }
{FLOAT}                   { yylval.fval = strtod(yytext, NULL); return FLOAT; }
{NUM}                     { yylval.uval = strtoul(yytext, NULL, 0); return UINT; }
{SIGN}{NUM}               { yylval.ival = strtol(yytext, NULL, 0); return INT; }
{NUM}-{NUM}               { yylval.mval[0] = strtoul(yytext, NULL, 0); yylval.mval[1] = strtoul(strchr(yytext, '-') + 1, NULL, 0); return MUL_VAL; }

{SIGN}                    { yylval.cval = yytext[0]; return SIGN; }
["]([^"]|\\["])*["]       { yylval.sval = g_strndup(yytext + 1, strlen(yytext) - 2); return TEXT; }
.                         { return yytext[0]; }

%%
