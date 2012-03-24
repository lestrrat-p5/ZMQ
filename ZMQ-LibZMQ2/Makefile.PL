BEGIN {
    if (-e '.git') {
        do 'tools/check_mi_mods.pl';
    } else {
        unshift @INC, 'inc';
        require inc::Module::Install;
        Module::Install->import;
    }
}

name 'ZMQ-LibZMQ2';

{ # M::I is silly about multiple authors:
    my $mainpm = 'lib/ZMQ/LibZMQ2.pm';
    name_from $mainpm;
    version_from $mainpm;
    perl_version_from $mainpm;
    license_from $mainpm;
    abstract_from $mainpm;
    author 'Daisuke Maki <daisuke@endeworks.jp>';
    author 'Steffen Mueller <smueller@cpan.org>';
}

do 'tools/detect_zmq.pl';
print "Detected the following ZMQ settings:\n";
foreach my $env (qw(ZMQ_HOME ZMQ_H ZMQ_INCLUDES ZMQ_LIBS ZMQ_TRACE)) {
    printf " + %s = %s\n", $env, exists $ENV{$env} ? $ENV{$env} : "(null)";
}

# XXX As of Devel::CheckLib 0.93, it seems like LIBS = "-L/path/to/foo"
# gets ignored (unlike what the docs say). So we manually strip and
# re-arrange the paths here
assertlibs
    lib => 'zmq',
    header => 'zmq.h',
    incpath => [ split /\s+/, $ENV{ZMQ_INCLUDES} ],
    libpath => [ grep { -d $_ } map { s/^-L//; $_ } split /\s+/, $ENV{ZMQ_LIBS} ]
;

auto_set_repository;
repository 'http://github.com/lestrrat/p5-ZMQ';
requires 'Task::Weaken';
requires 'ZMQ::Constants', '1.00';
test_requires 'Test::More', '0.98';
test_requires 'Test::TCP' => '1.08';
test_requires 'Test::Requires';
test_requires 'Test::Fatal';
recommends 'JSON' => '2.00';
use_xshelper '-clean';

use_ppport;
cc_warnings;
cc_include_paths split/\s+/, $ENV{ZMQ_INCLUDES};
cc_libs $ENV{ZMQ_LIBS};
cc_include_paths 'xs';
cc_src_paths 'xs';
cc_assert_lib 'zmq';
cc_libs 'zmq', 'uuid'; # uuid for cygwin, but can't hurt
if ($ENV{ZMQ_TRACE}) {
    cc_define qq|-DPERLZMQ_TRACE=$ENV{ZMQ_TRACE}|;
}

author_tests 'xt';
clean_files "xs/*.inc xs/typemap";

do 'tools/genfiles.pl';
WriteAll;