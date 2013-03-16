package App::Tom::Config;
use v5.10;
use strict;
use warnings;

use App::Tom::Utils;

use Exporter qw{ import };
our @EXPORT_OK = qw{ config defconfig setconfig };

{
  my %config = ();
  sub defconfig(@) {
    my %args = @_;
    setconfig($_ => $args{$_}) for keys %args;
  }

  sub setconfig($$) {
    my ($k, $v) = @_;
    if ( ref $v eq 'CODE' ) {
      $config{$k} = $v;
    }
    else {
      $config{$k} = sub { $v };
    }
  }
  
  sub config($) {
    my ($name) = @_;
    if ( $config{$name} ) {
      if ( ref $config{$name} eq 'CODE' ) {
        my $r = $config{$name}->();
        if    ( ref $r eq 'ARRAY' ) { @{$r} }
        elsif ( ref $r eq 'HASH' )  { %{$r} }
        else                        { $r }
      }
      else { $config{$name} }
    }
    else { undef }
  }
}

1;
