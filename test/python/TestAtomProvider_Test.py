#!/usr/bin/env python
#
#Author: Kenny Woodson
#Date: Mon Sep 17, 2007 
#Description: Script to test the functions of the TestAtomProvider.
#Tests include:
# CreateInstance, EnumerateInstance, EnumerateInstanceNames,
#  ModifyInstance, DeleteInstance, GetInstance
#
###############################################################################

import pywbem
from os import path
import subprocess
import unittest
import math
from lib import wbem_connection
from optparse import OptionParser
conn = None

globalParser = None

_tolerance = .04

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

_atomic_weights = {'Hydrogen': 1.00794,
                   'Helium': 4.002602,
                   'Lithium': 6.941,
                   'Beryllium': 9.012182,
                   'Boron': 10.811,
                   'Carbon': 12.0107,
                   'Nitrogen': 14.0067,
                   'Oxygen': 15.9994,
                   'Fluorine': 18.9984032,
                   'Neon': 20.1797 }

def restart_gmond():
    p = subprocess.Popen([ path.join('/etc/init.d/', "novell-gmond"), \
                          "restart"], stdout=subprocess.PIPE)
    p.wait()


def _compare_values(conn, instance, time):
    types = {'boolProp': 'boolean',
             'dateProp': 'datetime',
             'real32Prop':  'real32',
             'real32Propa': 'real32',
             'real64Prop':  'real64',
             'real64Propa': 'real64',
             'sint16Prop':  'sint16',
             'sint16Propa': 'sint16',
             'sint32Prop':  'sint32',
             'sint32Propa': 'sint32',
             'sint64Prop':  'sint64',
             'sint64Propa': 'sint64',
             'sint8prop':   'sint8',
             'sint8propa':  'sint8',
             'stringProp':  'string',
             'stringPropa': 'string',
             'uint16Prop':  'uint16',
             'uint16Propa': 'uint16',
             'uint32Prop':  'uint32',
             'uint32Propa': 'uint32',
             'uint64Prop':  'uint64',
             'uint64Propa': 'uint64',
             'uint8Prop'  : 'uint8',
             'uint8Propa' : 'uint8' }

    if instance['Name'] in _atoms:
        #print instance['Name']
        atoms_value = _atoms.get(instance['Name'])
        atoms_weight = _atomic_weights[instance['Name']]
        for prop,value in instance.items():
            #print "\nProperty=%s"%str(prop),"Value=%s"%str(value)
            #print "Type=%s"%instance.properties[prop].type
            #Char and Char_array
            if prop == 'char16Prop' or prop == 'char16Propa':
                pass
            #Date Property
            elif prop == 'dateProp':
                if str(instance[prop]) != str(time):
                    raise "DateProp NOT EQUAL"
            #Name or stringProp
            elif prop == 'Name' or prop == 'stringProp':
                if instance['Name'] not in _atoms or \
                   instance['stringProp'] not in _atoms:
                    raise "Atom Name NOT FOUND: %s" & instance['Name']
            #boolProp
            elif prop == 'boolProp':
                if instance[prop] !=  False:
                    raise "False NOT EQUAL False"
            #All values not in lists
            #real64Prop fails this check
            elif (instance.properties[prop].type == types.get(prop)) and \
                  type(instance.properties[prop].value) != type([]):
                if prop == 'uint8Prop':
                    if pywbem.Uint8(atoms_value) != instance[prop]:
                        raise "%s Error: %s" % (prop, instance[prop])
                elif prop.startswith("real"):
                    if _atomic_weights[instance['Name']] != atoms_weight:
                        raise "%s == %s"%(_atomic_weights[instance['Name']],atoms_weight)
                elif atoms_value != value:
                    raise "%s == %s"%(atoms_value,value)
            #All list values
            elif isinstance(instance.properties[prop].value, list) and \
                 instance.properties[prop].type == types.get(prop):
                if prop == 'stringPropa':
                    if value[0] != 'proton' and value[1] != 'electron' \
                       and value[2] != 'neutron':
                        raise "String Array NOT EQUAL"
                elif prop == 'uint8Propa':
                    for val in instance.properties[prop].value:
                        if pywbem.Uint8(atoms_value) != val:
                            raise ("Uint8 Values NOT EQUAL")
                else:
                    #print "\n"
                    #print "instance.properties[prop]=%s"%str(prop)
                    #print "atoms_value=%s"%str(atoms_value)
                    for a_prop in instance.properties[prop].value:
                        #print "a_prop=%s"%str(a_prop)
                        #print "value=%s"%str(value)
                        for num in value: #Array
                            #print "Checking a_prop=%s with num=%s" % (str(a_prop),str(num))
                            #print "startswith=%s"%str(prop.startswith("real"))
                            #if str(instance.properties[prop]).startswith("real"): 
                            if prop.startswith("real"): 
                                #print "Checking num=%s with atoms_weight=%s"%(str(num),str(atoms_weight))
                                if math.fabs(num - atoms_weight) > _tolerance:
                                    raise "%s NOT EQUAL %s" % (str(num), str(atoms_weight))
                            elif a_prop != num:
                                raise "%s NOT EQUAL %s" % (atoms_value, num)
            else:
                raise "%s NOT EQUAL %s" % (atoms_value, value)
    else:
        raise "Instance of Test_Atom not Found: %s" % (instance['Name'])


def get_instance(conn, keybindings, propertylist=None):
    if propertylist is None:
        propertylist = []
    inst = None
    try:
        iname = pywbem.CIMInstanceName(classname='Test_Atom', \
                keybindings=(keybindings), namespace='root/cimv2')
        inst = conn.GetInstance(iname, PropertyList=propertylist)
    except pywbem.CIMError, arg:
        raise (arg)
    return inst


def get_instance_names(conn):
    """
    Open a wbem connection and retrieve the newly created instance names. 
    """

    try:
        ta_list = conn.EnumerateInstanceNames('Test_Atom')
    except pywbem.CIMError, arg:
        raise 
        return None

    return ta_list


def get_test_instances(conn):
    """
    Open a wbem connection and retrieve the newly created instances.
    """

    try:
        ta_list = conn.EnumerateInstances('Test_Atom')
    except pywbem.CIMError, arg:
        raise 
        return None

    return ta_list


def delete_test_instances(conn, del_instances):
    """
    Open a wbem connection and attempt to delete the newly created instance.
    """

    try:
        for atom in del_instances:
            conn.DeleteInstance(atom)
    except pywbem.CIMError, arg:
        raise arg
        return False

    return True

class TestAtomProvider(unittest.TestCase):
    time = pywbem.CIMDateTime.now()

    def setUp(self):
        global conn
        self.inst_paths = []
        self.instance = None
        if conn is None:
            conn = wbem_connection.WBEMConnFromOptions(globalParser)
        unittest.TestCase.setUp(self)

    def tearDown(self):
        for ipath in self.inst_paths:
            try:
                conn.DeleteInstance(ipath)
            except pywbem.CIMError,arg:
                pass
        unittest.TestCase.tearDown(self)



    #def test_1_register(self):
    #    """ Test Register Provider """
    #    testdir = "/usr/lib/pycim"
    #    reginst = pywbem.CIMInstance('OpenWBEM_PyProviderRegistration', \
    #              properties={ 'InstanceID':'TestAtomProvider', \
    #              'NamespaceNames':['root/cimv2'],
    #              'ClassName':'TestAtom',
    #              'ProviderTypes':[pywbem.Uint16(1)], # Indication Handler
    #              'ModulePath':'%s/TestAtomProvider.py' % testdir,
    #               },
    #               path=pywbem.CIMInstanceName('OpenWBEM_PyProviderRegistration',
    #               namespace='Interop')) 
    #        
    #    try:
    #        conn.CreateInstance(reginst)
    #    except pywbem.CIMError, arg:
    #        self.fail("Could not REGISTER %s:%s" % (reginst.classname, str(arg)))
    #    restart_gmond()




    #def test_7_deregister(self):
    #    """ Test Deregister Provider """
    #    conn.default_namespace = 'Interop'
    #    reglist = conn.EnumerateInstanceNames('OpenWBEM_PyProviderRegistration')
    #    for inst_name in reglist:
    #        if inst_name['InstanceID'] == 'TestAtomProvider':
    #            try:
    #                conn.DeleteInstance(inst_name)
    #            except pywbem.CIMError, arg:
    #                self.fail("Could not DEREGISTER Class")

    #    restart_gmond()

    #    try:
    #        conn.GetInstance(inst_name)
    #    except pywbem.CIMError, arg:
    #        self.failUnlessEqual(arg[0], pywbem.CIM_ERR_NOT_FOUND,
    #             'Unexpected exception on GetInstance: %s' % str(arg))


    
    def _create_test_instance(self, name_of_atom, number):
        """ Create a TestAtom instance.  """

        weight = _atomic_weights[name_of_atom]
        #new_instance['char16Prop']  = 
        #new_instance['char16Propa'] = Null
        new_instance = pywbem.CIMInstance('Test_Atom')
        new_instance['Name'] = name_of_atom
        new_instance['boolProp']     = False
        new_instance['dateProp']     = self.time
        new_instance['real32Prop']   = pywbem.Real32(weight)
        new_instance['real32Propa']  = [pywbem.Real32(weight), \
                                        pywbem.Real32(weight), \
                                        pywbem.Real32(weight)]
        new_instance['real64Prop']   = pywbem.Real64(weight)
        new_instance['real64Propa']  = [pywbem.Real64(weight), \
                                        pywbem.Real64(weight), \
                                        pywbem.Real64(weight)]
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
            cipath = conn.CreateInstance(new_instance)
            new_instance.path = cipath
            self.inst_paths.append(cipath)

        except pywbem.CIMError, arg:
            return None, arg

        return new_instance, None 


    def test_2_create_instance(self):
        """Test create"""
        for atom_name, atomic_number in _atoms.items():
            rval, msg = self._create_test_instance(atom_name, atomic_number)
            if not rval:
                self.fail('%s: CreateInstance Failed.' % str(msg))
                continue
            try:
                ci = conn.GetInstance(rval.path)
            except pywbem.CIMError,arg:
                self.fail('GetInstance failed for instance just created')
                continue

            _compare_values(conn, ci, self.time)


    def test_3_enum_instances(self):
        """Test enum_instances"""
        insts = []
        for atom_name, atomic_number in _atoms.items():
            rval, msg = self._create_test_instance(atom_name, atomic_number)
            if not rval:
                self.fail('%s: CreateInstance Failed.' % str(msg))
                continue
            try:
                ci = conn.GetInstance(rval.path)
                insts.append(ci)
            except pywbem.CIMError,arg:
                self.fail('GetInstance failed for instance just created')
                continue
        
        try: 
            ta_list = conn.EnumerateInstances('Test_Atom')
        except pywbem.CIMError, arg:
            self.fail('EnumerateInstances Failed: %s' % str(arg))
            raise

        try:
            paths = conn.EnumerateInstanceNames('Test_Atom')
        except pywbem.CIMError, arg:
            self.fail('EnumerateInstanceNames Failed: %s' % str(arg))

        if len(paths) != len(ta_list):
            self.fail('EnumerateInstances returned different number of '
                'results than EnumerateInstanceNames')

        for ci in insts:
            for rci in ta_list:
                rci.path.host = None
                if rci.path == ci.path:
                    _compare_values(conn, rci, self.time)
                    break
            else:
                self.fail('Did not get a created instance back from EnumerateInstance')
                return


    def test_4_enum_instance_names(self):
        """Test enum_instance_names"""
        insts = []
        for atom_name, atomic_number in _atoms.items():
            rval, msg = self._create_test_instance(atom_name, atomic_number)
            if not rval:
                self.fail('%s: CreateInstance Failed.' % str(msg))
                continue
            try:
                ci = conn.GetInstance(rval.path)
                insts.append(ci)
            except pywbem.CIMError,arg:
                self.fail('GetInstance failed for instance just created')
                continue
        
        try: 
            ta_list = conn.EnumerateInstanceNames('Test_Atom')
        except pywbem.CIMError, arg:
            self.fail('EnumerateInstanceNames Failed: %s' % str(arg))
            raise

        try: 
            instances = conn.EnumerateInstances('Test_Atom')
        except pywbem.CIMError, arg:
            self.fail('EnumerateInstances Failed: %s' % str(arg))

        for ci in insts:
            for path in ta_list:
                path.host = None
                if path == ci.path:
                    break
            else:
                self.fail('Did not get a created instance name back from EnumerateNames')
                return


    def test_5_get_instance_with_property_list(self):
        """Test Get_Instance """
        rinst, msg = self._create_test_instance('Carbon', 6)
        if not rinst:
            self.fail('%s: CreateInstance Failed.' % str(msg))
            return

        propertylist = ['uint16Prop', 'dateProp', 'stringProp', 'real64Prop', \
                        'sint32Propa', 'sint32Prop']
        keybindings = {'Name': 'Carbon'}
        try:
            inst = get_instance(conn, keybindings, propertylist)
        except pywbem.CIMError, arg:
            raise arg

        for prop in inst.properties.keys():
            if prop not in inst.path and prop not in propertylist:
                self.fail("Property Not Found in PropertyList: %s" % prop)


    def test_6_modify_instance(self):
        """Test modify instance"""
        rinst, msg = self._create_test_instance('Boron', 5)
        if not rinst:
            self.fail('%s: CreateInstance Failed.' % str(msg))
            return

        propertylist = ['uint64Prop', 'dateProp', 'stringProp', 'real32Prop', 
                        'sint64Propa', 'sint64prop', 'boolProp']
        keybindings = {'Name': 'Boron'}

        mod_instance = get_instance(conn, keybindings, propertylist)

        weight = _atomic_weights['Boron']
        new_time = pywbem.CIMDateTime.now()
        if mod_instance['boolProp']:
            mod_instance['boolProp'] = False
        else:
            mod_instance['boolProp'] = True
        mod_instance['uint64Prop'] = pywbem.Uint64(2)
        mod_instance['dateProp'] = new_time
        mod_instance['stringProp'] = "Helium"
        mod_instance['real32Prop'] = pywbem.Real32(weight)
        mod_instance['sint64Propa'] = pywbem.CIMProperty('sint64Propa', \
                                        value=[pywbem.Sint64(2),  \
                                        pywbem.Sint64(2), pywbem.Sint64(2)])
        mod_instance['sint64prop'] = pywbem.Sint64(2)
        mod_instance['Name'] = 'Boron'

        try:
            conn.ModifyInstance(mod_instance, PropertyList=propertylist)
        except pywbem.CIMError, arg:
            self.fail(arg)

        mod_instance = get_instance(conn, keybindings, propertylist)
        for prop in mod_instance.properties.keys():
            if prop == 'uint64Prop' or prop == 'sint64Prop':
                self.assertEqual(mod_instance[prop],2,"Values NOT EQUAL")
            elif prop == "real32Prop":
                self.assertTrue(math.fabs(mod_instance[prop] - weight) <\
                        _tolerance,"Values NOT EQUAL")
            elif prop == 'dateProp':
                self.assertNotEquals(self.time,mod_instance[prop], \
                                     "Times ARE EQUAL")
            elif prop == 'sint64Propa':
                for val in mod_instance[prop]:
                    self.assertEquals(val, pywbem.Sint64(2), \
                            ("Values NOT EQUAL: " + str(prop)))
            elif prop == 'stringProp':
                self.assertNotEquals(mod_instance[prop], 'Boron', \
                            ("Values NOT EQUAL"+str(prop))) 
            elif prop == 'boolProp':
                self.assertNotEqual(mod_instance['boolProp'], \
                                   (not mod_instance['boolProp']), \
                                    "ModifyInstance failed.") 


    def test_7_delete(self):
        """Test delete instance"""
        insts = []
        for atom_name, atomic_number in _atoms.items():
            rval, msg = self._create_test_instance(atom_name, atomic_number)
            if not rval:
                self.fail('%s: CreateInstance Failed.' % str(msg))
                continue
            try:
                ci = conn.GetInstance(rval.path)
                insts.append(ci)
            except pywbem.CIMError,arg:
                self.fail('GetInstance failed for instance just created')
                continue

        del_instances = get_instance_names(conn)
        for inst in del_instances:
            try:
                conn.DeleteInstance(inst)
            except pywbem.CIMError, arg:
                self.fail('DeleteInstance Failed: %s' % str(arg))
                break
        else:
            for inst in del_instances:
                try:
                    conn.DeleteInstance(inst)
                except pywbem.CIMError, arg:
                    self.failUnlessEqual(arg[0], pywbem.CIM_ERR_NOT_FOUND,
                         'Unexpected exception on delete: %s' % str(arg))

################################################################################
#Return the TestAtomClass
def get_unit_test():
    return TestAtomProvider

if __name__ == "__main__":
    p = OptionParser()
    wbem_connection.getWBEMConnParserOptions(p)
    options, arguments = p.parse_args()
    globalParser = p

    suite = unittest.makeSuite(TestAtomProvider)
    unittest.TextTestRunner(verbosity=2).run(suite)

