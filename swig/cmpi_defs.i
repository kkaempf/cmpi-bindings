# cmpi_defs.i
#
# swig bindings for CMPI constant definitions
#

%nodefault CMPIData;
#%ignore _CMPIData::type;
#%ignore _CMPIData::state;
#%ignore _CMPIData::value;
%rename(CMPIData) _CMPIData;

%nodefault CMPIStatus;
#%rename(CMPIStatus) _CMPIStatus;
%ignore _CMPIStatus::rc;
%ignore _CMPIStatus::msg;

%include "cmpidt.h"


#-----------------------------------------------------
#
# CMPIData
#

%extend CMPIData {
  CMPIData()
  {
    CMPIData *data = (CMPIData *)calloc(1, sizeof(CMPIData));
    return data;
  }
  ~CMPIData()
  {
    free( $self );
  }
}


#-----------------------------------------------------
#
# CMPIStatus
#

%extend CMPIStatus {
  CMPIStatus()
  {
    CMPIStatus *status = (CMPIStatus *)calloc(1, sizeof(CMPIStatus));
    status->rc = CMPI_RC_OK;
    return status;
  }
  ~CMPIStatus()
  {
    free( $self );
  }
  int rc() { return $self->rc; }
  char *msg() { return (char *) ($self->msg->hdl); }
#if defined(SWIGRUBY)
  %rename("ok?") is_ok;
#endif
  int is_ok() { return $self->rc == CMPI_RC_OK; }
  const char* to_s() {
    CMPIString *s = CDToString(_BROKER, $self, NULL);
    return CMGetCharPtr(s);
  }
}

