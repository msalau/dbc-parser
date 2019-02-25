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

%token TAG_VERSION TAG_BO TAG_SG TAG_CM TAG_CM_BO TAG_CM_SG TAG_VAL
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
        |       frame_with_signals
        |       comment
        |       comment_frame
        |       comment_signal
        |       signal_values
                ;

version:        TAG_VERSION TEXT end
                {
                  printf("Version: %s\n", $2);
                  free($2);
                };

frame_with_signals:
                frame signals
        ;

signals:        signal signals
        |       signal
        ;

frame:          TAG_BO INT NAME ':' INT NAME end
                {
                  printf("Frame: %s with id %i, length %i, sender %s\n", $3, $2[0], $5[0], $6);
                  free($3);
                  free($6);
                };

signal:         TAG_SG NAME ':' SIG_POS SIG_CONV SIG_LIMITS TEXT NAME end
                {
                  printf("Signal: %s %i|%i@%i%c (%f,%f) [%f.%f] %s, receiver: %s\n",
                         $2,
                         $4[0],$4[1], $4[2], ($4[3] ? '-' : '+'),
                         $5[0], $5[1], $6[0], $6[1], $7, $8);
                  free($2);
                  free($7);
                  free($8);
                };

comment:        TAG_CM TEXT ';' end
                {
                  printf("Comment: %s\n", $2);
                  free($2);
                };

comment_frame:  TAG_CM_BO INT TEXT ';' end
                {
                  printf("Comment for frame %i: %s\n", $2[0], $3);
                  free($3);
                };

comment_signal: TAG_CM_SG INT NAME TEXT ';' end
                {
                  printf("Comment for signal %s in frame %i: %s\n", $3, $2[0], $4);
                  free($3);
                  free($4);
                };

signal_values:  TAG_VAL INT NAME {
                  printf("Values for signal %s in frame %i\n", $3, $2[0]);
                  free($3);
                } values ';' end {
                  printf("end of values\n");
                };

values:         value values
        |       value;

value:          INT TEXT
                {
                  printf("Value: %i = %s\n", $1[0], $2);
                  free($2);
                };

end:            ENDL end
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
