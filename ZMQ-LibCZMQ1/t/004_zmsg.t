use strict;
use Test::More;
use Test::TCP;

BEGIN {
    use_ok "ZMQ::LibCZMQ1", qw(:zctx :zmsg :zsocket :zframe);
    use_ok "ZMQ::Constants", qw(ZMQ_REQ ZMQ_REP);
}

{
    my $msg = zmsg_new();
    if (ok $msg) {

        my $size = 0;
        my $content_size;
        my @frames = qw(foo bar baz);
        foreach my $buf (@frames) {
            zmsg_pushstr($msg, $buf);
            $size++;
            $content_size += length($buf);
            is zmsg_size($msg), $size;
            is zmsg_content_size($msg), $content_size;
        }

        my $f = zframe_new("bar", 3);
        zmsg_wrap($msg, $f);
        my $frame = zmsg_unwrap($msg);
        if (ok $frame) {
            is zframe_data($frame), "bar", "unwrapperd frame contains 'bar'";
        }
    }
}

{
    my $server = Test::TCP->new(code => sub {
        my $port = shift;
        my $ctx = zctx_new;
        my $sock = zsocket_new($ctx, ZMQ_REP);
        zsocket_bind($sock, "tcp://127.0.0.1:%d", $port);

        my $msg = zmsg_recv($sock);
        my $data = zmsg_popstr($msg);
        if (ok $data) {
            is($data, "foo");

            $msg = zmsg_new;
            zmsg_wrap($msg, zframe_new("foo", 3));
            zmsg_wrap($msg, zframe_new("bar", 3));

            zmsg_send($msg, $sock);
        }

        zsocket_destroy($ctx, $sock);
        zctx_destroy($ctx);
        exit 0;
    });

    sleep 1;

    my $ctx = zctx_new;
    my $sock = zsocket_new($ctx, ZMQ_REQ);
    zsocket_connect($sock, "tcp://127.0.0.1:%d", $server->port);

    my $msg = zmsg_new;
    zmsg_wrap($msg, zframe_new("foo", 3));
    zmsg_send($msg, $sock);
    $msg = zmsg_recv($sock);
    for my $expect (qw(bar foo)) {
        note "expecting $expect from server...";
        my $frame = zmsg_unwrap($msg);
        if (ok $frame) {
            is zframe_data($frame), $expect, "expected $expect, got " . zframe_data($frame);
        }
    }
    
}

done_testing;