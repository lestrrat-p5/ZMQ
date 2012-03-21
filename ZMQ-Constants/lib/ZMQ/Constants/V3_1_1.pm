package ZMQ::Constants::V3_1_1;
use strict;
use base qw(ZMQ::Constants::Basic);

my %device = map { ($_ => 1) } @{$ZMQ::Constants::Basic::EXPORT_TAGS{device}};
our @EXPORT_OK = grep { ! $device{$_} } @ZMQ::Constants::Basic::EXPORT_OK;
our %EXPORT_TAGS = %ZMQ::Constants::Basic::EXPORT_TAGS;
delete $EXPORT_TAGS{device};
$EXPORT_TAGS{all} = [ @EXPORT_OK ];

1;
