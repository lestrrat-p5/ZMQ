use inc::Module::Install;

do "tools/detect.pl";

name 'ZMQ-CZMQ';
all_from 'lib/ZMQ/CZMQ.pm';

use_xshelper '-clean';
cc_warnings;
cc_include_paths split/\s+/, $ENV{CZMQ_INCLUDES};
cc_libs "$ENV{CZMQ_LIBS} -lzmq -lczmq";
cc_include_paths 'xs';
cc_src_paths 'xs';
cc_assert_lib 'zmq', 'czmq';

if ($ENV{CZMQ_VOID_RETURN_VALUES}) {
    cc_define qq{-DCZMQ_VOID_RETURN_VALUES};
}

do 'tools/genfiles.pl';

clean_files "xs/typemap", "xs/*.inc", "zmqinfo";

postamble(<<'EOM');
zmqinfo:
	$(CC) $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION)  $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) zmqinfo.c -o zmqinfo

gen_includes:
	$(FULLPERLRUN) tools/gen_versioned.pl > xs/versioned-xs.inc

EOM

auto_set_repository;
requires 'ZMQ::Constants';

WriteAll;

system $^X, "-i", "-pe", 's/pure_all :: config pm_to_blib subdirs linkext/pure_all :: zmqinfo gen_includes config pm_to_blib subdirs linkext/', 'Makefile';