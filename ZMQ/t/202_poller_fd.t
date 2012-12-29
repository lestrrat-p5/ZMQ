use Test::More;

use ZMQ;
use ZMQ::Constants qw/:all/;

my $ctx = ZMQ::Context->new(1);

my $poller = ZMQ::Poller->new;

$poller->register(fileno(STDOUT), ZMQ_POLLOUT);

my @fired = $poller->poll(1000); 
is(@fired, 1);

done_testing();

