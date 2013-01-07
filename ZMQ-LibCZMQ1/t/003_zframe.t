use strict;
use Test::More;

use_ok "ZMQ::LibCZMQ1",
    qw(zframe_new zframe_data zframe_streq);

{
    my $frame = zframe_new("foo", 3);
    if (ok $frame) {
        isa_ok $frame, "ZMQ::LibCZMQ1::Zframe";
        is zframe_data($frame), "foo";
        ok zframe_streq($frame, "foo");
    }
}

done_testing;