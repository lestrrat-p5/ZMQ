use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::CZMQ";
    use_ok "ZMQ::Constants", qw(ZMQ_REQ);
}

{
    my $cxt = ZMQ::CZMQ::Zctx->new;
    my $sock = $cxt->socket(ZMQ_REQ);

    is $sock->type, ZMQ_REQ;
    is $sock->type_str, "REQ";
}

done_testing;