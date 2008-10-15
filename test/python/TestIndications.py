#!/usr/bin/python
#
# Simple indication receiver using Twisted Python.  HTTP post requests
# are listened for on port 5988 and port 5899 using SSL.
#
# Requires Twisted Python and 
#

import sys
import optparse
from twisted.internet import reactor, ssl
from twisted.web import server, resource
import pywbem
import threading
from socket import getfqdn

from twisted.python import log

import time 
from lib import wbem_connection

_port = 5309
_lock = threading.RLock()

class CIMListener(resource.Resource):
    """ CIM Listener
    """

    isLeaf = 1


    def __init__(self, callback, http_port=5988): 
        self.callback = callback
        self.http_port = http_port

        site = server.Site(self)

        reactor.listenTCP(self.http_port, site)

    def stop(self):
        reactor.stop()

    def run(self):
        reactor.run()
        
    def render_POST(self, request):
        tt = pywbem.parse_cim(pywbem.xml_to_tupletree(request.content.read()))
        insts = [x[1] for x in tt[2][2][0][2][2]]
        for inst in insts:
            self.callback(inst)
        return ''

def createFilter( ch, query='select * from CIM_ProcessIndication',
                  ns='root/interop',
                  querylang='WQL',
                  src_ns='root/cimv2',
                  in_name=None):
    name = in_name or 'cimfilter%s'%time.time()
    filterinst=pywbem.CIMInstance('CIM_IndicationFilter')
    filterinst['CreationClassName']='CIM_IndicationFilter'
    filterinst['SystemCreationClassName']='CIM_ComputerSystem'
    filterinst['SystemName']=getfqdn()
    filterinst['Name']=name
    filterinst['Query']=query
    filterinst['QueryLanguage']=querylang
    filterinst['SourceNamespace']=src_ns
    cop = pywbem.CIMInstanceName('CIM_IndicationFilter')
    cop.keybindings = { 'CreationClassName':'CIM_IndicationFilter',
                        'SystemClassName':'CIM_ComputerSystem',
                        'SystemName':getfqdn(),
                        'Name':name }
    cop.namespace=ns
    filterinst.path = cop
    filtercop = ch.CreateInstance(filterinst)
    return filtercop

def createDest( ch, destination='http://localhost:%s' % _port,
                ns='root/interop',
                in_name=None):
    name = in_name or 'cimlistener%s'%time.time()
    destinst=pywbem.CIMInstance('CIM_ListenerDestinationCIMXML')
    destinst['CreationClassName']='CIM_ListenerDestinationCIMXML'
    destinst['SystemCreationClassName']='CIM_ComputerSystem'
    destinst['SystemName']=getfqdn()
    destinst['Name']=name
    destinst['Destination']=destination
    cop = pywbem.CIMInstanceName('CIM_ListenerDestinationCIMXML')
    cop.keybindings = { 'CreationClassName':'CIM_ListenerDestinationCIMXML',
                        'SystemClassName':'CIM_ComputerSystem',
                        'SystemName':getfqdn(),
                        'Name':name }
    cop.namespace=ns
    destinst.path = cop
    destcop = ch.CreateInstance(destinst)
    return destcop

def createSubscription(ch, ns='root/interop'):
    replace_ns = ch.default_namespace
    ch.default_namespace=ns
    indfilter=createFilter(ch)
    indhandler=createDest(ch)
    subinst=pywbem.CIMInstance('CIM_IndicationSubscription')
    subinst['Filter']=indfilter
    subinst['Handler']=indhandler
    cop = pywbem.CIMInstanceName('CIM_IndicationSubscription')
    cop.keybindings = { 'Filter':indfilter,
                        'Handler':indhandler }
    cop.namespace=ns
    subinst.path = cop
    subcop = ch.CreateInstance(subinst)
    ch.default_namespace=replace_ns
    return subcop


def deleteSubscription(ch, subcop):
    indfilter = subcop['Filter']
    indhandler= subcop['Handler']
    ch.DeleteInstance(subcop)
    ch.DeleteInstance(indfilter)
    ch.DeleteInstance(indhandler)

# end indication support methods

#log.startLogging(sys.stdout)


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
    conn = wbem_connection.WBEMConnFromOptions(parser)
    
    def cb(inst):
        print inst['IndicationTime'], inst['Description']
    cl = CIMListener(callback=cb, http_port=5309)

    def threadfunc():
        time.sleep(1)
        numrcv = 0
        subcop = createSubscription(conn)
        num_to_send = pywbem.Uint16(7)
        time.sleep(1)
        conn.InvokeMethod('reset_indication_count', 'Test_UpcallAtom')
        countsent,outs = conn.InvokeMethod('send_indications', 
                'Test_UpcallAtom', num_to_send=num_to_send)
        numsent,outs = conn.InvokeMethod('get_indication_send_count', 
                'Test_UpcallAtom')
        deleteSubscription(conn, subcop)
        if (countsent != numsent):
            print("send_indications NumSent(%d) doesn't match get_indication_send_count NumSent(%d)"%(countsent, numsent));
            sys.exit(1)
        time.sleep(4)
        if reactor.running:
            reactor.stop()
        #self.fail("number received(%d) doesn't match number sent(%d)"%(numrcv,numsent));

    thread = threading.Thread(target=threadfunc)
    thread.start()
    reactor.run()

