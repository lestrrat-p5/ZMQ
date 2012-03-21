use strict;
use Test::More;
use Test::Requires qw( Test::TCP AnyEvent );

BEGIN {
    use_ok "ZMQ::LibZMQ3";
    use_ok "ZMQ::Constants", ":v3.1.1", ":all";
}

my $server = Test::TCP->new(code => sub {
    my $port = shift;
    my $ctxt = zmq_init(1);
    my $sock = zmq_socket( $ctxt, ZMQ_REP );
    zmq_bind( $sock, "tcp://127.0.0.1:$port" );

    my $msg;
    if ( $^O eq 'MSWin32' ) {
        note "Win32 server, using zmq_poll";
        my $timeout = time() + 5;
        do {
            zmq_poll([
                {
                    socket   => $sock,
                    events   => ZMQ_POLLIN,
                    callback => sub {
                        $msg = zmq_recvmsg( $sock, ZMQ_RCVMORE );
                    }
                },
            ], 5);
        } while (! $msg && time < $timeout );
    } else {
        note "Using zmq_getsockopt + AE";
        my $cv = AE::cv;

        note " + Extracting ZMQ_FD";
        my $fh = zmq_getsockopt( $sock, ZMQ_FD );

        note " + Creating AE::io for fd";
        my $w; $w = AE::io $fh, 0, sub {
            if (my $msg = zmq_recvmsg( $sock, ZMQ_RCVMORE )) {
                undef $w;
                $cv->send( $msg );
            }
        };
        note "Waiting...";
        $msg = $cv->recv;
    }

    zmq_send( $sock, zmq_msg_data( $msg ) );
    exit 0;
});

my $port = $server->port;
my $ctxt = zmq_init(1);
my $sock = zmq_socket( $ctxt, ZMQ_REQ );

zmq_connect( $sock, "tcp://127.0.0.1:$port" );
my $data = join '.', time(), $$, rand, {};

note "Sending data to server";
zmq_send( $sock, $data );
my $msg = zmq_recvmsg( $sock );
is $data, zmq_msg_data( $msg ), "Got back same data";

done_testing;
