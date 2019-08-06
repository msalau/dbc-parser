#include "dbc-info.h"
#include <stdio.h>

dbc_file_t *dbc_new(const char *filepath)
{
    dbc_file_t *dbc = g_new0(dbc_file_t, 1);

    dbc->filepath             = g_strdup(filepath);
    dbc->j1939_type_num       = -1;
    dbc->cyclic_send_type_num = -1;

    return dbc;
}

static gint dbc_find_node_helper(gconstpointer node, gconstpointer name)
{
    return g_strcmp0(((const dbc_node_t *)node)->name, name);
}

dbc_node_t *dbc_find_node(const dbc_file_t *file, const char *name)
{
    GSList *elem = g_slist_find_custom(file->nodes, name, dbc_find_node_helper);
    return elem ? elem->data : NULL;
}

static gint dbc_find_message_helper(gconstpointer message, gconstpointer id)
{
    return ((const dbc_message_t *)message)->id == GPOINTER_TO_UINT(id) ? 0 : 1;
}

dbc_message_t *dbc_find_message(const dbc_file_t *file, uint32_t id)
{
    GSList *elem = g_slist_find_custom(file->messages, GUINT_TO_POINTER(id), dbc_find_message_helper);
    return elem ? elem->data : NULL;
}

static gint dbc_find_signal_helper(gconstpointer signal, gconstpointer name)
{
    return g_strcmp0(((const dbc_signal_t *)signal)->name, name);
}

dbc_signal_t *dbc_find_signal(const dbc_file_t *file, uint32_t id, const char *name)
{
    dbc_message_t *message = dbc_find_message(file, id);
    if (!message)
        return NULL;

    GSList *elem = g_slist_find_custom(message->signals, name, dbc_find_signal_helper);
    return elem ? elem->data : NULL;
}

void free_value_string(gpointer data)
{
    g_free(((value_string *)data)->strptr);
}

void dbc_free(dbc_file_t *file)
{
    g_free(file->filepath);
    g_free(file->comment);
    g_free(file->version);

    g_slist_free_full(file->nodes, (GDestroyNotify)dbc_free_node);
    g_slist_free_full(file->messages, (GDestroyNotify)dbc_free_message);

    g_free(file);
}

void dbc_free_node(dbc_node_t *node)
{
    g_free(node->name);
    g_free(node->long_name);
    g_free(node);
}

void dbc_free_message(dbc_message_t *message)
{
    g_free(message->name);
    g_free(message->long_name);
    g_free(message->comment);

    g_slist_free(message->senders);
    g_slist_free_full(message->signals, (GDestroyNotify)dbc_free_signal);

    g_free(message);
}

void dbc_free_signal(dbc_signal_t *signal)
{
    g_free(signal->name);
    g_free(signal->long_name);
    g_free(signal->comment);
    g_free(signal->unit);

    if (signal->values)
    {
        for (value_string *val = signal->values; val->strptr; val++)
            free_value_string(val);
        g_free(signal->values);
    }

    g_free(signal);
}
