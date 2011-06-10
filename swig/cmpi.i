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

#define __type

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
#define Target_Null Py_None
#define Target_Void Py_None
#define Target_Type PyObject*
#define Target_Bool(x) PyBool_FromLong(x)
#define Target_WChar(x) PyInt_FromLong(x)
#define Target_Int(x) PyInt_FromLong(x)
#define Target_String(x) PyString_FromString(x)
#define Target_Real(x) Py_None
#define Target_Array() PyList_New(0)
#define Target_SizedArray(len) PyList_New(len)
#define Target_Append(x,y) PyList_Append(x,y)
#define Target_DateTime(x) Py_None
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
#define Target_WChar(x) INT2FIX(x)
#define Target_Int(x) INT2FIX(x)
#define Target_String(x) rb_str_new2(x)
#define Target_Real(x) rb_float_new(x)
#define Target_Array() rb_ary_new()
#define Target_SizedArray(len) rb_ary_new2(len)
#define Target_Append(x,y) rb_ary_push(x,y)
#define Target_DateTime(x) Qnil
#define TARGET_THREAD_BEGIN_BLOCK do {} while(0)
#define TARGET_THREAD_END_BLOCK do {} while(0)
#define TARGET_THREAD_BEGIN_ALLOW do {} while(0)
#define TARGET_THREAD_END_ALLOW do {} while(0)
#include <ruby.h>
#include <rubyio.h>
#endif

#if defined(SWIGPERL)
#define TARGET_THREAD_BEGIN_BLOCK do {} while(0)
#define TARGET_THREAD_END_BLOCK do {} while(0)
#define TARGET_THREAD_BEGIN_ALLOW do {} while(0)
#define TARGET_THREAD_END_ALLOW do {} while(0)

SWIGINTERNINLINE SV *SWIG_From_long  SWIG_PERL_DECL_ARGS_1(long value);
SWIGINTERNINLINE SV *SWIG_FromCharPtr(const char *cptr);
SWIGINTERNINLINE SV *SWIG_From_double  SWIG_PERL_DECL_ARGS_1(double value);

#define Target_Null_p(x) (x == NULL)
#define Target_INCREF(x) 
#define Target_DECREF(x) 
#define Target_True (&PL_sv_yes)
#define Target_False (&PL_sv_no)
#define Target_Null NULL
#define Target_Void NULL
#define Target_Type SV *
#define Target_Bool(x) (x)?Target_True:Target_False
#define Target_WChar(x) NULL
#define Target_Int(x) SWIG_From_long(x)
#define Target_String(x) SWIG_FromCharPtr(x)
#define Target_Real(x) SWIG_From_double(x)
#define Target_Array() (SV *)newAV()
#define Target_SizedArray(len) (SV *)newAV()
#define Target_Append(x,y) av_push(((AV *)(x)), y)
#define Target_DateTime(x) NULL
#include <perl.h>
#include <EXTERN.h>
#endif


#include <stdint.h>

/* OS support macros */
#include <cmpios.h>

/* CMPI convenience macros */
#include <cmpimacs.h>

/* CMPI platform check */
#include <cmpipl.h>

#include <pthread.h>

/*
 * value_value
 * convert CMPIValue to target value
 * Attn: CMPIValue must be of non-array type !
 */

static Target_Type
value_value(const CMPIValue *value, const CMPIType type)
{
  Target_Type result;
  switch (type)
    {
      case CMPI_null:
        result = Target_Null;
      break;
 
      case CMPI_boolean:    /* (2+0) */
        result = Target_Bool(value->boolean);
      break;
      case CMPI_char16:    /* (2+1) */
        result = Target_WChar(value->char16);
      break;

      case CMPI_real32:    /* ((2+0)<<2) */
        result = Target_Real(value->real32);
      break;
      case CMPI_real64:    /* ((2+1)<<2) */
        result = Target_Real(value->real64);
      break;

      case CMPI_uint8:        /* ((8+0)<<4) */
        result = Target_Int(value->uint8);
      break;
      case CMPI_uint16:       /* ((8+1)<<4) */
        result = Target_Int(value->uint16);
      break;
      case CMPI_uint32:      /* ((8+2)<<4) */
        result = Target_Int(value->uint32);
      break;
      case CMPI_uint64:       /* ((8+3)<<4) */
        result = Target_Int(value->uint64);
      break;

      case CMPI_sint8:        /* ((8+4)<<4) */
        result = Target_Int(value->sint8);
      break;
      case CMPI_sint16:       /* ((8+5)<<4) */
        result = Target_Int(value->sint16);
      break;
      case CMPI_sint32:       /* ((8+6)<<4) */
        result = Target_Int(value->sint32);
      break;
      case CMPI_sint64:       /* ((8+7)<<4) */
        result = Target_Int(value->sint64);
      break;

      case CMPI_instance:     /* ((16+0)<<8) */
        return SWIG_NewPointerObj((void*) (value->inst), SWIGTYPE_p__CMPIInstance, SWIG_POINTER_OWN);
      break;
      case CMPI_ref:          /* ((16+1)<<8) */
        return SWIG_NewPointerObj((void*) (value->ref), SWIGTYPE_p__CMPIObjectPath, SWIG_POINTER_OWN);
      break;
      case CMPI_args:         /* ((16+2)<<8) */
        return SWIG_NewPointerObj((void*) (value->args), SWIGTYPE_p__CMPIArgs, SWIG_POINTER_OWN);
      break;
      case CMPI_class:        /* ((16+3)<<8) */
        return SWIG_NewPointerObj((void*) (value->inst), SWIGTYPE_p__CMPIInstance, SWIG_POINTER_OWN);
      break;
      case CMPI_filter:       /* ((16+4)<<8) */
        return SWIG_NewPointerObj((void*) (value->filter), SWIGTYPE_p__CMPISelectExp, SWIG_POINTER_OWN);
      break;
      case CMPI_enumeration:  /* ((16+5)<<8) */
        return SWIG_NewPointerObj((void*) (value->Enum), SWIGTYPE_p__CMPIEnumeration, SWIG_POINTER_OWN);
      break;
      case CMPI_string:       /* ((16+6)<<8) */
        result = Target_String(CMGetCharPtr(value->string));
      break;
      case CMPI_chars:        /* ((16+7)<<8) */
        result = Target_String(value->chars);
      break;
      case CMPI_dateTime:     /* ((16+8)<<8) */
        result = Target_DateTime(value->dateTime);
      break;
      case CMPI_ptr:          /* ((16+9)<<8) */
        return SWIG_NewPointerObj((void*) &(value->dataPtr), SWIGTYPE_p__CMPIValuePtr, SWIG_POINTER_OWN);
      break;
      case CMPI_charsptr:     /* ((16+10)<<8) */
         /* FIXME: unused ? */
        result = Target_Null;
      break;
      default:
        /* FIXME: raise ! */
        result = Target_Null;
      break;
    }
  Target_INCREF(result);
  return result;
}


/*
 * data_clone
 * clone CMPIData
 */

static CMPIData *
data_clone(const CMPIData *dp)
{
  CMPIData *data = (CMPIData *)calloc(1, sizeof(CMPIData));
  memcpy(data, dp, sizeof(CMPIData));
  return data;
}


/*
 * data_value
 * Convert CMPIData to target type
 */

static Target_Type
data_value(const CMPIData *dp)
{
  Target_Type result = Target_Null;

  if (dp->state & CMPI_notFound) {
    SWIG_exception(SWIG_IndexError, "value not found");
  }
  else if (dp->state & CMPI_badValue) {
    SWIG_exception(SWIG_ValueError, "bad value");
  }
  else if ((dp->type) & CMPI_ARRAY) {
    int size = CMGetArrayCount(dp->value.array, NULL);
    int i;
    result = Target_SizedArray(size);
    for (i = 0; i < size; --i) {
      CMPIData data = CMGetArrayElementAt(dp->value.array, i, NULL);
      Target_Append(result, value_value(&(data.value), (dp->type) & ~CMPI_ARRAY));
    }
    Target_INCREF(result);
  }
  else {
    result = value_value(&(dp->value), dp->type);
  }
fail:
  return result;
}


/*
 * data_data
 * Convert CMPIData to target CMPIData
 */

static Target_Type
data_data(const CMPIData *dp)
{
  Target_Type result = Target_Null;

  if (dp->state & CMPI_notFound) {
    SWIG_exception(SWIG_IndexError, "value not found");
  }
  else if (dp->state & CMPI_badValue) {
    SWIG_exception(SWIG_ValueError, "bad value");
  }
  else if (dp->state & CMPI_nullValue) {
    Target_INCREF(result);
  }
  else if ((dp->type) & CMPI_ARRAY) {
    int size = CMGetArrayCount(dp->value.array, NULL);
    int i;
    result = Target_SizedArray(size);
    for (i = 0; i < size; --i) {
      CMPIData data = CMGetArrayElementAt(dp->value.array, i, NULL);
      Target_Append(result, data_data(&data));
    }
    Target_INCREF(result);
  }
  else {
    result = SWIG_NewPointerObj((void*) data_clone(dp), SWIGTYPE_p__CMPIData, SWIG_POINTER_OWN);
  }
fail:
  return result;
}




#if defined (SWIGRUBY)
/*
 * Callback to get CMPIBroker pointer from provider
 *
 * CMPIBroker is required e.g. for CMNewString and the provider
 * gets the pointer during initialization and keeps it as a
 * _module_ variable.
 *
 */

#define HAVE_CMPI_BROKER 1 /* flag availability of cmpi_broker() callback */

static CMPIBroker *
cmpi_broker()
{
  void *ptr = 0 ;
  long long res1;
  VALUE broker = rb_funcall(mCmpi, rb_intern("cmpi_broker"), 0);
  res1 = SWIG_ConvertPtr(broker, &ptr, SWIGTYPE_p__CMPIBroker, 0 |  0 );
  if (!SWIG_IsOK(res1)) {
    SWIG_exception_fail(SWIG_ArgError(res1), Ruby_Format_TypeError("", "CMPIBroker *", "cmpi_broker", 1, mCmpi));
  }
  return (CMPIBroker *)ptr;
fail:
  return NULL;
}


/*
 * Convert Ruby Value to CMPIString
 *
 */
static CMPIString *
to_cmpi_string(VALUE data)
{
  CMPIBroker *broker = cmpi_broker();
  const char *str;

  switch(TYPE(data)) {
    case T_STRING:
      str = StringValuePtr(data);
      break;
    case T_SYMBOL:
      str = rb_id2name(SYM2ID(data));
      break;
    default:
      data = rb_funcall(data, rb_intern("to_s"), 0 );
      str = StringValuePtr(data);
   }      
   return CMNewString(broker, str, NULL);
}

#endif /* SWIGRUBY */

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
    obj = SWIG_NewPointerObj(ex, SWIGTYPE_p__CMPIException, SWIG_POINTER_OWN);
    PyErr_SetObject(SWIG_Python_ExceptionType(SWIGTYPE_p__CMPIException), obj);
    SWIG_PYTHON_THREAD_END_BLOCK;
    _set_raised();
#endif /* SWIGPYTHON */
}

/*
**==============================================================================
**
** Shim code converting CMPI provider calls to target language
**
**
**  define CMPI_PURE_BINDINGS during build to just get the SWIG bindings
**  for testing
**
**==============================================================================
*/

#ifndef CMPI_PURE_BINDINGS
#include "../src/cmpi_provider.c"
#endif

/*
**==============================================================================
**
** raise_exception()
** provider code
**
**==============================================================================
*/

/* RAISE exception IF status argument has a nonzero rc member */
#define RAISE_IF(EXPR) \
    do \
    { \
        CMPIStatus __st__ = (EXPR); \
        if (__st__.rc) \
            _raise_ex(&__st__); \
    } \
    while (0)

/*
**==============================================================================
**
** String array implementation functions.
**
**==============================================================================
*/

#include "string_array.h"

%}

%exceptionclass CMPIException;
%exceptionclass _CMPIException;

# Definitions
%include "cmpi_defs.i"

# Data types
%include "cmpi_types.i"

# Broker callbacks
%include "cmpi_callbacks.i"
