use strict;
use Test::More;
use Test::Fatal;

BEGIN {
    use_ok "ZMQ::LibZMQ3";
    use_ok "ZMQ::Constants", ":v3.1.1", ":all";
}

subtest 'basic poll with fd' => sub {
    SKIP: {
        skip "Can't poll using fds on Windows", 2 if ($^O eq 'MSWin32');
        is exception {
            my $called = 0;
            zmq_poll([
                {
                    fd       => fileno(STDOUT),
                    events   => ZMQ_POLLOUT,
                    callback => sub { $called++ }
                }
            ], 1);
            ok $called, "callback called";
        }, undef, "PollItem doesn't die";
    }
};

subtest 'poll with zmq sockets' => sub {
    my $ctxt = zmq_init();
    my $req = zmq_socket( $ctxt, ZMQ_REQ );
    my $rep = zmq_socket( $ctxt, ZMQ_REP );
    my $called = 0;
    is exception {
        zmq_bind( $rep, "inproc://polltest");
        zmq_connect( $req, "inproc://polltest");
        zmq_send( $req, "Test");

        zmq_poll([
            {
                socket   => $rep,
                events   => ZMQ_POLLIN,
                callback => sub { $called++ }
            },
        ], 1);
    }, undef, "PollItem correctly handles callback";

    is $called, 1;
};

done_testing;