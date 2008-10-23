#!/bin/sh


python test_assoc.py $@ &
python test_assoc.py $@ &

python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python UpcallAtomTest.py $@ &
python TestIndications.py $@ &

python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python UpcallAtomTest.py $@ &
python TestIndications.py $@ &

python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python UpcallAtomTest.py $@ &
python TestIndications.py $@ &

#sleep 15

#python test_assoc.py $@ &

python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python TestAtomProvider_Test.py $@ &
python TestMethod_Test.py $@ &
python UpcallAtomTest.py $@ &
python TestIndications.py $@ &

