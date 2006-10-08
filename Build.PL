#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id$
# Copyright 2006 Christopher J. Madsen
#
# Build.PL for HTML-Embellish
#---------------------------------------------------------------------

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'HTML::Embellish',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <cjm@pobox.com>',
  dist_version_from  => 'lib/HTML/Embellish.pm',
  requires => {
      'HTML::Tree' => 3.21,
      'Test::More' => 0,
  },
  add_to_cleanup     => [ 'HTML-Embellish-*' ],
  create_makefile_pl => 'passthrough',
);

$builder->create_build_script();
