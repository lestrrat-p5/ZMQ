package ZMQ::Poller;
use strict;

use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_PULL ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_POLLIN);

sub new {
    my ($class) = @_;
    my $self = bless {
        items => [],
    }, $class;
    return $self;
}

sub register {
    my ($self, $socket, $events) = @_;
    push @{$self->{items}}, { socket => $socket, events => $events };
    return;
}

sub unregister {
    my ($self, $socket) = @_;
    @{$self->{items}} = grep { !($_->{socket} == $socket) } @{$self->{items}};
    return;
}

sub _poll {
    my ($self, $items, $timeout) = @_;

    my @pollitems;
    
    for (@$items) {
        if (ref($_->{socket}) eq 'ZMQ::Socket') {
            push @pollitems, { socket => $_->{socket}{_socket}, events => $_->{events}, callback => sub {} };
        }
        elsif (ref($_->{socket}) eq 'ZMQ::LibZMQ2::Socket') {
            push @pollitems, { socket => $_->{socket}, events => $_->{events}, callback => sub {} };
        }
        elsif (ref($_->{socket}) eq 'ZMQ::LibZMQ3::Socket') {
            push @pollitems, { socket => $_->{socket}, events => $_->{events}, callback => sub {} };
        }
        elsif ($_->{socket} =~ m/^\d+$/) {
            push @pollitems, { fd => int($_->{socket}), events => $_->{events}, callback => sub {} };
        }
        else {
            die "Unknown type of socket";
        }
    }

    my @rv = zmq_poll(\@pollitems, $timeout);

    my @res;
    my $i = 0;
    for (@rv) {
        push @res, $items->[$i] if $rv[$i];
    }
    continue { $i++; }

    return @res;
}

sub poll {
    my ($self, $timeout) = @_;
    return $self->_poll($self->{items}, $timeout);
}

1;
