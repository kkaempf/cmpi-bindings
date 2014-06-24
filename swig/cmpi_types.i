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

# cmpift.i
#
# swig bindings for CMPI function tables
#

#
# Prevent default con-/destructors for all types
# CMPI types are handled through function tables
# and the broker.
#

%nodefault _CMPIError;
%rename(CMPIError) _CMPIError;
typedef struct _CMPIError {} CMPIError;

%nodefault _CMPIResult;
%rename(CMPIResult) _CMPIResult;
typedef struct _CMPIResult {} CMPIResult;

%nodefault _CMPIMsgFileHandle;
%rename(CMPIMsgFileHandle) _CMPIMsgFileHandle;
typedef struct _CMPIMsgFileHandle {} CMPIMsgFileHandle;

%nodefault _CMPIObjectPath;
%rename(CMPIObjectPath) _CMPIObjectPath;
typedef struct _CMPIObjectPath {} CMPIObjectPath;

%nodefault _CMPIInstance;
%rename(CMPIInstance) _CMPIInstance;
typedef struct _CMPIInstance {} CMPIInstance;

%nodefault _CMPIArgs;
%rename(CMPIArgs) _CMPIArgs;
typedef struct _CMPIArgs {} CMPIArgs;

%nodefault _CMPISelectExp;
%rename(CMPISelectExp) _CMPISelectExp;
typedef struct _CMPISelectExp {} CMPISelectExp;

%nodefault _CMPISelectCond;
%rename(CMPISelectCond) _CMPISelectCond;
typedef struct _CMPISelectCond {} CMPISelectCond;

%nodefault _CMPISubCond;
%rename(CMPISubCond) _CMPISubCond;
typedef struct _CMPISubCond {} CMPISubCond;

%nodefault _CMPIPredicate;
%rename(CMPIPredicate) _CMPIPredicate;
typedef struct _CMPIPredicate {} CMPIPredicate;

%nodefault _CMPIEnumeration;
%rename(CMPIEnumeration) _CMPIEnumeration;
typedef struct _CMPIEnumeration {} CMPIEnumeration;

%nodefault _CMPIArray;
%rename(CMPIArray) _CMPIArray;
typedef struct _CMPIArray {} CMPIArray;

%nodefault _CMPIString;
%rename(CMPIString) _CMPIString;
typedef struct _CMPIString {} CMPIString;

%nodefault _CMPIContext;
%rename(CMPIContext) _CMPIContext;
typedef struct _CMPIContext {} CMPIContext;

%nodefault _CMPIDateTime;
%rename(CMPIDateTime) _CMPIDateTime;
typedef struct _CMPIDateTime {} CMPIDateTime;

#-----------------------------------------------------
#
# CMPIException
#
#-----------------------------------------------------

%nodefault _CMPIException;
%rename(CMPIException) CMPIException;
typedef struct _CMPIException {} CMPIException;

/*
 *
 * Container for a fault, contains numeric error_code and textual
 * description
 *
 */
%extend _CMPIException 
{
  _CMPIException() 
  {
      return (CMPIException*)calloc(1, sizeof(CMPIException));
  }

  ~_CMPIException() 
  {
      free($self->description);
      free($self);
  }
#if defined(SWIGRUBY)
%rename("error_code") get_error_code();
#endif
  /*
   * Numerical error code
   *
   */
  int get_error_code() 
  {
    return $self->error_code;
  }

#if defined(SWIGRUBY)
%rename("description") get_description();
#endif
  /*
   * Textual error description
   *
   */
  const char* get_description() 
  {
    return $self->description;
  }
}

#-----------------------------------------------------
#
# %exception
#
#-----------------------------------------------------

%exception 
{
    _clr_raised();
    $action
    if (_get_raised())
    {
        _clr_raised();
#ifdef SWIGPYTHON
#if SWIG_VERSION < 0x020000
        SWIG_PYTHON_THREAD_END_ALLOW;
#endif
#endif
        SWIG_fail;
    }
}

#-----------------------------------------------------
#
# CMPIError
#

/*
 * Document-class: CMPIError
 *
 */
%extend _CMPIError 
{
  ~_CMPIError() { }

/* Gets the type of this Error */
  CMPIErrorType type() {
    return CMGetErrorType($self, NULL);
  }

#if defined(SWIGRUBY)
  %rename("type=") set_type(const CMPIErrorType et);
#endif
  /* Sets the error type of this error object. */
  void set_type(const CMPIErrorType et) {
    CMSetErrorType($self, et);
  }

/* Returns a string which describes the alternate error type. */
  %newobject other_type;
  const char *other_type() {
    CMPIString *s = CMGetOtherErrorType($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }

#if defined(SWIGRUBY)
  %rename("other_type=") set_other_type(const char *ot);
#endif
  /* Sets the 'other' error type of this error object. */
  void set_other_type(const char *ot) {
    CMSetOtherErrorType($self, ot);
  }

  /* Returns a string which describes the owning entity. */
  %newobject owning_entity;
  const char *owning_entity() {
    CMPIString *s = CMGetOwningEntity($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
  
  /* Returns a string which is the message ID. */
  %newobject message_id;
  const char *message_id() {
    CMPIString *s = CMGetMessageID($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
  
  /* Returns a string combinating an error message. */
  %newobject message;
  const char *message() {
    CMPIString *s = CMGetErrorMessage($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
  
  /* Returns the perceieved severity of this error. */
  CMPIErrorSeverity severity() {
    return CMGetPerceivedSeverity($self, NULL);
  }
  
  /* Returns the probable cause of this error. */
  CMPIErrorProbableCause probable_cause() {
    return CMGetProbableCause($self, NULL);
  }
  
#if defined(SWIGRUBY)
  %rename("probable_cause=") set_probable_cause(const char *pcd);
#endif
  /* Sets the description of the probable cause. */
  void set_probable_cause(const char *pcd) {
    CMSetProbableCauseDescription($self, pcd);
  }
  
  /* Returns a string which describes the probable cause. */
  %newobject probable_cause_description;
  const char *probable_cause_description() {
    CMPIString *s = CMGetProbableCauseDescription($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
  
  /* Returns an array of strings which describes recomended actions. */
  CMPIArray *recommended_actions() {
    return CMGetRecommendedActions($self, NULL);
  }
  
#if defined(SWIGRUBY)
  %rename("recommended_actions=") set_recommended_actions(const CMPIArray* ra);
#endif
  /* Sets the recomended actions array. */
  void set_recommended_actions(const CMPIArray* ra) {
    CMSetRecommendedActions($self, ra);
  }
  
  /* Returns a string which describes the Error source. */
  %newobject source;
  const char *source() {
    CMPIString *s = CMGetErrorSource($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
  
#if defined(SWIGRUBY)
  %rename("source=") set_source(const char *es);
#endif
  /* Specifies a string which specifes The identifying information of
     the entity (i.e., the instance) generating the error. */
  void set_source(const char *es) {
    CMSetErrorSource($self, es);
  }
  
  /* Returns a the format that the error src is in. */
  CMPIErrorSrcFormat source_format() {
    return CMGetErrorSourceFormat($self, NULL);
  }

#if defined(SWIGRUBY)
  %rename("source_format=") set_source_format(const CMPIErrorSrcFormat esf);
#endif
  /* Sets the source format of the error object. */
  void set_source_format(const CMPIErrorSrcFormat esf) {
    CMSetErrorSourceFormat($self, esf);
  }
  
  /* Returns a string which describes the 'other' format, only
     available if the error source is OTHER. */
  %newobject other_format;
  const char *other_format() {
    CMPIString *s = CMGetOtherErrorSourceFormat($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
  
#if defined(SWIGRUBY)
  %rename("other_format=") set_other_format(const char *oesf);
#endif
  /* specifies A string defining "Other" values for ErrorSourceFormat */
  void set_other_format(const char *oesf) {
    CMSetOtherErrorSourceFormat($self, oesf);
  }
  
  /* Returns the status code of this error. */
  CMPIrc status_code() {
    return CMGetCIMStatusCode($self, NULL);
  }
  
  /* Returns a string which describes the status code error. */
  %newobject status_description;
  const char *status_description() {
    CMPIString *s = CMGetCIMStatusCodeDescription($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
  
#if defined(SWIGRUBY)
  %rename("status_description=") set_status_description(const char *cd);
#endif
  /* Sets the description of the status code. */
  void set_status_description(const char *cd) {
    CMSetCIMStatusCodeDescription($self, cd);
  }
  
  /* Returns an array which contains the dynamic content of the message. */
  CMPIArray *message_arguments() {
    return CMGetMessageArguments($self, NULL);
  }

#if defined(SWIGRUBY)
  %rename("message_arguments=") set_message_arguments(CMPIArray* ma);
#endif
  /* Sets an array of strings for the dynamic content of the message. */
  void set_message_arguments(CMPIArray* ma) {
    CMSetMessageArguments($self, ma);
  }
}

#-----------------------------------------------------
#
# CMPIResult
#

/*
 * Document-class: CMPIResult
 *
 */
%extend _CMPIResult 
{
  /* no con-/destructor, the broker handles this */

  /* Add the +instance+ to the result */
  void return_instance(CMPIInstance *instance_disown) 
  {
    RAISE_IF(CMReturnInstance($self, instance_disown));
  }

  /* Add the +objectpath+ to the result */
  void return_objectpath(CMPIObjectPath *path_disown)
  {
    RAISE_IF(CMReturnObjectPath($self, path_disown));
  }

  /* Add typed value to the result */
  void return_data(const CMPIValue* value, const CMPIType type) 
  {
    RAISE_IF(CMReturnData($self, value, type));
  }

  void done() 
  {
    RAISE_IF(CMReturnDone($self));
  }
}

#-----------------------------------------------------
#
# CMPIObjectPath
#

/*
 * Document-class: CMPIObjectPath
 *
 */
%extend _CMPIObjectPath 
{
#if HAVE_CMPI_BROKER
#if defined(SWIGRUBY)
  _CMPIObjectPath(VALUE ns_t, VALUE cn_t = Qnil) /* Can't use Target_Type here: this is SWIG level, not C */
#else
  _CMPIObjectPath(const char *ns, const char *cn = NULL)
#endif
#else
  _CMPIObjectPath(const CMPIBroker* broker, const char *ns, const char *cn = NULL)
#endif
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
#if HAVE_CMPI_BROKER
    const CMPIBroker* broker = cmpi_broker();
#endif
#if defined(SWIGRUBY)
    const char *ns = target_charptr(ns_t);
    const char *cn = target_charptr(cn_t);
#endif

    CMPIObjectPath *path;
    if (cn == NULL) { /* assume creating from string representation */
      /* parse <namespace>:<classname>[.<key>=<value>[,<key>=<value>]...] */
      CMPIValue value;
      const char *ptr;
      /* find and extract namespace */
/*      fprintf(stderr, "CMPIObjectPath.new(%s)\n", ns); */
      ptr = strchr(ns, ':');
      if (ptr == NULL) {
 	path = NULL;
	SWIG_exception(SWIG_ValueError, "Missing ':' between namespace and classname");
      }
      ns = strndup(ns, ptr-ns);
      /* find and extract classname */
      cn = ++ptr;
      ptr = strchr(cn, '.');
      if (ptr != NULL) {      /* key is optional */
        cn = strndup(cn, ptr-cn);
	++ptr;
      }
      path = CMNewObjectPath( broker, ns, cn, &st );
      RAISE_IF(st);
      
      /* find and extract properties (if any) */

      /*
       * FIXME: lookup the class definition and add the keys with
       * properly typed values
       */
      while (ptr && *ptr) {
        const char *key;
	const char *val;
	
	key = ptr;
	ptr = strchr(key, '=');
	if (ptr == NULL) {
 	  path = NULL;
	  SWIG_exception(SWIG_ValueError, "Missing '=' between property name and value");
        }
	key = strndup(key, ptr-key);
	val = ++ptr;
	if (*val == '"') {
	  val++;
	  ptr = val;
	  for (;*ptr;) {
	    ptr = strchr(ptr, '"');
	    if (ptr == NULL) {
	      path = NULL;
	      SWIG_exception(SWIG_ValueError, "Missing '\"' at end of string value");
	    }
	    if (*(ptr-1) != '\\') /* not escaped " */
	      break;
	    ptr++;
	  }
	  val = strndup(val, ptr-val);
	  ++ptr; /* skip " */
          if (*ptr) { /* not EOS */
            if (*ptr++ != ',') {
              SWIG_exception(SWIG_ValueError, "Missing ',' after string value");
            }
          }
	}
	else {
	  ptr = strchr(ptr, ',');
	  if (ptr) {
	    val = strndup(val, ptr-val);
	    ++ptr;
	  }
	  else {
	    val = strdup(val);
          }
	}
	value.string = CMNewString(broker, val, &st);
	RAISE_IF(st);
	free((void *)val);
	CMAddKey(path, key, &value, CMPI_string);
	CMRelease(value.string);
	free((void *)key);
      }
    }
    else {
      path = CMNewObjectPath( broker, ns, cn, &st );
      RAISE_IF(st);
    }
#if !defined (SWIGRUBY)
fail:
#endif
    return path;
  }

  ~_CMPIObjectPath() 
  { 
/* FIXME    CMRelease( $self ); */
  }

  /**
   * Create an independent copy of this ObjectPath object. The resulting
   *          object must be released explicitly.
FIXME: if clone() is exposed, release() must also
  CMPIObjectPath *clone() {
    return $self->ft->clone($self, NULL);
  }
   */     

#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  /* Return string representation */
  %newobject string;
  const char *string()
  {
    CMPIString *s = $self->ft->toString($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
  
#if defined(SWIGRUBY)
  %alias set "[]=";
  /*
   * Property setting in Ruby
   *  Set property of ObjectPath by name and type
   *  type is optional for string and boolean
   * reference[:propname] = data    # set by name (symbol)
   * reference[:propname, CMPI::uint16] = data    # set by name (symbol)
   * reference["propname"] = data   # set by name (string)
   */
  CMPIStatus set(VALUE property, VALUE data, VALUE expected_type = Qnil)
  {
    const char *name;
    CMPIValue value;
    CMPIType actual_type;
    CMPIType type;
    CMPIStatus status;
    if (NIL_P(expected_type)) {
      type = CMPI_null;
    }
    else if (FIXNUM_P(expected_type)) {
      type = FIX2LONG(expected_type);
    }
    else {
      SWIG_exception(SWIG_ValueError, "bad expected_type");
    }
    name = target_charptr(property);
    if (NIL_P(data)) {
      actual_type = type; /* prevent type error */
      value.chars = NULL;
    }
    else {
      actual_type = target_to_value(data, &value, type);
    }
/*    fprintf(stderr, "CMPIObjectPath.%s <expected %04x, actual %04x>\n",name, type, actual_type); */
    status = CMAddKey($self, name, &value, actual_type);
    RAISE_IF(status);
    return status;
  }
#endif

  /* Adds/replaces a named key property.
   * name: Key property name.
   * value: Address of value structure.
   * type: Value type.
   */
  void add_key(
      const char *name, 
      const CMPIValue* value, 
      const CMPIType type) 
  {
    RAISE_IF(CMAddKey($self, name, value, type));
  }

#if defined(SWIGRUBY)
  %rename("key") get_key(const char *name);
  %alias get_key "[]";
#endif
  /* Gets a named key property value.
   * name: Key property name.
   */
#if defined(SWIGRUBY)
  VALUE get_key(VALUE property) 
#else
  CMPIData get_key(const char *name) 
#endif
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;
#if defined(SWIGRUBY)
    const char *name;
    name = target_charptr(property);
#endif
    result = CMGetKey($self, name, &st);
    /* key not found is ok, will return NULL */
    if (st.rc != CMPI_RC_ERR_NOT_FOUND) {
      RAISE_IF(st);
    }
#if defined(SWIGRUBY)
    return data_value(&result);
#else
    return result;
#endif
  }

  %newobject get_key_at;
#if defined (SWIGRUBY)
  %rename("key_at") get_key_at(int index);
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
#if defined (SWIGPERL)
  SV* 
#endif
  /* Gets a key property [value,name] defined by its index.
   * name: [out] Key property name
   */
  __type get_key_at(int index) {
    Target_Type tdata;
    CMPIString *s = NULL;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data = CMGetKeyAt($self, index, &s, &st);
    Target_Type result;
    if (st.rc)
    {
        RAISE_IF(st);
	result = Target_Null;
	Target_INCREF(result);
        return result;
    }

    TARGET_THREAD_BEGIN_BLOCK;
    tdata = data_data(&data);
#if defined (SWIGPYTHON)
    result = PyTuple_New(2);
    PyTuple_SetItem(result, 0, tdata);
    PyTuple_SetItem(result, 1, PyString_FromString(CMGetCharPtr(s)));
#else
    result = Target_SizedArray(2);
    Target_Append(result, tdata);
    Target_Append(result, Target_String(CMGetCharPtr(s)));
#endif
    TARGET_THREAD_END_BLOCK;
    CMRelease(s);
    return result;
  }

  /* Gets the number of key properties contained in this ObjectPath. */
  int key_count() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    int result;

    result = CMGetKeyCount($self, &st);
    RAISE_IF(st);

    return result;
  }

#if defined(SWIGRUBY)
  /* iterate over keys as [<value>,<name>] pairs */
  void each()
  {
    int i;
    int count = CMGetKeyCount($self, NULL);
    CMPIString *name;
    for (i = 0; i < count; ++i )
    {
      VALUE yield = rb_ary_new2(2);
      name = NULL;
      CMPIData data = CMGetKeyAt($self, i, &name, NULL);
      VALUE rbdata = data_data(&data);
      rb_ary_push(yield, rbdata);
      rb_ary_push(yield, rb_str_new2(CMGetCharPtr(name)));
      CMRelease(name);
      rb_yield(yield);
    }
  }
#endif
#if defined(SWIGPYTHON)
      %pythoncode %{
        def keys(self):
            for i in xrange(0, self.key_count()):
                yield self.get_key_at(i)
      %}
#endif

  /* Set/replace namespace and classname components from +src+. */
  void replace_from(const CMPIObjectPath * src) 
  {
    RAISE_IF(CMSetNameSpaceFromObjectPath($self, src));
  }

  /* Set/replace hostname, namespace and classname components from +src+. 
  */
  void replace_all_from(const CMPIObjectPath * src) 
  {
    RAISE_IF(CMSetHostAndNameSpaceFromObjectPath($self, src));
  }

  /* Get class qualifier value.
   * +qName+: Qualifier name.
   */
  CMPIData qualifier(const char *qname) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetClassQualifier($self, qname, &st);
    RAISE_IF(st);

    return result;
  }

  /* Get property qualifier value.
   * +pName+: Property name.
   * +qName+: Qualifier name.
   */
  CMPIData property_qualifier(const char *pName, const char *qName) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetPropertyQualifier($self, pName, qName, &st);
    RAISE_IF(st);

    return result;
  }

  /* Get method qualifier value.
   * mName: Method name.
   * qName: Qualifier name.
   */
  CMPIData method_qualifier(const char *methodName, const char *qName) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetMethodQualifier($self, methodName, qName, &st);
    RAISE_IF(st);

    return result;
  }

  /* Get method parameter qualifier value.
   * mName: Method name.
   * pName: Parameter name.
   * qName: Qualifier name.
   */
  CMPIData parameter_qualifier(
      const char *mName, 
      const char *pName, 
      const char *qName) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetParameterQualifier($self, mName, pName, qName, &st);
    RAISE_IF(st);

    return result;
  }

  /* Get the namespace component. */
  %newobject namespace;
  const char *namespace() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIString *s = CMGetNameSpace($self, &st);
    const char* result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }

  /* Set/replace the namespace component. */
#if defined(SWIGRUBY)
  %rename("namespace=") set_namespace(const char *nm);
#endif
  void set_namespace(const char *nm) 
  {
    RAISE_IF(CMSetNameSpace($self, nm));
  }

  /* Set/replace the hostname component. */
#if defined(SWIGRUBY)
  %rename("hostname=") set_hostname(const char *hostname);
#endif
  void set_hostname(const char *hostname) 
  {
    RAISE_IF(CMSetHostname($self, hostname));
  }

  /* Get the hostname component. */
  %newobject hostname;
  const char *hostname() 
  {
    const char* result;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIString *s = CMGetHostname($self, &st);
    RAISE_IF(st);
    result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }

  /* Set/replace the classname component. */
#if defined(SWIGRUBY)
  %rename("classname=") set_classname(const char *classname);
#endif
  void set_classname(const char *classname) 
  {
    RAISE_IF(CMSetClassName($self, classname));
  }

  /* Get the classname component. */
  %newobject classname;
  const char *classname() 
  {
    const char* result;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIString *s = CMGetClassName($self, &st);
    RAISE_IF(st);
    result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
}

#-----------------------------------------------------
#
# CMPIInstance
#

/*
 * Document-class: CMPIInstance
 *
 */
%extend _CMPIInstance 
{
  /* path: ObjectPath containing namespace and classname. */
#if HAVE_CMPI_BROKER
  _CMPIInstance(CMPIObjectPath *path)
#else
  _CMPIInstance(const CMPIBroker* broker, CMPIObjectPath *path)
#endif
  {
    CMPIInstance *instance;
    CMPIStatus st = { CMPI_RC_OK, NULL };
#if HAVE_CMPI_BROKER
    const CMPIBroker* broker = cmpi_broker();
#endif
    instance = CMNewInstance(broker, path, &st);
    RAISE_IF(st);
    return instance;
  }

  ~_CMPIInstance() 
  { 
/* FIXME    CMRelease( $self ); */
  }

#if defined(SWIGRUBY)
  %alias set "[]=";
  /*
   * Property setting in Ruby
   *   set property of Instance by name and type
   * instance[:propname] = data    # set by name (symbol)
   * instance[:propname, data] = CMPI::uint16    # set by name (symbol)
   * instance["propname"] = data   # set by name (string)
   */
  CMPIStatus set(VALUE property, VALUE data, VALUE expected_type = Qnil)
  {
    const char *name;
    CMPIValue value;
    CMPIType actual_type;
    CMPIType type;
    CMPIStatus status;
    if (NIL_P(expected_type)) {
      type = CMPI_null;
    }
    else if (FIXNUM_P(expected_type)) {
      type = FIX2LONG(expected_type);
    }
    else {
      SWIG_exception(SWIG_ValueError, "bad expected_type");
    }
    name = target_charptr(property);
    if (NIL_P(data)) {
      actual_type = type; /* prevent type error */
      value.chars = NULL;
    }
    else {
      actual_type = target_to_value(data, &value, type);
    }
/*    fprintf(stderr, "CMPIInstance.%s <expected %04x, actual %04x>\n",name, type, actual_type); */
    status = CMSetProperty($self, name, &value, actual_type);
    RAISE_IF(status);
    return status;
  }
#endif

  /* Adds/replaces a named Property.
   * name: Entry name.
   * value: Address of value structure.
   * type: Value type.
   */
  void set_property(
      const char *name, 
      const CMPIValue * value, 
      const CMPIType type) 
  {
    RAISE_IF(CMSetProperty($self, name, value, type));
  }

#if defined(SWIGRUBY)
  %alias get "[]";
  /*
   * get a named property value
   * Property access in Ruby:
   * data = instance[:propname]     # access by name (symbol)
   * data = instance["propname"     # access by name (string)
   * data = instance[1]             # access by index
   *
   * See get_property_at to retrieve property name and value
   */
  VALUE get(VALUE property)
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data;
    if (FIXNUM_P(property)) {
      data = CMGetPropertyAt($self, FIX2ULONG(property), NULL, &st);
    }
    else {
      const char *name;
      name = target_charptr(property);

      data = CMGetProperty($self, name, &st);
    }
    RAISE_IF(st);
    return data_value(&data);
  }

#else /* !defined(SWIGRUBY) */

  /* Get property by name */
  CMPIData get_property(const char *name) 
  {
    CMPIData result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetProperty($self, name, &st);
    RAISE_IF(st);

    return result;
  }
#endif

#if defined (SWIGRUBY)
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
#if defined (SWIGPERL)
  SV * 
#endif
  /** Gets a Property name and value defined by its index.
   * index: Position in the internal Data array.
   */
  __type get_property_at(int index) 
  {
    Target_Type tdata;
    Target_Type result;
    CMPIString *s = NULL;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data = CMGetPropertyAt($self, index, &s, &st);
    if (st.rc)
    {
        RAISE_IF(st);
	result = Target_Null;
	Target_INCREF(result);
        return result;
    }
/*    fprintf(stderr, "CMGetPropertyAt(%d) -> name %s, data type %x, state %x, value %p\n", index, CMGetCharPtr(s), data.type, data.state, data.value);
    fflush(stderr);
    */
    TARGET_THREAD_BEGIN_BLOCK;
    tdata = data_data(&data);
#if defined (SWIGPYTHON)
    result = PyTuple_New(2);
    PyTuple_SetItem(result, 0, tdata);
    PyTuple_SetItem(result, 1, PyString_FromString(CMGetCharPtr(s)));
#else
    result = Target_SizedArray(2);
    Target_Append(result, tdata);
    Target_Append(result, Target_String(CMGetCharPtr(s)));
#endif
    TARGET_THREAD_END_BLOCK;
    CMRelease(s);
    return result;
  }

#if defined(SWIGRUBY)
  %alias property_count "size";
#endif
  /* Gets the number of properties contained in this Instance. */
  int property_count() 
  {
    int result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetPropertyCount($self, &st);
    RAISE_IF(st);

    return result;
  }

  /* Generates an ObjectPath out of the namespace, classname and
   *  key propeties of this Instance.
   */
  CMPIObjectPath *objectpath() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIObjectPath* result;

    result = CMGetObjectPath($self, &st);
    RAISE_IF(st);
    /* fprintf(stderr, "<%p>.objectpath = %p\n", $self, result); */

    return result;
  }

#if defined(SWIGRUBY)
  %alias set_objectpath "objectpath=";
#endif
  /* Replaces the ObjectPath of the instance.
   *  The passed objectpath shall contain the namespace, classname,
   *   as well as all keys for the specified instance.
   */
  void set_objectpath(const CMPIObjectPath *path) 
  {
    RAISE_IF(CMSetObjectPath($self, path));
  }

  /* Directs CMPI to ignore any setProperty operations for this
   *        instance for any properties not in this list.
   * properties: If not NULL, the members of the array define one
   *         or more Property names to be accepted by setProperty operations.
   */
  void set_property_filter(const char **properties) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIObjectPath* cop;
    CMPICount n;
    CMPICount i;
    char** props;

    /* Make copy of property list (we may modify it) */
    
    props = string_array_clone((char**)properties);

#if 0
    string_array_print(props);
#endif

    /* Pegasus requires that the keys be in the property list, else it
     * throws an exception. To work around, add key properties to property
     * list.
     */

    if (!(cop = CMGetObjectPath($self, &st)) || st.rc)
    {
        st.rc = CMPI_RC_ERR_FAILED;
        RAISE_IF(st);
        string_array_free(props);
        return;
    }

    n = CMGetKeyCount(cop, &st);

    if (st.rc)
    {
        RAISE_IF(st);
        string_array_free(props);
        return;
    }

    for (i = 0; i < n; i++)
    {
        CMPIString* pn = NULL;
        const char* str;

        (void)CMGetKeyAt(cop, i, &pn, &st); /* get key name at i */

        if (st.rc)
        {
            RAISE_IF(st);
            string_array_free(props);
            return;
        }

        str = CMGetCharsPtr(pn, &st);

        if (st.rc)
        {
            RAISE_IF(st);
            string_array_free(props);
            return;
        }

        if (string_array_find_ignore_case(props, str) == NULL)
            props = string_array_append(props, str);
    }

#if 0
    string_array_print(props);
#endif

    RAISE_IF(CMSetPropertyFilter($self, (const char**)props, NULL));

    string_array_free(props);
  }

  /* Add/replace a named Property value and origin
   * name: is a string containing the Property name.
   * value: points to a CMPIValue structure containing the value
   *        to be assigned to the Property.
   * type: is a CMPIType structure defining the type of the value.
   * origin: specifies the instance origin.  If NULL, then
             no origin is attached to  the property
   */
  void set_property_with_origin(
      const char *name,
     const CMPIValue *value, 
     CMPIType type, 
     const char* origin)
  {
    RAISE_IF(CMSetPropertyWithOrigin($self, name, value, type, origin));
  }
}

#-----------------------------------------------------
#
# CMPIArgs

/*
 * CMPI Arguments
 *
 * Arguments are passed in an ordered Hash-like fashion (name/value pairs) and can
 * be accessed by name or by index
 *
 */
%extend _CMPIArgs 
{
  ~_CMPIArgs() 
  { 
    CMRelease( $self );
  }
  
  /*
   * Adds/replaces a named argument.
   *
   * call-seq:
   *   set("arg_name", arg_value, arg_type)
   *
   */
  void set(char *name, const CMPIValue * value, const CMPIType type) 
  {
    RAISE_IF(CMAddArg($self, name, value, type));
  }

#if defined(SWIGRUBY)
  %alias get "[]";
#endif
  /*
   * Gets a named argument value.
   *
   */
  CMPIData get(const char *name) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetArg($self, name, &st);
    RAISE_IF(st);

    return result;
  }

#if defined (SWIGRUBY)
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
#if defined (SWIGPERL)
  SV * 
#endif
  /*
   * Get an Argument value by index.
   * Returns a pair of value and name
   *
   * call-seq:
   *   get_arg_at(1) -> [ "name", value ]
   * ** Python returns value, name pair !
   *
   */
  __type get_arg_at(int index) 
  {
    Target_Type tdata;
    Target_Type result;
    CMPIString *s = NULL;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data = CMGetArgAt($self, index, &s, &st);

    if (st.rc)
    {
        RAISE_IF(st);
	result = Target_Null;
	Target_INCREF(result);
        return result;
    }
    TARGET_THREAD_BEGIN_BLOCK;
    tdata = data_data(&data);
#if defined (SWIGPYTHON)
    result = PyTuple_New(2);
    PyTuple_SetItem(result, 0, tdata);
    PyTuple_SetItem(result, 1, PyString_FromString(CMGetCharPtr(s)));
#else
    result = Target_SizedArray(2);
    Target_Append(result, Target_String(CMGetCharPtr(s)));
    Target_Append(result, tdata);
#endif
    TARGET_THREAD_END_BLOCK;
    CMRelease(s);
    return result;
  }

#if defined(SWIGRUBY)
  %alias arg_count "size";
#endif
  /*
   * Gets the number of arguments contained in this Args.
   *
   */
  int arg_count() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    int result;

    result = CMGetArgCount($self, &st);
    RAISE_IF(st);

    return result;
  }
}

#-----------------------------------------------------
#
# CMPISelectExp

/*
 * This structure encompasses queries
 *       and provides mechanism to operate on the query.
 */
%extend _CMPISelectExp {
#if HAVE_CMPI_BROKER
  _CMPISelectExp(const char *query, const char *language, char **keys = NULL)
#else
  _CMPISelectExp(const CMPIBroker* broker, const char *query, const char *language, char **keys = NULL)
#endif
  {
#if HAVE_CMPI_BROKER
    const CMPIBroker* broker = cmpi_broker();
#endif
    return (CMPISelectExp *)create_select_filter_exp(broker, query, language, keys);
  }

  ~_CMPISelectExp()
  {
    release_select_filter_exp((select_filter_exp *)$self);
  }

#if defined(SWIGRUBY)
  %typemap(out) int match
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int match(CMPIInstance *instance)
  {
    CMPIStatus st = {CMPI_RC_OK, NULL};
    select_filter_exp *sfe = (select_filter_exp *)$self;
    CMPIBoolean res = CMEvaluateSelExp(sfe->exp, instance, &st);
    RAISE_IF(st);
    return res;
  }

  char **filter() {
    select_filter_exp *sfe = (select_filter_exp *)$self;
    return sfe->filter;
  }

  /* Return string representation */
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  %newobject string;
  const char* string() {
    select_filter_exp *sfe = (select_filter_exp *)$self;
    CMPIString *s = CMGetSelExpString(sfe->exp, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
}

#-----------------------------------------------------
#
# CMPISelectCond

/*
 * Select conditions
 *
 *
 */
%extend _CMPISelectCond {
  /* Return string representation */
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  %newobject string;
  const char* string() {
    const CMPIBroker* broker = cmpi_broker();
    CMPIString *s = CDToString(broker, $self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
#endif
}

#-----------------------------------------------------
#
# CMPISubCond

/*
 * Sub Conditions
 *
 *
 */
%extend _CMPISubCond {
}

#-----------------------------------------------------
#
# CMPIPredicate

/*
 * Predicate
 *
 *
 */
%extend _CMPIPredicate {
  /* Return string representation */
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  %newobject string;
  const char* string() {
    const CMPIBroker* broker = cmpi_broker();
    CMPIString *s = CDToString(broker, $self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
#endif
}

#-----------------------------------------------------
#
# CMPIEnumeration

/*
 * Enumeration provide a linked-list type access to multiple elements
 *
 *
 */
%extend _CMPIEnumeration 
{
  ~_CMPIEnumeration() {
    CMRelease( $self );
  }
#if defined(SWIGPYTHON)
/* Warning(314): 'next' is a Perl and Ruby keyword; keep 'next' in
Python for compatibility */
%rename("next") next_element;
#endif
  CMPIData next_element()
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CMGetNext($self, &st);
    RAISE_IF(st);

    return result;
  }

#if defined(SWIGRUBY)
  %typemap(out) int hasNext
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
  %rename("has_next") hasNext;
#endif
  int hasNext() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    int result;

    result = CMHasNext($self, &st);
    RAISE_IF(st);
    return result;
  }

#if defined(SWIGRUBY)
  %rename("to_ary") toArray;
#endif
  CMPIArray *toArray() 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIArray* result;

    result = CMToArray($self, NULL);
    RAISE_IF(st);

    return result;
  }

}

#-----------------------------------------------------
#
# CMPIArray

/*
 * Array of equally-typed elements
 *
 *
 */
%extend _CMPIArray 
{
  ~_CMPIArray() {
    CMRelease( $self );
  }	
  /* Return string representation */
#if HAVE_CMPI_BROKER
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  %newobject string;
  const char* string()
  {
    const CMPIBroker* broker = cmpi_broker();
    CMPIString *s = CDToString(broker, $self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
#endif
  int size() 
  {
    return CMGetArrayCount($self, NULL);
  }

  /* Gets the element type.  */
  CMPIType cmpi_type() 
  {
    CMPIType result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetArrayType($self, &st);
    RAISE_IF(st);

    return result;
  }

#if defined(SWIGRUBY)
  %alias at "[]";
#endif
  /* Gets an element value defined by its index. */
  CMPIData at(int index) 
  {
    CMPIData result;
    CMPIStatus st = { CMPI_RC_OK, NULL };

    result = CMGetArrayElementAt($self, index, &st);
    RAISE_IF(st);

    return result;
  }

#if defined(SWIGRUBY)
  %alias set "[]=";
#endif
  /* Sets an element value defined by its index. */
  void set(int index, const CMPIValue * value, CMPIType type) 
  {
    RAISE_IF(CMSetArrayElementAt($self, index, value, type));
  }
}

#BOOKMARK

#-----------------------------------------------------
#
# CMPIString

/*
 * A string
 *
 */
%extend _CMPIString {
  ~_CMPIString() {
    CMRelease( $self );
  }	
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  const char* string() {
    return CMGetCharPtr($self);
  }
}

#-----------------------------------------------------
#
# CMPIContext

/*
 * Context of the provider invocation
 *
 *
 */
%extend _CMPIContext {
  ~_CMPIContext() {
    CMRelease( $self );
  }	
  /*
   * Add entry by name
   * call-seq:
   *   add_entry(name, CMPIValue, CMPIType)
   */
  void add_entry(const char* name, const CMPIValue* data, 
                     const CMPIType type) {
    CMAddContextEntry($self, name, data, type);
  }

  /*
   * Get entry by name
   * call-seq:
   *   get_entry(name) -> CMPIData
   */
  CMPIData get_entry(const char* name) {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data = CMGetContextEntry($self, name, &st);
    if (st.rc)
    {
        RAISE_IF(st);
	data.type = CMPI_null;
        data.state = CMPI_notFound;
        data.value.chars = NULL;
    }
    return data;
  }

  /*
   * Get entry by index or name
   * call-seq:
   *   get_entry_at(index) -> [name, CMPIData]
   *   [index] -> [name, CMPIData]
   *
   * returns a name:string,value:CMPIData pair
   */
#if defined (SWIGRUBY)
  %alias get_entry_at "[]";
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
#if defined (SWIGPERL)
  SV* 
#endif
  __type get_entry_at(
#if defined (SWIGRUBY)
  VALUE pos
#else
  int index
#endif
  )
  {
    Target_Type tdata;
    Target_Type result;
    CMPIString *s = NULL;
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData data;
    const char *name;
#if defined (SWIGRUBY)
    if (FIXNUM_P(pos)) {
      data = CMGetContextEntryAt($self, FIX2LONG(pos), &s, &st);      
    }
    else {
      name = target_charptr(pos);
      data = CMGetContextEntry($self, name, &st);
    }
#else
    data = CMGetContextEntryAt($self, index, &s, &st);
#endif

    if (st.rc)
    {
        RAISE_IF(st);
	result = Target_Null;
	Target_INCREF(result);
        return result;
    }
    if (s)
      name = CMGetCharPtr(s);
    TARGET_THREAD_BEGIN_BLOCK;
    tdata = data_data(&data);
#if defined (SWIGPYTHON)
    result = PyTuple_New(2);
    PyTuple_SetItem(result, 0, PyString_FromString(name));
    PyTuple_SetItem(result, 1, tdata);
#else
    result = Target_SizedArray(2);
    Target_Append(result, Target_String(name));
    Target_Append(result, tdata);
#endif
    TARGET_THREAD_END_BLOCK;
    if (s)
      CMRelease(s);
    return result;
  }

  /*
   * Get number of entries in Context
   */
  CMPICount get_entry_count(void) {
     return CMGetContextEntryCount($self, NULL); 
    // TODO CMPIStatus exception handling
  }

}

#-----------------------------------------------------
#
# CMPIDateTime

/*
 * Date and Time
 *
 *
 */
%extend _CMPIDateTime {
  ~_CMPIDateTime()
  {
    CMRelease( $self );
  }
  
  /* Return string representation */
#ifdef SWIGPYTHON
%rename ("__str__") string();
#endif
#ifdef SWIGRUBY
%rename ("to_s") string();
#endif
  %newobject string;
  const char* string() {
    CMPIString *s = CMGetStringFormat($self, NULL);
    const char *result = strdup(CMGetCharPtr(s));
    CMRelease(s);
    return result;
  }
  
  /* Return integer representation in miliseconds since the epoch */
  uint64_t to_i() {
    return CMGetBinaryFormat($self, NULL);
  }
  
#if defined(SWIGRUBY)
  %rename("interval?") is_interval;
#endif
  /* Tests whether DateTime is an interval value. */
  int is_interval() {
    return CMIsInterval($self, NULL);
  }
}

# EOF
