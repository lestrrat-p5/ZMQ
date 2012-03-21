package ZMQ::Constants::V2_1_11;
use strict;
use Storable ();
use ZMQ::Constants ();

my %not_in_v2 = (
    ZMQ_MAXMSGSIZE          => 22,
    ZMQ_SNDHWM              => 23,
    ZMQ_RCVHWM              => 24,
    ZMQ_MULTICAST_HOPS      => 25,
    ZMQ_RCVTIMEO            => 27,
    ZMQ_SNDTIMEO            => 28,
    ZMQ_IPV4ONLY            => 31,
    ZMQ_LAST_ENDPOINT       => 32,
    ZMQ_MORE                => 1,
    ZMQ_DONTWAIT            => 1,
    ZMQ_FAIL_UNROUTABLE     => 1,
);

my $export_tags = Storable::dclone( \%ZMQ::Constants::EXPORT_TAGS );
$export_tags->{socket} = [
    (grep { ! $not_in_v2{$_} } @{ $export_tags->{socket} }),
];
$export_tags->{message} = [ qw(ZMQ_MAX_VSM_SIZE ZMQ_DELIMITER ZMQ_VSM ZMQ_MSG_MORE ZMQ_MSG_SHARED ZMQ_MSG_MASK) ];

ZMQ::Constants::register_set(
    '2.1.11' => (
        tags => $export_tags
    )
);

1;
