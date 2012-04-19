package ZMQ::LibZMQ2;
use strict;
use base qw(Exporter);
use XSLoader;
use ZMQ::Constants ();

BEGIN {
    our $VERSION = '1.00';
    XSLoader::load(__PACKAGE__, $VERSION);
}

our @EXPORT = qw(
    zmq_init
    zmq_term

    zmq_msg_close
    zmq_msg_data
    zmq_msg_init
    zmq_msg_init_data
    zmq_msg_init_size
    zmq_msg_size
    zmq_msg_copy
    zmq_msg_move

    zmq_bind
    zmq_close
    zmq_connect
    zmq_getsockopt
    zmq_recv
    zmq_send
    zmq_setsockopt
    zmq_socket

    zmq_poll

    zmq_device
);

sub zmq_send {
    my $sock = shift;
    my $msg  = shift;
    if (!ref $msg) {
        my $wrap = zmq_msg_init_data($msg);
        if (! $wrap) {
            return ();
        }
        $msg = $wrap;
    }

    @_ = ($sock, $msg, @_);
    goto \&_zmq_send;
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

sub ZMQ::LibZMQ2::Socket::CLONE_SKIP { 1 } 

1;

__END__

=head1 NAME

ZMQ::LibZMQ2 - A libzmq 2.x wrapper for Perl

=head1 SYNOPSIS

    use ZMQ::LibZMQ;

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
    my $rv   = zmq_send( $sock, $msg, $flags );
    my $msg  = zmq_recv( $sock, $flags );

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

The C<ZMQ::LibZMQ2> module is a wrapper of the 0MQ message passing library for Perl. 
It's a thin wrapper around the C API. Please read L<http://zeromq.org> for
more details on 0MQ.

Note that this is a wrapper for libzmq 2.x. For 3.x, you need to check L<ZMQ::LibZMQ3>

=head1 BASIC USAGE

To start using ZMQ::LibZMQ2, you need to create a context object, then as many ZMQ::LibZMQ2::Socket obects as you need:

    my $ctxt = zmq_init;
    my $socket = zmq_socket( $ctxt, ... options );

You need to call C<zmq_bind()> or C<zmq_connect()> on the socket, depending on your usage. For example on a typical server-client model you would write on the server side:

    zmq_bind( $socket, "tcp://127.0.0.1:9999" );

and on the client side:

    zmq_connect( $socket, "tcp://127.0.0.1:9999" );

The underlying zeromq library offers TCP, multicast, in-process, and ipc connection patterns. Read the zeromq manual for more details on other ways to setup the socket.

When sending data, you can either pass a ZMQ::LibZMQ2::Message object or a Perl string. 

    # the following two send() calls are equivalent
    my $msg = zmq_msg_init_data( "a simple message" );
    zmq_send( $socket, $msg );
    
    zmq_send( $socket, "a simple message" ); 

In most cases using ZMQ::LibZMQ2::Message is redundunt, so you will most likely use the string version.

To receive, simply call C<zmq_recv()> on the socket

    my $msg = zmq_recv( $socket );

The received message is an instance of ZMQ::LibZMQ2::Message object, and you can access the content held in the message via the C<data()> method:

    my $data = zmq_msg_data( $msg );

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

As of zeromq2-2.1.0, you can use getsockopt to retrieve the underlying file
descriptor, so use that to integrate ZMQ::LibZMQ2 and AnyEvent:

    my $socket = zmq_socket( $ctxt, ZMQ_REP );
    my $fh = zmq_getsockopt( $socket, ZMQ_FD );
    my $w; $w = AE::io $fh, 0, sub {
        while ( my $msg = zmq_recv( $socket, ZMQ_RCVMORE ) ) {
            # do something with $msg;
        }
        undef $w;
    };

Returns undef on error (and sets $! in that case). Returns an array reference
containing as many booleans as there are elements in C<@list_of_hashrefs>.
These booleans indicate whether the socket in question has fired the callback.

=head1 NOTES ON MULTI-PROCESS and MULTI-THREADED USAGE

0MQ works on both multi-process and multi-threaded use cases, but you need
to be careful bout sharing ZMQ::LibZMQ2 objects.

For multi-process environments, you should not be sharing the context object.
Create separate contexts for each process, and therefore you shouldn't
be sharing the socket objects either.

For multi-thread environemnts, you can share the same context object. However
you cannot share sockets.

=head1 FUNCTIONS

ZMQ::LibZMQ2 attempts to stick to the libzmq interface as much as possible. Unless there is a structural problem (say, an underlying poitner that the Perl binding expects was missing), no function should throw an exception.

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

=head2 $rv = zmq_term( $cxt )

Terminates the context. Be careful, as it might hang if you have pending socket
operations. 

Returns a non-zero status upon failure, and sets $!.

=head2 $socket = zmq_socket( $cxt, $socket_type )

Creates a new socket object. C<$socket_types> are constants declared in ZMQ::Constants. Sockets cannot be reused across threads.

Returns undef upon error, and sets $!.

C<ZMQ::LibZMQ2::Socket> objects aren't thread safe due to the underlying 
library.  Therefore, they are currently not cloned when a new Perl ithread is
spawned. The variables in the new thread that contained the socket in the 
parent thread will be a scalar reference to C<undef> in the new thread.
This makes the Perl wrapper thread safe (i.e. no segmentation faults).T

=head2 $rv = zmq_bind( $sock, $address )

Binds the socket to listen to specified C<$address>.

Returns a non-zero status upon failure, and sets $!

=head2 $rv = zmq_connect( $sock, $address )

Connects the socket to specified C<$address>.

Returns a non-zero status upon failure, and sets $!

=head2 $rv = zmq_close( $sock )

Closes the socket explicitly.

Returns a non-zero status upon failure, and sets $!.

=head2 $value = zmq_getsockopt( $socket, $option )

Gets the value of the specified option.

If the particular version of ZMQ::LibZMQ2 does not implement the named socket option, an exception will be thrown:

    /* barfs, because we don't know what type this new option is */
    zmq_getsockopt( $socket, ZMQ_NEW_SHINY_OPTION );
    
In this case you can either use ZMQ::Constants, or you can use one of the utility functions that ZMQ::LibZMQ2 provides.

=over 4

=item Using ZMQ::Constants

ZMQ::LibZMQ2 internally refers to ZMQ::Constants to learn about the type of a
socket option. You can easily add new constants to this map:

    use ZMQ::Constants;
    ZMQ::Constants::add_sockopt_type( "int" => ZMQ_NEW_SHINY_OPTION );

=item Using utilities in ZMQ::LibZMQ2

You need to know which socket options are integers, which are strings, etc, to manipulate the socket options. Choose the right one from the following helpers that ZMQ::LibZMQ2 provides (they are not part of the libzmq interface)

    /* say you know that the value is an int, int64, uint64, or char *
       by reading the zmq docs */
    $int    = zmq_getsockopt_int( $socket, ZMQ_NEW_SHINY_OPTION );
    $int64  = zmq_getsockopt_int64( $socket, ZMQ_NEW_SHINY_OPTION );
    $uint64 = zmq_getsockopt_uint64( $socket, ZMQ_NEW_SHINY_OPTION );
    $string = zmq_getsockopt_string( $socket, ZMQ_NEW_SHINY_OPTION );

Corresponding C<zmq_setsockopt_*> functions should also exist.

=back

=head2 $status = zmq_setsockopt( $socket, $option, $value )

Sets the value of the specified option. Returns the status.

See C<zmq_getsockopt()> if you have problems with ZMQ::LibZMQ2 not knowing the type of the option.

=head2 $rv = zmq_send($sock, $message, $flags)

Sends C<$message> via C<$sock>. Argument C<$flags> may be omitted.

If C<$message> is a non-ref, creates a new ZMQ::LibZMQ2::Message object via C<zmq_msg_init_data()>, and uses that to pass to the underlying C layer..

Returns a non-zero status upon failure, and sets $!.

=head2 $message = zmq_recv($sock, $flags)

Receives a new message from C<$sock>. Argument C<$flags> may be omitted.

Returns undef upon failure, and sets $!.

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

One of either C<fd> or C<socket> key must exist. C<fd> should contain a UNIX file descriptor. C<socket> should contain a C<ZMQ::LibZMQ2::Socket> socket object.

=item events

A bit mask containing C<ZMQ_POLLOUT>, C<ZMQ_POLLIN>, C<ZMQ_POLLERR> or combination there of.

=item callback

A subroutine reference, which will be called without arguments when the socket or descriptor is available.

=back

=head2 zmq_version()

Returns the version of the underlying zeromq library that is being linked.
In scalar context, returns a dotted version string. In list context,
returns a 3-element list of the version numbers:

    my $version_string = ZMQ::LibZMQ2::zmq_version();
    my ($major, $minor, $patch) = ZMQ::LibZMQ2::zmq_version();

=head2 $rv = zmq_device($type, $sock1, $sock2)

Creates a new "device". See C<zmq_device> for details. zmq_device() will only return if/when the current context is closed. Therefore, the return value is always -1, and errno is always ETERM

=head1 FUNCTIONS PROVIDED BY ZMQ::LIBZMQ2

These functions are provided by ZMQ::LibZMQ2 to make some operations easier in the Perl binding. They are not part of the official libzmq interface.

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

First, make sure to compile C<ZMQ::LibZMQ2> with debugging on by specifying -g:

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

This module has been tested againt B<zeromq 2.1.11>. Semantics of this
module rely heavily on the underlying zeromq version. Make sure
you know which version of zeromq you're working with.

=head1 SEE ALSO

L<http://zeromq.org>

L<http://github.com/lestrrat/p5-ZMQ>

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

Steffen Mueller, C<< <smueller@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

The ZMQ::LibZMQ2 module is

Copyright (C) 2010 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
