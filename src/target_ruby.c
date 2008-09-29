/*
 * target_ruby.c
 *
 * Target language specific functions for cmpi_bindings
 *
 * Here: Ruby
 */


static VALUE
load_code()
{
   _SBLIM_TRACE(1,("Ruby: require 'rcmpi_instance'..."));
    
    rb_require("rcmpi_instance");

   _SBLIM_TRACE(1,("Ruby: ... done"));
  
   return Qnil;
}

static VALUE
create_cmpi(VALUE args)
{
    VALUE *values = (VALUE *)args;
   _SBLIM_TRACE(1,("Ruby: Cmpi_Instance.new ..."));
    VALUE klass = rb_class_new_instance(1, values, rb_const_get(rb_cObject, rb_intern("Cmpi_Instance")));
   _SBLIM_TRACE(1,("Ruby: ... done"));
    return klass;
}


/*---------------------------------------------------------------*/

/*
 * local (per MI) Ruby initializer
 * keeps track of reference count
 */

static int
TargetInitialize(ProviderMIHandle* hdl, CMPIStatus* st)
{
	int rc = 0; 
	if (st != NULL)
	{
		st->rc = CMPI_RC_OK; 
		st->msg = NULL; 
	}
    int error = 0;
    VALUE cmpiInstance;
    SWIGEXPORT void SWIG_init(void);
    
   _SBLIM_TRACE(1,("Initialize() called"));

    _SBLIM_TRACE(1,("Ruby: Loading"));
    ruby_init();
    ruby_init_loadpath();
    ruby_script("rcmpi_instance");
    SWIG_init();

    rb_protect(load_code, Qnil, &error);
    if (error) {
		_SBLIM_TRACE(1,("Ruby: FAILED loading rcmpi_instance.rb"));
		if (st != NULL)
		{
		st->rc = CMPI_RC_ERR_FAILED;
		}
    }
    else {
	_SBLIM_TRACE(1,("Ruby: loaded rcmpi_instance.rb"));
	VALUE args[1];
	args[0] = rb_str_new2(hdl->miName);
	cmpiInstance = rb_protect(create_cmpi, (VALUE)args, &error);
	if (error) {
	    _SBLIM_TRACE(1,("Ruby: FAILED creating Cmpi"));
		if (st != NULL)
		{
	    	st->rc = CMPI_RC_ERR_FAILED;
		}
	}
	else {
	    _SBLIM_TRACE(1,("Ruby: cmpi at %p", cmpiInstance));
	    hdl->tgMod = cmpiInstance;
	}
    }

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("Initialize() %s", (rc == 0)? "succeeded":"failed"));
   return rc; 
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
   
  return;
}

