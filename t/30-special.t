#! /usr/bin/perl
#---------------------------------------------------------------------
# 30-special.t
#
# Test special cases in single-quote substitution
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More 0.88;            # done_testing

binmode STDOUT, ':utf8';

my $checkWarnings;
BEGIN {
  # RECOMMEND PREREQ: Test::NoWarnings
  $checkWarnings = eval { require Test::NoWarnings; 1 };
}

use HTML::Element;
use HTML::Embellish;

#=====================================================================
sub fmt
{
  my ($html) = @_;

  my $text = $html->as_HTML("<>&", undef, {});
  $text =~ s/[ \t\r\n]+/ /g;  # Convert all whitespace to single space
  $text =~ s/\s*\z/\n/;       # Ensure it ends with a single newline

  return $text;
} # end fmt

#=====================================================================

my $rsquo = chr(0x2019);

my @tests = qw(
  '45
  '90s
  'cause
  'cept
  'd
  'ee
  'em
  'er
  'ere
  'fraid
  'fraidy
  'gainst
  'im
  'm
  'n
  'nother
  'nothers
  'r
  're
  's
  'scuse
  't
  'til
  'tis
  'tisn't
  'twas
  'twasn't
  'twere
  'tweren't
  'twould
  'twouldn't
  'ud
  'un
  'uns
);

plan tests => 1 + @tests;

#=====================================================================
# Run the tests:

my $html = HTML::Element->new('p');

foreach my $word (@tests) {
  $html->delete_content;
  my $text = "This is $word in use.";
  $html->push_content($text);

  $text =~ s/'/$rsquo/g;

  embellish($html);
  is(fmt($html), "<p>$text</p>\n", $word);
} # end while @tests

#---------------------------------------------------------------------
SKIP: {
 skip "Test::NoWarnings not installed", 1 unless $checkWarnings;

 Test::NoWarnings::had_no_warnings();
}

done_testing;
