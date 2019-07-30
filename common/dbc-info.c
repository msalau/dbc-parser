#include "dbc-info.h"
#include <stdio.h>

dbc_file_t *dbc_new(const char *filepath)
{
    dbc_file_t *dbc = g_new0(dbc_file_t, 1);

    dbc->filepath       = g_strdup(filepath);
    dbc->j1939_type_num = -1;

    return dbc;
}

static gint dbc_find_frame_helper(gconstpointer frame, gconstpointer id)
{
    return ((const dbc_frame_t *)frame)->id == GPOINTER_TO_UINT(id) ? 0 : 1;
}

dbc_frame_t *dbc_find_frame(const dbc_file_t *file, uint32_t id)
{
    GSList *elem = g_slist_find_custom(file->frames, GUINT_TO_POINTER(id), dbc_find_frame_helper);
    return elem ? elem->data : NULL;
}

static gint dbc_find_signal_helper(gconstpointer signal, gconstpointer name)
{
    return g_strcmp0(((const dbc_signal_t *)signal)->name, name);
}

dbc_signal_t *dbc_find_signal(const dbc_file_t *file, uint32_t id, const char *name)
{
    dbc_frame_t *frame = dbc_find_frame(file, id);
    if (!frame)
        return NULL;

    GSList *elem = g_slist_find_custom(frame->signals, name, dbc_find_signal_helper);
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

    g_slist_free_full(file->frames, (GDestroyNotify)dbc_free_frame);

    g_free(file);
}

void dbc_free_frame(dbc_frame_t *frame)
{
    g_free(frame->name);
    g_free(frame->comment);
    g_free(frame->senders);

    g_slist_free_full(frame->signals, (GDestroyNotify)dbc_free_signal);

    g_free(frame);
}

void dbc_free_signal(dbc_signal_t *signal)
{
    g_free(signal->name);
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
