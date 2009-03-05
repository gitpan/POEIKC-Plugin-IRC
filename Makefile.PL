use inc::Module::Install;
name 'POEIKC-Plugin-IRC';
all_from 'lib/POEIKC/Plugin/IRC.pm';

requires('Class::Inspector');
requires('POE');
requires('POE::Sugar::Args');
requires('POE::Component::IKC::ClientLite');
requires('POE::Component::IRC');

build_requires 'Test::More';

features(
    'poeikc daemon' => [
        -default => 0,
        recommends('POEIKC'),
    ],
);

use_test_base;
auto_include_deps;
WriteAll;
