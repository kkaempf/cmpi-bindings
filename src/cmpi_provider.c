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

#include <sys/types.h>
#include <stdio.h>
#include <stdarg.h>
#include <unistd.h>
#include <pthread.h>

/* Include the required CMPI macros, data types, and API function headers */
#include <cmpi/cmpidt.h>
#include <cmpi/cmpift.h>
#include <cmpi/cmpimacs.h>

// Needed to obtain errno of failed system calls
#include <errno.h>

/* Needed for kill() */
#include <signal.h>

static int cmpi_bindings_trace_level = 0; /* increase by setenv CMPI_BINDINGS_TRACE_LEVEL */

/* A simple stderr logging/tracing facility. */
#ifndef _SBLIM_TRACE
#define _SBLIM_TRACE(tracelevel,args) if (tracelevel <= cmpi_bindings_trace_level) { _logstderr args; }
static void _logstderr(char *fmt,...)
{
   va_list ap;
   va_start(ap,fmt);
   vfprintf(stderr,fmt,ap);
   va_end(ap);
   fprintf(stderr,"\n");
}
#endif

#define _CMPI_SETFAIL(msgstr) {if (st != NULL) st->rc = CMPI_RC_ERR_FAILED; st->msg = msgstr; }

/*
**==============================================================================
**
** Local definitions:
**
**==============================================================================
*/

/*
 * per-MI struct to keep
 * - name of MI
 * - pointer to target instrumentation
 * - pointer to Broker
 */

typedef struct __ProviderMIHandle
{
    char *miName;
    Target_Type implementation;
    const CMPIBroker* broker;
    const CMPIContext* context;
} ProviderMIHandle;


/*
 * string2target
 * char* -> Target_Type
 * 
 * *must* be called within TARGET_THREAD_BEGIN_BLOCK/TARGET_THREAD_END_BLOCK
 */

static Target_Type
string2target(const char *s)
{
    Target_Type obj;

    if (s == NULL)
    {
        obj = Target_Null;
	Target_INCREF(obj);
    }
    else
    {
	obj = Target_String(s);
    }
    return obj;
}


/*
 * proplist2target
 * char** -> Target_Type
 * 
 * *must* be called within TARGET_THREAD_BEGIN_BLOCK/TARGET_THREAD_END_BLOCK
 */

static Target_Type
proplist2target(const char** cplist)
{
    Target_Type pl;

    if (cplist == NULL)
    {
	pl = Target_Null;
        Target_INCREF(pl);
    }
    else
    {
        pl = Target_Array(); 
        for (; (cplist!=NULL && *cplist != NULL); ++cplist)
        {
            Target_Append(pl, Target_String(*cplist)); 
        }
    }
    return pl; 
}


static char *
fmtstr(const char* fmt, ...)
{
    static char buf[1];
    va_list ap; 
    int len; 
    char* str;

    va_start(ap, fmt); 
    len = vsnprintf(buf, 1, fmt, ap); /* vsnprintf(NULL, 0, ...) should work. bnc#762684 */
    va_end(ap); 
    if (len <= 0)
    {
        fprintf(stderr, "*Err: vsnprintf(%s) = %d\n", fmt, len);
        return NULL; 
    }
    str = (char*)malloc(len+1); 
    if (str == NULL)
    {
        fprintf(stderr, "*Err: malloc(%d) failed\n", len+1);
        return NULL; 
    }
    va_start(ap, fmt); 
    vsnprintf(str, len+1, fmt, ap); 
    va_end(ap); 
    return str; 
}


/*
**==============================================================================
**
** Local definitions:
**
**==============================================================================
*/


/*
 * There is one target interpreter, serving multiple MIs
 * The number of MIs using the interpreter is counted in _MI_COUNT,
 * when the last user goes aways, the target interpreter is unloaded.
 * 
 * _CMPI_INIT_MUTEX protects this references counter from concurrent access.
 * 
 */

#if defined(SWIGPERL)
static PerlInterpreter * _TARGET_INIT = 0; /* acts as a boolean - is target initialized? */
#else
static int _TARGET_INIT = 0; /* acts as a boolean - is target initialized? */
#endif
static int _MI_COUNT = 0;    /* use count, number of MIs */
static pthread_mutex_t _CMPI_INIT_MUTEX = PTHREAD_MUTEX_INITIALIZER;  /* mutex around _MI_COUNT */

#ifndef SWIGRUBY
static Target_Type _TARGET_MODULE = Target_Null;  /* The target module (aka namespace) */
#endif

#if defined(SWIGPYTHON)
#include "target_python.c"
#endif

#if defined(SWIGRUBY)
#include "target_ruby.c"
#endif

#if defined(SWIGPERL)
#include "target_perl.c"
#endif

/*
 * Cleanup
 * 
 */

static CMPIStatus
Cleanup(
        ProviderMIHandle * miHdl,
        const CMPIContext * context,
        CMPIBoolean terminating)    
{
    _SBLIM_TRACE(1,("Cleanup() called, miHdl %p, miHdl->implementation %p, context %p, terminating %d", 
                    miHdl, miHdl->implementation, context, terminating));
    CMPIStatus status = {CMPI_RC_OK, NULL}; 

    if (miHdl->implementation != Target_Null)
    {
        Target_Type _context;
        Target_Type _terminating; 

        TARGET_THREAD_BEGIN_BLOCK; 
        _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
        _terminating = Target_Bool(terminating); 

        TargetCall(miHdl, &status, "cleanup", 2, _context, _terminating); 
        TARGET_THREAD_END_BLOCK; 
        _SBLIM_TRACE(1,("Cleanup() %d", status.rc));
    }

    if (!terminating && (status.rc == CMPI_RC_DO_NOT_UNLOAD ||
                status.rc ==  CMPI_RC_NEVER_UNLOAD))
    {
        _SBLIM_TRACE(1,("Cleanup() Provider requested not to be unloaded.")); 
        return status; 
    }
  
    TargetCleanup(miHdl);
    if (miHdl != NULL) 
    { 
        free(miHdl->miName); 
     
        // we must free the miHdl - it is our ProviderMIHandle.
        // it is pointed to by the CMPI<type>MI * that the broker holds onto...
        // the broker is responsible for freeing the CMPI<type>MI*  
        free(miHdl);
        miHdl = NULL; 
    }

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

/*
 * InstCleanup
 */

static CMPIStatus
InstCleanup(CMPIInstanceMI * self,      
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    CMPIStatus st;
    _SBLIM_TRACE(1,("Cleanup() called for Instance provider %s", ((ProviderMIHandle *)self->hdl)->miName));
    st = Cleanup((ProviderMIHandle*)self->hdl, context, terminating);
    if (terminating && st.rc == CMPI_RC_OK)
      free(self);
    return st;
}


/*
 * AssocCleanup
 */

static CMPIStatus
AssocCleanup(CMPIAssociationMI * self,   
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    CMPIStatus st;
    _SBLIM_TRACE(1,("Cleanup() called for Association provider %s", ((ProviderMIHandle *)self->hdl)->miName));
    st = Cleanup((ProviderMIHandle*)self->hdl, context, terminating); 
    if (terminating && st.rc == CMPI_RC_OK)
      free(self);
    return st;
}


/*
 * MethodCleanup
 */

static CMPIStatus
MethodCleanup(CMPIMethodMI * self,    
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    CMPIStatus st;
    _SBLIM_TRACE(1,("Cleanup() called for Method provider %s", ((ProviderMIHandle *)self->hdl)->miName));
    st = Cleanup((ProviderMIHandle*)self->hdl, context, terminating); 
    if (terminating && st.rc == CMPI_RC_OK)
      free(self);
    return st;
}


/*
 * IndicationCleanup
 */

static CMPIStatus
IndicationCleanup(CMPIIndicationMI * self,    
        const CMPIContext * context,
        CMPIBoolean terminating)
{
    CMPIStatus st;
    _SBLIM_TRACE(1,("Cleanup() called for Indication provider %s", ((ProviderMIHandle *)self->hdl)->miName));
      st = Cleanup((ProviderMIHandle*)self->hdl, context, terminating); 
    if (terminating && st.rc == CMPI_RC_OK)
      free(self);
    return st;
}

// ----------------------------------------------------------------------------


/*
 * EnumInstanceNames() - return a list of all the instances names (i.e. return their object paths only)
 */
static CMPIStatus
EnumInstanceNames(CMPIInstanceMI * self,      
        const CMPIContext * context,
        const CMPIResult * result,
        const CMPIObjectPath * reference)
{
    Target_Type _context;
    Target_Type _result;
    Target_Type _reference;

    CMPIStatus status = {CMPI_RC_OK, NULL};

    _SBLIM_TRACE(1,("EnumInstancesNames() called, self %p, context %p, result %p, reference %p", self, context, result, reference));

    TARGET_THREAD_BEGIN_BLOCK; 
    _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    _result = SWIG_NewPointerObj((void*) result, SWIGTYPE_p__CMPIResult, 0);
    _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);

    TargetCall((ProviderMIHandle*)self->hdl, &status, "enum_instance_names", 3, 
                                                        _context,
                                                        _result,
                                                        _reference); 
    TARGET_THREAD_END_BLOCK;
    _SBLIM_TRACE(1,("EnumInstanceNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


// ----------------------------------------------------------------------------


/*
 * EnumInstances() - return a list of all the instances (i.e. return all the instance data)
 */
static CMPIStatus
EnumInstances(CMPIInstanceMI * self,  
        const CMPIContext * context,
        const CMPIResult * result,
        const CMPIObjectPath * reference,
        const char ** properties)
{
    Target_Type _context;
    Target_Type _result;
    Target_Type _reference;
    Target_Type _properties;

    CMPIStatus status = {CMPI_RC_OK, NULL};  /* Return status of CIM operations */
    /*   char * namespace = CMGetCharPtr(CMGetNameSpace(reference, NULL));  Our current CIM namespace */

    _SBLIM_TRACE(1,("EnumInstances() called, self %p, context %p, result %p, reference %p, properties %p", self, context, result, reference, properties));

    TARGET_THREAD_BEGIN_BLOCK; 
    _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    _result = SWIG_NewPointerObj((void*) result, SWIGTYPE_p__CMPIResult, 0);
    _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    _properties = proplist2target(properties); 

    TargetCall((ProviderMIHandle*)self->hdl, &status, "enum_instances", 4, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _properties); 
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("EnumInstances() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


// ----------------------------------------------------------------------------


/*
 * GetInstance() -  return the instance data for the specified instance only
 */
static CMPIStatus
GetInstance(CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results,
        const CMPIObjectPath * reference,
        const char ** properties)
{
    Target_Type _context;
    Target_Type _result;
    Target_Type _reference;
    Target_Type _properties;

    CMPIStatus status = {CMPI_RC_OK, NULL};  /* Return status of CIM operations */

    _SBLIM_TRACE(1,("GetInstance() called, self %p, context %p, results %p, reference %p, properties %p", self, context, results, reference, properties));

    TARGET_THREAD_BEGIN_BLOCK; 
    _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    _properties = proplist2target(properties); 

    /* For Python, TargetCall() packs all arguments into a tuple and releases this tuple,
     * effectively DECREFing all elements */

    TargetCall((ProviderMIHandle*)self->hdl, &status, "get_instance", 4, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _properties);
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("GetInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


// ----------------------------------------------------------------------------


/*
 * CreateInstance() - create a new instance from the specified instance data.
 */
static CMPIStatus
CreateInstance(CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results,
        const CMPIObjectPath * reference,
        const CMPIInstance * newinstance)
{
    Target_Type _context;
    Target_Type _result;
    Target_Type _reference;
    Target_Type _newinst;

    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};   /* Return status of CIM operations. */

   
   /* Creating new instances is not supported for this class. */
  
    _SBLIM_TRACE(1,("CreateInstance() called, context %p, results %p, reference %p, newinstance %p", context, results, reference, newinstance));

    TARGET_THREAD_BEGIN_BLOCK; 
    _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    _newinst = SWIG_NewPointerObj((void*) newinstance, SWIGTYPE_p__CMPIInstance, 0);

    TargetCall((ProviderMIHandle*)self->hdl, &status, "create_instance", 4, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _newinst); 
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("CreateInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


// ----------------------------------------------------------------------------

#ifdef CMPI_VER_100
#define SetInstance ModifyInstance
#endif

/*
 * SetInstance() - save modified instance data for the specified instance.
 */
static CMPIStatus
SetInstance(CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results, 
        const CMPIObjectPath * reference,
        const CMPIInstance * newinstance,
        const char ** properties)
{
    Target_Type _context;
    Target_Type _result;
    Target_Type _reference;
    Target_Type _newinst;
    Target_Type plist;

    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};   /* Return status of CIM operations. */
   
   /* Modifying existing instances is not supported for this class. */
 
    _SBLIM_TRACE(1,("SetInstance() called, context %p, results %p, reference %p, newinstance %p, properties %p", context, results, reference, newinstance, properties));

    TARGET_THREAD_BEGIN_BLOCK; 
    _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    _newinst = SWIG_NewPointerObj((void*) newinstance, SWIGTYPE_p__CMPIInstance, 0);
    plist = proplist2target(properties); 

    TargetCall((ProviderMIHandle*)self->hdl, &status, "set_instance", 5, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _newinst,
                                                               plist); 
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("SetInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/* ---------------------------------------------------------------------------- */

/*
 * DeleteInstance() - delete/remove the specified instance.
 */
static CMPIStatus
DeleteInstance(CMPIInstanceMI * self,  
        const CMPIContext * context,
        const CMPIResult * results, 
        const CMPIObjectPath * reference)
{
    Target_Type _context;
    Target_Type _result;
    Target_Type _reference;

    CMPIStatus status = {CMPI_RC_OK, NULL};  

    _SBLIM_TRACE(1,("DeleteInstance() called, context %p, results %p, reference %p", context, results, reference));

    TARGET_THREAD_BEGIN_BLOCK; 
    _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);

    TargetCall((ProviderMIHandle*)self->hdl, &status, "delete_instance", 3, 
                                                               _context,
                                                               _result, 
                                                               _reference); 
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("DeleteInstance() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/* ---------------------------------------------------------------------------- */

/*
 * ExecQuery() - return a list of all the instances that satisfy the desired query filter.
 */
static CMPIStatus
ExecQuery(CMPIInstanceMI * self,
        const CMPIContext * context,
        const CMPIResult * results,
        const CMPIObjectPath * reference,
        const char * query,
        const char * language)  
{
    Target_Type _context;
    Target_Type _result;
    Target_Type _reference;
    Target_Type _query;
    Target_Type _lang;

    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};   /* Return status of CIM operations. */
   
    _SBLIM_TRACE(1,("ExecQuery() called, context %p, results %p, reference %p, query %s, language %s", context, results, reference, query, language));

    TARGET_THREAD_BEGIN_BLOCK; 
    _context = SWIG_NewPointerObj((void*) context, SWIGTYPE_p__CMPIContext, 0);
    _result = SWIG_NewPointerObj((void*) results, SWIGTYPE_p__CMPIResult, 0);
    _reference = SWIG_NewPointerObj((void*) reference, SWIGTYPE_p__CMPIObjectPath, 0);
    _query = string2target(query); 
    _lang = string2target(language); 

    TargetCall((ProviderMIHandle*)self->hdl, &status, "exec_query", 5, 
                                                               _context,
                                                               _result, 
                                                               _reference,
                                                               _query,
                                                               _lang); 
    TARGET_THREAD_END_BLOCK; 

    /* Query filtering is not supported for this class. */

    _SBLIM_TRACE(1,("ExecQuery() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/* ---------------------------------------------------------------------------- 
 * CMPI external API
 * ---------------------------------------------------------------------------- */

/*
 * associatorMIFT
 */

static CMPIStatus
associatorNames(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* assocClass,
        const char* resultClass,
        const char* role,
        const char* resultRole)
{
    Target_Type _ctx;
    Target_Type _rslt;
    Target_Type _objName ;
    Target_Type _assocClass;
    Target_Type _resultClass;
    Target_Type _role;
    Target_Type _resultRole;

    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("associatorNames() called, ctx %p, rslt %p, objName %p, assocClass %s, resultClass %s, role %s, resultRole %s", ctx, rslt, objName, assocClass, resultClass, role, resultRole));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    _assocClass = (Target_Type)NULL; 
    _resultClass = (Target_Type)NULL; 
    _role = (Target_Type)NULL; 
    _resultRole = (Target_Type)NULL;
    if (assocClass != NULL)
    {
        _assocClass = string2target(assocClass); 
    }
    if (resultClass != NULL)
    {
        _resultClass = string2target(resultClass); 
    }
    if (role != NULL) 
    { 
        _role = string2target(role); 
    }
    if (resultRole != NULL) 
    { 
        _resultRole = string2target(resultRole); 
    }

    TargetCall((ProviderMIHandle*)self->hdl, &status, "associator_names", 7, 
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _assocClass,
                                                               _resultClass,
                                                               _role,
                                                               _resultRole); 
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("associatorNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}

/*
 * associators
 */

static CMPIStatus
associators(
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
    Target_Type _ctx;
    Target_Type _rslt;
    Target_Type _objName;
    Target_Type _props;
    Target_Type _assocClass;
    Target_Type _resultClass;
    Target_Type _role;
    Target_Type _resultRole;

    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("associators() called, ctx %p, rslt %p, objName %p, assocClass %s, resultClass %s, role %s, resultRole %s", ctx, rslt, objName, assocClass, resultClass, role, resultRole));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    _props = proplist2target(properties); 
    _assocClass = (Target_Type)NULL;
    _resultClass = (Target_Type)NULL;
    _role = (Target_Type)NULL;
    _resultRole = (Target_Type)NULL;
    if (assocClass != NULL)
    {
        _assocClass = string2target(assocClass); 
    }
    if (resultClass != NULL)
    {
        _resultClass = string2target(resultClass); 
    }
    if (role != NULL) 
    { 
        _role = string2target(role); 
    }
    if (resultRole != NULL) 
    { 
        _resultRole = string2target(resultRole); 
    }

    TargetCall((ProviderMIHandle*)self->hdl, &status, "associators", 8, 
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _assocClass,
                                                               _resultClass,
                                                               _role,
                                                               _resultRole,
                                                               _props);

    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("associators() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}

/*
 * referenceNames
 */

static CMPIStatus
referenceNames(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* resultClass,
        const char* role)
{
    Target_Type _ctx;
    Target_Type _rslt;
    Target_Type _objName;
    Target_Type _resultClass;
    Target_Type _role;

    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("referenceNames() called, ctx %p, rslt %p, objName %p, resultClass %s, role %s", ctx, rslt, objName, resultClass, role));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    _resultClass = (Target_Type)NULL;
    _role = (Target_Type)NULL;
    if (role != NULL) 
    { 
        _role = string2target(role); 
    }
    if (resultClass != NULL) 
    { 
        _resultClass = string2target(resultClass); 
    }

    TargetCall((ProviderMIHandle*)self->hdl, &status, "reference_names", 5,
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _resultClass,
                                                               _role); 

    TARGET_THREAD_END_BLOCK;
    _SBLIM_TRACE(1,("referenceNames() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/*
 * references
 */

static CMPIStatus
references(
        CMPIAssociationMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* resultClass,
        const char* role,
        const char** properties)
{
    Target_Type _ctx;
    Target_Type _rslt;
    Target_Type _objName;
    Target_Type _role;
    Target_Type _resultClass;
    Target_Type _props;

    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("references() called, ctx %p, rslt %p, objName %p, resultClass %s, role %s, properties %p", ctx, rslt, objName, resultClass, role, properties));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
    _role = (Target_Type)NULL;
    _resultClass = (Target_Type)NULL;
    if (role != NULL) 
    { 
        _role = string2target(role); 
    }
    if (resultClass != NULL) 
    { 
        _resultClass = string2target(resultClass); 
    }
    _props = proplist2target(properties); 

    TargetCall((ProviderMIHandle*)self->hdl, &status, "references", 6, 
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _resultClass,
                                                               _role,
                                                               _props); 
    TARGET_THREAD_END_BLOCK;
    _SBLIM_TRACE(1,("references() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


#if defined(SWIGRUBY)
/*
 * Check type of VALUE
 *
 * return 0 if ok
 * return -1 if bad type, set status accordingly
 *
 */

static int
check_ruby_type( VALUE value, int type, const char *message, CMPIStatus *status, ProviderMIHandle* hdl )
{
  if (TYPE(value) != type) {
    status->rc = CMPI_RC_ERR_TYPE_MISMATCH;
    status->msg = CMNewString(hdl->broker, message, NULL);
    return -1;
  }
  return 0;
}
#endif

/*
 * invokeMethod
 */
static CMPIStatus
invokeMethod(
        CMPIMethodMI* self,
        const CMPIContext* ctx,
        const CMPIResult* rslt,
        const CMPIObjectPath* objName,
        const char* method,
        const CMPIArgs* in,
        CMPIArgs* out)
{
    Target_Type _ctx;
    Target_Type _objName;

    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("invokeMethod() called, ctx %p, rslt %p, objName %p, method %s, in %p, out %p", ctx, rslt, objName, method, in, out));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    _objName = SWIG_NewPointerObj((void*) objName, SWIGTYPE_p__CMPIObjectPath, 0);
  
    /* Ruby style method invocation */
#if defined(SWIGRUBY)
  
    /* de-camelize method name, might need 2time length */
    char *methodname = alloca(strlen(method) * 2 + 1);
    decamelize(method, methodname);
  
    /* access method arguments information via <decamelized>_args */
    int argsnamesize = strlen(methodname) + 5 + 1;
    char *argsname = alloca(argsnamesize); /* "<name>_args" */
    snprintf(argsname, argsnamesize, "%s_args", methodname);
  
    /* get the args array, gives names of input and output arguments */
    VALUE args = rb_funcall(((ProviderMIHandle*)self->hdl)->implementation, rb_intern(argsname), 0);
    if (check_ruby_type(args, T_ARRAY, "invoke: <method>_args must be Array",  &status, (ProviderMIHandle*)self->hdl ) < 0)
      return status;
  
    VALUE argsin = rb_ary_entry(args, 0); /* array of input arg names */
    if (check_ruby_type(argsin, T_ARRAY, "invoke: Input arguments must be Array", &status, (ProviderMIHandle*)self->hdl ) < 0)
      return status;

    int number_of_arguments = RARRAY_LEN(argsin) / 2;
    _SBLIM_TRACE(1,("%s -> %d input args", argsname, number_of_arguments));
    /* 3 args will be added by TargetCall, 2 args are added here, others are input args to function */
    VALUE *input = alloca((3 + 2 + number_of_arguments) * sizeof(VALUE));
    input[3] = _ctx;
    input[4] = _objName;
    /* loop over input arg names and types and get CMPIData via CMGetArg() */
    int i;
    for (i = 0; i < number_of_arguments; ++i) {
      const char *argname;
      CMPIData data;
      argname = target_charptr(rb_ary_entry(argsin, i*2));
      data = CMGetArg(in, argname, &status);
      if (status.rc != CMPI_RC_OK) {
	if ((data.state & CMPI_nullValue)
	    ||(data.state & CMPI_notFound)) {
	  input[5+i] = Target_Null;
	  continue;
	} 
	_SBLIM_TRACE(1,("Failed (rc %d) to get input arg %d:%s for %s", status.rc, i>>1, argname, method));
	return status;
      }
      input[5+i] = data_value(&data);
    }

    /* actual provider call, passes output args and return value via 'result' */
    VALUE result = TargetCall((ProviderMIHandle*)self->hdl, &status, methodname, -(2+number_of_arguments), input);

    /* argsout is array of [<return_type>, <output_arg_name>, <output_arg_type>, ... */
    VALUE argsout = rb_ary_entry(args, 1);
    CMPIValue value;
    CMPIType expected_type;
    CMPIType actual_type;
    if (check_ruby_type(argsout, T_ARRAY, "invoke: Output arguments must be Array", &status, (ProviderMIHandle*)self->hdl) < 0)
      return status;
    number_of_arguments = (RARRAY_LEN(argsout) - 1);

    if (number_of_arguments > 0) {
      /* if output args are defined, result must be an array
       * result[0] is the return value
       * result[1..n] are the output args in argsout order
       */
      if (check_ruby_type(result, T_ARRAY, "invoke: function with output arguments must return Array", &status, (ProviderMIHandle*)self->hdl) < 0)
        return status;

      /* loop over output arg names and types and set CMPIData via CMSetArg() */
      for (i = 0; i < number_of_arguments; i += 2) {
	const char *argname;
	argname = target_charptr(rb_ary_entry(argsout, i+1));
	expected_type = FIX2ULONG(rb_ary_entry(argsout, i+2));
	actual_type = target_to_value(rb_ary_entry(result, (i >> 1) + 1), &value, expected_type);
	status = CMAddArg(out, argname, &value, actual_type);
	if (status.rc != CMPI_RC_OK) {
	  _SBLIM_TRACE(1,("Failed (rc %d) to set output arg %d:%s for %s; expected type %x, actual type %x", status.rc, i>>1, argname, method, expected_type, actual_type));
	  return status;
	}
      }
      /* result[0] is the return value */
      result = rb_ary_entry(result, 0);

    }
    expected_type = FIX2ULONG(rb_ary_entry(argsout, 0));
    actual_type = target_to_value(result, &value, expected_type);
    CMReturnData(rslt, &value, actual_type);
    CMReturnDone(rslt);
  
#else
    Target_Type _rslt;
    Target_Type _in;
    Target_Type _out;
    _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    _in = SWIG_NewPointerObj((void*) in, SWIGTYPE_p__CMPIArgs, 0);
    _out = SWIG_NewPointerObj((void*) out, SWIGTYPE_p__CMPIArgs, 0);
    Target_Type _method;
    _method = string2target(method); 
    TargetCall((ProviderMIHandle*)self->hdl, &status, "invoke_method", 6, 
                                                               _ctx,
                                                               _rslt, 
                                                               _objName,
                                                               _method,
                                                               _in,
                                                               _out);
#endif
    TARGET_THREAD_END_BLOCK;
    _SBLIM_TRACE(1,("invokeMethod() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/*
 * authorizeFilter
 */

static CMPIStatus
authorizeFilter(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath,
        const char* owner)
{
    Target_Type _ctx;
    Target_Type _filter;
    Target_Type _classPath;
    Target_Type _className;
    Target_Type _owner;
    select_filter_exp *sfe = (select_filter_exp *)filter;

    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
  
    _SBLIM_TRACE(1,("authorizeFilter() called, ctx %p, filter %p, className %s, classPath %p, owner %s", ctx, filter, className, classPath, owner)); 

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    _filter = SWIG_NewPointerObj((void*) sfe->exp, SWIGTYPE_p__CMPISelectExp, 0);
    _classPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    _className = string2target(className); 
    _owner = string2target(owner); 

    TargetCall((ProviderMIHandle*)self->hdl, &status, "authorize_filter", 5, 
                                                               _ctx,
                                                               _filter, 
                                                               _className,
                                                               _classPath,
                                                               _owner);
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("authorizeFilter() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/*
 * activateFilter
 */

static CMPIStatus
activateFilter(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath,
        CMPIBoolean firstActivation)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
    Target_Type _ctx;
    Target_Type _filter;
    Target_Type _classPath;
    Target_Type _firstActivation;
    Target_Type _className;
    select_filter_exp *sfe = (select_filter_exp *)filter;

    _SBLIM_TRACE(1,("activateFilter() called, ctx %p, filter %p, className %s, classPath %p, firstActivation %d", ctx, filter, className, classPath, firstActivation));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    _filter = SWIG_NewPointerObj((void*) sfe->exp, SWIGTYPE_p__CMPISelectExp, 0);
    _classPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    _firstActivation = Target_Bool(firstActivation); 
    _className = string2target(className); 

    TargetCall((ProviderMIHandle*)self->hdl, &status, "activate_filter", 5, 
                                                               _ctx,
                                                               _filter, 
                                                               _className,
                                                               _classPath,
                                                               _firstActivation);
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("activateFilter() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/*
 * deActivateFilter
 */

static CMPIStatus
deActivateFilter(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath,
        CMPIBoolean lastActivation)
{
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
    Target_Type _ctx;
    Target_Type _filter;
    Target_Type _classPath;
    Target_Type _lastActivation;
    Target_Type _className;
    select_filter_exp *sfe = (select_filter_exp *)filter;
   
    _SBLIM_TRACE(1,("deActivateFilter() called, ctx %p, filter %p, className %s, classPath %p, lastActivation %d", ctx, filter, className, classPath, lastActivation));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    _filter = SWIG_NewPointerObj((void*) sfe->exp, SWIGTYPE_p__CMPISelectExp, 0);
    _classPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    _lastActivation = Target_Bool(lastActivation); 
    _className = string2target(className); 

    TargetCall((ProviderMIHandle*)self->hdl, &status, "deactivate_filter", 5, 
                                                               _ctx,
                                                               _filter, 
                                                               _className,
                                                               _classPath,
                                                               _lastActivation);
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("deActivateFilter() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/*
 * mustPoll
 * Note: sfcb doesn't support mustPoll. :(
 * http://sourceforge.net/mailarchive/message.php?msg_id=OFF38FF3F9.39FD2E1F-ONC1257385.004A7122-C1257385.004BB0AF%40de.ibm.com
 */

static CMPIStatus
mustPoll(
        CMPIIndicationMI* self,
        const CMPIContext* ctx,
        //const CMPIResult* rslt, TODO: figure out who is right: spec. vs. sblim
        const CMPISelectExp* filter,
        const char* className,
        const CMPIObjectPath* classPath)
{
    Target_Type _ctx;
    Target_Type _className;
    Target_Type _filter;
    Target_Type _classPath;
    select_filter_exp *sfe = (select_filter_exp *)filter;
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    //_SBLIM_TRACE(1,("mustPoll() called, ctx %p, rslt %p, filter %p, className %s, classPath %p", ctx, rslt, filter, className, classPath));
    _SBLIM_TRACE(1,("mustPoll() called, ctx %p, filter %p, className %s, classPath %p", ctx, filter, className, classPath));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);
    //Target_Type _rslt = SWIG_NewPointerObj((void*) rslt, SWIGTYPE_p__CMPIResult, 0);
    _filter = SWIG_NewPointerObj((void*) sfe->exp, SWIGTYPE_p__CMPISelectExp, 0);
    _classPath = SWIG_NewPointerObj((void*) classPath, SWIGTYPE_p__CMPIObjectPath, 0);
    _className = string2target(className); 

    TargetCall((ProviderMIHandle*)self->hdl, &status, "must_poll", 4, 
                                                               _ctx,
                                                               //_rslt,
                                                               _filter, 
                                                               _className,
                                                               _classPath);
    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("mustPoll() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/*
 * enableIndications
 */

static CMPIStatus
enableIndications(
        CMPIIndicationMI* self,
        const CMPIContext* ctx)
{
    Target_Type _ctx;
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("enableIndications() called, ctx %p", ctx));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);

    TargetCall((ProviderMIHandle*)self->hdl, &status, "enable_indications", 1, _ctx); 

    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("enableIndications() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;
}


/*
 * disableIndications
 */

static CMPIStatus 
disableIndications(
        CMPIIndicationMI* self,
        const CMPIContext* ctx)
{
    Target_Type _ctx;
    CMPIStatus status = {CMPI_RC_ERR_NOT_SUPPORTED, NULL};
   
    _SBLIM_TRACE(1,("disableIndications() called, ctx %p", ctx));

    TARGET_THREAD_BEGIN_BLOCK; 
    _ctx = SWIG_NewPointerObj((void*) ctx, SWIGTYPE_p__CMPIContext, 0);

    TargetCall((ProviderMIHandle*)self->hdl, &status, "disable_indications", 1, _ctx); 

    TARGET_THREAD_END_BLOCK; 
    _SBLIM_TRACE(1,("disableIndications() %s", (status.rc == CMPI_RC_OK)? "succeeded":"failed"));
    return status;

}


/***************************************************************************/

/* MI function tables */

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
    "associatonCmpi_Swig",  // miName
    AssocCleanup, 
    associators, 
    associatorNames, 
    references, 
    referenceNames, 
}; 


static CMPIInstanceMIFT InstanceMIFT__={ 
    CMPICurrentVersion, 
    CMPICurrentVersion, 
    "instanceCmpi_Swig",  // miName
    InstCleanup, 
    EnumInstanceNames, 
    EnumInstances, 
    GetInstance, 
    CreateInstance, 
    SetInstance, 
    DeleteInstance, 
    ExecQuery, 
}; 


static int
createInit(ProviderMIHandle* miHdl, CMPIStatus* st)
{
    const char *trace_level = getenv("CMPI_BINDINGS_TRACE_LEVEL");
    _SBLIM_TRACE(1,(">>>>> createInit() called, broker %p, miname= %s (ctx=%p), status %p, trace_level %s", miHdl->broker, miHdl->miName, miHdl->context, st, trace_level?trace_level:"(null)"));

    if (trace_level) {
      cmpi_bindings_trace_level = *trace_level - '0';
      _SBLIM_TRACE(0,("tracing at level %d", cmpi_bindings_trace_level));
    }
    return TargetInitialize(miHdl, st);
}


#define SWIG_CMPI_MI_FACTORY(ptype) \
CMPI##ptype##MI* _Generic_Create_##ptype##MI(const CMPIBroker* broker, \
        const CMPIContext* context, const char* miname, CMPIStatus* st)\
{ \
    CMPI##ptype##MI *mi; \
    ProviderMIHandle *hdl; \
    _SBLIM_TRACE(1, (">>>>> in FACTORY: CMPI"#ptype"MI* _Generic_Create_"#ptype"MI... miname=%s", miname)); \
    hdl = (ProviderMIHandle*)malloc(sizeof(ProviderMIHandle)); \
    if (hdl) { \
        hdl->implementation = Target_Null; \
        hdl->miName = strdup(miname); \
        hdl->broker = broker; \
        hdl->context = context; \
    } \
    if (createInit(hdl, st) != 0) { \
        free(hdl->miName); \
        free(hdl); \
        return NULL; \
    } \
    mi = (CMPI##ptype##MI*)malloc(sizeof(CMPI##ptype##MI)); \
    if (mi) { \
        mi->hdl = hdl; \
        mi->ft = &ptype##MIFT__; \
    } \
    ++_MI_COUNT; \
    _SBLIM_TRACE(1, (">>>>> CMPI"#ptype"MI(%s) _MI_COUNT %d: returning mi=%p : miHdl=%p, hdl->implementation=%p, mi->ft=%p", miname, _MI_COUNT, mi, mi->hdl, hdl->implementation, mi->ft)); \
    return mi; \
}

SWIG_CMPI_MI_FACTORY(Instance)
SWIG_CMPI_MI_FACTORY(Method)
SWIG_CMPI_MI_FACTORY(Association)
SWIG_CMPI_MI_FACTORY(Indication)

#undef _CMPI_SETFAIL
