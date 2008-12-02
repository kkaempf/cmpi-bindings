#!/usr/bin/env python

import pywbem
from subprocess import call, Popen, PIPE
from time import sleep
import sys

conn = pywbem.SFCBUDSConnection()
conn.default_namespace = 'root/interop'

cnt = 0
while True:
    call('/etc/init.d/sfcb start', shell=True)
    for i in xrange(0,20):
        sleep(1)
        try:
            cnames = conn.EnumerateClassNames()
            break;
        except:
            exc_class, exc, tb = sys.exc_info()
        sys.stdout.write('.'); sys.stdout.flush()
        sleep(1)
    else:
        raise exc_class, exc, tb 
    print '\nfetched %s classes' % len(cnames)
    print cnt
    cnt+= 1
    call('/etc/init.d/sfcb stop', shell=True)
    for i in xrange(0,20):
        po = Popen('ps ax | grep sfcbd | grep -v grep', shell=True, stdout=PIPE)
        procs = po.stdout.read()
        if po.wait() != 0:
            break
        sys.stdout.write('.'); sys.stdout.flush()
        sleep(1)
    else:
        print '\nError: not all sfcbd processes stopped'
        print procs
        sys.exit(1)



