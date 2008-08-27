#!/bin/bash
#wbemgi "http://"`wbemein http://localhost:5988/root/cimv2:Py_UnixProcess| head -1`
wbemgi http://localhost:5988/root/cimv2:Py_UnixProcess.Handle=1
