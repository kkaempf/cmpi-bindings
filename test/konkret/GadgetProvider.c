#include <konkret/konkret.h>
#include "Gadget.h"

static const CMPIBroker* _cb;

static void GadgetInitialize()
{
}

static CMPIStatus GadgetCleanup( 
    CMPIInstanceMI* mi,
    const CMPIContext* cc, 
    CMPIBoolean term)
{
    CMReturn(CMPI_RC_OK);
}

static CMPIStatus GadgetEnumInstanceNames( 
    CMPIInstanceMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop)
{
    const char* ns = KNameSpace(cop);
    WidgetRef left;
    WidgetRef right;
    GadgetRef g;

    /* First Gadget */
    {
        WidgetRef_Init(&left, _cb, ns);
        WidgetRef_Set_Id(&left, "1001");

        WidgetRef_Init(&right, _cb, ns);
        WidgetRef_Set_Id(&right, "1002");

        GadgetRef_Init(&g, _cb, ns);
        GadgetRef_Set_Left(&g, &left);
        GadgetRef_Set_Right(&g, &right);
        // GadgetRef_Print(&g, stdout);
        KReturnObjectPath(cr, g);
    } 

    /* Second Gadget */
    {
        WidgetRef_Init(&left, _cb, ns);
        WidgetRef_Set_Id(&left, "1001");

        WidgetRef_Init(&right, _cb, ns);
        WidgetRef_Set_Id(&right, "1003");

        GadgetRef_Init(&g, _cb, ns);
        GadgetRef_Set_Left(&g, &left);
        GadgetRef_Set_Right(&g, &right);
        // GadgetRef_Print(&g, stdout);
        KReturnObjectPath(cr, g);
    }

    CMReturn(CMPI_RC_OK);
}

static CMPIStatus GadgetEnumInstances( 
    CMPIInstanceMI* mi,
    const CMPIContext* cc, 
    const CMPIResult* cr, 
    const CMPIObjectPath* cop, 
    const char** properties) 
{
    const char* ns = KNameSpace(cop);
    WidgetRef left;
    WidgetRef right;
    Gadget g;

    /* First Gadget */
    {
        WidgetRef_Init(&left, _cb, ns);
        WidgetRef_Set_Id(&left, "1001");

        WidgetRef_Init(&right, _cb, ns);
        WidgetRef_Set_Id(&right, "1002");

        Gadget_Init(&g, _cb, ns);
        Gadget_Set_Left(&g, &left);
        Gadget_Set_Right(&g, &right);
        KReturnInstance(cr, g);
    } 

    /* Second Gadget */
    {
        WidgetRef_Init(&left, _cb, ns);
        WidgetRef_Set_Id(&left, "1001");

        WidgetRef_Init(&right, _cb, ns);
        WidgetRef_Set_Id(&right, "1003");

        Gadget_Init(&g, _cb, ns);
        Gadget_Set_Left(&g, &left);
        Gadget_Set_Right(&g, &right);
        KReturnInstance(cr, g);
    }

    CMReturn(CMPI_RC_OK);
}

static CMPIStatus GadgetGetInstance( 
    CMPIInstanceMI* mi, 
    const CMPIContext* cc,
    const CMPIResult* cr, 
    const CMPIObjectPath* cop, 
    const char** properties) 
{
    const char* ns = KNameSpace(cop);
    GadgetRef gr;
    Gadget g;
    WidgetRef left;
    WidgetRef right;

    if (GadgetRef_InitFromObjectPath(&gr, _cb, cop).rc)
        KReturn(ERR_FAILED);

    if (WidgetRef_InitFromObjectPath(&left, _cb, gr.Left.value).rc)
        KReturn(ERR_FAILED);

    if (WidgetRef_InitFromObjectPath(&right, _cb, gr.Right.value).rc)
        KReturn(ERR_FAILED);

    /* First Gadget */

    if (!strcmp(left.Id.chars, "1001") && !strcmp(right.Id.chars, "1002"))
    {
        WidgetRef_Init(&left, _cb, ns);
        WidgetRef_Set_Id(&left, "1001");

        WidgetRef_Init(&right, _cb, ns);
        WidgetRef_Set_Id(&right, "1002");

        Gadget_Init(&g, _cb, ns);
        Gadget_Set_Left(&g, &left);
        Gadget_Set_Right(&g, &right);
        KReturnInstance(cr, g);
        KReturn(OK);
    } 
    else if (!strcmp(left.Id.chars, "1001") && !strcmp(right.Id.chars, "1003"))
    {
        WidgetRef_Init(&left, _cb, ns);
        WidgetRef_Set_Id(&left, "1001");

        WidgetRef_Init(&right, _cb, ns);
        WidgetRef_Set_Id(&right, "1003");

        Gadget_Init(&g, _cb, ns);
        Gadget_Set_Left(&g, &left);
        Gadget_Set_Right(&g, &right);
        KReturnInstance(cr, g);
        KReturn(OK);
    }

    KReturn(ERR_NOT_FOUND);
}

static CMPIStatus GadgetCreateInstance( 
    CMPIInstanceMI* mi, 
    const CMPIContext* cc, 
    const CMPIResult* cr, 
    const CMPIObjectPath* cop, 
    const CMPIInstance* ci) 
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus GadgetModifyInstance( 
    CMPIInstanceMI* mi, 
    const CMPIContext* cc, 
    const CMPIResult* cr, 
    const CMPIObjectPath* cop,
    const CMPIInstance* ci, 
    const char**properties) 
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus GadgetDeleteInstance( 
    CMPIInstanceMI* mi, 
    const CMPIContext* cc, 
    const CMPIResult* cr, 
    const CMPIObjectPath* cop) 
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus GadgetExecQuery(
    CMPIInstanceMI* mi, 
    const CMPIContext* cc, 
    const CMPIResult* cr, 
    const CMPIObjectPath* cop, 
    const char* lang, 
    const char* query) 
{
    CMReturn(CMPI_RC_ERR_NOT_SUPPORTED);
}

static CMPIStatus GadgetAssociationCleanup( 
    CMPIAssociationMI* mi,
    const CMPIContext* cc, 
    CMPIBoolean term) 
{
    CMReturn(CMPI_RC_OK);
}

static CMPIStatus GadgetAssociators(
    CMPIAssociationMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char* assocClass,
    const char* resultClass,
    const char* role,
    const char* resultRole,
    const char** properties)
{
    return KDefaultAssociators(
        _cb,
        mi,
        cc,
        cr,
        cop,
        Gadget_ClassName,
        assocClass,
        resultClass,
        role,
        resultRole,
        properties);
}

static CMPIStatus GadgetAssociatorNames(
    CMPIAssociationMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char* assocClass,
    const char* resultClass,
    const char* role,
    const char* resultRole)
{
    return KDefaultAssociatorNames(
        _cb,
        mi,
        cc,
        cr,
        cop,
        Gadget_ClassName,
        assocClass,
        resultClass,
        role,
        resultRole);
}

static CMPIStatus GadgetReferences(
    CMPIAssociationMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char* assocClass,
    const char* role,
    const char** properties)
{
    return KDefaultReferences(
        _cb,
        mi,
        cc,
        cr,
        cop,
        Gadget_ClassName,
        assocClass,
        role,
        properties);
}

static CMPIStatus GadgetReferenceNames(
    CMPIAssociationMI* mi,
    const CMPIContext* cc,
    const CMPIResult* cr,
    const CMPIObjectPath* cop,
    const char* assocClass,
    const char* role)
{
    return KDefaultReferenceNames(
        _cb,
        mi,
        cc,
        cr,
        cop,
        Gadget_ClassName,
        assocClass,
        role);
}

CMInstanceMIStub( 
    Gadget,
    KC_Gadget,
    _cb,
    GadgetInitialize())

CMAssociationMIStub( 
    Gadget,
    KC_Gadget,
    _cb,
    GadgetInitialize())

KONKRET_REGISTRATION(
    "root/cimv2",
    "KC_Gadget",
    "KC_Gadget",
    "instance association");
