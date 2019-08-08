#ifndef DBC_H__
#define DBC_H__

#include <gmodule.h>

#define DBC_MAX_SYMBOL_NAME_LENGTH 32

typedef struct
{
    gchar  *filepath;
    gchar  *comment;
    gchar  *version;
    GSList *nodes;
    GSList *messages;
    gint    j1939_type_num;
    gint    cyclic_send_type_num;
} dbc_file_t;

typedef struct
{
    gchar *name;
    gchar *long_name;
} dbc_node_t;

typedef enum
{
    DBC_MESSAGE_TYPE_UNDEFINED,
    DBC_MESSAGE_TYPE_GENERIC,
    DBC_MESSAGE_TYPE_J1939,
} dbc_message_type_t;

typedef enum
{
    DBC_MESSAGE_SEND_TYPE_UNDEFINED,
    DBC_MESSAGE_SEND_TYPE_CYCLIC,
    DBC_MESSAGE_SEND_TYPE_OTHER,
} dbc_message_send_type_t;

#define DBC_MESSAGE_TYPE_ATTRIBUTE_NAME "VFrameFormat"
#define DBC_MESSAGE_TYPE_J1939_VALUE    "J1939PG"

#define DBC_NODE_LONG_NAME_ATTRIBUTE_NAME    "SystemNodeLongSymbol"
#define DBC_ENV_VAR_LONG_NAME_ATTRIBUTE_NAME "SystemEnvVarLongSymbol"
#define DBC_MESSAGE_LONG_NAME_ATTRIBUTE_NAME "SystemMessageLongSymbol"
#define DBC_SIGNAL_LONG_NAME_ATTRIBUTE_NAME  "SystemSignalLongSymbol"

#define DBC_MESSAGE_SEND_TYPE_ATTRIBUTE_NAME "GenMsgSendType"
#define DBC_MESSAGE_SEND_TYPE_CYCLIC_VALUE   "Cyclic"

#define DBC_MESSAGE_CYCLE_TIME_ATTRIBUTE_NAME "GenMsgCycleTime"
#define DBC_MESSAGE_CYCLE_TIME_UNDEFINED      -1

typedef struct
{
    guint32                  id;
    gint32                   length;
    dbc_message_type_t       type;
    dbc_message_send_type_t  send_type;
    gint32                   cycle_time;
    gchar                   *name;
    gchar                   *long_name;
    gchar                   *comment;
    GSList                  *senders;
    GSList                  *signals;
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

typedef struct {
    gint32 min;
    gint32 max;
} dbc_mux_value_t;

struct dbc_signal;
typedef struct dbc_signal dbc_signal_t;

typedef struct {
    gboolean      is_muxer;
    gboolean      is_muxed;
    dbc_signal_t *muxer;
    GArray       *muxer_values;
} dbc_mux_info_t;

typedef struct {
    gint32  value;
    gchar  *strptr;
} dbc_value_string_t;

typedef struct dbc_signal
{
    gchar     *name;
    gchar     *long_name;
    gchar     *comment;
    gint32    start;
    gint32    length;

    dbc_signal_endianess_t endianess;
    dbc_signal_signess_t   signess;
    dbc_value_type_t       type;

    double  factor;
    double  offset;
    double  min;
    double  max;
    gchar  *unit;

    dbc_mux_info_t *mux_info;

    dbc_value_string_t *values;
} dbc_signal_t;

dbc_file_t *dbc_new(const gchar *filepath);

dbc_node_t *dbc_find_node(const dbc_file_t *file, const gchar *name);
dbc_message_t *dbc_find_message(const dbc_file_t *file, guint32 id);
dbc_signal_t *dbc_find_signal(const dbc_file_t *file, guint32 id, const gchar *name);

void dbc_free(dbc_file_t *file);
void dbc_free_node(dbc_node_t *node);
void dbc_free_message(dbc_message_t *message);
void dbc_free_signal(dbc_signal_t *signal);
void dbc_free_mux_info(dbc_mux_info_t *mux);

gint dbc_compare_value_strings(gconstpointer a, gconstpointer b);
void dbc_free_value_string(gpointer data);

#endif /* DBC_H__ */
