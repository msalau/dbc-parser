#include "dbc-info.h"

static void free_value_string(gpointer data)
{
    g_free(((value_string *)data)->strptr);
}

void dbc_free(dbc_file_t *file)
{
    g_free(file->name);
    g_free(file->path);
    g_free(file->comment);
    g_free(file->version);

    g_slist_free_full(file->frames, (GDestroyNotify)dbc_free_frame);
    g_slist_free_full(file->frame_types, (GDestroyNotify)free_value_string);

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
    g_free(signal->value_strings);

    if (signal->value_array)
    {
        g_array_set_clear_func(signal->value_array, free_value_string);
        g_array_free(signal->value_array, TRUE);
    }

    g_free(signal);
}
