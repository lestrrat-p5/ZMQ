use strict;
use Test::Requires qw(
    Data::UUID
    Parallel::ForkManager
    Time::HiRes
    Test::SharedFork
);
use Test::More;
use ZMQ::LibZMQ2;
use ZMQ::Constants qw(:v2.1.11 :all);

run();

sub run {
    my $max = 1_000; # 1_000_000;
    my $port = 9999;
    my @prefixes = (0..9, 'A'..'Z');
    my $pm = Parallel::ForkManager->new(36);
    foreach my $prefix ( @prefixes ) {
        $pm->start() and next;
        eval { run_client( $port, $prefix ) };
        warn if $@;
        $pm->finish;
    }

    my $uuid = Data::UUID->new;
    my $ctxt = zmq_init();
    my $socket = zmq_socket( $ctxt, ZMQ_PUB );
    zmq_bind( $socket, "tcp://127.0.0.1:$port" );
    for ( 1 .. $max ) {
        my $data = $uuid->create_from_name_str(
            "pubsub_stress",
            join( ".",
                Time::HiRes::time(),
                {},
                rand(),
                $$
            )
        );
#        warn "sending $data";
        zmq_send( $socket, $data );
    }

    sleep 5;

    for my $prefix ( 0..9, 'A' ..'Z' ) {
        zmq_send( $socket, "$prefix-EXIT" );
    }

#    warn "now waiting...";
    $pm->wait_all_children;

    zmq_close( $socket );
    zmq_term($ctxt);
    done_testing();
}

sub run_client {
    my ($port, $prefix) = @_;

    my $ctxt = zmq_init();
    my $socket = zmq_socket( $ctxt, ZMQ_SUB );
    zmq_connect( $socket, "tcp://127.0.0.1:$port" );
#    warn "connected...";
    zmq_setsockopt( $socket, ZMQ_SUBSCRIBE, $prefix );
#    warn "subscribing to $prefix";

    my $loop = 1;
    while (1) {
        zmq_poll([ {
            socket => $socket,
            events => ZMQ_POLLIN,
            callback => sub {
                while (my $msg = zmq_recv( $socket, ZMQ_RCVMORE )) {
                    my $data = zmq_msg_data( $msg );
#                    warn $data;
                    if ($data =~ /-EXIT$/ ) {
                        $loop = 0;
                    }
                }
            }
        } ], 1000000);
        last unless $loop;
    }

#    warn "child for $prefix done";
    zmq_close( $socket );
    zmq_term( $ctxt );
    ok(1);
}

1;