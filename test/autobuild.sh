#!/bin/sh

ABSPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
THISDIR=$(dirname $ABSPATH)
export CPANM=$THISDIR/cpanm
export PERL=$(which perl)

cd $1

$PERL $CPANM -lextlib \
    Module::Install \
    Module::Install::AuthorTests \
    Module::Install::CheckLib \
    Module::Install::XSUtil \
    AnyEvent

$PERL Makefile.PL -g
$PERL $CPANM -lextlib --installdeps -lextlib .

make test

