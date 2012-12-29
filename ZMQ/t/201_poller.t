use Test::More;

use ZMQ;
use ZMQ::Constants qw/:all/;

my $ctx = ZMQ::Context->new(1);

my $push = $ctx->socket(ZMQ_PUSH);
$push->bind('tcp://127.0.0.1:5099');

my $pull = $ctx->socket(ZMQ_PULL);
$pull->connect('tcp://127.0.0.1:5099');

my $poller = ZMQ::Poller->new;

$poller->register($pull, ZMQ_POLLIN);
$poller->register($push, ZMQ_POLLOUT);

my $cnt = 0;

for (;;) {
    last if $cnt > 10;

    my @fired = $poller->poll(1000); 

    for (@fired) {
        if ($_->{socket} == $push && $_->{events} == ZMQ_POLLOUT) {
            $push->sendmsg('Hello');
            ok(1, 'push out fired');
        }
        elsif ($_->{socket} == $pull && $_->{events} == ZMQ_POLLIN) {
            ok(1, 'pull in fired');
            my $msg = $pull->recvmsg;
            is($msg->data, 'Hello');
            $cnt++;
        }
    }
}

done_testing();
