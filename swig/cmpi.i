%module cmpi

%include "typemaps.i"
%include exception.i

%{
#include <stdint.h>

/* OS support macros */
#include <cmpios.h>

/* CMPI convenience macros */
#include <cmpimacs.h>

/* CMPI platform check */
#include <cmpipl.h>

#include <pthread.h>

static CMPIData *
clone_data(const CMPIData *dp)
{
  CMPIData *data = (CMPIData *)calloc(1, sizeof(CMPIData));
  memcpy(data, dp, sizeof(CMPIData));
  return data;
}

/*
**==============================================================================
**
** struct _CMPIException
**
**==============================================================================
*/

struct _CMPIException
{
    int error_code;
    char* description;
};

typedef struct _CMPIException CMPIException;

/*
**==============================================================================
**
** raise_exception() and associated paraphernalia
**
**==============================================================================
*/

static pthread_once_t _once = PTHREAD_ONCE_INIT;
static pthread_key_t _key;

static void _init_key()
{
    pthread_key_create(&_key, NULL);
}

static void* _get_raised()
{
    pthread_once(&_once, _init_key);
    return pthread_getspecific(_key);
}

static void _set_raised()
{
    pthread_once(&_once, _init_key);
    pthread_setspecific(_key, (void*)1);
}

static void _clr_raised()
{
    pthread_once(&_once, _init_key);
    pthread_setspecific(_key, NULL);
}

static void _raise_ex(const CMPIStatus* st)
{
#ifdef SWIGPYTHON
    PyObject* obj;
    CMPIException* ex;
    
    ex = (CMPIException*)malloc(sizeof(CMPIException));
    ex->error_code = st->rc;
    const char* chars;

    if (st->msg)
        chars = CMGetCharsPtr(st->msg, NULL);

    if (chars)
        ex->description = strdup(chars);
    else
        ex->description = NULL;

    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    obj = SWIG_NewPointerObj(ex, SWIGTYPE_p__CMPIException, 1);
    PyErr_SetObject(SWIG_Python_ExceptionType(SWIGTYPE_p__CMPIException), obj);
    SWIG_PYTHON_THREAD_END_BLOCK;
    _set_raised();
#endif /* SWIGPYTHON */
}

/*
**==============================================================================
**
** raise_exception()
** provider code
**
**==============================================================================
*/

#if defined(SWIGRUBY)
#include "../src/cmpi_provider_ruby.c"
#endif

#if defined(SWIGPYTHON)
#include "../src/cmpi_provider_python.c"
#endif

/* RAISE exception IF status argument has a nonzero rc member */
#define RAISE_IF(ST) \
    do \
    { \
        CMPIStatus __st__ = (ST); \
        if (__st__.rc) \
            _raise_ex(&__st__); \
    } \
    while (0)

%}

%exceptionclass CMPIException;
%exceptionclass _CMPIException;

# Definitions
%include "cmpi_defs.i"

# Data types
%include "cmpi_types.i"

# Broker callbacks
%include "cmpi_callbacks.i"
