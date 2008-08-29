# cmpi_callbacks.i
#
# swig bindings for CMPI broker callbacks
#

%nodefault _CMPIBroker;
%rename(CMPIBroker) CMPIBroker;
typedef struct _CMPIBroker {} CMPIBroker;


%extend CMPIBroker {
  CMPIBroker() { return _BROKER; }
  ~CMPIBroker() { }
  void LogMessage(int severity, const char *id, const char *text) {
    CMLogMessage(_BROKER, severity, id, text, NULL);
  }
  unsigned long capabilities() {
    return CBGetCapabilities(_BROKER);
  }
  int version() {
    return CBBrokerVersion(_BROKER);
  }
  const char *name() {
    return CBBrokerName(_BROKER);
  }
  CMPIStatus deliverIndication(const CMPIContext * ctx, const char * ns, const CMPIInstance * ind) {
    return CBDeliverIndication(_BROKER, ctx, ns, ind);
  }
  CMPIEnumeration* enumInstanceNames(const CMPIContext * ctx, const CMPIObjectPath * op) {
    return CBEnumInstanceNames(_BROKER, ctx, op, NULL);
  }
  CMPIEnumeration *enumInstances(const CMPIContext * ctx, const CMPIObjectPath * op, const char **properties) {
    return CBEnumInstances(_BROKER, ctx, op, properties, NULL);
  }
  CMPIInstance *getInstance(const CMPIContext * ctx, const CMPIObjectPath * op, const char **properties) {
    return CBGetInstance(_BROKER, ctx, op, properties, NULL);
  }
  CMPIObjectPath *createInstance(const CMPIContext * ctx, const CMPIObjectPath * op, const CMPIInstance * inst) {
    return CBCreateInstance(_BROKER, ctx, op, inst, NULL);
  }
  /*
  CMPIStatus setInstance(const CMPIContext* ctx, const CMPIObjectPath* op, const CMPIInstance* inst, const char** properties) { 
    return CBSetInstance(_BROKER, ctx, op, inst, properties);
  }
  */
  CMPIStatus deleteInstance(const CMPIContext * ctx, const CMPIObjectPath * op) {
    return CBDeleteInstance(_BROKER, ctx, op);
  }
  CMPIEnumeration *execQuery(const CMPIContext * ctx, const CMPIObjectPath * op, const char *query, const char *lang) {	  
    return CBExecQuery(_BROKER, ctx, op, query, lang, NULL);
  }
  CMPIEnumeration *associators(const CMPIContext * ctx, const CMPIObjectPath * op,
                               const char *assocClass, const char *resultClass, const char *role,
			       const char *resultRole, const char **properties) {
    return CBAssociators(_BROKER, ctx, op, assocClass, resultClass, role, resultRole, properties, NULL);
  }
  CMPIEnumeration *associatorNames(const CMPIContext * ctx, const CMPIObjectPath * op,
                                   const char *assocClass, const char *resultClass, const char *role,
				   const char *resultRole) {
    return CBAssociatorNames (_BROKER, ctx, op, assocClass, resultClass, role, resultRole, NULL);
  }
  CMPIEnumeration *references(const CMPIContext * ctx, const CMPIObjectPath * op,
                              const char *resultClass, const char *role, const char **properties) {
    return CBReferences(_BROKER, ctx, op, resultClass, role, properties, NULL);
  }
  CMPIEnumeration *referenceNames(const CMPIContext * ctx, const CMPIObjectPath * op,
                                  const char *resultClass, const char *role) {
    return CBReferenceNames(_BROKER, ctx, op, resultClass, role, NULL);
  }
  CMPIData invokeMethod(const CMPIContext * ctx, const CMPIObjectPath * op, const char *method,
                        const CMPIArgs * in, CMPIArgs * out) {
    return CBInvokeMethod(_BROKER, ctx, op, method, in, out, NULL);
  }
  CMPIStatus setProperty(const CMPIContext * ctx, const CMPIObjectPath * op, const char *name,
                         const CMPIValue * value, const CMPIType type) {
    return CBSetProperty(_BROKER, ctx, op, name, (CMPIValue *)value, type);
  }
  CMPIData getProperty(const CMPIContext * ctx, const CMPIObjectPath *op, const char *name) {
    return CBGetProperty(_BROKER, ctx, op, name, NULL);
  }
}
