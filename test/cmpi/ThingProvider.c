#include <cmpi/cmpidt.h>
#include <cmpi/cmpimacs.h>

static const CMPIBroker* _broker = NULL;

static void ThingInitialize()
{
}

static CMPIStatus ThingCleanup(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    CMPIBoolean term)
{
    CMReturn(CMPI_RC_OK);
}

static CMPIStatus ThingEnumInstanceNames(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop)
{
    CMReturn(CMPI_RC_OK);
}

static CMPIArray* _make_string_array()
{
    CMPIStatus st;
    CMPIValue value;
    CMPIArray* arr;

    arr = CMNewArray(_broker, 3, CMPI_string, &st);

    if (!arr || st.rc)
        return arr;

    value.string = CMNewString(_broker, "RED", NULL);
    CMSetArrayElementAt(arr, 0, &value, CMPI_string);

    value.string = CMNewString(_broker, "GREEN", NULL);
    CMSetArrayElementAt(arr, 1, &value, CMPI_string);

    value.string = CMNewString(_broker, "BLUE", NULL);
    CMSetArrayElementAt(arr, 2, &value, CMPI_string);

    return arr;
}

static CMPIStatus ThingEnumInstances(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char** properties)
{
    CMPIInstance* inst;
    CMPIObjectPath* tcop;
    CMPIStatus st;
    CMPIValue value;

    /* Create object path */

    tcop = CMNewObjectPath(_broker, "root/cimv2", "Test_Thing", &st);

    if (!tcop || st.rc)
        CMReturn(CMPI_RC_ERR_FAILED);

    st = CMAddKey(tcop, "id", (const CMPIValue*)"RED", CMPI_chars);

    if (st.rc)
        CMReturn(CMPI_RC_ERR_FAILED);

    /* Create instance */

    inst = CMNewInstance(_broker, tcop, &st);

    if (!inst || st.rc)
        CMReturn(CMPI_RC_ERR_FAILED);

    st = CMSetProperty(inst, "id", (const CMPIValue*)"RED", CMPI_chars);

    if (st.rc)
        CMReturn(CMPI_RC_ERR_FAILED);

    value.array = _make_string_array();

    /* ATTN: by setting a string property to a string[], we cause a SIGSEGV
     * in SFCBD.
     */

    st = CMSetProperty(inst, "message", &value, CMPI_ARRAY|CMPI_string);

    if (st.rc)
        CMReturn(CMPI_RC_ERR_FAILED);

    CMReturnInstance(cr, inst);

    CMReturn(CMPI_RC_OK);
}

CMPIStatus ThingGetInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* result,
    const CMPIObjectPath* cop,
    const char** properties)
{
    CMReturn(CMPI_RC_ERR_NOT_FOUND);
}

static CMPIStatus ThingCreateInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const CMPIInstance* ci)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus ThingModifyInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const CMPIInstance* ci,
    const char** properties)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus ThingDeleteInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus ThingExecQuery(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char* lang,
    const char* query)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

CMInstanceMIStub(
    Thing,
    ThingProvider, 
    _broker, 
    ThingInitialize())
