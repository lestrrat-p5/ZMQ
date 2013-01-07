use strict;
use Test::More;

BEGIN {
    use_ok "ZMQ::CZMQ";
}

{
    my $msg = ZMQ::CZMQ::Zmsg->new;
    if (ok $msg) {
        isa_ok $msg, "ZMQ::CZMQ::Zmsg";

        my $size = 0;
        my $content_size;
        my @frames = qw(foo bar baz);
        foreach my $buf (@frames) {
            $msg->pushstr($buf);
            $size++;
            $content_size += length($buf);
            is $msg->size, $size;
            is $msg->content_size, $content_size;
        }

        for my $i (1..$size) {
            my $b = $size - $i;
            is $msg->popstr, $frames[$b], "frame (@{[$b + 1]}) should contain $frames[$b]";
            is $msg->size, $b, "now we should have $b frames";
        }

        my $f = ZMQ::CZMQ::Zframe->new("bar", 3);
        $msg->wrap($f);
        my $frame = $msg->unwrap;
        if (ok $frame) {
            is $frame->data, "bar", "unwrapped frame contains 'bar'";
        }
    }
}

done_testing;