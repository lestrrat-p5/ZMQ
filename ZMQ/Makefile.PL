use strict;
use inc::Module::Install;

name 'ZMQ';
all_from 'lib/ZMQ.pm';

if ($ENV{PERL_ZMQ_BACKEND}) {
    print <<EOM;
+ Detected PERL_ZMQ_BACKEND '$ENV{PERL_ZMQ_BACKEND}'

EOM
} else {
print <<EOM;

+ ZMQ.pm will by default use ZMQ::LibZMQ2, but you can tell it to use
  ZMQ::LibZMQ3 by setting PERL_ZMQ_BACKEND environment variable.
+ Using default ZMQ::LibZMQ2 backend

EOM
    $ENV{PERL_ZMQ_BACKEND} = 'ZMQ::LibZMQ2';
}

repository "git://github.com/lestrrat/p5-ZMQ.git";
homepage "https://github.com/lestrrat/p5-ZMQ";
bugtracker "https://github.com/lestrrat/p5-ZMQ/issues";

requires $ENV{PERL_ZMQ_BACKEND};
requires 'ZMQ::Constants';
requires 'Sub::Name';

WriteAll;