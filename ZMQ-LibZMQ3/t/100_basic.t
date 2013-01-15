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

subtest 'connect before server socket is bound (should fail)' => sub {
    my $cxt = zmq_init;
    my $sock = zmq_socket($cxt, ZMQ_PAIR); # Receiver

    # too early, server socket not created:
    my $client = zmq_socket($cxt, ZMQ_PAIR);
    my $status = zmq_connect($client, "inproc://myPrivateSocket");
    if (is $status, -1, "Error connecting to invalid socket") {
        like $!, qr/Connection refused/, "Error is Connection refused";
    }
};

subtest 'basic inproc communication' => sub {
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

    ok(!defined(zmq_recvmsg($sock, ZMQ_DONTWAIT())), "recv before sending anything should return nothing");

    my $bytes = zmq_sendmsg($client, zmq_msg_init_data("Talk to me"));
    if (! is $bytes, length("Talk to me"), "zmq_sendmsg is successful") {
        diag "zmq_sendmsg failed with $!";
    }

    # These tests are potentially dangerous when upgrades happen....
    # I thought of plain removing, but I'll leave it for now
    my ($major, $minor, $micro) = ZMQ::LibZMQ3::zmq_version();
    SKIP: {
        skip( "Need to be exactly zeromq 2.1.0", 3 )
            if ($major != 2 || $minor != 1 || $micro != 0);
        ok(!zmq_getsockopt($sock, ZMQ_RCVMORE), "no ZMQ_RCVMORE set");
        ok(zmq_getsockopt($sock, ZMQ_AFFINITY) == 0, "no ZMQ_AFFINITY");
        ok(zmq_getsockopt($sock, ZMQ_RATE) == 100, "ZMQ_RATE is at default 100");
    }

    my $msg = zmq_recvmsg($sock);
    ok(defined $msg, "received defined msg");
    is(zmq_msg_data($msg), "Talk to me", "received correct message");

    # now test with objects, just for kicks.

    my $obj = {
        foo => 'bar',
        baz => [1..9],
        blah => 'blubb',
    };
    my $frozen = nfreeze($obj);
    $bytes = zmq_sendmsg($client, zmq_msg_init_data($frozen));
    if (! is $bytes, length($frozen), "zmq_sendmsg is successful") {
        diag "zmq_sendmsg failed with $!";
    }
    $msg = zmq_recvmsg($sock);
    ok(defined $msg, "received defined msg");
    isa_ok($msg, 'ZMQ::LibZMQ3::Message');
    is(zmq_msg_data($msg), $frozen, "got back same data");
    my $robj = thaw(zmq_msg_data($msg));
    is_deeply($robj, $obj);

    if (ZMQ::LibZMQ3::HAS_ZMQ_MSG_SEND) {
        # test zmq_msg_send
        my $zmq_msg_send_bytes = zmq_msg_send(zmq_msg_init_data("Talk to me"), $client,);
        if (! is $zmq_msg_send_bytes, length("Talk to me"), "zmq_msg_send is successful") {
            diag "zmq_msg_send failed with $!";
        }
    }

};


subtest 'invalid bind' => sub {
    my $cxt = zmq_init(0); # must be 0 theads for in-process bind
    my $sock = zmq_socket($cxt, ZMQ_REP); # server like reply socket
    my $status = zmq_bind($sock, "bulls***");
    if (is $status, -1, "zmq_bind should fail") {
        like $!, qr/Invalid argument/, "Error is as expected";
    }
};

done_testing;
