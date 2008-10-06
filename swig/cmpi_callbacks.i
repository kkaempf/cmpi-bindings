# cmpi_callbacks.i
#
# swig bindings for CMPI broker callbacks
#

%nodefault _CMPIBroker;
%rename(CMPIBroker) CMPIBroker;
typedef struct _CMPIBroker {} CMPIBroker;

%extend CMPIBroker 
{
  void LogMessage(
    int severity, 
    const char *id, 
    const char *text) 
  {
    RAISE_IF(CMLogMessage($self, severity, id, text, NULL)); 
  }

  unsigned long capabilities() 
  {
    return CBGetCapabilities($self);
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

  /*
  CMPIStatus setInstance(const CMPIContext* ctx, const CMPIObjectPath* op, const CMPIInstance* inst, const char** properties) { 
    return CBSetInstance($self, ctx, op, inst, properties);
  }
  */

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
    const CMPIArgs * in, 
    CMPIArgs * out) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIData result;

    result = CBInvokeMethod($self, ctx, op, method, in, out, &st);
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

  CMPIObjectPath* new_object_path(const char* ns, const char* cname)
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIObjectPath* result;

    result = CMNewObjectPath($self, ns, cname, &st); 
    RAISE_IF(st);

    return result;
  }

  CMPIInstance* new_instance(const CMPIObjectPath* path)
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIInstance* result;

    result = CMNewInstance($self, path, &st); 
    RAISE_IF(st);

    return result;
  }

  CMPIArgs* new_args(void)
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIArgs* result;

    result = CMNewArgs($self, &st); 
    RAISE_IF(st);

    return result;
  }

  CMPIDateTime* new_datetime(void) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIDateTime* result;

    result = CMNewDateTime($self, &st);
    RAISE_IF(st);

    return result;
  }

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
  CMPIDateTime* new_datetime_from_string(const char *utc) 
  {
    CMPIStatus st = { CMPI_RC_OK, NULL };
    CMPIDateTime* result;

    result = CMNewDateTimeFromChars($self, utc, &st);
    RAISE_IF(st);

    return result;
  }

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
