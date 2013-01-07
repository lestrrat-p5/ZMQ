use strict;
use Test::More;

BEGIN {
    use_ok("ZMQ::CZMQ");
    use_ok("ZMQ::Constants", "ZMQ_REQ");
}

{
    my $ctx = ZMQ::CZMQ::Zctx->new;
    if (ok $ctx) {
        isa_ok $ctx, "ZMQ::CZMQ::Zctx";
    }
}

{
    my $ctx = ZMQ::CZMQ::Zctx->new;
    my $sock = $ctx->socket(ZMQ_REQ);
    if (ok $sock) {
        $sock->destroy($ctx);
    }
}

done_testing;