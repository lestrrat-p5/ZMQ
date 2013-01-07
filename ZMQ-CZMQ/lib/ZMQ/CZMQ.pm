package ZMQ::CZMQ;
use strict;
our $VERSION = '1.03';
our $BACKEND;
BEGIN {
    $BACKEND ||= $ENV{PERL_ZMQ_CZMQ_BACKEND};
    if ( $BACKEND ) {
        eval "require $BACKEND";
        if ($@) {
            die $@;
        }
    } else {
        foreach my $lib ( qw(ZMQ::LibCZMQ1) ) {
            eval "require $lib";
            if ($@) {
                next;
            }
            $BACKEND = $lib;
        }
    }

    if (! $BACKEND) {
        die "Could not find a suitable backend for ZMQ::CZMQ";
    }
}

sub call {
    my $funcname = shift;
    no strict 'refs';
    goto &{"${BACKEND}::$funcname"};
}

use ZMQ::CZMQ::Zctx;
use ZMQ::CZMQ::Zframe;
use ZMQ::CZMQ::Zmsg;
use ZMQ::CZMQ::Zsocket;

1;

__END__

=head1 UNSUPPORTED

=head2 zclock_*, zfile_*

Functions in this area doesn't make sense to be made OO/Perlish. Either
use them directly via C<ZMQ::LibCZMQ*::> or C<ZMQ::CZMQ::call()>

=cut