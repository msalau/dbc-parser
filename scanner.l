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

%%

[ \t]             ;
["]([^"]|\\["])*["]     { yylval.sval = strdup(yytext); return TEXT; }
^VERSION          { return TAG_VERSION; }
^BO_              { printf("BO_\n"); return TAG_BO; }
^[ \t]+SG_        { printf("SG_\n"); return TAG_SG; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.sval = strdup(yytext); return NAME; }
[0-9]+\.[0-9]+    { yylval.fval[0] = atof(yytext); return FLOAT; }
[0-9]+            { yylval.ival[0] = atoi(yytext); return INT; }

[0-9]+\|[0-9]+@1[+-] { printf("SIG_POS: '%s'\n", yytext); return SIG_POS; }
\([0-9]*\.?[0-9]+,[0-9]*\.?[0-9]+\) { printf("SIG_SCALE: '%s'\n", yytext); return SIG_CONV; }
\[[+-]?[0-9]*\.?[0-9]+\|[0-9]*\.?[0-9]+\] { printf("SIG_LIMITS: '%s'\n", yytext);return SIG_LIMITS; }

[:;,\(\)\[\]\|]   { return yytext[0]; }
\n                { printf("CR\n"); return ENDL; }

%%
