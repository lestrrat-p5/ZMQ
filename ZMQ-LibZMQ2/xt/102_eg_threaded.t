BEGIN {
     require Config;
     if (!$Config::Config{useithreads}) {
        print "1..0 # Skip: no ithreads\n";
        exit 0;
     }
}

use strict;
use Test::More;
use Test::Requires qw(Test::TCP Proc::Guard IO::Socket::INET);
use threads;

BEGIN {
    use_ok "ZMQ::LibZMQ2";
    use_ok "ZMQ::Constants", qw(:v2.1.11 ZMQ_REQ ZMQ_XREQ ZMQ_XREP ZMQ_REQ ZMQ_REP ZMQ_QUEUE);
}

my $port = Test::TCP::empty_port();
my $proc = Proc::Guard->new(code => sub {
    my $ctxt = zmq_init();
    my $sock = zmq_socket($ctxt, ZMQ_REQ);
    zmq_connect($sock,  "tcp://127.0.0.1:$port" );
    for my $i (1..10) {
        zmq_send($sock, "Hello $i");
        my $message = zmq_recv($sock);
    }
    for (1..5) {
        zmq_send($sock, "END");
        my $message = zmq_recv($sock);
    }
    zmq_close($sock);
    zmq_term($ctxt);
});

my $ctxt = zmq_init();
my $device = threads->create( sub {
    my $ctxt = shift;
    my $clients = zmq_socket($ctxt, ZMQ_XREP);
    my $workers = zmq_socket($ctxt, ZMQ_XREQ);
    zmq_bind($clients, "tcp://127.0.0.1:$port" );
    zmq_bind($workers, "inproc://workers" );
    zmq_device(ZMQ_QUEUE, $clients, $workers);
}, $ctxt );
$device->detach();

my @threads;
for (1..5) {
    push @threads, threads->create( sub {
        my $tid = threads->tid;
        my $ctxt = shift;
        my $wsock = zmq_socket($ctxt, ZMQ_REP);

        zmq_connect($wsock, "inproc://workers" );

        my $loop = 1;
        while ($loop) {
            my $message = zmq_recv($wsock);
            my $string  = zmq_msg_data($message);
            if ($string eq 'END') {
                $loop = 0;
                zmq_send($wsock, "END");
                zmq_close($wsock);
            } else {
                zmq_send($wsock, "World $tid");
            }
        }
    }, $ctxt );
}

foreach my $thr (@threads) {
    $thr->join;
}

ok(1);
undef $proc;

done_testing;