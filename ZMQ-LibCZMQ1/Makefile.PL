use inc::Module::Install;

do "tools/detect.pl";

name 'ZMQ-LibCZMQ1';
all_from 'lib/ZMQ/LibCZMQ1.pm';

use_xshelper '-clean';
cc_warnings;
cc_include_paths split/\s+/, $ENV{CZMQ_INCLUDES};
cc_libs "$ENV{CZMQ_LIBS} -lzmq -lczmq";
cc_include_paths 'src';
cc_src_paths 'src';
cc_assert_lib 'zmq', 'czmq';

if ($ENV{CZMQ_VOID_RETURN_VALUES}) {
    cc_define qq{-DCZMQ_VOID_RETURN_VALUES};
}

do 'tools/genfiles.pl';

clean_files "src/typemap", "src/*.inc", "zmqinfo";

postamble(<<'EOM');
zmqinfo:
	$(CC) $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION)  $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) zmqinfo.c -o zmqinfo

EOM

auto_set_repository;
requires 'ZMQ::Constants';

WriteAll;

system $^X, "-i", "-pe", 's/pure_all :: config pm_to_blib subdirs linkext/pure_all :: zmqinfo config pm_to_blib subdirs linkext/', 'Makefile';