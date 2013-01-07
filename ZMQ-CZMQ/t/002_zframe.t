use strict;
use Test::More;

use_ok "ZMQ::CZMQ";

{
    my $frame = ZMQ::CZMQ::Zframe->new("foo", 3);
    if (ok $frame) {
        isa_ok $frame, "ZMQ::CZMQ::Zframe";
        is $frame->data, "foo";
        ok $frame->streq("foo");
        is $frame->strdup, "foo";
        is $frame->strhex, uc unpack "H*", "foo";
#        ok !$frame->zero_copy;
        ok !$frame->more;

        my $dup = $frame->dup;
        if (ok $dup) {
            is $dup->data, $frame->data;
        }

        $frame->reset("bar", 3);
        is $frame->data, "bar";
    }
}

done_testing;