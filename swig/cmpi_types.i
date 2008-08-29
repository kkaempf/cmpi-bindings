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

%nodefault CMPIError;
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
# CMPIError
#

%extend _CMPIError {
  /* Create a new CMPIError object.
  * owner: Identifies the entity that owns the msg format definition.
  * msgID: Identifies the format of the message.
  * msg: Formatted and translated message.
  * sev: Perceived severity of this error.
  * pc: Probable caues of this error.
  * cimStatusCodeStatus: Code.
  */
  CMPIError(const char *owner, const char* msgID, const char* msg,
     const CMPIErrorSeverity sev, const CMPIErrorProbableCause pc,
     const CMPIrc cimStatusCode)
  {
    return CMNewCMPIError(_BROKER, owner, msgID, msg, sev, pc, cimStatusCode, NULL);    
  }
  ~CMPIError() { }
  /* Gets the type of this Error */
  CMPIErrorType type() {
    CMGetErrorType( $self, NULL );
  }
  /* Sets the error type of this error object. */
#if defined(SWIGRUBY)
  %rename("type=") set_type(const CMPIErrorType et);
#endif
  void set_type(const CMPIErrorType et) {
    CMSetErrorType( $self, et );
  }
  /* Returns a string which describes the alternate error type. */
  const char *other_type() {
    return CMGetCharPtr( CMGetOtherErrorType( $self, NULL ) );
  }
  /* Sets the 'other' error type of this error object. */
#if defined(SWIGRUBY)
  %rename("other_type=") set_other_type(const char *ot);
#endif
  void set_other_type(const char *ot) {
    CMSetOtherErrorType( $self, ot );
  }
  /* Returns a string which describes the owning entity. */
  const char *owning_entity() {
    return CMGetCharPtr( CMGetOwningEntity( $self, NULL ) );
  }
  /* Returns a string which is the message ID. */
  const char *message_id() {
    return CMGetCharPtr( CMGetMessageID( $self, NULL ) );
  }
  /* Returns a string comnating an error message. */
  const char *message() {
    return CMGetCharPtr( CMGetErrorMessage( $self, NULL ) );
  }
  /* Returns the perceieved severity of this error. */
  CMPIErrorSeverity severity() {
    return CMGetPerceivedSeverity( $self, NULL );
  }
  /* Returns the probable cause of this error. */
  CMPIErrorProbableCause probable_cause() {
    return CMGetProbableCause( $self, NULL );
  }
  /* Sets the description of the probable cause. */
#if defined(SWIGRUBY)
  %rename("probable_cause=") set_probable_cause(const char *pcd);
#endif
  void set_probable_cause(const char *pcd) {
    CMSetProbableCauseDescription( $self, pcd );
  }
  /* Returns a string which describes the probable cause. */
  const char *probable_cause_description() {
    return CMGetCharPtr( CMGetProbableCauseDescription( $self, NULL ) );
  }
  /* Returns an array of strings which describes recomended actions. */
  CMPIArray *recommended_actions() {
    return CMGetRecommendedActions( $self, NULL );
  }
  /* Sets the recomended actions array. */
#if defined(SWIGRUBY)
  %rename("recommended_actions=") set_recommended_actions(const CMPIArray* ra);
#endif
  void set_recommended_actions(const CMPIArray* ra) {
    CMSetRecommendedActions( $self, ra );
  }
  /* Returns a string which describes the Error source. */
  const char *source() {
    return CMGetCharPtr( CMGetErrorSource( $self, NULL ) );
  }
  /* Specifies a string which specifes The identifying information of
     the entity (i.e., the instance) generating the error. */
#if defined(SWIGRUBY)
  %rename("source=") set_source(const char *es);
#endif
  void set_source(const char *es) {
    CMSetErrorSource( $self, es );
  }
  /* Returns a the format that the error src is in. */
  CMPIErrorSrcFormat source_format() {
    return CMGetErrorSourceFormat( $self, NULL );
  }
  /* Sets the source format of the error object. */
#if defined(SWIGRUBY)
  %rename("source_format=") set_source_format(const CMPIErrorSrcFormat esf);
#endif
  void set_source_format(const CMPIErrorSrcFormat esf) {
    CMSetErrorSourceFormat( $self, esf );
  }
  /* Returns a string which describes the 'other' format, only
     available if the error source is OTHER. */
  const char *other_format() {
    return CMGetCharPtr( CMGetOtherErrorSourceFormat( $self, NULL ) );
  }
  /* specifies A string defining "Other" values for ErrorSourceFormat */
#if defined(SWIGRUBY)
  %rename("other_format=") set_other_format(const char *oesf);
#endif
  void set_other_format(const char *oesf) {
    CMSetOtherErrorSourceFormat( $self, oesf );
  }
  /* Returns the status code of this error. */
  CMPIrc status_code() {
    return CMGetCIMStatusCode( $self, NULL );
  }
  /* Returns a string which describes the status code error. */
  const char *status_description() {
    return CMGetCharPtr( CMGetCIMStatusCodeDescription( $self, NULL ) );
  }
  /* Sets the description of the status code. */
#if defined(SWIGRUBY)
  %rename("status_description=") set_status_description(const char *cd);
#endif
  void set_status_description(const char *cd) {
    CMSetCIMStatusCodeDescription( $self, cd );
  }
  /* Returns an array which contains the dynamic content of the message. */
  CMPIArray *message_arguments() {
    return CMGetMessageArguments( $self, NULL );
  }
  /* Sets an array of strings for the dynamic content of the message. */
#if defined(SWIGRUBY)
  %rename("message_arguments=") set_message_arguments(CMPIArray* ma);
#endif
  void set_message_arguments(CMPIArray* ma) {
    CMSetMessageArguments( $self, ma );
  }
}

#-----------------------------------------------------
#
# CMPIResult
#

%extend _CMPIResult {
  /* no con-/destructor, the broker handles this */
  
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }

  void return_instance(CMPIInstance *instance) {
    CMReturnInstance( $self, instance );
  }
  void return_objectpath(CMPIObjectPath *path) {
    CMReturnObjectPath( $self, path );
  }
  void return_data(const CMPIValue* value, const CMPIType type) {
    CMReturnData( $self, value, type); 
  }
  void done() {
    CMReturnDone( $self );
  }
}

#-----------------------------------------------------
#
# CMPIMsgFileHandle
#

%extend _CMPIMsgFileHandle {
  CMPIMsgFileHandle(const char *msgFile) {
    CMPIMsgFileHandle handle;
    CMPIStatus st = CMOpenMessageFile(_BROKER, msgFile, &handle);
    /* FIXME */
  }
  ~CMPIMsgFileHandle() {
    CMCloseMessageFile( _BROKER, $self );
  }
}

#-----------------------------------------------------
#
# CMPIObjectPath
#

%extend _CMPIObjectPath {
  /* nm: namespace */
  CMPIObjectPath( const char *nm ) {
    CMPIObjectPath *path = CMNewObjectPath(_BROKER, nm, _CLASSNAME, NULL);
/*    fprintf( stderr, "CMNewObjectPath: %p\n", path ); */
    return path;
  }
  ~CMPIObjectPath( ) { }
  /**
   * Create an independent copy of this ObjectPath object. The resulting
   *          object must be released explicitly.
FIXME: if clone() is exposed, release() must also
  CMPIObjectPath *clone() {
    return $self->ft->clone( $self, NULL );
  }
   */	     
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }
  
  /* Function to determine whether the class specified by the object path is of &lt;type&gt;
   * or any of &lt;type&gt; subclasses.
   * type: The type to tested for.
   */
  int is_a(const char *type) {
    return CMClassPathIsA(_BROKER, $self, type, NULL);
  }
  /* Adds/replaces a named key property.
   * name: Key property name.
   * value: Address of value structure.
   * type: Value type.
   */
#if defined(SWIGRUBY)
  %alias set "[]=";
  /*
   * Key setting in Ruby
   * instance[:propname] = data    # set by name (symbol)
   * instance["propname"] = data   # set by name (string)
   */
  CMPIStatus set(VALUE property, VALUE data)
  {
    const char *name;
    CMPIValue *value = (CMPIValue *)malloc(sizeof(CMPIValue));
    CMPIType type;
    if (SYMBOL_P(property)) {
      name = rb_id2name( SYM2ID( property ) );
    }
    else {
      name = StringValuePtr( property );
    }
    switch (TYPE(data)) {
      case T_FLOAT:
        value->Float = RFLOAT(data)->value;
	type = CMPI_real32;
      break;
      case T_STRING:
        value->string = CMNewString(_BROKER, StringValuePtr(data), NULL);
	type = CMPI_string;
      break; 
      case T_FIXNUM:
        value->Int = FIX2ULONG(data);
	type = CMPI_uint32;
      break;
      case T_TRUE:
        value->boolean = 1;
	type = CMPI_boolean;
      break;
      case T_FALSE:
        value->boolean = 0;
	type = CMPI_boolean;
      break;
      case T_SYMBOL:
        value->string = CMNewString(_BROKER, rb_id2name(SYM2ID( data )), NULL);
	type = CMPI_string;
      break;
      default:
        value->chars = NULL;
	type = CMPI_null;
        break;
    }
    return CMAddKey( $self, name, value, type );
  }
#endif
  CMPIStatus add_key( const char *name, const CMPIValue * value, const CMPIType type) {
    return CMAddKey( $self, name, value, type );
  }
  /* Gets a named key property value.
   * name: Key property name.
   */
  CMPIData get_key( const char *name ) {
    return CMGetKey( $self, name, NULL );
  }
  /* Gets a key property value defined by its index.
   * name: [out] Key property name
   */
#if defined (SWIGRUBY)
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
  get_key_at( int index ) {
    CMPIString *s = NULL;
    CMPIData data = CMGetKeyAt( $self, index, &s, NULL );

#if defined (SWIGRUBY)
    VALUE rbdata = SWIG_NewPointerObj((void*) clone_data(&data), SWIGTYPE_p__CMPIData, 0);
    VALUE rl = rb_ary_new2(2);
    return rb_ary_push( rb_ary_push( rl, rbdata ), rb_str_new2(CMGetCharPtr(s) ) );
#endif
#if defined (SWIGPYTHON)
    #TODO memory leak alert (clone_data)
    PyObject* pydata = SWIG_NewPointerObj((void*) clone_data(&data), SWIGTYPE_p__CMPIData, 0);

    PyObject* pl = PyTuple_New(2);
    PyTuple_SetItem(pl, 0, pydata);
    PyTuple_SetItem(pl, 1, PyString_FromString(CMGetCharPtr(s)));
    return pl;
#endif
  }
  /* Gets the number of key properties contained in this ObjectPath. */
  int key_count() {
    return CMGetKeyCount( $self, NULL );
  }
  /* Set/replace namespace and classname components from &lt;src&gt;. */
  void replace_from( const CMPIObjectPath * src ) {
    CMSetNameSpaceFromObjectPath( $self, src );
  }
  /* Set/replace hostname, namespace and classname components from &lt;src&gt;. */
  void replace_all_from( const CMPIObjectPath * src ) {
    CMSetHostAndNameSpaceFromObjectPath( $self, src );
  }
  /* Get class qualifier value.
   * qName: Qualifier name.
   */
  CMPIData qualifier( const char *qname ) {
    return CMGetClassQualifier( $self, qname, NULL );
  }
  /* Get property qualifier value.
   * pName Property name.
   * qName Qualifier name.
   */
  CMPIData property_qualifier( const char *pName, const char *qName ) {
    return CMGetPropertyQualifier( $self, pName, qName, NULL );
  }
  /* Get method qualifier value.
   * mName: Method name.
   * qName: Qualifier name.
   */
  CMPIData method_qualifier(const char *methodName, const char *qName) {
    return CMGetMethodQualifier( $self, methodName, qName, NULL);
  }
  /* Get method parameter qualifier value.
   * mName: Method name.
   * pName: Parameter name.
   * qName: Qualifier name.
   */
  CMPIData parameter_qualifier( const char *mName, const char *pName, const char *qName ) {
    return CMGetParameterQualifier( $self, mName, pName, qName, NULL );
  }
  /* Get the namespace component. */
  const char *namespace() {
    return CMGetCharPtr( CMGetNameSpace( $self, NULL ) );
  }
  /* Set/replace the namespace component. */
#if defined(SWIGRUBY)
  %rename("namespace=") set_namespace(const char *nm);
#endif
  void set_namespace( const char *nm ) {
    CMSetNameSpace( $self, nm );
  }
  /* Set/replace the hostname component. */
#if defined(SWIGRUBY)
  %rename("hostname=") set_hostname(const char *hostname);
#endif
  void set_hostname( const char *hostname ) {
    CMSetHostname( $self, hostname );
  }
  /* Get the hostname component. */
  const char *hostname() {
    return CMGetCharPtr(CMGetHostname($self, NULL));
  }
  /* Set/replace the classname component. */
#if defined(SWIGRUBY)
  %rename("classname=") set_classname(const char *classname);
#endif
  void set_classname( const char *classname ) {
    CMSetClassName( $self, classname );
  }
  /* Get the classname component. */
  const char *classname() {
    return CMGetCharPtr(CMGetClassName($self, NULL));
  }
  
}

#-----------------------------------------------------
#
# CMPIInstance
#

%extend _CMPIInstance {
  /* path: ObjectPath containing namespace and classname. */
  CMPIInstance(CMPIObjectPath *path) {
    CMPIInstance *inst = CMNewInstance(_BROKER, path, NULL);
#if 0
fprintf(stderr, "CMNewInstance( path %p ) -> %p [%d:%s]\n", path,
inst, status.rc, status.msg?CMGetCharPtr(status.msg):"<NULL>" );
    CMPIString *s = CDToString(_BROKER, path, NULL);
  fprintf(stderr, "path : %s\n", CMGetCharPtr(s));
#endif	
  return inst;
  }
  ~CMPIInstance() { }
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }

  /* Adds/replaces a named Property.
   * name: Entry name.
   * value: Address of value structure.
   * type: Value type.
   */
#if defined(SWIGRUBY)
  %alias set "[]=";
  /*
   * Property setting in Ruby
   * instance[:propname] = data    # set by name (symbol)
   * instance["propname"] = data   # set by name (string)
   */
  CMPIStatus set(VALUE property, VALUE data)
  {
    const char *name;
    CMPIValue *value = (CMPIValue *)malloc(sizeof(CMPIValue));
    CMPIType type;
    if (SYMBOL_P(property)) {
      name = rb_id2name( SYM2ID( property ) );
    }
    else {
      name = StringValuePtr( property );
    }
    switch (TYPE(data)) {
      case T_FLOAT:
        value->Float = RFLOAT(data)->value;
	type = CMPI_real32;
      break;
      case T_STRING:
        value->string = CMNewString(_BROKER, StringValuePtr(data), NULL);
	type = CMPI_string;
      break; 
      case T_FIXNUM:
        value->Int = FIX2ULONG(data);
	type = CMPI_uint32;
      break;
      case T_TRUE:
        value->boolean = 1;
	type = CMPI_boolean;
      break;
      case T_FALSE:
        value->boolean = 0;
	type = CMPI_boolean;
      break;
      case T_SYMBOL:
        value->string = CMNewString(_BROKER, rb_id2name(SYM2ID( data )), NULL);
	type = CMPI_string;
      break;
      default:
        value->chars = NULL;
	type = CMPI_null;
        break;
    }
    return CMSetProperty( $self, name, value, type );
  }
#endif
  CMPIStatus set_property(const char *name, const CMPIValue * value, const CMPIType type) {
    return CMSetProperty( $self, name, value, type );
  }
  /* get a named property value */
#if defined(SWIGRUBY)
  %alias get "[]";
  /*
   * Property access in Ruby:
   * data = instance[:propname]     # access by name (symbol)
   * data = instance["propname"     # access by name (string)
   * data = instance[1]             # access by index
   */
  CMPIData get(VALUE property)
  {
    if (FIXNUM_P(property)) {
      return CMGetPropertyAt( $self, FIX2ULONG(property), NULL, NULL );
    }
    else {
      const char *name;
      if (SYMBOL_P(property)) {
        name = rb_id2name( SYM2ID( property ) );
      }
      else {
        name = StringValuePtr( property );
      }
      return CMGetProperty( $self, name, NULL );
    }
  }
#endif
  CMPIData get_property(const char *name) {
    return CMGetProperty( $self, name, NULL );
  }
  /** Gets a Property value defined by its index.
   * index: Position in the internal Data array.
   */
#if defined (SWIGRUBY)
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
  get_property_at(int index) {
    CMPIString *s = NULL;
    CMPIData data = CMGetPropertyAt( $self, index, &s, NULL );

#if defined (SWIGRUBY)
    VALUE rbdata = SWIG_NewPointerObj((void*) clone_data(&data), SWIGTYPE_p__CMPIData, 0);
    VALUE rl = rb_ary_new2(2);
    return rb_ary_push( rb_ary_push( rl, rbdata ), rb_str_new2(CMGetCharPtr(s) ) );
#endif
#if defined (SWIGPYTHON)
    #TODO memory leak alert (clone_data)
    PyObject* pydata = SWIG_NewPointerObj((void*) clone_data(&data), SWIGTYPE_p__CMPIData, 0);

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject* pl = PyTuple_New(2);
    PyTuple_SetItem(pl, 0, pydata);
    PyTuple_SetItem(pl, 1, PyString_FromString(CMGetCharPtr(s)));
    SWIG_PYTHON_THREAD_END_BLOCK; 
    return pl;
#endif
  }
  /* Gets the number of properties contained in this Instance. */
#if defined(SWIGRUBY)
  %alias property_count "size";
#endif
  int property_count() {
    return CMGetPropertyCount( $self, NULL );
  }
  /* Generates an ObjectPath out of the namespace, classname and
   *  key propeties of this Instance.
   */
  CMPIObjectPath *objectpath() {
    CMPIObjectPath *path = CMGetObjectPath( $self, NULL );
/*    fprintf(stderr, "<%p>.objectpath = %p\n", $self, path ); */
    return path;
  }
  /* Replaces the ObjectPath of the instance.
   *  The passed objectpath shall contain the namespace, classname,
   *   as well as all keys for the specified instance.
   */
#if defined(SWIGRUBY)
  %alias set_objectpath "objectpath=";
#endif
  CMPIStatus set_objectpath(const CMPIObjectPath *path) {
    return CMSetObjectPath( $self, path );
  }
  /* Directs CMPI to ignore any setProperty operations for this
   *        instance for any properties not in this list.
   * properties: If not NULL, the members of the array define one
   *         or more Property names to be accepted by setProperty operations.
   */
  CMPIStatus set_property_filter( const char **properties ) {
    return CMSetPropertyFilter( $self, properties, NULL );
  }
  /* Add/replace a named Property value and origin
   * name: is a string containing the Property name.
   * value: points to a CMPIValue structure containing the value
   *        to be assigned to the Property.
   * type: is a CMPIType structure defining the type of the value.
   * origin: specifies the instance origin.  If NULL, then
             no origin is attached to  the property
   */
  CMPIStatus set_property_with_origin(const char *name,
     const CMPIValue * value, CMPIType type, const char * origin)
  {
    return CMSetPropertyWithOrigin( $self, name, value, type, origin );
  }
}

#-----------------------------------------------------
#
# CMPIArgs

%extend _CMPIArgs {
  CMPIArgs() {
    return CMNewArgs(_BROKER, NULL);
  }
  ~CMPIArgs() { }
  
  /* Adds/replaces a named argument. */
  void set( char *name, const CMPIValue * value, const CMPIType type) {
    CMAddArg( $self, name, value, type );
  }
  /* Gets a named argument value. */
#if defined(SWIGRUBY)
  %alias get "[]";
#endif
  CMPIData get( const char *name ) {
    return CMGetArg( $self, name, NULL );
  }
  /* Gets a Argument value defined by its index.
   */
#if defined (SWIGRUBY)
  VALUE
#endif
#if defined (SWIGPYTHON)
  PyObject* 
#endif
  get_arg_at(int index) {
    CMPIString *s = NULL;
    CMPIData data = CMGetArgAt( $self, index, &s, NULL );

#if defined (SWIGRUBY)
    VALUE rbdata = SWIG_NewPointerObj((void*) clone_data(&data), SWIGTYPE_p__CMPIData, 0);
    VALUE rl = rb_ary_new2(2);
    return rb_ary_push( rb_ary_push( rl, rbdata ), rb_str_new2(CMGetCharPtr(s) ) );
#endif
#if defined (SWIGPYTHON)
    #TODO memory leak alert (clone_data)
    PyObject* pydata = SWIG_NewPointerObj((void*) clone_data(&data), SWIGTYPE_p__CMPIData, 0);

    SWIG_PYTHON_THREAD_BEGIN_BLOCK; 
    PyObject* pl = PyTuple_New(2);
    PyTuple_SetItem(pl, 0, pydata);
    PyTuple_SetItem(pl, 1, PyString_FromString(CMGetCharPtr(s)));
    SWIG_PYTHON_THREAD_END_BLOCK; 
    return pl;
#endif
  }
  /* Gets the number of arguments contained in this Args. */

  int arg_count() {
    return CMGetArgCount($self, NULL);
  }

}

#-----------------------------------------------------
#
# CMPISelectExp

%extend _CMPISelectExp {
  /* This structure encompasses queries
   *       and provides mechanism to operate on the query.
   * query: The select expression.
   * lang: The query language.
   * projection [Output]: Projection specification (suppressed when NULL).
   */
  CMPISelectExp(const char *query, const char *lang, CMPIArray **projection) {
    return CMNewSelectExp(_BROKER, query, lang, projection, NULL);
  }
  ~CMPISelectExp() { }
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }
}

#-----------------------------------------------------
#
# CMPISelectCond

%extend _CMPISelectCond {
  CMPISelectCond() { }
  ~CMPISelectCond() { }
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }
}

#-----------------------------------------------------
#
# CMPISubCond

%extend _CMPISubCond {
  CMPISubCond() { }
  ~CMPISubCond() { }
}

#-----------------------------------------------------
#
# CMPIPredicate

%extend _CMPIPredicate {
  CMPIPredicate() { }
  ~CMPIPredicate() { }
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }
}

#-----------------------------------------------------
#
# CMPIEnumeration

%extend _CMPIEnumeration {
  CMPIEnumeration() { }
  ~CMPIEnumeration() { }
#if defined(SWIGRUBY)
  %alias length "size";
#endif
  int length() {
    int l = 0;
    while (CMHasNext( $self, NULL ) ) {
      ++l;
      CMGetNext( $self, NULL );
    }
    return l;
  }
  CMPIData next() {
    return CMGetNext( $self, NULL );
  }
#if defined(SWIGRUBY)
  %alias hasNext "empty?";
#endif
  int hasNext() {
    return CMHasNext( $self, NULL );
  }
#if defined(SWIGRUBY)
  %alias toArray "to_ary";
#endif
  CMPIArray *toArray() {
    return CMToArray( $self, NULL );
  }
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }
}

#-----------------------------------------------------
#
# CMPIArray

%extend _CMPIArray {
  /* count: Maximum number of elements
   * type: Element type
   */
  CMPIArray(int count, CMPIType type ) {
    return CMNewArray( _BROKER, count, type, NULL);
  }
  CMPIArray( ) { }
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }
  int size() {
    return CMGetArrayCount( $self, NULL );
  }
  /* Gets the element type.  */
  CMPIType cmpi_type() {
    return CMGetArrayType( $self, NULL );
  }
  /* Gets an element value defined by its index. */
#if defined(SWIGRUBY)
  %alias at "[]";
#endif
  CMPIData at( int index ) {
    return CMGetArrayElementAt( $self, index, NULL );
  }
  /* Sets an element value defined by its index. */
#if defined(SWIGRUBY)
  %alias set "[]=";
#endif
  void set(int index, const CMPIValue * value, CMPIType type) {
    CMSetArrayElementAt( $self, index, value, type );
  }
  
}

#-----------------------------------------------------
#
# CMPIString

%extend _CMPIString {
  CMPIString(const char *s) {
    return CMNewString(_BROKER, s, NULL);
  }
  CMPIString() { }
  const char* to_s() {
    return CMGetCharPtr($self);
  }
}

#-----------------------------------------------------
#
# CMPIContext

%extend _CMPIContext {
  CMPIContext() { }
  ~CMPIContext() { }
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }
}

#-----------------------------------------------------
#
# CMPIDateTime

%extend _CMPIDateTime {
  /* Initialized with the time of day. */
  CMPIDateTime(void) {
    return CMNewDateTime(_BROKER, NULL);
  }
  ~CMPIDateTime() { }
  /* bintime: Date/Time definition in binary format in microsecods
   *          starting since 00:00:00 GMT, Jan 1,1970.
   * interval: Wenn true, defines Date/Time definition to be an interval value
   */
  CMPIDateTime(uint64_t bintime, int interval = 0 ) {
    return CMNewDateTimeFromBinary(_BROKER, bintime, interval, NULL);
  }
  /* utc Date/Time definition in UTC format */
  CMPIDateTime(const char *utc) {
    return CMNewDateTimeFromChars(_BROKER, utc, NULL);
  }

  const char* to_s() {
    return CMGetCharPtr( CMGetStringFormat( $self, NULL ) );
  }
  uint64_t to_i() {
    return CMGetBinaryFormat( $self, NULL );
  }
  /* Tests whether DateTime is an interval value. */
#if defined(SWIGRUBY)
  %rename("interval?") is_interval;
#endif
  int is_interval() {
    return CMIsInterval( $self, NULL );
  }
}

# EOF
