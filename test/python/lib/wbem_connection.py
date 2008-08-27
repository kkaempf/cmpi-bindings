#!/usr/bin/env python
import pywbem 
from optparse import OptionParser
from getpass import getpass

def getWBEMConnParserOptions(parser):
    parser.add_option('-u', '--url', default='https://localhost', help='Specify the URL to the CIMOM')
    parser.add_option('-n', '--namespace', default='root/cimv2', help='Specify the namespace the test runs against')
    parser.add_option('', '--user', default='', help='Specify the user name used when connection to the CIMOM')
    parser.add_option('', '--password', default='', help='Specify the password for the user')



def WBEMConnFromOptions(parser=None):
    if parser==None:
        parser = OptionParser()
        getWBEMConnParserOptions(parser)
    options, args = parser.parse_args()
    pw = options.password
    if options.user and not pw:
        pw = getpass('\nEnter password for %s: ' % options.user)
    wconn = pywbem.WBEMConnection(options.url, (options.user, pw))
    if options.namespace:
        wconn.default_namespace = options.namespace
    return wconn




