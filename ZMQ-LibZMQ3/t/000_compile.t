use strict;
use Test::More;
use_ok "ZMQ::LibZMQ3";

my ($major, $minor, $patch) = ZMQ::LibZMQ3::zmq_version();
my $version = join('.', $major, $minor, $patch);

diag sprintf( 
    "\n   This is ZMQ::LibZMQ3.pm version %s\n   Linked against zmq %s",
    $ZMQ::LibZMQ3::VERSION,
    $version, 
);



done_testing;
