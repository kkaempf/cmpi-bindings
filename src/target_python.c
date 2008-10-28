/*
 * target_python.c
 *
 * Target language specific functions for cmpi_bindings
 *
 * Here: Python
 */


#include <Python.h>


static PyThreadState* cmpiMainPyThreadState = NULL; 

/*
 * get Python exception trace -> CMPIString
 * 
 */

#define TB_ERROR(str) {tbstr = str; goto cleanup;}
static CMPIString *
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
    TARGET_THREAD_BEGIN_BLOCK; 
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

    _SBLIM_TRACE(1,("%s", PyString_AsString(obstr))); 
    args = PyTuple_New(2);
    PyTuple_SetItem(args, 0, string2target("\n")); 
    PyTuple_SetItem(args, 1, string2target("<br>")); 
    
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


    TARGET_THREAD_END_BLOCK; 
    return rv;
}


/*
 * Global Python initializer
 * 
 * load the Python interpreter
 * import 'cmpi_pywbem_bindings' -> _TARGET_MODULE
 * init threads
 */

static int
PyGlobalInitialize(const CMPIBroker* broker, CMPIStatus* st)
{
/*  _SBLIM_TRACE(1,("<%d/0x%x> PyGlobalInitialize() called", getpid(), pthread_self())); */
  
  if (_TARGET_INIT)
    {
/*      _SBLIM_TRACE(1,("<%d/0x%x> PyGlobalInitialize() returning: already initialized", getpid(), pthread_self())); */
      return 0; 
    }
  _TARGET_INIT=1;//true
  
  _SBLIM_TRACE(1,("<%d/0x%x> Python: Loading", getpid(), pthread_self()));
  
  Py_SetProgramName("cmpi_swig");
  Py_Initialize();
  SWIGEXPORT void SWIG_init(void);
  SWIG_init();
  cmpiMainPyThreadState = PyGILState_GetThisThreadState();
  PyEval_ReleaseThread(cmpiMainPyThreadState); 
  
  TARGET_THREAD_BEGIN_BLOCK;
  
  /*
   * import 'cmpi_pywbem_bindings'
   */
  
  _TARGET_MODULE = PyImport_ImportModule("cmpi_pywbem_bindings");
  if (_TARGET_MODULE == NULL)
    {
      TARGET_THREAD_END_BLOCK; 
      _SBLIM_TRACE(1,("<%d/0x%x> Python: import cmpi_pywbem_bindings failed", getpid(), pthread_self()));
	  CMPIString* trace = get_exc_trace(broker);
      _SBLIM_TRACE(1,("<%d/0x%x> %s", getpid(), pthread_self(), 
				  CMGetCharsPtr(trace, NULL)));
      _CMPI_SETFAIL(trace); 
      abort();
      return -1; 
    }
  _SBLIM_TRACE(1,("<%d/0x%x> Python: _TARGET_MODULE at %p", getpid(), pthread_self(), _TARGET_MODULE));
  
  TARGET_THREAD_END_BLOCK; 
  _SBLIM_TRACE(1,("<%d/0x%x> PyGlobalInitialize() succeeded", getpid(), pthread_self())); 
  return 0; 
}


/*---------------------------------------------------------------*/

/*
 * TargetCall
 * 
 * ** must be called while holding the threads lock **
 */

static int 
TargetCall(ProviderMIHandle* hdl, CMPIStatus* st, 
                 const char* opname, int nargs, ...)
{
    int rc = 1; 
    va_list vargs; 
    PyObject *pyargs = NULL; 
    PyObject *pyfunc = NULL; 
    PyObject *prv = NULL; 
 
    pyargs = PyTuple_New(nargs); 
    pyfunc = PyObject_GetAttrString(hdl->instance, opname); 
    if (pyfunc == NULL)
    {
        PyErr_Print(); 
        PyErr_Clear(); 
        char* str = fmtstr("Python module does not contain \"%s\"", opname); 
        _SBLIM_TRACE(1,("%s", str)); 
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
        _SBLIM_TRACE(1,("%s", str)); 
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
        TARGET_THREAD_BEGIN_ALLOW;
        char* str = fmtstr("Python function \"%s\" didn't return a two-tuple",
                opname); 
        _SBLIM_TRACE(1,("%s", str)); 
        st->rc = CMPI_RC_ERR_FAILED; 
        st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
        free(str); 
        rc = 1; 
        TARGET_THREAD_END_ALLOW; 
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
        TARGET_THREAD_BEGIN_ALLOW;
        char* str = fmtstr("Python function \"%s\" didn't return a {<int>, <str>) two-tuple", opname); 
        _SBLIM_TRACE(1,("%s", str)); 
        st->rc = CMPI_RC_ERR_FAILED; 
        st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
        free(str); 
        rc = 1; 
        TARGET_THREAD_END_ALLOW; 
        goto cleanup; 
    }
    long pi = PyInt_AsLong(prc);
    st->rc = (CMPIrc)pi; 
    if (prstr == Py_None)
    {
        TARGET_THREAD_BEGIN_ALLOW;
        st->msg = hdl->broker->eft->newString(hdl->broker, "", NULL); 
        TARGET_THREAD_END_ALLOW; 
    }
    else
    {
        char *msg = PyString_AsString(prstr);
        TARGET_THREAD_BEGIN_ALLOW;
        st->msg = hdl->broker->eft->newString(hdl->broker, 
				msg, NULL); 
        TARGET_THREAD_END_ALLOW; 
    }
    rc = pi != 0; 
cleanup:
    Py_DecRef(pyargs);
    Py_DecRef(pyfunc);
    Py_DecRef(prv);
 
    return rc; 
}


/*
 * local (per MI) Python initializer
 * keeps track of reference count
 */

static int
TargetInitialize(ProviderMIHandle* hdl, CMPIStatus* st)
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
  /* import 'cmpi_pywbem_bindings' */
  rc = PyGlobalInitialize(hdl->broker, st); 
  pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
  if (rc != 0)
  {
      return rc; 
  }

  _SBLIM_TRACE(1,("<%d/0x%x> TargetInitialize(Python) called", getpid(), pthread_self()));
  
  TARGET_THREAD_BEGIN_BLOCK;
  
  /* cmpi_pywbem_bindings::get_cmpi_proxy_provider */
  PyObject *provclass = PyObject_GetAttrString(_TARGET_MODULE, 
                           "get_cmpi_proxy_provider"); 
  if (provclass == NULL)
    {
      TARGET_THREAD_END_BLOCK; 
      _CMPI_SETFAIL(get_exc_trace(hdl->broker)); 
      return -1; 
    }
  PyObject *broker = SWIG_NewPointerObj((void*) hdl->broker, SWIGTYPE_p__CMPIBroker, 0);
  PyObject *args = PyTuple_New(2); 
  _SBLIM_TRACE(1,("\n<%d/0x%x> >>>>> TargetInitialize(Python) called, MINAME=%s\n",
               getpid(), pthread_self(), hdl->miName));
  PyTuple_SetItem(args, 0, string2target(hdl->miName)); 
  PyTuple_SetItem(args, 1, broker); 
  
  /* provinst = cmpi_pywbem_bindings::get_cmpi_proxy_provider( miName, broker ) */
  PyObject *provinst = PyObject_CallObject(provclass, args); 
  Py_DecRef(args); 
  Py_DecRef(provclass); 
  if (provinst == NULL)
    {
      TARGET_THREAD_END_BLOCK; 
      _CMPI_SETFAIL(get_exc_trace(hdl->broker)); 
      return -1; 
    }
  /* save per-MI provider instance */
  hdl->instance = provinst; 
  
  TARGET_THREAD_END_BLOCK; 
  _SBLIM_TRACE(1,("<%d/0x%x> TargetInitialize(Python) succeeded", getpid(), pthread_self())); 
  return 0; 
}


/*
 * TargetCleanup
 */

static void
TargetCleanup(void)
{
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
        return;
    }
  
    TARGET_THREAD_BEGIN_BLOCK;
    Py_DecRef(_TARGET_MODULE); 
    TARGET_THREAD_END_BLOCK; 
  
    PyEval_AcquireLock(); 
    PyThreadState_Swap(cmpiMainPyThreadState); 
    if (_TARGET_INIT)  // if Python is initialized and _MI_COUNT == 0, call Py_Finalize
    {
        _SBLIM_TRACE(1,("Calling Py_Finalize()"));
        Py_Finalize();
        _TARGET_INIT=0; // false
    }
    pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
  
}
