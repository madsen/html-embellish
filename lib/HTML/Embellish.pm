#---------------------------------------------------------------------
package HTML::Embellish;
#
# Copyright 2006 Christopher J. Madsen
#
# Author: Christopher J. Madsen <cjm@pobox.com>
# Created: October 8, 2006
# $Id$
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Typographically enhance HTML trees
#---------------------------------------------------------------------

use 5.006;
use warnings;
use strict;
#use Carp;

require Exporter;

#=====================================================================
# Package Global Variables:

our $VERSION = '0.01';

our @ISA    = qw(Exporter);
our @EXPORT = qw(embellish);

my $mdash = chr(0x2014);
my $lsquo = chr(0x2018);
my $rsquo = chr(0x2019);
my $ldquo = chr(0x201C);
my $rdquo = chr(0x201D);

my $notQuote = qq/[^\"$ldquo$rdquo]/;
my $balancedQuoteString = qq/(?: $notQuote | $ldquo $notQuote* $rdquo)*/;

#=====================================================================
# Constants:
#---------------------------------------------------------------------

BEGIN
{
  my $i = 0;
  for (qw(parDepth textRefs fixQuotes fixDashes fixEllipses totalFields)) {
    ## no critic (ProhibitStringyEval)
    eval "sub $_ () { $i }";
    ++$i;
  }
} # end BEGIN

#=====================================================================
# Exported functions:
#---------------------------------------------------------------------
sub embellish
{
  my $html = shift @_;

  my $e = HTML::Embellish->new(@_);
  $e->process($html);
} # end embellish

#=====================================================================
# Class Methods:
#---------------------------------------------------------------------
sub new
{
  my $class = shift;
  my %parms = @_;

  my $self = [ (undef) x totalFields ];
  bless $self, $class;

  my $def = (exists $parms{default} ? $parms{default} : 1);

  $self->[parDepth]    = 0;
  $self->[textRefs]    = [];
  $self->[fixDashes]   = (exists $parms{dashes}   ? $parms{dashes}   : $def);
  $self->[fixEllipses] = (exists $parms{ellipses} ? $parms{ellipses} : $def);
  $self->[fixQuotes]   = (exists $parms{quotes}   ? $parms{quotes}   : $def);

  return $self;
} # end new

#---------------------------------------------------------------------
# Convert quotes & apostrophes into curly quotes:
#
# Input:
#   self:  The HTML::Embellish object
#   refs:  Arrayref of stringrefs to the text of this paragraph

sub curlyquote
{
  my ($self, $refs) = @_;

  local $_ = join('', map { $$_ } @$refs);

  s/^([\xA0\s]*)"/$1$ldquo/;
  s/(?<=[\s\pZ])"(?=[^\s\pZ])/$ldquo/g;
  s/(?<=\pP)"(?=\w)/$ldquo/g;
  s/(?<=[ \t\n\r])"(?=\xA0)/$ldquo/g;
  s/\("/($ldquo/g;

  s/"[\xA0\s]*$/$rdquo/;
  s/(?<![\s\pZ])"(?=[\s\pZ])/$rdquo/g;
  s/(?<=\w)"(?=\pP)/$rdquo/g;
  s/(?<=\xA0)"(?=[ \t\n\r]|[\s\xA0]+$)/$rdquo/g;
  s/"\)/$rdquo)/g;
  s/(?<=[,;.!?])"(?=[-$mdash])/$rdquo/go;

  s/'(?=(?:em?|tisn?|twas)\b)/$rsquo/ig;

  s/`/$lsquo/g;
  s/^'/$lsquo/;
  s/(?<=[\s\pZ])'(?=[^\s\pZ])/$lsquo/g;
  s/(?<=\pP)(?<![.!?])'(?=\w)/$lsquo/g;
  s/(?<=[ \t\n\r])'(?=\xA0)/$lsquo/g;

  s/'/$rsquo/g;

  s/(?<!\PZ)"([\xA0\s]+$lsquo)/$ldquo$1/go;
  s/(${rsquo}[\xA0\s]+)"(?!\PZ)/$1$rdquo/go;

  1 while s/^($balancedQuoteString (?![\"$ldquo$rdquo])[ \t\n\r\pP]) "/$1$ldquo/xo
      or  s/^($balancedQuoteString $ldquo $notQuote*) "/$1$rdquo/xo;

  s/${ldquo}\s([$lsquo$rsquo])/$ldquo\xA0$1/go;
  s/${rsquo}\s$rdquo/$rsquo\xA0$rdquo/go;

  # Return the text to where it came from:
  #   This only works because the replacement text is always
  #   the same length as the original.
  foreach my $r (@$refs) {
    $$r = substr($_, 0, length($$r), '');
    # Since the replacement text isn't the same length,
    # these can't be done on the string as a whole:
    $$r =~ s/(?<=[$ldquo$rdquo])(?=[$lsquo$rsquo])/\xA0/go;
    $$r =~ s/(?<=[$lsquo$rsquo])(?=[$ldquo$rdquo])/\xA0/go;
    $$r =~ s/(?<=[$ldquo$lsquo])\xA0(?=\.\xA0\.)//go;
  } # end foreach @$refs
} # end curlyquote

#---------------------------------------------------------------------
# Recursively process an HTML::Element tree:

sub process
{
  my ($self, $elt) = @_;

  my $isP = ($elt->tag =~ /^(?: p | h\d | d[dt] )$/x);

  ++$self->[parDepth] if $isP;

  my @content = $elt->content_refs_list;

  if ($self->[fixQuotes] and $self->[parDepth] and @content) {
    # A " that opens a tag can be assumed to be a left quote
    ${$content[ 0]} =~ s/^"/$ldquo/ unless ref ${$content[ 0]};
    # A " that ends a tag can be assumed to be a right quote
    ${$content[-1]} =~ s/"$/$rdquo/ unless ref ${$content[-1]};
  }

  foreach my $r (@content) {
    if (ref $$r) { # element node
      my $tag = $$r->tag;
      next if $tag =~ /^(?: ~comment | script | style )$/x;

      if ($self->[parDepth] and $tag eq 'br') {
        my $break = "\n";
        push @{$self->[textRefs]}, \$break;
      }
      $self->process($$r);
    } else { # text node
      # Convert -- to em-dash:
      if ($self->[fixDashes]) {
        $$r =~ s/(?<!-)---?(?!-)/$mdash/g; # &mdash;
        $$r =~ s/(?<!-)----(?!-)/$mdash$mdash/g;
      } # end if fixDashes

      # Fix ellipses:
      if ($self->[fixEllipses]) {
        $$r =~ s/(?<!\.)\.\.\.([.?!;:,])(?!\.)/.\xA0.\xA0.\xA0$1/g;
        $$r =~ s/(?<!\.)\.\.\.(?!\.)/.\xA0.\xA0./g;
        $$r =~ s/\. (?=[,.?!])/.\xA0/g;
        $$r =~ s/(?:(?<=\w)|\A) (\.\xA0\.\xA0\.|\.\.\.)(?=[ \xA0\n\"\'?!])(?![ \xA0\n]+\w)/\xA0$1/g;
      } # end if fixEllipses

      push @{$self->[textRefs]}, $r if $self->[parDepth];
    } # end else text node
  } # end foreach $r

  if ($isP and not --$self->[parDepth]) {
    $self->curlyquote($self->[textRefs]) if $self->[fixQuotes];
    @{ $self->[textRefs] } = ();
  } # end if this was a top-level paragraph
} # end process

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

HTML::Embellish - Typographically enhance HTML trees

=head1 VERSION

This document describes HTML::Embellish version 0.01

=head1 SYNOPSIS

    use HTML::Embellish;
    use HTML::TreeBuilder;

    my $html = HTML::TreeBuilder->new_from_file(...);
    embellish($html);

=head1 DESCRIPTION

HTML::Embellish adds typographical enhancements to HTML text.  It
converts certain ASCII characters to Unicode characters.  It converts
quotation marks and apostrophes into curly quotes.  It converts
hyphens into em-dashes.  It inserts non-breaking spaces between the
periods of an ellipsis.  (It doesn't use the HORIZONTAL ELLIPSIS
character (U+2026), because I like more space in my ellipses.)

=head1 INTERFACE

=over

=item C<embellish($html, ...)>

This subroutine (exported by default) is the main entry point.  It's a
shortcut for C<< HTML::Embellish->new(...)->process($html) >>.

If you're going to process several trees with the same parameters, the
object-oriented interface will be slightly more efficient.

=item C<< $emb = HTML::Embellish->new(flag => value, ...) >>

This creates an HTML::Embellish object that will perform the specified
enhancements.  These are the (optional) flags that you can pass:

=over

=item dashes

If true, converts sequences of hyphens into em-dashes.  Two or 3
hyphens become one em-dash.  Four hyphens become two em-dashes.  Any
other sequence of hyphens is not changed.

=item ellipses

If true, inserts non-breaking spaces between the periods making up an
ellipsis.  Also converts the space before an ellipsis that appears to
end a sentence to a non-breaking space.

=item quotes

If true, converts quotation marks and apostrophes into curly quotes.

=item default

This is the default value used for flags that you didn't specify.  It
defaults to 1 (enabled).  The main reason for using this flag is to
disable any enhancements that might be introduced in future versions
of HTML::Embellish.

=back

=item C<< $emb->process($html) >>

The C<process> method enhances the content of the HTML::Element you
pass in.  You can pass the root element to process the entire tree, or
any sub-element to process just that part of the tree.  The tree is
modified in-place; the return value is not meaningful.

=back

=head1 CONFIGURATION AND ENVIRONMENT

HTML::Embellish requires no configuration files or environment variables.

=head1 DEPENDENCIES

Requires the HTML::Tree distribution from CPAN (or some other module
that implements the HTML::Element interface).  Versions of HTML::Tree
prior to 3.21 had some bugs involving Unicode characters and
non-breaking spaces.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-html-embellish@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Christopher J. Madsen  C<< <cjm@pobox.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2006, Christopher J. Madsen C<< <cjm@pobox.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
