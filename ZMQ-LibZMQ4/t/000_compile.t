use strict;
use Test::More;
use_ok "ZMQ::LibZMQ4";

my ($major, $minor, $patch) = ZMQ::LibZMQ4::zmq_version();
my $version = join('.', $major, $minor, $patch);

diag sprintf( 
    "\n   This is ZMQ::LibZMQ4.pm version %s\n   Linked against zmq %s",
    $ZMQ::LibZMQ4::VERSION,
    $version, 
);



done_testing;
