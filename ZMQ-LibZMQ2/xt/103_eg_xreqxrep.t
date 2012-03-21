use strict;
use Test::More;
use Test::TCP;
use Test::Requires 'Parallel::Prefork';
use File::Temp;
BEGIN {
    use_ok "ZMQ::LibZMQ2";
    use_ok "ZMQ::Constants", qw(:v2.1.11 ZMQ_REQ ZMQ_REP ZMQ_POLLOUT ZMQ_NOBLOCK);
}

my $parent;
test_tcp(
    server => sub {
        my $port = shift;

        my $ctxt = zmq_init;
        my $socket = zmq_socket($ctxt, ZMQ_REP);
        zmq_bind($socket,  "tcp://127.0.0.1:$port");

        while ( 1 ) {
            my $msg = zmq_recv($socket);
            next unless $msg;
            zmq_send($socket, "Thank you " . zmq_msg_data($msg));
        }
    },
    client => sub {
        my $port = shift;

        sleep 2;
        my %children;
        foreach (1..3) {
            my $pid = fork();
            if (! defined $pid) {
                die "Could not fork";
            } elsif ($pid) {
                $parent = $$;
                $children{$pid}++;
            } else {
                my $ctxt = zmq_init();
                my $client = zmq_socket($ctxt,  ZMQ_REQ );
                zmq_connect($client, "tcp://127.0.0.1:$port");
                zmq_send($client, $$);
                my $msg = zmq_recv($client);
                my $data = zmq_msg_data($msg);
                is $data, "Thank you $$", "child $$ got reply '" . $data . "'";
                exit 0;
            }
        }

        while (%children) {
            if ( my $pid = wait ) {
                delete $children{$pid};
            }
        }
    }
);

done_testing;
