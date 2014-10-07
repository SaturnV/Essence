#! /usr/bin/perl
# It's 2014-01-16 today. Will all major OS vendors go fsck themselves?
# Perl 5.18 was introduced on 2013-05-18.
# Perl 5.16 was introduced on 2012-05-20.
# Perl 5.14 was introduced on 2011-05-14.
# Perl 5.12 was introduced on 2010-04-12.
# Perl 5.10 was introduced on 2007-12-18.
# 5.10 has // and mro though, that's what most of us needs.
# use common::sense has no strict refs, no warnings on undefs.
# I totally accept their reasoning, just don't agree with them.

package Essence::Strict;

use 5.010;
use strict;
use warnings;
use utf8;

# use mro has global effect
use mro;

sub import
{
  strict->import;
  warnings->import;
  utf8->import;
  feature->import(':5.10');
}

1
