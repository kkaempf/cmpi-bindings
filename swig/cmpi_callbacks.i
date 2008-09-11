# cmpi_callbacks.i
#
# swig bindings for CMPI broker callbacks
#

%nodefault _CMPIBroker;
%rename(CMPIBroker) CMPIBroker;
typedef struct _CMPIBroker {} CMPIBroker;


%extend CMPIBroker {
  CMPIBroker() { return _BROKER; }
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
    return CBEnumInstanceNames($self, ctx, op, NULL);
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
}
