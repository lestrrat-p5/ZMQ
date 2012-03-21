use strict;
use Test::More;
use Test::TCP;
BEGIN {
    use_ok "ZMQ::LibZMQ2";
    use_ok "ZMQ::Constants", qw(:v2.1.11 ZMQ_REQ ZMQ_REP);
}

my $server = Test::TCP->new( code => sub {
    my $port = shift;
    my $ctxt = zmq_init();
    my $sock = zmq_socket($ctxt, ZMQ_REP);
    zmq_bind($sock, "tcp://127.0.0.1:$port" );

    my $message = zmq_recv($sock);
    is zmq_msg_data($message), "hello", "server receives correct data";
    zmq_send($sock, "world");
    exit 0;
} );

my $port = $server->port;
my $ctxt = zmq_init();
my $sock = zmq_socket($ctxt, ZMQ_REQ);
zmq_connect($sock, "tcp://127.0.0.1:$port" );
zmq_send($sock, "hello");

my $message = zmq_recv($sock);
is zmq_msg_data($message), "world", "client receives correct data";

done_testing;