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

/* mutex to flag Ruby call in progress - the one aquiring the lock inits the stack */
static pthread_mutex_t _stack_init_mutex = PTHREAD_MUTEX_INITIALIZER;

static void
decamelize(const char *from, char *to)
{
  const char *start = from;
  /* copy/decamelize classname */
  while (*from) {
    if (isupper(*from)) {
      if (from > start /* not first char */
	  && (*(to-1) != '_')
	  && (islower(*(from-1)) || islower(*(from+1))) ) { /* last was lower or next is lower */
	*to++ = '_';
      }
      *to++ = tolower(*from++);
    }
    else {
      *to++ = *from++;
    }
  }
  *to = 0;
}

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
  VALUE req; /* result of rb_require */
  if (classname == NULL || *classname == 0) {
    _SBLIM_TRACE(1,("Ruby: load_provider(%s) no class given", classname));
    return Qfalse;
  }
  char *filename = alloca(strlen(classname) * 2 + 1);
  decamelize(classname, filename);
  ruby_script(filename);
  _SBLIM_TRACE(1,("<%d> Ruby: loading (%s)", getpid(), filename));
  req = rb_require(filename);
  /* Qtrue == just loaded, Qfalse = already loaded, else: fail */
  if ((req != Qtrue) && (req != Qfalse)) {
    _SBLIM_TRACE(1,("<%d> require '%s' failed", getpid(), filename));
    return Qnil;
  }
  /* Get Cmpi::Provider */
  VALUE val = rb_const_get(rb_cObject, rb_intern(RB_MODULE_NAME));
  if (NIL_P(val)) {
    _SBLIM_TRACE(1,("<%d> No such module '%s'", getpid(), RB_MODULE_NAME));
    return val;
  }
  val = rb_const_get(val, rb_intern(classname));
  if (NIL_P(val)) {
    _SBLIM_TRACE(1,("<%d> No such class '%s::%s'", getpid(), RB_MODULE_NAME, classname));
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
  VALUE searchpath;

  if (_TARGET_INIT) {
    return error; 
  }
  _TARGET_INIT=1; /* safe, since mutex is locked */
  
  _SBLIM_TRACE(1,("<%d> Ruby: RbGlobalInitialize", getpid()));
  
  ruby_init();
  ruby_init_loadpath();
  extern void SWIG_init();
  SWIG_init();

  searchpath = rb_gv_get("$:");
  /* Append /usr/share/cmpi to $: */
  rb_ary_push(searchpath, rb_str_new2("/usr/share/cmpi"));

  /* Check RUBY_PROVIDERS_DIR_ENV if its a dir, append to $: */
  loadpath = getenv(RUBY_PROVIDERS_DIR_ENV);
  if (loadpath) {
    struct stat buf;
    if (stat(loadpath, &buf)) {
      _SBLIM_TRACE(1,("<%d> Can't stat $RUBY_PROVIDERS_DIR '%s'", getpid(), loadpath)); 
      return -1;
    }
    if ((buf.st_mode & S_IFDIR) == 0) {
      _SBLIM_TRACE(1,("<%d> Not a directory: $RUBY_PROVIDERS_DIR '%s'", getpid(), loadpath)); 
      return -1;
    }
    rb_ary_push(searchpath, rb_str_new2(loadpath));
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
  VALUE args[6] = { Qnil };
  int error;
  int have_lock = 0;

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
    if (st != NULL) {
      st->rc = CMPI_RC_ERR_INVALID_CLASS;
      st->msg = CMNewString(hdl->broker, "Failed to init Ruby", NULL);
    }
    goto fail;
  }

  _SBLIM_TRACE(1,("<%d> TargetInitialize(Ruby) called, miName '%s'", getpid(), hdl->miName));

  if (pthread_mutex_trylock(&_stack_init_mutex) == 0) {
    have_lock = 1;
    RUBY_INIT_STACK
  }

  /* call   static VALUE load_provider(const char *classname)
     returns Cmpi::<Class>
   */
  args[0] = rb_protect(load_provider, (VALUE)hdl->miName, &error);
  if (error) {
    _SBLIM_TRACE(1,("Ruby: load_provider(%s) failed !", hdl->miName));
    if (st != NULL) {
      st->rc = CMPI_RC_ERR_INVALID_CLASS;
      st->msg = CMNewString(hdl->broker, "Failed to load provider", NULL);
    }
    goto fail;
  }

  args[1] = rb_intern("new");
  args[2] = 3;
  args[3] = rb_str_new2(hdl->miName);
  args[4] = SWIG_NewPointerObj((void*) hdl->broker, SWIGTYPE_p__CMPIBroker, 0);
  args[5] = SWIG_NewPointerObj((void*) hdl->context, SWIGTYPE_p__CMPIContext, 0);
  hdl->implementation = rb_protect(call_mi, (VALUE)args, &error);
  if (error) {
    _SBLIM_TRACE(1,("Ruby: %s.new() failed !", hdl->miName));
  }

fail:
  if (error) {
    CMPIString *trace = get_exc_trace(hdl->broker);
    if (st != NULL) {
      st->rc = CMPI_RC_ERR_INVALID_CLASS;
      st->msg = trace;
    }
  }
  else {
    /* prevent Ruby GC from deallocating the provider
     * found at http://www.lysator.liu.se/~norling/ruby_callbacks.html
     */
    rb_gc_register_address(&(hdl->implementation));
  }
  if (have_lock)
    pthread_mutex_unlock(&_stack_init_mutex);
  _SBLIM_TRACE(1,("Initialize() %s", (error == 0)?"succeeded":"failed"));
  return error;
}


/*
 * TargetCall
 * 
 * Call function 'opname' with nargs arguments within managed interface hdl->implementation
 */

static Target_Type
TargetCall(ProviderMIHandle* hdl, CMPIStatus* st, 
                 const char* opname, int nargs, ...)
{
  int have_lock = 0;
  int invoke = (nargs < 0) ? 1 : 0; /* invokeMethod style call */
  int i;
  VALUE *args, result, op = rb_intern(opname);
  va_list vargs; 

  if (pthread_mutex_trylock(&_stack_init_mutex) == 0) {
    have_lock = 1;
    RUBY_INIT_STACK
  }
  if (invoke) {
    va_start(vargs, nargs);
    args = va_arg(vargs, VALUE *);
    va_end(vargs);
    nargs = -nargs;
  }
  /* add hdl->instance, op and nargs to the args array, so rb_protect can be called */
  nargs += 3;
  if (!invoke) {
    args = (VALUE *)alloca(nargs * sizeof(VALUE));
    if (args == NULL) {
      _SBLIM_TRACE(1,("Out of memory")); 
      abort();
    }
  }
  args[0] = (VALUE)(hdl->implementation);
  args[1] = op;
  args[2] = (VALUE)(nargs-3);
  if (!invoke && (nargs > 3))
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

  if (i) /* exception ? */
    {
      CMPIString *trace = get_exc_trace(hdl->broker);
      char* str = fmtstr("Ruby: calling '%s' failed: %s", opname, CMGetCharPtr(trace)); 
      _SBLIM_TRACE(1,("%s", str));
      st->rc = CMPI_RC_ERR_FAILED; 
      st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
      goto done;
    }
  if (NIL_P(result)) /* not or wrongly implemented */
    {
      st->rc = CMPI_RC_ERR_NOT_SUPPORTED;
      goto done;
    }

  if (invoke) {
    st->rc = CMPI_RC_OK;
    goto done;
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
	  goto done;
	}
  
      rc = rb_ary_entry(resulta, 0);
      msg = rb_ary_entry(resulta, 1);
      if (!FIXNUM_P(rc))
	{
	  char* str = fmtstr("Ruby: calling '%s' returned non-numeric rc code", opname); 
	  st->rc = CMPI_RC_ERR_FAILED;
	  st->msg = hdl->broker->eft->newString(hdl->broker, str, NULL); 
	  goto done;
	}
      st->rc = FIX2LONG(rc);
      st->msg = hdl->broker->eft->newString(hdl->broker, StringValuePtr(msg), NULL);
      goto done;
    }
  
  /* all is fine */
  st->rc = CMPI_RC_OK;
done:
  if (have_lock)
    pthread_mutex_unlock(&_stack_init_mutex);
  return result;
}


/*
 * TargetCleanup
 */

static void
TargetCleanup(ProviderMIHandle * hdl)
{
  _SBLIM_TRACE(1,("TargetCleanup(hdl %p)", hdl));
  /* free() provider instance */
  if (hdl && hdl->implementation) {
    _SBLIM_TRACE(1,("unregister(%p)", hdl->implementation));
    rb_gc_unregister_address(&(hdl->implementation));
  }

  /* Decrement _MI_COUNT, protected by _CMPI_INIT_MUTEX
   * call ruby_finalize when _MI_COUNT drops to zero
   */
  if (pthread_mutex_lock(&_CMPI_INIT_MUTEX))
  {
    perror("Can't lock _CMPI_INIT_MUTEX");
    abort();
  }
  if (--_MI_COUNT > 0) 
  {
    pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
    _SBLIM_TRACE(1,("_MI_COUNT > 0: %d", _MI_COUNT));
    return;
  }

  if (_TARGET_INIT)  // if Ruby is initialized and _MI_COUNT == 0, call ruby_finalize
  {
    _SBLIM_TRACE(1,("Calling ruby_finalize()"));
    ruby_finalize();
    _TARGET_INIT=0; // false
  }
  pthread_mutex_unlock(&_CMPI_INIT_MUTEX);
  return;
}

