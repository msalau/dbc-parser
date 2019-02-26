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
NUM [+-]?[0-9]*\.?[0-9]+
INT [0-9]+
SIGN [+-]

%%

{SPC}                     ;

^VERSION{SPC}             { return TAG_VERSION; }
{SPC}VERSION{SPC}         { return TAG_VERSION; }
{SPC}BO_{SPC}             { return TAG_BO; }
{SPC}SG_{SPC}             { return TAG_SG; }
{SPC}CM_{SPC}+BO_{SPC}    { return TAG_CM_BO; }
{SPC}CM_{SPC}+SG_{SPC}    { return TAG_CM_SG; }
{SPC}CM_{SPC}             { return TAG_CM; }
{SPC}VAL_{SPC}            { return TAG_VAL; }

[a-zA-Z_][a-zA-Z0-9_]*    { yylval.sval = strdup(yytext); return NAME; }
{SIGN}?{INT}\.{INT}       { yylval.fval[0] = atof(yytext); return FLOAT; }
{SIGN}?{INT}              { yylval.ival[0] = atoi(yytext); return INT; }

{INT}\|{INT}@[01]{SIGN} {
    yylval.ival[0] = atoi(yytext);
    yylval.ival[1] = atoi(strchr(yytext, '|') + 1);
    yylval.ival[2] = atoi(strchr(yytext, '@') + 1);
    yylval.ival[3] = (strchr(yytext, '@') + 2)[0] == '-';
    return SIG_POS;
}

\({SIGN}?{NUM},{SIGN}?{NUM}\) {
    yylval.fval[0] = atof(yytext + 1);
    yylval.fval[1] = atof(strchr(yytext, ',') + 1);
    return SIG_CONV;
}

\[{SIGN}?{NUM}\|{SIGN}?{NUM}\] {
    yylval.fval[0] = atof(yytext + 1);
    yylval.fval[1] = atof(strchr(yytext, '|') + 1);
    return SIG_LIMITS;
}

[:;]              { return yytext[0]; }
["][^"]*["]       { yylval.sval = strdup(yytext); return TEXT; }

%%
