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
    print STDERR "===> @_\n";
    system(@_) == 0 or die "Failed to execute @_: $!";
}

sub install_libzmq(@) {
    my ($basename, $opts) = @_;

    my $tail = $opts->{tail} || '';
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
    mysystem("./configure", "--prefix", $prefix, @{$opts->{extra_configure_args} ||[]});
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

sub install_libczmq {
    my $zmq_version = shift;

    print STDERR "===> Installing libczmq against zeromq-$zmq_version\n";
    install_libzmq("zeromq-$zmq_version");
    install_libzmq("czmq-1.3.2", {
        extra_configure_args => [
            sprintf('--with-libzmq=%s', File::Spec->catdir($EXTDIR, "zeromq-$zmq_version")),
        ]
    });
}

if ( $target eq 'ZMQ-Constants' ) {
    cpanm(qw(
        inc::Module::Install
        Module::Install::Repository
        Test::Requires
    ));
    test_binding("ZMQ-Constants");
} elsif ( $target eq 'ZMQ-CZMQ' ) {
    cpanm(qw(
        inc::Module::Install
        Module::Install::Repository
        Module::Install::XSUtil
        Module::Install::CheckLib
        Test::Requires
        Test::TCP
    ));
    foreach my $zmq_version( qw(2.2.0 3.2.2) ) {
        install_libczmq($zmq_version);
        $ENV{CZMQ_HOME} = File::Spec->catdir($EXTDIR, "czmq-1.3.2");
        cpanm(File::Spec->catdir($ROOT, "ZMQ-LibCZMQ1"));
        test_binding("ZMQ-CZMQ");
    }
} elsif ( $target eq 'ZMQ-LibCZMQ1' ) {
    cpanm(qw(
        inc::Module::Install
        Module::Install::Repository
        Module::Install::XSUtil
        Module::Install::CheckLib
        Test::Requires
        Test::TCP
    ));
    foreach my $zmq_version ( qw(2.2.0 3.2.2) ) {
        install_libczmq($zmq_version);
        $ENV{CZMQ_HOME} = File::Spec->catdir($EXTDIR, "czmq-1.3.2");
        test_binding("ZMQ-LibCZMQ1");
    }
} elsif ( $target eq 'ZMQ-LibZMQ2' ) {
    install_libzmq("zeromq-2.2.0");
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
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
        Module::Install::XSUtil
        Module::Install::Repository
    ));

    print STDERR "===\n\nTesting $target w/o optional dependencies...\n\n===\n";
    test_binding("ZMQ-LibZMQ3");
    print STDERR "===\n\nTesting $target with optional dependencies...\n\n===\n";
    cpanm(qw(AnyEvent Test::TCP Proc::Guard));
    test_binding("ZMQ-LibZMQ3");
} elsif ( $target eq 'ZMQ' ) {
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
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