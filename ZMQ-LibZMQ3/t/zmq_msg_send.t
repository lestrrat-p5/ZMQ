use strict;
use warnings;
use POSIX ();
BEGIN {
    POSIX::setlocale(&POSIX::LC_MESSAGES, "en_GB.UTF-8");
}

use Test::More;
use ZMQ::LibZMQ3;
use ZMQ::Constants ':v3.1.1', ':all';
use Storable qw/nfreeze thaw/;

subtest 'zmq_msg_send_broken' => sub {
    my $cxt = zmq_init;
    my $sock = zmq_socket($cxt, ZMQ_PAIR); # Receiver
    my $status = zmq_bind($sock, "inproc://myPrivateSocket");
    if (! is $status, 0, "bind to inproc socket") {
        diag "zmq_bind failed with $!";
    }

    my $client = zmq_socket($cxt, ZMQ_PAIR); # sender
    $status = zmq_connect($client, "inproc://myPrivateSocket");
    if (! is $status, 0, "connect to inproc socket" ) {
        diag "zmq_connect failed with $!";
    }

    my $bytes = zmq_sendmsg($client, zmq_msg_init_data("Talk to me"));
    if (! is $bytes, length("Talk to me"), "zmq_sendmsg is successful") {
        diag "zmq_sendmsg failed with $!";
    }

    my $bytes = zmq_msg_send($client, zmq_msg_init_data("Talk to me"));
    if (! is $bytes, length("Talk to me"), "zmq_sendmsg is successful") {
        diag "zmq_sendmsg failed with $!";
    }


};

done_testing;
