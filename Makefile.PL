use inc::Module::Install;
use Module::Install::CPANfile;

name 'tom';
version_from 'lib/Tom.pm';
perl_version '5.008001';
#license_from 'bin/tom';
author_from 'bin/tom';
#readme_from('bin/tom');

cpanfile;

install_script 'bin/tom';

build_requires 'Test::More';
#auto_set_repository();
#auto_provides;

resources
  homepage => 'https://github.com/delonnewman/tom',
  bugtracker => 'https://github.com/delonnewman/tom/issues';

WriteAll;
