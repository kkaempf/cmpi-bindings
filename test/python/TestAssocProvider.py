"""Python Provider for TestAssoc

Instruments:
- TestAssoc_User (instance provider)
- TestAssoc_Group (instance provider)
- TestAssoc_MemberOfGroup (instance and association provider)

"""

import pywbem
import pwd
import grp
from cim_provider import CIMProvider

def get_user_instance(uid, model, keys_only):
    try:
        pwinfo = pwd.getpwuid(uid)
        #model['UserID'] = pywbem.Uint32(uid)
        model['UserID'] = str(uid)
        if hasattr(model, 'path'):
            model.path['UserID'] = str(uid)
        if keys_only:
            return model
        model['UserName'] = pwinfo[0]
        model['LoginShell'] = pwinfo[6]
        model['HomeDirectory'] = pwinfo[5]
        return model
    except KeyError:
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_FOUND)
        
def get_group_instance(gid, model, keys_only):
    try:
        grinfo = grp.getgrgid(gid)
        #model['GroupID'] = pywbem.Uint32(gid)
        model['GroupID'] = str(gid)
        if hasattr(model, 'path'):
            model.path['GroupID'] = str(gid)
        if keys_only:
            return model
        model['GroupName'] = grinfo[0]
        return model
    except KeyError:
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_FOUND)
        
def is_primary_user(uid, gid):
    pwinfo = pwd.getpwuid(uid)
    return gid == pwinfo[3]
    
def is_user_in_group(uid, gid):
    pwinfo = pwd.getpwuid(uid)
    grinfo = grp.getgrgid(gid)
    return pwinfo[0] in grinfo[3]
        
def get_assoc_instance(uid, gid, model, keys_only):
    try:
        isPrimary = is_primary_user(uid, gid)
        if not isPrimary and not is_user_in_group(uid, gid):
            raise pywbem.CIMError(pywbem.CIM_ERR_NOT_FOUND)
        model['Dependent'] = get_user_instance(uid, model.path['Dependent'], keys_only)
        model['Antecedent'] = get_group_instance(gid, model.path['Antecedent'], keys_only)
        if keys_only:
            return model
        model['isPrimaryGroup'] = isPrimary
        return model
    except KeyError:
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_FOUND)

class TestAssoc_User(CIMProvider):
    
    def __init__(self, env):
        self._logger = env.get_logger()
        
    def get_instance(self, env, model, property_list, inst=None):
        try:
            uid = model.path['UserID']
            uid = int(uid)
            return get_user_instance(uid, model, False)
        except KeyError:
            raise pywbem.CIMError(pywbem.CIM_ERR_NOT_FOUND)
        
    def enum_instances(self, env, model, property_list, keys_only):
        self._logger.log_debug("%s:  enum_instances called for class %s" % (self.__class__.__name__.upper(), model.classname))
        for pwent in pwd.getpwall():
            yield get_user_instance(pwent[2], model, keys_only)
        
    def set_instance(self, env, instance, modify_existing, property_list):
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED)
        
    def delete_instance(self, env, instance_name):
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED)
        
    
    
class TestAssoc_Group(CIMProvider):
    
    def __init__(self, env):
        self._logger = env.get_logger()
        
    def get_instance(self, env, model, property_list, inst=None):
        try:
            gid = model.path['GroupID']
            gid = int(gid)
            return get_group_instance(gid, model, False)
        except KeyError:
            raise pywbem.CIMError(pywbem.CIM_ERR_NOT_FOUND)
        
    def enum_instances(self, env, model, property_list, keys_only):
        for grent in grp.getgrall():
            yield get_group_instance(grent[2], model, keys_only)
        
    def set_instance(self, env, instance, modify_existing, property_list):
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED)
        
    def delete_instance(self, env, instance_name):
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED)
        
    
class TestAssoc_MemberOfGroup(CIMProvider):
    
    def __init__(self, env):
        self._logger = env.get_logger()
        
    def get_instance(self, env, model, property_list, inst=None):
        try:
            uid = model.path['Dependent']['UserID']
            uid = int(uid)
            gid = model.path['Antecedent']['GroupID']
            gid = int(gid)
            return get_assoc_instance(uid, gid, model, False)
        except KeyError:
            raise pywbem.CIMError(pywbem.CIM_ERR_NOT_FOUND)
        
    def enum_instances(self, env, model, property_list, keys_only):
        self._logger.log_debug("\n%s:  enum_instances called for class %s" % (self.__class__.__name__.upper(), model.classname))
        for pwent in pwd.getpwall():
            user_cin = pywbem.CIMInstanceName('TestAssoc_User',
                    namespace=model.path.namespace)
            group_cin = pywbem.CIMInstanceName('TestAssoc_Group',
                    namespace=model.path.namespace)
            model['Dependent'] = get_user_instance(pwent[2], user_cin, True)
            model.path['Dependent'] = get_user_instance(pwent[2], 
                    user_cin, True)
            model['Antecedent'] = get_group_instance(pwent[3], group_cin, True)
            model.path['Antecedent'] = get_group_instance(pwent[3], 
                    group_cin, True)
            if not keys_only:
                model['isPrimaryGroup'] = True
            yield model
            for grent in grp.getgrall():
                if pwent[0] in grent[3]:
                    model['Antecedent'] = get_group_instance(grent[2], 
                            group_cin, True)
                    model.path['Antecedent'] = get_group_instance(grent[2], 
                            group_cin, True)
                    if not keys_only:
                        model['isPrimaryGroup'] = False
                    yield model
        
    def set_instance(self, env, instance, modify_existing, property_list):
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED)
        
    def delete_instance(self, env, instance_name):
        raise pywbem.CIMError(pywbem.CIM_ERR_NOT_SUPPORTED)

    def references(self, env, object_name, model, assoc_class_name,
            result_class_name, role, result_role, keys_only):
        self._logger.log_debug("\n%s:  References called for class %s" % (self.__class__.__name__.upper(), object_name))
        model.path.keybindings['antecedent'] = None
        model.path.keybindings['dependent'] = None
        if object_name.classname.lower() == 'testassoc_user':
            if role and role.lower() == 'antecedent':
                return
            if result_role and result_role.lower() == 'dependent':
                return
            if result_class_name and \
                    result_class_name.lower() != 'testassoc_group':
                return
            model['Dependent'] = object_name
            cn = pywbem.CIMInstanceName('TestAssoc_Group',
                    namespace=object_name.namespace)
            uid = model['Dependent']['UserID']
            uid = int(uid)
            pwinfo = pwd.getpwuid(uid)
            model['Antecedent'] = get_group_instance(pwinfo[3], cn, True)
            if not keys_only:
                model['isPrimaryGroup'] = True
            yield model
            for grent in grp.getgrall():
                if pwinfo[0] in grent[3]:
                    model['Antecedent'] = get_group_instance(grent[2], cn, True)
                    if not keys_only:
                        model['isPrimaryGroup'] = False
                    yield model
        if object_name.classname.lower() == 'testassoc_group':
            if role and role.lower() == 'dependent':
                return
            if result_role and result_role.lower() == 'antecedent':
                return
            if result_class_name and \
                    result_class_name.lower() != 'testassoc_user':
                return
            model['Antecedent'] = object_name
            cn = pywbem.CIMInstanceName('TestAssoc_User',
                    namespace=object_name.namespace)
            gid = model['Antecedent']['GroupID']
            gid = int(gid)
            grinfo = grp.getgrgid(gid)
            for member_name in grinfo[3]:
                pwinfo = pwd.getpwnam(member_name)
                model['Dependent'] = get_user_instance(pwinfo[2], cn, True)
                if not keys_only:
                    model['isPrimaryGroup'] = False
                yield model
            for pwent in pwd.getpwall():
                if pwent[3] == grinfo[2]:
                    model['Dependent'] = get_user_instance(pwent[2], cn, True)
                    if not keys_only:
                        model['isPrimaryGroup'] = True
                    yield model
        
    
def get_providers(env):
    user_prov = TestAssoc_User(env)
    group_prov = TestAssoc_Group(env)
    mog_prov = TestAssoc_MemberOfGroup(env)
    return { 'TestAssoc_User' : user_prov,
        'TestAssoc_Group' : group_prov,
        'TestAssoc_MemberOfGroup' : mog_prov }
