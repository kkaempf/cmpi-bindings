/*
 * target_ruby.c
 *
 * Target language specific functions for cmpi_bindings
 *
 * Here: Ruby
 */

/* load <RB_BINDINGS_FILE>.rb */
#define RB_BINDINGS_FILE "cmpi_rbwbem_bindings"

/* expect 'module <RB_BINDINGS_MODULE>' inside */
#define RB_BINDINGS_MODULE "RbCmpi"

/*
 * load_module
 * separate function for rb_require so it can be wrapped into rb_protect()
 */

static VALUE
load_module()
{
  _SBLIM_TRACE(1,("Ruby: require '%s'...", RB_BINDINGS_FILE));

  rb_require(RB_BINDINGS_FILE);
  
  _SBLIM_TRACE(1,("Ruby: ... done"));
  
  return Qnil;
}


/*
 * create_mi
 * call constructor for MI implementation class
 *
 * I args : pointer to array of 2 values
 *          values[0] = broker, passed to constructor
 *          values[1] = id of class (rb_intern(<classname>))
 */

static VALUE
create_mi(VALUE args)
{
  VALUE *values = (VALUE *)args;
  _SBLIM_TRACE(1,("Ruby: <MIclass>.new ..."));
  VALUE klass = rb_class_new_instance(1, values, rb_const_get(_TARGET_MODULE, values[1]));
  _SBLIM_TRACE(1,("Ruby: ... done"));
  return klass;
}


/*
 * Global Ruby initializer
 * loads the Ruby interpreter
 * init threads
 */

static int
RbGlobalInitialize(const CMPIBroker* broker, CMPIStatus* st)
{
  int error;

  _SBLIM_TRACE(1,("<%d> RbGlobalInitialize() called", getpid()));
  
  if (_TARGET_INIT)
    {
      _SBLIM_TRACE(1,("<%d> RbGlobalInitialize() returning: already initialized", getpid()));
      return 0; 
    }
  _TARGET_INIT=1;//true
  
  _SBLIM_TRACE(1,("<%d> Ruby: Loading", getpid()));
  
  ruby_init();
  ruby_init_loadpath();
  ruby_script("cmpi_swig");
  SWIG_init();

  /* load module */
  rb_protect(load_module, Qnil, &error);
  if (error)
    {
      _SBLIM_TRACE(1,("<%d> Ruby: import '%s' failed", getpid(), RB_BINDINGS_FILE));
/*      _CMPI_SETFAIL(<CMPIString *>); */ 
      abort();
      return -1; 
    }
  _TARGET_MODULE = rb_intern(RB_BINDINGS_MODULE);
  _SBLIM_TRACE(1,("<%d> RbGlobalInitialize() succeeded -> %ld", getpid(), _TARGET_MODULE)); 
  return 0; 
}


/*---------------------------------------------------------------*/

/*
 * local (per MI) Ruby initializer
 * keeps track of reference count
 */

static int
TargetInitialize(ProviderMIHandle* hdl, CMPIStatus* st)
{
  VALUE args[2];
  int error;

  /* Set _CMPI_INIT, protected by _CMPI_INIT_MUTEX
   * so we call ruby_finalize() only once.
   */
  if (pthread_mutex_lock(&_CMPI_INIT_MUTEX))
  {
      perror("Can't lock _CMPI_INIT_MUTEX");
      abort();
  }
  error = RbGlobalInitialize(hdl->broker, st); 
  pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
  if (error != 0)
  {
     goto exit;
  }

  _SBLIM_TRACE(1,("<%d> TargetInitialize(Ruby) called", getpid()));
  
  args[0] = SWIG_NewPointerObj((void*) hdl->broker, SWIGTYPE_p__CMPIBroker, 0);
  args[1] = rb_str_new2(hdl->miName);
  hdl->instance = rb_protect(create_mi, (VALUE)args, &error);
  if (error)
    {
      _SBLIM_TRACE(1,("Ruby: FAILED creating %s", hdl->miName));
      hdl->instance = Qnil;
      if (st != NULL)
	{
	  st->rc = CMPI_RC_ERR_FAILED;
	}
    }
  else
    {
      _SBLIM_TRACE(1,("Ruby: cmpi at %p", hdl->instance));
    }
exit:
  _SBLIM_TRACE(1,("Initialize() %s", (error == 0)? "succeeded":"failed"));
  return error;
}


/*
 * call_provider
 * 
 */

static int 
call_provider(ProviderMIHandle* hdl, CMPIStatus* st, 
                 const char* opname, int nargs, ...)
{
  return 0;
}


/*
 * TargetCleanup
 */

static void
TargetCleanup(void)
{
  ruby_finalize();
  _TARGET_MODULE = Qnil;   
  return;
}

