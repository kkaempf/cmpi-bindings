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
%include "cmpidt.h"

#-----------------------------------------------------

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

%extend CMPIData {
  CMPIData(CMPIData *data)
  {
    return data_clone(data);
  }
  ~CMPIData()
  {
    free($self);
  }

#ifdef SWIGRUBY
  VALUE to_s()
  {
    Target_Type value = data_value($self);
    return rb_funcall(value, rb_intern("to_s"), 0);
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

%extend CMPIStatus {
  CMPIStatus()
  {
    CMPIStatus *status = (CMPIStatus *)calloc(1, sizeof(CMPIStatus));
    status->rc = CMPI_RC_OK;
    return status;
  }
  ~CMPIStatus()
  {
    free( $self );
  }
  int rc() { return $self->rc; }
  char *msg() { return (char *) ($self->msg->hdl); }
#if defined(SWIGRUBY)
  %rename("ok?") is_ok;
#endif
  int is_ok() { return $self->rc == CMPI_RC_OK; }
  const char* to_s(const CMPIBroker* broker) {
    CMPIString *s = CDToString(broker, $self, NULL);
    return CMGetCharPtr(s);
  }
}
