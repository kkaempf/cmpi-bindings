import pywbem
from pywbem.cim_provider2 import CIMProvider2

class Test_NullArray(CIMProvider2):
    def __init__ (self, env):
        logger = env.get_logger()
        logger.log_debug('Initializing provider %s from %s' \
                % (self.__class__.__name__, __file__))
        self.instances = {
            '1': {
                'Description' : 'Instance with non-empty properties.',
                'OperationalStatus' : [ self.Values.OperationalStatus.OK],
                'StatusDescriptions' : [ 'OK' ]
            },
            '2': {
                'Description' : 'Instance with empty properties.',
                'OperationalStatus' : pywbem.CIMProperty(
                        name='OperationalStatus',
                        value=[],
                        type='uint16',
                        is_array=True,
                        array_size=0),
                'StatusDescriptions' : pywbem.CIMProperty(
                        name='StatusDescriptions',
                        value=[],
                        type='string',
                        is_array=True,
                        array_size=0)
            },
            '3': {
                'Description' : 'Instance with NULL properties.',
                'OperationalStatus' : pywbem.CIMProperty(
                        name='OperationalStatus',
                        value=None,
                        type='uint16',
                        is_array=True,
                        array_size=0),
                'StatusDescriptions' : pywbem.CIMProperty(
                        name='StatusDescriptions',
                        value=None,
                        type='string',
                        is_array=True,
                        array_size=0)
            }
        }

    def get_instance(self, env, model):
        logger = env.get_logger()
        logger.log_debug('Entering %s.get_instance()' \
                % self.__class__.__name__)

        instance = self.instances[model['InstanceID']]

        model['Description'] = instance['Description']
        model['OperationalStatus'] = instance['OperationalStatus']
        model['StatusDescriptions'] = instance['StatusDescriptions']
        return model

    def enum_instances(self, env, model, keys_only):
        logger = env.get_logger()
        logger.log_debug('Entering %s.enum_instances()' \
                % self.__class__.__name__)
                
        model.path.update({'InstanceID': None})
        
        for k in self.instances.keys():
            model['InstanceID'] = k
            if keys_only:
                yield model
            else:
                try:
                    yield self.get_instance(env, model)
                except pywbem.CIMError, (num, msg):
                    if num not in (pywbem.CIM_ERR_NOT_FOUND, 
                                   pywbem.CIM_ERR_ACCESS_DENIED):
                        raise

    class Values(object):
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
            Relocating = pywbem.Uint16(19)
            # DMTF_Reserved = ..
            # Vendor_Reserved = 0x8000..
            _reverse_map = {0: 'Unknown', 1: 'Other', 2: 'OK', 3: 'Degraded', 4: 'Stressed', 5: 'Predictive Failure', 6: 'Error', 7: 'Non-Recoverable Error', 8: 'Starting', 9: 'Stopping', 10: 'Stopped', 11: 'In Service', 12: 'No Contact', 13: 'Lost Communication', 14: 'Aborted', 15: 'Dormant', 16: 'Supporting Entity in Error', 17: 'Completed', 18: 'Power Mode', 19: 'Relocating'}

def get_providers(env): 
    test_nullarray_prov = Test_NullArray(env)  
    return {'Test_NullArray': test_nullarray_prov}

