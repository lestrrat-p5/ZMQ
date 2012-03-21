package ZMQ::Constants::V3_1_2;
use strict;
use ZMQ::Constants ();
use Storable ();

my $export_tags = Storable::dclone(\%ZMQ::Constants::EXPORT_TAGS);
push @{ $export_tags->{socket} }, 'ZMQ_FAIL_UNROUTABLE';

ZMQ::Constants::add_constant( ZMQ_FAIL_UNROUTABLE => 33 );
ZMQ::Constants::register_set(
    '3.1.2' => (
        tags => $export_tags,
    )
);

1;
