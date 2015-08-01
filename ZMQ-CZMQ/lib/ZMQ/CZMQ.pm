package ZMQ::CZMQ;
use warnings;
use strict;
our $VERSION = '1.04';
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

=head1 NAME

ZMQ::CZMQ - Perl-ish wrapper for libczmq

=head1 SYNOPSIS

    use ZMQ::CZMQ;
    use ZMQ::Constants ...;

=head1 DESCRIPTION

ZMQ::CZMQ is a Perl-ish wrapper for libczmq. It uses ZMQ::LibCZMQ1 for
its backend (when/if libczmq 2.x comes out, we may change to use
ZMQ::LibCZMQ2 or whatever)

If you want a one-to-one direct mapping to libzmq, then you should be using ZMQ::LibCZMQ1

If you think your code will be used from another program that also uses libczmq,
you might want to consider using the ZMQ::LibCZMQ* modules. This is because you
can't write "truly" portable code using this high level interface (libczmq's
API change rather drastically between versions). Personally, I'd recommend
only using this module for your one-shot scripts, and use ZMQ::LibCZMQ* for
all other uses. YMMV.

=head1 FUNCTIONS

=head2 ZMQ::CZMQ::call($funcname, @args)

Calls C<$funcname> via whichever backend loaded by ZMQ.pm. 
If C<@args> is passed, they are passed directly to the target function.

=head1 UNSUPPORTED

=head2 zclock_*, zfile_*, zhash_*, zlist_*, zloop_*, zmutex_*, zsys_*, and zthread_*

Functions in this area doesn't make sense to be made OO/Perlish. Either
use them directly via C<ZMQ::LibCZMQ*::> or C<ZMQ::CZMQ::call()>

If you don't agree and would like to add them, patches are welcome.

=head1 SEE ALSO

L<http://zeromq.org>

L<http://github.com/lestrrat/p5-ZMQ>

L<ZMQ::LibCZMQ1>, L<ZMQ::Constants>

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT AND LICENSE

The ZMQ module is

Copyright (C) 2013 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
