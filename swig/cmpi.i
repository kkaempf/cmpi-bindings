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
#define Target_Char16(x) PyInt_FromLong(x)
#define Target_Int(x) PyInt_FromLong(x)
#define Target_String(x) PyString_FromString(x)
#define Target_Real(x) Py_None
#define Target_Array() PyList_New(0)
#define Target_SizedArray(len) PyList_New(len)
#define Target_ListSet(x,n,y) PyList_SetItem(x,n,y)
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
#define Target_Type VALUE
#define Target_Bool(x) ((x)?Qtrue:Qfalse)
#define Target_Char16(x) INT2FIX(x)
#define Target_Int(x) INT2FIX(x)
#define Target_String(x) rb_str_new2(x)
#define Target_Real(x) rb_float_new(x)
#define Target_Array() rb_ary_new()
#define Target_SizedArray(len) rb_ary_new2(len)
#define Target_ListSet(x,n,y) rb_ary_store(x,n,y)
#define Target_Append(x,y) rb_ary_push(x,y)
#define TARGET_THREAD_BEGIN_BLOCK do {} while(0)
#define TARGET_THREAD_END_BLOCK do {} while(0)
#define TARGET_THREAD_BEGIN_ALLOW do {} while(0)
#define TARGET_THREAD_END_ALLOW do {} while(0)
#include <ruby.h>
#if HAVE_RUBY_IO_H
#include <ruby/io.h> /* Ruby 1.9 style */
#else
#include <rubyio.h>
#endif
#if HAVE_RUBY_VERSION_H
#include <ruby/version.h>
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
#define Target_Char16(x) SWIG_From_long(x)
#define Target_Int(x) SWIG_From_long(x)
#define Target_String(x) SWIG_FromCharPtr(x)
#define Target_Real(x) SWIG_From_double(x)
#define Target_Array() (SV *)newAV()
#define Target_SizedArray(len) (SV *)newAV()
#define Target_ListSet(x,n,y) av_store((AV *)(x),n,y)
#define Target_Append(x,y) av_push(((AV *)(x)), y)
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

#include <syslog.h>
#include <pthread.h>

/*
 * Convert CMPIDateTime to native representation as Target_Type
 *
 * Calls Cmpi#datetime in Ruby
 */

static Target_Type
Target_DateTime(CMPIDateTime *datetime)
{
  CMPIStatus st;
  Target_Type result;
  if (datetime) {
    /* this used to call datetime->ft->getBinaryFormat(datetime, &st)
     * but was abandoned since getBinaryFormat cannot handle pre-epoch
     * times (as per CMPI 2.0 standard).
     */
    CMPIString *dtstr = datetime->ft->getStringFormat(datetime, &st);
    if (st.rc) {
#if !defined (SWIGRUBY)
      result = Target_Null;
#endif
      SWIG_exception(SWIG_ValueError, "bad CMPIDateTime value");
    }
#if defined(SWIGRUBY)
    result = rb_funcall(mCmpi, rb_intern("cimdatetime_to_ruby"), 1, Target_String(CMGetCharPtr(dtstr)));
#else
    SWIG_exception(SWIG_RuntimeError, "CMPIDate conversion not implemented");
#endif
  }
  else {
    result = Target_Null;
  }
#if !defined (SWIGRUBY)
fail:
#endif
  return result;
}


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
        result = Target_Char16(value->char16);
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
        result = SWIG_NewPointerObj((void*) (value->inst),
SWIGTYPE_p__CMPIInstance, SWIG_POINTER_OWN);
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
      {
        const char *s = CMGetCharPtr(value->string);
        if (s == NULL) /* yes, this is possible */
          s = "";
        result = Target_String(s);
      }
      break;
      case CMPI_chars:        /* ((16+7)<<8) */
        if (value->chars == NULL)
          result = Target_String("");
        else
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

  if ((dp->state & CMPI_notFound)  /* should CMPI_notFound raise or return NULL ? */
      || (dp->state & CMPI_nullValue)
      || (dp->type == CMPI_null)) {
    result = Target_Null;
    Target_INCREF(result);
  }
  else if (dp->state & (unsigned short)CMPI_badValue) {
    SWIG_exception(SWIG_ValueError, "bad value");
  }
  else if (dp->type & CMPI_ARRAY) {
    int size = CMGetArrayCount(dp->value.array, NULL);
    int i;
    result = Target_SizedArray(size);
    for (i = 0; i < size; ++i) {
      CMPIData data = CMGetArrayElementAt(dp->value.array, i, NULL);
      Target_Type value = data_value(&data);
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
    SWIG_exception(SWIG_ArgError(res1), Ruby_Format_TypeError("", "CMPIBroker *", "broker", 1, broker));
  }
  return (CMPIBroker *)ptr;
#if !defined (SWIGRUBY)
fail:
#endif
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
 * return actual type
 */

static CMPIType
target_to_value(Target_Type data, CMPIValue *value, CMPIType type)
{
#if defined(SWIGRUBY)
  /*
   * Array-type
   *
   */
  if (type & CMPI_ARRAY) {

    const CMPIBroker* broker = cmpi_broker();
    int size, i;
    CMPIType element_type = 0;    
    if (TYPE(data) != T_ARRAY) {
      if (Target_Null_p(data)) {
        value->array = NULL;
        return CMPI_null;
      }
      data = rb_funcall(data, rb_intern("to_a"), 0 );
    }
    size = RARRAY_LEN(data);
    value->array = CMNewArray (broker, size, type, NULL);
    /* take away ARRAY flag to process elements */
    type &= ~CMPI_ARRAY;
    for (i = 0; i < size; ++i) {
      CMPIValue val;
      CMPIType new_type;
      Target_Type elem = rb_ary_entry(data, i);
      new_type = target_to_value(elem, &val, type);
      if (element_type) {
        /* ensure all array elements have same type */
        if (new_type != element_type) {
          SWIG_exception(SWIG_ValueError, "non-uniform element types in array");
        }
      }
      else {
        element_type = new_type;
      }      
      CMSetArrayElementAt(value->array, i, &val, element_type);
    }
    if (type & ((1<<15)|(1<<14))) { /* embedded instance or object */
      type = element_type;
    }
    /* re-add ARRAY flag */
    type |= CMPI_ARRAY;
  }
  else {

    /*
     * Normal-type
     *
     */

    if ((type & CMPI_REAL)) {
      if (Target_Null_p(data)) {
        SWIG_exception(SWIG_ValueError, "can't convert NULL to real");
      }
      if (TYPE(data) != T_FLOAT) {
        data = rb_funcall(data, rb_intern("to_f"), 0 );
      }
    }
    else if ((type & CMPI_INTEGER)) {
      if (Target_Null_p(data)) {
        SWIG_exception(SWIG_ValueError, "can't convert NULL to integer");
      }
      if (!FIXNUM_P(data)) {
        data = rb_funcall(data, rb_intern("to_i"), 0 );
      }
    }
    else if (Target_Null_p(data)) {
      /* A NULL value always has CMPIType CMPI_null */
      value->chars = NULL;
      return CMPI_null;
    }
    switch (type) {
      case CMPI_null: /*         0 */
	/* CMPIType not given, deduce it from Ruby type */
	switch (TYPE(data)) {
	case T_FLOAT:
            value->Float = RFLOAT_VALUE(data);
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
        if (FIXNUM_P(data)) {
          value->char16 = FIX2INT(data);
        }
        else {
          const char *s = target_charptr(data);
          if (s) {
            value->char16 = *s + (*(s+1)<<8);
          }
          else {
            value->char16 = 0;
          }
        }
        if (value->char16 == 0) {
          static char msg[64];
          snprintf(msg, 63, "target_to_value: invalid value %d for char16 type", value->char16);
          SWIG_exception(SWIG_ValueError, msg);
        }
        break;
      case CMPI_real32: /*       ((2+0)<<2) */
        value->Float = RFLOAT_VALUE(data);
        break;
      case CMPI_real64: /*       ((2+1)<<2) */
        value->Double = RFLOAT_VALUE(data);
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
	  SWIG_exception(SWIG_ArgError(res), Ruby_Format_TypeError( "", "CMPIInstance *","target_to_value", 1, data )); 
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
	  SWIG_exception(SWIG_ArgError(res), Ruby_Format_TypeError( "", "CMPIObjectPath *","target_to_value", 1, data )); 
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
        CMPIStatus st;
        const char *s;

        data = rb_funcall(mCmpi, rb_intern("ruby_to_cimdatetime"), 1, data);
        s = StringValuePtr(data);
        value->dateTime = CMNewDateTimeFromChars(broker, s, &st);
        if (st.rc) {
          static char msg[64];
          snprintf(msg, 63, "CMNewDateTimeFromChars(%s) failed with %d", s, st.rc);
          SWIG_exception(SWIG_ValueError, msg);
        }
      }
      break;
#if 0
      case CMPI_ptr: /*          ((16+9)<<8) */
        break;
      case CMPI_charsptr: /*     ((16+10)<<8) */
        break;
#endif
      case ((1)<<14): { /* cmpi-bindings-ruby: EmbeddedObject */
        /* class or instance */
        /* need CMPIClass as Ruby class */
        int res;
        res = SWIG_ConvertPtr(data, (void *)&(value->inst), SWIGTYPE_p__CMPIInstance, 0 |  0 );
	if (!SWIG_IsOK(res)) {
          SWIG_exception(SWIG_ValueError, "EmbeddedObject supports CMPI::Instance only");
        }
        else {
          type = CMPI_instance;
        }
      }
      break;
      case ((1)<<15): { /* cmpi-bindings-ruby: EmbeddedInstance */
        /* class or instance */
        int res;
        res = SWIG_ConvertPtr(data, (void *)&(value->inst), SWIGTYPE_p__CMPIInstance, 0 |  0 );
	if (!SWIG_IsOK(res)) {
          SWIG_exception(SWIG_ValueError, "EmbeddedInstance expects CMPI::Instance");
        }
        else {
          type = CMPI_instance;
        }
      }
      break;
      default: {
        static char msg[64];
        snprintf(msg, 63, "target_to_value unhandled type 0x%04x", type);
        SWIG_exception(SWIG_ValueError, msg);
      }
      break;
    } /* switch (type) */
  }
#if !defined (SWIGRUBY)
fail:
#endif
  return type;
#else
#error Undefined
#endif
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
 * Called by LogMessage and TraceMessage
 */

static void log_message(
    const CMPIBroker *broker,
    int severity, 
    const char *id, 
    const char *text) 
{
  CMPIStatus st = CMLogMessage(broker, severity, id, text, NULL);
  if (st.rc == CMPI_RC_ERR_NOT_SUPPORTED) {
    int priority = LOG_DAEMON;
    openlog("cmpi-bindings", LOG_CONS|LOG_PID, LOG_DAEMON);
    switch(severity) {
      case CMPI_SEV_ERROR:   priority |= LOG_ERR; break;
      case CMPI_SEV_INFO:    priority |= LOG_INFO; break;
      case CMPI_SEV_WARNING: priority |= LOG_WARNING; break;
      case CMPI_DEV_DEBUG:   priority |= LOG_DEBUG; break;
      default:               priority |= LOG_NOTICE;
    }
    syslog(priority, "%s: %s", id, text);
  }
  else {
    RAISE_IF(st);
  }
}


/*
**==============================================================================
**
** String array implementation functions.
**
**==============================================================================
*/

#include "string_array.h"

/*
 *==============================================================================
 * CMPISelectExp wrapper to capture also the projections
 *==============================================================================
 */

typedef struct select_filter_exp {
  CMPISelectExp *exp;
  char **filter;
} select_filter_exp;

static select_filter_exp *
create_select_filter_exp(const CMPIBroker* broker, const char *query, const char *language, char **keys)
{
  CMPIStatus st = {CMPI_RC_OK, NULL};
  CMPIArray *projection;
  select_filter_exp *sfe;
  CMPISelectExp *exp = CMNewSelectExp(broker, query, language, &projection, &st);
  RAISE_IF(st);
  sfe = (select_filter_exp *)calloc(1, sizeof(select_filter_exp));
  if (sfe == NULL) {
    SWIG_exception(SWIG_MemoryError, "malloc failed");
  }
  sfe->exp = exp;
  if (projection || keys) {
    size_t kcount = 0;
    int pcount = 0;
    int count = 0;
    if (keys) {
      kcount = string_array_size(keys);
    }
    if (projection) {
      pcount = CMGetArrayCount(projection, NULL);
    }
    count = pcount + kcount;
    if (count > 0) {
      int i = 0;
      sfe->filter = calloc(count + 1, sizeof(char **)); /* incl. final NULL ptr */
      for (; i < kcount; i++) {
        sfe->filter[i] = strdup(keys[i]);
      }
      for (; i < count; i++) {
        CMPIData data = CMGetArrayElementAt(projection, i-kcount, &st);
        if (st.rc != CMPI_RC_OK) {
          while(i) {
            free(sfe->filter[--i]);
          }
          free(sfe->filter);
          CMRelease(sfe->exp);
          free(sfe);
          sfe = NULL;            
          RAISE_IF(st);
          break;
        }
        sfe->filter[i] = (char *)strdup(CMGetCharsPtr(data.value.string, NULL));
        CMRelease(data.value.string);
      }
    }
    CMRelease(projection);
  }
#if !defined(SWIGRUBY)
fail:
#endif
  return sfe;
}

static void
release_select_filter_exp(select_filter_exp *sfe)
{
  CMRelease( sfe->exp );
  if (sfe->filter) {
    int i = 0;
    while (sfe->filter[i])
      free(sfe->filter[i++]);
    free(sfe->filter);
  }
  free(sfe);
}

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
