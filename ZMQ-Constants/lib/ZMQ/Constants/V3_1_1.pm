package ZMQ::Constants::V3_1_1;
use strict;
use ZMQ::Constants ();
use Storable ();

my %not_in_v3 = map { ($_ => 1) } qw(
    ZMQ_MAX_VSM_SIZE
    ZMQ_DELIMITER
    ZMQ_VSM
    ZMQ_MSG_MORE
    ZMQ_MSG_SHARED
    ZMQ_MSG_MASK
    ZMQ_HWM
    ZMQ_SWAP
    ZMQ_RECOVERY_IVL_MSEC
    ZMQ_NOBLOCK
    ZMQ_FAIL_UNROUTABLE
);
my $export_tags = Storable::dclone(\%ZMQ::Constants::EXPORT_TAGS);
$export_tags->{socket} = [ 
    grep { ! $not_in_v3{$_} } @{ $export_tags->{socket} }
];
$export_tags->{message} = [ 
    grep { ! $not_in_v3{$_} } @{ $export_tags->{message} }
];
delete $export_tags->{device};
ZMQ::Constants::register_set(
    '3.1.1' => (
        tags => $export_tags,
    )
);

1;
