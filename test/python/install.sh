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

##
## Check usage
##

if [ "$#" != 1 ]; then
    echo "Usage: $0 [op|sfcb]"
    exit 1
fi

if [ "$1" != "op" -a "$1" != "sfcb" ]; then
    echo "Usage: $0 [op|sfcb]"
    exit 1
fi

##
## Install python providers:
##

__install TestMethod.py /usr/lib/pycim
__install TestAssocProvider.py /usr/lib/pycim
__install TestAtomProvider.py /usr/lib/pycim
__install UpcallAtomProvider.py /usr/lib/pycim
__install TestExcept.py /usr/lib/pycim

if [ "$1" = "op" ]; then
    cimmof TestMethodPegasus.mof
    cimmof -n root/PG_InterOp TestMethod.peg.reg
    cimmof TestAssoc.mof
    cimmof -n root/PG_InterOp TestAssocProvider.peg.reg
    cimmof TestAtom.mof
    cimmof -n root/PG_InterOp TestAtomProvider.peg.reg
    cimmof UpcallAtom.mof
    cimmof -n root/PG_Interop UpcallAtom.peg.reg
    cimmof TestExcept.mof
    cimmof -n root/PG_InterOp TestExcept.peg.reg

else
    __install TestMethod.mof /var/lib/sfcb/stage/mofs/root/cimv2
    __install TestAssoc.mof /var/lib/sfcb/stage/mofs/root/cimv2
    __install TestAtom.mof /var/lib/sfcb/stage/mofs/root/cimv2
    __install UpcallAtom.mof /var/lib/sfcb/stage/mofs/root/cimv2
    __install TestExcept.mof /var/lib/sfcb/stage/mofs/root/cimv2

    __install TestAssocProvider.sfcb.reg /var/lib/sfcb/stage/regs
    __install TestMethod.sfcb.reg /var/lib/sfcb/stage/regs
    __install TestAtomProvider.sfcb.reg /var/lib/sfcb/stage/regs
    __install UpcallAtom.sfcb.reg /var/lib/sfcb/stage/regs
    __install TestExcept.sfcb.reg /var/lib/sfcb/stage/regs
    sfcbrepos -f
fi
