use strict;
use Test::More;
use Test::TCP;
BEGIN {
    use_ok "ZMQ::LibZMQ2";
    use_ok "ZMQ::Constants", qw(:v2.1.11 ZMQ_PUB ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_POLLIN ZMQ_NOBLOCK);
}

test_tcp(
    client => sub {
        my $port = shift;
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_SUB);
        zmq_connect($sock,  "tcp://127.0.0.1:$port" );
        zmq_setsockopt($sock, ZMQ_SUBSCRIBE, "W");
        my $message = zmq_recv($sock);
        is zmq_msg_data($message), "WORLD?";
    },
    server => sub {
        my $port = shift;
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_PUB);
        zmq_bind($sock, "tcp://127.0.0.1:$port" );

        # if this server goes away before the client can recv(), the
        # client waits hanging
        local $SIG{ALRM} = sub {
            die "ZMQ_ALRM_TIMEOUT";
        };
        eval {
            alarm(10);
            my @message = qw(HELLO? WORLD? HELLO? HELLO?);
            while(1) {
                my $message = shift @message;
                if ($message) {
                    zmq_send($sock, $message);
                }
                sleep 1
            }
        };
    }
);

done_testing;