use strict;
use Test::More;

use_ok "ZMQ::CZMQ";

subtest 'basic' => sub {
    my $ctx = zctx_new();
    ok $ctx, "new context";
    isa_ok $ctx, "ZMQ::CZMQ::zctx";
    zctx_destroy( $ctx );
};

done_testing;