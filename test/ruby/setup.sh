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
## Install Ruby providers:
##

__install test_method_provider.rb /usr/lib/rbcim
__install Test_Atom.rb /usr/lib/rbcim
__install test_association_provider.rb /usr/lib/rbcim
__install test_instance_provider.rb /usr/lib/rbcim

if [ "$1" = "op" ]; then
    cimmof ../python/TestMethod.mof
    cimmof -n root/PG_InterOp TestMethod.peg.reg
    cimmof ../python/TestAssoc.mof
    cimmof -n root/PG_InterOp TestAssocProvider.peg.reg
    cimmof ../python/TestAtom.mof
    cimmof -n root/PG_InterOp TestAtomProvider.peg.reg
else
    __install ../python/TestMethod.mof /var/lib/sfcb/stage/mofs/root/cimv2
    __install ../python/TestAssoc.mof /var/lib/sfcb/stage/mofs/root/cimv2
    __install ../python/TestAtom.mof /var/lib/sfcb/stage/mofs/root/cimv2

    __install TestAssocProvider.sfcb.reg /var/lib/sfcb/stage/regs
    __install TestMethod.sfcb.reg /var/lib/sfcb/stage/regs
    __install TestAtomProvider.sfcb.reg /var/lib/sfcb/stage/regs
    sfcbrepos -f
fi
