##############################################################################
# Copyright (C) 2008 Novell Inc. All rights reserved.
# Copyright (C) 2008 SUSE Linux Products GmbH. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#   - Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
# 
#   - Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
# 
#   - Neither the name of Novell Inc. nor of SUSE Linux Products GmbH nor the
#     names of its contributors may be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL Novell Inc. OR SUSE Linux Products GmbH OR
# THE CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##############################################################################

# Author: Bart Whiteley <bwhiteley suse.de>

import cmpi


from cim_provider import ProviderProxy
import pywbem


def SFCBUDSConnection():
    return pywbem.WBEMConnection('/tmp/sfcbHttpSocket')

class CIMInstanceNameIterator:
    def __init__(self, enumeration):
        self.enumeration = enumeration

    def __iter__(self):
        return self

    def next(self):
        if not self.enumeration.hasNext():
            raise StopIteration
        val = getattr(self.enumeration.next().value, 'ref')
        if val is None:
            raise StopIteration
        return cmpi2pywbem_instname(val)

class CIMInstanceIterator:
    def __init__(self, enumeration):
        self.enumeration = enumeration

    def __iter__(self):
        return self

    def next(self):
        if not self.enumeration.hasNext():
            raise StopIteration
        val = getattr(self.enumeration.next().value, 'inst')
        if val is None:
            raise StopIteration
        return cmpi2pywbem_inst(val)

class BrokerCIMOMHandle(object):
    def __init__(self, broker, ctx):
        self.broker = broker
        self.ctx = ctx

    def EnumerateInstanceNames(self, ns, cn):
        cop = cmpi.CMPIObjectPath(ns, cn)
        e = self.broker.enumInstanceNames(self.ctx, cop)
        return CIMInstanceNameIterator(e)

    def EnumerateInstances(self, ns, cn, props = None):
        cop = cmpi.CMPIObjectPath(ns, cn)
        e = self.broker.enumInstances(self.ctx, cop, props)
        return CIMInstanceIterator(e)

    def GetInstance(self, path, props = None):
        cop = pywbem2cmpi_instname(path)
        ci = self.broker.getInstance(self.ctx, cop, props)
        if ci is None:
            return None
        return cmpi2pywbem_inst(ci)

    def Associators(self, path, assocClass = None, resultClass = None, 
        role = None, resultRole = None, props = None):
        cop = pywbem2cmpi_instname(path)
        e = self.broker.associators(self.ctx, cop, assocClass, resultClass,
            role, resultRole, props)
        return CIMInstanceIterator(e)

    def AssociatorNames(self, path, assocClass = None, resultClass = None, 
        role = None, resultRole = None, props = None):
        cop = pywbem2cmpi_instname(path)
        e = self.broker.associatorNames(self.ctx, cop, assocClass, resultClass,
            role, resultRole)
        return CIMInstanceNameIterator(e)

    def References(self):
        pass
    def ReferenceNames(self):
        pass
    def InvokeMethod(self):
        pass
    def GetClass(self, *args, **kwargs):
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED)
    def EnumerateClassNames(self, *args, **kwargs):
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED)
    def EnumerateClasses(self, *args, **kwargs):
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED)
    ### Not sure whether this should be on BrokerCIMOMHandle or
    ### on ProviderEnvironment
    ### We may want to move it ?
    def is_subclass(self, ns, super, sub):
        subObjPath=cmpi.CMPIObjectPath(ns, sub)
        return bool(self.broker.classPathIsA(subObjPath,super))


class Logger(object):
    def __init__(self, broker):
        self.broker = broker
    def log_debug(self, msg):
        print msg
    def log_info(self, msg):
        pass
    def log_error(self, msg):
        pass
    def log_fatal(self, msg):
        pass


class ProviderEnvironment(object):
    def __init__(self, broker):
        self.broker = broker
        self.ctx = None
    def get_logger(self):
        return Logger(self.broker)
    def get_cimom_handle(self):
        return SFCBUDSConnection()
    def get_cimom_handle2(self):
        return BrokerCIMOMHandle(self.broker, self.ctx)
    def get_user_name(self):
        pass
    def get_context_value(self, key):
        pass
    def set_context_value(self, key, value):
        pass

_classcache = {}
_conn = SFCBUDSConnection()


class CMPIProvider(object):

    def __init__(self, miname, broker):
        print 'called CMPIProvider(', miname, ',', broker, ')'
        self.broker = broker
        self.miname = miname
        self.env = ProviderEnvironment(self.broker)
        self.proxy = ProviderProxy(self.env, 
                '/usr/lib/pycim/'+miname+'.py')
        #print '*** broker.name()', broker.name()
        #print '*** broker.capabilities()', broker.capabilities()
        #print '*** broker.version()', broker.version()
        broker.LogMessage(1, 'LogID', 
                '** This should go through broker.LogMessage()')

    def enum_instance_names(self, ctx, rslt, objname):
        print 'provider.py: In enum_instance_names()' 
        #test_conversions()
        self.env.ctx = ctx
        op = cmpi2pywbem_instname(objname)
        conn = SFCBUDSConnection()
        try:
            for i in self.proxy.MI_enumInstanceNames(self.env, op):
                cop = pywbem2cmpi_instname(i)
                rslt.return_objectpath(cop)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')

    def enum_instances(self, ctx, rslt, objname, plist):
        print 'provider.py: In enum_instances()' 
        self.env.ctx = ctx
        op = cmpi2pywbem_instname(objname)
        conn = SFCBUDSConnection()
        try:
            for i in self.proxy.MI_enumInstances(self.env, op, plist):
                cinst = pywbem2cmpi_inst(i)
                rslt.return_instance(cinst)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')

    def get_instance(self, ctx, rslt, objname, plist):
        print 'provider.py: In get_instance()' 
        self.env.ctx = ctx
        op = cmpi2pywbem_instname(objname)
        conn = SFCBUDSConnection()
        try:
            pinst = self.proxy.MI_getInstance(self.env, op, plist)
        except pywbem.CIMError, args:
            return args[:2]
        cinst = pywbem2cmpi_inst(pinst)
        rslt.return_instance(cinst)
        rslt.done()
        return (0, '')


    def create_instance(self, ctx, rslt, objname, newinst):
        self.env.ctx = ctx
        pinst = cmpi2pywbem_inst(newinst)
        try:
            piname = self.proxy.MI_createInstance(self.env, pinst)
        except pywbem.CIMError, args:
            return args[:2]
        ciname = pywbem2cmpi_instname(piname)
        rslt.return_objectpath(ciname)
        rslt.done()
        return (0, '')


    def set_instance(self, ctx, rslt, objname, newinst, plist):
        self.env.ctx = ctx
        pinst = cmpi2pywbem_inst(newinst)
        pinst.path = cmpi2pywbem_instname(objname)
        try:
            self.proxy.MI_modifyInstance(self.env, pinst, plist)
        except pywbem.CIMError, args:
            return args[:2]
        return (0, '')

    def delete_instance(self, ctx, rslt, objname):
        piname = cmpi2pywbem_instname(objname)
        try:
            self.proxy.MI_deleteInstance(self.env, piname)
        except pywbem.CIMError, args:
            return args[:2]
        return (0, '')


    def exec_query(self, ctx, rslt, objname, query, lang):
        return (pywbem.CIM_ERR_NOT_SUPPORTED, '')


    def associator_names(self, ctx, rslt, objName, assocClass, resultClass,
            role, resultRole):
        self.env.ctx = ctx
        piname = cmpi2pywbem_instname(objName)

        try:
            for i in self.proxy.MI_associatorNames(self.env, piname, 
                    assocClass, resultClass, role, resultRole):
                ciname = pywbem2cmpi_instname(i)
                rslt.return_objectpath(ciname)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')

    def associators(self, ctx, rslt, objName, assocClass, resultClass,
            role, resultRole, props):
        self.env.ctx = ctx
        piname = cmpi2pywbem_instname(objName)

        try:
            for i in self.proxy.MI_associators(self.env, piname, 
                    assocClass, resultClass, role, resultRole, props):
                cinst = pywbem2cmpi_inst(i)
                rslt.return_instance(cinst)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')


    def reference_names(self, ctx, rslt, objName, resultClass, role):
        print 'pycmpi_provider.py: In reference_names()' 
        self.env.ctx = ctx
        piname = cmpi2pywbem_instname(objName)

        try:
            for i in self.proxy.MI_referenceNames(self.env, piname, 
                    resultClass, role):
                ciname = pywbem2cmpi_instname(i)
                rslt.return_objectpath(ciname)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')


    def references(self, ctx, rslt, objName, resultClass, role, props):
        self.env.ctx = ctx
        piname = cmpi2pywbem_instname(objName)

        try:
            for i in self.proxy.MI_references(self.env, piname, 
                    resultClass, role, props):
                cinst = pywbem2cmpi_inst(i)
                rslt.return_instance(cinst)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')


    def invoke_method(self, ctx, rslt, objName, method, inargs, outargs):
        print '*** in invoke_method'
        self.env.ctx = ctx
        op = cmpi2pywbem_instname(objName)
        pinargs = cmpi2pywbem_args(inargs)
        try:
            ((_type, rv), poutargs) = self.proxy.MI_invokeMethod(self.env, 
                    op, method, pinargs)
        except pywbem.CIMError, args:
            return args[:2]

        pywbem2cmpi_args(poutargs, outargs)


        data, _type = pywbem2cmpi_value(rv, _type=_type)
        rslt.return_data(data, _pywbem2cmpi_typemap[_type])
        rslt.done()
        return (0, '')


    def authorize_filter(self, ctx, filter, className, classPath, owner):
        #self.env.ctx = ctx
        pass

    def activate_filter(self, ctx, filter, className, classPath, 
            firstActivation):
        #self.env.ctx = ctx
        pass


    def deactivate_filter(self, ctx, filter, className, classPath, 
            lastActivation):
        #self.env.ctx = ctx
        pass



    #def must_poll(self, ctx, rslt, filter, className, classPath):
    # NOTE: sfcb signature for this doesn't have the rslt. 
    def must_poll(self, ctx, filter, className, classPath):
        #self.env.ctx = ctx
        pass


    def enable_indications(self, ctx):
        #self.env.ctx = ctx
        pass

    def disable_indications(self, ctx):
        #self.env.ctx = ctx
        pass


def cmpi2pywbem_inst(cmpiinst):
    cop = cmpi2pywbem_instname(cmpiinst.objectpath())
    props = {}
    for i in xrange(0, cmpiinst.property_count()):
        data, name = cmpiinst.get_property_at(i)
        _type, is_array = cmpi_type2string(data.type)
        pval = cmpi2pywbem_data(data, _type, is_array)
        prop = pywbem.CIMProperty(name, pval, _type, is_array=is_array)
        props[name] = prop
    inst = pywbem.CIMInstance(cop.classname, props, path=cop)
    return inst

def cmpi2pywbem_args(cargs):
    r = {}
    for i in xrange(0, cargs.arg_count()):
        data, name = cargs.get_arg_at(i)
        _type, is_array = cmpi_type2string(data.type)
        pval = cmpi2pywbem_data(data, _type, is_array)
        r[name] = pval
    return r

def pywbem2cmpi_args(pargs, cargs=None):
    if cargs is None:
        cargs = cmpi.CMPIArgs()
    for name, (_type, pval) in pargs.items():
        data, _type = pywbem2cmpi_value(pval, _type)
        ctype = _pywbem2cmpi_typemap[_type]
        if isinstance(pval, list):
            ctype = ctype | cmpi.CMPI_ARRAY
        cargs.set(str(name), data, ctype)
    return cargs


def pywbem2cmpi_inst(pinst):
    pcop = pinst.path
    if pcop is None:
        pcop = pywbem.CIMInstanceName(pinst.classname)
    cop = pywbem2cmpi_instname(pcop)
    cinst = cmpi.CMPIInstance(cop)
    for prop in pinst.properties.values():
        data, _type = pywbem2cmpi_value(prop.value, _type=prop.type)
        ctype = _pywbem2cmpi_typemap[_type]
        if isinstance(prop.value, list):
            ctype = ctype | cmpi.CMPI_ARRAY
        cinst.set_property(str(prop.name), data, ctype)
    return cinst



def cmpi2pywbem_instname(cmpiobjpath):
    keys = {}
    for i in xrange(0, cmpiobjpath.key_count()):
        data,keyname = cmpiobjpath.get_key_at(i)
        pval = cmpi2pywbem_data(data)
        keys[keyname] = pval

    rv = pywbem.CIMInstanceName(cmpiobjpath.classname(), 
            keys, namespace=cmpiobjpath.namespace())
    return rv

def pywbem2cmpi_instname(iname):
    cop = cmpi.CMPIObjectPath(iname.namespace, str(iname.classname))
    for name, val in iname.keybindings.items():
        data, _type = pywbem2cmpi_value(val)
        cop.add_key(str(name), data, _pywbem2cmpi_typemap[_type])
    return cop
    
def pywbem2cmpi_value(pdata, _type=None, cval=None):
    if pdata is None:
        assert(_type is not None)
        return None, _type
    is_array = isinstance(pdata, list)
    if _type is None:
        if isinstance(pdata, pywbem.CIMInstance):
            _type = 'instance'
        elif isinstance(pdata, pywbem.CIMInstanceName):
            _type = 'reference'
        else:
            _type = pywbem.cimtype(pdata)
    attr = _type
    if cval is None:
        cval = cmpi.CMPIValue()
    if is_array:
        ralen = len(pdata)
        ctype = _pywbem2cmpi_typemap[_type]
        car = cmpi.CMPIArray(ralen, ctype)
        for i, rael in enumerate(pdata):
            cv, tt = pywbem2cmpi_value(rael, _type=_type)
            car.set(i, cv, ctype)
        cval.array = car
        return cval, _type
    if _type == 'reference':
        attr = 'ref'
        pdata = pywbem2cmpi_instname(pdata)
    elif _type == 'string':
        pdata = cmpi.CMPIString(str(pdata))
    elif _type == 'datetime':
        attr = 'dateTime'
        pdata = pywbem2cmpi_datetime(pdata)
    elif _type == 'instance':
        attr = 'inst'
        pdata = pywbem2cmpi_inst(pdata)
    setattr(cval, attr, pdata)
    return cval, _type

def cmpi2pywbem_value(cval, _type, is_array=False):
    ctype = _type
    if _type == 'reference':
        ctype = 'ref' 
    if is_array:
        pval = []
        car = cval.array
        for i in xrange(0, car.size()):
            data = car.at(i)
            ptype = _cmpi2pywbem_typemap[data.type]
            rael = cmpi2pywbem_value(data.value, _type)
            pval.append(rael)
    else:
        cval = getattr(cval, ctype)
        if _type == 'string':
            pval = cval.to_s()
        elif ctype == 'ref':
            pval = cmpi2pywbem_instname(cval)
        else:
            pval = pywbem.tocimobj(_type, cval)
    return pval



def pywbem2cmpi_data(pdata, _type=None):
    is_array = isinstance(pdata, list)
    if _type is None:
        _type = pywbem.cimtype(pdata)
    # This doesn't work below.  cmpi.CMPIData() takes a CMPIData argument. ??
    data = cmpi.CMPIData()
    data.state = 0
    data.type = pywbem2cmpi_typemap[_type]
    if is_array:
        data.type = data.type | cmpi.CMPI_ARRAY
    if _type == 'reference':
        _type = 'ref'
        pdata = pywbem2cmpi_instname(pdata)
    pywbem2cmpi_value(pdata, _type, data.value)
    return data



def cmpi2pywbem_data(cdata, _type=None, is_array=None):
    #TODO check for valid cdata.state
    #TODO error handling
    if _type is None:
        _type, is_array = cmpi_type2string(cdata.type)
    attr = _type
    if is_array:
        rv = []
        car = cdata.value.array
        if car is None:
            return None
        for i in xrange(0, car.size()):
            adata = car.at(i)
            pdata = cmpi2pywbem_data(adata, _type, is_array=False)
            rv.append(pdata)
        return rv
    if attr == 'datetime':
        attr = 'dateTime'
    if attr == 'reference':
        attr = 'ref'
    if attr == 'instance':
        attr = 'inst'
    val = getattr(cdata.value, attr)
    if val is None:
        return None
    if _type == 'string':
        val = val.to_s()
    if _type == 'boolean':
        val = val == 0 and 'false' or 'true'
    if _type == 'datetime':
        val = cmpi2pywbem_datetime(val)
    if _type == 'reference':
        val = cmpi2pywbem_instname(val)
    if _type == 'instance':
        val = cmpi2pywbem_inst(val)
        return val
    return pywbem.tocimobj(_type, val)

def cmpi2pywbem_datetime(dt):
    return pywbem.CIMDateTime(dt.to_s())

def pywbem2cmpi_datetime(dt):
    return cmpi.CMPIDateTime(str(dt))

_pywbem2cmpi_typemap = {
        'boolean'       : cmpi.CMPI_boolean,
        'real32'        : cmpi.CMPI_real32,
        'real64'        : cmpi.CMPI_real64,
        'uint8'        : cmpi.CMPI_uint8,
        'uint16'        : cmpi.CMPI_uint16,
        'uint32'        : cmpi.CMPI_uint32,
        'uint64'        : cmpi.CMPI_uint64,
        'sint8'        : cmpi.CMPI_sint8,
        'sint16'        : cmpi.CMPI_sint16,
        'sint32'        : cmpi.CMPI_sint32,
        'sint64'        : cmpi.CMPI_sint64,
        'reference'     : cmpi.CMPI_ref,
        'string'        : cmpi.CMPI_string,
        'datetime'      : cmpi.CMPI_dateTime,
        'instance'      : cmpi.CMPI_instance,
        }

_cmpi2pywbem_typemap = {
        0                     : None,
        cmpi.CMPI_boolean     : 'boolean',
        cmpi.CMPI_real32      : 'real32', 
        cmpi.CMPI_real64      : 'real64', 
        cmpi.CMPI_uint8       : 'uint8', 
        cmpi.CMPI_uint16      : 'uint16', 
        cmpi.CMPI_uint32      : 'uint32', 
        cmpi.CMPI_uint64      : 'uint64', 
        cmpi.CMPI_sint8       : 'sint8', 
        cmpi.CMPI_sint16      : 'sint16', 
        cmpi.CMPI_sint32      : 'sint32', 
        cmpi.CMPI_sint64      : 'sint64', 
        cmpi.CMPI_ref         : 'reference', 
        cmpi.CMPI_string      : 'string', 
        cmpi.CMPI_dateTime    : 'datetime', 
        cmpi.CMPI_instance    : 'instance', 

        #cmpi.CMPI_null        : None,
        #cmpi.CMPI_args        : 'args', 
        #cmpi.CMPI_class       : 'class ', 
        #cmpi.CMPI_filter      : 'filter', 
        #cmpi.CMPI_ptr         : 'ptr', 
        #cmpi.CMPI_charsptr    : 'charsp', 
        #cmpi.CMPI_enumeration : 'enumeration', 
        #cmpi.CMPI_chars       : 'chars ', 
        #cmpi.CMPI_char16      : 'char16'
        }

def cmpi_type2string(itype):
    """ Convert an unsigned short CMPIType to the string representation of 
    the type.

    returns a two-tuple: (<str_type>, bool_is_array)

    """

    tp = None
    is_array = bool(itype & cmpi.CMPI_ARRAY)

    if is_array:
        itype = itype ^ cmpi.CMPI_ARRAY

    try:
        tp = _cmpi2pywbem_typemap[itype]
    except KeyError:
        raise ValueError('Unknown type: %d' % itype)

    return (tp, is_array)

'''
def traceback2string(_type, value, tb):
    import traceback
    import cStringIO
    iostr = cStringIO.StringIO()
    traceback.print_exception(_type, value, tb, None, iostr)
    s = iostr.getvalue()
    return (s, 'cmpi:' + s.replace('\n', '<br>'))
    '''


def test_conversions():
    s = 'foo'
    cs, _type = pywbem2cmpi_value(s)
    assert(cs.string.to_s() == s)
    assert(_type == 'string')
    ns = cmpi2pywbem_value(cs, _type)
    assert(s == ns)
    #cdata = cmpi.CMPIData(None)
    i = pywbem.Uint32(5)
    ci, _type = pywbem2cmpi_value(i)
    assert(_type == 'uint32')
    assert(ci.uint32 == i)
    ni = cmpi2pywbem_value(ci, _type)
    assert(isinstance(ni, pywbem.Uint32))
    assert(i == ni)
    l = ['python','is','great']
    cl, _type = pywbem2cmpi_value(l)
    nl = cmpi2pywbem_value(cl, _type, is_array=True)
    assert(nl == l)

    l = [pywbem.Real32(3.4), pywbem.Real32(3.14159)] 
    cl, _type = pywbem2cmpi_value(l)
    nl = cmpi2pywbem_value(cl, _type, is_array=True)
    assert(_type == 'real32')
    for i in xrange(0, len(l)):
        assert(abs(l[i] - nl[i]) <= 0.001)

            
    

    #print s == cmpi2pywbem_

    pcop = pywbem.CIMInstanceName('Cmpi_Swig', namespace='root/cimv2', 
            keybindings={'k1':'A', 'k2':'B'})
    ccop = pywbem2cmpi_instname(pcop)
    ncop = cmpi2pywbem_instname(ccop)
    assert(ncop.classname == 'Cmpi_Swig')
    assert(ncop.namespace == 'root/cimv2')
    assert(len(ncop.keybindings) == 2)
    assert(ncop['k1'] == 'A')
    assert(ncop['k2'] == 'B')

    cinst = cmpi.CMPIInstance(ccop)
    # Klaus, fix this. 
    assert(cinst.objectpath() is not None)

    pinst = pywbem.CIMInstance('Cmpi_Swig', path=pcop, 
            properties={'k1':'A', 'k2':'B',
                'p3':'string prop', 
                'p4':pywbem.Uint32(47)
                })
    cinst = pywbem2cmpi_inst(pinst)
    ninst = cmpi2pywbem_inst(cinst)
    assert(ninst.classname == pinst.classname)
    pinst.properties['n'] = pywbem.CIMProperty('n', None, type='uint32')
    cinst = pywbem2cmpi_inst(pinst)
    ninst = cmpi2pywbem_inst(cinst)
    #assert(ninst['n'] is None)
    assert(ninst.classname == pinst.classname)
    pinst['sint16'] = pywbem.Sint16(16)
    cinst = pywbem2cmpi_inst(pinst)
    ninst = cmpi2pywbem_inst(cinst)
    assert(ninst['sint16'] == 16)
    pinst['sint8'] = pywbem.Sint8(8)
    cinst = pywbem2cmpi_inst(pinst)
    ninst = cmpi2pywbem_inst(cinst)
    assert(ninst['sint8'] == 8)
    pinst['uint8a'] = [pywbem.Uint8(1), pywbem.Uint8(2), pywbem.Uint8(3)]
    cinst = pywbem2cmpi_inst(pinst)
    ninst = cmpi2pywbem_inst(cinst)
    assert(ninst['uint8a'] == pinst['uint8a'])

    pdt = pywbem.CIMDateTime.now()
    cdt = pywbem2cmpi_datetime(pdt)
    ndt = cmpi2pywbem_datetime(cdt)
    assert(pdt == ndt)
    cdt = cmpi.CMPIDateTime('20080623144759.823564-360')
    print '** ctd.is_interval()', cdt.is_interval()
    print '** ctd.to_s()', cdt.to_s()

    pinst['dt'] = pywbem.CIMDateTime('20080623144759.823564-360')
    cinst = pywbem2cmpi_inst(pinst)
    ninst = cmpi2pywbem_inst(cinst)
    print '** ninst["dt"]', ninst['dt']
    print '** pinst["dt"]', pinst['dt']
    assert(ninst['dt'] == pinst['dt'])

    pargs = {
            'one':'one',
            'two':pywbem.Uint32(43), 
            'three':pywbem.CIMDateTime.now(),
            'four':['one','two','three'],
            'five':[pywbem.CIMDateTime.now(), pywbem.CIMDateTime.now()],
            'six':[pywbem.Sint32(-1), pywbem.Sint32(-2)]
            }
    iargs = dict([(k, (pywbem.cimtype(v), v)) for k, v in pargs.items()])
    cargs = pywbem2cmpi_args(iargs)
    nargs = cmpi2pywbem_args(cargs)
    assert(pargs == nargs)


    print '** tests passed' 

