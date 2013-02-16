#!/usr/bin/env python

""" Test script to validate the correctness of
association handling in a CIM provider interface.

Exercises the classes defined in TestAssoc.mof
and the corresponding provider in TestAssocProvider.py.
"""

import unittest
import optparse
import pywbem

from lib import wbem_connection
conn = None
   
class TestNullArray(unittest.TestCase):

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

    def test_null_array(self):
        """
            Run EnumInstances on the test class and check, that
            1) all instances are returned.
            2) no error is returned.

            The main purpose of this test is to check that NULL arrays can
            be returned from Pegasus CIMOM. It used to return
            CIMError: (1, '61') instead.
        """
        self._dbgPrint('Reading Test_NullArray instances.')
        instances = self._conn.EnumerateInstances('Test_NullArray')
        self.assertEquals(len(instances), 3)
        self._dbgPrint('Instances are OK.')

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
    suite = unittest.makeSuite(TestNullArray)
    unittest.TextTestRunner(verbosity=options.dbglevel).run(suite)
