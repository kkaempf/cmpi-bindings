/*
 * This file defines functions for manipulating null-terminated arrays of
 * pointers to strings (string arrays).
 */
#ifndef string_array_h
#define string_array_h

#include <stdio.h>
#include <stdlib.h>

static size_t string_array_size(char** array)
{
    char** p;

    if (!array)
        return 0;

    for (p = array; *p; p++)
        ;

    return p - array;
}

static char** string_array_clone(char** array)
{
    char** p;
    size_t n;
    size_t i;

    if (!array)
    {
        p = (char**)malloc(sizeof(char*));
        *p = NULL;
        return p;
    }

    n = string_array_size(array);

    if (!(p = (char**)malloc((n + 1) * sizeof(char*))))
        return NULL;

    for (i = 0; i < n; i++)
        p[i] = strdup(array[i]);

    p[i] = NULL;

    return p;
}

static char** string_array_append(char** array, const char* str)
{
    size_t n;

    n = string_array_size(array);

    if (!(array = (char**)realloc(array, (n + 2) * sizeof(char*))))
        return NULL;

    array[n] = strdup(str);
    array[n+1] = NULL;

    return array;
}

static void string_array_free(char** array)
{
    char** p;

    if (!array)
        return;

    for (p = array; *p; p++)
        free(*p);

    free(array);
}

#if 0
static const char* string_array_find(char** array, const char* str)
{
    char** p;

    for (p = array; *p; p++)
    {
        if (strcmp(*p, str) == 0)
            return *p;
    }

    /* Not found! */
    return NULL;
}
#endif

static const char* string_array_find_ignore_case(char** array, const char* str)
{
    char** p;

    for (p = array; *p; p++)
    {
        if (strcasecmp(*p, str) == 0)
            return *p;
    }

    /* Not found! */
    return NULL;
}

#if 0
static void string_array_print(char** array)
{
    char** p;

    fprintf(stderr, "string_array\n");
    fprintf(stderr, "{\n");

    for (p = array; *p; p++)
    {
        fprintf(stderr, "    {%s}\n", *p);
    }

    fprintf(stderr, "}\n");
}
#endif

#endif /* string_array_h */
