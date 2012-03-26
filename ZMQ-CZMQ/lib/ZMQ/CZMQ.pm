package ZMQ::CZMQ;
use strict;
use Exporter 'import';
use XSLoader;
our $VERSION;
BEGIN {
    $VERSION = '1.00';
    XSLoader::load(__PACKAGE__, $VERSION);
}

our %EXPORT_OK = (
    zctx => [ qw(
        zctx_new
        zctx_destroy
        zctx_set_iothreads
        zctx_set_linger
    ) ],
    zsocket => [ qw(
        zsocket_new
        zsocket_destroy
        zsocket_bind
        zsocket_connect
    ) ],
    zstr => [ qw(
        zstr_send
        zstr_recv
        zstr_recv_nowait
        zstr_sendm
        zstr_sendf
    ) ]
);
our @EXPORT = map { @$_ } values %EXPORT_OK;

sub zstr_sendf {
    my ($socket, $fmt, @args) = @_;
    zstr_send( $socket, sprintf $fmt, @args );
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
    zmsg_pushmem( $msg, sprintf $fmt, @args );
}

sub zmsg_addstr {
    my ($msg, $fmt, @args) = @_;
    zmsg_addmem( $msg, sprintf $fmt, @args );
}

1;

=head1 NAME

ZMQ::CZMQ - Wrapper Around czmq high level ZMQ API

=head1 SYNOPSIS

    use ZMQ::CZMQ;

    my $ctx = zctx_new();
    zctx_destroy( $ctx );
    zctx_set_iothreads( $ctx, $iothreads );
    zctx_set_linger( $ctx, $linger );

=head1 DESCRIPTION

This is a wrapper around libczmq. 

=head1 FUNCTIONS

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

=head2 zmsg_add

=head2 zmsg_addmem

=head2 zmsg_addstr

=head2 zmsg_content_size

=head2 zmsg_decode

=head2 zmsg_destroy

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

=head2 zsocket_type_str

=head2 zsockopt_affinity

=head2 zsockopt_backlog

=head2 zsockopt_events

=head2 zsockopt_fd

=head2 zsockopt_hwm

=head2 zsockopt_linger

=head2 zsockopt_maxmsgsize

=head2 zsockopt_mcast_loop

=head2 zsockopt_rate

=head2 zsockopt_rcvbuf

=head2 zsockopt_rcvhwm

=head2 zsockopt_rcvmore

=head2 zsockopt_reconnect_ivl

=head2 zsockopt_reconnect_ivl_max

=head2 zsockopt_recovery_ivl

=head2 zsockopt_recovery_ivl_msec

=head2 zsockopt_set_affinity

=head2 zsockopt_set_backlog

=head2 zsockopt_set_hwm

=head2 zsockopt_set_identity

=head2 zsockopt_set_linger

=head2 zsockopt_set_maxmsgsize

=head2 zsockopt_set_mcast_loop

=head2 zsockopt_set_rate

=head2 zsockopt_set_rcvbuf

=head2 zsockopt_set_rcvhwm

=head2 zsockopt_set_reconnect_ivl

=head2 zsockopt_set_reconnect_ivl_max

=head2 zsockopt_set_recovery_ivl

=head2 zsockopt_set_recovery_ivl_msec

=head2 zsockopt_set_sndbuf

=head2 zsockopt_set_sndhwm

=head2 zsockopt_set_subscribe

=head2 zsockopt_set_swap

=head2 zsockopt_set_unsubscribe

=head2 zsockopt_sndbuf

=head2 zsockopt_sndhwm

=head2 zsockopt_swap

=head2 zsockopt_type

=head2 zstr_recv

=head2 zstr_recv_nowait

=head2 zstr_send

=head2 zstr_sendf

=head2 zstr_sendm

=cut
