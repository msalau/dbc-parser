#ifndef DBC_INFO_H__
#define DBC_INFO_H__

#include <stdint.h>
#include "value_string.h"
#include <gmodule.h>

typedef struct
{
    char   *filepath;
    char   *comment;
    char   *version;
    GSList *messages;
    int     j1939_type_num;
} dbc_file_t;

typedef enum
{
    DBC_MESSAGE_TYPE_GENERIC = 0,
    DBC_MESSAGE_TYPE_J1939   = 1,
} dbc_message_type_t;

#define MESSAGE_TYPE_ATTRIBUTE_NAME "VMessageFormat"
#define MESSAGE_TYPE_J1939_VALUE    "J1939PG"

typedef struct
{
    uint32_t          id;
    uint32_t          length;
    dbc_message_type_t  type;
    char             *name;
    char             *comment;
    char             *senders;
    GSList           *signals;
} dbc_message_t;

typedef enum
{
    DBC_SIGNAL_ENDIANESS_MOTOROLA = 0,
    DBC_SIGNAL_ENDIANESS_INTEL    = 1,
} dbc_signal_endianess_t;

typedef enum
{
    DBC_SIGNAL_SIGNESS_UNSIGNED = 0,
    DBC_SIGNAL_SIGNESS_SIGNED   = 1,
} dbc_signal_signess_t;

typedef enum
{
    DBC_SIGNAL_TYPE_INT    = 0,
    DBC_SIGNAL_TYPE_FLOAT  = 1,
    DBC_SIGNAL_TYPE_DOUBLE = 2,
} dbc_signal_type_t;

typedef struct
{
    char     *name;
    char     *comment;
    uint32_t  start;
    uint32_t  length;

    dbc_signal_endianess_t endianess;
    dbc_signal_signess_t   signess;
    dbc_signal_type_t      type;

    double  factor;
    double  offset;
    double  min;
    double  max;
    char   *unit;

    value_string *values;
} dbc_signal_t;

dbc_file_t *dbc_new(const char *filepath);

dbc_message_t *dbc_find_message(const dbc_file_t *file, uint32_t id);
dbc_signal_t *dbc_find_signal(const dbc_file_t *file, uint32_t id, const char *name);

void dbc_free(dbc_file_t *file);
void dbc_free_message(dbc_message_t *message);
void dbc_free_signal(dbc_signal_t *signal);
void free_value_string(gpointer data);

#endif /* DBC_INFO_H__ */
