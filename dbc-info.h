#ifndef DBC_INFO_H__
#define DBC_INFO_H__

#include <stdint.h>
#include "value_string.h"
#include <gmodule.h>

typedef struct
{
    char   *name;
    char   *path;
    char   *comment;
    char   *version;
    GSList *frames;
    GSList *frame_types;
} dbc_file_t;

typedef enum
{
    DBC_FRAME_TYPE_GENERIC,
    DBC_FRAME_TYPE_J1939,
} dbc_frame_type_t;

typedef struct
{
    uint32_t          id;
    uint32_t          length;
    dbc_frame_type_t  type;
    char             *name;
    char             *comment;
    char             *senders;
    GSList           *signals;
} dbc_frame_t;

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
    DBC_SIGNAL_TYPE_INT,
    DBC_SIGNAL_TYPE_FLOAT,
    DBC_SIGNAL_TYPE_DOUBLE,
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

    GArray       *value_array;
    value_string *value_strings;
} dbc_signal_t;


dbc_frame_t *dbc_find_frame(const dbc_file_t *file, uint32_t id);
dbc_signal_t *dbc_find_signal(const dbc_file_t *file, uint32_t id, const char *name);

void dbc_free(dbc_file_t *file);
void dbc_free_frame(dbc_frame_t *frame);
void dbc_free_signal(dbc_signal_t *signal);

#endif /* DBC_INFO_H__ */
