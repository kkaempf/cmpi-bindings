#!/usr/bin/env python

""" Test script to validate the correctness of
association handling in a CIM provider interface.

Exercises the classes defined in TestAssoc.mof
and the corresponding provider in TestAssocProvider.py.
"""

import unittest
import optparse
import pywbem
import pwd
import grp

from lib import ProviderSanityTest as PST
from lib import wbem_connection
from socket import getfqdn

_globalVerbose = False

conn = None
   
def isObjPathMatch( op1, op2 ):
    op1.host = None
    op2.host = None
    _local_op1_str = str(op1)
    _local_op2_str = str(op2)
    """
    This function is used to manipulate CIMInstanceName objects to
    determine if they are the same.
    In openwbem, for some reason if you take some object, follow
    a reference to a related object, then follow the reference back
    to the original, the reference back has the hostname prepended
    to the beginning of the object path, whereas the original does not.
    So this function considers this possibility in comparing two
    object paths.
    If you want to not accomodate this discrepancy, comment out the
    rest of the code up to but not including the return statement.
    """
    '''
    # removed in favor of ...host = None above
    hostname = '//%s' % getfqdn()
    if -1 == _local_op1_str.find(hostname, 0, len(hostname)):
        _local_op1_str = '%s/%s' % (hostname,str(op1))
    if -1 == _local_op2_str.find(hostname, 0, len(hostname)):
        _local_op2_str = '%s/%s' % (hostname,str(op2))
    '''
    return _local_op1_str == _local_op2_str
    

        

class TestAssociations(unittest.TestCase):

    def _dbgPrint(self, msg=''):
        if self._verbose:
            if len(msg):
                print('\t -- %s --' % msg)
            else:
                print('')

    def setUp(self):
        unittest.TestCase.setUp(self)
        self._verbose = _globalVerbose
        self._conn = conn
        self._dbgPrint()
        
    def tearDown(self):
        unittest.TestCase.tearDown(self)
    
    def test_a_users(self):
        """
        This test validates that the number of TestAssoc_User objects
        reported from the CIMOM is the same as the number of users
        we get directly from the system via pwd.getpwall(), and that
        the users are the same in both sets.
        """
        self._dbgPrint('Checking validity of TestAssoc_User objects.')
        cimom_users = self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False)
        sys_users = pwd.getpwall()
        self._dbgPrint('Comparing number of TestAssoc_User objects with system users...')
        if len(cimom_users) != len(sys_users):
            self.fail('Different number of users reported from CIMOM than are in system.')
        self._dbgPrint('Number of users matches.')
        self._dbgPrint('Matching every TestAssoc_User to a system user...')
        for cu in cimom_users:
            found = False
            for i in xrange(len(sys_users)):
                if int(cu['UserID']) == sys_users[i][2]:
                    found = True
                    if cu['UserName'] != sys_users[i][0] or \
                            cu['HomeDirectory'] != sys_users[i][5] or \
                            cu['LoginShell'] != sys_users[i][6]:
                        self.fail('%s "%s" %s' % ('User information for user name',
                                cu['UserName'],
                                'from CIMOM does not match system information.'))
                    sys_users.pop(i)
                    break
            if not found:
                self.fail('User name "%s" from CIMOM not found in system.' % cu['UserName'])
        if 0 < len(sys_users):
            self.fail('Not all system users found in list of users from CIMOM.')
        self._dbgPrint('All users match.')
        
    def test_a_groups(self):
        """
        Same as test_a_users but for TestAssoc_Group and system groups.
        """
        self._dbgPrint('Checking validity of TestAssoc_Group objects.')
        cimom_groups = self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False)
        sys_groups = grp.getgrall()
        self._dbgPrint('Comparing number of TestAssoc_Group objects with system groups...')
        if len(cimom_groups) != len(sys_groups):
            self.fail('Different number of groups reported from CIMOM than are in system.')
        self._dbgPrint('Number of groups matches.')
        self._dbgPrint('Matching every TestAssoc_Group to a system group...')
        for cg in cimom_groups:
            found = False
            for i in xrange(len(sys_groups)):
                if int(cg['GroupID']) == sys_groups[i][2]:
                    found = True
                    if cg['GroupName'] != sys_groups[i][0]:
                        self.fail('%s "%s" %s' % ('Group information from group name',
                                cg['GroupName'],
                                'from CIMOM does not match system information.'))
                    sys_groups.pop(i)
                    break
            if not found:
                self.fail('Group name "%s" from CIMOM not found in system.' % cg['GroupName'])
        if 0 < len(sys_groups):
            self.fail('Not all system groups found in list of groups from CIMOM.')
        self._dbgPrint('All groups match.')

    def test_b_usergroups(self):
        """
        This test fetches all TestAssoc_User objects from the CIMOM.  For each user object,
        the references for that user object are retrieved.  The test validates that each group
        associated with this user is correct based upon system information, and also that the
        correct primary group is identified.
        """
        self._dbgPrint('Validating TestAssoc_User group references with system information.')
        cimom_users = self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False)
        for cu in cimom_users:
            self._dbgPrint('Checking group references for user %s' % cu['UserName'])
            pwinfo = pwd.getpwuid(int(int(cu['UserID'])))
            #for ref in refs:
            for ref in self._conn.References(cu.path, ResultClass='TestAssoc_MemberOfGroup'):
                grp = self._conn.GetInstance(ref['Antecedent'], LocalOnly=False)
                if pwinfo[3] == int(grp['GroupID']):
                    if ref['isPrimaryGroup']:
                        self._dbgPrint('Correctly identified primary group %s for user %s' % (grp['GroupName'], cu['UserName']))
                        break
                    else:
                        self.fail('%s "%s" %s "%s" %s' % ('Group',
                                grp['GroupName'],
                                'not designated as primary for user',
                                pwinfo[0],
                                'when it should be.'))
                else:
                    grinfo = grp.getgruid(int(grp['GroupID']))
                    if pwinfo[0] in grinfo[3]:
                        self._dbgPrint('Correctly identified supplemental group %s for user %s' % (grp['GroupName'], cu['UserName']))
                        break
                    else:
                        self.fail('%s "%s" %s "%s" %s' % ('User',
                                pwinfo[0],
                                'not a member of group',
                                ref['GroupName'],
                                'when it should be.'))
        
    def test_b_groupusers(self):
        """
        This test fetches all TestAssoc_Group objects from the CIMOM.  For each group object,
        the references for that group object are retrieved.  The test validates that each user
        associated with this group is correct based upon system information, and also that the
        correct primary groups are identified.
        """
        self._dbgPrint('Validating TestAssoc_Group user references with system information.')
        cimom_groups = self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False)
        for cg in cimom_groups:
            refs = self._conn.References(cg.path, ResultClass='TestAssoc_MemberOfGroup')
            grinfo = grp.getgrgid(int(int(cg['GroupID'])))
            for ref in refs:
                usr = self._conn.GetInstance(ref['Dependent'], LocalOnly=False)
                pwinfo = pwd.getpwuid(int(usr['UserID']))
                if pwinfo[0] in grinfo[3]:
                    if ref['isPrimaryGroup']:
                        self.fail('%s "%s" %s "%s" %s' % ('Group',
                                cg['GroupName'],
                                'designated as primary for user',
                                pwinfo[0],
                                'when it should not be.'))
                    else:
                        self._dbgPrint('Correctly identified supplmental group %s for user %s' % (cg['GroupName'], usr['UserName']))
                elif pwinfo[3] == int(cg['GroupID']):
                    if not ref['isPrimaryGroup']:
                        self.fail('%s "%s" %s "%s" %s' % ('Group',
                                cg['GroupName'],
                                'not designated as primary for user',
                                pwinfo[0],
                                'when it should be.'))
                    else:
                        self._dbgPrint('Correctly identified primary group %s for user %s' % (cg['GroupName'], usr['UserName']))
                            
    def test_c_sanitytest(self):
        PST.association_sanity_check(self, self._conn, 'TestAssoc_MemberOfGroup', self._verbose)
        
    def test_d_user_op_references_traversal(self):
        """
        This test fetches all user object paths, follows references for these object paths
        to group object paths, then follows references back, and checks to see that the same
        user object path can be found and that it fetches the same references as the original.
        """
        self._dbgPrint('Validating user object path references traversal.')
        for uop in self._conn.EnumerateInstanceNames('TestAssoc_User'):
            self._dbgPrint('Getting user references for object path %s' % uop )
            urefs = self._conn.References(uop, ResultClass='TestAssoc_MemberOfGroup')
            for uref in urefs:
                uopFound = False
                self._dbgPrint('Getting group references for object path %s' % uref['Antecedent'])
                for gref in self._conn.References(uref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                    if uop == gref['Dependent']:
                        self._dbgPrint('Found matching user object path.')
                        uopFound = True
                        for uref2 in self._conn.References(gref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                            if not uref2 in urefs:
                                userobj = self._conn.GetInstance(uop, LocalOnly=False)
                                self.fail('Failed to retrieve identical references for user "%s"' % userobj['UserName'])
                        self._dbgPrint('Found matching references for user object path.')
                        break
                if not uopFound:
                    userobj = self._conn.GetInstance(uop, LocalOnly=False)
                    grpobj = self._conn.GetInstance(uref['Antecedent'], LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Reference to group',
                            grpobj['GroupName'],
                            'from user',
                            userobj['UserName'],
                            'doesn\'t return to user.'))
                            
    def test_d_user_op_referencenames_traversal(self):
        """
        Same as test_d_user_op_references_traversal, but using the ReferenceNames call
        instead of the References call.
        """
        self._dbgPrint('Validating user object path reference names traversal.')
        for uop in self._conn.EnumerateInstanceNames('TestAssoc_User'):
            self._dbgPrint('Getting user reference names for object path %s' % uop)
            urefs = self._conn.ReferenceNames(uop, ResultClass='TestAssoc_MemberOfGroup')
            for uref in urefs:
                uopFound = False
                self._dbgPrint('Getting group reference names for object path %s' % uref['Antecedent'])
                for gref in self._conn.ReferenceNames(uref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                    if uop == gref['Dependent']:
                        self._dbgPrint('Found matching user object path.')
                        uopFound = True
                        for uref2 in self._conn.ReferenceNames(gref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                            if not uref2 in urefs:
                                userobj = self._conn.GetInstance(uop, LocalOnly=False)
                                self.fail('Failed to retrieve identical references for user "%s"' % userobj['UserName'])
                        self._dbgPrint('Found matching references for user object path.')
                        break
                if not uopFound:
                    userobj = self._conn.GetInstance(uop, LocalOnly=False)
                    grpobj = self._conn.GetInstance(uref['Antecedent'], LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Reference to group',
                            grpobj['GroupName'],
                            'from user',
                            userobj['UserName'],
                            'doesn\'t return to user.'))
                            
    def test_e_user_references_traversal(self):
        """
        Same as test_d_user_op_references_traversal, but using users instead
        of object paths, i.e. initially calls EnumerateInstances instead of EnumerateInstanceNames.
        """
        self._dbgPrint('Validating user object references traversal.')
        for userobj in self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False):
            self._dbgPrint('Getting user references for user %s' % userobj['UserName'])
            urefs = self._conn.References(userobj.path, ResultClass='TestAssoc_MemberOfGroup')
            for uref in urefs:
                userobjFound = False
                self._dbgPrint('Getting group references for user object path %s' % uref['Antecedent'])
                for gref in self._conn.References(uref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                    userobj2 = self._conn.GetInstance(gref['Dependent'], LocalOnly=False)
                    if userobj == userobj2:
                        self._dbgPrint('Found matching user object.')
                        userobjFound = True
                        for uref2 in self._conn.References(gref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                            if not uref2 in urefs:
                                self.fail('Failed to retrieve identical references for user "%s"' % userobj['UserName'])
                        self._dbgPrint('Found matching references for user object.')
                        break
                if not userobjFound:
                    grpobj = self._conn.GetInstance(uref['Antecedent'], LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Reference to group',
                            grpobj['GroupName'],
                            'from user',
                            userobj['UserName'],
                            'doesn\'t return to user.'))
                            
    def test_e_user_referencenames_traversal(self):
        """
        Same as test_e_user_references_traversal, but calling ReferenceNames instead
        of References.
        """
        self._dbgPrint('Validating user object reference names traversal.')
        for userobj in self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False):
            self._dbgPrint('Getting user reference names for user %s' % userobj['UserName'])
            urefs = self._conn.ReferenceNames(userobj.path, ResultClass='TestAssoc_MemberOfGroup')
            for uref in urefs:
                userobjFound = False
                self._dbgPrint('Getting group references for user object path %s' % uref['Antecedent'])
                for gref in self._conn.ReferenceNames(uref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                    userobj2 = self._conn.GetInstance(gref['Dependent'], LocalOnly=False)
                    if userobj == userobj2:
                        self._dbgPrint('Found matching user object.')
                        userobjFound = True
                        for uref2 in self._conn.ReferenceNames(gref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                            if not uref2 in urefs:
                                self.fail('Failed to retrieve identical references for user "%s"' % userobj['UserName'])
                        self._dbgPrint('Found matching reference names for user object.')
                        break
                if not userobjFound:
                    grpobj = self._conn.GetInstance(uref['Antecedent'], LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Reference to group',
                            grpobj['GroupName'],
                            'from user',
                            userobj['UserName'],
                            'doesn\'t return to user.'))
                
    def test_f_user_op_associators_traversal(self):
        """
        Same as test_d_user_op_references_traversal but calls Associators
        instead of References; thus we skip looking up the group object
        for each reference Antecedent.
        """
        self._dbgPrint('Validating user object path associators traversal.')
        for uop in self._conn.EnumerateInstanceNames('TestAssoc_User'):
            self._dbgPrint('Getting associated groups for user object path %s' % uop)
            for grp in self._conn.Associators(uop, AssocClass='TestAssoc_MemberOfGroup'):
                usrFound = False
                self._dbgPrint('Getting associated users for group object path %s' % grp.path)
                for usr in self._conn.Associators(grp.path, AssocClass='TestAssoc_MemberOfGroup'):
                    if isObjPathMatch( usr.path, uop ):
                        usrFound = True
                        self._dbgPrint('Found matching user object.')
                        if not grp in self._conn.Associators(usr.path, AssocClass='TestAssoc_MemberOfGroup'):
                            self.fail('Failed to retrieve identical associators for user "%s"' % usr['UserName'])
                        self._dbgPrint('Found matching associators for user %s' % usr['UserName'])
                        break
                if not usrFound:
                    self.fail('%s "%s" %s "%s" %s' % ('Associator to group',
                            grp['GroupName'],
                            'from user',
                            usr['UserName'],
                            'doesn\'t return to user.'))
    
    def test_f_user_op_associatornames_traversal(self):
        """
        Same as test_f_user_op_associators_traversal, but calls
        AssociatorNames instead of Associators.
        """
        self._dbgPrint('Validating user object path associator names traversal.')
        for uop in self._conn.EnumerateInstanceNames('TestAssoc_User'):
            self._dbgPrint('Getting associated group names for user object path %s' % uop)
            for grp in self._conn.AssociatorNames(uop, AssocClass='TestAssoc_MemberOfGroup'):
                usrFound = False
                self._dbgPrint('Getting associated user names for group object path %s' % grp)
                for usr in self._conn.AssociatorNames(grp, AssocClass='TestAssoc_MemberOfGroup'):
                    if isObjPathMatch( usr, uop ):
                        usrFound = True
                        self._dbgPrint('Found matching user object path.')
                        if not grp in self._conn.AssociatorNames(usr, AssocClass='TestAssoc_MemberOfGroup'):
                            userobj = self._conn.GetInstance(usr, LocalOnly=False)
                            self.fail('Failed to retrieve identical associators for user "%s"' % userobj['UserName'])
                        self._dbgPrint('Found matching associator names for user object path %s' % uop)
                        break
                if not usrFound:
                    userobj = self._conn.GetInstance(usr, LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Associator to group',
                            grp['GroupName'],
                            'from user',
                            userobj['UserName'],
                            'doesn\'t return to user.'))
            
    def test_g_user_associators_traversal(self):
        """
        Same as test_f_user_op_associators_traversal, but uses user objects
        instead of user object paths, i.e. initially calls EnumerateInstances
        instead of EnumerateInstanceNames.
        Performs a deeper check of user object equivalence.
        """
        self._dbgPrint('Validating user associators traversal.')
        for usr in self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False):
            self._dbgPrint('Getting associated groups for user %s' % usr['UserName'])
            for grp in self._conn.Associators(usr.path, AssocClass='TestAssoc_MemberOfGroup'):
                usrFound = False
                self._dbgPrint('Getting associated users for group %s' % grp['GroupName'])
                for usr2 in self._conn.Associators(grp.path, AssocClass='TestAssoc_MemberOfGroup'):
                    if isObjPathMatch( usr2.path, usr.path ) and \
                            usr2['UserName'] == usr['UserName'] and \
                            usr2['UserID'] == usr['UserID']:
                        usrFound = True
                        self._dbgPrint('Found matching user.')
                        if not grp in self._conn.Associators(usr2.path, AssocClass='TestAssoc_MemberOfGroup'):
                            self.fail('Failed to retrieve identical associators for user "%s"' % usr2['UserName'])
                        self._dbgPrint('Found matching associated objects for user %s' % usr['UserName'])
                        break
                if not usrFound:
                    self.fail('%s "%s" %s "%s" %s' % ('Associator to group',
                            grp['GroupName'],
                            'from user',
                            usr['UserName'],
                            'doesn\'t return to user.'))
        
    def test_g_user_associatornames_traversal(self):
        """
        Same as test_g_user_associators_traversal but calls AssociatorNames instead of Associators.
        """
        self._dbgPrint('Validating user associator names traversal.')
        for usr in self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False):
            self._dbgPrint('Getting associated group names for user %s' % usr['UserName'])
            for grp in self._conn.AssociatorNames(usr.path, AssocClass='TestAssoc_MemberOfGroup'):
                usrFound = False
                self._dbgPrint('Getting associated user names for group object path %s' % grp)
                for usr2 in self._conn.AssociatorNames(grp, AssocClass='TestAssoc_MemberOfGroup'):
                    if isObjPathMatch( usr2, usr.path ):
                        usrFound = True
                        self._dbgPrint('Found matching user.')
                        if not grp in self._conn.AssociatorNames(usr2, AssocClass='TestAssoc_MemberOfGroup'):
                            userobj = self._conn.GetInstance(usr2, LocalOnly=False)
                            self.fail('Failed to retrieve identical associators for user "%s"' % userobj['UserName'])
                        self._dbgPrint('Found matching associated group object paths for user %s' % usr['UserName'])
                        break
                if not usrFound:
                    self.fail('%s "%s" %s "%s" %s' % ('Associator to group',
                            grp['GroupName'],
                            'from user',
                            usr['UserName'],
                            'doesn\'t return to user.'))
            
    def test_h_group_op_references_traversal(self):
        """
        This test fetches all group object paths, follows references for these object paths
        to user object paths, then follows references back, and checks to see that the same
        group object path can be found and that it fetches the same references as the original.
        """
        self._dbgPrint('Validating group object path references traversal.')
        for gop in self._conn.EnumerateInstanceNames('TestAssoc_Group'):
            self._dbgPrint('Getting group references for object path %s' % gop)
            grefs = self._conn.References(gop, ResultClass='TestAssoc_MemberOfGroup')
            for gref in grefs:
                gopFound = False
                self._dbgPrint('Getting user references for object path %s' % gref['Dependent'])
                for uref in self._conn.References(gref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                    if gop == uref['Antecedent']:
                        self._dbgPrint('Found matching group object path.')
                        gopFound = True
                        for gref2 in self._conn.References(uref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                            if not gref2 in grefs:
                                grpobj = self._conn.GetInstance(gop, LocalOnly=False)
                                self.fail('Failed to retrieve identical references for group "%s"' % grpobj['GroupName'])
                        self._dbgPrint('Found matching references for group object path.')
                        break
                if not gopFound:
                    grpobj = self._conn.GetInstance(gop, LocalOnly=False)
                    userobj = self._conn.GetInstance(gref['Dependent'], LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Reference to user',
                            userobj['UserName'],
                            'from group',
                            grpobj['GroupName'],
                            'doesn\'t return to group.'))
        
    def test_h_group_op_referencenames_traversal(self):
        """
        Same as test_h_group_op_references_traversal but calls
        ReferenceNames instead of References.
        """
        self._dbgPrint('Validating group object path reference names traversal.')
        for gop in self._conn.EnumerateInstanceNames('TestAssoc_Group'):
            self._dbgPrint('Getting group reference names for object path %s' % gop)
            grefs = self._conn.ReferenceNames(gop, ResultClass='TestAssoc_MemberOfGroup')
            for gref in grefs:
                gopFound = False
                self._dbgPrint('Getting user reference names for object path %s' % gref['Dependent'])
                for uref in self._conn.ReferenceNames(gref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                    if gop == uref['Antecedent']:
                        self._dbgPrint('Found matching group object path.')
                        gopFound = True
                        for gref2 in self._conn.ReferenceNames(uref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                            if not gref2 in grefs:
                                grpobj = self._conn.GetInstance(gop, LocalOnly=False)
                                self.fail('Failed to retrieve identical references for group "%s"' % grpobj['GroupName'])
                        self._dbgPrint('Found matching reference names for group object path.')    
                        break
                if not gopFound:
                    grpobj = self._conn.GetInstance(gop, LocalOnly=False)
                    userobj = self._conn.GetInstance(gref['Dependent'], LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Reference to user',
                            userobj['UserName'],
                            'from group',
                            grpobj['GroupName'],
                            'doesn\'t return to group.'))
    
    def test_i_group_references_traversal(self):
        """
        Same as test_h_group_op_references_traversal but uses group
        objects instead of object paths, i.e. initially calls EnumerateInstances
        instead of EnumerateInstanceNames.
        """
        self._dbgPrint('Validating group references traversal.')
        for grp in self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False):
            self._dbgPrint('Getting group references for group %s' % grp['GroupName'])
            grefs = self._conn.References(grp.path, ResultClass='TestAssoc_MemberOfGroup')
            for gref in grefs:
                grpFound = False
                self._dbgPrint('Getting user references for object path %s' % gref['Dependent'])
                for uref in self._conn.References(gref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                    if grp.path == uref['Antecedent']:
                        self._dbgPrint('Found matching group.')
                        grpFound = True
                        for gref2 in self._conn.References(uref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                            if not gref2 in grefs:
                                self.fail('Failed to retrieve identical references for group "%s"' % grp['GroupName'])
                        self._dbgPrint('Found matching references for group.')
                        break
                if not grpFound:
                    userobj = self._conn.GetInstance(gref['Dependent'], LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Reference to user',
                            userobj['UserName'],
                            'from group',
                            grp['GroupName'],
                            'doesn\'t return to group.'))
        
    def test_i_group_referencenames_traversal(self):
        """
        Same as test_i_group_references_traversal but calls
        ReferenceNames instead of References.
        """
        self._dbgPrint('Validating group reference names traversal.')
        for grp in self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False):
            self._dbgPrint('Getting group reference names for group %s' % grp['GroupName'])
            grefs = self._conn.ReferenceNames(grp.path, ResultClass='TestAssoc_MemberOfGroup')
            for gref in grefs:
                grpFound = False
                self._dbgPrint('Getting user reference names for object path %s' % gref['Dependent'])
                for uref in self._conn.ReferenceNames(gref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                    if grp.path == uref['Antecedent']:
                        self._dbgPrint('Found matching group.')
                        grpFound = True
                        for gref2 in self._conn.ReferenceNames(uref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                            if not gref2 in grefs:
                                self.fail('Failed to retrieve identical references for group "%s"' % grp['GroupName'])
                        self._dbgPrint('Found matching reference names for group.')
                        break
                if not grpFound:
                    userobj = self._conn.GetInstance(gref['Dependent'], LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Reference to user',
                            userobj['UserName'],
                            'from group',
                            grp['GroupName'],
                            'doesn\'t return to group.'))
       
    def test_j_group_op_associators_traversal(self):
        """
        Same as test_h_group_op_references_traversal but
        calls Associators instead of References.
        """
        self._dbgPrint('Validating group object path associators traversal.')
        for gop in self._conn.EnumerateInstanceNames('TestAssoc_Group'):
            self._dbgPrint('Getting associated users for group object path %s' % gop)
            for usr in self._conn.Associators(gop, AssocClass='TestAssoc_MemberOfGroup'):
                grpFound = False
                self._dbgPrint('Getting associated groups for user %s' % usr['UserName'])
                for grp in self._conn.Associators(usr.path, AssocClass='TestAssoc_MemberOfGroup'):
                    if isObjPathMatch( grp.path, gop ):
                        grpFound = True
                        self._dbgPrint('Found matching group object path.')
                        if not usr in self._conn.Associators(grp.path, AssocClass='TestAssoc_MemberOfGroup'):
                            self.fail('Failed to retrieve identical associators for group "%s"' % grp['GroupName'])
                        self._dbgPrint('Found matching associators for group object path.')
                        break
                if not grpFound:
                    self.fail('%s "%s" %s "%s" %s' % ('Associator to user',
                            usr['UserName'],
                            'from group',
                            grp['GroupName'],
                            'doesn\'t return to group.'))
        
    def test_j_group_op_associatornames_traversal(self):
        """
        Same as test_j_group_op_associators_traversal but
        calls AssociatorNames instead of Associators.
        """
        self._dbgPrint('Validating group object path associator names traversal.')
        for gop in self._conn.EnumerateInstanceNames('TestAssoc_Group'):
            self._dbgPrint('Getting associated user names for group object path %s' % gop)
            for usr in self._conn.AssociatorNames(gop, AssocClass='TestAssoc_MemberOfGroup'):
                grpFound = False
                self._dbgPrint('Getting associated group names for user object path %s' % usr)
                for grp in self._conn.AssociatorNames(usr, AssocClass='TestAssoc_MemberOfGroup'):
                    if isObjPathMatch( grp, gop ):
                        grpFound = True
                        self._dbgPrint('Found matching group object path.')
                        if not usr in self._conn.AssociatorNames(grp, AssocClass='TestAssoc_MemberOfGroup'):
                            grpobj = self._conn.GetInstance(grp, LocalOnly=False)
                            self.fail('Failed to retrieve identical associators for group "%s"' % grpobj['GroupName'])
                        self._dbgPrint('Found matching associator names for group object path.')
                        break
                if not grpFound:
                    usrobj = self._conn.GetInstance(usr, LocalOnly=False)
                    grpobj = self._conn.GetInstance(grp, LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Associator to user',
                            usrobj['UserName'],
                            'from group',
                            grpobj['GroupName'],
                            'doesn\'t return to group.'))
            
    def test_k_group_associators_traversal(self):
        """
        Same as test_j_group_op_associators_traversal but
        uses group objects instead of object paths, i.e. originally
        calls EnumerateInstances instead of EnumerateInstanceNames.
        Performs a deeper object comparison of the two groups.
        """
        self._dbgPrint('Validating group associators traversal.')
        for grp in self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False):
            self._dbgPrint('Getting associated users for group %s' % grp['GroupName'])
            for usr in self._conn.Associators(grp.path, AssocClass='TestAssoc_MemberOfGroup'):
                grpFound = False
                self._dbgPrint('Getting associated groups for user %s' % usr['UserName'])
                for grp2 in self._conn.Associators(usr.path, AssocClass='TestAssoc_MemberOfGroup'):
                    if isObjPathMatch( grp2.path, grp.path ) and \
                            grp2['GroupID'] == grp['GroupID'] and \
                            grp2['GroupName'] == grp['GroupName']:
                        grpFound = True
                        self._dbgPrint('Found matching group.')
                        if not usr in self._conn.Associators(grp2.path, AssocClass='TestAssoc_MemberOfGroup'):
                            self.fail('Failed to retrieve identical associators for group "%s"' % grp2['GroupName'])
                        self._dbgPrint('Found matching associated users for group.')
                        break
                if not grpFound:
                    self.fail('%s "%s" %s "%s" %s' % ('Associator to user',
                            usr['UserName'],
                            'from group',
                            grp['GroupName'],
                            'doesn\'t return to group.'))
        
    def test_k_group_associatornames_traversal(self):
        """
        Same as test_k_group_associators_traversal but calls
        AssociatorNames instead of Associators.
        """
        self._dbgPrint('Validating group associator names traversal.')
        for grp in self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False):
            self._dbgPrint('Getting associated user names for group %s' % grp['GroupName'])
            for uop in self._conn.AssociatorNames(grp.path, AssocClass='TestAssoc_MemberOfGroup'):
                grpFound = False
                self._dbgPrint('Getting associated group names for user object path %s' % uop)
                for gop in self._conn.AssociatorNames(uop, AssocClass='TestAssoc_MemberOfGroup'):
                    if isObjPathMatch( gop, grp.path ):
                        grpFound = True
                        self._dbgPrint('Found matching group.')
                        if not uop in self._conn.AssociatorNames(gop, AssocClass='TestAssoc_MemberOfGroup'):
                            grpobj = self._conn.GetInstance(gop, LocalOnly=False)
                            self.fail('Failed to retrieve identical associators for group "%s"' % grpobj['GroupName'])
                        self._dbgPrint('Found matching associator names for group.')
                        break
                if not grpFound:
                    usrobj = self._conn.GetInstance(uop, LocalOnly=False)
                    self.fail('%s "%s" %s "%s" %s' % ('Associator to user',
                            usrobj['UserName'],
                            'from group',
                            grp['GroupName'],
                            'doesn\'t return to group.'))
       
    def test_l_user_primarygroup_references_traversal(self):
        """
        This test fetches all TestAssoc_User objects, and for each one, it
        searches the References for the reference that is designated as the
        one to the primary group.  Then it follows that reference to the group
        on the other side, and searches all the references on that side for
        primary group designations, and makes sure one of them points to
        the original user object.
        Note that while a user can only have one primary group, any group may
        be primary for a number of users.
        """
        self._dbgPrint('Validating User->Primary Group->User references traversal.')
        for usr in self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False):
            self._dbgPrint('Finding primary group for user %s' % usr['UserName'])
            for ref in self._conn.References(usr.path, ResultClass='TestAssoc_MemberOfGroup'):
                if ref['isPrimaryGroup']:
                    usrFound = False
                    self._dbgPrint('Found primary group, object path is %s' % ref['Antecedent'])
                    for ref2 in self._conn.References(ref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                        if ref2['isPrimaryGroup']:
                            if ref2['Dependent'] == usr.path:
                                usrFound = True
                                break
                    if not usrFound:
                        self.fail('User "%s" primary group does not indicate user as primary.' % usr['UserName'])
                    self._dbgPrint('Retraced primary group reference back to original user.')
                    break
        
    def test_l_user_primarygroup_associators_traversal(self):
        """
        This test is similar to test_l_user_primarygroup_references_traversal
        but uses Associators instead of References.  This means it cannot directly
        check that the relationship is for the primary group using the CIMOM.  So
        what this test does instead is use system information to identify the group
        which *should* be the primary group, then it constructs a CIMInstanceName using
        the user object path as Dependent and the group object path as Antecedent.
        Then it fetches a TestAssoc_MemberOfGroup CIMInstance using this name, and
        verifies that an instance is retrieved and that it is designated as primary.
        """
        self._dbgPrint('Validating User->Primary Group->User associators traversal.')
        for usr in self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False):
            self._dbgPrint('Finding primary group for user %s' % usr['UserName'])
            grp = None
            for g in self._conn.Associators(usr.path, AssocClass='TestAssoc_MemberOfGroup'):
                if int(g['GroupID']) == pwd.getpwuid(int(usr['UserID']))[3]:
                    grp = g
                    break
            if grp is None:
                self.fail('Couldn\'t find group with group id that matches user "%s" group id.' % usr['UserName'])
            self._dbgPrint('Found primary group candidate %s for user %s' % (grp['GroupName'], usr['UserName']))
            refname = pywbem.CIMInstanceName('TestAssoc_MemberOfGroup',
                    namespace='root/cimv2',
                    keybindings={
                        'Dependent':usr.path,
                        'Antecedent':grp.path})
            ref = self._conn.GetInstance(refname, LocalOnly=False)
            if not ref:
                self.fail('Failed to retrieve reference instance from known associator object paths.')
            if not ref['isPrimaryGroup']:
                self.fail('%s "%s" %s "%s" %s' % ('Reference does not indicate primary group for user',
                        usr['UserName'],
                        'and group',
                        grp['GroupName'],
                        'when it should.'))
            self._dbgPrint('Successfully validated user/group relationship.')
                
    def test_m_group_primarygroup_references_traversal(self):
        """
        This test fetches all TestAssoc_Group objects, and checks every reference that
        indicates a primary group reference.  For every user on the other side of the
        reference, the test fetches references for that user, looks up the primary group
        reference, and makes sure it refers back to the original group.
        """
        self._dbgPrint('Validating Group->Primary Group->Group references traversal.')
        for grp in self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False):
            self._dbgPrint('Getting primary group references for group %s' % grp['GroupName'])
            for ref in self._conn.References(grp.path, ResultClass='TestAssoc_MemberOfGroup'):
                if ref['isPrimaryGroup']:
                    pgFound = False
                    self._dbgPrint('%s %s %s, checking its references...' % (grp['GroupName'],
                            'is a primary group for user object path', ref['Dependent']))
                    for ref2 in self._conn.References(ref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                        if ref2['isPrimaryGroup']:
                            pgFound = True
                            if grp.path != ref2['Antecedent']:
                                self.fail('Discovered primary group not the same as the original for "%s".' % grp['GroupName'])
                            break
                    if not pgFound:
                        usr = self._conn.GetInstance(ref['Dependent'], LocalOnly=False)
                        self.fail('Could not find primary group "%s" for discovered group member "%s".' % (grp['GroupName'], usr['UserName']))
                    self._dbgPrint('Retraced primary group reference back to original group.')
                    break
        
    def test_m_group_primarygroup_associators_traversal(self):
        """
        This test is like test_m_group_primarygroup_references_traversal
        but uses Associators instead of References, so it validates the relationship
        by constructing a TestAssoc_MemberOfGroup object from scratch;
        see test_l_user_primarygroup_associators_traversal for details.
        """
        self._dbgPrint('Validating Group->Primary Group->Group associators traversal.')
        for grp in self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False):
            self._dbgPrint('Getting associated users for group %s' % grp['GroupName'])
            for usr in self._conn.Associators(grp.path, AssocClass='TestAssoc_MemberOfGroup'):
                if int(grp['GroupID']) == pwd.getpwuid(int(usr['UserID']))[3]:
                    self._dbgPrint('Found user %s that has group %s as primary; checking reference object.' % (usr['UserName'],
                            grp['GroupName']))
                    refname = pywbem.CIMInstanceName('TestAssoc_MemberOfGroup',
                            namespace='root/cimv2',
                            keybindings={
                                'Dependent':usr.path,
                                'Antecedent':grp.path})
                    ref = self._conn.GetInstance(refname, LocalOnly=False)
                    if not ref:
                        self.fail('Failed to get reference instance for group "%s" and user "%s".' % (grp['GroupName'], usr['UserName']))
                    if not ref['isPrimaryGroup']:
                        self.fail('%s "%s" %s "%s" %s' % ('Reference for group',
                                grp['GroupName'],
                                'and user',
                                usr['UserName'],
                                'not designated primary when it should be.'))
                    self._dbgPrint('Successfully validated group/user relationship.')
                                
    def test_n_user_nonprimarygroup_references_traversal(self):
        """
        This test fetches each TestAssoc_User object and checks references to
        each object that are not designated as being the primary group reference.
        Then with each group it fetches references back to the users, and makes
        sure there is a reference to this user and that it is not designated
        as primary.
        """
        self._dbgPrint('Validating User->Supplemental Group->User references traversal.')
        for usr in self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False):
            self._dbgPrint('Finding supplemental groups for user %s' % usr['UserName'])
            for ref in self._conn.References(usr.path, ResultClass='TestAssoc_MemberOfGroup'):
                if not ref['isPrimaryGroup']:
                    usrFound = False
                    self._dbgPrint('%s %s for user %s, checking references...' % ('Found supplemental group object path',
                            ref['Antecedent'], usr['UserName']))
                    for ref2 in self._conn.References(ref['Antecedent'], ResultClass='TestAssoc_MemberOfGroup'):
                        if not ref2['isPrimaryGroup']:
                            if ref2['Dependent'] == usr.path:
                                usrFound = True
                                break
                    if not usrFound:
                        self.fail('User "%s" non-primary group does not indicate user as member.' % usr['UserName'])
                    self._dbgPrint('Retraced supplemental group reference back to original user.')
                    break
        
    def test_n_user_nonprimarygroup_associators_traversal(self):
        """
        This test is like test_n_user_nonprimarygroup_references_traversal except
        it uses Associators instead of References.  Like test_l_user_primarygroup_associators_traversal,
        it constructs a TestAssoc_MemberOfGroup reference object path from scratch,
        fetches the instance, and validates that it has the expected properties.
        """
        self._dbgPrint('Validating User->Supplemental Group->User associators traversal.')
        for usr in self._conn.EnumerateInstances('TestAssoc_User', LocalOnly=False):
            self._dbgPrint('Finding supplemental groups for user %s' % usr['UserName'])
            for grp in self._conn.Associators(usr.path, AssocClass='TestAssoc_MemberOfGroup'):
                if int(grp['GroupID']) == pwd.getpwuid(int(usr['UserID']))[3]:
                    continue
                self._dbgPrint('Found supplemental group %s for user %s, validating...' % (grp['GroupName'], usr['UserName']))
                refname = pywbem.CIMInstanceName('TestAssoc_MemberOfGroup',
                        namespace='root/cimv2',
                        keybindings={
                            'Dependent':usr.path,
                            'Antecedent':grp.path})
                ref = self._conn.GetInstance(refname, LocalOnly=False)
                if not ref:
                    self.fail('Failed to retrieve reference instance from known associator object paths.')
                if ref['isPrimaryGroup']:
                    self.fail('%s "%s" %s "%s" %s' % ('Reference does not indicate non-primary group for user',
                            usr['UserName'],
                            'and group',
                            grp['GroupName'],
                            'when it should.'))
                self._dbgPrint('Successfully validated user/group relationship.')
        
    def test_o_group_nonprimarygroup_references_traversal(self):
        """
        This test is like test_n_user_nonprimarygroup_references_traversal but
        it begins with group objects instead of user objects.
        """
        self._dbgPrint('Validating Group->Supplemental Group->Group references traversal.')
        for grp in self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False):
            self._dbgPrint('Fetching user references for group %s' % grp['GroupName'])
            for ref in self._conn.References(grp.path, ResultClass='TestAssoc_MemberOfGroup'):
                if not ref['isPrimaryGroup']:
                    grpFound = False
                    self._dbgPrint('Found supplemental user object path %s, checking groups...' % ref['Dependent'])
                    for ref2 in self._conn.References(ref['Dependent'], ResultClass='TestAssoc_MemberOfGroup'):
                        if not ref2['isPrimaryGroup'] and grp.path == ref2['Antecedent']:
                            grpFound = True
                            break
                    if not grpFound:
                        usr = self._conn.GetInstance(ref['Dependent'], LocalOnly=False)
                        self.fail('%s "%s" for discovered group member "%s".' % ('Could not find non-primary group',
                                grp['GroupName'], usr['UserName']))
                    self._dbgPrint('Retraced supplemental group reference back to original group.')
                    break
        
    def test_o_group_nonprimarygroup_associators_traversal(self):
        """
        This test is like test_o_group_nonprimarygroup_references_traversal but
        calls Associators instead of References, constructing the reference object
        path and validating the instance like in test_n_user_nonprimarygroup_associators_traversal.
        """
        self._dbgPrint('Validating Group->Supplemental Group->Group associators traversal.')
        for grp in self._conn.EnumerateInstances('TestAssoc_Group', LocalOnly=False):
            self._dbgPrint('Fetching associated users for group %s' % grp['GroupName'])
            for usr in self._conn.Associators(grp.path, AssocClass='TestAssoc_MemberOfGroup'):
                if int(grp['GroupID']) != pwd.getpwuid(int(usr['UserID']))[3]:
                    self._dbgPrint('%s %s for group %s, validating...' % ('Found candidate supplemental user',
                            usr['UserName'], grp['GroupName']))
                    refname = pywbem.CIMInstanceName('TestAssoc_MemberOfGroup',
                            namespace='root/cimv2',
                            keybindings={
                                'Dependent':usr.path,
                                'Antecedent':grp.path})
                    ref = self._conn.GetInstance(refname, LocalOnly=False)
                    if not ref:
                        self.fail('Failed to get reference instance for group "%s" and user "%s".' % (grp['GroupName'], usr['UserName']))
                    if ref['isPrimaryGroup']:
                        self.fail('%s "%s" %s "%s" %s' % ('Reference for group',
                                grp['GroupName'],
                                'and user',
                                usr['UserName'],
                                'designated primary when it should not be.'))
                    self._dbgPrint('Successfully validated user/group relationship.')
        
    def test_p_user_references_associators_match(self):
        """
        This test fetches all references and associators for every TestAssoc_User
        object, then makes sure each reference antecedent has an associated
        entry in the list of associators.
        Then, for each group in the list of associators, the reverse of the same
        test is performed.
        """
        self._dbgPrint('Validating user references and associators.')
        for uop in self._conn.EnumerateInstanceNames('TestAssoc_User'):
            urefs = self._conn.References(uop, ResultClass='TestAssoc_MemberOfGroup')
            uassocs = self._conn.Associators(uop, AssocClass='TestAssoc_MemberOfGroup')
            self._dbgPrint('Matching references and associators for user object path %s...' % uop)
            for grp in uassocs:
                grpFound = False
                for i in xrange(len(urefs)):
                    if isObjPathMatch(urefs[i]['Antecedent'], grp.path):
                        urefs.pop(i)
                        grpFound = True
                        break
                if not grpFound:
                    self.fail('Could not find group "%s" in references.' % grp.path)
            if 0 < len(urefs):
                self.fail('Unmatched reference object found.')
            self._dbgPrint('All references accounted for.')
            for grp in uassocs:
                grefs = self._conn.References(grp.path, ResultClass='TestAssoc_MemberOfGroup')
                gassocs = self._conn.AssociatorNames(grp.path, AssocClass='TestAssoc_MemberOfGroup')
                self._dbgPrint('Matching references and associators for group %s...' % grp['GroupName'])
                for uop2 in gassocs:
                    usrFound = False
                    for i in xrange(len(grefs)):
                        if isObjPathMatch(grefs[i]['Dependent'], uop2):
                            grefs.pop(i)
                            usrFound = True
                            break
                    if not usrFound:
                        self.fail('Could not find user "%s" in backreferences.' % uop2)
                if 0 < len(grefs):
                    self.fail('Unmatched backreference object found.')
                self._dbgPrint('All references accounted for.')
                    
    def test_p_group_references_associators_match(self):
        """
        This test is like test_p_user_references_associators_match
        except the test begins with TestAssoc_Group objects.
        """
        self._dbgPrint('Validating group references and associators.')
        for gop in self._conn.EnumerateInstanceNames('TestAssoc_Group'):
            grefs = self._conn.References(gop, ResultClass='TestAssoc_MemberOfGroup')
            gassocs = self._conn.Associators(gop, AssocClass='TestAssoc_MemberOfGroup')
            self._dbgPrint('Matching references and associators for group object path %s...' % gop)
            for usr in gassocs:
                usrFound = False
                for i in xrange(len(grefs)):
                    if isObjPathMatch( grefs[i]['Dependent'], usr.path):
                        grefs.pop(i)
                        usrFound = True
                        break
                if not usrFound:
                    self.fail('Could not find user "%s" in references.' % usr.path)
            if 0 < len(grefs):
                self.fail('Unmatched reference object found.')
            self._dbgPrint('All references accounted for.')
            for usr in gassocs:
                urefs = self._conn.References(usr.path, ResultClass='TestAssoc_MemberOfGroup')
                uassocs = self._conn.AssociatorNames(usr.path, AssocClass='TestAssoc_MemberOfGroup')
                self._dbgPrint('Matching referencs and associators for user %s...' % usr['UserName'])
                for gop2 in uassocs:
                    grpFound = False
                    for i in xrange(len(urefs)):
                        if isObjPathMatch( urefs[i]['Antecedent'], gop2):
                            urefs.pop(i)
                            grpFound = True
                            break
                    if not grpFound:
                        self.fail('Could not find group "%s" in backreferences.' % gop2)
                if 0 < len(urefs):
                    self.fail('Unmatched backreference object found.')
                self._dbgPrint('All references accounted for.')
        
    def test_q_references_propertylist(self):
        """
        This test calls References from user and group objects
        in a number of ways.  In each case a PropertyList is provided.
        Each result from References is checked to make sure that only
        the properties requested are provided.
        """
        self._dbgPrint('Validating references with PropertyList specifications.')
        for uop in self._conn.EnumerateInstanceNames('TestAssoc_User'):
            self._dbgPrint('First validation reference properties for reference to user %s...' % uop)
            for ref in self._conn.References(uop, ResultClass='TestAssoc_MemberOfGroup', PropertyList=['Dependent']):
                try:
                    if ref['Dependent'] is None:
                        self.fail('Reference dependent not set when it should be.')
                    if not isObjPathMatch(ref['Dependent'], uop):
                        self.fail('Reference dependent set to "%s" when it should be "%s"' % (ref['Dependent'], uop))
                except KeyError:
                    self.fail('KeyError caught trying to read "Dependent" property that should exist.')
                isValid=False
                try:
                    if ref['Antecedent'] is not None and len(ref['Antecedent']) > 0:
                        self.fail('Reference antecedent is set when it should not be (%s).' % ref['Antecedent'])
                    if ref['isPrimaryGroup'] is not None:
                        self.fail('Reference property "isPrimaryGroup" is set when it should not be (%s).' % ref['isPrimaryGroup'])
                    isValid=True
                except KeyError:
                    # not an error
                    isValid=True
                if not isValid:
                    self.fail('Values found for properties not in property list.')
            self._dbgPrint('All reference properties successfully validated.')
            # Figure out the object path of this user's primary group.
            pgop = None
            for ref in self._conn.References(uop, ResultClass='TestAssoc_MemberOfGroup'):
                if ref['isPrimaryGroup']:
                    pgop = ref['Antecedent']
                    break
            # Rescan references with propertylist=Antecedent, isPrimaryGroup.  Check that isPrimaryGroup is correct.
            self._dbgPrint('Second validation reference properties for reference to user %s...' % uop)
            for ref in self._conn.References(uop, ResultClass='TestAssoc_MemberOfGroup',
                    PropertyList=['Antecedent','isPrimaryGroup']):
                try:
                    if ref['Antecedent'] is None:
                        self.fail('Reference antecedent not set when it should be.')
                    if ref['isPrimaryGroup'] is None:
                        self.fail('Reference property "isPrimaryGroup" not set when it should be.')
                    if isObjPathMatch(ref['Antecedent'], pgop) and \
                            not ref['isPrimaryGroup']:
                        self.fail('Reference not designated as primary when it should be.')
                    elif not isObjPathMatch(ref['Antecedent'], pgop) and \
                            ref['isPrimaryGroup']:
                        self.fail('Reference designated as primary when it should not be.')
                except KeyError:
                    self.fail('KeyError caught trying to read properties that should exist.')
                isValid=False
                try:
                    if ref['Dependent'] is not None and len(ref['Dependent']) > 0:
                        self.fail('Reference dependent is set when it should not be (%s).' % ref['Dependent'])
                    isValid=True
                except KeyError:
                    # not an error
                    isValid=True
                if not isValid:
                    self.fail('Values found for properties not in property list.')
            self._dbgPrint('All reference properties successfully validated.')
        for gop in self._conn.EnumerateInstanceNames('TestAssoc_Group'):
            self._dbgPrint('First validation reference properties for reference to group %s...' % gop)
            for ref in self._conn.References(gop, ResultClass='TestAssoc_MemberOfGroup',
                    PropertyList=['Antecedent']):
                try:
                    if ref['Antecedent'] is None:
                        self.fail('Reference antecedent not set when it should be.')
                except KeyERror:
                    self.fail('KeyError caught trying to read antecedent property that should exist.')
                isValid=False
                try:
                    if ref['Dependent'] is not None and len(ref['Dependent']) > 0:
                        self.fail('Reference dependent is set when it should not be (%s).' % ref['Dependent'])
                    isValid=True
                except KeyError:
                    # not an error
                    isValid=True
                if not isValid:
                    self.fail('Values found for properties not in property list.')
            uopmembers = []
            for ref in self._conn.References(gop, ResultClass='TestAssoc_MemberOfGroup'):
                if ref['isPrimaryGroup']:
                    uopmembers.append(ref['Dependent'])
            if 0 < len(uopmembers):
                for ref in self._conn.References(gop, ResultClass='TestAssoc_MemberOfGroup',
                        PropertyList=['Dependent','isPrimaryGroup']):
                    self._dbgPrint('Second validation reference properties for reference to group %s...' % gop)
                    try:
                        if ref['Dependent'] is None:
                            self.fail('Reference dependent not set when it should be.')
                        if ref['isPrimaryGroup'] is None:
                            self.fail('Reference property "isPrimaryGroup" not set when it should be.')
                        if ref['Dependent'] in uopmembers:
                            if not ref['isPrimaryGroup']:
                                self.fail('Reference not designated as primary when it should be.')
                        elif ref['isPrimaryGroup']:
                            self.fail('Reference designated as primary when it should not be.')
                    except KeyError:
                        self.fail('KeyError caught trying to read properties that should exist.')
                    isValid=False
                    try:
                        if ref['Antecedent'] is not None and len(ref['Antecedent']) > 0:
                            self.fail('Reference antecedent is set when it should not be (%s).' % ref['Antecedent'])
                        isValid=True
                    except KeyError:
                        # not an error
                        isValid=True
                    if not isValid:
                        self.fail('Values found for properties not in property list.')
            self._dbgPrint('All reference properties successfully validated.')
        
    def test_r_associators_propertylist(self):
        """
        This test calls Associators from user and group objects in a variety of
        ways, passing a PropertyList into the call each time.  Resulting objects
        are checked to make sure that the property list is honored.
        """
        self._dbgPrint('Validating associators with property list provided.')
        for uop in self._conn.EnumerateInstanceNames('TestAssoc_User'):
            self._dbgPrint('Validating associators properties for user %s...' % uop)
            for grp in self._conn.Associators(uop, AssocClass='TestAssoc_MemberOfGroup',
                    PropertyList=['GroupID']):
                try:
                    if grp['GroupID'] is None:
                        self.fail('GroupID property not set when it should be.')
                except KeyError:
                    self.fail('KeyError caught trying to access property that should exist.')
                isValid=False
                try:
                    if grp['GroupName'] is not None and 0 < len(grp['GroupName']):
                        self.fail('GroupName property set when it should not be.')
                    isValid=True
                except KeyError:
                    # not an error
                    isValid=True
                if not isValid:
                    self.fail('Found properties set that should not be.')
            self._dbgPrint('All associator properties successfully validated.')
        for gop in self._conn.EnumerateInstanceNames('TestAssoc_Group'):
            self._dbgPrint('Validating associators properites for group %s...' % gop)
            for usr in self._conn.Associators(gop, AssocClass='TestAssoc_MemberOfGroup',
                    PropertyList=['UserName','LoginShell']):
                try:
                    if usr['UserName'] is None:
                        self.fail('UserName property not set when it should be.')
                    if usr['LoginShell'] is None:
                        self.fail('LoginShell property not set when it should be.')
                except KeyError:
                    self.fail('KeyError caught trying to access properties that should exist.')
                isValid=False
                try:
                    # some CIMOMs always return keys .
                    #if usr['UserID'] is not None:
                    #    self.fail('UserID property set when it should not be.')
                    if usr['HomeDirectory'] is not None:
                        self.fail('HomeDirectory property set when it should not be.')
                    isValid=True
                except KeyError:
                    # not an error
                    isValid=True
                if not isValid:
                    self.fail('Found properties set that should not be.')
            self._dbgPrint('All associator properties successfully validated.')
        

if __name__ == '__main__':
    parser = optparse.OptionParser()
    wbem_connection.getWBEMConnParserOptions(parser)
    parser.add_option('--level',
            '-l',
            action='store',
            type='int',
            dest='dbglevel',
            help='Indicate the level of debugging statements to display (default=2)',
            default=2)
    parser.add_option('--verbose', '', action='store_true', default=False,
            help='Show verbose output')
    options, arguments = parser.parse_args()
    
    _globalVerbose = options.verbose

    conn = wbem_connection.WBEMConnFromOptions(parser)
    suite = unittest.makeSuite(TestAssociations)
    unittest.TextTestRunner(verbosity=options.dbglevel).run(suite)
