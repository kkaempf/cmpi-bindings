%module cmpi

%include "typemaps.i"

%{
#include <stdint.h>

/* OS support macros */
#include <cmpios.h>

/* CMPI convenience macros */
#include <cmpimacs.h>

/* CMPI platform check */
#include <cmpipl.h>

#include <pthread.h>

/* CMPIException */
struct _CMPIException
{
    int error_code;
    char* description;
};

typedef struct _CMPIException CMPIException;

static CMPIData *
clone_data(const CMPIData *dp)
{
  CMPIData *data = (CMPIData *)calloc(1, sizeof(CMPIData));
  memcpy(data, dp, sizeof(CMPIData));
  return data;
}

/*
 * raise_exception()
 */

pthread_once_t _once = PTHREAD_ONCE_INIT;

static void* _get_raised()
{
    return pthread_getspecific(_once);
}

static void _set_raised()
{
    static const char _data[] = "dummy string";
    pthread_setspecific(_once, (void*)_data);
}

static void _clr_raised()
{
    pthread_setspecific(_once, NULL);
}

void raise_exception(int error_code, const char* description)
{
    char buffer[1024];
    sprintf(buffer, "%d:%s", error_code, description);

    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    PyErr_SetString(PyExc_RuntimeError, buffer);
    SWIG_PYTHON_THREAD_END_BLOCK;
    _set_raised();
}

/*
 * provider code
 */

#if defined(SWIGRUBY)
#include "../src/cmpi_provider_ruby.c"
#endif

#if defined(SWIGPYTHON)
#include "../src/cmpi_provider_python.c"
#endif

%}

# Definitions
%include "cmpi_defs.i"

# Data types
%include "cmpi_types.i"

# Broker callbacks
%include "cmpi_callbacks.i"
