#line 1
package Module::Install::CheckLib;

use strict;
use warnings;
use File::Spec;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.08';

sub checklibs {
  my $self = shift;
  my @parms = @_;
  return unless scalar @parms;

  unless ( $Module::Install::AUTHOR ) {
     require Devel::CheckLib;
     Devel::CheckLib::check_lib_or_exit( @parms );
     return;
  }

  _author_side();
}

sub assertlibs {
  my $self = shift;
  my @parms = @_;
  return unless scalar @parms;

  unless ( $Module::Install::AUTHOR ) {
     require Devel::CheckLib;
     Devel::CheckLib::assert_lib( @parms );
     return;
  }

  _author_side();
}

sub _author_side {
  mkdir 'inc';
  mkdir 'inc/Devel';
  print "Extra directories created under inc/\n";
  require Devel::CheckLib;
  local $/ = undef;
  open(CHECKLIBPM, $INC{'Devel/CheckLib.pm'}) ||
    die("Can't read $INC{'Devel/CheckLib.pm'}: $!");
  (my $checklibpm = <CHECKLIBPM>) =~ s/package Devel::CheckLib/package #\nDevel::CheckLib/;
  close(CHECKLIBPM);
  open(CHECKLIBPM, '>'.File::Spec->catfile(qw(inc Devel CheckLib.pm))) ||
    die("Can't write inc/Devel/CheckLib.pm: $!");
  print CHECKLIBPM $checklibpm;
  close(CHECKLIBPM);

  print "Copied Devel::CheckLib to inc/ directory\n";
  return 1;
}

'All your libs are belong';

__END__

#line 126
