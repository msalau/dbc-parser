#ifndef VALUE_STRING_H
#define VALUE_STRING_H

#include <stdint.h>

typedef struct
{
  int32_t  value;
  char    *strptr;
} value_string;

#endif
