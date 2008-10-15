#!/usr/bin/python
#
# Simple indication receiver using Twisted Python.  HTTP post requests
# are listened for on port 5988 and port 5899 using SSL.
#
# Requires Twisted Python and 
#

import sys
from twisted.internet import reactor
from twisted.web import server, resource
import pywbem
import threading
import os

from twisted.internet import ssl, reactor
from twisted.python import log

from time import sleep

class CIMListener(resource.Resource):
    """ CIM Listener
    """

    isLeaf = 1

    class ServerContextFactory(object):
        def __init__(self, cert, key):
            self.cert = cert
            self.key = key

        def getContext(self):
            """Create an SSL context with a dodgy certificate."""

            from OpenSSL import SSL
            ctx = SSL.Context(SSL.SSLv23_METHOD)
            ctx.use_certificate_file(self.cert)
            ctx.use_privatekey_file(self.key)
            return ctx

    def __init__(self, callback, 
            http_port=5988, https_port=5989,
            ssl_key=None, ssl_cert=None):
        self.callback = callback
        self.http_port = http_port
        self.https_port = https_port
        self.ssl_key = ssl_key
        self.ssl_cert = ssl_cert

        site = server.Site(self)

        if self.http_port and self.http_port > 0:
            reactor.listenTCP(self.http_port, site)
        if self.https_port and self.https_port > 0:
            reactor.listenSSL(self.https_port, site, 
                    self.ServerContextFactory(cert=ssl_cert, key=ssl_key))

    def start(self):
        ''' doesn't work'''
        thread = threading.Thread(target=reactor.run)
        thread.start()

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


#log.startLogging(sys.stdout)

        
rcv_count=0

if __name__ == '__main__':
    global rcv_count
    rcv_count = 0
    
    killval = sys.argv[1]
    filename = sys.argv[2]
    print
    print "killval=",killval

    cl=None

    def update_file():
        global rcv_count
        fd = open(filename, 'w')
        fd.write('%s'%rcv_count)
        fd.close
    
    def cb(inst):
        global rcv_count
        rcv_count+=1
        update_file()
        print inst['IndicationTime'], inst['Description']
        if inst['Description']==killval:
            cl.stop()
    
    update_file()    
    cl = CIMListener(cb, https_port=None)
    cl.run()
