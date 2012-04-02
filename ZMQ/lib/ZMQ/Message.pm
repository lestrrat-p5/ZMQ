package ZMQ::Message;
use strict;

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
    foreach my $funcname ( qw(data size close) ) {
        eval sprintf <<'EOM', $funcname, $funcname;
            sub %s {
                my ($self) = @_;
                ZMQ::call( "zmq_msg_%s", $self->{_msg} );
            }
EOM
        die if $@;
    }

    foreach my $funcname ( qw(copy move) ) {
        eval sprintf <<'EOM', $funcname, $funcname;
            sub %s {
                my ($dst, $src) = @_;
                ZMQ::call( "zmq_msg_%s", $dst->{_msg}, $src->{_msg} );
            }
EOM
        die if $@;
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
