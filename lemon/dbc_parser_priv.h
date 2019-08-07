#ifndef DBC_PARSER_PRIV_H__
#define DBC_PARSER_PRIV_H__

#include <gmodule.h>
#include <stdio.h>

#define DBC_WARNINGS
//#define DBC_DEBUG
//#define DBC_TRACE

typedef struct {
    unsigned first_line;
    unsigned first_column;
    unsigned last_line;
    unsigned last_column;
} dbc_scanner_lloc_t;

typedef struct {
    gchar *token;

    GSList *errors;

#ifdef DBC_WARNINGS
    GSList *warnings;
#endif

    dbc_file_t *dbc;

    dbc_scanner_lloc_t lloc;
} dbc_state_t;

#ifdef DBC_DEBUG
#define dbc_printf(...) printf(__VA_ARGS__)
#else
#define dbc_printf(...) (void)0
#endif

#endif
