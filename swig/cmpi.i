%{
/* Document-module: Cmpi
 *
 * Cmpi is the module namespace for cmpi-bindings.
 *
 * cmpi-bindings implements a CMPI providers in any
 * target language by using the SWIG bindings generator.
 *
 */
%}

	   
%module cmpi
%feature("autodoc","1");

%include "typemaps.i"
%include exception.i

%{

/*
 * type definitions to keep the C code generic
 */
 
#if defined(SWIGPYTHON)
#define Target_Null_p(x) (x == Py_None)
#define Target_INCREF(x) Py_INCREF(x)
#define Target_DECREF(x) Py_DECREF(x)
#define Target_True Py_True
#define Target_False Py_False
#define Target_Null NULL
#define Target_Void Py_None
#define Target_Type PyObject*
#define Target_Bool(x) PyBool_FromLong(x)
#define Target_Int(x) PyInt_FromLong(x)
#define Target_String(x) PyString_FromString(x)
#define Target_Array() PyList_New(0)
#define Target_Append(x,y) PyList_Append(x,y)
#include <Python.h>
#define TARGET_THREAD_BEGIN_BLOCK SWIG_PYTHON_THREAD_BEGIN_BLOCK
#define TARGET_THREAD_END_BLOCK SWIG_PYTHON_THREAD_END_BLOCK
#define TARGET_THREAD_BEGIN_ALLOW SWIG_PYTHON_THREAD_BEGIN_ALLOW
#define TARGET_THREAD_END_ALLOW SWIG_PYTHON_THREAD_END_ALLOW
#endif

#if defined(SWIGRUBY)
#define Target_Null_p(x) NIL_P(x)
#define Target_INCREF(x) 
#define Target_DECREF(x) 
#define Target_True Qtrue
#define Target_False Qfalse
#define Target_Null Qnil
#define Target_Void Qnil
#define Target_Type VALUE
#define Target_Bool(x) ((x)?Qtrue:Qfalse)
#define Target_Int(x) INT2FIX(x)
#define Target_String(x) rb_str_new2(x)
#define Target_Array() rb_ary_new()
#define Target_Append(x,y) rb_ary_push(x,y)
#define TARGET_THREAD_BEGIN_BLOCK
#define TARGET_THREAD_END_BLOCK
#define TARGET_THREAD_BEGIN_ALLOW
#define TARGET_THREAD_END_ALLOW
#include <ruby.h>
#include <rubyio.h>
#endif

#if defined(SWIGPERL)
#define Target_Null_p(x) (x == NULL)
#define Target_INCREF(x) 
#define Target_DECREF(x) 
#define Target_True (&PL_sv_yes)
#define Target_False (&PL_sv_no)
#define Target_Null NULL
#define Target_Type SV *
#define Target_Bool(x) (x)
#define Target_Int(x) 0 /* should be Target_From_long(x), but Swig declares it too late. FIXME */
#define Target_String(x) "" /* Target_FromCharPtr(x), also */
#define Target_Array(x) NULL
#define Target_Append(x,y) av_create_and_push(&x, y)
#define TARGET_THREAD_BEGIN_BLOCK
#define TARGET_THREAD_END_BLOCK
#define TARGET_THREAD_BEGIN_ALLOW
#define TARGET_THREAD_END_ALLOW
#endif


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

    if (st->msg) {
        const char* chars = CMGetCharsPtr(st->msg, NULL);
        ex->description = strdup(chars);
    }
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

#include "../src/cmpi_provider.c"

/* RAISE exception IF status argument has a nonzero rc member */
#define RAISE_IF(EXPR) \
    do \
    { \
        CMPIStatus __st__ = (EXPR); \
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
