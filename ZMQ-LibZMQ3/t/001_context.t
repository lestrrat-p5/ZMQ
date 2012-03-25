use strict;
use Test::More;
use Test::Fatal;
use POSIX qw(EFAULT);
BEGIN {
    use_ok "ZMQ::LibZMQ3", qw(
        zmq_init
        zmq_term
    );
}

subtest 'sane creation/destroy' => sub {
    is exception {
        my $context = zmq_init(5);
        isa_ok $context, "ZMQ::LibZMQ3::Context";
        zmq_term( $context );
    }, undef, "sane allocation / cleanup for context";

    is exception {
        my $context = zmq_init();
        is zmq_term( $context ), 0, "successful zmq_term";
        isnt zmq_term( $context ), 0, "duplicate zmq_term";
        is $! + 0, EFAULT, '$! is set';
    }, undef, "double zmq_term should not die";
};

subtest 'error cae' => sub {
    local $!;

    ok ! $!, "\$! is not set";

    my $cxt = zmq_init(-1);

    ok ! $cxt, "context allocation failed";
    ok $!, "\$! is set";
};

done_testing;