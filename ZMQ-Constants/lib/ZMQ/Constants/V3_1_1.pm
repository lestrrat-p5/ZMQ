package ZMQ::Constants::V3_1_1;
use strict;
use ZMQ::Constants ();
use Storable ();

my $export_tags = Storable::dclone(\%ZMQ::Constants::EXPORT_TAGS);
delete $export_tags->{device};
ZMQ::Constants::register_set(
    '3.1.2' => (
        tags => $export_tags,
    )
);

1;
