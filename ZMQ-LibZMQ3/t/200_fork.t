use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::LibZMQ3";
    use_ok "ZMQ::Constants", "ZMQ_REQ";
}

subtest 'parent creates context and forks, child exists w/o doing anything' => sub {
    my $ctx = zmq_init(1);
    my $pid = fork();
    exit(0) unless $pid;
    waitpid($pid, 0);
    pass('zmq_init() is fork-resistant');
};

subtest 'parent creates context and forks, child calls zmq_term' => sub {
    my $ctx = zmq_init(1);
    my $pid = fork();
    if (! $pid) {
        zmq_term($ctx);
        exit(0);
    }
    waitpid($pid, 0);
    pass('zmq_init() is fork-resistant');
};

subtest 'parent creates context, socket, and forks, child does nothing' => sub {
    my $ctx = zmq_init(1);
    my $sock = zmq_socket($ctx, ZMQ_REQ);
    my $pid = fork();
    exit(0) unless $pid;
    waitpid($pid, 0);
    pass('zmq_init() is fork-resistant');
};

subtest 'parent creates context, socket, and forks, child calls zmq_close()' => sub {
    my $ctx = zmq_init(1);
    my $sock = zmq_socket($ctx, ZMQ_REQ);
    my $pid = fork();
    if (! $pid) {
        zmq_close($sock);
        exit(0);
    }
    waitpid($pid, 0);
    pass('zmq_init() is fork-resistant');
};

subtest 'parent creates context, message, and forks, child does nothing' => sub {
    my $ctx = zmq_init(1);
    my $msg = zmq_msg_init();
    my $pid = fork();
    exit(0) unless $pid;
    waitpid($pid, 0);
    pass('zmq_init() is fork-resistant');
};

done_testing();