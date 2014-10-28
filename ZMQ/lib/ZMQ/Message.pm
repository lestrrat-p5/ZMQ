package ZMQ::Message;
use strict;
use Sub::Name ();

sub new {
    my $class = shift;
    my $msg = @_ == 1 ?
        ZMQ::call( "zmq_msg_init_data", @_ ) :
        ZMQ::call( "zmq_msg_init" )
    ;
    return $class->_wrap( $msg );
}

sub _wrap {
    my ($class, $msg) = @_;
    bless { _msg => $msg }, $class;
}

BEGIN {
    my %methods;
    foreach my $funcname ( qw(data size close) ) {
        $methods{$funcname} = sub {
            my ($self) = @_;
            ZMQ::call( "zmq_msg_$funcname", $self->{_msg} );
        };
    }

    foreach my $funcname ( qw(copy move) ) {
        $methods{$funcname} = sub {
            my ($dst, $src) = @_;
            ZMQ::call( "zmq_msg_$funcname", $dst->{_msg}, $src->{_msg} );
        };
    }

    foreach my $name (keys %methods) {
        no strict 'refs';
        *{$name} = Sub::Name::subname($name, $methods{$name});
    }
}

1;

__END__

=head1 NAME

ZMQ::Message - ZMQ Message Object

=head1 SYNOPSIS

    use ZMQ;

    my $msg  = ZMQ::Message->new( "Hello World!" );
    my $data = $msg->data();
    my $size = $msg->size();
    my $rv   = $msg->copy( $src );
    my $rv   = $msg->move( $src );
    my $rv   = $msg->close();

=head1 DESCRIPTION

A ZMQ::Context object represents a message to be passed over a ZMQ::Socket.

=head2 ZMQ::Message->new([ $msg ])

Creates a new message. If C<$msg> is passed, calls C<zmq_msg_init_data()>. Othewise C<zmq_msg_init()> is called

=head2 $msg->data()

Retrieves the data in message

=head2 $msg->size()

Retrieves the size of the data in message

=head2 $msg->copy( $src )

Copies contents of C<$src> to C<$msg>

=head2 $msg->move( $src )

Moves contents of C<$src> to C<$msg>

=head2 $msg->close()

Terminates and fress C<$msg>'s underlying data structure.

=cut
