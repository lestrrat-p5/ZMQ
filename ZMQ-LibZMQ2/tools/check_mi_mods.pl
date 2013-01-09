# Okay, so some people wanting to check out the latest and greatest
# version from github is getting stuck not knowing what M::I modules
# to install. So do the check here
my @modules = qw(
    inc::Module::Install
    Module::Install::AuthorTests
    Module::Install::CheckLib
    Module::Install::XSUtil
    Module::Install::Repository
);

my @missing;
foreach my $module (@modules) {
    eval "require $module";
    push @missing, $module if $@;
}
if (@missing) {
    print STDERR <<EOM;

**** Missing Developer Tools! ****

Whoa there, you don't have the required modules to run this Makefile.PL!
This probably means you cloned the repository from github (if you
encounter this from a tarball uploaded to CPAN, it's a bug, so please
report it).

If you are running from a cloned git repository, install the following
modules first:
EOM
    foreach my $module (@missing) {
        $module =~ s/^inc:://;
        print STDERR "    * $module\n";
    }
    print STDERR <<EOM;
and try again.

While you're at it, install these modules as they are needed to run
the tests:

* Test::Fatal
* Test::Requires
* Test::TCP
* Devel::CheckLib

EOM
    exit 0;
}
Module::Install->import;
