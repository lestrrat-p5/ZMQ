package ZMQ::CZMQ::Zsocket;
use warnings;
use strict;
use ZMQ::CZMQ;
use Scalar::Util ();

sub _wrap {
    my $class = shift;
    bless { _socket => $_[0] }, $class;
}

# Oh why, oh why did you name zsocket_destroy and
# yet you made the first argument zctx_t, not zsocket_t?
sub destroy {
    my ($self, $ctx) = @_;
    $ctx->socket_destroy($self);
}

BEGIN {
    foreach my $method (qw(
        bind
        connect
        disconnect
        poll
        type_str
        type
    )) {
        eval <<EOM;
            sub $method {
                my \$self = shift;
                ZMQ::CZMQ::call("zsocket_$method", \$self->{_socket}, \@_);
            }
EOM
        die if $@;
    }

    # These socket options are both getters and setters
    foreach my $method (qw(
        affinity
        backlog
        events
        fd
        identity
        ipv4only
        last_endpoint
        linger
        maxmsgsize
        multicast_hops
        rate
        rcvbuf
        rcvhwm
        rcvmore
        rcvtimeo
        reconnect_ivl
        reconnect_ivl_max
        recovery_ivl
        sndbuf
        sndhwm
        sndtimeo
    )) {
        eval <<EOM;
            sub $method {
                my \$self = shift;
                return \@_ ?
                    ZMQ::CZMQ::call("zsocket_set_$method", \$self->{_socket}, \@_) :
                    ZMQ::CZMQ::call("zsocket_$method", \$self->{_socket});
                ;
            }
EOM
        die if $@;
    }
}

sub send {
    my $self = shift;
    my $thing = shift;

    my $klass = Scalar::Util::blessed($thing);
    if (! $klass) { # 
        return ZMQ::CZMQ::call("zstr_send", $self->{_socket}, $thing, @_);
    } else {
        return $thing->send($self);
    }
}

sub sendm {
    my $self = shift;
    return ZMQ::CZMQ::call("zstr_sendm", $self->{_socket}, @_);
}

1;

__END__

=head1 NAME

ZMQ::CZMQ::Zsocket - Wrapper Around zsocket_t

=head1 SYNOPSIS

    use ZMQ::CZMQ;
    use ZMQ::Constants (ZMQ_REQ);

    my $ctx = ZMQ::CZMQ::Ctx->new;
    my $sock = $ctx->socket(ZMQ_REQ);
    $sock->bind($endpoint);
    $sock->connect($endpoint);
    $sock->disconnect;
    $sock->poll($msecs);
    $sock->type_str;
    $sock->destroy($ctx);

    # send() is overloaded
    $sock->send($msg);
    $sock->send($frame);
    $sock->send($fmt, ...);

    $sock->sendm($fmt, ...);

    # sockopts are very much dependent on the underlying
    # libzmq version: don't just trust this list

    # If you pass an argument, you can set values
    $sock->affinity()
    $sock->backlog()
    $sock->events()
    $sock->fd()
    $sock->identity()
    $sock->ipv4only()
    $sock->last_endpoint()
    $sock->linger()
    $sock->maxmsgsize()
    $sock->multicast_hops()
    $sock->rate()
    $sock->rcvbuf()
    $sock->rcvhwm()
    $sock->rcvmore()
    $sock->rcvtimeo()
    $sock->reconnect_ivl()
    $sock->reconnect_ivl_max()
    $sock->recovery_ivl()
    $sock->sndbuf()
    $sock->sndhwm()
    $sock->sndtimeo()

=head1 METHODS

=head2 affinity

=head2 backlog

=head2 bind

=head2 connect

=head2 destroy

=head2 disconnect

=head2 events

=head2 fd

=head2 identity

=head2 ipv4only

=head2 last_endpoint

=head2 linger

=head2 maxmsgsize

=head2 multicast_hops

=head2 poll

=head2 rate

=head2 rcvbuf

=head2 rcvhwm

=head2 rcvmore

=head2 rcvtimeo

=head2 reconnect_ivl

=head2 reconnect_ivl_max

=head2 recovery_ivl

=head2 send

=head2 sendm

=head2 sndbuf

=head2 sndhwm

=head2 sndtimeo

=head2 type

=head2 type_str

=cut