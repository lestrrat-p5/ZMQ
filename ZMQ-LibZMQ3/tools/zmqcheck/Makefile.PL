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
    zmq_proxy       => 'zmq_proxy(NULL, NULL, NULL);',
    zmq_socket_monitor => 'zmq_socket_monitor(NULL, NULL, 0);',
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
	@$(CC) $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION)  $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(EXTRALIBS) %s.c -o %s >> zmqcheck.out 2>&1

EOM
}

sub MY::postamble { $postamble }

my @libs = map { 
    !/^-[Ll]/ ? "-l$_" : $_
} split /\s+/, $ENV{ZMQ_LIBS};
WriteMakefile(
    LIBS => \@libs,
    clean => {
        FILES => join(' ', "zmqcheck.out", map { ($_, "$_.c") } @functions),
    }
);