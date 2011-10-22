/*
 * target_ruby.c
 *
 * Target language specific functions for cmpi_bindings
 *
 * Here: Ruby
 * 
 * Written by Klaus Kaempf <kkaempf@suse.de>
 * 
 */

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

/*
 * How it works
 *
 * This target language adapter provides three functions for use by cmpi-provider.c 
 * 
 * static int TargetInitialize(ProviderMIHandle* hdl, CMPIStatus* st)
 * static int TargetCall(ProviderMIHandle* hdl, CMPIStatus* st, const char* opname, int nargs, ...)
 * static void TargetCleanup(ProviderMIHandle * hdl)
 *
 * TargetInitialize
 * - loads the provider pointed to by ProviderMIHandle#miName
 *   miName - managed interface name - is FooBar (camel case) and loads foo_bar.rb
 *     expecting class Cmpi::FooBar
 *
 * TargetCall
 * - calls opname with args of ProviderMIHandle#implementation
 * 
 * TargetCleanup
 * - tear down provider
 */

#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

/* the module name for all Ruby code */
#define RB_MODULE_NAME "Cmpi"

/* an optional environment variable pointing to a directory with Ruby providers */
#define RUBY_PROVIDERS_DIR_ENV "RUBY_PROVIDERS_DIR"

/*
 * load_module - load provider
 * 
 * separate function for rb_require so it can be wrapped into rb_protect()
 * 
 * Returns Cmpi::<Class>
 * 
 */

static VALUE
load_provider(VALUE arg)
{
  const char *classname = (const char *)arg;
  if (classname == NULL || *classname == 0) {
    _SBLIM_TRACE(1,("Ruby: load_provider(%s) failed", classname));
    return Qfalse;
  }
  char *filename = alloca(strlen(classname) * 2 + 1);
  /* copy/decamelize classname */
  const char *cptr = classname;
  char *fptr = filename;
  while (*cptr) {
    if (isupper(*cptr)) {
      if (cptr > classname /* not first char */
	  && (*(fptr-1) != '_')
	  && (islower(*(cptr-1)) || islower(*(cptr+1))) ) { /* last was lower or next is lower */
	*fptr++ = '_';
      }
      *fptr++ = tolower(*cptr++);
    }
    else {
      *fptr++ = *cptr++;
    }
  }
  *fptr = 0;
  ruby_script(filename);
  _SBLIM_TRACE(1,("Ruby: loading (%s)", filename));
  if (rb_require(filename) != Qtrue) {
    _SBLIM_TRACE(1,("<%d> require '%s' failed", getpid(), filename));
    return Qnil;
  }
  /* Get Cmpi::Provider */
  VALUE val = rb_const_get(rb_cObject, rb_intern(RB_MODULE_NAME));
  if (val == Qnil) {
    _SBLIM_TRACE(1,("<%d> No such module '%s'", getpid(), RB_MODULE_NAME));
    return val;
  }
  val = rb_const_get(val, rb_intern(classname));
  if (val == Qnil) {
    _SBLIM_TRACE(1,("<%d> No such class  '%s::%s'", getpid(), RB_MODULE_NAME, classname));
  }
  return val;
}


/*
 * call_mi (called from rb_protect)
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
 * 
 * ** called with mutex locked **
 * 
 * loads the Ruby interpreter
 * init threads
 */

static int
RbGlobalInitialize(const CMPIBroker* broker, CMPIStatus* st)
{
  int error = 0;
  char *loadpath;

  if (_TARGET_INIT) {
    return error; 
  }
  _TARGET_INIT=1; /* safe, since mutex is locked */
  
  _SBLIM_TRACE(1,("<%d> Ruby: Loading", getpid()));
  
  ruby_init();
  ruby_init_loadpath();
  extern void SWIG_init();
  SWIG_init();

  /* Check RUBY_PROVIDERS_DIR_ENV if its a dir, append to $: */
  loadpath = getenv(RUBY_PROVIDERS_DIR_ENV);
  if (loadpath) {
    struct stat buf;
    VALUE search;
    if (stat(loadpath, &buf)) {
      _SBLIM_TRACE(1,("<%d> Can't stat $RUBY_PROVIDERS_DIR '%s'", getpid(), loadpath)); 
      return -1;
    }
    if ((buf.st_mode & S_IFDIR) == 0) {
      _SBLIM_TRACE(1,("<%d> Not a directory: $RUBY_PROVIDERS_DIR '%s'", getpid(), loadpath)); 
      return -1;
    }
    search = rb_gv_get("$:");
    rb_ary_push(search, rb_str_new2(loadpath));
  }
  return error; 
}


/*---------------------------------------------------------------*/

/*
 * local (per MI) Ruby initializer
 * keeps track of reference count
 * 
 */

static int
TargetInitialize(ProviderMIHandle* hdl, CMPIStatus* st)
{
  VALUE args[6];
  int error;

  /* Set _CMPI_INIT, protected by _CMPI_INIT_MUTEX
   * so we call ruby_finalize() only once.
   */
  if (pthread_mutex_lock(&_CMPI_INIT_MUTEX)) {
    perror("Can't lock _CMPI_INIT_MUTEX");
    abort();
  }
  error = RbGlobalInitialize(hdl->broker, st); 
  pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
  if (error != 0) {
   goto fail;
  }

  _SBLIM_TRACE(1,("<%d> TargetInitialize(Ruby) called, miName '%s'", getpid(), hdl->miName));

  /* call   static VALUE load_provider(const char *classname)
     returns Cmpi::<Class>
   */
  args[0] = rb_protect(load_provider, (VALUE)hdl->miName, &error);
  if (error)
    goto fail;

  args[1] = rb_intern("new");
  args[2] = 3;
  args[3] = rb_str_new2(hdl->miName);
  args[4] = SWIG_NewPointerObj((void*) hdl->broker, SWIGTYPE_p__CMPIBroker, 0);
  args[5] = SWIG_NewPointerObj((void*) hdl->context, SWIGTYPE_p__CMPIContext, 0);
  hdl->implementation = rb_protect(call_mi, (VALUE)args, &error);

fail:
  if (error) {
    CMPIString *trace = get_exc_trace(hdl->broker);
    _SBLIM_TRACE(1,("Ruby: FAILED creating %s: %s", hdl->miName, CMGetCharPtr(trace)));
    if (st != NULL) {
      st->rc = CMPI_RC_ERR_INVALID_CLASS;
      st->msg = trace;
    }
  }
  _SBLIM_TRACE(1,("Initialize() %s", (error == 0)?"succeeded":"failed"));
  return error;
}


/*
 * TargetCall
 * 
 * Call function 'opname' with nargs arguments within managed interface hdl->implementation
 */

static int 
TargetCall(ProviderMIHandle* hdl, CMPIStatus* st, 
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
  args[0] = (VALUE)(hdl->implementation);
  args[1] = op;
  args[2] = (VALUE)(nargs-3);
  if (nargs > 3)
    {
      va_start(vargs, nargs);
      for (i = 3; i < nargs; ++i)
	{
	  VALUE value;
	  value = va_arg(vargs, VALUE);
	  args[i] = (value == (VALUE)NULL) ? Qnil : value;
	}
      va_end(vargs);
    }

  
  /* call the Ruby function
   * possible results:
   *   i nonzero: Exception raised
   *   result == nil: not (or badly) implemented 
   *   result == true: success
   *   result == Array: pair of CMPIStatus rc(int) and msg(string)
   */
  result = rb_protect(call_mi, (VALUE)args, &i);
  free( args );

  if (i) /* exception ? */
    {
      CMPIString *trace = get_exc_trace(hdl->broker);
      char* str = fmtstr("Ruby: calling '%s' failed: %s", opname, CMGetCharPtr(trace)); 
      _SBLIM_TRACE(1,("%s", str));
      st->rc = CMPI_RC_ERR_FAILED; 
      st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
      return 1;
    }
  
  if (NIL_P(result)) /* not or wrongly implemented */
    {
      st->rc = CMPI_RC_ERR_NOT_SUPPORTED;
      return 1;
    }

  if (result != Qtrue)
    {
      VALUE resulta = rb_check_array_type(result);
      VALUE rc, msg;
      if (NIL_P(resulta))
	{
	  char* str = fmtstr("Ruby: calling '%s' returned unknown result", opname); 
	  st->rc = CMPI_RC_ERR_FAILED;
	  st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
	  return 1;
	}
  
      rc = rb_ary_entry(resulta, 0);
      msg = rb_ary_entry(resulta, 1);
      if (!FIXNUM_P(rc))
	{
	  char* str = fmtstr("Ruby: calling '%s' returned non-numeric rc code", opname); 
	  st->rc = CMPI_RC_ERR_FAILED;
	  st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
	  return 1;
	}
      st->rc = FIX2LONG(rc);
      st->msg = hdl->broker->eft->newString(hdl->broker, StringValuePtr(msg), NULL);
      return 1;
    }
  
  /* all is fine */
  st->rc = CMPI_RC_OK;
  return 0;
}


/*
 * TargetCleanup
 */

static void
TargetCleanup(ProviderMIHandle * hdl)
{
  ruby_finalize();
  return;
}
