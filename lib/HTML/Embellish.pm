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

my $mdash = chr(8212);
my $lsquo = chr(8216);
my $rsquo = chr(8217);
my $ldquo = chr(8220);
my $rdquo = chr(8221);

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

  $self->[parDepth]    = 0;
  $self->[textRefs]    = [];
  $self->[fixDashes]   = (exists $parms{dashes}   ? $parms{dashes}   : 1);
  $self->[fixEllipses] = (exists $parms{ellipses} ? $parms{ellipses} : 1);
  $self->[fixQuotes]   = (exists $parms{quotes}   ? $parms{quotes}   : 1);

  return $self;
} # end new

#---------------------------------------------------------------------
sub curlyquote
{
  my ($self, $refs) = @_;

  local $_ = join('', map { $$_ } @$refs);

  s/^"/$ldquo/;
  s/(?<=\s)"(?=\S)/$ldquo/g;
  s/(?<=\pP)"(?=\w)/$ldquo/g;

  s/"$/$rdquo/;
  s/(?<!\s)"(?=\s)/$rdquo/g;
  s/(?<=\w)"(?=\pP)/$rdquo/g;

  s/'(?=(?:em|tis|twas)\b)/$rsquo/g;

  s/`/$lsquo/g;
  s/^'/$lsquo/;
  s/(?<=\s)'(?=\S)/$lsquo/g;
  s/(?<=\pP)(?<![.!?])'(?=\w)/$lsquo/g;

  s/'$/$rsquo/;
  s/(?<!\s)'(?=\s)/$rsquo/g;
  s/(?<=\w)'(?=\pP)/$rsquo/g;
  s/'(?=$rdquo)/$rsquo/go;

  s/(?<!\S)"([\xA0\s]+$lsquo)/$ldquo$1/go;
  s/(${rsquo}[\xA0\s]+)"(?!\S)/$1$rdquo/go;

  s/${ldquo}[\xA0\s]$lsquo/$ldquo\x{202F}$lsquo/g;
  s/${rsquo}[\xA0\s]$rdquo/$rsquo\x{202F}$rdquo/g;

  # Return the text to where it came from:
  #   This only works because the replacement text is always
  #   the same length as the original.
  foreach my $r (@$refs) {
    $$r = substr($_, 0, length($$r), '');
    # Since the replacement text isn't the same length,
    # these can't be done on the string as a whole:
    $$r =~ s/$ldquo$lsquo/$ldquo\x{202F}$lsquo/g;
    $$r =~ s/$rsquo$rdquo/$rsquo\x{202F}$rdquo/g;
  } # end foreach @$refs
} # end curlyquote

#---------------------------------------------------------------------
sub process
{
  my ($self, $elt) = @_;

  my $isP = ($elt->tag eq 'p');

  ++$self->[parDepth] if $isP;

  foreach my $r ($elt->content_refs_list) {
    if (ref $$r) {
      if ($self->[parDepth] and $$r->tag eq 'br') {
        my $break = "\n";
        push @{$self->[textRefs]}, \$break;
      }
      $self->process($$r);
    } else {
      # Convert -- to em-dash:
      if ($self->[fixDashes]) {
        $$r =~ s/(?<!-)--(?!-)/$mdash/g; # &mdash;
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
  }
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

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

HTML::Embellish requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

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
