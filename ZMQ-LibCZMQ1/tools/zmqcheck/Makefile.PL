use strict;
use ExtUtils::MakeMaker;

my $postamble = '';
my @functions = map { s/\.c$//; $_ } glob("*.c");
my %functions = (
    zsocket_hwm                   => 'zsocket_hwm(NULL);',
    zsocket_maxmsgsize            => 'zsocket_maxmsgsize(NULL);',
    zsocket_mcast_loop            => 'zsocket_mcast_loop(NULL);',
    zsocket_rcvhwm                => 'zsocket_rcvhwm(NULL);',
    zsocket_recovery_ivl_msec     => 'zsocket_recovery_ivl_msec(NULL);',
    zsocket_sndhwm                => 'zsocket_sndhwm(NULL);',
    zsocket_set_maxmsgsize        => 'zsocket_set_maxmsgsize(NULL, 0);',
    zsocket_set_mcast_loop        => 'zsocket_set_mcast_loop(NULL, 0);',
    zsocket_set_rcvhwm            => 'zsocket_set_rcvhwm(NULL, 0);',
    zsocket_set_recovery_ivl_msec => 'zsocket_set_recovery_ivl_msec(NULL, 0);',
    zsocket_set_sndhwm            => 'zsocket_set_sndhwm(NULL, 0);',
    zsocket_set_swap              => 'zsocket_set_swap(NULL, 0);',
    zsocket_swap                  => 'zsocket_swap(NULL);',
);

# Create files
foreach my $func (keys %functions) {
    open my $fh, '>', "$func.c" or die "Failed to open file $func.c for writing: $!";
    printf $fh <<'EOM', $functions{$func};
#include "EXTERN.h"
#include "perl.h"
#include "czmq.h"

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

	@$(CC) -c $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(EXTRALIBS) -pedantic-errors %s.c -o %s.o >> zmqcheck.out 2>&1

EOM
}

sub MY::postamble { $postamble }

WriteMakefile(
    VERSION => '0.01',
    INC  => join(' ', map { !/^-/ ? "-I$_" : $_ } split /\s+/, $ENV{CZMQ_INCLUDES}),
    LIBS => $ENV{CZMQ_LIBS},
    clean => {
        FILES => join(' ', "zmqcheck.out", map { ("$_.o", "$_.c") } @functions),
    }
);