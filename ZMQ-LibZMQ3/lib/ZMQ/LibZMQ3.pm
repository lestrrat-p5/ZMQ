package ZMQ::LibZMQ3;
use strict;
use warnings;
use base qw(Exporter);
use XSLoader;
use ZMQ::Constants ();

BEGIN {
    our $VERSION = '1.08';
    XSLoader::load(__PACKAGE__, $VERSION);
}

our @EXPORT = qw(
    zmq_init
    zmq_term
    zmq_ctx_new
    zmq_ctx_destroy
    zmq_ctx_set
    zmq_ctx_get

    zmq_msg_send
    zmq_msg_recv

    zmq_msg_close
    zmq_msg_data
    zmq_msg_init
    zmq_msg_init_data
    zmq_msg_init_size
    zmq_msg_size
    zmq_msg_copy
    zmq_msg_move

    zmq_bind
    zmq_unbind
    zmq_close
    zmq_connect
    zmq_getsockopt
    zmq_recv
    zmq_recvmsg
    zmq_send
    zmq_sendmsg
    zmq_setsockopt
    zmq_socket
    zmq_socket_monitor

    zmq_poll

    zmq_device
    zmq_proxy
);

BEGIN {
    no warnings 'redefine';
    if (!HAS_ZMQ_INIT && HAS_ZMQ_CTX_NEW) {
        *zmq_init = \&zmq_ctx_new;
    }
    if (!HAS_ZMQ_TERM && HAS_ZMQ_CTX_DESTROY) {
        *zmq_term = \&zmq_ctx_destroy;
    }
}

sub zmq_msg_send {
    my $msg  = shift;
    my $sock = shift;
    if (!ref $msg) {
        my $wrap = zmq_msg_init_data($msg);
        if (! $wrap) {
            return ();
        }
        $msg = $wrap;
    }

    @_ = ($msg, $sock, @_);
    goto \&_zmq_msg_send;
}

sub zmq_sendmsg {
    my $sock = shift;
    my $msg  = shift;
    if (HAS_ZMQ_MSG_SEND) {
        # Delegate to zmq_msg_send
        @_ = ($msg, $sock, @_);
        goto \&zmq_msg_send;
    } else {
        if (!ref $msg) {
            my $wrap = zmq_msg_init_data($msg);
            if (! $wrap) {
                return ();
            }
            $msg = $wrap;
        }

        @_ = ($sock, $msg, @_);
        goto \&_zmq_sendmsg;
    }
}

sub zmq_getsockopt {
    my ($sock, $option) = @_;
    my $type = ZMQ::Constants::get_sockopt_type($option);
    if (! $type) {
        Carp::croak("zmq_getsockopt: Could not find the data type for option $option");
    }
    no strict 'refs';
    goto &{"zmq_getsockopt_$type"}
}

sub zmq_setsockopt {
    my ($sock, $option) = @_;
    my $type = ZMQ::Constants::get_sockopt_type($option);
    if (! $type) {
        Carp::croak("zmq_setsockopt: Could not find the data type for option $option");
    }
    no strict 'refs';
    goto &{"zmq_setsockopt_$type"}
}

1;

__END__

=head1 NAME

ZMQ::LibZMQ3 - A libzmq 3.x wrapper for Perl

=head1 SYNOPSIS

    use ZMQ::LibZMQ3;
    use ZMQ::Constants; # separate module

    my $ctxt = zmq_init($threads);
    my $rv   = zmq_term($ctxt);

    my $msg  = zmq_msg_init();
    my $msg  = zmq_msg_init_size( $size );
    my $msg  = zmq_msg_init_data( $data );
    my $rv   = zmq_msg_close( $msg );
    my $rv   = zmq_msg_move( $dest, $src );
    my $rv   = zmq_msg_copy( $dest, $src );
    my $data = zmq_msg_data( $msg );
    my $size = zmq_msg_size( $msg);

    my $sock = zmq_socket( $ctxt, $type );
    my $rv   = zmq_close( $sock );
    my $rv   = zmq_setsockopt( $socket, $option, $value );
    my $val  = zmq_getsockopt( $socket, $option );
    my $rv   = zmq_bind( $sock, $addr );
    my $rv   = zmq_send( $sock, $buffer, $length, $flags );
    my $msg  = zmq_sendmsg( $sock, $msg, $flags );
    my $rv   = zmq_recv( $sock, $buffer, $length, $flags );
    my $msg  = zmq_recvmsg( $sock, $flags );

=head1 INSTALLATION

If you have libzmq registered with pkg-config:

    perl Makefile.PL
    make 
    make test
    make install

If you don't have pkg-config, and libzmq is installed under /usr/local/libzmq:

    ZMQ_HOME=/usr/local/libzmq \
        perl Makefile.PL
    make
    make test
    make install

If you want to customize include directories and such:

    ZMQ_INCLUDES=/path/to/libzmq/include \
    ZMQ_LIBS=/path/to/libzmq/lib \
    ZMQ_H=/path/to/libzmq/include/zmq.h \
        perl Makefile.PL
    make
    make test
    make install

If you want to compile with debugging on:

    perl Makefile.PL -g

=head1 DESCRIPTION

The C<ZMQ::LibZMQ3> module is a wrapper of the 0MQ message passing library for Perl. 

Before you start using this module, please make sure you have read and understood the zguide.

    http://zguide.zeromq.org/page:all

For specifics on each function, please refer to their documentation for the definitive explanation of each.

    http://api.zeromq.org/

This module is merely a thin wrapper around the C API: You need to understand
how the C API works in order to properly use this module.

Note that this is a wrapper for libzmq 3.x. For 2.x, you need to check L<ZMQ::LibZMQ2>

=head1 BASIC USAGE

Please make sure you already have ZMQ::Constants module. If you installed ZMQ::LibZMQ3 from CPAN via cpan/cpanm, it should have already been installed for you. All socket types and other flags are declared in this module.

To start using ZMQ::LibZMQ3, you need to create a context object, then as many ZMQ::LibZMQ3::Socket obects as you need:

    my $ctxt = zmq_init;
    my $socket = zmq_socket( $ctxt, ... options );

You need to call C<zmq_bind()> or C<zmq_connect()> on the socket, depending on your usage. For example on a typical server-client model you would write on the server side:

    zmq_bind( $socket, "tcp://127.0.0.1:9999" );

and on the client side:

    zmq_connect( $socket, "tcp://127.0.0.1:9999" );

The underlying zeromq library offers TCP, multicast, in-process, and ipc connection patterns. Read the zeromq manual for more details on other ways to setup the socket.

When sending data, you can either pass a ZMQ::LibZMQ3::Message object or a Perl string. 

    # the following two send() calls are equivalent
    my $msg = zmq_msg_init_data( "a simple message" );
    zmq_sendmsg( $socket, $msg );
    
    zmq_sendmsg( $socket, "a simple message" ); 

In most cases using ZMQ::LibZMQ3::Message is redundunt, so you will most likely use the string version.

To receive, simply call C<zmq_recvmsg()> on the socket

    my $msg = zmq_recvmsg( $socket );

The received message is an instance of ZMQ::LibZMQ3::Message object, and you can access the content held in the message via the C<zmq_msg_data()> method:

    my $data = zmq_msg_data( $msg );

=head1 WHEN IN DOUBT

0MQ is a relatively large framework, and to use it you need to be comfortable
with a lot of concepts. If you think this module is not behaving like you
expect it to, I<please read the documents for the C API>

=head1 ASYNCHRONOUS I/O WITH ZEROMQ

By default 0MQ comes with its own zmq_poll() mechanism that can handle
non-blocking sockets. You can use this by calling zmq_poll with a list of
hashrefs:

    zmq_poll([
        {
            fd => fileno(STDOUT),
            events => ZMQ_POLLOUT,
            callback => \&callback,
        },
        {
            socket => $zmq_socket,
            events => ZMQ_POLLIN,
            callback => \&callback
        },
    ], $timeout );

Unfortunately this custom polling scheme doesn't play too well with AnyEvent.

Fortunately you can use getsockopt to retrieve the underlying file descriptor,
so use that to integrate ZMQ::LibZMQ3 and AnyEvent:

    my $socket = zmq_socket( $ctxt, ZMQ_REP );
    my $fh = zmq_getsockopt( $socket, ZMQ_FD );
    my $w; $w = AE::io $fh, 0, sub {
        while ( my $msg = zmq_recv( $socket, ZMQ_RCVMORE ) ) {
            # do something with $msg;
        }
        undef $w;
    };

=head1 NOTES ON MULTI-PROCESS and MULTI-THREADED USAGE

0MQ works on both multi-process and multi-threaded use cases, but you need
to be careful bout sharing ZMQ::LibZMQ3 objects.

For multi-process environments, you should not be sharing the context object.
Create separate contexts for each process, and therefore you shouldn't
be sharing the socket objects either.

For multi-thread environemnts, you can share the same context object. However
you cannot share sockets. Note that while the Perl Socket objects survive
between threads, their underlying C structures do not, and you will get an 
error if you try to use them between sockets.

=head1 FUNCTIONS

ZMQ::LibZMQ3 attempts to stick to the libzmq interface as much as possible. Unless there is a structural problem (say, an underlying poitner that the Perl binding expects was missing), no function should throw an exception.

Return values should resemble that of libzmq, except for when new data is allocated and returned to the user - That includes things like C<zmq_init()>, C<zmq_socket()>, C<zmq_msg_data()>, etc.

Where applicable, $! should be updated to match the value set by libzmq, so you should be able to do:

    my $cxt = zmq_init();
    if (! $cxt) {
        die "zmq_init() failed with $!";
    }

=head2 $errno = zmq_errno()

Returns the value of errno variable for the calling thread. You normally should not need to use this function. See the man page for zmq_errno() provided by libzmq.

=head2 $string = zmq_strerror( $errno )

Returns the string representation of C<$errno>. Use this to stringify errors that libzmq provides.

=head2 $cxt = zmq_init( $threads )

Creates a new context object. C<$threads> argument is optional.
Context objects can be reused across threads.

Returns undef upon error, and sets $!.

Note: Deprecated in libzmq, but the Perl binding will silently fallback to
using C<zmq_ctx_new()>, if available.

=head2 $cxt = zmq_ctx_new( $threads );

Creates a new context object. C<$threads> argument is optional.
Context objects can be reused across threads.

Returns undef upon error, and sets $!.

Note: may not be available depending on your libzmq version.

=head2 $rv = zmq_ctx_get( $cxt, $option )

Gets the value for the given option.

Returns -1 status upon failure, and sets $!

Note: may not be available depending on your libzmq version.

=head2 $rv = zmq_ctx_set( $cxt, $option, $value )

Sets the value for the given option.

Returns a non-zero status upon failure, and sets $!.

Note: may not be available depending on your libzmq version.

=head2 $rv = zmq_term( $cxt )

Terminates the context. Be careful, as it might hang if you have pending socket
operations. 

Returns a non-zero status upon failure, and sets $!.

Note: Deprecated in libzmq, but the Perl binding will silently fallback to
using C<zmq_ctx_destroy()>, if available.

=head2 $rv = zmq_ctx_destroy( $cxt )

Terminates the context. Be careful, as it might hang if you have pending socket
operations. 

Returns a non-zero status upon failure, and sets $!.

Note: may not be available depending on your libzmq version.

=head2 $socket = zmq_socket( $cxt, $socket_type )

Creates a new socket object. C<$socket_types> are constants declared in ZMQ::Constants. Sockets cannot be reused across threads.

Returns undef upon error, and sets $!.

=head2 $rv = zmq_bind( $sock, $address )

Binds the socket to listen to specified C<$address>.

Returns a non-zero status upon failure, and sets $!

=head2 $rv = zmq_unbind( $sock, $address )

Stops listening on this endpoint.

Returns a non-zero status upon failure, and sets $!

Note: may not be available depending on your libzmq version.

=head2 $rv = zmq_connect( $sock, $address )

Connects the socket to specified C<$address>.

Returns a non-zero status upon failure, and sets $!

=head2 $rv = zmq_close( $sock )

Closes the socket explicitly.

Returns a non-zero status upon failure, and sets $!.

=head2 $value = zmq_getsockopt( $socket, $option )

Gets the value of the specified option.

If the particular version of ZMQ::LibZMQ3 does not implement the named socket option, an exception will be thrown:

    /* barfs, because we don't know what type this new option is */
    zmq_getsockopt( $socket, ZMQ_NEW_SHINY_OPTION );
    
In this case you can either use ZMQ::Constants, or you can use one of the utility functions that ZMQ::LibZMQ3 provides.

=over 4

=item Using ZMQ::Constants

ZMQ::LibZMQ3 internally refers to ZMQ::Constants to learn about the type of a
socket option. You can easily add new constants to this map:

    use ZMQ::Constants;
    ZMQ::Constants::add_sockopt_type( "int" => ZMQ_NEW_SHINY_OPTION );

    # Then elsewhere...
    my $value = zmq_getsockopt( $socket, ZMQ_NEW_SHINY_OPTION );

=item Using utilities in ZMQ::LibZMQ3

    /* say you know that the value is an int, int64, uint64, or char *
       by reading the zmq docs */
    $int    = zmq_getsockopt_int( $socket, ZMQ_NEW_SHINY_OPTION );
    $int64  = zmq_getsockopt_int64( $socket, ZMQ_NEW_SHINY_OPTION );
    $uint64 = zmq_getsockopt_uint64( $socket, ZMQ_NEW_SHINY_OPTION );
    $string = zmq_getsockopt_string( $socket, ZMQ_NEW_SHINY_OPTION );

=back

=head2 $status = zmq_setsockopt( $socket, $option, $value )

Sets the value of the specified option. Returns the status.

See C<zmq_getsockopt()> if you have problems with ZMQ::LibZMQ3 not knowing the type of the option.

=head2 $bytes = zmq_send($sock, $buffer, $size, $flags)

Queues C<$size> bytes from C<$buffer> to be sent from the socket. Argument C<$flags> may be omitted. If C<$size> is -1, then the size of the buffer calcualted via C<SvPV()> will be used.

Returns the number of bytes sent on success (which should be exact C<$size>)

Returns -1 upon failure, and sets $!.

=head2 $rv = zmq_sendmsg($sock, $message, $flags)

Queues C<$message> to be sent via C<$sock>. Argument C<$flags> may be omitted.

If C<$message> is a non-ref, creates a new ZMQ::LibZMQ3::Message object via C<zmq_msg_init_data()>, and uses that to pass to the underlying C layer..

Returns the number of bytes sent on success (which should be exact C<$size>)

Returns -1 upon failure, and sets $!.

Note: Deprecated in favor of C<zmq_msg_send()>, and may not be available depending on your libzmq version.

=head2 $rv = zmq_msg_send($message, $sock, $flags)

Queues C<$message> to be sent via C<$sock>. Argument C<$flags> may be omitted.

If C<$message> is a non-ref, creates a new ZMQ::LibZMQ3::Message object via C<zmq_msg_init_data()>, and uses that to pass to the underlying C layer..

Returns the number of bytes sent on success (which should be exact C<$size>)

Returns -1 upon failure, and sets $!.

Note: may not be available depending on your libzmq version.

=head2 $rv = zmq_recv($sock, $buffer, $len, $flags)

Receives a new message from C<$sock>, and store the message payload in C<$buffer>, up to C<$len> bytes. Argument C<$flags> may be omitted.

Returns the number of bytes in the I<original> message, which may exceed C<$len> (if you have C<$rv> E<gt> C<$len>, then the message was truncated).

Returns -1 upon failure, and sets $!.

=head2 $message = zmq_recvmsg($sock, $flags)

Receives a new message from C<$sock>. Argument C<$flags> may be omitted.
Returns the message object.

Returns undef upon failure, and sets $!.

Note: Although this function is marked as deprecated in libzmq3, it will
stay in the Perl binding as the official short-circuit version of
C<zmq_msg_recv()>, so that you don't have to create a message object
every time.

=head2 $rv = zmq_msg_recv($msg, $sock, $flags)

Receives a new message from C<$sock>, and writes the new content to C<$msg>.
Argument C<$flags> may be omitted. Returns 0 upon succes, -1 on failure and
sets $!.

Other than the fact that libzmq has deprecated C<zmq_recvmsg()>, this
construct is useful if you don't want to allocate a message struct for
every recv call:

    my $msg = zmq_msg_init();
    while (1) {
        my $rv = zmq_msg_recv($msg, $sock, $flags);
        ...
    }

Note: may not be available depending on your libzmq version

=head2 $msg = zmq_msg_init()

Creates a new message object.

Returns undef upon failure, and sets $!.

=head2 $msg = zmq_msg_init_data($string)

Creates a new message object, and sets the message payload to the string in C<$string>.

Returns undef upon failure, and sets $!.

=head2 $msg = zmq_msg_init_size($size)

Creates a new message object, allocating C<$size> bytes. This call isn't so useful from within Perl

Returns undef upon failure, and sets $!.

=head2 $string = zmq_msg_data( $msg )

Returns the payload contained in C<$msg>

=head2 $size = zmq_msg_size( $msg )

Returns the size of payload contained in C<$msg>

=head2 zmq_msg_copy( $dst, $src )

Copies contents of C<$src> to C<$dst>.

Returns a non-zero status upon failure, and sets $!.

=head2 zmq_msg_move( $dst, $src )

Moves contents of C<$src> to C<$dst>

Returns a non-zero status upon failure, and sets $!.

=head2 $rv = zmq_msg_close( $msg )

Closes, cleans up the message.

Returns a non-zero status upon failure, and sets $!.

=head2 $rv = zmq_poll( \@pollitems, $timeout )

C<@pollitems> are list of hash references containing the following elements:

=over 4

=item fd or socket

One of either C<fd> or C<socket> key must exist. C<fd> should contain a UNIX file descriptor. C<socket> should contain a C<ZMQ::LibZMQ3::Socket> socket object.

=item events

A bit mask containing C<ZMQ_POLLOUT>, C<ZMQ_POLLIN>, C<ZMQ_POLLERR> or combination there of.

=item callback

A subroutine reference, which will be called without arguments when the socket or descriptor is available.

=back

In scalar context, returns the return value of zmq_poll() in the C layer, and sets $!.

    my $rv = zmq_poll( .... ); # do scalar(zmq_poll(...)) if you're nuerotic
    if ( $rv == -1 ) {
        warn "zmq_poll failed: $!";
    }

In list context, return a list containing as many booleans as there are 
elements in C<@pollitems>.
These booleans indicate whether the socket in question has fired the callback.

    my @pollitems = (...);
    my @fired     = zmq_poll( @pollitems ... );
    for my $i ( 0 .. $#pollitems ) {
        my $fired = $fired[$i];
        if ( $fired ) {
            my $item = $pollitems[$i];
            ...
        }
    }

=head2 zmq_version()

Returns the version of the underlying zeromq library that is being linked.
In scalar context, returns a dotted version string. In list context,
returns a 3-element list of the version numbers:

    my $version_string = ZMQ::LibZMQ3::zmq_version();
    my ($major, $minor, $patch) = ZMQ::LibZMQ3::zmq_version();

=head2 zmq_device($type, $sock1, $sock2)

Creates a new "device". See C<zmq_device> for details. zmq_device() will only return if/when the current context is closed. Therefore, the return value is always -1, and errno is always ETERM

Note: may not be available depending on your libzmq version.

=head2 zmq_proxy($frontend_sock, $backend_sock, $capture_sock)

WARNING: EXPERIMENTAL. Use at your own risk.

Start a proxy in the current thread, which connects the frontend socket to a
backend socket. The capture sock is optional, and is by default undef.

Note: may not be available depending on your libzmq version.

=head2 $rv = zmq_socket_monitor($socket, $addr, events)

Note: may not be available depending on your libzmq version.

=head1 FUNCTIONS PROVIDED BY ZMQ::LIBZMQ3

These functions are provided by ZMQ::LibZMQ3 to make some operations easier in the Perl binding. They are not part of the official libzmq interface.

=head2 $value = zmq_getsockopt_int( $sock, $option )

=head2 $value = zmq_getsockopt_int64( $sock, $option )

=head2 $value = zmq_getsockopt_string( $sock, $option )

=head2 $value = zmq_getsockopt_uint64( $sock, $option )

=head2 $rv = zmq_setsockopt_int( $sock, $option, $value );

=head2 $rv = zmq_setsockopt_int64( $sock, $option, $value );

=head2 $rv = zmq_setsockopt_string( $sock, $option, $value );

=head2 $rv = zmq_setsockopt_uint64( $sock, $option, $value );

=head1 DEBUGGING XS

If you see segmentation faults, and such, you need to figure out where the error is occuring in order for the maintainers to figure out what happened. Here's a very very brief explanation of steps involved.

First, make sure to compile C<ZMQ::LibZMQ3> with debugging on by specifying -g:

    perl Makefile.PL -g
    make

Then fire gdb:

    gdb perl
    (gdb) R -Mblib /path/to/your/script.pl

When you see the crash, get a backtrace:

    (gdb) bt

=head1 CAVEATS

This is an early release. Proceed with caution, please report
(or better yet: fix) bugs you encounter.

This module has been tested againt B<zeromq 3.2.2>. Semantics of this
module rely heavily on the underlying zeromq version. Make sure
you know which version of zeromq you're working with.

As of 1.04 some new constants have been added, but they are not really
meant to be used by consumers of this module. If you find yourself
looking at these, please let us know why you need to use it -- we'll see
if we can find a workaround, or make these constants public.

=head1 SEE ALSO

L<http://zeromq.org>

L<http://github.com/lestrrat/p5-ZMQ>

L<ZMQ::Constants>

L<ZMQ::LibZMQ2>

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

Steffen Mueller, C<< <smueller@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

The ZMQ::LibZMQ3 module is

Copyright (C) 2010 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
