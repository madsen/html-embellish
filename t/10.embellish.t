#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 13;

use HTML::Element;

BEGIN {
    use_ok('HTML::Embellish');
}

my $nb    = chr(0x00A0);
my $mdash = chr(0x2014);
my $lsquo = chr(0x2018);
my $rsquo = chr(0x2019);
my $ldquo = chr(0x201C);
my $rdquo = chr(0x201D);

#=====================================================================
sub fmt
{
  my ($html) = @_;

  $html->as_HTML("<>&", undef, {});
} # end fmt

#=====================================================================
my $source_list = [
  p => q{"Here we have--in this string--some 'characters' ... to process."}
];

#---------------------------------------------------------------------
my $html = HTML::Element->new_from_lol($source_list);

embellish($html);
is(fmt($html), <<"", 'default processing');
<p>${ldquo}Here we have${mdash}in this string${mdash}some ${lsquo}characters${rsquo} .$nb.$nb. to process.$rdquo</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol($source_list);

embellish($html, default => 0);
is(fmt($html), <<"", 'all disabled');
<p>"Here we have--in this string--some 'characters' ... to process."</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol($source_list);

embellish($html, dashes => 1, default => 0);
is(fmt($html), <<"", 'dashes only');
<p>"Here we have${mdash}in this string${mdash}some 'characters' ... to process."</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol($source_list);

embellish($html, ellipses => 1, default => 0);
is(fmt($html), <<"", 'ellipses only');
<p>"Here we have--in this string--some 'characters' .$nb.$nb. to process."</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol($source_list);

embellish($html, quotes => 1, default => 0);
is(fmt($html), <<"", 'quotes only');
<p>${ldquo}Here we have--in this string--some ${lsquo}characters${rsquo} ... to process.$rdquo</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol(
  [ blockquote =>
    [ a => { href => "dest" }, qq!This isn't "wrong".! ],
    [ blockquote => qq!It should 'work'.! ] ]
);

embellish($html);
is(fmt($html), <<"", 'nested blockquotes');
<blockquote><a href="dest">This isn${rsquo}t ${ldquo}wrong${rdquo}.</a><blockquote>It should ${lsquo}work${rsquo}.</blockquote></blockquote>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol(
  [ p => q!"Probably. 'If - '"! ]
);

embellish($html);
is(fmt($html), <<"", 'Probably If');
<p>${ldquo}Probably. ${lsquo}If - $rsquo$nb$rdquo</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol(
  [ p => q!"I'm quoting"--not quoted--"in part," he said.! ]
);

embellish($html);
is(fmt($html), <<"", 'dash quote');
<p>${ldquo}I${rsquo}m quoting${rdquo}${mdash}not quoted${mdash}${ldquo}in part,${rdquo} he said.</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol(
  [ p => q!She said, "'All the world's a stage,'"--and then--"nonsense."! ]
);

embellish($html);
is(fmt($html), <<"", 'quoted quote dash');
<p>She said, ${ldquo}$nb${lsquo}All the world${rsquo}s a stage,${rsquo}$nb${rdquo}${mdash}and then${mdash}${ldquo}nonsense.${rdquo}</p>

#=====================================================================
# Argument checking:

eval { embellish() };
like($@, qr/^First parameter of embellish must be an HTML::Element at \Q$0\E line \d/, 'no parameters');

eval { embellish($html, 'whoops') };
like($@, qr/^Odd number of parameters passed to HTML::Embellish->new at \Q$0\E line \d/, 'odd parameter');

eval { HTML::Embellish->new()->process('whoops') };
like($@, qr/^HTML::Embellish->process must be passed an HTML::Element at \Q$0\E line \d/, 'bad parameter');
