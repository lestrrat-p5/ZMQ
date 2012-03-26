#!/bin/sh

ABSPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
THISDIR=$(dirname $ABSPATH)
export CPANM=$THISDIR/cpanm
export PERL=$(which perl)

cd $1

export PERL5OPT=-Mlib=extlib/lib/perl5

$PERL $CPANM -lextlib \
    Module::Install \
    Module::Install::AuthorTests \
    Module::Install::CheckLib \
    Module::Install::Repository \
    Module::Install::XSUtil \
    AnyEvent

$PERL Makefile.PL -g
# XXX Currently we don't have ZMQ::Constants up on CPAN, so 
# install it locally
$PERL $CPANM -lextlib ../ZMQ-Constants 
$PERL $CPANM -lextlib --installdeps -lextlib .

make test

