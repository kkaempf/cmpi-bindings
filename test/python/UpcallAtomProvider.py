"""Python Provider for UpcallAtom

Instruments the CIM class UpcallAtom

"""
#This is a Method Provider that will exercise the TestAtomProvider Interface
# by making "up-calls" into the cimom.  The functions that are tested are
# create, delete, enuminst, enuminstnames, modifyinstance
# author: kenny woodson
# Date: Nov. 2007

import os,time,socket
import pywbem
from pywbem.cim_provider2 import CIMProvider2
from socket import getfqdn


_inst_paths = []
_indication_count = 0
_indication_names = { "jon": False,
                      "norm": False,
                      "matt": False, 
                      "bart": False, 
                      "kenny": False, 
                      "brad": False }



# start indication support methods                      

def _createFilter(ch, query='select * from CIM_ProcessIndication',
                  ns='root/interop',
                  querylang='WQL',
                  src_ns='root/cimv2',
                  in_name=None):
    name = in_name or 'cimfilter%s'%time.time()
    filterinst=pywbem.CIMInstance('CIM_IndicationFilter')
    filterinst['CreationClassName']='CIM_IndicationFilter'
    filterinst['SystemCreationClassName']='CIM_ComputerSystem'
    filterinst['SystemName']=getfqdn()
    filterinst['Name']=name
    filterinst['Query']=query
    filterinst['QueryLanguage']=querylang
    filterinst['SourceNamespace']=src_ns
    cop = pywbem.CIMInstanceName('CIM_IndicationFilter')
    cop.keybindings = { 'CreationClassName':'CIM_IndicationFilter',
                        'SystemClassName':'CIM_ComputerSystem',
                        'SystemName':getfqdn(),
                        'Name':name }
    cop.namespace=ns
    filterinst.path = cop
    filtercop = ch.CreateInstance(cop, filterinst)
    return filtercop

def _createDest(ch, destination='http://localhost:5998',
                ns='root/interop',
                in_name=None):
    name = in_name or 'cimlistener%s'%time.time()
    destinst=pywbem.CIMInstance('CIM_ListenerDestinationCIMXML')
    destinst['CreationClassName']='CIM_ListenerDestinationCIMXML'
    destinst['SystemCreationClassName']='CIM_ComputerSystem'
    destinst['SystemName']=getfqdn()
    print "destname=",name
    destinst['Name']=name
    destinst['Destination']=destination
    cop = pywbem.CIMInstanceName('CIM_ListenerDestinationCIMXML')
    cop.keybindings = { 'CreationClassName':'CIM_ListenerDestinationCIMXML',
                        'SystemClassName':'CIM_ComputerSystem',
                        'SystemName':getfqdn(),
                        'Name':name }
    cop.namespace=ns
    destinst.path = cop
    destcop = ch.CreateInstance(cop, destinst)
    return destcop

def _createSubscription(ch, ns='root/interop'):
    replace_ns = ch.default_namespace
    ch.default_namespace=ns
    indfilter=_createFilter(ch)
    indhandler=_createDest(ch)
    subinst=pywbem.CIMInstance('CIM_IndicationSubscription')
    subinst['Filter']=indfilter
    subinst['Handler']=indhandler
    cop = pywbem.CIMInstanceName('CIM_IndicationSubscription')
    cop.keybindings = { 'Filter':indfilter,
                        'Handler':indhandler }
    cop.namespace=ns
    subinst.path = cop
    subcop = ch.CreateInstance(cop, subinst)
    ch.default_namespace=replace_ns
    return subcop


def _deleteSubscription(ch, subcop):
    indfilter = subcop['Filter']
    indhandler= subcop['Handler']
    ch.DeleteInstance(subcop)
    ch.DeleteInstance(indfilter)
    ch.DeleteInstance(indhandler)

# end indication support methods                      


        
                      
################################################################################
_atoms = {'Hydrogen': 1,
         'Helium': 2,
         'Lithium': 3,
         'Beryllium': 4,
         'Boron': 5,
         'Carbon': 6,
         'Nitrogen': 7,
         'Oxygen': 8,
         'Fluorine': 9,
         'Neon': 10 }

################################################################################
def _compare_values(instance, time, logger):
    log = "Entering _compare_values: "
    types = {'boolprop': 'boolean',
             'dateprop': 'datetime',
             'real32prop':  'real32',
             'real32propa': 'real32',
             'real64prop':  'real64',
             'real64propa': 'real64',
             'sint16prop':  'sint16',
             'sint16propa': 'sint16',
             'sint32prop':  'sint32',
             'sint32propa': 'sint32',
             'sint64prop':  'sint64',
             'sint64propa': 'sint64',
             'sint8prop':   'sint8',
             'sint8propa':  'sint8',
             'stringprop':  'string',
             'stringpropa': 'string',
             'uint16prop':  'uint16',
             'uint16propa': 'uint16',
             'uint32prop':  'uint32',
             'uint32propa': 'uint32',
             'uint64prop':  'uint64',
             'uint64propa': 'uint64',
             'uint8prop'  : 'uint8',
             'uint8propa' : 'uint8' }

    print '#### _compare_values called. Name:', instance['Name']

    if instance['Name'] in _atoms:
        #print instance['Name']
        atoms_value = _atoms.get(instance['Name'])
        for pname,value in instance.items():
            prop = pname.lower()
            print '### Checking prop:',prop
            print '### types.get(prop)',str(types.get(prop))
            #Char and Char_array
            if prop == 'char16prop' or prop == 'char16propa':
                pass
            #Date Property
            elif prop == 'dateprop':
                if str(instance[prop]) != str(time):
                    logger.log_debug("DateProp NOT EQUAL")
                    return false 
            #Name or stringProp
            elif prop == 'name' or prop == 'stringprop':
                if instance['name'] not in _atoms or \
                   instance['stringProp'] not in _atoms:
                    logger.log_debug("Atom name NOT FOUND: %s" & instance['name'])
                    return false
            #boolProp
            elif prop == 'boolprop':
                if instance[prop] !=  False:
                    logger.log_debug("False NOT EQUAL False")
                    return false
            #All values not in lists
            elif (instance.properties[prop].type == types.get(prop)) and \
                  value == atoms_value and \
                  type(instance.properties[prop].value) != type([]):
                if prop == 'uint8prop':
                    if pywbem.Uint8(atoms_value) != instance[prop]:
                        logger.log_debug("%s Error: %s" % (prop, instance[prop]))
                        return false
                elif atoms_value != value:
                    logger.log_debug("%s == %s"%(atoms_value,value))
                    return false
            #All list values
            elif type(instance.properties[prop].value) == type([]) and \
                 instance.properties[prop].type == types.get(prop):
                if prop == 'stringpropa':
                    if value[0] != 'proton' and value[1] != 'electron' \
                       and value[2] != 'neutron':
                        logger.log_debug("String Array NOT EQUAL")
                        return false
                elif prop == 'uint8':
                    for val in instance.properties[prop].value:
                        if pywbem.uint8(atoms_value) != val:
                            logger.log_debug("Uint8 Values NOT EQUAL")
                            return false 
                else:
                    for a_prop in instance.properties[prop].value:
                        if a_prop != atoms_value:
                            logger.log_debug("%s NOT EQUAL %s" % (atoms_value\
                                        , value))
                            return false
            else:
                print '!! instance.properties[prop].type:', str(instance.properties[prop].type)
                print '!! types.get(prop):', str(types.get(prop))
                print '!! type(instance.properties[prop].value):', str(type(instance.properties[prop].value))
                print "!! prop:",prop
                print "!! Test Atom %s NOT EQUAL %s" % (atoms_value, value)
                logger.log_debug("%s NOT EQUAL %s" % (atoms_value, value))
                return False
    else:
        logger.log_debug("Instance of TestAtom not Found: %s" % (instance['Name']))
        return false

    return True

################################################################################
def _get_instance(ch, keybindings, propertylist=None):
    if propertylist is None:
        propertylist = []
    inst = None
    try:
        iname = pywbem.CIMInstanceName(classname='Test_Atom', \
                keybindings=(keybindings), namespace='root/cimv2')
        inst = ch.GetInstance(iname, props=propertylist)
    except pywbem.CIMError, arg:
        raise
    return inst


################################################################################
def _get_instance_names(ch):
    """
    Open a wbem connection and retrieve the newly created instance names. 
    """

    try:
        ta_list = ch.EnumerateInstanceNames(ch.default_namespace, 'Test_Atom')
    except pywbem.CIMError, arg:
        raise
    return ta_list


################################################################################
def _delete_test_instances(conn, del_instances): 
    """
    Open a wbem connection and attempt to delete the newly created instance.
    """
    try:
        for atom in del_instances:
            ch.DeleteInstance(ch.default_namespace, atom)
    except pywbem.CIMError, arg:
        raise 

    return True


################################################################################
def _create_test_instance(ch, name_of_atom, number, time):
    """ Create a TestAtom instance.  """
    global _inst_paths

    new_instance = pywbem.CIMInstance('Test_Atom')
    new_instance['Name'] = name_of_atom
    cop = pywbem.CIMInstanceName(namespace=ch.default_namespace, classname='Test_Atom')
    cop['Name'] = name_of_atom
    new_instance.path = cop
    new_instance['boolProp']     = False
    #new_instance['char16Prop']  = 
    #new_instance['char16Propa'] = Null
    new_instance['dateProp']     = time
    new_instance['real32Prop']   = pywbem.Real32(number)
    #new_instance['real32Propa'] = pywbem.CIMProperty('Real32Propa', \ type='Real32', is_array=True, value=None)
    new_instance['real32Propa']  = [pywbem.Real32(number), \
                                    pywbem.Real32(number), \
                                    pywbem.Real32(number)]
    new_instance['real64Prop']   = pywbem.Real64(number)
    new_instance['real64Propa']  = [pywbem.Real64(number), \
                                    pywbem.Real64(number), \
                                    pywbem.Real64(number)]
    new_instance['sint16Prop']   = pywbem.Sint16(number)
    new_instance['sint16Propa']  = [pywbem.Sint16(number), \
                                    pywbem.Sint16(number), \
                                    pywbem.Sint16(number)]
    new_instance['sint32Prop']   = pywbem.Sint32(number)
    new_instance['sint32Propa']  = [pywbem.Sint32(number), \
                                    pywbem.Sint32(number), \
                                    pywbem.Sint32(number)]
    new_instance['sint64Prop']   = pywbem.Sint64(number)
    new_instance['sint64Propa']  = [pywbem.Sint64(number), \
                                    pywbem.Sint64(number), \
                                    pywbem.Sint64(number)]
    new_instance['sint8prop']    = pywbem.Sint8(number)
    new_instance['sint8Propa']   = [pywbem.Sint8(number), \
                                    pywbem.Sint8(number), \
                                    pywbem.Sint8(number)]
    new_instance['stringProp']   = name_of_atom
    new_instance['stringPropa']  = ['proton', 'electron', 'neutron']
    new_instance['uint16Prop']   = pywbem.Uint16(number)
    new_instance['uint16Propa']  = [pywbem.Uint16(number), \
                                    pywbem.Uint16(number), \
                                    pywbem.Uint16(number)]
    new_instance['uint32Prop']   = pywbem.Uint32(number)
    new_instance['uint32Propa']  = [pywbem.Uint32(number), \
                                    pywbem.Uint32(number), \
                                    pywbem.Uint32(number)]
    new_instance['uint64Prop']   = pywbem.Uint64(number)
    new_instance['uint64Propa']  = [pywbem.Uint64(number), \
                                    pywbem.Uint64(number), \
                                    pywbem.Uint64(number)]
    new_instance['uint8Prop']    = pywbem.Uint8(number)
    new_instance['uint8Propa']   = [pywbem.Uint8(number), \
                                    pywbem.Uint8(number), \
                                    pywbem.Uint8(number)]

    try:
        msg = ''
        cipath = ch.CreateInstance(cop, new_instance)
        new_instance.path = cipath
        _inst_paths.append(cipath)

    except pywbem.CIMError, arg:
        raise

    return new_instance, msg 

################################################################################
def _setup(ch, time, env):
    global _inst_paths
    if len(_inst_paths):
        raise '_inst_paths was not empty (%d elements) calling into setup: %s'%(len(_inst_paths),_inst_paths)
    insts = []
    log = ''
    logger = env.get_logger()
    for atom_name, atomic_number in _atoms.items():
        rval, msg = _create_test_instance(ch, atom_name, atomic_number, time)
        if not rval:
            continue
        try:
            ci = ch.GetInstance(rval.path)
            insts.append(ci)
        except pywbem.CIMError,arg:
            raise

    return insts 

################################################################################
def _cleanup(ch, delobjs=True):
    global _inst_paths
        
    if delobjs:
        for ipath in _inst_paths:
            try:
                ch.DeleteInstance(ipath)
            except pywbem.CIMError,arg:
                raise '#### Delete Instance failed on %s: %s'%(ipath, arg)
            except:
                raise
    _inst_paths = []

##############################################################################
def activate_filter(env, filter, namespace, classes, firstActivation):
    print '#### Python activate_filter called. filter: %s' % filter
    print '#### Python firstActivation: %d' % firstActivation

    logger = env.get_logger()
    logger.log_debug('#### Python activate_filter called. filter: %s' % filter)
    logger.log_debug('#### Python firstActivation: %d' % firstActivation)
    if firstActivation: # and not theIndicationThread
        logger.log_debug('#### Got first activation')
        # do thread setup here
        # theIndicationThread = MainMonitorThread(...)
        # theIndicationThread.start()

    '''
    #start an irecv thread here to count the indications received back
    global indThread
    indThread=IndThread()
    indThread.start()
    '''


##############################################################################
def deactivate_filter(env, filter, namespace, classes, lastActivation):
    print '#### Python deactivate_filter called. filter: %s' % filter
    print '#### Python lastActivation: %d' % lastActivation

    logger = env.get_logger()
    logger.log_debug('#### Python deactivate_filter called. filter: %s' % filter)
    logger.log_debug('#### Python lastActivation: %d' % lastActivation)
    if lastActivation == 1: # and theIndicationThread
        logger.log_debug('#### Got last deactivation')
        # do thread teardown here
        # theIndicationThread.shutdown()
        # theIndicationThread = None

    '''
    #delete the irecv thread
    global indThread
    indThread.stop()
    '''

##############################################################################
def authorize_filter(env, filter, namespace, classes, owner):
    print '#### Python authorize_filter called. filter: %s' % filter
    print '#### Python authorize_filter owner: %s' % owner
    logger = env.get_logger()
    logger.log_debug('#### Python authorize_filter called. filter: %s' % filter)
    logger.log_debug('#### Python authorize_filter owner: %s' % owner)
    # if not authorized
    #    raise pywbem.CIM_ERR_ACCESS_DENIED
    return

################################################################################
class UpcallAtomProvider(CIMProvider2):
    """Instrument the CIM class UpcallAtom 

    Testing up-calls into the CIMOM from a provider
    
    """

    def __init__ (self, env):
        print '#### UpcallAtomProvider CTOR'
        logger = env.get_logger()
        logger.log_debug('Initializing provider %s from %s' \
                % (self.__class__.__name__, __file__))
        # If you will be filtering instances yourself according to 
        # property_list, role, result_role, and result_class_name 
        # parameters, set self.filter_results to False
        # self.filter_results = False

    def cim_method_starttest(self, env, object_name):
        """Implements UpcallAtom.starttest()

        Kickoff the method provider test
        
        Keyword arguments:
        env -- Provider Environment (pycimmb.ProviderEnvironment)
        object_name -- A pywbem.CIMInstanceName or pywbem.CIMCLassName 
            specifying the object on which the method starttest() 
            should be invoked.
        method -- A pywbem.CIMMethod representing the method meta-data

        Returns a two-tuple containing the return value (type pywbem.Sint32)
        and a dictionary with the out-parameters

        Output parameters: none

        Possible Errors:
        CIM_ERR_ACCESS_DENIED
        CIM_ERR_INVALID_PARAMETER (including missing, duplicate, 
            unrecognized or otherwise incorrect parameters)
        CIM_ERR_NOT_FOUND (the target CIM Class or instance does not 
            exist in the specified namespace)
        CIM_ERR_METHOD_NOT_AVAILABLE (the CIM Server is unable to honor 
            the invocation request)
        CIM_ERR_FAILED (some other unspecified error occurred)

        """
        global _inst_paths 
        log = []
        insts = []
        time = pywbem.CIMDateTime.now()
        #Create a cimom_handle
        ch = env.get_cimom_handle()
        ch.default_namespace = "root/cimv2"
        logger = env.get_logger()
        logger.log_debug('Entering %s.cim_method_starttest()' \
                % self.__class__.__name__)


#       ch methods =['AssociatorNames', 'Associators', 'References', 'ReferenceNames'
#       'CreateInstance', 'DeleteInstance', 'GetInstance', 'ModifyInstance',
#       'EnumerateInstanceNames', 'EnumerateInstances', 'InvokeMethod', 
#       'DeliverIndication' ]

        print "####### test_1_context #######"
        ## Test context
        if not isinstance(env.ctx['CMPIInvocationFlags'], pywbem.Uint32):
            raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                    'context is broken (1): ' + `env.ctx`)

        oldlen = len(env.ctx)
        env.ctx['foo'] = 'bar'
        if env.ctx['foo'] != 'bar':
            raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                    'context is broken (2): ' + `env.ctx`)

        if oldlen + 1 != len(env.ctx):
            raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                    'context is broken (3): ' + `env.ctx`)

        if not 'foo' in env.ctx:
            raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                    'context is broken (4): ' + `env.ctx`)

        if 'foobar' in env.ctx:
            raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                    'context is broken (5): ' + `env.ctx`)

        env.ctx.update(foobar='foobar')
        if env.ctx['foobar'] != 'foobar':
            raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                    'context is broken (6): ' + `env.ctx`)

        ## end context tests


        #Written to test associators of TestAssoc_User/TestAssoc_Group/TestAssoc_MemberOfGroup classes
        # 
        try:
            user_list = ch.EnumerateInstanceNames(ch.default_namespace, "TestAssoc_User")
            if user_list:
                print "####### test_1A_associatorNames #######"
                # NOTE:  AssociatorNames upcall is currently broken in sfcb
                #        This test will get no assoc_names, but will not fail
                
                # Use the first entry
                user_entry=user_list.next()
                assoc_names = ch.AssociatorNames(user_entry,\
                        assocClass="TestAssoc_MemberOfGroup") #AssocNames
                #TestAssoc_User has an association through TestAssoc_MemberOfGroup
                # to TestAssoc_Group
                for name in assoc_names:
                    if name.classname.lower() != 'TestAssoc_Group':
                        raise "AssociatorName Error: %s" %str(name)

                print "####### test_1B_associators #######"
                # NOTE:  Associators upcall is currently broken in sfcb
                #        This test will get no assocs, but will not fail
                assocs = ch.Associators(user_entry,\
                        assocClass="TestAssoc_MemberOfGroup") #Assocs
                #TestAssoc_User has an association through TestAssoc_MemberOfGroup
                # to TestAssoc_Group
                for assoc in assocs:
                    name = assoc.path
                    if name.classname.lower() != 'TestAssoc_Group':
                        raise "Associator Error: %s" %str(name)

#
#InvokeMethod
#            
            print "####### test_1C_InvokeMethod #######"
            try:
                logger.log_debug("**** Testing InvokeMethod ****")

                new_instance = pywbem.CIMInstance('Test_Method')
                new_instance['id'] = 'One'
                new_instance['p_sint32'] = pywbem.Sint32(1)
                new_instance['p_str'] = 'One'
                cop = pywbem.CIMInstanceName(namespace=ch.default_namespace, classname='Test_Method')
                cop['id'] = 'One'
                new_instance.path = cop
                try:
                    cipath=ch.CreateInstance(cop, new_instance)
                    new_instance.path = cipath
                    gotinst = ch.GetInstance(cipath)

                    #temporary workaround to known provider init bug
                    #must invoke the method provider too, then start over
                    (numinsts,outArgs) = ch.InvokeMethod('Test_Method', 'numinsts')
                except pywbem.CIMError, arg:
                    print "exception: %s" %arg

                    gotinst = ch.GetInstance(cipath)

                (retstr,outArgs) = ch.InvokeMethod(cop, "setStrProp", value=('string','newstr'))
                
                (retstr,outArgs) = ch.InvokeMethod(cop, "getStrProp")
                if retstr != 'newstr':
                    raise "*** Invoke method return val not as expected"
                

            except pywbem.CIMError, arg:
                logger.log_debug("**** CIMError: ch.InvokeMethod ****")
#ReferenceNames
            print "####### test_1D_referenceNames #######"
            # NOTE:  ReferenceNames upcall is currently broken in sfcb
            #        This test will get no refs, but will not fail
            try:
                user_list = ch.EnumerateInstanceNames(ch.default_namespace, "TestAssoc_User")
                for user in user_list:
                    ref_list = ch.ReferenceNames(user)
                    for ref in ref_list:
                        if ref.classname == "TestAssoc_MemberOfGroup":
                            pass
                        else:
                            raise "**** ReferenceNames returned were incorrect ****"

            except pywbem.CIMError, arg:
                logger.log_debug("**** CIMError: ch.ReferenceNames ****")

#Reference
            print "####### test_1E_references #######"
            # NOTE:  References upcall is currently broken in sfcb
            #        This test will get no refs, but will not fail
            try:
                user_list = ch.EnumerateInstanceNames(ch.default_namespace, "TestAssoc_User")
                for user in user_list:
                    ref_list = ch.References(user)
                    for ref in ref_list:
                        if ref.classname == "TestAssoc_MemberOfGroup":
                            pass
                        else:
                            raise "**** References returned were incorrect ****"

            except pywbem.CIMError, arg:
                logger.log_debug("**** CIMError: ch.Reference ****")

#DeliverIndication
            # Separate test for indications

            
        except pywbem.CIMError, arg:
            raise 


################################################################################
#        #test_2_create_instance
        print "####### test_2_create_instance #######"
        try:
            insts = _setup(ch, time, env)
            for inst in insts:
                rval = _compare_values(inst, time, logger)
                if not rval:
                    raise "Object compare failed: Return Value is false"
            _cleanup(ch)
        except pywbem.CIMError, arg:
            raise "**** CreateInstance Failed ****"

################################################################################
        #test_3_enum_instances
        #Test enumeration of instances and then compare them with the local
        # storage dictionary
        print "####### test_3_enum_instances #######"
        insts = _setup(ch, time, env)
        
        ta_list = ch.EnumerateInstances(ch.default_namespace, 'Test_Atom')
        paths = ch.EnumerateInstanceNames(ch.default_namespace, 'Test_Atom')
        lTAList=list(ta_list)
        lNames=list(paths)
    
        if len(lNames) != len(lTAList):
            raise 'EnumerateInstances (%d) returned different number of '\
                'results than EnumerateInstanceNames (%d)' %(len(lTAList), len(lNames))
     
        for ci in insts:#Loop through instances
            for rci in ch.EnumerateInstances(ch.default_namespace, 'Test_Atom'):
                if rci.path != ci.path:
                    continue
                else:
                    rval = _compare_values(rci, time, logger)
                    if rval:
                        break #break out of for rci loop
                    else:
                        continue
            else:
                raise ("**** Error: CIMInstance paths NOT EQUAL ****")
        _cleanup(ch)
        ta_list = []
        paths = []
################################################################################
        #test_4_enum_instance_names
        #Test enumeration of names
        print "####### test_4_enum_instance_names ########"
        insts = _setup(ch, time, env)

        try: 
            ta_list = ch.EnumerateInstanceNames(ch.default_namespace, 'Test_Atom')
        except pywbem.CIMError, arg:
            raise 'EnumerateInstanceNames Failed: %s' % str(arg)

        try: 
            instances = ch.EnumerateInstances(ch.default_namespace, 'Test_Atom')
        except pywbem.CIMError, arg:
            raise 'EnumerateInstances Failed: %s' % str(arg)

        lTAList=list(ta_list)
        lInsts=list(instances)
    
        if len(lInsts) != len(lTAList):
            raise 'EnumerateInstances (%d) returned different number of '\
                'results than EnumerateInstanceNames (%d)' %(len(lInsts), len(lTAList))

        for ci in insts:
            for path in ch.EnumerateInstanceNames(ch.default_namespace, 'Test_Atom'):
                #path.host = None
                if path == ci.path:
                    break
            else:
                raise 'EnumInstNames: Local and retrieved Paths '
                'are NOT EQUAL'

        _cleanup(ch)
        ta_list = []

################################################################################
        #test_5_get_instance_with_property_list
        print "####### test_5_get_instance_with_property_list ########"

        rinst= _create_test_instance(ch, 'Carbon', 6, time)
        if not rinst:
            raise '%s: CreateInstance Failed.' % str(msg)

        propertylist = ['uint16Prop', 'dateProp', 'stringProp', 'real64Prop', \
                        'sint32Propa', 'sint32Prop']
        keybindings = {'Name': 'Carbon'}
        try:
            inst = _get_instance(ch, keybindings, propertylist)
        except pywbem.CIMError, arg:
            raise 'Could not _get_instance on %s'%str(rinst)

        if inst:
            for prop in inst.properties.keys():
                if prop not in propertylist and prop not in inst.keys():
                    raise "Property %s Not Found in PropertyList: %s... checking: %s" % (prop, propertylist, inst.properties.keys())
        _cleanup(ch)

################################################################################
        #test_6_modify_instance
        '''
        print "####### test_6_modify_instance ########"
        #Create an instance of "Boron" and then modify it to Helium
        # Once modified, get_instance returns it and then check the values of it
        rinst = _create_test_instance(ch, 'Boron', 5, time)
        if not rinst:
            raise '%s: CreateInstance Failed.' % str(msg)

        propertylist = ['uint64Prop', 'dateProp', 'stringProp', 'real32Prop', \
                        'sint64Propa', 'sint64prop', 'boolProp']
        keybindings = {'Name': 'Boron'}

        mod_instance = _get_instance(ch, keybindings, propertylist)
        

        if mod_instance:
            new_time = pywbem.CIMDateTime.now()
            if mod_instance['boolProp']:
                mod_instance['boolProp'] = False
            else:
                mod_instance['boolProp'] = True
            mod_instance['uint64Prop'] = pywbem.Uint64(2)
            mod_instance['dateProp'] = new_time
            mod_instance['stringProp'] = "Helium"
            mod_instance['real32Prop'] = pywbem.Real32(2)
            mod_instance['sint64Propa'] = pywbem.CIMProperty('sint64Propa', \
                                            type='sint64', \
                                            value=[pywbem.Sint64(2),  \
                                            pywbem.Sint64(2), pywbem.Sint64(2)])
            mod_instance['sint64prop'] = pywbem.Sint64(2)
            mod_instance['Name'] = 'Boron'

            try:
                ch.ModifyInstance(ch.default_namespace, mod_instance)
            except pywbem.CIMError, arg:
                raise 

            mod_instance = _get_instance(ch, keybindings, propertylist)
            for prop in mod_instance.properties.keys():
                if prop == 'uint64Prop' or prop == 'real32Prop' or \
                   prop == 'sint64Prop':
                    if mod_instance[prop] != 2:
                        raise ("Values %s, %s: NOT EQUAL"%(str(\
                                        mod_instance[prop]), str(2)))
                elif prop == 'dateProp':
                    if time == mod_instance[prop]:
                        raise ("Times %s, %s: ARE EQUAL"%(str(\
                                    mod_instance[prop]), str(2)))
                elif prop == 'sint64Propa':
                    for val in mod_instance[prop]:
                        if val != pywbem.Sint64(2):
                            raise ("Values %s, %s: NOT EQUAL"%(str(\
                                        val), str(2)))
                elif prop == 'stringProp':
                    if val != pywbem.Sint64(2):
                        raise ("Values %s, %s: NOT EQUAL"%(str(\
                                        mod_instance[prop]), 'Boron'))
                elif prop == 'boolProp':
                    if mod_instance['boolProp'] != mod_instance['boolProp']:
                        raise "ModifyInstance failed on boolean property"
        else:
            raise "ModifyInstance Failed!!"
        _cleanup(ch)
        '''

################################################################################
        #test_7_delete
        print "######## test_7_delete #######"
        #Testing the delete upcall for TestAtom
        insts = _setup(ch, time, env)

        del_instances = _get_instance_names(ch)
        for inst in del_instances:
            try:
                ch.DeleteInstance(inst)
            except pywbem.CIMError, arg:
                raise 'DeleteInstance Failed: %s' % str(arg)
        else:
            for inst in del_instances:
                try:
                    ch.DeleteInstance(ch.default_namespace, inst)
                except pywbem.CIMError, arg:
                    if arg[0] != pywbem.CIM_ERR_NOT_FOUND:
                         raise 'Unexpected exception on delete: %s' % str(arg)

        _cleanup(ch, delobjs=False) #cuz they're already deleted, that's what this test is
        out_params = {}
        rval = "Finished testing Upcalls..." # TODO (type pywbem.Sint32)
        return (rval, out_params)

    def cim_method_reset_indication_count(self, env, object_name):
        _indication_count = 0
        return (pywbem.Uint16(0), {})

    def cim_method_get_indication_send_count(self, env, object_name):
        rval = pywbem.Uint16(_indication_count)
        return (rval, {})


    def cim_method_send_indications(self, env, object_name):
        """
        Method to test the upcalls to the cimom handle for DeliverIndications.
        return number of indications sent
        """
        try:
            try:
                global _indication_names,_indication_count
                cimtime = pywbem.CIMDateTime.now()
                ch = env.get_cimom_handle()
                ch.default_namespace = "root/cimv2"
                logger = env.get_logger()

                subcop=_createSubscription(ch)


                for name in _indication_names:
                    alert_ind = pywbem.CIMInstance("UpcallAtom_Indication")
                    alert_ind['AlertType'] = pywbem.Uint16(2)
                    alert_ind['Description'] = name
                    alert_ind['PerceivedSeverity'] = pywbem.Uint16(1)
                    alert_ind['PorbablyCause'] = pywbem.Uint16(1)
                    alert_ind['IndicationTime'] = cimtime
                    alert_ind['SystemName'] = socket.getfqdn()
                    
                    try:
                        print '### Exporting indication. pid:',os.getpid()
                        ch.DeliverIndication(ch.default_namespace, alert_ind)
                        print '### Done exporting indication'
                    except pywbem.CIMError, arg:
                        print '### Caught exception exporting indication'
                        raise

                indcount = len(_indication_names)
                st = time.time()
                while _indication_count < indcount:
                    time.sleep(.01)
                    if (time.time() - st) > 10.00:
                        raise "Only received %d. expected %d" % (_indication_count, indcount)

                for name,received in _indication_names.items():
                    if not received:
                        raise "Indication Not received for: %s" % str(name)
            except:
                raise
        finally:
            _deleteSubscription(ch, subcop)

        out_params = {}
        rval = pywbem.Uint16(indcount) 
        return (rval, out_params)


## end of class UpcallAtomProvider

def get_providers(env): 
    upcallatom_prov = UpcallAtomProvider(env)  
    return {'Test_UpcallAtom': upcallatom_prov} 
