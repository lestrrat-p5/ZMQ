use strict;
use Test::More;
use Test::Requires qw( Test::TCP );
use Data::Dumper;

BEGIN {
    use_ok "ZMQ::LibZMQ2";
    use_ok "ZMQ::Constants", qw(:v2.1.11 :all);
}

my $max = $ENV{ MSGCOUNT } || 100;
note "Using $max messages to test - set MSGCOUNT to a different number if you want to change this";

test_tcp(
    client => sub {
        my $port = shift;
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_SUB);
        note "Client connecting to port $port";
        zmq_connect($sock,"tcp://127.0.0.1:$port" );
        zmq_setsockopt($sock, ZMQ_SUBSCRIBE, '');

        note "Starting to receive data";
        for my $cnt ( 0 .. ($max - 1) ) {
            my $rawmsg = zmq_recv($sock);
            my $data = zmq_msg_data($rawmsg);
            is($data, $cnt, "Expected $cnt, got $data");
        } 
        my $msg = zmq_recv( $sock );
        is( zmq_msg_data($msg), "end", "Done!" );
        note "Received all messages";
    },
    server => sub {
        my $port = shift;
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_PUB);

        note "Server Binding to port $port\n";
        zmq_bind($sock, "tcp://127.0.0.1:$port");
        note "Waiting on client to bind...";
        sleep 2;

        note "Server sending ordered data... (numbers 1..1000)";
        for my $c ( 0 .. ( $max - 1 ) ) {
        	my $msg = zmq_msg_init_data($c);
            zmq_send($sock, $msg, ZMQ_SNDMORE);
        }
        zmq_send( $sock, "end" );
        note "Sent all messages";
        note "Server exiting...";
        exit 0;
    }
);

done_testing;
