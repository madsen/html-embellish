#! /usr/bin/perl -T
#---------------------------------------------------------------------
# $Id$
#---------------------------------------------------------------------

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;

my @private = map { qr/^\Q$_\E$/ } qw(
  parDepth processTextRefs textRefs fixQuotes fixDashes fixEllipses
  fixEllipseSpace fixHellip totalFields
);

all_pod_coverage_ok({also_private => \@private});
