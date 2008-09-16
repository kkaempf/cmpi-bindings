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


_inst_paths = []
_indication_count = 0
_indication_names = { "jon": False,
                      "norm": False,
                      "matt": False, 
                      "bart": False, 
                      "kenny": False, 
                      "brad": False }
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
# Note: consume_indication is called on OpenPegasus because this is an 
#       indication consumer in that environment.
def consume_indication(env, destinationPath, indicationInstance):
    print '#### consume_indication called. pid:',os.getpid()
    global _indication_names,_indication_count
    if indicationInstance['Description'] in _indication_names.keys():
        print '#### consume_indication: My Indication :-)!'
        _indication_names[indicationInstance['Description']] = True
        _indication_count += 1


################################################################################
# Note: handle_indication is called on OpenWBEM because this is an 
#       indication handler in that environment.
def handle_indication(env, ns, handlerInstance, indicationInstance):
    consume_indication(env, None, indicationInstance)

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
        print ">>>>> _get_instance: inst: %s" %inst
    except pywbem.CIMError, arg:
        print ">>>>> _get_instance: raise"
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
def _cleanup(ch):
    global _inst_paths
    for ipath in _inst_paths:
        try:
            ch.DeleteInstance(ipath)
        except pywbem.CIMError,arg:
            raise '#### Delete Instance failed'
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

##############################################################################
def authorize_filter(env, filter, namespace, classes, owner):
    print '#### Python authorize_filter called. filter: %s' % filter
    print '#### Python authorize_filter owner: %s' % owner
    logger = env.get_logger()
    logger.log_debug('#### Python authorize_filter called. filter: %s' % filter)
    logger.log_debug('#### Python authorize_filter owner: %s' % owner)

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
        log = []
        insts = []
        time = pywbem.CIMDateTime.now()
        #Create a cimom_handle
        ch = env.get_cimom_handle()
        ch.default_namespace = "root/cimv2"
        logger = env.get_logger()
        logger.log_debug('Entering %s.cim_method_starttest()' \
                % self.__class__.__name__)


#       ch methods =['AssociatorNames', 'Associators', 'CreateClass', 'CreateInstance', 'DeleteClass', 
#       'DeleteInstance', 'DeleteQualifier', 'EnumerateClassNames', 'EnumerateClasses', 
#       'EnumerateInstanceNames', 'EnumerateInstances', 'EnumerateQualifiers', 'GetClass', #                    'GetInstance', 'GetQualifier', 'InvokeMethod', 'ModifyClass', 'ModifyInstance', #                    'ReferenceNames', 'References', 'SetQualifier', 'export_indication', #                    'set_default_namespace'] 
        #test_1_upcalls
        print "####### test_1_upcalls #######"
        #Written to test associators of Linux_UnixProcess class
        # 
        try:
            logger.log_debug("Getting AssociatorNames")
            ci_list = ch.EnumerateInstanceNames(ch.default_namespace, "Linux_UnixProcess")
            if ci_list and ci_list.length() > 0:
                ci_entry=ci_list.next()
                assoc_names = ch.AssociatorNames(ci_entry,\
                        assocClass="Linux_OSProcess") #AssocNames
                if assoc_names and assoc_names.length() > 0:
                    #Linux_UnixProcess has an association through Linux_OSProcess
                    #1. Linux_OperatingSystem
                    for name in assoc_names:
                        if name['CSCreationClassName'] != 'Linux_UnitaryComputerSystem' \
                          and name['CreationClassName'] != 'Linux_OperatingSystem':
                            raise "AssociatorName Error: %s" %str(name)

                assoc = ch.AssociatorNames(ci_entry, \
                        assocClass="Linux_ProcessExecutable")#Assoc
                if assoc and assoc_names.length() > 0:
                    #Linux_UnixProcess has an association through Linux_ProcessExecutable
                    #1. Linux_LinuxDataFile
                    for inst in assoc:
                        if inst['CSCreationClassName'] != 'CIM_UnitaryComputerSystem' \
                          and inst['CreationClassName'] != 'Linux_LinuxDataFile':
                            raise "Associator Error: %s" %str(inst)

#
#CreateClass Method
#
            '''
            try:
                cim_class = pywbem.CIMClass("Test")
                ch.CreateClass(ch.default_namespace, cim_class)
            except pywbem.CIMError,arg:
                logger.log_debug("**** CIMError: ch.CreateClass ****")
                ch.DeleteClass("Test")
                raise
            '''
#
#GetClass
#
            '''
            try:
                _class = ch.GetClass("Test")
            except pywbem.CIMError,arg:
                logger.log_debug("**** CIMError: ch.GetClass ****")
                raise
            '''
#
#ModifyClass
#
            '''
            try:
                _class.properties['NewBogusProperty'] = pywbem.CIMProperty('BogProp', None, 'uint64')
                ch.ModifyClass(_class)
                _class2 = ch.GetClass("Test")
                if 'BogProp' not in _class2.properties:
                    raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                        'BogProp missing from modified class')
            except pywbem.CIMError,arg:
                logger.log_debug("**** CIMError: ch.ModifyClass ****")
                raise
            '''

#
#DeleteClass
#
            '''
            try:
                ch.DeleteClass("Test")
            except pywbem.CIMError,arg:
                logger.log_debug("**** CIMError: ch.DeleteClass ****")
                raise
            try:
                _class = ch.GetClass("Test")
                raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                    '*** CIMError: DeleteClass GetClass returned '
                    'class just deleted')
            except pywbem.CIMError,arg:
                if arg[0] != pywbem.CIM_ERR_NOT_FOUND:
                    raise
            '''

#
#SetQualifier
#
            '''
            try:
                # Just in case it is still there
                ch.DeleteQualifier('Bogus')
            except pywbem.CIMError, arg:
                pass
            try:
                qdecl = pywbem.CIMQualifierDeclaration('Bogus', 'boolean',
                    value=False, is_array=False, scopes={'class':True}, 
                    overridable=False, tosubclass=True, toinstance=True)
                ch.SetQualifier(qdecl)
            except pywbem.CIMError, arg:
                logger.log_debug("**** CIMError: ch.SetQualifier ****")
                raise
            '''

#
#GetQualifier
#
            '''
            try:
                q = ch.GetQualifier('Bogus')
                copy_q = q.copy() 
                if type(q) != pywbem.cim_obj.CIMQualifierDeclaration:
                    raise "GetQualifier failed."
                logger.log_debug("q=%s"% str(type(q)))
                logger.log_debug("q=%s"% str(dir(q)))
                logger.log_debug("q.name=%s"% str(q.name))
                logger.log_debug("q.value=%s"% str(q.value))
            except pywbem.CIMError,arg:
                logger.log_debug("**** CIMError: ch.GetQualifier ****")
                raise
            '''

#EnumerateQualifiers
            '''
            cq_list = ch.EnumerateQualifiers()
            if not cq_list:
                raise "EnumerateQualifiers Failed"
            else:
                for cq in cq_list:
                    if cq.name.lower() == 'bogus':
                        break;
                else:
                    logger.log_debug('*** CIMError: EnumerateQualifiers did'
                        'not return qualifier that was just created')
                    raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                        '*** CIMError: EnumerateQualifiers did not return '
                        'qualifier that was just created')
            '''
#
#DeleteQualifier
#
            '''
            try:
                ch.DeleteQualifier('Bogus')
            except pywbem.CIMError, arg:
                logger.log_debug("**** CIMError: ch.DeleteQualifier ****")
                raise
            try:
                q = ch.GetQualifier('Bogus')
                raise pywbem.CIMError(pywbem.CIM_ERR_FAILED,
                    '*** CIMError: DeleteQualifier. GetQualifier returned '
                    'qualifier just deleted')
            except pywbem.CIMError,arg:
                if arg[0] != pywbem.CIM_ERR_NOT_FOUND:
                    raise
            '''

#
#InvokeMethod
#            
            try:
                logger.log_debug("**** Calling EnumInstances ****")
                list = ch.EnumerateInstanceNames(ch.default_namespace, "Novell_DCAMStatGatheringService")
                if list and list.length() > 0:
                    logger.log_debug("**** Calling GetINstance ****")
                    list_entry = list.next()
                    service = ch.GetInstance(list_entry)
                    if service:
                        if service['Started']:
                            ch.InvokeMethod("StopService", list_entry)
                        else:
                            ch.InvokeMethod("StartService", list.entry)

                logger.log_debug("**** #2:Calling EnumInstances ****")
                list = ch.EnumerateInstanceNames(ch.default_namespace, "Novell_DCAMStatGatheringService")
                if list and list.length() > 0:
                    logger.log_debug("**** #2:Calling GetInstance ****")
                    list_entry = list.next()
                    service = ch.GetInstance(list_entry)
                    if service:
                        if service['Started']:
                            pass
                        else:
                            ch.InvokeMethod("StartService", list_entry)

            except pywbem.CIMError, arg:
                logger.log_debug("**** CIMError: ch.InvokeMethod ****")

#ReferenceNames
            try:
                stat_list = ch.EnumerateInstanceNames(ch.default_namespace, "Novell_DCAMStatDef")
                if stat_list and stat_list.length() > 0:
                    for statdef in stat_list:
                        if statdef['DefinitionID'] == "machine_type":
                            ref_list = ch.ReferenceNames(statdef)
                            if ref_list and ref_list.length() > 0:
                                for ref in ref_list:
                                    cn = ref.classname 
                                    if cn == "Novell_DCAMCurrentValueForStatDef" or\
                                       cn == "Novell_DCAMStatDefForService":
                                       pass
                                    else:
                                        raise "**** ReferenceNames Returned \
                                            were incorrect ****"
                            break

            except pywbem.CIMError, arg:
                logger.log_debug("**** CIMError: ch.ReferenceNames ****")

#Reference
            try:
                stat_list = ch.EnumerateInstanceNames(ch.default_namespace, "Novell_DCAMStatDef")
                if stat_list and stat_list.length() > 0:
                    for statdef in stat_list:
                        if statdef['DefinitionID'] == "machine_type":
                            ref_list = ch.References(statdef)
                            if ref_list and ref_list.length() > 0:
                                for ref in ref_list:
                                    cn = ref.classname 
                                    if cn == "Novell_DCAMCurrentValueForStatDef" or\
                                       cn == "Novell_DCAMStatDefForService":
                                       pass
                                    else:
                                        raise "**** Reference Returned \
                                            were incorrect ****"
                            break

            except pywbem.CIMError, arg:
                logger.log_debug("**** CIMError: ch.Reference ****")

#export_indication

            
        except pywbem.CIMError, arg:
            raise 


################################################################################
#        #test_2_create_instance
        print "####### test_2_create_instance #######"
        '''
        try:
            insts = _setup(ch, time, env)
            for inst in insts:
                rval = _compare_values(inst, time, logger)
                if not rval:
                    raise "Return Value is false"
            _cleanup(ch)
        except pywbem.CIMError, arg:
            raise "**** CreateInstance Failed ****"
        '''

################################################################################
        #test_3_enum_instances
        #Test enumeration of instances and then compare them with the local
        # storage dictionary
        print "####### test_3_enum_instances #######"
        insts = _setup(ch, time, env)
        paths = []
        ta_list = []
        try: 
            ta_list = ch.EnumerateInstances(ch.default_namespace, 'Test_Atom')
        except pywbem.CIMError, arg:
            raise 'EnumerateInstances failed: %s' % str(arg)
        try:
            paths = ch.EnumerateInstanceNames(ch.default_namespace, 'Test_Atom')
        except pywbem.CIMError, arg:
            raise 'EnumerateInstanceNames failed: %s' % str(arg)

        if paths.length() != ta_list.length():
            raise 'EnumerateInstances (%d) returned different number of '\
                'results than EnumerateInstanceNames (%d)' %(ta_list.length(), paths.length())
      
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

        if instances.length() != ta_list.length():
            raise 'EnumerateInstances returned different number of '\
                'results than EnumerateInstanceNames'

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
            print ">>>>> 1"
        except pywbem.CIMError, arg:
            raise 'Could not _get_instance on %s'%str(rinst)

        print ">>>>> 2"
        if inst:
            print ">>>>> 3"
            for prop in inst.properties.keys():
                print ">>>>> 4"
                if prop not in propertylist:
                    print ">>>>> 5"
                    #raise "Property Not Found in PropertyList: " % prop
        _cleanup(ch)

################################################################################
        #test_6_modify_instance
        print "####### test_6_modify_instance ########"
        '''
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


        out_params = {}
        rval = "Finished testing Upcalls..." # TODO (type pywbem.Sint32)
        return (rval, out_params)

    def cim_method_send_indication(self, env, object_name):
        """
        Method to test the upcalls to the cimom handle for export_indications.
        """
        global _indication_names,_indication_count
        cimtime = pywbem.CIMDateTime.now()
        ch = env.get_cimom_handle()
        ch.default_namespace = "root/cimv2"
        logger = env.get_logger()



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
                ch.export_indication(ch.default_namespace, alert_ind)
                print '### Done exporting indication'
            except pywbem.CIMError, arg:
                print '### Caught exception exporting indication'
                raise

        indcount = _indication_names.length()
        st = time.time()
        while _indication_count < indcount:
            time.sleep(.01)
            if (time.time() - st) > 60.00:
                raise "Only received %d. expected %d" % (_indication_count, indcount)

        for name,received in _indication_names.items():
            if not received:
                raise "Indication Not received for: %s" % str(name)

        out_params = {}
        rval = "Sending indication finished..." # 
        return (rval, out_params)


## end of class UpcallAtomProvider

def get_providers(env): 
    upcallatom_prov = UpcallAtomProvider(env)  
    return {'Test_UpcallAtom': upcallatom_prov} 
