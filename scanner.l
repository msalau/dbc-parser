%option noyywrap
%option noinput
%option nounput

%{
#include <stdio.h>
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
FLOAT [+-]?([0-9]+\.[0-9]*|[0-9]*\.[0-9]+|[0-9]+\.?[0-9]*[Ee][+-]?[0-9+])
NUM [0-9]+
SIGN [+-]

%%

{SPC}                     ;

VERSION{SPC}              { return TAG_VERSION; }
BO_{SPC}                  { return TAG_BO; }
SG_{SPC}                  { return TAG_SG; }
CM_{SPC}+BO_{SPC}         { return TAG_CM_BO; }
CM_{SPC}+SG_{SPC}         { return TAG_CM_SG; }
CM_{SPC}                  { return TAG_CM; }
VAL_{SPC}                 { return TAG_VAL; }

[a-zA-Z_][a-zA-Z0-9_]*    { yylval.sval = strdup(yytext); return NAME; }
{FLOAT}                   { yylval.fval = atof(yytext); return FLOAT; }
{NUM}                     { yylval.ival = atoi(yytext); return UINT; }
{SIGN}{NUM}               { yylval.ival = atoi(yytext); return INT; }

{SIGN}                    { yylval.cval = yytext[0]; return SIGN; }
[:;@,\|\[\]\(\)]          { return yytext[0]; }
["][^"]*["]               { yylval.sval = strdup(yytext); return TEXT; }

%%
