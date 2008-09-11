#!/usr/bin/env python

#import gmetaddata as gmetad
#import gmonddata as gmond
import optparse
import pywbem
from lib import wbem_connection
#import telnetlib as telnet
#import elementtree.ElementTree as ET
#import socket
import unittest
import os
import shutil
import random
import sys

real_tolerance = 0.01

#This test requires the usage of elementtree

_g_opts = None
_g_args = None

def _typed_randrange(lo, hi, type):
    if type == 'sint8':
        return pywbem.Sint8(random.randrange(pywbem.Sint8(lo), pywbem.Sint8(hi)))
    elif type == 'sint16':
        return pywbem.Sint16(random.randrange(pywbem.Sint16(lo), pywbem.Sint16(hi)))
    elif type == 'sint32':
        return pywbem.Sint32(random.randrange(pywbem.Sint32(lo), pywbem.Sint32(hi)))
    elif type == 'sint64':
        return pywbem.Sint64(random.randrange(pywbem.Sint64(lo), pywbem.Sint64(hi)))
    elif type == 'uint8':
        return pywbem.Uint8(random.randrange(pywbem.Uint8(lo), pywbem.Uint8(hi)))
    elif type == 'uint16':
        return pywbem.Uint16(random.randrange(pywbem.Uint16(lo), pywbem.Uint16(hi)))
    elif type == 'uint32':
        return pywbem.Uint32(random.randrange(pywbem.Uint32(lo), pywbem.Uint32(hi)))
    elif type == 'uint64':
        return pywbem.Uint64(random.randrange(pywbem.Uint64(lo), pywbem.Uint64(hi)))
    elif type == 'real32':
        return pywbem.Real32(random.randrange(pywbem.Real32(lo), pywbem.Real32(hi)))
    elif type == 'real64':
        return pywbem.Real64(random.randrange(pywbem.Real64(lo), pywbem.Real64(hi)))
        
################################################################################
class TestMethods(unittest.TestCase):

    limits = {'sint8_min':pywbem.Sint8(-128),
            'sint8_max':pywbem.Sint8(127),
            'sint16_min':pywbem.Sint16(-32768),
            'sint16_max':pywbem.Sint16(32767),
            'sint32_min':pywbem.Sint32(-2147483648),
            'sint32_max':pywbem.Sint32(2147483647),
            'sint64_min':pywbem.Sint64(-92233736854775808L),
            'sint64_max':pywbem.Sint64(9223372036854775807L),
            'uint8_min':pywbem.Uint8(0),
            'uint8_max':pywbem.Uint8(0xFF),
            'uint16_min':pywbem.Uint16(0),
            'uint16_max':pywbem.Uint16(0xFFFF),
            'uint32_min':pywbem.Uint32(0),
            'uint32_max':pywbem.Uint32(0xFFFFFFFF),
            'uint64_min':pywbem.Uint64(0L),
            'uint64_max':pywbem.Uint64(0x7FFFFFFFFFFFFFFFL),
            'real32_min':pywbem.Real32(-123456.78),
            'real32_max':pywbem.Real32(123456.78),
            'real64_min':pywbem.Real64(-12345678987654.32),
            'real64_max':pywbem.Real64(12345678987654.32)}
            # note: the last Uint64 value should be 0xFFFFFFFFFFFFFFFF but there is a bug somewhere...
            
    inttypes = ['sint8', 'sint16', 'sint32', 'sint64', 'uint8', 'uint16', 'uint32', 'uint64']
    
    realtypes = ['real32', 'real64']
    
    zeros = {'sint8':pywbem.Sint8(0),
            'sint16':pywbem.Sint16(0),
            'sint32':pywbem.Sint32(0),
            'sint64':pywbem.Sint64(0),
            'uint8':pywbem.Uint8(0),
            'uint16':pywbem.Uint16(0),
            'uint32':pywbem.Uint32(0),
            'uint64':pywbem.Uint64(0),
            'real32':pywbem.Real32(0),
            'real64':pywbem.Real64(0)}
            
    ones = {'sint8':pywbem.Sint8(1),
            'sint16':pywbem.Sint16(1),
            'sint32':pywbem.Sint32(1),
            'sint64':pywbem.Sint64(1),
            'uint8':pywbem.Uint8(1),
            'uint16':pywbem.Uint16(1),
            'uint32':pywbem.Uint32(1),
            'uint64':pywbem.Uint64(1),
            'real32':pywbem.Real32(0),
            'real64':pywbem.Real64(0)}
            
    tens = {'sint8':pywbem.Sint8(10),
            'sint16':pywbem.Sint16(10),
            'sint32':pywbem.Sint32(10),
            'sint64':pywbem.Sint64(10),
            'uint8':pywbem.Uint8(10),
            'uint16':pywbem.Uint16(10),
            'uint32':pywbem.Uint32(10),
            'uint64':pywbem.Uint64(10),
            'real32':pywbem.Real32(10),
            'real64':pywbem.Real64(10)}
            
    twenties = {'sint8':pywbem.Sint8(20),
            'sint16':pywbem.Sint16(20),
            'sint32':pywbem.Sint32(20),
            'sint64':pywbem.Sint64(20),
            'uint8':pywbem.Uint8(20),
            'uint16':pywbem.Uint16(20),
            'uint32':pywbem.Uint32(20),
            'uint64':pywbem.Uint64(20),
            'real32':pywbem.Real32(20),
            'real64':pywbem.Real64(20)}
            
    numlists = {
            'sint8':[pywbem.Sint8(8), pywbem.Sint8(2), pywbem.Sint8(5),
                    pywbem.Sint8(6), pywbem.Sint8(3), pywbem.Sint8(9),
                    pywbem.Sint8(7), pywbem.Sint8(1), pywbem.Sint8(4)],
            'sint16':[pywbem.Sint16(8), pywbem.Sint16(2), pywbem.Sint16(5),
                    pywbem.Sint16(6), pywbem.Sint16(3), pywbem.Sint16(9),
                    pywbem.Sint16(7), pywbem.Sint16(1), pywbem.Sint16(4)],
            'sint32':[pywbem.Sint32(8), pywbem.Sint32(2), pywbem.Sint32(5),
                    pywbem.Sint32(6), pywbem.Sint32(3), pywbem.Sint32(9),
                    pywbem.Sint32(7), pywbem.Sint32(1), pywbem.Sint32(4)],
            'sint64':[pywbem.Sint64(8), pywbem.Sint64(2), pywbem.Sint64(5),
                    pywbem.Sint64(6), pywbem.Sint64(3), pywbem.Sint64(9),
                    pywbem.Sint64(7), pywbem.Sint64(1), pywbem.Sint64(4)],
            'uint8':[pywbem.Uint8(8), pywbem.Uint8(2), pywbem.Uint8(5),
                    pywbem.Uint8(6), pywbem.Uint8(3), pywbem.Uint8(9),
                    pywbem.Uint8(7), pywbem.Uint8(1), pywbem.Uint8(4)],
            'uint16':[pywbem.Uint16(8), pywbem.Uint16(2), pywbem.Uint16(5),
                    pywbem.Uint16(6), pywbem.Uint16(3), pywbem.Uint16(9),
                    pywbem.Uint16(7), pywbem.Uint16(1), pywbem.Uint16(4)],
            'uint32':[pywbem.Uint32(8), pywbem.Uint32(2), pywbem.Uint32(5),
                    pywbem.Uint32(6), pywbem.Uint32(3), pywbem.Uint32(9),
                    pywbem.Uint32(7), pywbem.Uint32(1), pywbem.Uint32(4)],
            'uint64':[pywbem.Uint64(8), pywbem.Uint64(2), pywbem.Uint64(5),
                    pywbem.Uint64(6), pywbem.Uint64(3), pywbem.Uint64(9),
                    pywbem.Uint64(7), pywbem.Uint64(1), pywbem.Uint64(4)],
            'real32':[pywbem.Real32(8), pywbem.Real32(2), pywbem.Real32(5),
                    pywbem.Real32(6), pywbem.Real32(3), pywbem.Real32(9),
                    pywbem.Real32(7), pywbem.Real32(1), pywbem.Real32(4)],
            'real64':[pywbem.Real64(8), pywbem.Real64(2), pywbem.Real64(5),
                    pywbem.Real64(6), pywbem.Real64(3), pywbem.Real64(9),
                    pywbem.Real64(7), pywbem.Real64(1), pywbem.Real64(4)]}

    def _dbgPrint(self, msg=''):
        if self._verbose:
            if len(msg):
                print('\t -- %s --' % msg)
            else:
                print('')

    def setUp(self):
        unittest.TestCase.setUp(self)
        #wconn = wbem_connection.wbem_connection()
        #self.conn = wconn._WBEMConnFromOptions(_g_opts)
        self.conn = pywbem.PegasusUDSConnection()
        self.conn = pywbem.SFCBUDSConnection()
	self.conn.debug = True
        for iname in self.conn.EnumerateInstanceNames('Test_Method'):
            self.conn.DeleteInstance(iname)
        self._verbose = _g_opts.verbose
        self._dbgPrint()

    def tearDown(self):
        unittest.TestCase.tearDown(self)
        for iname in self.conn.EnumerateInstanceNames('Test_Method'):
            self.conn.DeleteInstance(iname)

    def _run_and_validate_getrand(self,
            type,
            methodName,
            min,
            max,
            expectedReturnValue=None,
            minReturnValue=None,
            maxReturnValue=None):
        isRealType = False
        if type.startswith('real'):
            isRealType = True
        if isRealType:
            self._dbgPrint('Testing %s invocation with min=%f, max=%f' % (methodName, min, max))
        else:
            self._dbgPrint('Testing %s invocation with min=%d, max=%d' % (methodName, min, max))
        (rv, oparams) = self.conn.InvokeMethod(methodName, 'Test_Method', min=min, max=max)
        if not oparams['success']:
            self.fail('"Success" reported as false for invocation of method %s' % methodName)
        if expectedReturnValue is not None:
            if isRealType:
                self._dbgPrint('Verifying return value (%f) equal to expected return value %f...' % (rv, expectedReturnValue))
                if abs(expectedReturnValue - rv) > real_tolerance:
                    self.fail('Return value not as expected for invocation of method %s' % methodName)
            else:
                self._dbgPrint('Verifying return value (%d) equal to expected return value %d...' % (rv, expectedReturnValue))
                if expectedReturnValue != rv:
                    self.fail('Return value not as expected for invocation of method %s' % methodName)
            self._dbgPrint('Return value is as expected.')
        if minReturnValue is not None:
            if isRealType:
                self._dbgPrint('Verifying return value (%f) >= %f' % (rv, minReturnValue))
            else:
                self._dbgPrint('Verifying return value (%d) >= %d' % (rv, minReturnValue))
            if rv < minReturnValue:
                self.fail('Return value less than expected for invocation of method %s' % methodName)
            self._dbgPrint('Return value is as expected.')
        if maxReturnValue is not None:
            if isRealType:
                self._dbgPrint('Verifying return value (%f) <= %f' % (rv, maxReturnValue))
            else:
                self._dbgPrint('Verifying return value (%d) <= %d' % (rv, maxReturnValue))
            if rv > maxReturnValue:
                self.fail('Return value greater than expected for invocation of method %s' % methodName)
            self._dbgPrint('Return value is as expected.')
            
    def _run_and_validate_getrandlist(self,
            type,
            methodName,
            min,
            max,
            nelems):
        isRealType = False
        if type.startswith('real'):
            isRealType = True
        if isRealType:
            self._dbgPrint('Testing %s invocation with min=%f, max=%f' % (methodName, min, max))
        else:
            self._dbgPrint('Testing %s invocation with min=%d, max=%d' % (methodName, min, max))
        (rv, oparams) = self.conn.InvokeMethod(methodName, 'Test_Method', lo=min, hi=max, nelems=nelems)
        if not rv:
            self.fail('Invocation of %s returned false success value.' % methodName)
        self._dbgPrint('Invocation of %s returned successfully.' % methodName)
        if isRealType:
            self._dbgPrint('Validating lo (%f) and hi (%f) outparams...' % (min, max))
            if abs(oparams['lo'] - min) > real_tolerance:
                self.fail('Returned low range value (%f) not equal to specified value (%f).' % (oparams['lo'], min))
            if abs(oparams['hi'] - max) > real_tolerance:
                self.fail('Returned high range value (%f) not equal to specified value (%f).' % (oparams['hi'], max))
        else:
            self._dbgPrint('Validating lo (%d) and hi (%d) outparams...' % (min, max))
            if oparams['lo'] != min:
                self.fail('Returned low range value (%d) not equal to specified value (%d).' % (oparams['lo'], min))
            if oparams['hi'] != max:
                self.fail('Returned high range value (%d) not equal to specified value (%d).' % (oparams['hi'], max))
        self._dbgPrint('Lo and hi outparams validated successfully.')
        self._dbgPrint('Validating random list values...')
        if oparams['nlist'] is None:
            self.fail('Expected a list of values but got none.')
        if len(oparams['nlist']) != nelems:
            self.fail('Expected a list of %d items but got %d items instead.' % (nelems, len(oparams['nlist'])))
        minkey = '%s_min' % type
        maxkey = '%s_max' % type
        for num in oparams['nlist']:
            if num < TestMethods.limits[minkey] or \
                    num > TestMethods.limits[maxkey]:
                if isRealType:
                    self.fail('List element %f not in expected range for type %s.' % (num, type))
                else:
                    self.fail('List element %d not in expected range for type %s.' % (num, type))
        self._dbgPrint('Random list values validated successfully.')
        
    def _run_and_validate_minmedmax(self, type, methodName, numlist):
        self._dbgPrint('Testing %s invocation' % methodName)
        (rv, oparams) = self.conn.InvokeMethod(methodName, 'Test_Method', numlist=numlist)
        if not rv:
            self.fail('Invocation of %s returned false success value.' % methodName)
        self._dbgPrint('Invocation of %s returned successfully.' % methodName)
        self._dbgPrint('Validating min, median, and max outparams...')
        if oparams['min'] != 1:
            self.fail('Expected min of 1 but instead got %d' % oparams['min'])
        if oparams['max'] != 9:
            self.fail('Expected max of 9 but instead got %d' % oparams['max'])
        if oparams['med'] != 5:
            self.fail('Expected median of 5 but instead got %d' % oparams['med'])
        self._dbgPrint('Min, median, and max values validated successfully.')
            
    def _run_numeric_type_tests(self, typelist):
        gr = self._run_and_validate_getrand
        grl = self._run_and_validate_getrandlist
        mmm = self._run_and_validate_minmedmax
        for type in typelist:
            method = 'genRand_%s' % type
            minkey = '%s_min' % type
            maxkey = '%s_max' % type
            min = TestMethods.limits[minkey]
            max = TestMethods.limits[maxkey]
            gr(type, method, min, max, None, min, max)
            gr(type, method, min, min, min)
            gr(type, method, max, max, max)
            if min != 0:
                gr(type, method, TestMethods.zeros[type], TestMethods.zeros[type], TestMethods.zeros[type])
            gr(type, method, TestMethods.tens[type], TestMethods.twenties[type], None, TestMethods.tens[type], TestMethods.twenties[type])
            # the next two should cause exceptions; getting a TypeError exception is not an error in this case.
            try:
                gr(type, method, min-1, min-1, min-1)
            except TypeError:
                pass
            try:
                gr(type, method, max+1, max+1, max+1)
            except TypeError:
                pass
                
            method = 'genRandList_%s' % type
            nelems = _typed_randrange(TestMethods.tens[type], TestMethods.twenties[type], type)
            grl(type, method, min, max, nelems)
            grl(type, method, min, max, TestMethods.ones[type])
            grl(type, method, min, max, TestMethods.zeros[type])
            if min != 0:
                grl(type, method, TestMethods.zeros[type], max, nelems)
            else:
                grl(type, method, min, TestMethods.zeros[type], nelems)
            grl(type, method, TestMethods.tens[type], TestMethods.twenties[type], nelems)
            grl(type, method, TestMethods.tens[type], TestMethods.twenties[type], TestMethods.ones[type])
            grl(type, method, TestMethods.tens[type], TestMethods.twenties[type], TestMethods.zeros[type])
            
            method = 'minmedmax_%s' % type
            mmm(type, method, TestMethods.numlists[type])
    
        
    def test_integer_types(self):
        self._run_numeric_type_tests(TestMethods.inttypes)
            
    def test_real_types(self):
        self._run_numeric_type_tests(TestMethods.realtypes)
        
    def test_refs(self):
        inst = pywbem.CIMInstance('Test_Method', properties={
                'id':'one', 
                'p_str':'One',
                'p_sint32':pywbem.Sint32(1)})
        self.conn.CreateInstance(inst)

        iname = pywbem.CIMInstanceName('Test_Method', namespace='root/cimv2',
                keybindings={'id':'one'})
        rv, outs = self.conn.InvokeMethod('getStrProp', iname)
        self.assertEquals(rv, 'One')

        rv, outs = self.conn.InvokeMethod('setStrProp', iname, value='won')
        self.assertFalse(outs)
        self.assertEquals(rv, 'One')
        rv, outs = self.conn.InvokeMethod('getStrProp', iname)
        self.assertEquals(rv, 'won')
        inst = self.conn.GetInstance(iname)
        self.assertEquals(inst['p_str'], 'won')

        rv, outs = self.conn.InvokeMethod('getIntProp', iname)
        self.assertEquals(rv, 1)
        self.assertTrue(isinstance(rv, pywbem.Sint32))
        self.assertEquals(inst['p_sint32'], 1)
        rv, outs = self.conn.InvokeMethod('setIntProp', iname, 
                value=pywbem.Sint32(2))
        self.assertTrue(isinstance(rv, pywbem.Sint32))
        self.assertEquals(rv, 1)
        self.assertFalse(outs)
        rv, outs = self.conn.InvokeMethod('getIntProp', iname)
        self.assertEquals(rv, 2)
        self.assertTrue(isinstance(rv, pywbem.Sint32))
        inst = self.conn.GetInstance(iname)
        self.assertEquals(inst['p_sint32'], 2)

        rv, outs = self.conn.InvokeMethod('getObjectPath', 'Test_Method')
        self.assertTrue(isinstance(outs['path'], pywbem.CIMInstanceName))
        self.assertEquals(outs['path']['id'], 'one')

        inst = pywbem.CIMInstance('Test_Method', properties={
                'id':'two', 
                'p_str':'Two',
                'p_sint32':pywbem.Sint32(2)})
        self.conn.CreateInstance(inst)

        rv, outs = self.conn.InvokeMethod('getObjectPaths', 'Test_Method')
        self.assertEquals(len(outs['paths']), 2)
        self.assertTrue(isinstance(outs['paths'][0], pywbem.CIMInstanceName))
        to_delete = outs['paths']

        inst = pywbem.CIMInstance('Test_Method', properties={
                'id':'three', 
                'p_str':'Three',
                'p_sint32':pywbem.Sint32(3)})
        self.conn.CreateInstance(inst)

        iname = pywbem.CIMInstanceName('Test_Method', namespace='root/cimv2', 
                keybindings={'id':'three'})

        inames = self.conn.EnumerateInstanceNames('Test_Method')
        self.assertEquals(len(inames), 3)
        rv, outs = self.conn.InvokeMethod('delObject', 'Test_Method', 
                path=iname)

        inames = self.conn.EnumerateInstanceNames('Test_Method')
        self.assertEquals(len(inames), 2)

        self.conn.CreateInstance(inst)

        '''  # OpenWBEM is broken!  uncomment this for Pegasus.  '''
        rv, outs = self.conn.InvokeMethod('delObjects', 'Test_Method', 
                paths=to_delete)
        
        inames = self.conn.EnumerateInstanceNames('Test_Method')
        self.assertEquals(len(inames), 1)
        self.assertEquals(inames[0]['id'], 'three')

    def test_mkUniStr_sint8(self):
        s = 'Scrum Rocks!'
        l = [pywbem.Sint8(ord(x)) for x in s]
        rv, outs = self.conn.InvokeMethod('mkUniStr_sint8', 'Test_Method', 
                cArr=l)
        self.assertFalse(outs)
        self.assertEquals(rv, s)
        rv, outs = self.conn.InvokeMethod('mkUniStr_sint8', 'Test_Method', 
                cArr=[])
        self.assertEquals(rv, '')

    def test_strCat(self):
        ra = ['one','two','three','four']
        rv, outs = self.conn.InvokeMethod('strCat', 'Test_Method', 
                strs=ra, sep=',')
        self.assertEquals(rv, ','.join(ra))
        self.assertFalse(outs)

    def test_strSplit(self):
        ra = 'one,two,three,four'
        rv, outs = self.conn.InvokeMethod('strSplit', 'Test_Method', 
                str=ra, sep=',')
        self.assertEquals(outs['elems'], ra.split(','))
        self.assertTrue(ra)

    def test_getDate(self):
        dt = pywbem.CIMDateTime.now()
        rv, outs = self.conn.InvokeMethod('getDate', 'Test_Method', 
                datestr=str(dt))
        self.assertFalse(outs)
        self.assertEquals(rv, dt)
        self.assertEquals(str(rv), str(dt))
        self.assertTrue(isinstance(rv, pywbem.CIMDateTime))

    def test_getDates(self):
        dt = pywbem.CIMDateTime.now()
        s1 = str(dt)
        ra = [s1]
        dt = pywbem.CIMDateTime(pywbem.datetime.now() + \
                pywbem.timedelta(seconds=10))
        s2 = str(dt)
        ra.append(s2)
        dt = pywbem.CIMDateTime(pywbem.datetime.now() + \
                pywbem.timedelta(seconds=10))
        s3 = str(dt)
        ra.append(s3)

        rv, outs = self.conn.InvokeMethod('getDates', 'Test_Method', 
                datestrs=ra)
        self.assertTrue(rv)
        self.assertTrue(isinstance(rv, bool))
        self.assertEquals(outs['nelems'], len(ra))
        self.assertTrue(isinstance(outs['nelems'], pywbem.Sint32))

        for i in range(0, len(ra)):
            self.assertTrue(isinstance(outs['elems'][i], pywbem.CIMDateTime))
            self.assertEquals(str(outs['elems'][i]), ra[i])

    def test_minmedmax(self):
        for tstr in ['Sint8', 'Uint8', 'Sint16', 'Uint16', 'Sint32', 'Uint32',
                  'Sint64', 'Uint64', 'Real32', 'Real64']:
            dt = getattr(pywbem, tstr)
            method = 'minmedmax_%s' % tstr
            numlist = [
                dt(2),
                dt(5),
                dt(8),
                dt(1),
                dt(9),
                dt(6),
                dt(4),
                dt(7),
                dt(3),
                ]
            rv, outs = self.conn.InvokeMethod(method, 'Test_Method', 
                    numlist=numlist)
            self.assertTrue(rv)
            self.assertTrue(isinstance(rv, bool))
            self.assertTrue(isinstance(outs['min'], dt))
            self.assertTrue(isinstance(outs['med'], dt))
            self.assertTrue(isinstance(outs['max'], dt))
            self.assertEquals(outs['min'], 1)
            self.assertEquals(outs['max'], 9)
            self.assertEquals(outs['med'], 5)


    def test_xembeddedinst(self):
        iname = pywbem.CIMInstanceName('Test_Method', namespace='root/cimv2',
                keybindings = {'id':'one'})
        inst = pywbem.CIMInstance('Test_Method', path=None, 
                properties={'p_str':'str1', 'p_sint32':pywbem.Sint32(1)})
        inst.update(iname)
        rv, outs = self.conn.InvokeMethod('createObject', 'Test_Method', 
                    inst=inst)
        insts = self.conn.EnumerateInstances('Test_Method')
        self.assertEquals(len(insts), 1)
        ninst = self.conn.GetInstance(iname)
        self.assertEquals(ninst['p_str'], 'str1')
        self.assertEquals(ninst['p_sint32'], 1)

        iname2 = pywbem.CIMInstanceName('Test_Method', namespace='root/cimv2',
                keybindings = {'id':'two'})
        inst2 = pywbem.CIMInstance('Test_Method', path=None, 
                properties={'p_str':'str2', 'p_sint32':pywbem.Sint32(2)})
        inst2.update(iname2)

        self.conn.DeleteInstance(iname)
        rv, outs = self.conn.InvokeMethod('createObjects', 'Test_Method', 
                    insts=[inst, inst2])
        insts = self.conn.EnumerateInstances('Test_Method')
        self.assertEquals(len(insts), 2)
        ninst = self.conn.GetInstance(iname2)
        self.assertEquals(ninst['p_str'], 'str2')
        self.assertEquals(ninst['p_sint32'], 2)
        

def get_unit_test():
    return TestMethods


if __name__ == '__main__':
    parser = optparse.OptionParser()
    wbem_connection.getWBEMConnParserOptions(parser)
    parser.add_option('--verbose', '', action='store_true', default=False,
            help='Show verbose output')
    parser.add_option('--level',
            '-l',
            action='store',
            type='int',
            dest='dbglevel',
            help='Indicate the level of debugging statements to display (default=2)',
            default=2)
    _g_opts, _g_args = parser.parse_args()
    
    suite = unittest.makeSuite(TestMethods)
    unittest.TextTestRunner(verbosity=_g_opts.dbglevel).run(suite)

