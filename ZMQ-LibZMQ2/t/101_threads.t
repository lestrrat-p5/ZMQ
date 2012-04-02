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
use ZMQ::LibZMQ2;
use ZMQ::Constants qw/:all/;

note 'sanity'; {
    my $cxt = zmq_init(1);
    isa_ok($cxt, 'ZMQ::LibZMQ2::Context');

    my $main_socket = zmq_socket($cxt, ZMQ_PUSH);
    isa_ok($main_socket, "ZMQ::LibZMQ2::Socket");
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
        if (ok $data, "got data") {
            $ok = is zmq_msg_data($data), "Wee Woo", "got same message";
        }
        return $ok;
    });

    note "Now waiting for thread to join";
    my $ok = $t->join();

    note "Thread joined";
    ok($ok, "socket and context not defined in subthread");
};

note 'invalidate socket between threads'; {
    my $cxt = zmq_init();
    my $sock = zmq_socket( $cxt, ZMQ_PUSH );
    my $msg = zmq_msg_init_data( "Wee Woo" );
    my $t   = threads->create( sub {
        my ($t_cxt, $t_sock, $t_msg) = @_;
        ok $t_cxt;
        is $$t_sock, undef;
        return zmq_msg_data($t_msg) eq "Wee Woo" &&
            zmq_msg_size($t_msg) == 7;
    }, $cxt, $sock, $msg );
    my $ok = $t->join();
    ok $ok, "cxt and message is available, but socket is under in a different thread";
};

done_testing;

