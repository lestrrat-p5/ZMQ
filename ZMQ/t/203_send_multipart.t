use Test::More;
use lib 'lib';

use ZMQ;
use ZMQ::Constants qw/:all/;

my $ctx = ZMQ::Context->new(1);

my $req = $ctx->socket(ZMQ_REQ);
$req->bind('tcp://127.0.0.1:5099');

my $rep = $ctx->socket(ZMQ_REP);
$rep->connect('tcp://127.0.0.1:5099');

$req->send_multipart([ "frame0", "frame1", "frame2" ]);

my @msg = $rep->recv_multipart;

is($msg[0]->data, "frame0");
is($msg[1]->data, "frame1");
is($msg[2]->data, "frame2");

$rep->send_multipart(["ok"]);

my @status = $req->recv_multipart;
is($status[0]->data, "ok");

sleep 0.5;

done_testing();

