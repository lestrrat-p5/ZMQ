use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::LibCZMQ1", qw(:zctx);
}

subtest 'basic' => sub {
    my $ctx = zctx_new();
    ok $ctx, "new context";
    isa_ok $ctx, "ZMQ::LibCZMQ1::Zctx";
    zctx_destroy( $ctx );
};

done_testing;