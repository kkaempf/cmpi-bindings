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
#define Target_Type PyObject*
#define Target_Bool(x) PyBool_FromLong(x)
#define Target_WChar(x) PyInt_FromLong(x)
#define Target_Int(x) PyInt_FromLong(x)
#define Target_String(x) PyString_FromString(x)
#define Target_Real(x) Py_None
#define Target_Array() PyList_New(0)
#define Target_SizedArray(len) PyList_New(len)
#define Target_ListSet(x,n,y) PyList_SetItem(x,n,y)
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
#define Target_Type VALUE
#define Target_Bool(x) ((x)?Qtrue:Qfalse)
#define Target_WChar(x) INT2FIX(x)
#define Target_Int(x) INT2FIX(x)
#define Target_String(x) rb_str_new2(x)
#define Target_Real(x) rb_float_new(x)
#define Target_Array() rb_ary_new()
#define Target_SizedArray(len) rb_ary_new2(len)
#define Target_ListSet(x,n,y) rb_ary_store(x,n,y)
#define Target_Append(x,y) rb_ary_push(x,y)
#define Target_DateTime(x) Qnil
#define TARGET_THREAD_BEGIN_BLOCK do {} while(0)
#define TARGET_THREAD_END_BLOCK do {} while(0)
#define TARGET_THREAD_BEGIN_ALLOW do {} while(0)
#define TARGET_THREAD_END_ALLOW do {} while(0)
#include <ruby.h>
#include <ruby.h>
#if HAVE_RUBY_IO_H
#include <ruby/io.h> /* Ruby 1.9 style */
#else
#include <rubyio.h>
#endif
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
#define Target_Type SV *
#define Target_Bool(x) (x)?Target_True:Target_False
#define Target_WChar(x) NULL
#define Target_Int(x) SWIG_From_long(x)
#define Target_String(x) SWIG_FromCharPtr(x)
#define Target_Real(x) SWIG_From_double(x)
#define Target_Array() (SV *)newAV()
#define Target_SizedArray(len) (SV *)newAV()
#define Target_ListSet(x,n,y) av_store((AV *)(x),n,y)
#define Target_Append(x,y) av_push(((AV *)(x)), y)
#define Target_DateTime(x) NULL
#include <perl.h>
#include <EXTERN.h>
#endif


#include <stdint.h>

/* OS support macros */
#include <cmpi/cmpios.h>

/* CMPI convenience macros */
#include <cmpi/cmpimacs.h>

/* CMPI platform check */
#include <cmpi/cmpipl.h>

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
        result = SWIG_NewPointerObj((void*) (value->inst), SWIGTYPE_p__CMPIInstance, SWIG_POINTER_OWN);
      break;
      case CMPI_ref:          /* ((16+1)<<8) */
        result = SWIG_NewPointerObj((void*) (value->ref), SWIGTYPE_p__CMPIObjectPath, SWIG_POINTER_OWN);
      break;
      case CMPI_args:         /* ((16+2)<<8) */
        result = SWIG_NewPointerObj((void*) (value->args), SWIGTYPE_p__CMPIArgs, SWIG_POINTER_OWN);
      break;
      case CMPI_class:        /* ((16+3)<<8) */
        result = SWIG_NewPointerObj((void*) (value->inst), SWIGTYPE_p__CMPIInstance, SWIG_POINTER_OWN);
      break;
      case CMPI_filter:       /* ((16+4)<<8) */
        result = SWIG_NewPointerObj((void*) (value->filter), SWIGTYPE_p__CMPISelectExp, SWIG_POINTER_OWN);
      break;
      case CMPI_enumeration:  /* ((16+5)<<8) */
        result = SWIG_NewPointerObj((void*) (value->Enum), SWIGTYPE_p__CMPIEnumeration, SWIG_POINTER_OWN);
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
        result = SWIG_NewPointerObj((void*) &(value->dataPtr), SWIGTYPE_p__CMPIValuePtr, SWIG_POINTER_OWN);
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
  if (result == Target_Null)
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
  Target_Type result;

  if (dp->state & CMPI_notFound) {
    result = Target_Null;
    Target_INCREF(result);
  }
  else if (dp->state & (unsigned short)CMPI_badValue) {
    SWIG_exception(SWIG_ValueError, "bad value");
  }
  else if (dp->state & CMPI_nullValue) {
    result = Target_Null;
    Target_INCREF(result);
  }
  else if ((dp->type) & CMPI_ARRAY) {
    int size = CMGetArrayCount(dp->value.array, NULL);
    int i;
    result = Target_SizedArray(size);
    for (i = 0; i < size; ++i) {
      CMPIData data = CMGetArrayElementAt(dp->value.array, i, NULL);
      Target_Type value = value_value(&(data.value), (dp->type) & ~CMPI_ARRAY);
      Target_ListSet(result, i, value);
    }
  }
  else {
    result = value_value(&(dp->value), dp->type);
  }
#if !defined (SWIGRUBY)
fail:
#endif
  return result;
}

/*
 * target_charptr
 * Convert target type to const char *
 */

static const char *
target_charptr(Target_Type target)
{
  const char *str;
#if defined (SWIGRUBY)
  if (SYMBOL_P(target)) {
    str = rb_id2name(SYM2ID(target));
  }
  else if (TYPE(target) == T_STRING) {
    str = StringValuePtr(target);
  }
  else if (target == Target_Null) {
    str = NULL;
  }
  else {
    VALUE target_s = rb_funcall(target, rb_intern("to_s"), 0 );
    str = StringValuePtr(target_s);
  }
#elif defined (SWIGPYTHON)
  str = PyString_AsString(target);
#else
#warning target_charptr not defined
  str = NULL;
#endif
  return str;
}


/*
 * data_data
 * Convert CMPIData to target CMPIData
 */

static Target_Type
data_data(const CMPIData *dp)
{
  Target_Type result;

  if (dp->state & CMPI_notFound) {
    SWIG_exception(SWIG_IndexError, "value not found");
  }
  else if (dp->state & (unsigned short)CMPI_badValue) {
    SWIG_exception(SWIG_ValueError, "bad value");
  }
  else if (dp->state & CMPI_nullValue) {
    result = Target_Null;
    Target_INCREF(result);
  }
  else if ((dp->type) & CMPI_ARRAY) {
    int size = CMGetArrayCount(dp->value.array, NULL);
    int i;
    result = Target_SizedArray(size);
    for (i = 0; i < size; ++i) {
      CMPIData data = CMGetArrayElementAt(dp->value.array, i, NULL);
      Target_Type value = data_data(&data);
      Target_ListSet(result, i, value);
    }
  }
  else {
    result = SWIG_NewPointerObj((void*) data_clone(dp), SWIGTYPE_p__CMPIData, SWIG_POINTER_OWN);
  }
#if !defined (SWIGRUBY)
fail:
#endif
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

#define HAVE_CMPI_BROKER 1 /* flag availability of Cmpi#broker() callback */

static CMPIBroker *
cmpi_broker()
{
  void *ptr = 0 ;
  long long res1;
  VALUE broker = rb_funcall(mCmpi, rb_intern("broker"), 0);
  res1 = SWIG_ConvertPtr(broker, &ptr, SWIGTYPE_p__CMPIBroker, 0 |  0 );
  if (!SWIG_IsOK(res1)) {
    SWIG_exception_fail(SWIG_ArgError(res1), Ruby_Format_TypeError("", "CMPIBroker *", "broker", 1, broker));
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
  const char *str = target_charptr(data);
  return CMNewString(broker, str, NULL);
}


/*
 * Convert Target_Type to CMPIValue
 * If type  != CMPI_null, convert to ctype
 * else convert to best matching CMPIType
 *
 */

static CMPIType
target_to_value(Target_Type data, CMPIValue *value, CMPIType type)
{
  CMPIStatus st;
  /*
   * Array-type
   *
   */

  if (type & CMPI_ARRAY) {

    const CMPIBroker* broker = cmpi_broker();
    int size, i;
#if defined(SWIGRUBY)
    if (TYPE(data) != T_ARRAY) {
      data = rb_funcall(data, rb_intern("to_a"), 0 );
    }
    size = RARRAY_LEN(data);
    value->array = CMNewArray (broker, size, type, NULL);
#else
#error Undefined
#endif
    type &= ~CMPI_ARRAY;
    for (i = 0; i < size; ++i) {
      CMPIValue val;
#if defined(SWIGRUBY)
      Target_Type elem = rb_ary_entry(data, i);
#endif
      target_to_value(elem, &val, type);
      CMSetArrayElementAt(value->array, i, &val, type);
    }
    type |= CMPI_ARRAY;
  }
  else {

    /*
     * Normal-type
     *
     */

    if ((type & CMPI_REAL)) {
      if (TYPE(data) != T_FLOAT) {
        data = rb_funcall(data, rb_intern("to_f"), 0 );
      }
    }
    else if ((type & CMPI_INTEGER)) {
      if (!FIXNUM_P(data)) {
        data = rb_funcall(data, rb_intern("to_i"), 0 );
      }
    }
    
    switch (type) {
      case CMPI_null: /*         0 */
	/* CMPIType not given, deduce it from Ruby type */
	switch (TYPE(data)) {
	case T_FLOAT:
            value->Float = RFLOAT(data)->value;
            type = CMPI_real32;
	break;
	case T_STRING:
            value->string = to_cmpi_string(data);
	    type = CMPI_string;
        break; 
        case T_FIXNUM:
            value->Int = FIX2ULONG(data);
	    type = CMPI_uint32;
        break;
	case T_TRUE:
            value->boolean = 1;
            type = CMPI_boolean;
        break;
	case T_FALSE:
            value->boolean = 0;
            type = CMPI_boolean;
	break;
        case T_SYMBOL:
            value->string = to_cmpi_string(data);
	    type = CMPI_string;
        break;
        default:
            value->chars = NULL;
            type = CMPI_null;
        break;

      }
      break;
      case CMPI_boolean: /*      (2+0) */
        value->boolean = RTEST(data) ? 1 : 0;
        break;
      case CMPI_char16: /*       (2+1) */
        value->string = to_cmpi_string(data);
        break;
      case CMPI_real32: /*       ((2+0)<<2) */
        value->Float = RFLOAT(data)->value;
        break;
      case CMPI_real64: /*       ((2+1)<<2) */
        value->Double = RFLOAT(data)->value;
        break;
      case CMPI_uint8: /*        ((8+0)<<4) */
        value->uint8 = FIX2ULONG(data);
        break;
      case CMPI_uint16: /*       ((8+1)<<4) */
        value->uint16 = FIX2ULONG(data);
        break;
      case CMPI_uint32: /*       ((8+2)<<4) */
        value->uint32 = FIX2ULONG(data);
        break;
      case CMPI_uint64: /*       ((8+3)<<4) */
        value->uint64 = FIX2ULONG(data);
        break;
      case CMPI_sint8: /*        ((8+4)<<4) */
        value->sint8 = FIX2LONG(data);
        break;
      case CMPI_sint16: /*       ((8+5)<<4) */
        value->sint16 = FIX2LONG(data);
        break;
      case CMPI_sint32: /*       ((8+6)<<4) */        
        value->sint32 = FIX2LONG(data);
        break;
      case CMPI_sint64: /*       ((8+7)<<4) */
        value->sint64 = FIX2LONG(data);
        break;
      case CMPI_instance: { /*     ((16+0)<<8) */
        CMPIData *cmpi_data;
	/* try with CMPIData first */
        int res = SWIG_ConvertPtr(data, (void *)&cmpi_data, SWIGTYPE_p__CMPIData, 0 |  0 );
	if (SWIG_IsOK(res)) {
	  if ((cmpi_data->state == CMPI_goodValue)
	      && (cmpi_data->type == type)) {
	    value->inst = cmpi_data->value.inst;
	  }
	  else {
	    res = SWIG_ERROR;
	  }
	}
	else {
          res = SWIG_ConvertPtr(data, (void *)&(value->inst), SWIGTYPE_p__CMPIInstance, 0 |  0 );
	}
	if (!SWIG_IsOK(res)) {
	  SWIG_exception_fail(SWIG_ArgError(res), Ruby_Format_TypeError( "", "CMPIInstance *","target_to_value", 1, data )); 
        }
        break;
      }
      case CMPI_ref: { /*          ((16+1)<<8) */
        CMPIData *cmpi_data;
	/* try with CMPIData first */
        int res = SWIG_ConvertPtr(data, (void *)&cmpi_data, SWIGTYPE_p__CMPIData, 0 |  0 );
	if (SWIG_IsOK(res)) {
	  if ((cmpi_data->state == CMPI_goodValue)
	      && (cmpi_data->type == type)) {
	    value->ref = cmpi_data->value.ref;
	  }
	  else {
	    res = SWIG_ERROR;
	  }
	}
	else {
          res = SWIG_ConvertPtr(data, (void *)&(value->ref), SWIGTYPE_p__CMPIObjectPath, 0 |  0 );
	}
	if (!SWIG_IsOK(res)) {
	  SWIG_exception_fail(SWIG_ArgError(res), Ruby_Format_TypeError( "", "CMPIObjectPath *","target_to_value", 1, data )); 
	}
        break;
      }
#if 0
      case CMPI_args: /*         ((16+2)<<8) */
        break;
      case CMPI_class: /*        ((16+3)<<8) */
        break;
      case CMPI_filter: /*       ((16+4)<<8) */
        break;
      case CMPI_enumeration: /*  ((16+5)<<8) */
        break;
#endif
      case CMPI_string: /*       ((16+6)<<8) */
        value->string = to_cmpi_string(data);
        break;
      case CMPI_chars: /*        ((16+7)<<8) */
        value->chars = strdup(target_charptr(data));
        break;
      case CMPI_dateTime: { /*     ((16+8)<<8) */
        const CMPIBroker* broker = cmpi_broker();
	if (FIXNUM_P(data)) { /* Integer -> seconds since Epoch */
	  data = rb_funcall(rb_cTime, rb_intern("at"), 1, data );
	}
	VALUE usecs = rb_funcall(data, rb_intern("usec"), 0 );
	VALUE secs = rb_funcall(data, rb_intern("to_i"), 0 );
	CMPIUint64 bintime = INT2FIX(usecs);
	fprintf(stderr, "CMPI_dateTime: usecs %lld\n", bintime);
	CMPIUint64 sectime = INT2FIX(secs);
	fprintf(stderr, "CMPI_dateTime: secs %lld\n", sectime);
	bintime += sectime * (CMPIUint64)1000 * (CMPIUint64)1000;
	value->dateTime = CMNewDateTimeFromBinary(broker, bintime, 0, &st);
	fprintf(stderr, "CMPI_dateTime: %lld => %d\n", bintime, st.rc); /* , CMGetCharPtr(st.msg) */
      }
      break;
#if 0
      case CMPI_ptr: /*          ((16+9)<<8) */
        break;
      case CMPI_charsptr: /*     ((16+10)<<8) */
        break;
#endif
      default:
      fprintf(stderr, "*** target_to_value: Unhandled type %08x\n", type);
      break;
    } /* switch (type) */
  }
fail:
  return type;
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

#ifdef SWIGPYTHON
static void _set_raised()
{
    pthread_once(&_once, _init_key);
    pthread_setspecific(_key, (void*)1);
}
#endif

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

%typemap(newfree) char * "free($1);";

/* disown pointers passed back through CMReturn... */
%apply SWIGTYPE *DISOWN { CMPIInstance *instance_disown };
%apply SWIGTYPE *DISOWN { CMPIObjectPath *path_disown };

# Definitions
%include "cmpi_defs.i"

# Data types
%include "cmpi_types.i"

# Broker callbacks
%include "cmpi_callbacks.i"
