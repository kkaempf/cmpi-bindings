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
#define RB_BINDINGS_MODULE "Cmpi"

/*
 * load_module
 * separate function for rb_require so it can be wrapped into rb_protect()
 */

static VALUE
load_module()
{
  ruby_script(RB_BINDINGS_FILE);
  return rb_require(RB_BINDINGS_FILE);
}


/*
 * create_mi (called from rb_protect)
 * load Ruby provider and create provider instance
 *
 * I args : pointer to array of 2 values
 *          values[0] = classname (String)
 *          values[1] = broker, passed to constructor
 */

static VALUE
create_mi(VALUE args)
{
  VALUE *values = (VALUE *)args;

  _SBLIM_TRACE(1,("Ruby: %s.new ...", StringValuePtr(values[0])));
  return rb_funcall2(_TARGET_MODULE, rb_intern("create_provider"), 2, values);
}


/*
 * call_mi
 * call function of instance
 * 
 * I args: pointer to array of at least 3 values
 *         args[0] -> (VALUE) instance
 *         args[1] -> (VALUE) id of function
 *         args[2] -> (int) number of arguments
 *         args[3...n] -> (VALUE) arguments
 */

static VALUE
call_mi(VALUE args)
{
  VALUE *values = (VALUE *)args;
  return rb_funcall3(values[0], values[1], (int)values[2], values+3);
}



/*
 * get Ruby exception trace -> CMPIString
 * 
 */

#define TB_ERROR(str) {tbstr = str; goto cleanup;}
static CMPIString *
get_exc_trace(const CMPIBroker* broker)
{
    VALUE exception = rb_gv_get("$!"); /* get last exception */
    VALUE reason = rb_funcall(exception, rb_intern("to_s"), 0 );
    VALUE trace = rb_gv_get("$@"); /* get last exception trace */
    VALUE backtrace = rb_funcall(trace, rb_intern("join"), 1, rb_str_new("\n\t", 2));

    char* tmp = fmtstr("%s\n\t%s", StringValuePtr(reason), StringValuePtr(backtrace)); 
    return broker->eft->newString(broker, tmp, NULL); 
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

  if (_TARGET_INIT)
    {
      return 0; 
    }
  _TARGET_INIT=1;//true
  
  _SBLIM_TRACE(1,("<%d> Ruby: Loading", getpid()));
  
  ruby_init();
  ruby_init_loadpath();
  ruby_script("cmpi_swig_ruby");
  extern void SWIG_init();
  SWIG_init();

  /* load module */
  rb_protect(load_module, Qnil, &error);
  if (error)
    {
      CMPIString *trace = get_exc_trace(broker);

      _SBLIM_TRACE(1,("<%d> Ruby: import '%s' failed: %s", getpid(), RB_BINDINGS_FILE, CMGetCharPtr(trace)));
/*      _CMPI_SETFAIL(<CMPIString *>); */ 
      abort();
      return -1; 
    }
  _TARGET_MODULE = rb_const_get(rb_cModule, rb_intern(RB_BINDINGS_MODULE));
  if (NIL_P(_TARGET_MODULE))
    {
      _SBLIM_TRACE(1,("<%d> Ruby: import '%s' doesn't define module '%s'", getpid(), RB_BINDINGS_MODULE));
      st->rc = CMPI_RC_ERR_NOT_FOUND;
      return -1;
    }  
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

  _SBLIM_TRACE(1,("<%d> TargetInitialize(Ruby) called, miName '%s'", getpid(), hdl->miName));

  args[0] = rb_str_new2(hdl->miName);
  args[1] = SWIG_NewPointerObj((void*) hdl->broker, SWIGTYPE_p__CMPIBroker, 0);
  hdl->instance = rb_protect(create_mi, (VALUE)args, &error);
  if (error)
    {
      CMPIString *trace = get_exc_trace(hdl->broker);
      _SBLIM_TRACE(1,("Ruby: FAILED creating %s:", hdl->miName, CMGetCharPtr(trace)));
      if (st != NULL)
	{
	  st->rc = CMPI_RC_ERR_INVALID_CLASS;
	  st->msg = trace;
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
  int i; 
  VALUE *args, result, op = rb_intern(opname);
  va_list vargs; 

  /* add hdl->instance, op and nargs to the args array, so rb_protect can be called */
  nargs += 3;
  args = (VALUE *)malloc(nargs * sizeof(VALUE));
  if (args == NULL)
    {
      _SBLIM_TRACE(1,("Out of memory")); 
      abort();
    }
  args[0] = (VALUE)(hdl->instance);
  args[1] = op;
  args[2] = (VALUE)(nargs-3);
  if (nargs > 3)
    {
      va_start(vargs, nargs);
      for (i = 3; i < nargs; ++i)
	{
	  args[i] = va_arg(vargs, VALUE);
	}
      va_end(vargs);
    }


  result = rb_protect(call_mi, (VALUE)args, &i);

  free( args );

  if (i)
    {
      CMPIString *trace = get_exc_trace(hdl->broker);
      char* str = fmtstr("Ruby: calling '%s' failed: %s", opname, CMGetCharPtr(trace)); 
      _SBLIM_TRACE(1,("%s", str));
      st->rc = CMPI_RC_ERR_FAILED; 
      st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
      return 1;
    }

  st->rc = CMPI_RC_OK;
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

