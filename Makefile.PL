use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::PetalTinyRenderer',
  VERSION_FROM => 'lib/Mojolicious/Plugin/PetalTinyRenderer.pm',
  AUTHOR       => 'Lars Balker <lars@balker.dk>',
  PREREQ_PM    => {
      'Mojolicious' => '5.05',
      'Petal::Tiny' => '1.04',
  },
  test         => {
      TESTS => 't/*.t',
  }
);
