use strict;
use Test::More;
use Test::Fatal;
BEGIN {
    use_ok "ZMQ::LibZMQ3", qw(
        zmq_msg_init
        zmq_msg_init_data
        zmq_msg_init_size
        zmq_msg_data
        zmq_msg_size
        zmq_msg_copy
        zmq_msg_move
        zmq_msg_close
    );
}

subtest "sane allocation / cleanup for message" => sub {
    is exception {
        my $msg = zmq_msg_init();
        isa_ok $msg, "ZMQ::LibZMQ3::Message";
        is zmq_msg_data( $msg ), '', "no message data";
        is zmq_msg_size( $msg ), 0, "data size is 0";
    }, undef, "code lives";

    is exception {
        my $msg = zmq_msg_init();
        zmq_msg_close($msg);
        zmq_msg_close($msg);
    }, undef, "double close should not die";
};

subtest "sane allocation / cleanup for message (init_data)" => sub {
    is exception {
        my $data = "TESTTEST";
        my $msg = zmq_msg_init_data( $data );
        isa_ok $msg, "ZMQ::LibZMQ3::Message";
        is zmq_msg_data( $msg ), $data, "data matches";
        is zmq_msg_size( $msg ), length $data, "data size matches";
    }, undef, "code lives";
};

subtest "sane allocation / cleanup for message (init_size)" => sub {
    is exception {
        my $msg = zmq_msg_init_size(100);
        isa_ok $msg, "ZMQ::LibZMQ3::Message";

        # don't check data(), as it will be populated with garbage
        is zmq_msg_size( $msg ), 100, "data size is 100";
    }, undef, "code lives";
};

subtest "copy / move" => sub {
    is exception {
        my $msg1 = zmq_msg_init_data( "foobar" );
        my $msg2 = zmq_msg_init_data( "fogbaz" );
        my $msg3 = zmq_msg_init_data( "figbun" );

        is zmq_msg_copy( $msg1, $msg2 ), 0, "copy returns 0";
        is zmq_msg_data( $msg1 ), zmq_msg_data( $msg2 ), "msg1 == msg2";
        is zmq_msg_data( $msg1 ), "fogbaz", "... and msg2's data is in msg1";
    }, undef, "code lives";
};

done_testing;