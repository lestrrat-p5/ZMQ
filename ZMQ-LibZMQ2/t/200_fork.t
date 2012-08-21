use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::LibZMQ2";
}

my $ctx = zmq_init(1);
my $pid = fork();
exit(0) unless $pid;
waitpid($pid, 0);
pass('zmq_init() is fork-resistant');


done_testing();
