#!/bin/sh
cp ./build/swig/python/cmpi.py ./swig/python/cim_provider.py ./swig/python/cmpi_bindings.py /usr/lib64/python2.5/site-packages
cp ./mof/Py_UnixProcess.reg /var/lib/sfcb/stage/regs
cp ./mof/Py_UnixProcess.mof /var/lib/sfcb/stage/mofs/root/cimv2
cp ./build/swig/python/libpyCmpiProvider.so /usr/lib64/
cp ./swig/python/Py_UnixProcessProvider.py /usr/lib/pycim
sfcbrepos -f
