# cmpi_defs.i
#
# swig bindings for CMPI constant definitions
#

%nodefault CMPIData;
#%ignore _CMPIData::type;
#%ignore _CMPIData::state;
#%ignore _CMPIData::value;
%rename(CMPIData) _CMPIData;

%nodefault CMPIStatus;
#%rename(CMPIStatus) _CMPIStatus;
%ignore _CMPIStatus::rc;
%ignore _CMPIStatus::msg;

#if defined(SWIGPERL)
/* Warning(314): 'ref' is a perl keyword */
%rename("reference") _CMPIValue::ref;
#endif
%include "cmpi/cmpidt.h"

#-----------------------------------------------------

#if defined(SWIGRUBY)
#
# Conversion from list of Ruby string array to null terminated char** array.
#
%typemap(in) char ** 
{
  if ($input == Qnil) {
    $1 = NULL;
  }
  else {
    int count, i;
    rb_check_type($input, T_ARRAY);
    count = RARRAY_LEN($input);
    $1 = (char **)calloc(count + 1, sizeof(char **)); /* incl. trailing NULL */
    if ($1 == NULL) {
      SWIG_exception(SWIG_MemoryError, "malloc failed");
    }
    for (i = 0; i < count; i++) {
      $1[i] = (char *)target_charptr(rb_ary_entry($input, i));
      if ($1[i] == NULL) {
        SWIG_exception(SWIG_MemoryError, "malloc failed");
      }
    }
    $1[i] = NULL;
  }
}

%typemap(out) char **
{
  if ($1 == NULL) {
    $result = Qnil;
  }
  else {
    size_t count = string_array_size($1);
    if (count == 0) {
      $result = rb_ary_new();
    }
    else {
      int i;
      $result = rb_ary_new2(count);
      for (i = 0; i < count; i++) {
        rb_ary_store($result, i, rb_str_new2($1[i]));
      }
    }
  }
}

%typemap(freearg) char ** 
{
  if ($1)
    free($1);
}
#endif

#if defined(SWIGPYTHON)
#
# Conversion from list of python strings to null terminated char** array.
#

%typemap(in) char ** 
{
  int size;
  int i;

  if ($input == Py_None)
  {
    $1 = NULL;
  }
  else
  {
      if (!PyList_Check($input))
      {
        PyErr_SetString(PyExc_TypeError, "expected list argument");
        return NULL;
      }

      size = PyList_Size($input);

      $1 = (char**)malloc(sizeof(char *) * (size+1));

      for (i = 0; i < size; i++) 
      {
        PyObject* obj = PyList_GetItem($input, i);

        if (PyString_Check(obj))
          $1[i] = PyString_AsString(PyList_GetItem($input,i));
        else 
        {
          PyErr_SetString(PyExc_TypeError,"list contains non-string");
          free($1);
          return NULL;
        }
      }

      $1[i] = 0;
    }
}

%typemap(freearg) char ** 
{
  if ($1)
    free($1);
}
#endif /* defined(SWIGPYTHON) */

#-----------------------------------------------------
#
# CMPIData
#

%extend _CMPIData {
/*
  type, state, value are created by SWIG via %include cmpidt above

*/
  _CMPIData(CMPIData *data)
  {
    return data_clone(data);
  }
  ~_CMPIData()
  {
    free($self);
  }

#ifdef SWIGRUBY
  VALUE to_s()
  {
    Target_Type value = data_value($self);
    return rb_funcall(value, rb_intern("to_s"), 0);
  }
  VALUE inspect()
  {
    Target_Type value = data_value($self);
    return rb_funcall(value, rb_intern("inspect"), 0);
  }
#endif

#if defined(SWIGRUBY)
  %rename("null?") is_null;
#endif

  int is_null()
  {
    return CMIsNullValue((*($self)));
  }
#if defined(SWIGRUBY)
  %rename("key?") is_key;
#endif
  int is_key()
  {
    return CMIsKeyValue((*($self)));
  }
#if defined(SWIGRUBY)
  %rename("array?") is_array;
#endif
  int is_array()
  {
    return CMIsArray((*($self)));
  }
#if defined(SWIGRUBY)
  VALUE
#endif
#if defined(SWIGPYTHON)
  PyObject *
#endif
#if defined(SWIGPERL)
  SV *
#endif
  _value()
  {
    return data_value($self);
  }
}


#-----------------------------------------------------
#
# CMPIStatus
#

%extend _CMPIStatus {
  _CMPIStatus()
  {
    CMPIStatus *status = (CMPIStatus *)calloc(1, sizeof(CMPIStatus));
    status->rc = CMPI_RC_OK;
    return status;
  }
  ~_CMPIStatus()
  {
    free( $self );
  }
  int rc() { return $self->rc; }
  char *msg() { return (char *) ($self->msg->hdl); }
#if defined(SWIGRUBY)
  %rename("ok?") is_ok;
#endif
  int is_ok() { return $self->rc == CMPI_RC_OK; }
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
  /*
   * add CMPIStatus.to_s in Python for backwards-compatibility
   *
   * DEPRECATED
   */
  %newobject to_s;
  const char* to_s(const CMPIBroker* broker) {
    CMPIString *s = CDToString(broker, $self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
#endif /* PYTHON */
  /* Return string representation */
  %newobject string;
  const char* string() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIString* s;
    const char *result;
    const CMPIBroker* broker = cmpi_broker();

    s = CDToString(broker, $self, &st);
    RAISE_IF(st);

    result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
#else /* no cmpi_broker() */
  %newobject to_s;
  const char* to_s(const CMPIBroker* broker) {
    CMPIString *s = CDToString(broker, $self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
#endif
}
