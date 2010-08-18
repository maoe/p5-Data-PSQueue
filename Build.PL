use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::PSQueue',
    license             => 'perl',
    dist_author         => 'Mitsutoshi Aoe <maoe.maoe@gmail.com>',
    dist_version_from   => 'lib/Data/PSQueue.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => ['Data-PSQueue-*'],
    test_files          => ['t', 'xt']
);

$builder->create_build_script();
