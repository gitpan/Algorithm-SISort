use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Algorithm::SISort',
    'VERSION_FROM'	=> 'lib/Algorithm/SISort.pm', # finds $VERSION
    'PREREQ_PM'		=> {Inline => '0.40'}, 
);
