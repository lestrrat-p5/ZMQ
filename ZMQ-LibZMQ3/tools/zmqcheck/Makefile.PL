use strict;
use ExtUtils::MakeMaker;

my $postamble = '';
my @functions = map { s/\.c$//; $_ } glob("*.c");
my %functions = (
    zmq_init        => 'zmq_init(0);',
    zmq_ctx_destroy => 'zmq_ctx_destroy(NULL);',
    zmq_ctx_get     => 'zmq_ctx_get(NULL, 0);',
    zmq_ctx_new     => 'zmq_ctx_new();',
    zmq_ctx_set     => 'zmq_ctx_set(NULL, 0, 0);',
    zmq_device      => 'zmq_device(0, NULL, NULL);',
    zmq_msg_recv    => 'zmq_msg_recv(NULL, NULL, 0);',
    zmq_msg_send    => 'zmq_msg_send(NULL, NULL, 0);',
    zmq_proxy       => 'zmq_proxy(NULL, NULL, NULL);',
    zmq_recvmsg     => 'zmq_recvmsg(NULL, NULL, 0);',
    zmq_socket_monitor => 'zmq_socket_monitor(NULL, NULL, 0);',
    zmq_sendmsg     => 'zmq_sendmsg(NULL, NULL, 0);',
    zmq_term        => 'zmq_term(NULL);',
    zmq_unbind      => 'zmq_unbind(NULL, NULL);',
);

# Create files
foreach my $func (keys %functions) {
    open my $fh, '>', "$func.c" or die "Failed to open file $func.c for writing: $!";
    printf $fh <<'EOM', $functions{$func};
#include "EXTERN.h"
#include "perl.h"
#include <zmq.h>

int main(int argc, char **argv)
{
    PERL_UNUSED_VAR(argc);
    PERL_UNUSED_VAR(argv);
    %s
}
EOM
    close($fh);
    
    $postamble .= sprintf <<'EOM', ($func) x 3;
%s:

	@$(CC) -c $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(EXTRALIBS) -std=c99 -pedantic-errors %s.c -o %s.o >> zmqcheck.out 2>&1

EOM
}

sub MY::postamble { $postamble }

WriteMakefile(
    VERSION => '0.01',
    INC  => join(' ', map { !/^-/ ? "-I$_" : $_ } split /\s+/, $ENV{ZMQ_INCLUDES}),
    LIBS => $ENV{ZMQ_LIBS},
    clean => {
        FILES => join(' ', "zmqcheck.out", map { ("$_.o", "$_.c") } @functions),
    }
);