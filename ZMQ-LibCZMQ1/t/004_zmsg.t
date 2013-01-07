use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::LibCZMQ1", qw(zmsg_new zmsg_wrap zmsg_unwrap zmsg_pushstr zmsg_size zmsg_content_size zframe_new zframe_data);
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

done_testing;