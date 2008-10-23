#!/bin/sh
python TestAtomProvider_Test.py $@
python TestIndications.py $@
python UpcallAtomTest.py $@
python test_assoc.py $@
python TestMethod_Test.py $@
