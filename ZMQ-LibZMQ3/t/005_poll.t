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
            my $rv = zmq_poll([
                {
                    fd       => fileno(STDOUT),
                    events   => ZMQ_POLLOUT,
                    callback => sub { $called++ }
                },
                {
                    fd       => fileno(STDERR),
                    events   => ZMQ_POLLOUT,
                    callback => sub { $called++ }
                }
            ], 1);
            ok $called, "callback called";
            ok $rv, "zmq_poll returns a boolean in scalar context";
        }, undef, "PollItem doesn't die";

        is exception {
            my $called = 0;
            my @rv = zmq_poll([
                {
                    fd       => fileno(STDOUT),
                    events   => ZMQ_POLLOUT,
                    callback => sub { $called++ }
                },
                {
                    fd       => fileno(STDERR),
                    events   => ZMQ_POLLOUT,
                    callback => sub { $called++ }
                }
            ], 1);
            is $called, 2, "callback called";
            is scalar @rv, 2, "zmq_poll returns a list in list context";
        }, undef, "PollItem doesn't die";
    }
};

subtest 'poll with zmq sockets' => sub {
    my $ctxt = zmq_init();
    my $n = 3;
    my $nsend = 2;
    my @req = map zmq_socket( $ctxt, ZMQ_REQ ), 1..$n;
    my @rep = map zmq_socket( $ctxt, ZMQ_REP ), 1..$n;
    my @called = ((0) x $n);
    is exception {
        zmq_bind($rep[$_], "inproc://polltest$_") for 0..$n-1;
        zmq_connect($req[$_], "inproc://polltest$_") for 0..$n-1;
        zmq_send( $req[$_], "Test$_") for 0..$nsend-1;

        my @rv = zmq_poll([
            map {
                my $x = $_;
                +{
                    socket   => $rep[$x],
                    events   => ZMQ_POLLIN,
                    callback => sub { $called[$x]++ }
                }
            }
            (0..$n-1)
        ], 1);
        my $exp_rv = [((1) x $nsend), ((0) x ($n-$nsend))];
        is_deeply(\@rv, $exp_rv,
                  "zmq_poll returns an array ref indicating whether the callback was invoked");
    }, undef, "PollItem correctly handles callback";

    for (0..$nsend-1) {
      is $called[$_], 1;
    }
    for ($nsend..$n-1) {
      is $called[$_], 0;
    }
};

done_testing;