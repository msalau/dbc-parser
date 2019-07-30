%option reentrant
%option noyywrap
%option noinput
%option nounput
%option batch
%option never-interactive
%option prefix="dbc_scanner_"
%option extra-type="dbc_state_t *"
%option yylineno
%option nodefault

%option noyy_scan_buffer
%option noyy_scan_bytes
%option noyy_scan_string

%option noyyalloc
%option noyyrealloc
%option noyyfree

%{
#include <gmodule.h>
#include <stdio.h>
#include <stdbool.h>
#include "value_string.h"
#include "dbc-info.h"
#include "dbc_parser.h"
#include "dbc_parser_priv.h"

#ifndef HAVE_UNISTD_H
#define YY_NO_UNISTD_H
#endif

#define YY_USER_ACTION \
    yyextra->token = NULL; \
    yyextra->lloc.first_line   = yyextra->lloc.last_line; \
    yyextra->lloc.first_column = yyextra->lloc.last_column; \
    for (const char *c = yytext; *c != '\0'; c++) \
    { \
        if (*c == '\n') \
        { \
            yyextra->lloc.last_line++; \
            yyextra->lloc.last_column = 0; \
        } \
        else \
        { \
            yyextra->lloc.last_column++; \
        } \
    } \

/*
 * Sleazy hack to suppress compiler warnings in yy_fatal_error().
 */
#define YY_EXIT_FAILURE ((void)yyscanner, 2)

/*
 * Macros for the allocators, to discard the extra argument.
 */
#define dbc_scanner_alloc(size, yyscanner)          (void *)malloc(size)
#define dbc_scanner_realloc(ptr, size, yyscanner)   (void *)realloc((char *)(ptr), (size))
#define dbc_scanner_free(ptr, yyscanner)            free((char *)(ptr))

%}

SPC [ \r\n\t]
FLOAT [+-]?([0-9]+\.[0-9]+|[0-9]+(\.[0-9]*)?[Ee][+-]?[0-9]+)
NUM [0-9]+

%%

{SPC}                     ;
\/\/.*$                   ;

VERSION                   { return TK_VERSION; }
NS_                       { return TK_NS; }
NS_DESC_                  { return TK_NS_DESC; }
BS_                       { return TK_BS; }
BU_                       { return TK_BU; }
BO_                       { return TK_BO; }
SG_                       { return TK_SG; }
BO_TX_BU_                 { return TK_BO_TX_BU; }
EV_                       { return TK_EV; }
EV_DATA_                  { return TK_EV_DATA; }
ENVVAR_DATA_              { return TK_ENVVAR_DATA; }
CM_                       { return TK_CM; }
BA_DEF_                   { return TK_BA_DEF; }
BA_DEF_REL_               { return TK_BA_DEF_REL; }
BA_DEF_SGTYPE_            { return TK_BA_DEF_SGTYPE; }
BA_DEF_DEF_               { return TK_BA_DEF_DEF; }
BA_DEF_DEF_REL_           { return TK_BA_DEF_DEF_REL; }
BA_                       { return TK_BA; }
BA_REL_                   { return TK_BA_REL; }
BA_SGTYPE_                { return TK_BA_SGTYPE; }
BU_BO_REL_                { return TK_BU_BO_REL; }
BU_SG_REL_                { return TK_BU_SG_REL; }
BU_EV_REL_                { return TK_BU_EV_REL; }
VAL_                      { return TK_VAL; }
VAL_TABLE_                { return TK_VAL_TABLE; }
CAT_DEF_                  { return TK_CAT_DEF; }
CAT_                      { return TK_CAT; }
FILTER                    { return TK_FILTER; }
SIG_VALTYPE_              { return TK_SIG_VALTYPE; }
SIG_GROUP_                { return TK_SIG_GROUP; }
SG_MUL_VAL_               { return TK_SG_MUL_VAL; }
SGTYPE_                   { return TK_SGTYPE; }
SIG_TYPE_REF_             { return TK_SIG_TYPE_REF; }
SGTYPE_VAL_               { return TK_SGTYPE_VAL; }
SIGTYPE_VALTYPE_          { return TK_SIGTYPE_VALTYPE; }
INT                       { return TK_ATTR_INT; }
HEX                       { return TK_ATTR_HEX; }
ENUM                      { return TK_ATTR_ENUM; }
FLOAT                     { return TK_ATTR_FLOAT; }
STRING                    { return TK_ATTR_STRING; }

M                         { yyextra->token = g_strdup(yytext); return TK_MUX; }
m{NUM}                    { yyextra->token = g_strdup(yytext); return TK_MUX; }
m{NUM}M                   { yyextra->token = g_strdup(yytext); return TK_MUX; }

[a-zA-Z_][a-zA-Z0-9_]*    { yyextra->token = g_strdup(yytext); return TK_NAME; }
{FLOAT}                   { yyextra->token = g_strdup(yytext); return TK_FLOAT; }
{NUM}                     { yyextra->token = g_strdup(yytext); return TK_UINT; }

"-"                       { return TK_MINUS; }
"+"                       { return TK_PLUS; }
"|"                       { return TK_PIPE; }
"@"                       { return TK_AT; }
"("                       { return TK_LEFT_PARENTHESIS; }
")"                       { return TK_RIGHT_PARENTHESIS; }
"["                       { return TK_LEFT_BRACKET; }
"]"                       { return TK_RIGHT_BRACKET; }
";"                       { return TK_SEMICOLON; }
":"                       { return TK_COLOM; }
["]([^"]|\\["])*["]       { yyextra->token = g_strndup(yytext + 1, strlen(yytext) - 2); return TK_TEXT; }
.                         { return TK_UNKNOWN; }

%%
