use strict;
use Test::More;
use_ok "ZMQ::LibCZMQ1";


my $zmq_version = join ".", ZMQ::LibCZMQ1::zmq_version();
my $czmq_version = join ".", ZMQ::LibCZMQ1::czmq_version();

diag sprintf( 
    "\n   This is ZMQ::LibCZMQ1.pm version %s\n   Linked against czmq %s\n   Linked against  zmq %s",
    $ZMQ::LibCZMQ1::VERSION,
    $czmq_version, 
    $zmq_version, 
);

done_testing;
