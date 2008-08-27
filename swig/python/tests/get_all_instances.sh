#!/bin/bash
for i in `wbemein http://localhost:5988/root/cimv2:Py_UnixProcess`; do
 uri="http://"$i
echo  `wbemgi $uri`
 done