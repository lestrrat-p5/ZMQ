BEGIN {
     require Config;
     if (!$Config::Config{useithreads}) {
        print "1..0 # Skip: no ithreads\n";
        exit 0;
     }
}

use strict;
use Test::More;
use threads;

BEGIN {
    use_ok "ZMQ::LibZMQ3";
    use_ok "ZMQ::Constants", "ZMQ_REQ";
}

subtest 'parent creates context and creates thread, child exists w/o doing anything' => sub {
    my $ctx = zmq_init(1);
    my $thr = threads->create(sub{
        note "thread created";
    });
    $thr->join();
    pass('zmq_init() is thread-resistant');
};

subtest 'parent creates context and creates thread, child calls zmq_term' => sub {
    my $ctx = zmq_init(1);
    my $thr = threads->create(sub {
        zmq_term($ctx);
        note "thread created";
    });
    $thr->join;
    pass('zmq_init() is thread-resistant');
};

subtest 'parent creates context, socket, and creates thread, child does nothing' => sub {
    my $ctx = zmq_init(1);
    my $sock = zmq_socket($ctx, ZMQ_REQ);
    my $thr = threads->create(sub {
        note "thread created";
    });
    $thr->join;
    pass('zmq_init() is thread-resistant');
};

subtest 'parent creates context, message, and creates thread, child does nothing' => sub {
    my $ctx = zmq_init(1);
    my $msg = zmq_msg_init();
    my $thr = threads->create(sub {
        note "thread created";
    });
    $thr->join;
    pass('zmq_init() is fork-resistant');
};

done_testing();