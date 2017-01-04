#!/usr/bin/perl

###################################################################################################################################
#
# Copyright 2014-2015 IRD-CIRAD-INRA-ADNid
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/> or
# write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# You should have received a copy of the CeCILL-C license with this program.
#If not see <http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.txt>
#
# Intellectual property belongs to IRD, CIRAD and South Green developpement plateform for all versions also for ADNid for v2 and v3 and INRA for v3
# Version 1 written by Cecile Monat, Ayite Kougbeadjo, Christine Tranchant, Cedric Farcy, Mawusse Agbessi, Maryline Summo, and Francois Sabot
# Version 2 written by Cecile Monat, Christine Tranchant, Cedric Farcy, Enrique Ortega-Abboud, Julie Orjuela-Bouniol, Sebastien Ravel, Souhila Amanzougarene, and Francois Sabot
# Version 3 written by Cecile Monat, Christine Tranchant, Cedric Farcy, Maryline Summo, Julie Orjuela-Bouniol, Sebastien Ravel, Gautier Sarah, and Francois Sabot
#
###################################################################################################################################

#Will test if fastxToolkit works correctly
use strict;
use warnings;
use Test::More 'no_plan'; #Number of tests, to modify if new tests implemented. Can be changed as 'no_plan' instead of tests=>11 .
use Test::Deep;
use Data::Dumper;
use lib qw(../Modules/);

########################################
#Test of the use of fastxToolkit modules
########################################
use_ok('toolbox') or exit;
use_ok('fastxToolkit') or exit;

can_ok('fastxToolkit','fastxTrimmer');

use toolbox;
use fastxToolkit;

my $expectedData="../../DATA/expectedData/";

#########################################
#Remove files and directory created by previous test
#########################################
my $testingDir="../DATA-TEST/fastxToolkitTestDir";
my $creatingDirCom="rm -Rf $testingDir ; mkdir -p $testingDir";                                    #Allows to have a working directory for the tests
system($creatingDirCom) and die ("ERROR: $0 : Cannot execute the command $creatingDirCom\n$!\n");

chdir $testingDir or die ("ERROR: $0 : Cannot go into the new directory with the command \"chdir $testingDir\"\n$!\n");


#######################################
#Creating the IndividuSoft.txt file
#######################################
my $creatingCommand="echo \"fastxToolkit\nTEST\" > individuSoft.txt";
system($creatingCommand) and die ("ERROR: $0: Cannot create the individuSoft.txt file with the command $creatingCommand \n$!\n");


#######################################
#Cleaning the logs for the test
#######################################
my $cleaningCommand="rm -Rf fastxToolkit_TEST_log.*";
system($cleaningCommand) and die ("ERROR: $0: Cannot clean the previous log files for this test with the command $cleaningCommand \n$!\n");


########################################
##### fastxToolkit::fastxTrimmer
########################################

# input file
my $fastqFile = $expectedData."RC3_1.fastq";

# output file
my $fastqFileOut = "RC3_1.FASTXTRIMMER.fastq";  

# execution test
my %optionsHachees = ("-f" => "8", "-Q33" => "");                             # Hash containing informations
my $optionHachees = \%optionsHachees;                           # Ref of the hash

is(fastxToolkit::fastxTrimmer($fastqFile, $fastqFileOut, $optionHachees),1, 'fastxToolkit::fastxTrimmer');


# expected output test
my $observedOutput = `ls`;
my @observedOutput = split /\n/,$observedOutput;
my @expectedOutput=('fastxToolkit_TEST_log.e','fastxToolkit_TEST_log.o','individuSoft.txt','RC3_1.FASTXTRIMMER.fastq');

is_deeply(\@observedOutput,\@expectedOutput,'fastxToolkit::fastxTrimmer - output list');

###Test for correct file value of fastq trimmed file using a md5sum file control
# expected content test
my $expectedMD5sum = "f9e6e28015919fab27f24dad62cb7a27";                                            # structure of the ref file for checking
my $observedMD5sum = `md5sum $fastqFileOut`;                                                        # structure of the test file for checking
my @withoutName = split (" ", $observedMD5sum);                                                     # to separate the structure and the name of file
$observedMD5sum = $withoutName[0];                                                     #just to have the md5sum result
is($observedMD5sum,$expectedMD5sum,'fastxToolkit::fastxTrimmer - output content');
##############################

exit;