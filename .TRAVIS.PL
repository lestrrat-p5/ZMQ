#!perl
use strict;
use Cwd ();
use File::Spec;

my $ROOT   = Cwd::abs_path( Cwd::cwd() );
my $EXTDIR = File::Spec->catdir($ROOT, "ext");
my $target = $ENV{PERL_ZMQ_TEST_TARGET} || 'ZMQ-LibZMQ2';

sub myguard::DESTROY {
    if ($_[0]->{code}) {
        $_[0]->{code}->();
    }
}
sub myguard(&) {
    bless { code => $_[0] }, 'myguard';
}

if (! -d $target) {
    die "$target does not exist";
}

sub mysystem(@) {
    system(@_) == 0 or die "Failed to execute @_: $!";
}

sub install_libzmq(@) {
    my ($basename, %opts) = @_;

    my $tail = $opts{tail} || '';
    my $prefix = File::Spec->catdir($EXTDIR, $basename);
    my $file   = "$basename$tail.tar.gz";
    if (! -e $file) {
        mysystem("curl", "-LO", "http://download.zeromq.org/$file");
    }
    if (! -e $basename) {
        mysystem("tar", "xzf", $file);
    }
    my $cwd = Cwd::abs_path();
    my $guard = myguard { chdir $cwd };
    chdir $basename;
    mysystem("./configure", "--prefix", $prefix, @{$opts{extra_configure_args} ||[]});
    mysystem("make");
    mysystem("make", "install");

    $ENV{ZMQ_HOME} = $prefix;
    return $prefix;
}

sub cpanm (@) {
    eval {
        mysystem("cpanm", "--notest", @_);
    };
    if (my $e = $@) {
        my $cpanm_log = "/home/travis/.cpanm/build.log";
        open my $fh, '<', $cpanm_log;
        while (<$fh>) {
            print;
        }
        die $e;
    }
}

sub test_binding {
    my $subdir = shift;
    my $cwd = Cwd::abs_path();
    my $guard = myguard { chdir $cwd };
    chdir File::Spec->catdir($ROOT, $subdir);
    cpanm("--installdeps", ".");
    mysystem("perl", "Makefile.PL");
    mysystem("make", "test");
}

sub setup_czmq {
    install_libzmq("zeromq-3.2.2");
    install_libzmq("czmq-1.3.2", {
        extra_configure_args => [
            '--with-libzmq' => File::Spec->catdir($EXTDIR, "zeromq-3.2.2")
        ]
    });
    cpanm(qw(
        inc::Module::Install
        Module::Install::Repository
        Module::Install::XSUtil
        Module::Install::CheckLib
        Test::Requires
        Test::TCP
    ));
}

if ( $target eq 'ZMQ-Constants' ) {
    cpanm(qw(
        inc::Module::Install
        Module::Install::Repository
        Test::Requires
    ));
    test_binding("ZMQ-Constants");
} elsif ( $target eq 'ZMQ-CZMQ' ) {
    setup_libczmq();
    $ENV{CZMQ_HOME} = File::Spec->catdir($EXTDIR, "czmq-1.3.2");
    cpanm(File::Spec->catdir($ROOT, "ZMQ-LibCZMQ1"));
    test_binding("ZMQ-CZMQ");
} elsif ( $target eq 'ZMQ-LibCZMQ1' ) {
    setup_czmq();
    $ENV{CZMQ_HOME} = File::Spec->catdir($EXTDIR, "czmq-1.3.2");
    test_binding("ZMQ-LibCZMQ1");
} elsif ( $target eq 'ZMQ-LibZMQ2' ) {
    install_libzmq("zeromq-2.2.0");
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::ReadmeFromPod
        Module::Install::XSUtil
        Module::Install::Repository
    ));
    test_binding("ZMQ-LibZMQ2");
    cpanm(qw(AnyEvent Proc::Guard));
    test_binding("ZMQ-LibZMQ2");
} elsif ( $target eq 'ZMQ-LibZMQ3' ) {
    install_libzmq("zeromq-3.2.2");
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::ReadmeFromPod
        Module::Install::XSUtil
        Module::Install::Repository
    ));
    test_binding("ZMQ-LibZMQ3");
    cpanm(qw(AnyEvent Proc::Guard));
    test_binding("ZMQ-LibZMQ3");
} elsif ( $target eq 'ZMQ' ) {
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::ReadmeFromPod
        Module::Install::XSUtil
        Module::Install::Repository
    ));
    $ENV{ZMQ_HOME} = install_libzmq("zeromq-2.2.0");
    cpanm(File::Spec->catdir($ROOT, "ZMQ-LibZMQ2"));
    $ENV{ZMQ_HOME} = install_libzmq("zeromq-3.2.2");
    cpanm(File::Spec->catdir($ROOT, "ZMQ-LibZMQ3"));

    $ENV{PERL_ZMQ_BACKEND} = "ZMQ::LibZMQ2";
    test_binding("ZMQ");
    $ENV{PERL_ZMQ_BACKEND} = "ZMQ::LibZMQ3";
    test_binding("ZMQ");
}