#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Time;

###### IMPORTS ################################################################

use Essence::Strict;

use Time::HiRes qw( gettimeofday );
use Time::Local;
use Carp;

###### EXPORTS ################################################################

use Exporter qw( import );

our @EXPORT_OK = qw( time_ms
                     fmt_localtime_s fmt_localtime_ms fmt_localtime_us
                     fmt_gmtime_s fmt_gmtime_ms fmt_gmtime_us
                     parse_local_s parse_local_ms parse_local_us
                     parse_gmt_s parse_gmt_ms parse_gmt_us
                     add_s add_ms add_us diff_s diff_ms diff_us
                     remove_ms remove_us
                     fix_ms fix_us fix_ms_hash fix_us_hash );

###### VARS ###################################################################

our $Exception = "Input doesn't look like date/time";

my $re_time_nocap_free =
    qr/ \d{4} - \d{2} - \d{2} [ ]
        \d{2} : \d{2} : \d{2} /x;
my $re_time_cap_free =
    qr/ (\d{4}) - (\d{2}) - (\d{2}) [ ]
        (\d{2}) : (\d{2}) : (\d{2}) /x;
my $re_time_cap = qr/^$re_time_cap_free\z/;

my $re_time_opt_ms_cap = qr/^ $re_time_cap_free (?: \. (\d{3}) )? \z/x;
my $re_time_opt_ms = qr/^ $re_time_nocap_free (?: \. \d{3} )? \z/x;

my $re_time_opt_us_cap = qr/^ $re_time_cap_free (?: \. (\d{6}) )? \z/x;
my $re_time_opt_us = qr/^ $re_time_nocap_free (?: \. \d{6} )? \z/x;

###### SUBS ###################################################################

sub time_ms
{
  my ($s, $us) = gettimeofday();
  return $s * 1000 + int($us / 1000);
}

# ==== format =================================================================

sub _fmt_in_s { return defined($_[0]) ? ($_[0]) : (scalar(time())) }

sub _fmt_in_ms
{
  my ($s, $x);

  if (@_)
  {
    carp "Undefined time" unless defined($_[0]);

    if (!$#_)
    {
      $s = int($_[0] / 1e3);
      $x = $_[0] % 1e3;
    }
    else
    {
      ($s, $x) = @_;
    }
  }
  else
  {
    ($s, $x) = gettimeofday();
    $x = int($x / 1e3);
  }

  return ($s, sprintf('.%03d', $x // 0));
}

sub _fmt_in_us
{
  my ($s, $x);

  if (@_)
  {
    carp "Undefined time" unless defined($_[0]);

    if (!$#_)
    {
      $s = int($_[0] / 1e6);
      $x = $_[0] % 1e6;
    }
    else
    {
      ($s, $x) = @_;
    }
  }
  else
  {
    ($s, $x) = gettimeofday();
  }

  return ($s, sprintf('.%06d', $x // 0));
}

sub _fmt
{
  my $ret = sprintf('%04d-%02d-%02d %02d:%02d:%02d',
      $_[6] + 1900, $_[5] + 1, $_[4], $_[3], $_[2], $_[1]);
  $ret .= $_[0] if defined($_[0]);
  return $ret;
}

# ---- local ------------------------------------------------------------------

sub fmt_localtime_s
{
  my @time =_fmt_in_s(@_);
  return _fmt($time[1], localtime($time[0]));
}
sub fmt_localtime_ms
{
  my @time =_fmt_in_ms(@_);
  return _fmt($time[1], localtime($time[0]));
}
sub fmt_localtime_us
{
  my @time =_fmt_in_us(@_);
  return _fmt($time[1], localtime($time[0]));
}

# ---- gmt --------------------------------------------------------------------

sub fmt_gmtime_s
{
  my @time =_fmt_in_s(@_);
  return _fmt($time[1], gmtime($time[0]));
}
sub fmt_gmtime_ms
{
  my @time =_fmt_in_ms(@_);
  return _fmt($time[1], gmtime($time[0]));
}
sub fmt_gmtime_us
{
  my @time =_fmt_in_us(@_);
  return _fmt($time[1], gmtime($time[0]));
}

# ==== parse ==================================================================

sub _parse_in
{
  my ($re, $str) = @_;
  my @time = ($str =~ $re) or
    carp $Exception;
  $time[0] -= 1900;
  $time[1] -= 1;
  return @time[6, 5, 4, 3, 2, 1, 0];
}

sub _parse_out_s { return ($_[0]) }

sub _parse_out_ms
{
  return @_ if wantarray;
  return $_[0] * 1e3 + ($_[1] // 0);
}

sub _parse_out_us
{
  return @_ if wantarray;
  return $_[0] * 1e6 + ($_[1] // 0);
}

# ---- local ------------------------------------------------------------------

sub parse_local_s
{
  my (undef, @t) = _parse_in($re_time_cap, @_);
  return _parse_out_s(timelocal(@t));
}
sub parse_local_ms
{
  my ($ms, @t) = _parse_in($re_time_opt_ms_cap, @_);
  return _parse_out_ms(timelocal(@t), $ms);
}
sub parse_local_us
{
  my ($us, @t) = _parse_in($re_time_opt_us_cap, @_);
  return _parse_out_us(timelocal(@t), $us);
}

# ---- gmt --------------------------------------------------------------------

sub parse_gmt_s
{
  my (undef, @t) = _parse_in($re_time_cap, @_);
  return _parse_out_s(timegm(@t));
}
sub parse_gmt_ms
{
  my ($ms, @t) = _parse_in($re_time_opt_ms_cap, @_);
  return _parse_out_ms(timegm(@t), $ms);
}
sub parse_gmt_us
{
  my ($us, @t) = _parse_in($re_time_opt_us_cap, @_);
  return _parse_out_us(timegm(@t), $us);
}

# ==== Arithmetic =============================================================

# add_s('2014-02-12 11:12:11', 3600) -> '2014-02-12 12:12:11'
sub add_s { return fmt_gmtime_s(parse_gmt_s($_[0]) + $_[1]) }
sub add_ms { return fmt_gmtime_ms(parse_gmt_ms($_[0]) + $_[1]) }
sub add_us { return fmt_gmtime_us(parse_gmt_us($_[0]) + $_[1]) }

# diff_s('2014-02-12 12:12:11', '2014-02-12 11:12:11') -> 3600
sub diff_s { return parse_gmt_s($_[0]) - parse_gmt_s($_[1]) }
sub diff_ms { return parse_gmt_ms($_[0]) - parse_gmt_ms($_[1]) }
sub diff_us { return parse_gmt_us($_[0]) - parse_gmt_us($_[1]) }

# =============================================================================

# 00000000011111111112222222
# 12345678901234567890123456
# 2014-02-06 16:55:42.480383

sub remove_ms
{
  my $str = $_[0];
  carp $Exception
    unless (defined($str) &&
            ($str =~ s/^ $re_time_nocap_free \K (?: \. [0]{0,3} )? \z//x));
  return $str;
}

sub remove_us
{
  my $str = $_[0];
  carp $Exception
    unless (defined($str) &&
            ($str =~ s/^ $re_time_nocap_free \K (?: \. [0]{0,6} )? \z//x));
  return $str;
}

sub fix_ms
{
  my $str = $_[0];
  if (defined($str))
  {
    carp $Exception
      unless (defined($str) && ($str =~ $re_time_opt_ms));

    my $missing = 23 - length($str);
    $str .= substr('.000', -$missing, $missing)
      if ($missing <= 4);
  }
  return $str;
}

sub fix_us
{
  my $str = $_[0];
  if (defined($str))
  {
    carp $Exception
      unless (defined($str) && ($str =~ $re_time_opt_us));

    my $missing = 26 - length($str);
    $str .= substr('.000000', -$missing, $missing)
      if ($missing <= 7);
  }
  return $str;
}

sub fix_ms_hash
{
  my $hash = shift;

  foreach (@_)
  {
    $hash->{$_} = fix_ms($hash->{$_})
      if defined($hash->{$_});
  }

  return $hash;
}

sub fix_us_hash
{
  my $hash = shift;

  foreach (@_)
  {
    $hash->{$_} = fix_us($hash->{$_})
      if defined($hash->{$_});
  }

  return $hash;
}

###############################################################################

1
