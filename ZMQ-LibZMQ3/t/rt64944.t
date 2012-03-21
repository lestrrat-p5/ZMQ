# This test file is used in xt/rt64944.t, but is also in t/
# because it checks (1) failure cases in ZMQ_RCVMORE, and
# (2) shows how non-blocking recv() should be handled

use strict;
use Test::More;
use Test::Requires qw( Test::TCP );

BEGIN {
    use_ok "ZMQ::LibZMQ3";
    use_ok "ZMQ::Constants", ":v3.1.1", ":all";
}

subtest 'blocking recv' => sub {
    my $server = Test::TCP->new(code => sub {
        my $port = shift;
        note "START blocking recv server on port $port";
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_PUB);

        zmq_bind($sock, "tcp://127.0.0.1:$port");
        sleep 2;
        for (1..10) {
            zmq_sendmsg($sock, zmq_msg_init_data($_) );
        }
        sleep 2;
        note "END blocking recv server";
        zmq_close($sock);

        exit 0;
    });

    my $port = $server->port;
    my $ctxt = zmq_init();
    my $sock = zmq_socket($ctxt, ZMQ_SUB);

    note "blocking recv client connecting to port $port";
    zmq_connect($sock, "tcp://127.0.0.1:$port" );
    zmq_setsockopt($sock, ZMQ_SUBSCRIBE, '');

    for(1..10) {
        my $msg = zmq_recvmsg($sock);
        is zmq_msg_data($msg), $_;
    }
};

subtest 'non-blocking recv (fail)' => sub {
    my $server = Test::TCP->new(code => sub {
        my $port = shift;
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_PUB);
    
        zmq_bind($sock, "tcp://127.0.0.1:$port");
        sleep 2;
        for (1..10) {
            zmq_sendmsg($sock, zmq_msg_init_data($_));
        }
        sleep 2;
        exit 0;
    } );

    my $port = $server->port;

    note "non-blocking client connecting to port $port";
    my $ctxt = zmq_init();
    my $sock = zmq_socket($ctxt, ZMQ_SUB);

    zmq_connect($sock, "tcp://127.0.0.1:$port" );
    zmq_setsockopt($sock, ZMQ_SUBSCRIBE, '');

    for(1..10) {
        my $msg = zmq_recvmsg($sock, ZMQ_RCVMORE); # most of this call should really fail
    }
    ok(1); # dummy - this is just here to find leakage
};

# Code excericising zmq_poll to do non-blocking recv()
subtest 'non-blocking recv (success)' => sub {
    my $server = Test::TCP->new( code => sub {
        my $port = shift;
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_PUB);

        zmq_bind($sock, "tcp://127.0.0.1:$port");
        sleep 2;
        for (1..10) {
            zmq_sendmsg($sock, zmq_msg_init_data($_));
        }
        sleep 2;
        exit 0;
    } );

    my $port = $server->port;
    my $ctxt = zmq_init();
    my $sock = zmq_socket( $ctxt, ZMQ_SUB);

    zmq_connect( $sock, "tcp://127.0.0.1:$port" );
    zmq_setsockopt( $sock, ZMQ_SUBSCRIBE, '');
    my $timeout = time() + 30;
    my $recvd = 0;
    while ( $timeout > time() && $recvd < 10 ) {
        zmq_poll( [ {
            socket => $sock,
            events => ZMQ_POLLIN,
            callback => sub {
                while (my $msg = zmq_recvmsg( $sock, ZMQ_RCVMORE)) {
                    is ( zmq_msg_data( $msg ), $recvd + 1 );
                    $recvd++;
                }
            }
        } ], 1000000 ); # timeout in microseconds, so this is 1 sec
    }
    is $recvd, 10, "got all messages";
};
    
# Code excercising AnyEvent + ZMQ_FD to do non-blocking recv
if ($^O ne 'MSWin32' && eval { require AnyEvent } && ! $@) {
    AnyEvent->import; # want AE namespace

    my $server = Test::TCP->new( code => sub {
        my $port = shift;
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_PUB);

        zmq_bind($sock, "tcp://127.0.0.1:$port");
        sleep 2;
        for (1..10) {
            zmq_sendmsg($sock, zmq_msg_init_data($_));
        }
        sleep 10;
    } );

    my $port = $server->port;
    my $ctxt = zmq_init();
    my $sock = zmq_socket( $ctxt, ZMQ_SUB);

    zmq_connect( $sock, "tcp://127.0.0.1:$port" );
    zmq_setsockopt( $sock, ZMQ_SUBSCRIBE, '');
    my $timeout = time() + 30;
    my $recvd = 0;
    my $cv = AE::cv();
    my $t;
    my $fh = zmq_getsockopt( $sock, ZMQ_FD );
    my $w; $w = AE::io( $fh, 0, sub {
        while (my $msg = zmq_recvmsg( $sock, ZMQ_RCVMORE)) {
            is ( zmq_msg_data( $msg ), $recvd + 1 );
            $recvd++;
            if ( $recvd >= 10 ) {
                undef $t;
                undef $w;
                $cv->send;
            }
        }
    } );
    $t = AE::timer( 30, 1, sub {
        undef $t;
        undef $w;
        $cv->send;
    } );
    $cv->recv;
    is $recvd, 10, "got all messages";
}

done_testing;
