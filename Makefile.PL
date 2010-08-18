use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::PSQueue',
    AUTHOR              => 'Mitsutoshi Aoe <maoe.maoe@gmail.com>',
    VERSION_FROM        => 'lib/Data/PSQueue.pm',
    ABSTRACT_FROM       => 'lib/Data/PSQueue.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-PSQueue-*' },
);
