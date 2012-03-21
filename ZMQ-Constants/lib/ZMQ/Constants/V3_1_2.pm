package ZMQ::Constants::V3_1_2;
use strict;
use base qw(ZMQ::Constants::Basic);

use constant ZMQ_FAIL_UNROUTABLE => 33;

our @EXPORT_OK = (@ZMQ::Constants::Basic::EXPORT_OK, "ZMQ_FAIL_UNROUTABLE");
our %EXPORT_TAGS = %ZMQ::Constants::Basic::EXPORT_TAGS;
$EXPORT_TAGS{all} = [ @EXPORT_OK ];
push @{$EXPORT_TAGS{socket}}, 'ZMQ_FAIL_UNROUTABLE';

1;
