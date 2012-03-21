use strict;
use Test::More;
use Test::Fatal;

BEGIN {
    use_ok "ZMQ::LibZMQ3", qw(
        zmq_connect
        zmq_close
        zmq_init
        zmq_socket
        zmq_close
        zmq_getsockopt
        zmq_setsockopt
    );
    use_ok "ZMQ::Constants", ':v3.1.1', ':all';
}

subtest 'simple creation and destroy' => sub {
    is exception {
        my $context = zmq_init(1);
        my $socket  = zmq_socket( $context, ZMQ_REP );
        isa_ok $socket, "ZMQ::LibZMQ3::Socket";
    }, undef, "socket creation OK";

    is exception {
        my $context = zmq_init(1);
        my $socket  = zmq_socket( $context, ZMQ_REP );
        isa_ok $socket, "ZMQ::LibZMQ3::Socket";
        zmq_close( $socket );
    }, undef, "socket create, then zmq_close";

    is exception {
        my $context = zmq_init();
        my $socket  = zmq_socket( $context, ZMQ_REP );
        zmq_close( $socket );
        zmq_close( $socket );
    }, undef, "double zmq_close should not die";
};

subtest 'connect to a non-existent addr' => sub {
    is exception {
        my $context = zmq_init(1);
        my $socket  = zmq_socket( $context, ZMQ_PUSH );

        TODO: {
            todo_skip "I get 'Assertion failed: rc == 0 (zmq_connecter.cpp:46)'", 2;

        lives_ok {
            zmq_connect( $socket, "tcp://inmemory" );
        } "connect should succeed";

        zmq_close( $socket );
        dies_ok {
            zmq_connect( $socket, "tcp://inmemory" );
        } "connect should fail on a closed socket";

        }
    }, undef, "check for proper handling of closed socket";
};

subtest 'github pull 33 (ZMQ_RECONNECT_IVL)' => sub {
    SKIP: {
        my $ok =
            __PACKAGE__->can('ZMQ_RECONNECT_IVL') &&
            __PACKAGE__->can('ZMQ_RECONNECT_IVL_MAX')
        ;
        if (! $ok) {
            skip "ZMQ_RECONNET_IVL(_MAX) not available", 1;
        }
    }

    is exception {
        my $ctx = zmq_init();
        my $sock = zmq_socket($ctx, ZMQ_PUSH);

        my %consts = (
            ZMQ_RECONNCET_IVL => ZMQ_RECONNECT_IVL(),
            ZMQ_RECONNCET_IVL_MAX => ZMQ_RECONNECT_IVL_MAX(),
        );
        while ( my ($name, $value) = each %consts ) {
            note "BEFORE: $name: " . zmq_getsockopt( $sock, $value );
            zmq_setsockopt( $sock, $value, 500 );
            note "AFTER: $name: " . zmq_getsockopt($sock, $value);
        }
    }, undef, "no exception";
};

done_testing;
