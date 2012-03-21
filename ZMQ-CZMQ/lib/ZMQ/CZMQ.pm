package ZMQ::CZMQ;
use strict;
use Exporter 'import';
use XSLoader;
our $VERSION;
BEGIN {
    $VERSION = '1.1.0.1';
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

    $ctx = zctx_new();
    zctx_destroy( $ctx );
    zctx_set_iothreads( $ctx, $iothreads );
    zctx_set_linger( $ctx, $linger );

=cut
