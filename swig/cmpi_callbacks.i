# cmpi_callbacks.i
#
# swig bindings for CMPI broker callbacks
#

%nodefault _CMPIBroker;
%rename(CMPIBroker) CMPIBroker;
typedef struct _CMPIBroker {} CMPIBroker;

%extend CMPIBroker {
  void LogMessage(int severity, const char *id, const char *text) {
    CMLogMessage($self, severity, id, text, NULL);
  }
  unsigned long capabilities() {
    return CBGetCapabilities($self);
  }
  int version() {
    return CBBrokerVersion($self);
  }
  const char *name() {
    return CBBrokerName($self);
  }
  CMPIBoolean classPathIsA(const CMPIObjectPath *op, const char *parent_class) {
    return CMClassPathIsA($self, op, parent_class, NULL);
  }
  CMPIStatus deliverIndication(const CMPIContext * ctx, const char * ns, const CMPIInstance * ind) {
    return CBDeliverIndication($self, ctx, ns, ind);
  }
  CMPIEnumeration* enumInstanceNames(const CMPIContext * ctx, const CMPIObjectPath * op) {
    CMPIStatus st;
    CMPIEnumeration* e;

    e = CBEnumInstanceNames($self, ctx, op, &st);

    if (st.rc)
        _raise_ex(&st);

    return e;
  }
  CMPIEnumeration *enumInstances(const CMPIContext * ctx, const CMPIObjectPath * op, const char **properties) {
    return CBEnumInstances($self, ctx, op, properties, NULL);
  }
  CMPIInstance *getInstance(const CMPIContext * ctx, const CMPIObjectPath * op, const char **properties) {
    return CBGetInstance($self, ctx, op, properties, NULL);
  }
  CMPIObjectPath *createInstance(const CMPIContext * ctx, const CMPIObjectPath * op, const CMPIInstance * inst) {
    return CBCreateInstance($self, ctx, op, inst, NULL);
  }
  /*
  CMPIStatus setInstance(const CMPIContext* ctx, const CMPIObjectPath* op, const CMPIInstance* inst, const char** properties) { 
    return CBSetInstance($self, ctx, op, inst, properties);
  }
  */
  CMPIStatus deleteInstance(const CMPIContext * ctx, const CMPIObjectPath * op) {
    return CBDeleteInstance($self, ctx, op);
  }
  CMPIEnumeration *execQuery(const CMPIContext * ctx, const CMPIObjectPath * op, const char *query, const char *lang) {	  
    return CBExecQuery($self, ctx, op, query, lang, NULL);
  }
  CMPIEnumeration *associators(const CMPIContext * ctx, const CMPIObjectPath * op,
                               const char *assocClass, const char *resultClass, const char *role,
                   const char *resultRole, const char **properties) {
    return CBAssociators($self, ctx, op, assocClass, resultClass, role, resultRole, properties, NULL);
  }
  CMPIEnumeration *associatorNames(const CMPIContext * ctx, const CMPIObjectPath * op,
                                   const char *assocClass, const char *resultClass, const char *role,
                   const char *resultRole) {
    return CBAssociatorNames ($self, ctx, op, assocClass, resultClass, role, resultRole, NULL);
  }
  CMPIEnumeration *references(const CMPIContext * ctx, const CMPIObjectPath * op,
                              const char *resultClass, const char *role, const char **properties) {
    return CBReferences($self, ctx, op, resultClass, role, properties, NULL);
  }
  CMPIEnumeration *referenceNames(const CMPIContext * ctx, const CMPIObjectPath * op,
                                  const char *resultClass, const char *role) {
    return CBReferenceNames($self, ctx, op, resultClass, role, NULL);
  }
  CMPIData invokeMethod(const CMPIContext * ctx, const CMPIObjectPath * op, const char *method,
                        const CMPIArgs * in, CMPIArgs * out) {
    return CBInvokeMethod($self, ctx, op, method, in, out, NULL);
  }
  CMPIStatus setProperty(const CMPIContext * ctx, const CMPIObjectPath * op, const char *name,
                         const CMPIValue * value, const CMPIType type) {
    return CBSetProperty($self, ctx, op, name, (CMPIValue *)value, type);
  }
  CMPIData getProperty(const CMPIContext * ctx, const CMPIObjectPath *op, const char *name) {
    return CBGetProperty($self, ctx, op, name, NULL);
  }
  CMPIObjectPath* new_object_path(const char* ns, const char* cname)
  {
    return CMNewObjectPath($self, ns, cname, NULL); 
  }
  CMPIInstance* new_instance(const CMPIObjectPath* path)
  {
    return CMNewInstance($self, path, NULL); 
  }
  CMPIArgs* new_args(void)
  {
    return CMNewArgs($self, NULL); 
  }
  CMPIDateTime* new_datetime(void) {
    return CMNewDateTime($self, NULL);
  }
  /* bintime: Date/Time definition in binary format in microsecods
   *          starting since 00:00:00 GMT, Jan 1,1970.
   * interval: Wenn true, defines Date/Time definition to be an interval value
   */
  CMPIDateTime* new_datetime_from_uint64(uint64_t bintime, int interval = 0 ) {
    return CMNewDateTimeFromBinary($self, bintime, interval, NULL);
  }
  /* utc Date/Time definition in UTC format */
  CMPIDateTime* new_datetime_from_string(const char *utc) {
    return CMNewDateTimeFromChars($self, utc, NULL);
  }
  CMPIString* new_string(const char *s) {
    return CMNewString($self, s, NULL);
  }
  /* count: Maximum number of elements
   * type: Element type
   */
  CMPIArray* new_array(int count, CMPIType type ) {
    return CMNewArray( $self, count, type, NULL);
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
  CMPISelectExp* new_select_exp(const char *query, const char *lang, 
                                CMPIArray **projection) {
    return CMNewSelectExp($self, query, lang, projection, NULL);
  }
  /* Create a new CMPIError object.
  * owner: Identifies the entity that owns the msg format definition.
  * msgID: Identifies the format of the message.
  * msg: Formatted and translated message.
  * sev: Perceived severity of this error.
  * pc: Probable caues of this error.
  * cimStatusCodeStatus: Code.
  */
  CMPIError* new_error(const char *owner, const char* msgID, const char* msg,
     const CMPIErrorSeverity sev, const CMPIErrorProbableCause pc,
     const CMPIrc cimStatusCode)
  {
    return CMNewCMPIError($self, owner, msgID, msg, sev, pc, 
                          cimStatusCode, NULL);    
  }

  void bummer()
  {
    CMPIStatus st;

    CMSetStatusWithChars(
        $self, &st, CMPI_RC_ERR_FAILED, "Bummer! I didn't see that coming");

    _raise_ex(&st);
  }
}
