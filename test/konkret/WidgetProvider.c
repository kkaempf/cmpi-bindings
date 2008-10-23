#include <konkret/konkret.h>
#include "Widget.h"

static const CMPIBroker* _broker = NULL;

static void WidgetInitialize()
{
}

static CMPIStatus WidgetCleanup(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    CMPIBoolean term)
{
    CMReturn(CMPI_RC_OK);
}

static CMPIStatus WidgetEnumInstanceNames(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop)
{
    WidgetRef w;

    /* Widget.Id="1001" */
    WidgetRef_Init(&w, _broker, KNameSpace(cop));
    WidgetRef_Set_Id(&w, "1001");
    KReturnObjectPath(cr, w);

    /* Widget.Id="1002" */
    WidgetRef_Init(&w, _broker, KNameSpace(cop));
    WidgetRef_Set_Id(&w, "1002");
    KReturnObjectPath(cr, w);

    /* Widget.Id=1003 */
    WidgetRef_Init(&w, _broker, KNameSpace(cop));
    WidgetRef_Set_Id(&w, "1003");
    KReturnObjectPath(cr, w);

    CMReturn(CMPI_RC_OK);
}

static CMPIStatus WidgetEnumInstances(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char** properties)
{
    Widget w;

    /* Widget.Id="1001" */
    Widget_Init(&w, _broker, KNameSpace(cop));
    Widget_Set_Id(&w, "1001");
    Widget_Set_Color(&w, "Red");
    Widget_Set_Size(&w, 1);
    KReturnInstance(cr, w);

    /* Widget.Id="1002" */
    Widget_Init(&w, _broker, KNameSpace(cop));
    Widget_Set_Id(&w, "1002");
    Widget_Set_Color(&w, "Green");
    Widget_Set_Size(&w, 2);
    KReturnInstance(cr, w);

    /* Widget.Id=1003 */
    Widget_Init(&w, _broker, KNameSpace(cop));
    Widget_Set_Id(&w, "1003");
    Widget_Set_Color(&w, "Blue");
    Widget_Set_Size(&w, 3);
    KReturnInstance(cr, w);

    CMReturn(CMPI_RC_OK);
}

CMPIStatus WidgetGetInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* result,
    const CMPIObjectPath* cop,
    const char** properties)
{
    WidgetRef wr;
    Widget w;

    WidgetRef_InitFromObjectPath(&wr, _broker, cop);

    if (!wr.Id.exists || wr.Id.null)
        CMReturn(CMPI_RC_ERR_FAILED);

    if (strcmp(wr.Id.chars, "1001") == 0)
    {
        Widget_Init(&w, _broker, KNameSpace(cop));
        Widget_Set_Id(&w, "1001");
        Widget_Set_Color(&w, "Red");
        Widget_Set_Size(&w, 1);
        KReturnInstance(result, w);
        CMReturn(CMPI_RC_OK);
    }
    else if (strcmp(wr.Id.chars, "1002") == 0)
    {
        Widget_Init(&w, _broker, KNameSpace(cop));
        Widget_Set_Id(&w, "1002");
        Widget_Set_Color(&w, "Green");
        Widget_Set_Size(&w, 2);
        KReturnInstance(result, w);
        CMReturn(CMPI_RC_OK);
    }
    else if (strcmp(wr.Id.chars, "1003") == 0)
    {
        Widget_Init(&w, _broker, KNameSpace(cop));
        Widget_Set_Id(&w, "1003");
        Widget_Set_Color(&w, "Blue");
        Widget_Set_Size(&w, 3);
        KReturnInstance(result, w);
        CMReturn(CMPI_RC_OK);
    }

    CMReturn(CMPI_RC_ERR_NOT_FOUND);
}

static CMPIStatus WidgetCreateInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const CMPIInstance* ci)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus WidgetModifyInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const CMPIInstance* ci,
    const char** properties)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus WidgetDeleteInstance(
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop)
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus WidgetExecQuery(
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
    Widget, 
    KC_Widget, 
    _broker, 
    WidgetInitialize())

static CMPIStatus WidgetMethodCleanup(
    CMPIMethodMI* mi,
    const CMPIContext* cc,
    CMPIBoolean term)
{
    CMReturn(CMPI_RC_OK);
}

static CMPIStatus WidgetInvokeMethod(
    CMPIMethodMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char* meth,
    const CMPIArgs* in,
    CMPIArgs* out)
{
    return Widget_DispatchMethod(
        _broker, mi, cc, cr, cop, meth, in, out);
}

CMMethodMIStub(
    Widget,
    KC_Widget,
    _broker,
    WidgetInitialize())

KUint32 Widget_Add(
    const CMPIBroker* cb,
    CMPIMethodMI* mi,
    const CMPIContext* context,
    const KUint32* X,
    const KUint32* Y,
    CMPIStatus* status)
{
    KUint32 result = KUINT32_INIT;

    KSetStatus(status, ERR_NOT_SUPPORTED);
    return result;
}

KONKRET_REGISTRATION(
    "root/cimv2",
    "KC_Widget",
    "KC_Widget",
    "instance method");
