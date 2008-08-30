#!/bin/sh

function __install {

    fn=$1
    dir=$2

    if [ ! -f "$fn" ]; then
        echo "no such file: $fn"
        exit 1
    fi

    if [ ! -d "$dir" ]; then
        echo "no such directory: $dir"
        exit 1
    fi

    echo "rm -f $dir/$fn"
    rm -f $dir/$fn
    echo "ln -s `pwd`/$fn $dir"
    ln -s `pwd`/$fn $dir
}

__install TestMethod.mof /var/lib/sfcb/stage/mofs/root/cimv2
__install TestAssoc.mof /var/lib/sfcb/stage/mofs/root/cimv2
__install TestAtom.mof /var/lib/sfcb/stage/mofs/root/cimv2

__install TestMethod.py /usr/lib/pycim
__install TestAssocProvider.py /usr/lib/pycim
__install TestAtomProvider.py /usr/lib/pycim

__install TestAssocProvider.sfcb.reg /var/lib/sfcb/stage/regs
__install TestMethod.sfcb.reg /var/lib/sfcb/stage/regs
__install TestAtomProvider.sfcb.reg /var/lib/sfcb/stage/regs

sfcbrepos -f
