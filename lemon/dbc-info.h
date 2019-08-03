#ifndef DBC_INFO_H__
#define DBC_INFO_H__

#include <stdint.h>
#include "value_string.h"
#include <gmodule.h>

#define DBC_MAX_MESSAGE_LENGTH 32

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
    DBC_MESSAGE_TYPE_UNDEFINED,
    DBC_MESSAGE_TYPE_GENERIC,
    DBC_MESSAGE_TYPE_J1939,
} dbc_message_type_t;

#define MESSAGE_TYPE_ATTRIBUTE_NAME "VFrameFormat"
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
    DBC_SIGNAL_ENDIANESS_MOTOROLA,
    DBC_SIGNAL_ENDIANESS_INTEL,
} dbc_signal_endianess_t;

typedef enum
{
    DBC_SIGNAL_SIGNESS_UNSIGNED,
    DBC_SIGNAL_SIGNESS_SIGNED,
} dbc_signal_signess_t;

typedef enum
{
    DBC_SIGNAL_TYPE_UNDEFINED,
    DBC_SIGNAL_TYPE_INT,
    DBC_SIGNAL_TYPE_FLOAT,
    DBC_SIGNAL_TYPE_DOUBLE,
} dbc_value_type_t;

typedef struct
{
    char     *name;
    char     *comment;
    uint32_t  start;
    uint32_t  length;

    dbc_signal_endianess_t endianess;
    dbc_signal_signess_t   signess;
    dbc_value_type_t       type;

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
