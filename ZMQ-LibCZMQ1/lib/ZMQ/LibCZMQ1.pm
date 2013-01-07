package ZMQ::LibCZMQ1;
use strict;
use Exporter 'import';
use XSLoader;
our $VERSION;
BEGIN {
    $VERSION = '1.03';
    XSLoader::load(__PACKAGE__, $VERSION);
}

our %EXPORT_TAGS = (
    zctx => [ qw(
        zctx_new
        zctx_destroy
        zctx_set_iothreads
        zctx_set_linger
        zctx_interrupted
    ) ],
    zsocket => [
        qw(
        zsocket_new
        zsocket_destroy
        zsocket_bind
        zsocket_connect
        zsocket_poll
        ),
        # These functions originally were named zsockopt_*
        # but have since been renamed in czmq. we now only
        # support these newer functions
        qw(
        zsocket_type
        zsocket_sndhwm
        zsocket_set_sndhwm
        zsocket_rcvhwm
        zsocket_set_rcvhwm
        zsocket_affinity
        zsocket_set_affinity
        zsocket_set_subscribe
        zsocket_set_unsubscribe
        zsocket_identity
        zsocket_set_identity
        zsocket_rate
        zsocket_set_rate
        zsocket_recovery_ivl
        zsocket_set_recovery_ivl
        zsocket_sndbuf
        zsocket_set_sndbuf
        zsocket_rcvbuf
        zsocket_set_rcvbuf
        zsocket_linger
        zsocket_set_linger
        zsocket_reconnect_ivl
        zsocket_set_reconnect_ivl
        zsocket_reconnect_ivl_max
        zsocket_set_reconnect_ivl_max
        zsocket_backlog
        zsocket_set_backlog
        zsocket_maxmsgsize
        zsocket_set_maxmsgsize
        zsocket_multicast_hops
        zsocket_set_multicast_hops
        zsocket_rcvtimeo
        zsocket_set_rcvtimeo
        zsocket_sndtimeo
        zsocket_set_sndtimeo
        zsocket_ipv4only
        zsocket_set_ipv4only
        zsocket_set_delay_attach_on_connect
        zsocket_set_router_mandatory
        zsocket_set_router_raw
        zsocket_set_xpub_verbose
        zsocket_rcvmore
        zsocket_fd
        zsocket_events
        zsocket_last_endpoint
        )
    ],
    zstr => [ qw(
        zstr_send
        zstr_recv
        zstr_recv_nowait
        zstr_send
        zstr_sendm
    ) ],
    zmsg => [ qw(
        zmsg_add
        zmsg_addmem
        zmsg_addstr
        zmsg_content_size
        zmsg_decode
        zmsg_destroy
        zmsg_dup
        zmsg_dump
        zmsg_encode
        zmsg_first
        zmsg_last
        zmsg_load
        zmsg_new
        zmsg_next
        zmsg_pop
        zmsg_popstr
        zmsg_push
        zmsg_pushmem
        zmsg_pushstr
        zmsg_recv
        zmsg_remove
        zmsg_save
        zmsg_send
        zmsg_size
        zmsg_unwrap
        zmsg_wrap
    ) ],
    zframe => [ qw(
        zframe_data
        zframe_destroy
        zframe_dup
        zframe_eq
        zframe_more
        zframe_new
        zframe_print
        zframe_recv
        zframe_recv_nowait
        zframe_reset
        zframe_send
        zframe_size
        zframe_strdup
        zframe_streq
        zframe_strhex
    ) ],
);
our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

sub zstr_send {
    my ($socket, $message, @args) = @_;
    if (@args) {
        $message = sprintf $message, @args;
    }
    _zstr_send( $socket, $message );
}

sub zsocket_bind {
    my ($socket, $address, @args) = @_;
    if (@args) {
        $address = sprintf $address, @args;
    }
    _zsocket_bind( $socket, $address );
}

sub zsocket_connect {
    my ($socket, $address, @args) = @_;
    if (@args) {
        $address = sprintf $address, @args;
    }
    _zsocket_connect( $socket, $address );
}

sub zmsg_pushstr {
    my ($msg, $fmt, @args) = @_;
    my $buf = sprintf $fmt, @args;
    zmsg_pushmem( $msg, $buf, length $buf );
}

sub zmsg_addstr {
    my ($msg, $fmt, @args) = @_;
    my $buf = sprintf $fmt, @args;
    zmsg_addmem( $msg, $buf, length $buf );
}

1;

=head1 NAME

ZMQ::LibCZMQ1 - Wrapper Around czmq high level ZMQ API

=head1 SYNOPSIS

    use ZMQ::LibCZMQ1;

    my $ctx = zctx_new();
    zctx_destroy( $ctx );
    zctx_set_iothreads( $ctx, $iothreads );
    zctx_set_linger( $ctx, $linger );

=head1 DESCRIPTION

This is a wrapper around libczmq (1.3.4). Versions prior to 1.3.4 have been
deliberately dropped off from the supported libczmq version (however,
patches are welcome)

=head1 FUNCTIONS

=head2 version()

In list context, returns 3 elements consisting of major version, minor version, and patch version.

In scalar context returns dotted version string.

=head2 zctx_destroy

=head2 zctx_interrupted

=head2 zctx_new

=head2 zctx_set_iothreads

=head2 zctx_set_linger

=head2 zframe_data

=head2 zframe_destroy

=head2 zframe_dup

=head2 zframe_eq

=head2 zframe_more

=head2 zframe_new

=head2 zframe_print

=head2 zframe_recv

=head2 zframe_recv_nowait

=head2 zframe_reset

=head2 zframe_send

=head2 zframe_size

=head2 zframe_strdup

=head2 zframe_streq

=head2 zframe_strhex

=head2 zframe_zero_copy

=head2 zmsg_add

=head2 zmsg_addmem

=head2 zmsg_addstr

=head2 zmsg_content_size

=head2 zmsg_decode

=head2 zmsg_destroy

=head2 zmsg_dump

=head2 zmsg_dup

=head2 zmsg_encode

=head2 zmsg_first

=head2 zmsg_last

=head2 zmsg_load

=head2 zmsg_new

=head2 zmsg_next

=head2 zmsg_pop

=head2 zmsg_popstr

=head2 zmsg_push

=head2 zmsg_pushmem

=head2 zmsg_pushstr

=head2 zmsg_recv

=head2 zmsg_remove

=head2 zmsg_save

=head2 zmsg_send

=head2 zmsg_size

=head2 zmsg_unwrap

=head2 zmsg_wrap

=head2 zsocket_bind

=head2 zsocket_connect

=head2 zsocket_destroy

=head2 zsocket_new

=head2 zsocket_poll

=head2 zsocket_type_str

=head2 zsocket_affinity

=head2 zsocket_backlog

=head2 zsocket_events

=head2 zsocket_fd

=head2 zsocket_hwm

=head2 zsocket_linger

=head2 zsocket_maxmsgsize

=head2 zsocket_mcast_loop (only in libzmq 2.x)

=head2 zsocket_rate

=head2 zsocket_rcvbuf

=head2 zsocket_rcvhwm

=head2 zsocket_rcvmore

=head2 zsocket_reconnect_ivl

=head2 zsocket_reconnect_ivl_max

=head2 zsocket_recovery_ivl

=head2 zsocket_recovery_ivl_msec

=head2 zsocket_set_affinity

=head2 zsocket_set_backlog

=head2 zsocket_set_hwm (only for libzmq 2.x)

=head2 zsocket_set_identity

=head2 zsocket_set_linger

=head2 zsocket_set_maxmsgsize

=head2 zsocket_set_mcast_loop (only in libzmq 2.x)

=head2 zsocket_set_rate

=head2 zsocket_set_rcvbuf

=head2 zsocket_set_rcvhwm

=head2 zsocket_set_reconnect_ivl

=head2 zsocket_set_reconnect_ivl_max

=head2 zsocket_set_recovery_ivl (only in libzmq 2.x)

=head2 zsocket_set_recovery_ivl_msec (only in libzmq 2.x)

=head2 zsocket_set_sndbuf

=head2 zsocket_set_sndhwm

=head2 zsocket_set_subscribe

=head2 zsocket_set_swap (only in libzmq 2.x)

=head2 zsocket_set_unsubscribe

=head2 zsocket_sndbuf

=head2 zsocket_sndhwm

=head2 zsocket_swap (only in libzmq 2.x)

=head2 zsocket_type

=head2 zstr_recv

=head2 zstr_recv_nowait

=head2 zstr_send

=head2 zstr_sendm

=cut
