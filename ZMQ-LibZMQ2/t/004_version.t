use strict;
use Test::More;

use_ok "ZMQ::LibZMQ2";

{
    my $version = ZMQ::LibZMQ2::zmq_version();
    ok $version;
    like $version, qr/^\d+\.\d+\.\d+$/, "dotted version string";

    my ($major, $minor, $patch) = ZMQ::LibZMQ2::zmq_version();

    is join('.', $major, $minor, $patch), $version, "list and scalar context";
}

done_testing;