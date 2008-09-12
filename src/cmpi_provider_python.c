/*****************************************************************************
* Copyright (C) 2008 Novell Inc. All rights reserved.
* Copyright (C) 2008 SUSE Linux Products GmbH. All rights reserved.
* 
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
* 
*   - Redistributions of source code must retain the above copyright notice,
*     this list of conditions and the following disclaimer.
* 
*   - Redistributions in binary form must reproduce the above copyright notice,
*     this list of conditions and the following disclaimer in the documentation
*     and/or other materials provided with the distribution.
* 
*   - Neither the name of Novell Inc. nor of SUSE Linux Products GmbH nor the
*     names of its contributors may be used to endorse or promote products
*     derived from this software without specific prior written permission.
* 
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL Novell Inc. OR SUSE Linux Products GmbH OR
* THE CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
* OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
* OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*****************************************************************************/

#include <stdio.h>
#include <stdarg.h>
#include <pthread.h>

/* Include the required CMPI macros, data types, and API function headers */
#include <cmpidt.h>
#include <cmpift.h>
#include <cmpimacs.h>

// Needed to obtain errno of failed system calls
#include <errno.h>

/* Needed for kill() */
#include <signal.h>

#include <Python.h>

/* A simple stderr logging/tracing facility. */
#ifndef _SBLIM_TRACE
#define _SBLIM_TRACE(tracelevel,args) _logstderr args 
void _logstderr(char *fmt,...)
{
   va_list ap;
   va_start(ap,fmt);
   vfprintf(stderr,fmt,ap);
   va_end(ap);
   fprintf(stderr,"\n");
}
#endif

/*
**==============================================================================
**
** Local definitions:
**
**==============================================================================
*/

static pthread_mutex_t _CMPI_INIT_MUTEX = PTHREAD_MUTEX_INITIALIZER; 
static int _PY_INIT = 0; // acts as a boolean - is Python Initialized
static int _MI_COUNT = 0; 
static PyThreadState* cmpiMainPyThreadState = NULL; 
static PyObject* _PYPROVMOD = NULL; 


typedef struct __PyProviderMIHandle
{
    char *miName;
    PyObject *pyMod;
    const CMPIBroker* broker;
} PyProviderMIHandle;

static char* fmtstr(const char* fmt, ...)
{
    va_list ap; 
    int len; 
    va_start(ap, fmt); 
    len = vsnprintf(NULL, 0, fmt, ap); 
    va_end(ap); 
    if (len <= 0)
    {
        return NULL; 
    }
    char* str = (char*)malloc(len+1); 
    if (str == NULL)
    {
        return NULL; 
    }
    va_start(ap, fmt); 
    vsnprintf(str, len+1, fmt, ap); 
    va_end(ap); 
    return str; 
}


static PyObject *
string2py(const char *s)
{
    PyObject *obj;
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
 
    obj = PyString_FromString(s);
    SWIG_PYTHON_THREAD_END_BLOCK; 
 
    return obj;
}



#define TB_ERROR(str) {tbstr = str; goto cleanup;}
static CMPIString*
get_exc_trace(const CMPIBroker* broker)
{
    char *tbstr = NULL; 

    PyObject *iostrmod = NULL;
    PyObject *tbmod = NULL;
    PyObject *iostr = NULL;
    PyObject *obstr = NULL;
    PyObject *args = NULL;
    PyObject *newstr = NULL;
    PyObject *func = NULL;
    CMPIString* rv = NULL; 

    PyObject *type, *value, *traceback;
    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyErr_Fetch(&type, &value, &traceback);
    _SBLIM_TRACE(1,("** type %p, value %p, traceback %p", type, value, traceback)); 
    PyErr_Print(); 
    PyErr_Clear(); 
    PyErr_NormalizeException(&type, &value, &traceback);
    _SBLIM_TRACE(1,("** type %p, value %p, traceback %p", type, value, traceback)); 

    iostrmod = PyImport_ImportModule("StringIO");
    if (iostrmod==NULL)
        TB_ERROR("can't import StringIO");

    iostr = PyObject_CallMethod(iostrmod, "StringIO", NULL);

    if (iostr==NULL)
        TB_ERROR("cStringIO.StringIO() failed");

    tbmod = PyImport_ImportModule("traceback");
    if (tbmod==NULL)
        TB_ERROR("can't import traceback");

    obstr = PyObject_CallMethod(tbmod, "print_exception",
        "(OOOOO)",
        type ? type : Py_None, 
        value ? value : Py_None,
        traceback ? traceback : Py_None,
        Py_None,
        iostr);

    if (obstr==NULL) 
    {
        PyErr_Print(); 
        TB_ERROR("traceback.print_exception() failed");
    }

    Py_DecRef(obstr);

    obstr = PyObject_CallMethod(iostr, "getvalue", NULL);
    if (obstr==NULL) 
        TB_ERROR("getvalue() failed.");

    if (!PyString_Check(obstr))
        TB_ERROR("getvalue() did not return a string");

    args = PyTuple_New(2);
    PyTuple_SetItem(args, 0, string2py("\n")); 
    PyTuple_SetItem(args, 1, string2py("<br>")); 
    
    func = PyObject_GetAttrString(obstr, "replace"); 
    //newstr = PyObject_CallMethod(obstr, "replace", args); 
    newstr = PyObject_CallObject(func, args); 

    tbstr = PyString_AsString(newstr); 

    char* tmp = fmtstr("cmpi:%s", tbstr); 
    rv = broker->eft->newString(broker, tmp, NULL); 
    free(tmp); 

cleanup:
    PyErr_Restore(type, value, traceback);

    if (rv == NULL)
    {
        rv = broker->eft->newString(broker, tbstr ? tbstr : "", NULL);    
    }

    Py_DecRef(func);
    Py_DecRef(args);
    Py_DecRef(newstr);
    Py_DecRef(iostr);
    Py_DecRef(obstr);
    Py_DecRef(iostrmod);
    Py_DecRef(tbmod);


    SWIG_PYTHON_THREAD_END_BLOCK; 
    return rv;
}


SWIGEXPORT void SWIG_init(void);
#define PY_CMPI_SETFAIL(msgstr) {if (st != NULL) st->rc = CMPI_RC_ERR_FAILED; st->msg = msgstr; }
static int PyGlobalInitialize(const CMPIBroker* broker, CMPIStatus* st)
{
  int rc = 0; 

  _SBLIM_TRACE(1,("<%d/0x%x> PyGlobalInitialize() called", getpid(), pthread_self()));
  
  if (_PY_INIT)
    {
      _SBLIM_TRACE(1,("<%d/0x%x> PyGlobalInitialize() returning: already initialized", getpid(), pthread_self()));
      return 0; 
    }
  _PY_INIT=1;//true
  
  _SBLIM_TRACE(1,("<%d/0x%x> Python: Loading", getpid(), pthread_self()));
  
  Py_SetProgramName("cmpi_swig");
  Py_Initialize();
  SWIG_init();
  cmpiMainPyThreadState = PyGILState_GetThisThreadState();
  PyEval_ReleaseThread(cmpiMainPyThreadState); 
  
  SWIG_PYTHON_THREAD_BEGIN_BLOCK;
  _PYPROVMOD = PyImport_ImportModule("cmpi_bindings");
  if (_PYPROVMOD == NULL)
    {
      SWIG_PYTHON_THREAD_END_BLOCK; 
      _SBLIM_TRACE(1,("<%d/0x%x> Python: import cmpi_bindings failed", getpid(), pthread_self()));
      PY_CMPI_SETFAIL(get_exc_trace(broker)); 
      abort();
      return -1; 
    }
  _SBLIM_TRACE(1,("<%d/0x%x> Python: _PYPROVMOD at %p", getpid(), pthread_self(), _PYPROVMOD));
  
  SWIG_PYTHON_THREAD_END_BLOCK; 
  _SBLIM_TRACE(1,("<%d/0x%x> PyGlobalInitialize() succeeded", getpid(), pthread_self())); 
  return 0; 
}


static int PyInitialize(PyProviderMIHandle* hdl, CMPIStatus* st)
{
  int rc = 0; 
  /* Set _CMPI_INIT, protected by _CMPI_INIT_MUTEX
   * so we call Py_Finalize() only once.
   */
  if (pthread_mutex_lock(&_CMPI_INIT_MUTEX))
  {
      perror("Can't lock _CMPI_INIT_MUTEX");
      abort();
  }
  rc = PyGlobalInitialize(hdl->broker, st); 
  pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
  if (rc != 0)
  {
      return rc; 
  }

  _SBLIM_TRACE(1,("<%d/0x%x> PyInitialize() called", getpid(), pthread_self()));
  
  SWIG_PYTHON_THREAD_BEGIN_BLOCK;
  PyObject* provclass = PyObject_GetAttrString(_PYPROVMOD, 
                           "CMPIProvider"); 
  if (provclass == NULL)
    {
      SWIG_PYTHON_THREAD_END_BLOCK; 
      PY_CMPI_SETFAIL(get_exc_trace(hdl->broker)); 
      return -1; 
    }
  PyObject* broker = SWIG_NewPointerObj((void*) hdl->broker, SWIGTYPE_p__CMPIBroker, 0);
  PyObject* args = PyTuple_New(2); 
  _SBLIM_TRACE(1,("\n<%d/0x%x> >>>>> PyInitialize(Python) called, MINAME=%s\n",
               getpid(), pthread_self(), hdl->miName));
  PyTuple_SetItem(args, 0, string2py(hdl->miName)); 
  PyTuple_SetItem(args, 1, broker); 
  PyObject* provinst = PyObject_CallObject(provclass, args); 
  Py_DecRef(args); 
  Py_DecRef(provclass); 
  if (provinst == NULL)
    {
      SWIG_PYTHON_THREAD_END_BLOCK; 
      PY_CMPI_SETFAIL(get_exc_trace(hdl->broker)); 
      return -1; 
    }
  
  hdl->pyMod = provinst; 
  
  SWIG_PYTHON_THREAD_END_BLOCK; 
  _SBLIM_TRACE(1,("<%d/0x%x> PyInitialize() succeeded", getpid(), pthread_self())); 
  return 0; 
}


#define PY_CMPI_INIT { if (((PyProviderMIHandle*)(self->hdl))->pyMod == NULL) if (PyInitialize(((PyProviderMIHandle*)(self->hdl)), &status) != 0) return status; }

static PyObject*
proplist2py(const char** cplist)
{
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    if (cplist == NULL)
    {
        Py_INCREF(Py_None);
        SWIG_PYTHON_THREAD_END_BLOCK; 
        return Py_None; 
    }
    PyObject* pl;
 
    pl = PyList_New(0); 
    for (; *cplist != NULL; ++cplist)
    {
    PyList_Append(pl, PyString_FromString(*cplist)); 
    }
    SWIG_PYTHON_THREAD_END_BLOCK; 
 
    return pl; 
}


static int 
call_py_provider(PyProviderMIHandle* hdl, CMPIStatus* st, 
                 const char* opname, int nargs, ...)
{
    int rc = 1; 
    va_list vargs; 
    PyObject *pyargs = NULL; 
    PyObject *pyfunc = NULL; 
    PyObject *prv = NULL; 
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
 
    pyargs = PyTuple_New(nargs); 
    pyfunc = PyObject_GetAttrString(hdl->pyMod, opname); 
    if (pyfunc == NULL)
    {
        PyErr_Print(); 
        PyErr_Clear(); 
        char* str = fmtstr("Python module does not contain \"%s\"", opname); 
        _SBLIM_TRACE(1,(str)); 
        st->rc = CMPI_RC_ERR_FAILED; 
        st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
        free(str); 
        rc = 1; 
        goto cleanup; 
    }
    if (! PyCallable_Check(pyfunc))
    {
        char* str = fmtstr("Python module attribute \"%s\" is not callable", 
                opname); 
        _SBLIM_TRACE(1,(str)); 
        st->rc = CMPI_RC_ERR_FAILED; 
        st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
        free(str); 
        rc = 1; 
        goto cleanup; 
    }
    
    va_start(vargs, nargs); 
    int i; 
    for (i = 0; i < nargs; ++i)
    {
        PyObject* arg = va_arg(vargs, PyObject*); 
        if (arg == NULL)
        {
            arg = Py_None; 
            Py_IncRef(arg); 
        }
        PyTuple_SET_ITEM(pyargs, i, arg); 
    }
    va_end(vargs); 
    prv = PyObject_CallObject(pyfunc, pyargs);
    if (PyErr_Occurred())
    {
        st->rc = CMPI_RC_ERR_FAILED; 
        st->msg = get_exc_trace(hdl->broker); 
        PyErr_Clear(); 
        rc = 1; 
        goto cleanup; 
    }

    if (! PyTuple_Check(prv) || 
            (PyTuple_Size(prv) != 2 && PyTuple_Size(prv) != 1))
    {
        SWIG_PYTHON_THREAD_BEGIN_ALLOW;
        char* str = fmtstr("Python function \"%s\" didn't return a two-tuple",
                opname); 
        _SBLIM_TRACE(1,(str)); 
        st->rc = CMPI_RC_ERR_FAILED; 
        st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
        free(str); 
        rc = 1; 
        SWIG_PYTHON_THREAD_END_ALLOW; 
        goto cleanup; 
    }
    PyObject* prc = PyTuple_GetItem(prv, 0); 
    PyObject* prstr = Py_None; 
    if (PyTuple_Size(prv) == 2)
    {
        prstr = PyTuple_GetItem(prv, 1); 
    }

    if (! PyInt_Check(prc) || (! PyString_Check(prstr) && prstr != Py_None))
    {
        SWIG_PYTHON_THREAD_BEGIN_ALLOW;
        char* str = fmtstr("Python function \"%s\" didn't return a {<int>, <str>) two-tuple", opname); 
        _SBLIM_TRACE(1,(str)); 
        st->rc = CMPI_RC_ERR_FAILED; 
        st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
        free(str); 
        rc = 1; 
        SWIG_PYTHON_THREAD_END_ALLOW; 
        goto cleanup; 
    }
    long pi = PyInt_AsLong(prc);
    st->rc = (CMPIrc)pi; 
    if (prstr == Py_None)
    {
        SWIG_PYTHON_THREAD_BEGIN_ALLOW;
        st->msg = hdl->broker->eft->newString(hdl->broker, "", NULL); 
        SWIG_PYTHON_THREAD_END_ALLOW; 
    }
    else
    {
        st->msg = hdl->broker->eft->newString(hdl->broker, 
				PyString_AsString(prstr), NULL); 
    }
    rc = pi != 0; 
cleanup:
    Py_DecRef(pyargs);
    Py_DecRef(pyfunc);
    Py_DecRef(prv);
    SWIG_PYTHON_THREAD_END_BLOCK; 
 
    return rc; 
}



static CMPIStatus Cleanup(
        PyProviderMIHandle * miHdl,
        const CMPIContext * context,
        CMPIBoolean terminating)    
{
    CMPIStatus status = {CMPI_RC_OK, NULL}; /* Return status of CIM operations. */
  
    if (miHdl != NULL) 
    { 
        free(miHdl->miName); 
     
        // we must free the miHdl - it is our PyProviderMIHandle.
        // it is pointed to by the CMPI<type>MI * that the broker holds onto...
        // the broker is responsible for freeing the CMPI<type>MI*  
        free(miHdl);
        miHdl = NULL; 
    }
  
    /* Decrement _MI_COUNT, protected by _CMPI_INIT_MUTEX
     * call Py_Finalize when _MI_COUNT drops to zero
     */
    if (pthread_mutex_lock(&_CMPI_INIT_MUTEX))
    {
        perror("Can't lock _CMPI_INIT_MUTEX");
        abort();
    }
    if (--_MI_COUNT > 0) 
    {
        pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
        return status;
    }
  
    SWIG_PYTHON_THREAD_BEGIN_BLOCK;
    Py_DecRef(_PYPROVMOD); 
    SWIG_PYTHON_THREAD_END_BLOCK; 
  
    PyEval_AcquireLock(); 
    PyThreadState_Swap(cmpiMainPyThreadState); 
    if (_PY_INIT)  // if PY is initialized and _MI_COUNT == 0, call Py_Finalize
    {
        _SBLIM_TRACE(1,("Calling Py_Finalize()"));
        Py_Finalize();
        _PY_INIT=0; // false
    }
    pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
  
    /* Finished. */
exit:
    _SBLIM_TRACE(1,("Cleanup() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/*
**==============================================================================
**
** Provider Interface functions
**
**==============================================================================
*/

static CMPIStatus InstCleanup(
        CMPIInstanceMI * self,      
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    _SBLIM_TRACE(1,("Cleanup(Python) called for Instance provider %s", ((PyProviderMIHandle *)self->hdl)->miName));
    CMPIStatus st = Cleanup((PyProviderMIHandle*)self->hdl, context, terminating); 
    return st;
}

static CMPIStatus AssocCleanup(
        CMPIAssociationMI * self,   
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    _SBLIM_TRACE(1,("Cleanup(Python) called for Association provider %s", ((PyProviderMIHandle *)self->hdl)->miName));
    CMPIStatus st = Cleanup((PyProviderMIHandle*)self->hdl, context, terminating); 
    return st;
}

static CMPIStatus MethodCleanup(
        CMPIMethodMI * self,    
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    _SBLIM_TRACE(1,("Cleanup(Python) called for Method provider %s", ((PyProviderMIHandle *)self->hdl)->miName));
    CMPIStatus st = Cleanup((PyProviderMIHandle*)self->hdl, context, terminating); 
    return st;
}

static CMPIStatus IndicationCleanup(
        CMPIIndicationMI * self,    
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    _SBLIM_TRACE(1,("Cleanup(Python) called for Indication provider %s", ((PyProviderMIHandle *)self->hdl)->miName));
    CMPIStatus st = Cleanup((PyProviderMIHandle*)self->hdl, context, terminating); 
    return st;
}

// ----------------------------------------------------------------------------


/* EnumInstanceNames() - return a list of all the instances names (i.e. return their object paths only) */
static CMPIStatus EnumInstanceNames(
        CMPIInstanceMI * self,      
        const CMPIContext * context,
        const CMPIResult * result,
        const CMPIObjectPath * reference)
{
    CMPIStatus status = {CMPI_RC_OK, NULL};
    _SBLIM_TRACE(1,("EnumInstanceNames() called"));

    _SBLIM_TRACE(1,("EnumInstancesNames(Python) called, context %p, result %p, reference %p", context, result, reference));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pycontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyresult = SWIG_NewPointerObj((void*) result, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "enum_instance_names", 3, 
                                                        pycontext,
                                                        pyresult,
                                                        pyreference); 

exit:
   _SBLIM_TRACE(1,("EnumInstanceNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------


/* EnumInstances() - return a list of all the instances (i.e. return all the instance data) */
static CMPIStatus EnumInstances(
        CMPIInstanceMI * self,  
        const CMPIContext * context,
        const CMPIResult * result,
        const CMPIObjectPath * reference,
        const char ** properties)
{
    CMPIStatus status = {CMPI_RC_OK, NULL};  /* Return status of CIM operations */
    /*   char * namespace = CMGetCharPtr(CMGetNameSpace(reference, NULL));  Our current CIM namespace */

    _SBLIM_TRACE(1,("EnumInstances(Python) called, context %p, result %p, reference %p, properties %p", context, result, reference, properties));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pycontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyresult = SWIG_NewPointerObj((void*) result, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pyproperties = proplist2py(properties); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "enum_instances", 4, 
                                                               pycontext,
                                                               pyresult, 
                                                               pyreference,
                                                               pyproperties); 

exit:
   _SBLIM_TRACE(1,("EnumInstances() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------


/* GetInstance() -  return the instance data for the specified instance only */
static CMPIStatus GetInstance(
        CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results,
        const CMPIObjectPath * reference,
        const char ** properties)
{
    CMPIStatus status = {CMPI_RC_OK, NULL};  /* Return status of CIM operations */

    _SBLIM_TRACE(1,("GetInstance(Python) called, context %p, results %p, reference %p, properties %p", context, results, reference, properties));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pycontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyresult = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pyproperties = proplist2py(properties); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "get_instance", 4, 
                                                               pycontext,
                                                               pyresult, 
                                                               pyreference,
                                                               pyproperties); 

exit:
   _SBLIM_TRACE(1,("GetInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------


/* CreateInstance() - create a new instance from the specified instance data. */
static CMPIStatus CreateInstance(
        CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results,
        const CMPIObjectPath * reference,
        const CMPIInstance * newinstance)
{
   CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};   /* Return status of CIM operations. */
   
   /* Creating new instances is not supported for this class. */
  
    _SBLIM_TRACE(1,("CreateInstance(Python) called, context %p, results %p, reference %p, newinstance %p", context, results, reference, newinstance));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pycontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyresult = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    PyObject *pynewinst = SWIG_NewPointerObj((void*) newinstance, SWIGTYPE_p__CMPIInstance, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "create_instance", 4, 
                                                               pycontext,
                                                               pyresult, 
                                                               pyreference,
                                                               pynewinst); 

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("CreateInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------

#ifdef CMPI_VER_100
#define SetInstance ModifyInstance
#endif

/* SetInstance() - save modified instance data for the specified instance. */
static CMPIStatus SetInstance(
        CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results, 
        const CMPIObjectPath * reference,
        const CMPIInstance * newinstance,
        const char ** properties)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};   /* Return status of CIM operations. */
   
   /* Modifying existing instances is not supported for this class. */
 
    _SBLIM_TRACE(1,("SetInstance(Python) called, context %p, results %p, reference %p, newinstance %p, properties %p", context, results, reference, newinstance, properties));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pycontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyresult = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    PyObject *pynewinst = SWIG_NewPointerObj((void*) newinstance, SWIGTYPE_p__CMPIInstance, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *plist = proplist2py(properties); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "set_instance", 5, 
                                                               pycontext,
                                                               pyresult, 
                                                               pyreference,
                                                               pynewinst,
                                                               plist); 
  
   /* Finished. */
exit:
   _SBLIM_TRACE(1,("SetInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

// ----------------------------------------------------------------------------


/* DeleteInstance() - delete/remove the specified instance. */
static CMPIStatus DeleteInstance(
        CMPIInstanceMI * self,  
        const CMPIContext * context,
        const CMPIResult * results, 
        const CMPIObjectPath * reference)
{
    CMPIStatus status = {CMPI_RC_OK, NULL};  

    _SBLIM_TRACE(1,("DeleteInstance(Python) called, context %p, results %p, reference %p", context, results, reference));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pycontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyresult = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "delete_instance", 3, 
                                                               pycontext,
                                                               pyresult, 
                                                               pyreference); 
  
   /* Finished. */
exit:
   _SBLIM_TRACE(1,("DeleteInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

// ----------------------------------------------------------------------------


/* ExecQuery() - return a list of all the instances that satisfy the desired query filter. */
static CMPIStatus ExecQuery(
        CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results,
        const CMPIObjectPath * reference,
        const char * query,
        const char * language)  
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};   /* Return status of CIM operations. */
   
    _SBLIM_TRACE(1,("ExecQuery(Python) called, context %p, results %p, reference %p, query %s, language %s", context, results, reference, query, language));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pycontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyresult = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pyquery = string2py(query); 
    PyObject *pylang = string2py(language); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "exec_query", 5, 
                                                               pycontext,
                                                               pyresult, 
                                                               pyreference,
                                                               pyquery,
                                                               pylang); 

   /* Query filtering is not supported for this class. */

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("ExecQuery() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------

//  associatorMIFT
//

CMPIStatus associatorNames(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* assocClass,
        const char* resultClass,
        const char* role,
        const char* resultRole)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("associatorNames(Python) called, ctx %p, rslt %p, objName %p, assocClass %s, resultClass %s, role %s, resultRole %s", ctx, rslt, objName, assocClass, resultClass, role, resultRole));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyrslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyobjName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pyassocClass = NULL; 
    PyObject *pyresultClass = NULL; 
    PyObject* pyrole = NULL; 
    PyObject* pyresultRole = NULL; 
    if (assocClass != NULL)
    {
        pyassocClass = string2py(assocClass); 
    }
    if (resultClass != NULL)
    {
        pyresultClass = string2py(resultClass); 
    }
    if (role != NULL) 
    { 
        pyrole = string2py(role); 
    }
    if (resultRole != NULL) 
    { 
        pyresultRole = string2py(resultRole); 
    }

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "associator_names", 7, 
                                                               pyctx,
                                                               pyrslt, 
                                                               pyobjName,
                                                               pyassocClass,
                                                               pyresultClass,
                                                               pyrole,
                                                               pyresultRole); 

   /* Query filtering is not supported for this class. */

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("associatorNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

/***************************************************************************/
CMPIStatus associators(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* assocClass,
        const char* resultClass,
        const char* role,
        const char* resultRole,
        const char** properties)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("associators(Python) called, ctx %p, rslt %p, objName %p, assocClass %s, resultClass %s, role %s, resultRole %s", ctx, rslt, objName, assocClass, resultClass, role, resultRole));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyrslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyobjName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pyprops = proplist2py(properties); 
    PyObject *pyassocClass = NULL; 
    PyObject *pyresultClass = NULL; 
    PyObject* pyrole = NULL; 
    PyObject* pyresultRole = NULL; 
    if (assocClass != NULL)
    {
        pyassocClass = string2py(assocClass); 
    }
    if (resultClass != NULL)
    {
        pyresultClass = string2py(resultClass); 
    }
    if (role != NULL) 
    { 
        pyrole = string2py(role); 
    }
    if (resultRole != NULL) 
    { 
        pyresultRole = string2py(resultRole); 
    }

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "associators", 8, 
                                                               pyctx,
                                                               pyrslt, 
                                                               pyobjName,
                                                               pyassocClass,
                                                               pyresultClass,
                                                               pyrole,
                                                               pyresultRole,
                                                               pyprops); 

   /* Query filtering is not supported for this class. */

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("associators() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

/***************************************************************************/
CMPIStatus referenceNames(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* resultClass,
        const char* role)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("referenceNames(Python) called, ctx %p, rslt %p, objName %p, resultClass %s, role %s", ctx, rslt, objName, resultClass, role));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyrslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyobjName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject* pyresultClass = NULL; 
    PyObject* pyrole = NULL; 
    if (role != NULL) 
    { 
        pyrole = string2py(role); 
    }
    if (resultClass != NULL) 
    { 
        pyresultClass = string2py(resultClass); 
    }

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "reference_names", 5,
                                                               pyctx,
                                                               pyrslt, 
                                                               pyobjName,
                                                               pyresultClass,
                                                               pyrole); 

   /* Query filtering is not supported for this class. */

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("referenceNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/***************************************************************************/
CMPIStatus references(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* resultClass,
        const char* role,
        const char** properties)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("references(Python) called, ctx %p, rslt %p, objName %p, resultClass %s, role %s, properties %p", ctx, rslt, objName, resultClass, role, properties));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyrslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyobjName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject* pyrole = NULL; 
    PyObject* pyresultClass = NULL; 
    if (role != NULL) 
    { 
        pyrole = string2py(role); 
    }
    if (resultClass != NULL) 
    { 
        pyresultClass = string2py(resultClass); 
    }
    PyObject *pyprops = proplist2py(properties); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "references", 6, 
                                                               pyctx,
                                                               pyrslt, 
                                                               pyobjName,
                                                               pyresultClass,
                                                               pyrole,
                                                               pyprops); 

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("references() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

/***************************************************************************/
CMPIStatus invokeMethod(
        CMPIMethodMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* method,
        const CMPIArgs* in,
        CMPIArgs* out)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("invokeMethod(Python) called, ctx %p, rslt %p, objName %p, method %s, in %p, out %p", ctx, rslt, objName, method, in, out));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyrslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyobjName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    PyObject *pyin = SWIG_NewPointerObj((void*) in, SWIGTYPE_p__CMPIArgs, 0);
    PyObject *pyout = SWIG_NewPointerObj((void*) out, SWIGTYPE_p__CMPIArgs, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pymethod = string2py(method); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "invoke_method", 6, 
                                                               pyctx,
                                                               pyrslt, 
                                                               pyobjName,
                                                               pymethod,
                                                               pyin,
                                                               pyout); 

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("invokeMethod() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

/***************************************************************************/
CMPIStatus authorizeFilter(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath,
        const char* owner)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("authorizeFilter(Python) called, ctx %p, filter %p, className %s, classPath %p, owner %s", ctx, filter, className, classPath, owner)); 

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyfilter = SWIG_NewPointerObj((void*) filter, SWIGTYPE_p__CMPISelectExp, 0);
    PyObject *pyclassPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pyclassName = string2py(className); 
    PyObject *pyowner = string2py(owner); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "authorize_filter", 5, 
                                                               pyctx,
                                                               pyfilter, 
                                                               pyclassName,
                                                               pyclassPath,
                                                               pyowner);

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("authorizeFilter() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

/***************************************************************************/
CMPIStatus activateFilter(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath,
        CMPIBoolean firstActivation)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("activateFilter(Python) called, ctx %p, filter %p, className %s, classPath %p, firstActivation %d", ctx, filter, className, classPath, firstActivation));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyfilter = SWIG_NewPointerObj((void*) filter, SWIGTYPE_p__CMPISelectExp, 0);
    PyObject *pyclassPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    PyObject *pyfirstActivation = PyBool_FromLong(firstActivation); 
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pyclassName = string2py(className); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "activate_filter", 5, 
                                                               pyctx,
                                                               pyfilter, 
                                                               pyclassName,
                                                               pyclassPath,
                                                               pyfirstActivation);

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("activateFilter() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

/***************************************************************************/
CMPIStatus deActivateFilter(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath,
        CMPIBoolean lastActivation)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("deActivateFilter(Python) called, ctx %p, filter %p, className %s, classPath %p, lastActivation %d", ctx, filter, className, classPath, lastActivation));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    PyObject *pyfilter = SWIG_NewPointerObj((void*) filter, SWIGTYPE_p__CMPISelectExp, 0);
    PyObject *pyclassPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    PyObject *pylastActivation = PyBool_FromLong(lastActivation); 
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pyclassName = string2py(className); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "deactivate_filter", 5, 
                                                               pyctx,
                                                               pyfilter, 
                                                               pyclassName,
                                                               pyclassPath,
                                                               pylastActivation);

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("deActivateFilter() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/***************************************************************************/
// Note: sfcb doesn't support mustPoll. :(
// http://sourceforge.net/mailarchive/message.php?msg_id=OFF38FF3F9.39FD2E1F-ONC1257385.004A7122-C1257385.004BB0AF%40de.ibm.com
CMPIStatus mustPoll(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        //const CMPIResult* rslt, TODO: figure out who is right: spec. vs. sblim
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    //_SBLIM_TRACE(1,("mustPoll(Python) called, ctx %p, rslt %p, filter %p, className %s, classPath %p", ctx, rslt, filter, className, classPath));
    _SBLIM_TRACE(1,("mustPoll(Python) called, ctx %p, filter %p, className %s, classPath %p", ctx, filter, className, classPath));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    //PyObject *pyrslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    PyObject *pyfilter = SWIG_NewPointerObj((void*) filter, SWIGTYPE_p__CMPISelectExp, 0);
    PyObject *pyclassPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 
    PyObject *pyclassName = string2py(className); 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "must_poll", 4, 
                                                               pyctx,
                                                               //pyrslt,
                                                               pyfilter, 
                                                               pyclassName,
                                                               pyclassPath);

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("mustPoll() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


/***************************************************************************/
CMPIStatus enableIndications(
        CMPIIndicationMI* self,
        const CMPIContext* ctx)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("enableIndications(Python) called, ctx %p", ctx));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "enable_indications", 1, pyctx); 

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("enableIndications() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;

}

/***************************************************************************/
CMPIStatus disableIndications(
        CMPIIndicationMI* self,
        const CMPIContext* ctx)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("disableIndications(Python) called, ctx %p", ctx));

    PY_CMPI_INIT

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject *pyctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    SWIG_PYTHON_THREAD_END_BLOCK; 

    call_py_provider((PyProviderMIHandle*)self->hdl, &status, "disable_indications", 1, pyctx); 

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("disableIndications() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;

}


/***************************************************************************/


static CMPIMethodMIFT MethodMIFT__={ 
    CMPICurrentVersion, 
    CMPICurrentVersion, 
    "methodCmpi_Swig",  // miName
    MethodCleanup, 
    invokeMethod, 
}; 


static CMPIIndicationMIFT IndicationMIFT__={ 
    CMPICurrentVersion, 
    CMPICurrentVersion, 
    "indicationCmpi_Swig",  // miName
    IndicationCleanup, 
    authorizeFilter, 
    mustPoll, 
    activateFilter, 
    deActivateFilter, 
    enableIndications, 
    disableIndications, 
}; 


static CMPIAssociationMIFT AssociationMIFT__={ 
    CMPICurrentVersion, 
    CMPICurrentVersion, 
    "instanceCmpi_Swig",  // miName
    AssocCleanup, 
    associators, 
    associatorNames, 
    references, 
    referenceNames, 
}; 


static CMPIInstanceMIFT InstanceMIFT__={ 
    CMPICurrentVersion, 
    CMPICurrentVersion, 
    "associatorCmpi_Swig",  // miName
    InstCleanup, 
    EnumInstanceNames, 
    EnumInstances, 
    GetInstance, 
    CreateInstance, 
    SetInstance, 
    DeleteInstance, 
    ExecQuery, 
}; 

static void createInit(const CMPIBroker* broker, 
        const CMPIContext* context, const char* miname, CMPIStatus* st)
{
    _SBLIM_TRACE(1,("\n>>>>> createInit(Python) called, miname= %s (ctx=%p)\n", miname, context));
  
   /*
    * We can't initialize Python here and load Python modules, because
    * SFCB passes a NULL CMPIStatus* st, which means we can't report 
    * back error strings.  Instead, we'll check and initialize in each
    * MIFT function
    */ 
}

#define SWIG_CMPI_MI_FACTORY(ptype) \
CMPI##ptype##MI* _Generic_Create_##ptype##MI(const CMPIBroker* broker, \
        const CMPIContext* context, const char* miname, CMPIStatus* st)\
{ \
    /*_SBLIM_TRACE(1, ("\n>>>>> in FACTORY: CMPI"#ptype"MI* _Generic_Create_"#ptype"MI... miname=%s", miname));*/ \
    PyProviderMIHandle *hdl = (PyProviderMIHandle*)malloc(sizeof(PyProviderMIHandle)); \
    if (hdl) { \
        hdl->pyMod = NULL; \
        hdl->miName = strdup(miname); \
        hdl->broker = broker; \
    } \
    CMPI##ptype##MI *mi= (CMPI##ptype##MI*)malloc(sizeof(CMPI##ptype##MI)); \
    if (mi) { \
        mi->hdl = hdl; \
        mi->ft = &ptype##MIFT__; \
    } \
    createInit(broker, context, miname, st); \
    /*_SBLIM_TRACE(1, ("\n>>>>>     returning mi=0x%08x  mi->hdl=0x%08x   mi->ft=0x%08x", mi, mi->hdl, mi->ft));*/ \
    ++_MI_COUNT; \
    return mi; \
}

SWIG_CMPI_MI_FACTORY(Instance)
SWIG_CMPI_MI_FACTORY(Method)
SWIG_CMPI_MI_FACTORY(Association)
SWIG_CMPI_MI_FACTORY(Indication)
