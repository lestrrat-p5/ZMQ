package ZMQ::Constants;
use strict;
use base qw(Exporter);
use Carp ();

my %constants;
BEGIN {
    %constants  = (
        ZMQ_PAIR                => 0,
        ZMQ_PUB                 => 1,
        ZMQ_SUB                 => 2,
        ZMQ_REQ                 => 3,
        ZMQ_REP                 => 4,
        ZMQ_DEALER              => 5,
        ZMQ_ROUTER              => 6,
        ZMQ_PULL                => 7,
        ZMQ_PUSH                => 8,
        ZMQ_XPUB                => 9,
        ZMQ_XSUB                => 10,
        ZMQ_AFFINITY            => 4,
        ZMQ_IDENTITY            => 5,
        ZMQ_SUBSCRIBE           => 6,
        ZMQ_UNSUBSCRIBE         => 7,
        ZMQ_RATE                => 8,
        ZMQ_RECOVERY_IVL        => 9,
        ZMQ_SNDBUF              => 11,
        ZMQ_RCVBUF              => 12,
        ZMQ_RCVMORE             => 13,
        ZMQ_FD                  => 14,
        ZMQ_EVENTS              => 15,
        ZMQ_TYPE                => 16,
        ZMQ_LINGER              => 17,
        ZMQ_RECONNECT_IVL       => 18,
        ZMQ_BACKLOG             => 19,
        ZMQ_RECONNECT_IVL_MAX   => 21,
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
        ZMQ_SNDMORE             => 2,
        ZMQ_POLLIN              => 1,
        ZMQ_POLLOUT             => 2,
        ZMQ_POLLERR             => 4,
        ZMQ_STREAMER            => 1,
        ZMQ_FORWARDER           => 2,
        ZMQ_QUEUE               => 3,
    );
}

use constant \%constants;
our @EXPORT;
our @EXPORT_OK = keys %constants;
our %EXPORT_TAGS = (
    socket => [ qw(
        ZMQ_PAIR
        ZMQ_PUB
        ZMQ_SUB
        ZMQ_REQ
        ZMQ_REP
        ZMQ_DEALER
        ZMQ_ROUTER
        ZMQ_PULL
        ZMQ_PUSH
        ZMQ_XPUB
        ZMQ_XSUB
        ZMQ_AFFINITY
        ZMQ_IDENTITY
        ZMQ_SUBSCRIBE
        ZMQ_UNSUBSCRIBE
        ZMQ_RATE
        ZMQ_RECOVERY_IVL
        ZMQ_SNDBUF
        ZMQ_RCVBUF
        ZMQ_RCVMORE
        ZMQ_FD
        ZMQ_EVENTS
        ZMQ_TYPE
        ZMQ_LINGER
        ZMQ_RECONNECT_IVL
        ZMQ_BACKLOG
        ZMQ_RECONNECT_IVL_MAX
        ZMQ_MAXMSGSIZE
        ZMQ_SNDHWM
        ZMQ_RCVHWM
        ZMQ_MULTICAST_HOPS
        ZMQ_RCVTIMEO
        ZMQ_SNDTIMEO
        ZMQ_IPV4ONLY
        ZMQ_LAST_ENDPOINT
        ZMQ_DONTWAIT
        ZMQ_SNDMORE
    ) ],
    message => [ qw(
        ZMQ_MORE
    ) ],
    poller => [ qw(
        ZMQ_POLLIN
        ZMQ_POLLOUT
        ZMQ_POLLERR
    ) ],
    device => [ qw(
        ZMQ_STREAMER
        ZMQ_FORWARDER
        ZMQ_QUEUE
    ) ],
);
$EXPORT_TAGS{all} = [ @EXPORT_OK ];

our $VERSION = '1.00';

our $DEFAULT_VERSION = '3.1.1';

our @CONSTANT_SETS;

sub add_constant {
    my (@args) = @_;
    require constant;
    constant->import({@args});
}

sub register_set {
    my ($version, @args) = @_;
    my $cb = (ref $version eq 'CODE') ? $version : sub { $version eq $_[0] };

    push @CONSTANT_SETS, ZMQ::Constant::Set->new(
        matcher => $cb,
        @args
    );
}

sub import {
    my $class = shift;

    my ($version, @args);
    foreach my $arg ( @_ ) {
        if ( $arg =~ /^:v(\d+\.\d+\.\d+$)/ ) {
            $version = $1;
        } else {
            push @args, $arg;
        }
    }

    $version ||= $DEFAULT_VERSION;
    my $klass = $version;
    $klass =~ s/\./_/g;
    $klass = "ZMQ::Constants::V$klass";
    eval "require $klass";
    if ($@) {
        Carp::croak($@);
    }

    foreach my $set ( @CONSTANT_SETS ) {
        next unless $set->match( $version );
        local %EXPORT_TAGS = (); # $set->get_tags;
        local @EXPORT_OK   = $set->get_export_oks;
        local @EXPORT      = $set->get_exports;
        $EXPORT_TAGS{all}  = [ sort @EXPORT_OK ];
        $class->export_to_level( 1, $class, @args );
        last;
    }
}

package
    ZMQ::Constant::Set;
use strict;

sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}

sub match {
    my ($self, $key) = @_;
    $self->{matcher}->($key);
}

sub get_tags {
    my $t =  $_[0]->{tags} || {};
    return wantarray ? %$t : $t;
}

sub get_export_oks {
    my $t = $_[0]->get_tags;
    local $t->{all};
    delete $t->{all};
    my %u = map { ($_ => 1) } map { @$_ } values %$t;
    my $l = [ keys %u ];
    return wantarray ? @$l : $l;
}

sub get_exports {
    my $l = $_[0]->{exports} || [];
    return wantarray ? @$l : $l;
}

1;

__END__

=head1 NAME

ZMQ::Constants - Constants for ZMQ

=head1 SYNOPSIS

    use ZMQ::Constants ':all'; # pulls in constants from $DEFAULT_VERSION
    use ZMQ::Constants ':v3.1.1', ':all'; # pulls in constants for 3.1.1
    use ZMQ::Constants ':v3.1.2', ':all'; # pulls in constants for 3.1.2

=head1 DESCRIPTION

libzmq is a fast-chanding beast and constants get renamed, new one gest
removed, etc... 

We used to auto-generate constants from the libzmq source code, but then
adpating the binding code to this change got very tedious, and controling
which version contains which constants got very hard to manage.

This module is now separate from ZMQ main code, and lists the constants
statically. You can also specify which set of constants to pull in depending
on the zmq version.

=head1 SUPPORTED VERSIONS

=over 4

=item libzmq 3.1.1

=item libzmq 3.1.2

Reintroduces ZMQ device related constants, and adds ZMQ_FAIL_UNROUTABLE

=back

If you would like to add more sets, please send in a pullreq

=cut
