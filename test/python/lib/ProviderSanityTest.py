import sys
import pywbem
from socket import getfqdn

_verbose = False

def _print (msg, indent=0):
    if _verbose is True:
        for x in xrange(indent):
            sys.__stdout__.write('\t')
        print "\t%s" %msg

###########################################################################
def association_sanity_check(pyunit, 
                             conn, 
                             assocClassName, 
                             verbose = False):
    instance_sanity_check(pyunit, conn, assocClassName, verbose)
    # this does most of the association tests:
    # enumerateInstances
    # enumerateInstanceNames
    # count of each is =
    # elements of each is =
    # getInstance from association instance name
    # getInstance from 'antecedent' and 'dependent' of association
    # Associators/AssociatorNames/References/ReferenceNames

    #print #get some blank lines before we start outputing from here
    global _verbose
    _verbose = verbose
    refClasses={}

    _print("")
    _print("")

    klass=conn.GetClass(assocClassName, LocalOnly=False)
    for propName,prop in klass.properties.items():
        if prop.reference_class is not None:
            refClasses[propName]=prop.reference_class

    tmpStr = ""
    for k,v in refClasses.items():
        tmpStr += '\n\t\t\t%s: %s' %(k,v)
    _print("Entering AssociationSanityCheck.\n\t\tAssocClassName: %s\n\t\t"
           "RefClasses: %s " %(assocClassName, tmpStr),0)

    #get assoc name for reference object check
    instNames = conn.EnumerateInstanceNames(assocClassName)

    _print("Reference Objects Legit?",0)
    #make sure reference objects are legit, etc
    for instName in instNames:
        _print("legit for %s" %instName,2)
        # try get instance
        try:
            _print("Checking 'GetInstance' on the association",1)
            testInst = conn.GetInstance(instName)
            if testInst.path != instName:
                pyunit.fail("In GetInstance, got an instance, but not the "
                            "one I was expecting")
        except pywbem.CIMError, arg:
            pyunit.fail("Got unexected error trying to 'GetInstance' on the "
                        "association: %s" %arg)
        # try get 'reference objects'
        try:
            for rolename in refClasses.keys():
                _print("Checking 'GetInstance' on the association's %s" %rolename,1)
                testInst = conn.GetInstance(instName[rolename])
                if testInst.path != instName[rolename]:
                    pyunit.fail("In GetInstance, got an instance, but not the "
                                "one I was expecting")
        except pywbem.CIMError, arg:
            pyunit.fail("Got unexected error trying to 'GetInstance' on the "
                        "association's %s: %s" %(rolename,arg))

    # Associators/AssociatorNames/References/ReferenceNames

    roles = refClasses.keys()
    # 
    # go through refClasses ('role'='ClassName')

    # Associators
    for role,roleClassName in refClasses.items():
        revAssocRoleName = roles[(roles.index(role)+1)%2]
        revAssocClassName = refClasses[revAssocRoleName]

        _print("")
        _print("Test Associators from RoleClassName: %s (Role: %s)" %(roleClassName, role),0)
        #start by getting first instance name of classname
        testNames = conn.EnumerateInstanceNames(roleClassName)
        #NOTE: Could change this to :
        #for testName in testNames
        # but that could create loads of iterations, depending on the provider
        testName = testNames[0]
#       if testName.host is None:
#            testName.host = getfqdn()
        testName.host = None
        _print("Using first instance of class: %s:" 
               %(roleClassName),1)
        _print(testName, 2)

        #First use Associators with AssocClass
        #use testName to call associators
        _print("Calling Associators with AssocClass=%s" %assocClassName,1)
        assocs = conn.Associators(testName, AssocClass=assocClassName)
        #now use testNameto call associatorNames
        _print("Calling Associator Names with AssocClass=%s" %assocClassName,1)
        assocNames = conn.AssociatorNames(testName, AssocClass=assocClassName)
        
        _print("Same Count?",1)
        #number returned by assocs and assocNames should match
        pyunit.failUnlessEqual(len(assocs), len(assocNames), 
                             "Number of objects returned by Associators(%d) "
                             "and AssociatorNames(%d) doesn't match" 
                             %(len(assocs),len(assocNames)))
        #so should their contents:
        _print("Same objects?",1)
        #first normalize them all by removing all hostnames
        _print("Normalizing")
        for assoc in assocs:
            assoc.path.host = None
        for assocName in assocNames:
            assocName.host = None
        for assoc in assocs:
            if assoc.path not in assocNames:
                pyunit.fail("Associators returned an object %s not returned "
                            "by AssociatorNames" %assoc.path)

        _print("Objects legit?",1)
        for assocName in assocNames:
            try:
                chkInst = conn.GetInstance(assocName)
                if chkInst.path != assocName:
                    pyunit.fail("In GetInstance, got an instance, but not the "
                                "one I was expecting")
            except pywbem.CIMError, arg:
                pyunit.fail("Got unexected error trying to 'GetInstance' on the "
                            "associated object: %s" %arg)

        #for each associator name, we should be able to reverse the association and get at least the starting object
        _print("")
        _print("Check Reverse Associators with AssocClass",1)
        for assocName in assocNames:
            #do associatornames
            _print("Calling Associator Names",2)
            revAssocNames = conn.AssociatorNames(assocName, AssocClass=assocClassName)
            for name in revAssocNames:
                name.host = None
                if not pywbem.is_subclass(conn,
                        'root/cimv2',
                        sub = name.classname,
                        super = roleClassName):
                    pyunit.fail("reverse associator names returned an object type other than %s: %s" %(roleClassName, name.classname))
            _print("Returned original object?",3)
            if testName not in revAssocNames:
                pyunit.fail("Reverse Associator namess from [%s] didn't return the original object: [%s]... returned: [%s]" %(assocName, testName, name))

            #now do associators
            _print("Calling Associators",2)
            revAssocs = conn.Associators(assocName, AssocClass=assocClassName)

            _print("Same Count?",2)
            pyunit.failUnlessEqual(len(revAssocNames), len(revAssocs), 
                             "Number of reverse associator names (%d) and reverse associators (%d) "
                             "returned don't match." %(len(revAssocNames), len(revAssocs)))

            _print("Same Objects?",2)
            # make sure names match... 
            for assoc in revAssocs:
                assoc.path.host = None
                if not pywbem.is_subclass(conn,
                        'root/cimv2',
                        sub = assoc.classname,
                        super = roleClassName):
                    pyunit.fail("reverse associators returned an object type other than %s: %s" %(roleClassname, assoc.classname))
                if assoc.path not in revAssocNames:
                    pyunit.fail("Reverse Associators from [%s] returned an object not returned by reverse associator names %s" %(assocName, assoc.path))

        _print("Check Reverse Associators with ResultClass",1)
        #use testNameto call associatorNames
        _print("Calling Associator Names ",2)
        revAssocNames = conn.AssociatorNames(testName, ResultClass=revAssocClassName)
        #Now use Associators with ResultClass
        _print("Calling Associators",2)
        revAssocs = conn.Associators(testName, ResultClass=revAssocClassName)
        
        _print("Same Count?",2)
        #number returned by assocs and assocNames should match
        pyunit.failUnlessEqual(len(revAssocs), len(revAssocNames), 
                             "Number of objects returned by Associators(%d) "
                             "and AssociatorNames(%d) doesn't match" 
                             %(len(revAssocs),len(revAssocNames)))
        #so should their contents:
        _print("Same Objects?",2)
        for rAssocName in revAssocNames:
            rAssocName.host = None
        for revAssoc in revAssocs:
            revAssoc.path.host = None
            if revAssoc.path not in revAssocNames:
                pyunit.fail("Associators returned an object %s not returned "
                            "by AssociatorNames" %revAssoc.path)



        _print("Test References with ResultClass = %s" %assocClassName,0)
        _print("Calling ReferenceNames ",1)
        refNames = conn.ReferenceNames(testName, ResultClass=assocClassName)
        _print("Calling References ",1)
        refs = conn.References(testName, ResultClass=assocClassName)
        _print("Same Count?",1)
        pyunit.failUnlessEqual(len(refNames), len(refs), 
                             "Number of objects returned by References(%d) "
                             "and ReferenceNames(%d) doesn't match" 
                             %(len(refs), len(refNames)))
        _print("Same Count As Associators?",1)
        pyunit.failUnlessEqual(len(refNames), len(assocNames), 
                             "Number of objects returned by ReferenceNames(%d) "
                             "and AssociatorNames(%d) doesn't match" 
                             %(len(refNames), len(assocNames)))
        _print("Same Objects?",1)
        for rname in refNames:
            rname.host = None
        for ref in refs:
            ref.path.host = None
            if ref.path not in refNames:
                pyunit.fail("References returned an object %s not returned "
                            "by ReferenceNames" %ref.path)
        _print("Same Objects As Associators?",1)
        for rname in refNames:
#rname[revAssocRoleName].host=getfqdn()
            if rname[revAssocRoleName] not in assocNames:
                pyunit.fail("ReferenceNames returned an object \n[%s]\n not returned "
                            "by AssociatorNames \n%s" %(rname[revAssocRoleName], assocNames))

    _print("Leaving AssociationSanityCheck")


def instance_sanity_check(pyunit, 
                         conn, 
                         className, 
                         verbose = False):
    global _verbose
    _verbose = verbose
    reqProps=[]

    _print("")
    _print("")

    #get the class
    klass=conn.GetClass(className, LocalOnly=False)
    #get the 'required' properties
    for propName,prop in klass.properties.items():
        if 'Required' in prop.qualifiers:
            if prop.qualifiers['Required'].value is True:
                reqProps.append(propName)

    _print("Entering InstanceSanityCheck.\n\t\tClassName: %s\n\t\t"
           %(className),0)

    _print("")
    _print("Test enumInstances / enumInstanceNames for sanity (same # objects, etc)",0)
    #get assoc name count
    _print("Enumerating instance names of %s" %className, 1)
    instNames = conn.EnumerateInstanceNames(className)
    _print("Resulted in %d objects" %len(instNames),2)

    #get assoc instance count
    _print("Enumerating instances of %s" %className, 1)
    insts = conn.EnumerateInstances(className)
    _print("Resulted in %d objects" %len(insts),2)

    #compare instName count with inst count
    _print("Same Count?",1)
    pyunit.failUnlessEqual(len(instNames), len(insts), 
                     "Number of instance names (%d) and instances (%d) "
                     "returned don't match." %(len(instNames), len(insts)))

    # make sure names match... 
    # inst.path in instances should be found in instNames
    _print("Same Objects?",1)
    for inst in insts:
        if inst.path not in instNames:
            pyunit.fail("EnumInstances returned an instance not found in "
                        "results from EnumInstanceNames")

    _print("Objects Legit?",1)
    #make sure objects are legit, etc
    for instName in instNames:
        _print("legit for %s" %instName,2)
        # try get instance
        try:
            _print("Checking 'GetInstance' on the instName %s" %str(instName),3)
            testInst = conn.GetInstance(instName)
            if testInst.path != instName:
                pyunit.fail("In GetInstance, got an instance, but not the "
                            "one I was expecting")
        except pywbem.CIMError, arg:
            pyunit.fail("Got unexected error trying to 'GetInstance' on the "
                        "instName: %s" %arg)

    #all 'required' properties filled in?
    _print("Required properties not empty?",1)
    for inst in insts:
        _print("Checking instance: %s" %inst.path,2)
        for propName in reqProps:
            _print("Checking required property: %s" %propName,3)
            if inst[propName] is None or inst[propName] == "":
                pyunit.fail("Retrieved an instance with empty required "
                            "property [%s].  InstanceName: %s " %(propName, inst.path))

    _print("Leaving InstanceSanityCheck")


