use strict;
use Test::More;
use Test::TCP;
BEGIN {
    use_ok "ZMQ::Constants", ":all";
    use_ok "ZMQ::CZMQ";
}

subtest 'basic' => sub {
    my $ctx = zctx_new();
    ok $ctx, "new context";

    my $socket = zsocket_new( $ctx, ZMQ_PAIR );
    ok $socket, "new socket";
    isa_ok $socket, "ZMQ::CZMQ::zsocket";
    
    zsocket_destroy( $ctx, $socket );
    zctx_destroy( $ctx );
};

subtest 'inproc bind and connect' => sub {
    my $addr = "inproc://zstr.test";
    my $ctx = zctx_new();
    my $reader = zsocket_new( $ctx, ZMQ_PAIR );
    my $writer = zsocket_new( $ctx, ZMQ_PAIR );

    my $rv;
    $rv = zsocket_bind( $reader, $addr );
    $rv = zsocket_connect( $writer, $addr );

    is $rv, 0, "zsocket_connect returns 0";
    for ( 1.. 10 ) {
        $rv = zstr_send( $writer, $_ );
        is $rv, 0, "zstr_send returns 0";
    }

    for ( 1.. 10 ) {
        my $str = zstr_recv( $reader );
        is $str, $_, "zstr_recv received correct message";
    }
};

done_testing;