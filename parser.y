%{

#include <stdio.h>
#include "parser.tab.h"
#include "scanner.yy.h"

void yyerror(const char *s);

%}

// Bison fundamentally works by asking flex to get the next token, which it
// returns as an object of type "yystype".  Initially (by default), yystype
// is merely a typedef of "int", but for non-trivial projects, tokens could
// be of any arbitrary data type.  So, to deal with that, the idea is to
// override yystype's default typedef to be a C union instead.  Unions can
// hold all of the types of tokens that Flex could return, and this this means
// we can return ints or floats or strings cleanly.  Bison implements this
// mechanism with the %union directive:
%union {
  int ival[4];
  float fval[2];
  char *sval;
}

%locations
%define parse.error verbose

%token TAG_VERSION TAG_BO TAG_SG
%token ENDL

// Define the "terminal symbol" token types I'm going to use (in CAPS
// by convention), and associate each with a field of the %union:
%token <ival> INT SIG_POS
%token <fval> FLOAT SIG_LIMITS SIG_CONV
%token <sval> TEXT NAME

%%

file:           entries;

entries:        entry entries
        |       entry;

entry:          version
        |       frames;

version:        TAG_VERSION TEXT end
                {
                  printf("Version: %s\n", $2);
                };

frames:         frame frames
        |       frame;

frame:          frame_def signals
        |       frame_def;

frame_def:      TAG_BO INT NAME ':' INT NAME end
                {
                  printf("Frame: %s with id %i\n", $3, $2[0]);
                };

signals:        signal_def signals
        |       signal_def;

signal_def:     TAG_SG NAME ':' SIG_POS SIG_CONV SIG_LIMITS TEXT NAME end
                {
                  printf("Signal: %s\n", $2);
                };

end:            end ENDL
        |       ENDL;

%%

int main(int argc, char** argv)
{
    (void)argc;
    (void)argv;

    yyparse();

    return 0;
}

void yyerror(const char *s)
{
    printf("EEK, parse error in line %i column %i!  Message: '%s'\n", yylloc.first_line, yylloc.first_column, s);
    // might as well halt now:
    exit(-1);
}
