BEGIN {
     require Config;
     if (!$Config::Config{useithreads}) {
        print "1..0 # Skip: no ithreads\n";
        exit 0;
     }
}

use strict;
use warnings;
use threads;
use Test::More;
use Test::Fatal;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw/:v3.1.1 :all/;

{
    my $cxt = zmq_init(1);
    isa_ok($cxt, 'ZMQ::LibZMQ3::Context');

    my $main_socket = zmq_socket($cxt, ZMQ_PUSH);
    isa_ok($main_socket, "ZMQ::LibZMQ3::Socket");
    zmq_close($main_socket);

    my $t = threads->new(sub {
        note "created thread " . threads->tid;
        my $sock = zmq_socket($cxt,  ZMQ_PAIR );
        ok $sock, "created server socket";
        is exception {
            zmq_bind($sock, "inproc://myPrivateSocket");
        }, undef, "bound server socket";
    
        my $client = zmq_socket($cxt, ZMQ_PAIR); # sender
        ok $client, "created client socket";
        is exception {
            zmq_connect($client, "inproc://myPrivateSocket");
        }, undef, "connected client socket";

        zmq_send( $client, "Wee Woo" );
        my $data = zmq_recv($sock);
        my $ok = 0;
        if (ok $data) {
            $ok = is zmq_msg_data($data), "Wee Woo", "got same message";
        }
        return $ok;
    });

    note "Now waiting for thread to join";
    my $ok = $t->join();

    note "Thread joined";
    ok($ok, "socket and context not defined in subthread");
}

{
    my $msg = zmq_msg_init_data( "Wee Woo" );
    my $t = threads->create( sub {
        my $msg = shift;
        return zmq_msg_data($msg) eq "Wee Woo" &&
            zmq_msg_size($msg) == 7;
    }, $msg);

    my $ok = $t->join();
    ok $ok, "message duped correctly";
};

done_testing;

