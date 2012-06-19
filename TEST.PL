#!perl
use strict;
use Cwd ();
use File::Spec;

my $ROOT   = Cwd::abs_path( Cwd::cwd() );
my $EXTDIR = File::Spec->catdir($ROOT, "ext");
my $target = $ENV{PERL_ZMQ_TEST_TARGET} || 'ZMQ-LibZMQ2';

if (! -d $target) {
    die "$target does not exist";
}

sub mysystem(@) {
    system(@_) == 0 or die "Failed to execute @_: $!";
}

sub install_libzmq(@) {
    my ($basename, $tail) = @_;

    $tail ||= '';
    my $prefix = File::Spec->catdir($EXTDIR, $basename);
    my $file   = "$basename$tail.tar.gz";
    mysystem("curl", "-LO", "http://download.zeromq.org/$file");
    mysystem("tar", "xzf", $file);
    chdir $basename;
    mysystem("./configure", "--prefix", $prefix);
    mysystem("make");
    mysystem("make", "install");

    $ENV{ZMQ_HOME} = $prefix;
    return $prefix;
}

sub cpanm (@) {
    mysystem("cpanm", "--notest", @_);
}

sub test_binding {
    my $subdir = shift;
    chdir File::Spec->catdir($ROOT, $subdir);
    mysystem("cpanm", "--notest", "--installdeps", ".");
    mysystem("perl", "Makefile.PL");
    mysystem("make", "test");
}

if ( $target eq 'ZMQ-Constants' ) {
    test_binding("ZMQ-Constants");
    cpanm(qw(
        inc::Module::Install
        Module::Install::Repository
    ));
} elsif ( $target eq 'ZMQ-LibZMQ2' ) {
    install_libzmq("zeromq-2.2.0");
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::ReadmeFromPod
        Module::Install::TestTarget
        Module::Install::XSUtil
        Module::Install::Repository
    ));
    test_binding("ZMQ-LibZMQ2");
} elsif ( $target eq 'ZMQ-LibZMQ3' ) {
    install_libzmq("zeromq-3.2.0", "-rc1");
    cpanm(qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::CheckLib
        Module::Install::ReadmeFromPod
        Module::Install::TestTarget
        Module::Install::XSUtil
        Module::Install::Repository
    ));
    test_binding("ZMQ-LibZMQ3");
}