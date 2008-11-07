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

from pywbem.cim_provider2 import ProviderProxy
import pywbem
import types
import syslog
import sys


import cmpi

##==============================================================================
##
## _exception_to_error()
##
##     This function converts a cmpi.CMPIException to a pywbem.CIMError.
##
##==============================================================================

def _exception_to_error(ex):

    code = ex.get_error_code()
    desc = ex.get_description()

    if code < 0 or code > 17:
        if desc is None:
            desc = str(code)
        else:
            desc = str(code) + ':' + desc
        code = pywbem.CIM_ERR_FAILED

    return pywbem.CIMError(code, desc)

##==============================================================================
##
## ExceptionMethodWrapper
##
##     This class puts an exception translation block around any method. This
##     block catches a cmpi.CMPIException, converts it a pywbem.CIMError, and
##     raises the new exception.
##
##==============================================================================

class ExceptionMethodWrapper:

    def __init__(self, meth):
        self.meth = meth

    def __call__(self, *args, **kwds):
        try:
            return self.meth(*args, **kwds)
        except cmpi.CMPIException,e:
            exc_class, exc, tb = sys.exc_info()
            new_exc = _exception_to_error(e)
            raise new_exc.__class__, new_exc, tb


##==============================================================================
##
## ExceptionClassWrapper
##
##     This class puts an exception translation block around all methods of any
##     class. It creates an ExceptionMethodWrapper to invoke each method. For
##     example, the following snipett wraps an instance of the Gadget class.
##    
##         g = Gadget()
##         w = ExceptionClassWrapper(g)
##         w.foo() # call g.foo() with exception translation block around it.
##
##==============================================================================

class ExceptionClassWrapper:

    def __init__(self, obj):
        self.obj = obj

    def __getattr__(self, name):
        attr = getattr(self.obj, name)

        if type(attr) is types.MethodType:
            return ExceptionMethodWrapper(attr)
        else:
            return attr

##==============================================================================
##
## _mwrap()
##
##     Wrap a method in a try block.
##
##==============================================================================

def _mwrap(obj, meth, *args, **kwds):
    try:
        return obj.meth(*args, **kwds)
    except cmpi.CMPIException,e:
        raise _exception_to_error(e)

##==============================================================================
##
## _fwrap()
##
##     Wrap a function in a try block.
##
##==============================================================================

def _fwrap(meth, *args, **kwds):
    try:
        return meth(*args, **kwds)
    except cmpi.CMPIException,e:
        raise _exception_to_error(e)

##==============================================================================
##
##
##
##==============================================================================

class ContextWrap(object):
    def __init__(self, proxy, cmpicontext):
        self.proxy = proxy
        self.cmpicontext = cmpicontext

    def __getitem__(self, key):
        data = self.cmpicontext.get_entry(key)
        _type, is_array = _cmpi_type2string(data.type)
        return self.proxy.cmpi2pywbem_data(data, _type, is_array)

    def __setitem__(self, key, pval):
        data, _type = self.proxy.pywbem2cmpi_value(pval)
        ctype = _pywbem2cmpi_typemap[_type]
        if isinstance(pval, list):
            ctype = ctype | cmpi.CMPI_ARRAY
        self.cmpicontext.add_entry(str(key), data, ctype)

    def __len__(self):
        return self.cmpicontext.get_entry_count()

    def __repr__(self):
        return `self.todict()`

    def keys(self):
        return self.todict().keys()

    def items(self):
        return self.todict().items()

    def values(self):
        return self.todict().values()

    def __contains__(self, key):
        return key in self.todict()

    def has_key(self, key):
        return self.todict().has_key(key)

    def iterkeys(self):
        return self.todict().iterkeys()

    def itervalues(self):
        return self.todict().itervalues()

    def iteritems(self):
        return self.todict().iteritems()

    def update(self, *args, **kwargs):
        for mapping in args:
            if hasattr(mapping, 'items'):
                for k, v in mapping.items():
                    self[k] = v
            else:
                for (k, v) in mapping:
                    self[k] = v
        for k, v in kwargs.items():
            self[k] = v

    def get(self, key, default = None):
        try:
            return self.todict()[key]
        except KeyError:
            return default

    def todict(self):
        d = {}
        for i in xrange(0, self.cmpicontext.get_entry_count()):
            data, name = self.cmpicontext.get_entry_at(i)
            _type, is_array = _cmpi_type2string(data.type)
            pval = self.proxy.cmpi2pywbem_data(data, _type, is_array)
            d[name] = pval
        return d


class BrokerCIMOMHandle(object):
    def __init__(self, proxy, ctx):
        #self.broker = proxy.broker
        self.broker = ExceptionClassWrapper(proxy.broker)
        self.proxy = proxy
        self.ctx = ctx

    def _yield_instance_names(self, e):
        while e and e.hasNext():
            data=e.next()
            assert(data.type == cmpi.CMPI_ref)
            piname=self.proxy.cmpi2pywbem_instname(data.value.ref)
            yield piname

    def EnumerateInstanceNames(self, ns, cn):
        cop = self.broker.new_object_path(ns, cn)
        e = self.broker.enumInstanceNames(self.ctx, cop)
        while e and e.hasNext():
            data=e.next()
            assert(data.type == cmpi.CMPI_ref)
            piname=self.proxy.cmpi2pywbem_instname(data.value.ref)
            yield piname

    def EnumerateInstances(self, ns, cn, props = None):
        cop = self.broker.new_object_path(ns, cn)
        e = self.broker.enumInstances(self.ctx, cop, props)
        while e and e.hasNext():
            data=e.next()
            assert(data.type == cmpi.CMPI_instance)
            pinst=self.proxy.cmpi2pywbem_inst(data.value.inst)
            yield pinst

    def GetInstance(self, path, props = None):
        cop = self.proxy.pywbem2cmpi_instname(path)
        ci = self.broker.getInstance(self.ctx, cop, props)
        if ci is None:
            return None
        return self.proxy.cmpi2pywbem_inst(ci)

    def Associators(self, path, assocClass = None, resultClass = None, 
        role = None, resultRole = None, props = None):
        cop = self.proxy.pywbem2cmpi_instname(path)
        e = self.broker.associators(self.ctx, cop, assocClass, resultClass,
            role, resultRole, props)
        while e and e.hasNext():
            data = e.next()
            assert(data.type == cmpi.CMPI_instance)
            pinst=self.proxy.cmpi2pywbem_inst(data.value.inst)
            yield pinst

    def AssociatorNames(self, path, assocClass = None, resultClass = None, 
        role = None, resultRole = None):
        cop = self.proxy.pywbem2cmpi_instname(path)
        e = self.broker.associatorNames(self.ctx, cop, assocClass, resultClass,
            role, resultRole)
        while e and e.hasNext():
            data = e.next()
            assert(data.type == cmpi.CMPI_ref)
            piname=self.proxy.cmpi2pywbem_instname(data.value.ref)
            yield piname

    def References(self, path, resultClass=None, role=None, props=None):
        cop = self.proxy.pywbem2cmpi_instname(path)
        e = self.broker.references(self.ctx, cop, resultClass,
            role, props)
        while e and e.hasNext():
            data = e.next()
            assert(data.type == cmpi.CMPI_instance)
            piname=self.proxy.cmpi2pywbem_inst(data.value.ref)
            yield piname
            
    def ReferenceNames(self, path, resultClass=None, role=None):
        cop = self.proxy.pywbem2cmpi_instname(path)
        e = self.broker.referenceNames(self.ctx, cop, resultClass, role)
        while e and e.hasNext():
            data = e.next()
            assert(data.type == cmpi.CMPI_ref)
            piname=self.proxy.cmpi2pywbem_instname(data.value.ref)
            yield piname

    def InvokeMethod(self, path, method, **params):
        if not isinstance(path, pywbem.CIMClassName) and \
                not isinstance(path, pywbem.CIMInstanceName):
            # invalid parameter
            raise pywbem.CIMError(pywbem.CIM_ERR_INVALID_PARAMETER)
        if path.namespace is None:
            # must have namespace
            raise pywbem.CIMError(pywbem.CIM_ERR_INVALID_NAMESPACE)
        cop = self.proxy.pywbem2cmpi_instname(path)
        inargs=self.proxy.pywbem2cmpi_args(params)
        poutargs = self.broker.new_args()
        rc=self.broker.invokeMethod(self.ctx, cop, method, inargs, poutargs)
        outrc = self.proxy.cmpi2pywbem_data(rc)
        outargs = self.proxy.cmpi2pywbem_args(poutargs)
        rslt = (outrc,outargs)
        return rslt
        
    def CreateInstance(self, instance):
        if instance.path is None or not instance.path:
            # no INVALID_PATH error... INVALID_NAMESPACE is best option
            raise pywbem.CIMError(pywbem.CIM_ERR_INVALID_NAMESPACE)
        if instance.path.namespace is None or not instance.path.namespace:
            raise pywbem.CIMError(pywbem.CIM_ERR_INVALID_NAMESPACE)
        cop = self.proxy.pywbem2cmpi_instname(instance.path)
        inst = self.proxy.pywbem2cmpi_inst(instance)
        ciname = self.broker.createInstance(self.ctx, cop, inst)
        if ciname is None:
            return None
        return self.proxy.cmpi2pywbem_instname(ciname)
    
    def DeleteInstance(self, path):
        cop = self.proxy.pywbem2cmpi_instname(path)
        return self.broker.deleteInstance(self.ctx, cop)

    def ModifyInstance(self, instance):
        if instance.path is None or not instance.path:
            # no INVALID_PATH error... INVALID_NAMESPACE is best option
            raise pywbem.CIMError(pywbem.CIM_ERR_INVALID_NAMESPACE)
        if instance.path.namespace is None or not instance.path.namespace:
            raise pywbem.CIMError(pywbem.CIM_ERR_INVALID_NAMESPACE)
        cop = self.proxy.pywbem2cmpi_instname(instance.path)
        inst = self.proxy.pywbem2cmpi_inst(instance)
        return self.broker.modifyInstance(self.ctx, cop, inst)
    
    def DeliverIndication(self, ns, instance):
        if self.broker.name() == 'Pegasus':
            allow_null_ns = False
        else:
            allow_null_ns = True
            if self.broker.name() == 'RequestHandler':
                # Check sblim bug #2185410.
                if instance.path is not None:
                    instance.path.namespace = None
        inst = self.proxy.pywbem2cmpi_inst(instance, allow_null_ns)
        rv = self.broker.deliverIndication(self.ctx, ns, inst)
        return rv
    
    def is_subclass(self, ns, super, sub):
        subObjPath=self.broker.new_object_path(ns, sub)
        return bool(self.broker.classPathIsA(subObjPath,super))

    def bummer(self):
        self.broker.bummer()

_log_pri_map = {
        cmpi.CMPI_SEV_ERROR    :syslog.LOG_ERR,
        cmpi.CMPI_SEV_INFO     :syslog.LOG_INFO,
        cmpi.CMPI_SEV_WARNING  :syslog.LOG_WARNING,
        cmpi.CMPI_DEV_DEBUG    :syslog.LOG_DEBUG,
        }

class Logger(object):
    def __init__(self, broker, miname):
        #self.broker = ExceptionClassWrapper(broker)
        self.broker = broker
        self.miname = miname
    def __log_message(self, severity, msg):
        try:
            self.broker.LogMessage(severity, self.miname, msg);
        except cmpi.CMPIException, e:
            if e.get_error_code() == cmpi.CMPI_RC_ERR_NOT_SUPPORTED: 
                syslog.syslog(syslog.LOG_DAEMON | _log_pri_map[severity], 
                        '%s: %s' % (self.miname, msg))
    def log_error(self, msg):
        self.__log_message(cmpi.CMPI_SEV_ERROR, msg);
    def log_info(self, msg):
        self.__log_message(cmpi.CMPI_SEV_INFO, msg);
    def log_warn(self, msg):
        self.__log_message(cmpi.CMPI_SEV_WARNING, msg);
    def log_debug(self, msg):
        self.__log_message(cmpi.CMPI_DEV_DEBUG, msg);

class ProviderEnvironment(object):
    def __init__(self, proxy, ctx):
        self.proxy = proxy
        self.ctx = ContextWrap(proxy, ctx)
    def get_logger(self):
        return Logger(self.proxy.broker, self.proxy.miname)
    def get_cimom_handle(self):
        return BrokerCIMOMHandle(self.proxy, self.ctx.cmpicontext)

g_proxies = {}

def get_cmpi_proxy_provider(miname, broker):
    try:
        prox = g_proxies[miname]
        if str(prox.proxy.env.proxy.broker) != str(broker):
                raise pywbem.CIMError(pywbem.CIM_ERR_FAILED, 
                        'New broker not the same as cached broker!')
    except KeyError:
        prox = ExceptionClassWrapper(CMPIProxyProvider(miname, broker))
        g_proxies[miname] = prox
    return prox


class CMPIProxyProvider(object):

    def __init__(self, miname, broker):
        print 'called CMPIProxyProvider(', miname, ',', broker, ')'
        self.miname = miname
        self.broker = broker
        env = ProviderEnvironment(self, None)
        provmod = miname
        if provmod[0] != '/':
            provmod = '/usr/lib/pycim/' + provmod
        if not provmod.endswith('.py'):
            provmod+= '.py'
        self.proxy = ProviderProxy(env, provmod)
        #print '*** broker.name()', broker.name()
        #print '*** broker.capabilities()', broker.capabilities()
        #print '*** broker.version()', broker.version()

    def enum_instance_names(self, ctx, rslt, objname):
        print 'provider.py: In enum_instance_names()' 
        #test_conversions()
        env = ProviderEnvironment(self, ctx)
        op = self.cmpi2pywbem_instname(objname)
        try:
            for i in self.proxy.MI_enumInstanceNames(env, op):
                cop = self.pywbem2cmpi_instname(i)
                rslt.return_objectpath(cop)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')

    def enum_instances(self, ctx, rslt, objname, plist):
        print 'provider.py: In enum_instances()' 
        env = ProviderEnvironment(self, ctx)
        op = self.cmpi2pywbem_instname(objname)
        try:
            for i in self.proxy.MI_enumInstances(env, op, plist):
                cinst = self.pywbem2cmpi_inst(i)
                rslt.return_instance(cinst)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')

    def get_instance(self, ctx, rslt, objname, plist):
        print 'provider.py: In get_instance()' 
        env = ProviderEnvironment(self, ctx)
        op = self.cmpi2pywbem_instname(objname)
        try:
            pinst = self.proxy.MI_getInstance(env, op, plist)
        except pywbem.CIMError, args:
            return args[:2]
        cinst = self.pywbem2cmpi_inst(pinst)
        rslt.return_instance(cinst)
        rslt.done()
        return (0, '')


    def create_instance(self, ctx, rslt, objname, newinst):
        env = ProviderEnvironment(self, ctx)
        pinst = self.cmpi2pywbem_inst(newinst)
        try:
            piname = self.proxy.MI_createInstance(env, pinst)
        except pywbem.CIMError, args:
            return args[:2]
        ciname = self.pywbem2cmpi_instname(piname)
        rslt.return_objectpath(ciname)
        rslt.done()
        return (0, '')


    def set_instance(self, ctx, rslt, objname, newinst, plist):
        env = ProviderEnvironment(self, ctx)
        pinst = self.cmpi2pywbem_inst(newinst)
        pinst.path = self.cmpi2pywbem_instname(objname)
        try:
            self.proxy.MI_modifyInstance(env, pinst, plist)
        except pywbem.CIMError, args:
            return args[:2]
        return (0, '')

    def delete_instance(self, ctx, rslt, objname):
        env = ProviderEnvironment(self, ctx)
        piname = self.cmpi2pywbem_instname(objname)
        try:
            self.proxy.MI_deleteInstance(env, piname)
        except pywbem.CIMError, args:
            return args[:2]
        return (0, '')


    def exec_query(self, ctx, rslt, objname, query, lang):
        return (pywbem.CIM_ERR_NOT_SUPPORTED, '')


    def associator_names(self, ctx, rslt, objName, assocClass, resultClass,
            role, resultRole):
        env = ProviderEnvironment(self, ctx)
        piname = self.cmpi2pywbem_instname(objName)

        try:
            for i in self.proxy.MI_associatorNames(env, piname, 
                    assocClass, resultClass, role, resultRole):
                ciname = self.pywbem2cmpi_instname(i)
                rslt.return_objectpath(ciname)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')

    def associators(self, ctx, rslt, objName, assocClass, resultClass,
            role, resultRole, props):
        env = ProviderEnvironment(self, ctx)
        piname = self.cmpi2pywbem_instname(objName)

        try:
            for i in self.proxy.MI_associators(env, piname, 
                    assocClass, resultClass, role, resultRole, props):
                cinst = self.pywbem2cmpi_inst(i)
                rslt.return_instance(cinst)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')


    def reference_names(self, ctx, rslt, objName, resultClass, role):
        print 'pycmpi_provider.py: In reference_names()' 
        env = ProviderEnvironment(self, ctx)
        piname = self.cmpi2pywbem_instname(objName)

        try:
            for i in self.proxy.MI_referenceNames(env, piname, 
                    resultClass, role):
                ciname = self.pywbem2cmpi_instname(i)
                rslt.return_objectpath(ciname)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')


    def references(self, ctx, rslt, objName, resultClass, role, props):
        env = ProviderEnvironment(self, ctx)
        piname = self.cmpi2pywbem_instname(objName)

        try:
            for i in self.proxy.MI_references(env, piname, 
                    resultClass, role, props):
                cinst = self.pywbem2cmpi_inst(i)
                rslt.return_instance(cinst)
        except pywbem.CIMError, args:
            return args[:2]
        rslt.done()
        return (0, '')


    def invoke_method(self, ctx, rslt, objName, method, inargs, outargs):
        print '*** in invoke_method'
        env = ProviderEnvironment(self, ctx)
        op = self.cmpi2pywbem_instname(objName)
        pinargs = self.cmpi2pywbem_args(inargs)
        try:
            ((_type, rv), poutargs) = self.proxy.MI_invokeMethod(env, 
                    op, method, pinargs)
        except pywbem.CIMError, args:
            return args[:2]

        self.pywbem2cmpi_args(poutargs, outargs)


        data, _type = self.pywbem2cmpi_value(rv, _type=_type)
        rslt.return_data(data, _pywbem2cmpi_typemap[_type])
        rslt.done()
        return (0, '')


    def authorize_filter(self, ctx, filter, className, classPath, owner):
        env = ProviderEnvironment(self, ctx)
        filt = self.cmpi2pywbem_selectexp(filter)
        classpath = self.cmpi2pywbem_instname(classPath)
        try:
            self.proxy.MI_authorizeFilter(env, 
                    filt, className, classpath, owner)
        except pywbem.CIMError, args:
            #expect an exception if not success
            return args[:2]

        return (0, '')

    def activate_filter(self, ctx, filter, className, classPath, 
            firstActivation):
        env = ProviderEnvironment(self, ctx)
        filt = self.cmpi2pywbem_selectexp(filter)
        classpath = self.cmpi2pywbem_instname(classPath)
        try:
            self.proxy.MI_activateFilter(env, 
                    filt, className, classpath, firstActivation)
        except pywbem.CIMError, args:
            #expect an exception if not success
            return args[:2]

        return (0, '')

    def deactivate_filter(self, ctx, filter, className, classPath, 
            lastActivation):
        env = ProviderEnvironment(self, ctx)
        filt = self.cmpi2pywbem_selectexp(filter)
        classpath = self.cmpi2pywbem_instname(classPath)
        try:
            self.proxy.MI_deActivateFilter(env, 
                    filt, className, classpath, lastActivation)
        except pywbem.CIMError, args:
            #expect an exception if not success
            return args[:2]

        return (0, '')

    #def must_poll(self, ctx, rslt, filter, className, classPath):
    # NOTE: sfcb signature for this doesn't have the rslt. 
    def must_poll(self, ctx, filter, className, classPath):
        # must_poll is not supported by most cimoms, partly because
        # the spec is ambiguous, so commented out for a no-op
        # and just return 1 for FALSE
        '''
        env = ProviderEnvironment(self, ctx)
        filt = self.cmpi2pywbem_selectexp(filter)
        classpath = self.cmpi2pywbem_instname(classPath)
        try:
            rv = self.proxy.MI_mustPoll(env, 
                    filt, className, classpath)
        except pywbem.CIMError, args:
            return args[:2]
        '''
        return (1, '')


    def enable_indications(self, ctx):
        env = ProviderEnvironment(self, ctx)
        try:
            self.proxy.MI_enableIndications(env)
        except pywbem.CIMError, args:
            #expect an exception if not success
            return args[:2]

        return (0, '')

    def disable_indications(self, ctx):
        env = ProviderEnvironment(self, ctx)
        try:
            self.proxy.MI_disableIndications(env)
        except pywbem.CIMError, args:
            #expect an exception if not success
            return args[:2]

        return (0, '')

    # conversion routines
    #######################################################################

    def cmpi2pywbem_inst(self, cmpiinst):
        cop = self.cmpi2pywbem_instname(cmpiinst.objectpath())
        props = {}
        for i in xrange(0, cmpiinst.property_count()):
            data, name = cmpiinst.get_property_at(i)
            _type, is_array = _cmpi_type2string(data.type)
            pval = self.cmpi2pywbem_data(data, _type, is_array)
            prop = pywbem.CIMProperty(name, pval, _type, is_array=is_array)
            props[name] = prop
        inst = pywbem.CIMInstance(cop.classname, props, path=cop)
        return inst

    def cmpi2pywbem_args(self, cargs):
        r = {}
        for i in xrange(0, cargs.arg_count()):
            data, name = cargs.get_arg_at(i)
            _type, is_array = _cmpi_type2string(data.type)
            pval = self.cmpi2pywbem_data(data, _type, is_array)
            r[name] = pval
        return r

    def pywbem2cmpi_args(self, pargs, cargs=None):
        if cargs is None:
            cargs = self.broker.new_args()
        for name, (_type, pval) in pargs.items():
            data, _type = self.pywbem2cmpi_value(pval, _type)
            ctype = _pywbem2cmpi_typemap[_type]
            if isinstance(pval, list):
                ctype = ctype | cmpi.CMPI_ARRAY
            cargs.set(str(name), data, ctype)
        return cargs


    def pywbem2cmpi_inst(self, pinst, allow_null_ns=False):
        pcop = pinst.path
        if not allow_null_ns:
            if pcop is None or pcop.namespace is None:
                raise pywbem.CIMError(pywbem.CIM_ERR_INVALID_NAMESPACE, 
                        "Instance must have a namespace")
        else:
            if pcop is None:
                pcop = pywbem.CIMInstanceName(pinst.classname)
        cop = self.pywbem2cmpi_instname(pcop)
        cinst = self.broker.new_instance(cop, allow_null_ns)
        if pinst.property_list is not None:
            cinst.set_property_filter(pinst.property_list)
        for prop in pinst.properties.values():
        #    if pinst.property_list and \
        #            prop.name.lower() not in pinst.property_list:
        #        continue
            data, _type = self.pywbem2cmpi_value(prop.value, _type=prop.type)
            ctype = _pywbem2cmpi_typemap[_type]
            if isinstance(prop.value, list):
                ctype = ctype | cmpi.CMPI_ARRAY
            cinst.set_property(str(prop.name), data, ctype)
        return cinst



    def cmpi2pywbem_instname(self, cmpiobjpath):
        keys = {}
        for i in xrange(0, cmpiobjpath.key_count()):
            data,keyname = cmpiobjpath.get_key_at(i)
            pval = self.cmpi2pywbem_data(data)
            keys[keyname] = pval

        rv = pywbem.CIMInstanceName(cmpiobjpath.classname(), 
                keys, namespace=cmpiobjpath.namespace())
        return rv

    def pywbem2cmpi_instname(self, iname):
        cop = self.broker.new_object_path(iname.namespace, str(iname.classname))
        if isinstance(iname, pywbem.CIMInstanceName):
            for name, val in iname.keybindings.items():
                if val is None:
                    raise ValueError('NULL value for key "%s.%s"' % \
                            (iname.classname, name))
                data, _type = self.pywbem2cmpi_value(val)
                cop.add_key(str(name), data, _pywbem2cmpi_typemap[_type])
        return cop
        
    def pywbem2cmpi_value(self, pdata, _type=None, cval=None):
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
            car = self.broker.new_array(ralen, ctype)
            for i, rael in enumerate(pdata):
                cv, tt = self.pywbem2cmpi_value(rael, _type=_type)
                car.set(i, cv, ctype)
            cval.array = car
            return cval, _type
        if _type == 'reference':
            attr = 'ref'
            pdata = self.pywbem2cmpi_instname(pdata)
        elif _type == 'string':
            pdata = self.broker.new_string(str(pdata))
        elif _type == 'datetime':
            attr = 'dateTime'
            pdata = self.pywbem2cmpi_datetime(pdata)
        elif _type == 'instance':
            attr = 'inst'
            pdata = self.pywbem2cmpi_inst(pdata)
        elif _type == 'chars':
            pdata = self.broker.new_string(str(pdata))
        setattr(cval, attr, pdata)
        return cval, _type

    def cmpi2pywbem_value(self, cval, _type, is_array=False):
        ctype = _type
        if _type == 'reference':
            ctype = 'ref' 
        if is_array:
            pval = []
            car = cval.array
            for i in xrange(0, car.size()):
                data = car.at(i)
                ptype = _cmpi2pywbem_typemap[data.type]
                rael = self.cmpi2pywbem_value(data.value, _type)
                pval.append(rael)
        else:
            cval = getattr(cval, ctype)
            if _type == 'string':
                pval = cval.to_s()
            elif _type == 'chars':
                pval = cval.to_s()
            elif ctype == 'ref':
                pval = self.cmpi2pywbem_instname(cval)
            else:
                pval = pywbem.tocimobj(_type, cval)
        return pval



    def pywbem2cmpi_data(self, pdata, _type=None):
        is_array = isinstance(pdata, list)
        if _type is None:
            _type = pywbem.cimtype(pdata)
        # This doesn't work below.  cmpi.CMPIData() takes a CMPIData argument. ??
        data = cmpi.CMPIData()
        data.state = 0
        data.type = _pywbem2cmpi_typemap[_type]
        if is_array:
            data.type = data.type | cmpi.CMPI_ARRAY
        if _type == 'reference':
            _type = 'ref'
            pdata = self.pywbem2cmpi_instname(pdata)
        self.pywbem2cmpi_value(pdata, _type, data.value)
        return data



    def cmpi2pywbem_data(self, cdata, _type=None, is_array=None):
        #TODO check for valid cdata.state
        #TODO error handling
        if _type is None:
            _type, is_array = _cmpi_type2string(cdata.type)
        attr = _type
        if is_array:
            rv = []
            car = cdata.value.array
            if car is None:
                return None
            for i in xrange(0, car.size()):
                adata = car.at(i)
                pdata = self.cmpi2pywbem_data(adata, _type, is_array=False)
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
            val = self.cmpi2pywbem_datetime(val)
        if _type == 'reference':
            val = self.cmpi2pywbem_instname(val)
        if _type == 'instance':
            val = self.cmpi2pywbem_inst(val)
            return val
        if _type == 'chars':
            _type = 'string'
        return pywbem.tocimobj(_type, val)

    def cmpi2pywbem_datetime(self, dt):
        return pywbem.CIMDateTime(dt.to_s())

    def pywbem2cmpi_datetime(self, dt):
        return self.broker.new_datetime_from_string(str(dt))

    def cmpi2pywbem_selectexp(self, filter):
        return filter.to_s()


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
        'chars'         : cmpi.CMPI_chars,
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
        cmpi.CMPI_chars       : 'chars', 

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

def _cmpi_type2string(itype):
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


def test_conversions(proxy):
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
    cdt = proxy.broker.new_datetime_from_string('20080623144759.823564-360')
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

