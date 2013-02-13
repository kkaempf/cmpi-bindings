# cmpi_callbacks.i
#
# swig bindings for CMPI broker callbacks
#

%nodefault _CMPIBroker;
%rename(CMPIBroker) CMPIBroker;
typedef struct _CMPIBroker {} CMPIBroker;

/*
 * The CMPIBroker represents the running CIMOM and provides utility
 * functions to the Provider
 *
 */


%extend CMPIBroker 
{
#if defined(SWIGPERL)
  int __eq__( const CMPIBroker *broker )
#endif
#if defined(SWIGRUBY)
  %typemap(out) int equal
    "$result = $1 ? Qtrue : Qfalse;";
  %rename("==") equal( const CMPIBroker *broker );
  int equal( const CMPIBroker *broker )
#endif
#if defined(SWIGPYTHON)
  /*
  * :nodoc:
  * Python treats 'eq' and 'ne' distinct.
  */
  int __ne__( const CMPIBroker *broker )
  { return $self != broker; }
  int __eq__( const CMPIBroker *broker )
#endif
  { return $self == broker; }

  /*
   * standard log messages are intended for user / system admin.
   * severity: Cmpi.CMPI_SEV_ERROR	Error
   *           Cmpi.CMPI_SEV_INFO       General info
   *           Cmpi.CMPI_SEV_WARNING	Warning message
   *           Cmpi.CMPI_DEV_DEBUG	Debug message
   */

#if defined(SWIGRUBY)
  %rename("log") LogMessage(int severity, const char *id, const char *text);
#endif
  void LogMessage(
    int severity, 
    const char *id, 
    const char *text) 
  {
    log_message($self, severity, id, text);
  }

  /*
   * The trace messages are intended for developer
   * level: Cmpi.CMPI_LEV_INFO   	Generic information
   *        Cmpi.CMPI_LEV_WARNING       warnings
   *        Cmpi.CMPI_LEV_VERBOSE	detailed/specific information
   *
   */

#if defined(SWIGRUBY)
  %rename("trace") TraceMessage(int level, const char *component, const char *text);
#endif

  void TraceMessage(
    int level,
    const char *component,
    const char *text)
  {
    CMPIStatus st = CMTraceMessage($self, level, component, text, NULL);
    if (st.rc == CMPI_RC_ERR_NOT_SUPPORTED) {
      int severity;
      switch (level) {
        case CMPI_LEV_INFO:    severity = CMPI_SEV_INFO; break;
        case CMPI_LEV_WARNING: severity = CMPI_SEV_WARNING; break;
        case CMPI_LEV_VERBOSE: severity = CMPI_SEV_INFO; break;
        default:               severity = CMPI_SEV_ERROR;
      }
      log_message($self, severity, component, text);
    }
    else {
      RAISE_IF(st);
    }    
  }

  int version() 
  {
    return CBBrokerVersion($self);
  }

  const char *name() 
  {
    return CBBrokerName($self);
  }

  CMPIBoolean classPathIsA(
    const CMPIObjectPath *op, 
    const char *parent_class) 
  {
    return CMClassPathIsA($self, op, parent_class, NULL);
  }

  void deliverIndication(
    const CMPIContext * ctx, 
    const char * ns, 
    const CMPIInstance * ind) 
  {
    RAISE_IF(CBDeliverIndication($self, ctx, ns, ind));
  }

  CMPIContext* prepareAttachThread(
    const CMPIContext * ctx)
  {
    return CBPrepareAttachThread($self, ctx);
  }

  void attachThread(
    const CMPIContext * ctx)
  {
    RAISE_IF(CBAttachThread($self, ctx));
  }

  void detachThread(
    const CMPIContext * ctx)
  {
    RAISE_IF(CBDetachThread($self, ctx));
  }

  CMPIEnumeration* enumInstanceNames(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIEnumeration* e;

    e = CBEnumInstanceNames($self, ctx, op, &st);
    RAISE_IF(st);

    return e;
  }

  CMPIEnumeration *enumInstances(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op, const char **properties) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIEnumeration* result;

    result = CBEnumInstances($self, ctx, op, properties, &st);
    RAISE_IF(st);

    return result;
  }

  CMPIInstance *getInstance(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op, 
    const char **properties) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIInstance* result;
    
    result = CBGetInstance($self, ctx, op, properties, &st);
    RAISE_IF(st);

    return result;
  }

  CMPIObjectPath *createInstance(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op, 
    const CMPIInstance * inst) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIObjectPath* result;

    result = CBCreateInstance($self, ctx, op, inst, &st);
    RAISE_IF(st);

    return result;
  }

  void modifyInstance(
    const CMPIContext *ctx,
    const CMPIObjectPath *op,
    const CMPIInstance *inst,
    const char **properties)	    
  {
    RAISE_IF(CBModifyInstance($self, ctx, op, inst, properties));
  }

  void deleteInstance(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op) 
  {
    RAISE_IF(CBDeleteInstance($self, ctx, op));
  }

  CMPIEnumeration *execQuery(
      const CMPIContext * ctx, 
      const CMPIObjectPath * op, 
      const char *query, 
      const char *lang) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIEnumeration* result;

    result = CBExecQuery($self, ctx, op, query, lang, &st);
    RAISE_IF(st);

    return result;
  }

  CMPIEnumeration *associators(
      const CMPIContext * ctx, 
      const CMPIObjectPath * op,
      const char *assocClass, 
      const char *resultClass, 
      const char *role,
      const char *resultRole, 
      const char **properties) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIEnumeration* result;

    result = CBAssociators($self, ctx, op, assocClass, resultClass, role, 
      resultRole, properties, &st);
    RAISE_IF(st);

    return result;
  }

  CMPIEnumeration *associatorNames(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op,
    const char *assocClass, 
    const char *resultClass, 
    const char *role,
    const char *resultRole) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIEnumeration* result;

    result = CBAssociatorNames($self, ctx, op, assocClass, resultClass, role, 
      resultRole, &st);
    RAISE_IF(st);

    return result;
  }

  CMPIEnumeration *references(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op,
    const char *resultClass, 
    const char *role, 
    const char **properties) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIEnumeration* result;

    result = CBReferences($self, ctx, op, resultClass, role, properties, &st);
    RAISE_IF(st);

    return result;
  }

  CMPIEnumeration *referenceNames(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op,
    const char *resultClass, 
    const char *role) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIEnumeration* result;

    result = CBReferenceNames($self, ctx, op, resultClass, role, &st);
    RAISE_IF(st);

    return result;
  }

  CMPIData invokeMethod(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op, 
    const char *method,
    const CMPIArgs * _in, /* 'in' is reserved in Python */
    CMPIArgs * out) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CBInvokeMethod($self, ctx, op, method, _in, out, &st);
    RAISE_IF(st);

    return result;
  }

  void setProperty(
    const CMPIContext * ctx, 
    const CMPIObjectPath * op, 
    const char *name,
    const CMPIValue * value, 
    const CMPIType type) 
  {
    RAISE_IF(CBSetProperty($self, ctx, op, name, (CMPIValue *)value, type));
  }

  CMPIData getProperty(
    const CMPIContext * ctx, 
    const CMPIObjectPath *op, 
    const char *name) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CBGetProperty($self, ctx, op, name, &st);
    RAISE_IF(st);

    return result;
  }

  %newobject new_object_path;
  CMPIObjectPath* new_object_path(const char* ns, const char* cname)
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIObjectPath* result;

    result = CMNewObjectPath($self, ns, cname, &st); 
    RAISE_IF(st);

    return result;
  }

  %newobject new_instance;
  CMPIInstance* new_instance(const CMPIObjectPath* path, int allow_null_ns)
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIInstance* result;
    CMPIString* ns = NULL;

    /* Raise exception if no namespace */

    if (!allow_null_ns)
    {
        const char* str;
        if (!(ns = CMGetNameSpace(path, &st)) || st.rc ||
            !(str = CMGetCharsPtr(ns, NULL)) || *str == '\0')
        {
            CMSetStatusWithChars($self, &st, CMPI_RC_ERR_FAILED, 
                "object path has no namespace");
            _raise_ex(&st);
            return NULL;
        }
	if (ns) CMRelease(ns);
    }

    result = CMNewInstance($self, path, &st); 
    RAISE_IF(st);

    return result;
  }

  %newobject new_args;
  CMPIArgs* new_args(void)
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIArgs* result;

    result = CMNewArgs($self, &st); 
    RAISE_IF(st);

    return result;
  }

  %newobject new_datetime;
  CMPIDateTime* new_datetime(void) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIDateTime* result;

    result = CMNewDateTime($self, &st);
    RAISE_IF(st);

    return result;
  }

  %newobject new_datetime_from_uint64;
  CMPIDateTime* new_datetime_from_uint64(
    uint64_t bintime, 
    int interval = 0 ) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIDateTime* result;

    result = CMNewDateTimeFromBinary($self, bintime, interval, &st);
    RAISE_IF(st);

    return result;
  }

  /* utc Date/Time definition in UTC format */
  %newobject new_datetime_from_string;
  CMPIDateTime* new_datetime_from_string(const char *utc) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIDateTime* result;

    result = CMNewDateTimeFromChars($self, utc, &st);
    RAISE_IF(st);

    return result;
  }

  %newobject new_string;
  CMPIString* new_string(const char *s) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIString* result;

    result = CMNewString($self, s, &st);
    RAISE_IF(st);

    return result;
  }

  /* count: Maximum number of elements
   * type: Element type
   */
  %newobject new_array;
  CMPIArray* new_array(int count, CMPIType type ) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIArray* result;

    result = CMNewArray($self, count, type, &st);

    RAISE_IF(st);
    return result;
  }

#-----------------------------------------------------
#
# TODO: CMPIMsgFileHandle stuff
#
  /*
   * query: The select expression.
   * lang: The query language.
   * projection [Output]: Projection specification (suppressed when NULL).
   */
  %newobject new_select_exp;
  CMPISelectExp* new_select_exp(
    const char *query, 
    const char *lang, 
    CMPIArray **projection) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPISelectExp* result;

    return CMNewSelectExp($self, query, lang, projection, &st);
    RAISE_IF(st);

    return result;
  }

  /* Create a new CMPIError object.
  * owner: Identifies the entity that owns the msg format definition.
  * msgID: Identifies the format of the message.
  * msg: Formatted and translated message.
  * sev: Perceived severity of this error.
  * pc: Probable caues of this error.
  * cimStatusCodeStatus: Code.
  */
  %newobject new_error;
  CMPIError* new_error(
    const char *owner, 
    const char* msgID, 
    const char* msg,
    const CMPIErrorSeverity sev, 
    const CMPIErrorProbableCause pc,
    const CMPIrc cimStatusCode)
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIError* result;

    result = CMNewCMPIError($self, owner, msgID, msg, sev, pc, cimStatusCode, 
      &st);
    RAISE_IF(st);

    return result;
  }

  void bummer()
  {
    CMPIStatus st;

    CMSetStatusWithChars(
        $self, &st, CMPI_RC_ERR_FAILED, "Bummer! I didn't see that coming");

    _raise_ex(&st);
  }
}
