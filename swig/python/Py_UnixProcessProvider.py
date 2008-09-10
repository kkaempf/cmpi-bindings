"""Python Provider for Py_UnixProcess

Instruments the CIM class Py_UnixProcess

"""

import pywbem
from cim_provider import CIMProvider

import os
from socket import getfqdn

class Py_UnixProcessProvider(CIMProvider):
    """Instrument the CIM class Py_UnixProcess 

    Model a Linux Process, For use with PyWBEM Provider QuickStart Guide
    
    """

    def __init__ (self, env):
        logger = env.get_logger()
        logger.log_debug('Initializing provider %s from %s' \
                % (self.__class__.__name__, __file__))
        # If you will be filtering instances yourself according to 
        # property_list, role, result_role, and result_class_name 
        # parameters, set self.filter_results to False
        # self.filter_results = False

    def get_instance(self, env, model, property_list):
        """Return an instance.

        Keyword arguments:
        env -- Provider Environment (pycimmb.ProviderEnvironment)
        model -- A template of the pywbem.CIMInstance to be returned.  The 
            key properties are set on this instance to correspond to the 
            instanceName that was requested.  The properties of the model
            are already filtered according to the PropertyList from the 
            request.  Only properties present in the model need to be
            given values.  If you prefer, you can set all of the 
            values, and the instance will be filtered for you. 
        property_list -- The PropertyList from the request. 

        Possible Errors:
        CIM_ERR_ACCESS_DENIED
        CIM_ERR_INVALID_PARAMETER (including missing, duplicate, unrecognized 
            or otherwise incorrect parameters)
        CIM_ERR_NOT_FOUND (the CIM Class does exist, but the requested CIM 
            Instance does not exist in the specified namespace)
        CIM_ERR_FAILED (some other unspecified error occurred)

        """
        
        logger = env.get_logger()
        logger.log_debug('Entering %s.get_instance()' \
                % self.__class__.__name__)
        

        # TODO fetch system resource matching the following keys:
        #   model['CreationClassName']
        #   model['OSCreationClassName']
        #   model['Handle']
        #   model['CSCreationClassName']
        #   model['OSName']
        #   model['CSName']
        #

        pid = model['handle']
        if not os.path.exists('/proc/' + pid):
            raise pywbem.CIMError(pywbem.CIM_ERR_NOT_FOUND)

        fo = open('/proc/'+pid+'/stat', 'r')
        st = fo.read()
        fo.close()
        head, sep, tail = st.partition('(')
        name, sep, tail = tail.partition(')')
        model['Name'] = name

        #model['AvailableRequestedStates'] = [self.Values.AvailableRequestedStates.<VAL>,] # TODO 
        #model['Caption'] = '' # TODO 
        #model['CommunicationStatus'] = self.Values.CommunicationStatus.<VAL> # TODO 
        #model['CreationDate'] = pywbem.CIMDateTime() # TODO 
        #model['Description'] = '' # TODO 
        #model['DetailedStatus'] = self.Values.DetailedStatus.<VAL> # TODO 
        #model['ElementName'] = '' # TODO 
        #model['EnabledDefault'] = self.Values.EnabledDefault.Enabled # TODO 
        #model['EnabledState'] = self.Values.EnabledState.Not_Applicable # TODO 
        #model['ExecutionState'] = self.Values.ExecutionState.<VAL> # TODO 
        #model['Generation'] = pywbem.Uint64() # TODO 
        #model['HealthState'] = self.Values.HealthState.<VAL> # TODO 
        #model['InstallDate'] = pywbem.CIMDateTime() # TODO 
        #model['InstanceID'] = '' # TODO 
        #model['KernelModeTime'] = pywbem.Uint64() # TODO 
        #model['ModulePath'] = '' # TODO 
        #model['OperatingStatus'] = self.Values.OperatingStatus.<VAL> # TODO 
        #model['OperationalStatus'] = [self.Values.OperationalStatus.<VAL>,] # TODO 
        #model['OtherEnabledState'] = '' # TODO 
        #model['OtherExecutionDescription'] = '' # TODO 
        #model['Parameters'] = ['',] # TODO 
        #model['ParentProcessID'] = '' # TODO (Required)
        #model['PrimaryStatus'] = self.Values.PrimaryStatus.<VAL> # TODO 
        #model['Priority'] = pywbem.Uint32(0) # TODO 
        #model['ProcessGroupID'] = pywbem.Uint64() # TODO (Required)
        #model['ProcessNiceValue'] = pywbem.Uint32() # TODO 
        #model['ProcessSessionID'] = pywbem.Uint64() # TODO 
        #model['ProcessTTY'] = '' # TODO 
        #model['ProcessWaitingForEvent'] = '' # TODO 
        #model['RealUserID'] = pywbem.Uint64() # TODO (Required)
        #model['RequestedState'] = self.Values.RequestedState.Not_Applicable # TODO 
        #model['Status'] = self.Values.Status.<VAL> # TODO 
        #model['StatusDescriptions'] = ['',] # TODO 
        #model['TerminationDate'] = pywbem.CIMDateTime() # TODO 
        #model['TimeOfLastStateChange'] = pywbem.CIMDateTime() # TODO 
        #model['TransitioningToState'] = self.Values.TransitioningToState.Not_Applicable # TODO 
        #model['UnixPriority'] = pywbem.Sint32() # TODO 
        #model['UserModeTime'] = pywbem.Uint64() # TODO 
        #model['WorkingSetSize'] = pywbem.Uint64() # TODO 
        return model

    def enum_instances(self, env, model, property_list, keys_only):
        """Enumerate instances.

        The WBEM operations EnumerateInstances and EnumerateInstanceNames
        are both mapped to this method. 
        This method is a python generator

        Keyword arguments:
        env -- Provider Environment (pycimmb.ProviderEnvironment)
        model -- A template of the pywbem.CIMInstances to be generated.  
            The properties of the model are already filtered according to 
            the PropertyList from the request.  Only properties present in 
            the model need to be given values.  If you prefer, you can 
            always set all of the values, and the instance will be filtered 
            for you. 
        property_list -- The PropertyList from the request. 
        keys_only -- A boolean.  True if only the key properties should be
            set on the generated instances.

        Possible Errors:
        CIM_ERR_FAILED (some other unspecified error occurred)

        """

        logger = env.get_logger()
        logger.log_debug('Entering %s.enum_instances()' \
                % self.__class__.__name__)
                
        # Prime model.path with knowledge of the keys, so key values on
        # the CIMInstanceName (model.path) will automatically be set when
        # we set property values on the model. 
        model.path.update({u'Handle': None, u'CSName': None, u'OSName': None, u'CSCreationClassName': None, u'OSCreationClassName': None, u'CreationClassName': None})
        
        model['CreationClassName'] = 'Py_UnixProcess'    
        model['OSCreationClassName'] = 'CIM_OperatingSystem'
        model['CSCreationClassName'] = 'CIM_ComputerSystem'
        model['OSName'] = 'Linux'
        model['CSName'] = getfqdn()
        for file in os.listdir('/proc'):
            if not file.isdigit():
                continue
            model['Handle'] = file
            if keys_only:
                yield model
            else:
                try:
                    yield self.get_instance(env, model, property_list)
                except pywbem.CIMError, (num, msg):
                    if num not in (pywbem.CIM_ERR_NOT_FOUND, 
                                   pywbem.CIM_ERR_ACCESS_DENIED):
                        raise

    def set_instance(self, env, instance, modify_existing, property_list):
        """Return a newly created or modified instance.

        Keyword arguments:
        env -- Provider Environment (pycimmb.ProviderEnvironment)
        instance -- The new pywbem.CIMInstance.  If modifying an existing 
            instance, the properties on this instance have been filtered by 
            the PropertyList from the request.
        modify_existing -- True if ModifyInstance, False if CreateInstance
        property_list -- The PropertyList from the request. 

        Return the new instance.  The keys must be set on the new instance. 

        Possible Errors:
        CIM_ERR_ACCESS_DENIED
        CIM_ERR_NOT_SUPPORTED
        CIM_ERR_INVALID_PARAMETER (including missing, duplicate, unrecognized 
            or otherwise incorrect parameters)
        CIM_ERR_ALREADY_EXISTS (the CIM Instance already exists -- only 
            valid if modify_existing is False, indicating that the operation
            was CreateInstance)
        CIM_ERR_NOT_FOUND (the CIM Instance does not exist -- only valid 
            if modify_existing is True, indicating that the operation
            was ModifyInstance)
        CIM_ERR_FAILED (some other unspecified error occurred)

        """

        logger = env.get_logger()
        logger.log_debug('Entering %s.set_instance()' \
                % self.__class__.__name__)
        # TODO create or modify the instance
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED) # Remove to implement
        return instance

    def delete_instance(self, env, instance_name):
        """Delete an instance.

        Keyword arguments:
        env -- Provider Environment (pycimmb.ProviderEnvironment)
        instance_name -- A pywbem.CIMInstanceName specifying the instance 
            to delete.

        Possible Errors:
        CIM_ERR_ACCESS_DENIED
        CIM_ERR_NOT_SUPPORTED
        CIM_ERR_INVALID_NAMESPACE
        CIM_ERR_INVALID_PARAMETER (including missing, duplicate, unrecognized 
            or otherwise incorrect parameters)
        CIM_ERR_INVALID_CLASS (the CIM Class does not exist in the specified 
            namespace)
        CIM_ERR_NOT_FOUND (the CIM Class does exist, but the requested CIM 
            Instance does not exist in the specified namespace)
        CIM_ERR_FAILED (some other unspecified error occurred)

        """ 

        logger = env.get_logger()
        logger.log_debug('Entering %s.delete_instance()' \
                % self.__class__.__name__)

        # TODO delete the resource
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED) # Remove to implement
        
    def cim_method_requeststatechange(self, env, object_name,
                                      param_requestedstate,
                                      param_timeoutperiod):
        """Implements Py_UnixProcess.RequestStateChange()

        Requests that the state of the element be changed to the value
        specified in the RequestedState parameter. When the requested
        state change takes place, the EnabledState and RequestedState of
        the element will be the same. Invoking the RequestStateChange
        method multiple times could result in earlier requests being
        overwritten or lost. \nA return code of 0 shall indicate the state
        change was successfully initiated. \nA return code of 3 shall
        indicate that the state transition cannot complete within the
        interval specified by the TimeoutPeriod parameter. \nA return code
        of 4096 (0x1000) shall indicate the state change was successfully
        initiated, a ConcreteJob has been created, and its reference
        returned in the output parameter Job. Any other return code
        indicates an error condition.
        
        Keyword arguments:
        env -- Provider Environment (pycimmb.ProviderEnvironment)
        object_name -- A pywbem.CIMInstanceName or pywbem.CIMCLassName 
            specifying the object on which the method RequestStateChange() 
            should be invoked.
        param_requestedstate --  The input parameter RequestedState (type pywbem.Uint16 self.Values.RequestStateChange.RequestedState) 
            The state requested for the element. This information will be
            placed into the RequestedState property of the instance if the
            return code of the RequestStateChange method is 0 (\'Completed
            with No Error\'), or 4096 (0x1000) (\'Job Started\'). Refer to
            the description of the EnabledState and RequestedState
            properties for the detailed explanations of the RequestedState
            values.
            
        param_timeoutperiod --  The input parameter TimeoutPeriod (type pywbem.CIMDateTime) 
            A timeout period that specifies the maximum amount of time that
            the client expects the transition to the new state to take.
            The interval format must be used to specify the TimeoutPeriod.
            A value of 0 or a null parameter indicates that the client has
            no time requirements for the transition. \nIf this property
            does not contain 0 or null and the implementation does not
            support this parameter, a return code of \'Use Of Timeout
            Parameter Not Supported\' shall be returned.
            

        Returns a two-tuple containing the return value (type pywbem.Uint32 self.Values.RequestStateChange)
        and a list of CIMParameter objects representing the output parameters

        Output parameters:
        Job -- (type REF (pywbem.CIMInstanceName(classname='CIM_ConcreteJob', ...)) 
            May contain a reference to the ConcreteJob created to track the
            state transition initiated by the method invocation.
            

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

        logger = env.get_logger()
        logger.log_debug('Entering %s.cim_method_requeststatechange()' \
                % self.__class__.__name__)

        # TODO do something
        raise pywbem.CIMError(pywbem.CIM_ERR_METHOD_NOT_AVAILABLE) # Remove to implemented
        out_params = []
        #out_params+= [pywbem.CIMParameter('job', type='reference', 
        #                   value=pywbem.CIMInstanceName(classname='CIM_ConcreteJob', ...))] # TODO
        #rval = # TODO (type pywbem.Uint32 self.Values.RequestStateChange)
        return (rval, out_params)
        
    def cim_method_kill(self, env, object_name,
                        param_signal):
        """Implements Py_UnixProcess.kill()

        Send a signal to a process.
        
        Keyword arguments:
        env -- Provider Environment (pycimmb.ProviderEnvironment)
        object_name -- A pywbem.CIMInstanceName or pywbem.CIMCLassName 
            specifying the object on which the method kill() 
            should be invoked.
        param_signal --  The input parameter signal (type pywbem.Uint16 self.Values.kill.signal) 
            The signal to send the process
            

        Returns a two-tuple containing the return value (type pywbem.Sint32)
        and a list of CIMParameter objects representing the output parameters

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

        logger = env.get_logger()
        logger.log_debug('Entering %s.cim_method_kill()' \
                % self.__class__.__name__)

        pid = object_name['handle']
        if not os.path.isdir('/proc/' + pid):
            raise pywbem.CIMError(pywbem.CIM_ERR_NOT_FOUND,
                         'Process %s does not exist' % pid)
        rval = pywbem.Sint32(0)
        try:
            os.kill(int(pid), param_signal)
        except OSError, arg:
            rval = pwbem.Sint32(arg.errno)
        out_params = []
        return (rval, out_params)

        
    class Values(object):
        class DetailedStatus(object):
            Not_Available = pywbem.Uint16(0)
            No_Additional_Information = pywbem.Uint16(1)
            Stressed = pywbem.Uint16(2)
            Predictive_Failure = pywbem.Uint16(3)
            Non_Recoverable_Error = pywbem.Uint16(4)
            Supporting_Entity_in_Error = pywbem.Uint16(5)
            # DMTF_Reserved = ..
            # Vendor_Reserved = 0x8000..

        class RequestedState(object):
            Unknown = pywbem.Uint16(0)
            Enabled = pywbem.Uint16(2)
            Disabled = pywbem.Uint16(3)
            Shut_Down = pywbem.Uint16(4)
            No_Change = pywbem.Uint16(5)
            Offline = pywbem.Uint16(6)
            Test = pywbem.Uint16(7)
            Deferred = pywbem.Uint16(8)
            Quiesce = pywbem.Uint16(9)
            Reboot = pywbem.Uint16(10)
            Reset = pywbem.Uint16(11)
            Not_Applicable = pywbem.Uint16(12)
            # DMTF_Reserved = ..
            # Vendor_Reserved = 32768..65535

        class HealthState(object):
            Unknown = pywbem.Uint16(0)
            OK = pywbem.Uint16(5)
            Degraded_Warning = pywbem.Uint16(10)
            Minor_failure = pywbem.Uint16(15)
            Major_failure = pywbem.Uint16(20)
            Critical_failure = pywbem.Uint16(25)
            Non_recoverable_error = pywbem.Uint16(30)
            # DMTF_Reserved = ..

        class TransitioningToState(object):
            Unknown = pywbem.Uint16(0)
            Enabled = pywbem.Uint16(2)
            Disabled = pywbem.Uint16(3)
            Shut_Down = pywbem.Uint16(4)
            No_Change = pywbem.Uint16(5)
            Offline = pywbem.Uint16(6)
            Test = pywbem.Uint16(7)
            Defer = pywbem.Uint16(8)
            Quiesce = pywbem.Uint16(9)
            Reboot = pywbem.Uint16(10)
            Reset = pywbem.Uint16(11)
            Not_Applicable = pywbem.Uint16(12)

        class EnabledDefault(object):
            Enabled = pywbem.Uint16(2)
            Disabled = pywbem.Uint16(3)
            Not_Applicable = pywbem.Uint16(5)
            Enabled_but_Offline = pywbem.Uint16(6)
            No_Default = pywbem.Uint16(7)
            Quiesce = pywbem.Uint16(9)
            # DMTF_Reserved = ..
            # Vendor_Reserved = 32768..65535

        class EnabledState(object):
            Unknown = pywbem.Uint16(0)
            Other = pywbem.Uint16(1)
            Enabled = pywbem.Uint16(2)
            Disabled = pywbem.Uint16(3)
            Shutting_Down = pywbem.Uint16(4)
            Not_Applicable = pywbem.Uint16(5)
            Enabled_but_Offline = pywbem.Uint16(6)
            In_Test = pywbem.Uint16(7)
            Deferred = pywbem.Uint16(8)
            Quiesce = pywbem.Uint16(9)
            Starting = pywbem.Uint16(10)
            # DMTF_Reserved = 11..32767
            # Vendor_Reserved = 32768..65535

        class ExecutionState(object):
            Unknown = pywbem.Uint16(0)
            Other = pywbem.Uint16(1)
            Ready = pywbem.Uint16(2)
            Running = pywbem.Uint16(3)
            Blocked = pywbem.Uint16(4)
            Suspended_Blocked = pywbem.Uint16(5)
            Suspended_Ready = pywbem.Uint16(6)
            Terminated = pywbem.Uint16(7)
            Stopped = pywbem.Uint16(8)
            Growing = pywbem.Uint16(9)
            Ready_But_Relinquished_Processor = pywbem.Uint16(10)
            Hung = pywbem.Uint16(11)

        class AvailableRequestedStates(object):
            Enabled = pywbem.Uint16(2)
            Disabled = pywbem.Uint16(3)
            Shut_Down = pywbem.Uint16(4)
            Offline = pywbem.Uint16(6)
            Test = pywbem.Uint16(7)
            Defer = pywbem.Uint16(8)
            Quiesce = pywbem.Uint16(9)
            Reboot = pywbem.Uint16(10)
            Reset = pywbem.Uint16(11)

        class Status(object):
            OK = 'OK'
            Error = 'Error'
            Degraded = 'Degraded'
            Unknown = 'Unknown'
            Pred_Fail = 'Pred Fail'
            Starting = 'Starting'
            Stopping = 'Stopping'
            Service = 'Service'
            Stressed = 'Stressed'
            NonRecover = 'NonRecover'
            No_Contact = 'No Contact'
            Lost_Comm = 'Lost Comm'
            Stopped = 'Stopped'

        class CommunicationStatus(object):
            Unknown = pywbem.Uint16(0)
            Not_Available = pywbem.Uint16(1)
            Communication_OK = pywbem.Uint16(2)
            Lost_Communication = pywbem.Uint16(3)
            No_Contact = pywbem.Uint16(4)
            # DMTF_Reserved = ..
            # Vendor_Reserved = 0x8000..

        class OperationalStatus(object):
            Unknown = pywbem.Uint16(0)
            Other = pywbem.Uint16(1)
            OK = pywbem.Uint16(2)
            Degraded = pywbem.Uint16(3)
            Stressed = pywbem.Uint16(4)
            Predictive_Failure = pywbem.Uint16(5)
            Error = pywbem.Uint16(6)
            Non_Recoverable_Error = pywbem.Uint16(7)
            Starting = pywbem.Uint16(8)
            Stopping = pywbem.Uint16(9)
            Stopped = pywbem.Uint16(10)
            In_Service = pywbem.Uint16(11)
            No_Contact = pywbem.Uint16(12)
            Lost_Communication = pywbem.Uint16(13)
            Aborted = pywbem.Uint16(14)
            Dormant = pywbem.Uint16(15)
            Supporting_Entity_in_Error = pywbem.Uint16(16)
            Completed = pywbem.Uint16(17)
            Power_Mode = pywbem.Uint16(18)
            # DMTF_Reserved = ..
            # Vendor_Reserved = 0x8000..

        class OperatingStatus(object):
            Unknown = pywbem.Uint16(0)
            Not_Available = pywbem.Uint16(1)
            Servicing = pywbem.Uint16(2)
            Starting = pywbem.Uint16(3)
            Stopping = pywbem.Uint16(4)
            Stopped = pywbem.Uint16(5)
            Aborted = pywbem.Uint16(6)
            Dormant = pywbem.Uint16(7)
            Completed = pywbem.Uint16(8)
            Migrating = pywbem.Uint16(9)
            Emigrating = pywbem.Uint16(10)
            Immigrating = pywbem.Uint16(11)
            Snapshotting = pywbem.Uint16(12)
            Shutting_Down = pywbem.Uint16(13)
            In_Test = pywbem.Uint16(14)
            Transitioning = pywbem.Uint16(15)
            In_Service = pywbem.Uint16(16)
            # DMTF_Reserved = ..
            # Vendor_Reserved = 0x8000..

        class RequestStateChange(object):
            Completed_with_No_Error = pywbem.Uint32(0)
            Not_Supported = pywbem.Uint32(1)
            Unknown_or_Unspecified_Error = pywbem.Uint32(2)
            Cannot_complete_within_Timeout_Period = pywbem.Uint32(3)
            Failed = pywbem.Uint32(4)
            Invalid_Parameter = pywbem.Uint32(5)
            In_Use = pywbem.Uint32(6)
            # DMTF_Reserved = ..
            Method_Parameters_Checked___Job_Started = pywbem.Uint32(4096)
            Invalid_State_Transition = pywbem.Uint32(4097)
            Use_of_Timeout_Parameter_Not_Supported = pywbem.Uint32(4098)
            Busy = pywbem.Uint32(4099)
            # Method_Reserved = 4100..32767
            # Vendor_Specific = 32768..65535
            class RequestedState(object):
                Enabled = pywbem.Uint16(2)
                Disabled = pywbem.Uint16(3)
                Shut_Down = pywbem.Uint16(4)
                Offline = pywbem.Uint16(6)
                Test = pywbem.Uint16(7)
                Defer = pywbem.Uint16(8)
                Quiesce = pywbem.Uint16(9)
                Reboot = pywbem.Uint16(10)
                Reset = pywbem.Uint16(11)
                # DMTF_Reserved = ..
                # Vendor_Reserved = 32768..65535

        class kill(object):
            class signal(object):
                SIGHUP = pywbem.Uint16(1)
                SIGKILL = pywbem.Uint16(9)
                SIGTERM = pywbem.Uint16(15)

        class PrimaryStatus(object):
            Unknown = pywbem.Uint16(0)
            OK = pywbem.Uint16(1)
            Degraded = pywbem.Uint16(2)
            Error = pywbem.Uint16(3)
            # DMTF_Reserved = ..
            # Vendor_Reserved = 0x8000..

## end of class Py_UnixProcessProvider

def get_providers(env): 
    py_unixprocess_prov = Py_UnixProcessProvider(env)  
    return {'Py_UnixProcess': py_unixprocess_prov} 

