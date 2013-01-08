use strict;
use ExtUtils::MakeMaker;

my @functions = qw(zmq_proxy zmq_device);

sub MY::postamble {
    my $postamble = '';
    foreach my $func (@functions) {
        $postamble .= sprintf <<'EOM', ($func) x 3;
%s:
	$(CC) $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION)  $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(EXTRALIBS) %s.c -o %s

EOM
    }
    return $postamble;
}

use Data::Dumper::Concise;
my @libs = map { 
    !/^-[Ll]/ ? "-l$_" : $_
} split /\s+/, $ENV{ZMQ_LIBS};
WriteMakefile(
    LIBS => \@libs,
    clean => {
        FILES => join(' ', @functions),
    }
);