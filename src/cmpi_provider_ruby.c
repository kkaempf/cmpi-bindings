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

static char _CLASSNAME[] = "CmpiInstanceRuby";

#include <stdio.h>
#include <stdarg.h>

/* Include the required CMPI macros, data types, and API function headers */
#include <cmpidt.h>
#include <cmpift.h>
#include <cmpimacs.h>

// Needed to obtain errno of failed system calls
#include <errno.h>

/* Needed for kill() */
#include <signal.h>


#include <ruby.h>

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

/* Global handle to the CIM broker. This is initialized by the CIMOM when the provider is loaded */
static const CMPIBroker * _BROKER = NULL;
static char* _MINAME = NULL; 

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

static int RBInitialize(CMPIInstanceMI * self, CMPIStatus* st);

static VALUE
properties2ruby( const char ** properties )
{
  if (properties) {
    VALUE rproperties = rb_ary_new();
    while (*properties)
      rb_ary_push( rproperties, rb_str_new2(*properties++) );
    return rproperties;
  }
  return Qnil;
}


// ----------------------------------------------------------------------------
// CMPI INSTANCE PROVIDER FUNCTIONS
// ----------------------------------------------------------------------------

static CMPIStatus Cleanup(
		const CMPIContext * context,
		CMPIBoolean terminating)	
{
   CMPIStatus status = {CMPI_RC_OK, NULL};	/* Return status of CIM operations. */
   
   _SBLIM_TRACE(1,("Cleanup() called"));
   
    ruby_finalize();
   _SBLIM_TRACE(1,("Cleanup(Ruby) called"));

	if (_MINAME != NULL) 
	{ 
		free(_MINAME); 
		_MINAME = NULL; 
	}
   
   /* Finished. */
exit:
   _SBLIM_TRACE(1,("Cleanup() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

static CMPIStatus InstCleanup(
		CMPIInstanceMI * self,		
		const CMPIContext * context,
		CMPIBoolean terminating)
{
	return Cleanup(context, terminating); 
}

static CMPIStatus AssocCleanup(
		CMPIAssociationMI * self,	
		const CMPIContext * context,
		CMPIBoolean terminating)
{
	return Cleanup(context, terminating); 
}

static CMPIStatus MethodCleanup(
		CMPIMethodMI * self,	
		const CMPIContext * context,
		CMPIBoolean terminating)
{
	return Cleanup(context, terminating); 
}

static CMPIStatus IndicationCleanup(
		CMPIIndicationMI * self,	
		const CMPIContext * context,
		CMPIBoolean terminating)
{
	return Cleanup(context, terminating); 
}

// ----------------------------------------------------------------------------


/* EnumInstanceNames() - return a list of all the instances names (i.e. return their object paths only) */
static CMPIStatus EnumInstanceNames(
		CMPIInstanceMI * self,		/* [in] Handle to this provider (i.e. 'self') */
		const CMPIContext * context,		/* [in] Additional context info, if any */				    
		const CMPIResult * result,	/* [in] Contains the CIM namespace and classname */
		const CMPIObjectPath * reference)	/* [in] Contains the CIM namespace and classname */
{
   CMPIStatus status = {CMPI_RC_OK, NULL};	/* Return status of CIM operations */

   _SBLIM_TRACE(1,("EnumInstanceNames() called"));

    _SBLIM_TRACE(1,("EnumInstanceNames(Ruby) called, context %p, result %p, reference %p", context, result, reference));
    VALUE klass = (VALUE)self->hdl;
    VALUE rcontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    VALUE rresult = SWIG_NewPointerObj((void*) result, SWIGTYPE_p__CMPIResult, 0);
    VALUE rreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);

    /* enum_instance_names instead of EnumInstanceNames to follow Ruby naming convention */
    VALUE r = rb_funcall( klass, rb_intern( "enum_instance_names" ), 3, rcontext, rresult, rreference );
   _SBLIM_TRACE(1,("r %p", r));

exit:
   _SBLIM_TRACE(1,("EnumInstanceNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------


/* EnumInstances() - return a list of all the instances (i.e. return all the instance data) */
static CMPIStatus EnumInstances(
        CMPIInstanceMI * self,		/* [in] Handle to this provider (i.e. 'self') */
		const CMPIContext * context,		/* [in] Additional context info, if any */
		const CMPIResult * result,	/* [in] Contains the CIM namespace and classname */
		const CMPIObjectPath * reference,	/* [in] Contains the CIM namespace and classname */
		const char ** properties)		/* [in] List of desired properties (NULL=all) */
{
   CMPIStatus status = {CMPI_RC_OK, NULL};	/* Return status of CIM operations */
/*   char * namespace = CMGetCharPtr(CMGetNameSpace(reference, NULL));  Our current CIM namespace */

    _SBLIM_TRACE(1,("EnumInstances(Ruby) called, context %p, result %p, reference %p, properties %p", context, result, reference, properties));
    VALUE klass = (VALUE)self->hdl;
    VALUE rcontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    VALUE rresult = SWIG_NewPointerObj((void*) result, SWIGTYPE_p__CMPIResult, 0);
    VALUE rreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    VALUE rproperties = properties2ruby( properties );
    /* enum_instances instead of EnumInstances to follow Ruby naming convention */
    VALUE r = rb_funcall( klass, rb_intern( "enum_instances" ), 4, rcontext, rresult, rreference, rproperties );
   _SBLIM_TRACE(1,("r %p", r));

exit:
   _SBLIM_TRACE(1,("EnumInstances() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------


/* GetInstance() -  return the instance data for the specified instance only */
static CMPIStatus GetInstance(
		CMPIInstanceMI * self,		/* [in] Handle to this provider (i.e. 'self') */
		const CMPIContext * context,		/* [in] Additional context info, if any */
		const CMPIResult * results,		/* [out] Results of this operation */
		const CMPIObjectPath * reference,	/* [in] Contains the CIM namespace, classname and desired object path */
		const char ** properties)		/* [in] List of desired properties (NULL=all) */
{
   CMPIStatus status = {CMPI_RC_OK, NULL};	/* Return status of CIM operations */

    _SBLIM_TRACE(1,("GetInstance(Ruby) called, context %p, results %p, reference %p, properties %p", context, results, reference, properties));
    VALUE klass = (VALUE)self->hdl;
    VALUE rcontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    VALUE rresults = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    VALUE rreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    VALUE rproperties = properties2ruby( properties );
    /* get_instance instead of GetInstance to follow Ruby naming convention */
    VALUE r = rb_funcall( klass, rb_intern( "get_instance" ), 4, rcontext, rresults, rreference, rproperties );
   _SBLIM_TRACE(1,("r %p", r));

exit:
   _SBLIM_TRACE(1,("GetInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------


/* CreateInstance() - create a new instance from the specified instance data. */
static CMPIStatus CreateInstance(
		CMPIInstanceMI * self,		/* [in] Handle to this provider (i.e. 'self') */
		const CMPIContext * context,		/* [in] Additional context info, if any. */
		const CMPIResult * results,		/* [out] Results of this operation */
		const CMPIObjectPath * reference,	/* [in] Contains the target namespace, classname and objectpath. */
		const CMPIInstance * newinstance)	/* [in] Contains all the new instance data. */
{
   CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};	/* Return status of CIM operations. */
   
   /* Creating new instances is not supported for this class. */
  
    _SBLIM_TRACE(1,("CreateInstance(Ruby) called, context %p, results %p, reference %p, instance %p, properties %p", context, results, reference, newinstance));
    VALUE klass = (VALUE)self->hdl;
    VALUE rcontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    VALUE rresults = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    VALUE rreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    VALUE rinstance = SWIG_NewPointerObj((void*) newinstance, SWIGTYPE_p__CMPIInstance, 0);
    /* create_instance instead of CreateInstance to follow Ruby naming convention */
    VALUE r = rb_funcall( klass, rb_intern( "create_instance" ), 4, rcontext, rresults, rreference, rinstance );
   _SBLIM_TRACE(1,("r %p", r));

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
		CMPIInstanceMI * self,		/* [in] Handle to this provider (i.e. 'self'). */
		const CMPIContext * context,		/* [in] Additional context info, if any. */
		const CMPIResult * results,		/* [out] Results of this operation. */
		const CMPIObjectPath * reference,	/* [in] Contains the target namespace, classname and objectpath. */
		const CMPIInstance * newinstance,	/* [in] Contains all the new instance data. */
		const char ** properties)		/* [in] List of desired properties (NULL=all) */
{
   CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};	/* Return status of CIM operations. */
   
   /* Modifying existing instances is not supported for this class. */
 
    _SBLIM_TRACE(1,("SetInstance(Ruby) called, context %p, results %p, reference %p, instance %p, properties %p", context, results, reference, newinstance, properties));
    VALUE klass = (VALUE)self->hdl;
    VALUE rcontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    VALUE rresults = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    VALUE rreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    VALUE rinstance = SWIG_NewPointerObj((void*) newinstance, SWIGTYPE_p__CMPIInstance, 0);
    VALUE rproperties = properties2ruby( properties );
    /* set_instance instead of SetInstance to follow Ruby naming convention */
    VALUE r = rb_funcall( klass, rb_intern( "set_instance" ), 5, rcontext, rresults, rreference, rinstance, rproperties );
   _SBLIM_TRACE(1,("r %p", r));
  
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

    _SBLIM_TRACE(1,("DeleteInstance(Ruby) called, context %p, results %p, reference %p", context, results, reference));
    VALUE klass = (VALUE)self->hdl;
    VALUE rcontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    VALUE rresults = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    VALUE rreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    /* delete_instance instead of DeleteInstance to follow Ruby naming convention */
    VALUE r = rb_funcall( klass, rb_intern( "delete_instance" ), 3, rcontext, rresults, rreference );
   _SBLIM_TRACE(1,("r %p", r));
  
   /* Finished. */
exit:
   _SBLIM_TRACE(1,("DeleteInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}

// ----------------------------------------------------------------------------


/* ExecQuery() - return a list of all the instances that satisfy the desired query filter. */
static CMPIStatus ExecQuery(
		CMPIInstanceMI * self,		/* [in] Handle to this provider (i.e. 'self'). */
		const CMPIContext * context,		/* [in] Additional context info, if any. */
		const CMPIResult * results,		/* [out] Results of this operation. */
		const CMPIObjectPath * reference,	/* [in] Contains the target namespace and classname. */
		const char * query,			/* [in] Text of the query, written in the query language. */ 
		const char * language)		/* [in] Name of the query language (e.g. "WQL"). */ 
{
   CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};	/* Return status of CIM operations. */
   
    _SBLIM_TRACE(1,("ExecQuery(Ruby) called, context %p, results %p, reference %p, query %s, language %s", context, results, reference, query, language));
    VALUE klass = (VALUE)self->hdl;
    VALUE rcontext = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    VALUE rresults = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    VALUE rreference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    VALUE rquery = rb_str_new2( query );
    VALUE rlanguage = rb_str_new2( language );
    /* exec_query instead of ExecQuery to follow Ruby naming convention */
    VALUE r = rb_funcall( klass, rb_intern( "exec_query" ), 5, rcontext, rresults, rreference, query, language );
   _SBLIM_TRACE(1,("r %p", r));

   /* Query filtering is not supported for this class. */

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("ExecQuery() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
   return status;
}


// ----------------------------------------------------------------------------

static VALUE load_code()
{
   _SBLIM_TRACE(1,("Ruby: require 'rcmpi_instance'..."));
    
    rb_require("rcmpi_instance");

   _SBLIM_TRACE(1,("Ruby: ... done"));
}

static VALUE create_cmpi(VALUE args)
{
    VALUE *values = (VALUE *)args;
   _SBLIM_TRACE(1,("Ruby: Cmpi_Instance.new ..."));
    VALUE klass = rb_class_new_instance(1, values, rb_const_get(rb_cObject, rb_intern("Cmpi_Instance")));
   _SBLIM_TRACE(1,("Ruby: ... done"));
    return klass;
}

/* Initialize() - perform any necessary initialization immediately after this provider is loaded. */
static int RBInitialize(
		CMPIInstanceMI * self, CMPIStatus* st)		/* [in] Handle to this provider (i.e. 'self'). */
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
	args[0] = rb_str_new2(_CLASSNAME);
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
	    self->hdl = (void *)cmpiInstance;
	}
    }

   /* Finished. */
exit:
   _SBLIM_TRACE(1,("Initialize() %s", (rc == 0)? "succeeded":"failed"));
   return rc; 
}




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
   _BROKER = broker;
   _MINAME = strdup(miname); 
}

#define SWIG_CMPI_MI_FACTORY(ptype) \
CMPI##ptype##MI* _Generic_Create_##ptype##MI(const CMPIBroker* broker, \
		const CMPIContext* context, const char* miname, CMPIStatus* st)\
{ \
	static CMPI##ptype##MI mi={ \
		NULL, \
		&ptype##MIFT__, \
	}; \
	createInit(broker, context, miname, st); \
	return &mi;  \
}

SWIG_CMPI_MI_FACTORY(Instance)
SWIG_CMPI_MI_FACTORY(Method)
SWIG_CMPI_MI_FACTORY(Association)
SWIG_CMPI_MI_FACTORY(Indication)

