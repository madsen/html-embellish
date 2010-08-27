#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More;

use HTML::Element;

#=====================================================================
sub fmt
{
  my ($html) = @_;

  $html->as_HTML("<>&", undef, {});
} # end fmt

#=====================================================================
my (@tests, $source_list);

BEGIN {
my $nb    = chr(0x00A0);
my $mdash = chr(0x2014);
my $lsquo = chr(0x2018);
my $rsquo = chr(0x2019);
my $ldquo = chr(0x201C);
my $rdquo = chr(0x201D);

$source_list = [
  p => q{"Here we have--in this string--some 'characters' ... to process."}
];

@tests = (
#---------------------------------------------------------------------
  $source_list, [],
  <<"", 'default processing',
<p>${ldquo}Here we have${mdash}in this string${mdash}some ${lsquo}characters${rsquo} .$nb.$nb. to process.$rdquo</p>

#---------------------------------------------------------------------
  $source_list, [ default => 0 ],
  <<"", 'all disabled',
<p>"Here we have--in this string--some 'characters' ... to process."</p>

#---------------------------------------------------------------------
  $source_list, [ dashes => 1, default => 0 ],
  <<"", 'dashes only',
<p>"Here we have${mdash}in this string${mdash}some 'characters' ... to process."</p>

#---------------------------------------------------------------------
  $source_list, [ ellipses => 1, default => 0 ],
  <<"", 'ellipses only',
<p>"Here we have--in this string--some 'characters' .$nb.$nb. to process."</p>

#---------------------------------------------------------------------
  $source_list, [ quotes => 1, default => 0 ],
  <<"", 'quotes only',
<p>${ldquo}Here we have--in this string--some ${lsquo}characters${rsquo} ... to process.$rdquo</p>

#---------------------------------------------------------------------
  [ blockquote =>
    [ a => { href => "dest" }, qq!This isn't "wrong".! ],
    [ blockquote => qq!It should 'work'.! ] ],
  [],
  <<"", 'nested blockquotes',
<blockquote><a href="dest">This isn${rsquo}t ${ldquo}wrong${rdquo}.</a><blockquote>It should ${lsquo}work${rsquo}.</blockquote></blockquote>

#---------------------------------------------------------------------
  [ p => q!"Probably. 'If - '"! ], [],
  <<"", 'Probably If',
<p>${ldquo}Probably. ${lsquo}If - $rsquo$nb$rdquo</p>

#---------------------------------------------------------------------
  [ p => q!"I'm quoting"--not quoted--"in part," he said.! ], [],
  <<"", 'dash quote',
<p>${ldquo}I${rsquo}m quoting${rdquo}${mdash}not quoted${mdash}${ldquo}in part,${rdquo} he said.</p>

#---------------------------------------------------------------------
  [ p => q!She said, "'All the world's a stage,'"--and then--"nonsense."! ],
  [],
  <<"", 'quoted quote dash',
<p>She said, ${ldquo}$nb${lsquo}All the world${rsquo}s a stage,${rsquo}$nb${rdquo}${mdash}and then${mdash}${ldquo}nonsense.${rdquo}</p>

#---------------------------------------------------------------------
); # end @tests

plan tests => 4 + @tests / 4;

use_ok('HTML::Embellish');
} # end BEGIN


#=====================================================================
# Normal tests

while (@tests) {
  my $source     = shift @tests;
  my $parameters = shift @tests;
  my $expected   = shift @tests;
  my $name       = shift @tests;

  my $html = HTML::Element->new_from_lol($source);

  embellish($html, @$parameters);
  is(fmt($html), $expected, $name);
} # end while @tests

#=====================================================================
# Argument checking:

my $html = HTML::Element->new_from_lol($source_list);

eval { embellish() };
like($@, qr/^First parameter of embellish must be an HTML::Element at \Q$0\E line \d/, 'no parameters');

eval { embellish($html, 'whoops') };
like($@, qr/^Odd number of parameters passed to HTML::Embellish->new at \Q$0\E line \d/, 'odd parameter');

eval { HTML::Embellish->new()->process('whoops') };
like($@, qr/^HTML::Embellish->process must be passed an HTML::Element at \Q$0\E line \d/, 'bad parameter');

done_testing;
