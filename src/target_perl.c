/*
 * target_perl.c
 *
 * Target language specific functions for cmpi_bindings
 *
 * Here: Perl
 */

/* load <RB_BINDINGS_FILE>.pl */
#define PL_BINDINGS_FILE "cmpi_plwbem_bindings"

/* expect 'module <PL_BINDINGS_MODULE>' inside */
#define PL_BINDINGS_MODULE "Cmpi"


/*
 * get Perl exception trace -> CMPIString
 * 
 */

#define TB_ERROR(str) {tbstr = str; goto cleanup;}
static CMPIString *
get_exc_trace(const CMPIBroker* broker)
{
    return broker->eft->newString(broker, "Perl failed", NULL); 
}


/*
 * Global Perl initializer
 * loads the Perl interpreter
 * init threads
 */

static int
PlGlobalInitialize(const CMPIBroker* broker, CMPIStatus* st)
{
  int error;
  char *embedding[] = { "", "-e", "0" };
  extern void SWIG_init(PerlInterpreter* my_perl, CV* cv);

  if (_TARGET_INIT)
    {
      return 0; 
    }
  
  _SBLIM_TRACE(1,("<%d> Perl: Loading", getpid()));
  
  _TARGET_INIT = perl_alloc();
  perl_construct(_TARGET_INIT);
  perl_parse(_TARGET_INIT, NULL, 3, embedding, NULL);
  perl_run(_TARGET_INIT);
      
  SWIG_init(_TARGET_INIT, NULL);

  /* load module */
  perl_eval_pv("use cmpi", TRUE);
  
  return 0; 
}


/*---------------------------------------------------------------*/

/*
 * local (per MI) Perl initializer
 * keeps track of reference count
 */

static int
TargetInitialize(ProviderMIHandle* hdl, CMPIStatus* st)
{
  int error;

  /* Set _CMPI_INIT, protected by _CMPI_INIT_MUTEX
   * so we call ruby_finalize() only once.
   */
  if (pthread_mutex_lock(&_CMPI_INIT_MUTEX))
  {
      perror("Can't lock _CMPI_INIT_MUTEX");
      abort();
  }
  error = PlGlobalInitialize(hdl->broker, st); 
  pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
  if (error != 0)
  {
     goto exit;
  }

  _SBLIM_TRACE(1,("<%d> TargetInitialize(Perl) called, miName '%s'", getpid(), hdl->miName));
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
  va_list vargs; 


  st->rc = CMPI_RC_OK;
  return 0;
}


/*
 * TargetCleanup
 */

static void
TargetCleanup(void)
{
  _TARGET_MODULE = NULL;
  perl_destruct(_TARGET_INIT);
  perl_free(_TARGET_INIT);

  return;
}

