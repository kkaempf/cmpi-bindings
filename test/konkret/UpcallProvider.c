#include <konkret/konkret.h>
#include "Upcall.h"

static const CMPIBroker* _cb = NULL;

static void UpcallInitialize()
{
}

static CMPIStatus UpcallCleanup(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    CMPIBoolean term)
{
    CMReturn(CMPI_RC_OK);
}

static CMPIStatus UpcallEnumInstanceNames(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop)
{
    return KDefaultEnumerateInstanceNames(
        _cb, mi, cc, cr, cop);
}

static CMPIStatus _associators(const CMPIContext* cc)
{
    CMPIObjectPath* op;
    CMPIEnumeration* e;
    CMPIStatus st;
    size_t count = 0;

    if (!(op = CMNewObjectPath(_cb, "root/cimv2", "KC_Widget", NULL)))
        CMReturn(CMPI_RC_ERR_FAILED);

    st = CMAddKey(op, "Id", "1001", CMPI_chars);

    if (st.rc)
        CMReturn(CMPI_RC_ERR_FAILED);

    if (!(e = CBAssociators(_cb, cc, op, NULL, NULL, NULL, NULL, NULL, NULL)))
        CMReturn(CMPI_RC_ERR_FAILED);

    while (CMHasNext(e, NULL))
    {
        CMPIData cd = CMGetNext(e, NULL);

        if (cd.type != CMPI_instance)
            CMReturn(CMPI_RC_ERR_FAILED);

        count++;
    }

    if (count == 0)
        CMReturn(CMPI_RC_ERR_FAILED);

    CMReturn(CMPI_RC_OK);
}

static CMPIStatus _associatorNames(const CMPIContext* cc)
{
    CMPIObjectPath* op;
    CMPIEnumeration* e;
    CMPIStatus st;
    size_t count = 0;

    if (!(op = CMNewObjectPath(_cb, "root/cimv2", "KC_Widget", NULL)))
        CMReturn(CMPI_RC_ERR_FAILED);

    st = CMAddKey(op, "Id", "1001", CMPI_chars);

    if (st.rc)
        CMReturn(CMPI_RC_ERR_FAILED);

    if (!(e = CBAssociatorNames(_cb, cc, op, NULL, NULL, NULL, NULL, NULL)))
        CMReturn(CMPI_RC_ERR_FAILED);

    while (CMHasNext(e, NULL))
    {
        CMPIData cd = CMGetNext(e, NULL);

        if (cd.type != CMPI_ref)
            CMReturn(CMPI_RC_ERR_FAILED);

        count++;
    }

    if (count == 0)
        CMReturn(CMPI_RC_ERR_FAILED);

    CMReturn(CMPI_RC_OK);
}

static CMPIStatus _references(const CMPIContext* cc)
{
    CMPIObjectPath* op;
    CMPIEnumeration* e;
    CMPIStatus st;
    size_t count = 0;

    if (!(op = CMNewObjectPath(_cb, "root/cimv2", "KC_Widget", NULL)))
        CMReturn(CMPI_RC_ERR_FAILED);

    st = CMAddKey(op, "Id", "1001", CMPI_chars);

    if (st.rc)
        CMReturn(CMPI_RC_ERR_FAILED);

    if (!(e = CBReferences(_cb, cc, op, NULL, NULL, NULL, NULL)))
        CMReturn(CMPI_RC_ERR_FAILED);

    while (CMHasNext(e, NULL))
    {
        CMPIData cd = CMGetNext(e, NULL);

        if (cd.type != CMPI_instance)
            CMReturn(CMPI_RC_ERR_FAILED);

        count++;
    }

    if (count == 0)
        CMReturn(CMPI_RC_ERR_FAILED);

    CMReturn(CMPI_RC_OK);
}

static CMPIStatus _referenceNames(const CMPIContext* cc)
{
    CMPIObjectPath* op;
    CMPIEnumeration* e;
    CMPIStatus st;
    size_t count = 0;

    if (!(op = CMNewObjectPath(_cb, "root/cimv2", "KC_Widget", NULL)))
        CMReturn(CMPI_RC_ERR_FAILED);

    st = CMAddKey(op, "Id", "1001", CMPI_chars);

    if (st.rc)
        CMReturn(CMPI_RC_ERR_FAILED);

    if (!(e = CBReferenceNames(_cb, cc, op, NULL, NULL, NULL)))
        CMReturn(CMPI_RC_ERR_FAILED);

    printf("BEFORE\n");

    while (CMHasNext(e, NULL))
    {
        CMPIData cd = CMGetNext(e, NULL);

        printf("INSIDE\n");

        if (cd.type != CMPI_ref)
            CMReturn(CMPI_RC_ERR_FAILED);

        count++;
    }

    printf("AFTER\n");

    if (count == 0)
        CMReturn(CMPI_RC_ERR_FAILED);

    CMReturn(CMPI_RC_OK);
}

static CMPIStatus UpcallEnumInstances(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char** properties)
{
    printf("UpcallEnumInstances\n");

    KTRACE;

    if (_associators(cc).rc != CMPI_RC_OK)
    {
        printf("UpcallEnumInstances: _associators() failed\n");
    }

    KTRACE;

    if (_associatorNames(cc).rc != CMPI_RC_OK)
    {
        printf("UpcallEnumInstances: _associatorNames() failed\n");
    }

    KTRACE;

    if (_references(cc).rc != CMPI_RC_OK)
    {
        printf("UpcallEnumInstances: _references() failed\n");
    }

    KTRACE;

    if (_referenceNames(cc).rc != CMPI_RC_OK)
    {
        printf("UpcallEnumInstances: _referenceNames() failed\n");
    }

    KTRACE;

    CMReturn(CMPI_RC_OK);
}

static CMPIStatus UpcallGetInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char** properties)
{
    return KDefaultGetInstance(
        _cb, mi, cc, cr, cop, properties);
}

static CMPIStatus UpcallCreateInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const CMPIInstance* ci)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus UpcallModifyInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const CMPIInstance* ci,
    const char** properties)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus UpcallDeleteInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus UpcallExecQuery(
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
    Upcall,
    KC_Upcall,
    _cb,
    UpcallInitialize())

static CMPIStatus UpcallMethodCleanup(
    CMPIMethodMI* mi,
    const CMPIContext* cc,
    CMPIBoolean term)
{
    CMReturn(CMPI_RC_OK);
}

static CMPIStatus UpcallInvokeMethod(
    CMPIMethodMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char* meth,
    const CMPIArgs* in,
    CMPIArgs* out)
{
    return Upcall_DispatchMethod(
        _cb, mi, cc, cr, cop, meth, in, out);
}

CMMethodMIStub(
    Upcall,
    KC_Upcall,
    _cb,
    UpcallInitialize())

KONKRET_REGISTRATION(
    "root/cimv2",
    "KC_Upcall",
    "KC_Upcall",
    "instance method");
