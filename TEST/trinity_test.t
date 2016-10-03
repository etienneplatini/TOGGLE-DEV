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

#Will test if trinity works correctly
use strict;
use warnings;
use Test::More 'no_plan'; #Number of tests, to modify if new tests implemented. Can be changed as 'no_plan' instead of tests=>11 .
use Test::Deep;
use Data::Dumper;
use lib qw(../Modules/);

########################################
#Test of the use of gatk modules
########################################
use_ok('toolbox') or exit;
use_ok('trinity') or exit;

can_ok('trinity','trinityRun');

use toolbox;
use trinity;

my $expectedData="../../DATA/expectedData/contigTrinity.fasta";

#########################################
#Remove files and directory created by previous test
#########################################
my $testingDir="../DATA-TEST/trinityTestDir";
my $creatingDirCom="rm -Rf $testingDir ; mkdir -p $testingDir";                                    #Allows to have a working directory for the tests
system($creatingDirCom) and die ("ERROR: $0 : Cannot execute the command $creatingDirCom\n$!\n");

chdir $testingDir or die ("ERROR: $0 : Cannot go into the new directory with the command \"chdir $testingDir\"\n$!\n");


#######################################
#Creating the IndividuSoft.txt file
#######################################
my $creatingCommand="echo \"trinity\nTEST\" > individuSoft.txt";
system($creatingCommand) and die ("ERROR: $0: Cannot create the individuSoft.txt file with the command $creatingCommand \n$!\n");

#######################################
#Cleaning the logs for the test
#######################################
my $cleaningCommand="rm -Rf trinity_TEST_log.*";
system($cleaningCommand) and die ("ERROR: $0: Cannot clean the previous log files for this test with the command $cleaningCommand \n$!\n");

##########################################
#trinityCreateSequenceDictionary test
##########################################

#Input file
my $forwardFastqFileIn = "../../DATA/testData/fastq/assembly/pairedOneIndivuPacaya/g02L5Mapped_R1.fq";
my @forwardFastqList = ($forwardFastqFileIn);
my @forwardFastqsList = ($forwardFastqFileIn,$forwardFastqFileIn);
my $forwardFastqList = \@forwardFastqList;
    

my $reverseFastqFileIn = "../../DATA/testData/fastq/assembly/pairedOneIndivuPacaya/g02L5Mapped_R2.fq";
my @reverseFastqList = ($reverseFastqFileIn);
my @reverseFastqsList = ($reverseFastqFileIn,$reverseFastqFileIn);
my $reverseFastqList = \@reverseFastqList;

my $trinityPairedOutDir = "./trinityPairedOutdir/"; # output directory must contain the word 'trinity' as a safety precaution, given that auto-deletion can take place
my $trinitySingleOutDir = "./trinitySingleOutdir/";
my $trinitySeveralOutDir = "./trinitySeveralOutdir/";
#my $originalRefFile = $expectedData."/".$refFile;    
#my $cpCmd = "cp $originalRefFile ."; # command to copy the original Ref fasta file into the test directory
#system ($cpCmd) and die ("ERROR: $0 : Cannot copy the file $originalRefFile in the test directory with the command $cpCmd\n$!\n"); 

#Output file
my $readGroup = 'g02L5'; ## à remplacer par le readGroup

#########################################################
###  Test for trinityRun with one bank (paired files)
#########################################################

is(trinity::trinityRun($trinityPairedOutDir,$readGroup,$forwardFastqList,$reverseFastqList),1,'trinity::trinityRun');

# expected output test

my $observedOutput = `ls $trinityPairedOutDir`;
my @observedOutput = split /\n/,$observedOutput;

my @expectedOutput = ($readGroup.'_both.fa',$readGroup.'_both.fa.ok',$readGroup.'_both.fa.read_count',$readGroup.'_inchworm.K25.L25.DS.fa',$readGroup.'_inchworm.K25.L25.DS.fa.finished',$readGroup.'_inchworm.kmer_count',$readGroup.'_jellyfish.kmers.fa',$readGroup.'_jellyfish.kmers.fa.histo',$readGroup.'_left.fa.ok',$readGroup.'_partitioned_reads.files.list',$readGroup.'_partitioned_reads.files.list.ok',$readGroup.'_recursive_trinity.cmds',$readGroup.'_recursive_trinity.cmds.completed',$readGroup.'_recursive_trinity.cmds.ok',$readGroup.'_right.fa.ok',$readGroup.'_Trinity.fasta',$readGroup.'_Trinity.timing');

is_deeply(\@observedOutput,\@expectedOutput,'trinity::trinityRun - output list - One paired bank');
#
## expected content test

my $cmd = 'grep -c "^>" '.$trinityPairedOutDir.$readGroup.'_Trinity.fasta';
#print $cmd;
my $expectedAnswer="13";
my $observedAnswer=`$cmd`;
chomp($observedAnswer);

is($observedAnswer,$expectedAnswer,'trinity::trinityRun- output content - One paired bank');

#########################################################
###  Test for trinityRun with several banks
#########################################################

is(trinity::trinityRun($trinitySeveralOutDir,$readGroup,\@forwardFastqsList,\@reverseFastqsList),1,'trinity::trinityRun');

# expected output test
$observedOutput = `ls $trinitySeveralOutDir`;
@observedOutput = split /\n/,$observedOutput;
@expectedOutput = ($readGroup.'_both.fa',$readGroup.'_both.fa.ok',$readGroup.'_both.fa.read_count',$readGroup.'_inchworm.K25.L25.DS.fa',$readGroup.'_inchworm.K25.L25.DS.fa.finished',$readGroup.'_inchworm.kmer_count',$readGroup.'_jellyfish.kmers.fa',$readGroup.'_jellyfish.kmers.fa.histo',$readGroup.'_left.fa.ok',$readGroup.'_partitioned_reads.files.list',$readGroup.'_partitioned_reads.files.list.ok',$readGroup.'_recursive_trinity.cmds',$readGroup.'_recursive_trinity.cmds.completed',$readGroup.'_recursive_trinity.cmds.ok',$readGroup.'_right.fa.ok',$readGroup.'_Trinity.fasta',$readGroup.'_Trinity.timing');
#

is_deeply(\@observedOutput,\@expectedOutput,'trinity::trinityRun - output list - Several banks');
#
## expected content test

$cmd = 'grep -c "^>" '.$trinitySeveralOutDir.$readGroup.'_Trinity.fasta';
#print $cmd;
$expectedAnswer="9";
$observedAnswer=`$cmd`;
chomp($observedAnswer);

is($observedAnswer,$expectedAnswer,'trinity::trinityRun- output content - Several banks');

#########################################################
###  Test for trinityRun with single mode
#########################################################
my @emptyList = ();
is(trinity::trinityRun($trinitySingleOutDir,$readGroup,\@forwardFastqList,\@emptyList),1,'trinity::trinityRun');

# expected output test
$observedOutput = `ls $trinitySingleOutDir`;
@observedOutput = split /\n/,$observedOutput;
@expectedOutput = ($readGroup.'_inchworm.K25.L25.DS.fa',$readGroup.'_inchworm.K25.L25.DS.fa.finished',$readGroup.'_inchworm.kmer_count',$readGroup.'_jellyfish.kmers.fa',$readGroup.'_jellyfish.kmers.fa.histo',$readGroup.'_partitioned_reads.files.list',$readGroup.'_partitioned_reads.files.list.ok',$readGroup.'_recursive_trinity.cmds',$readGroup.'_recursive_trinity.cmds.completed',$readGroup.'_recursive_trinity.cmds.ok',$readGroup.'_single.fa',$readGroup.'_single.fa.ok',$readGroup.'_single.fa.read_count',$readGroup.'_Trinity.fasta',$readGroup.'_Trinity.timing');
#@expectedOutput = ($readGroup.'_both.fa',$readGroup.'_both.fa.ok',$readGroup.'_both.fa.read_count',$readGroup.'_chrysalis',$readGroup.'_inchworm.K25.L25.DS.fa',$readGroup.'_inchworm.K25.L25.DS.fa.finished',$readGroup.'_inchworm.kmer_count',$readGroup.'_jellyfish.kmers.fa',$readGroup.'_jellyfish.kmers.fa.histo',$readGroup.'_left.fa.ok',$readGroup.'___log.e',$readGroup.'___log.o',$readGroup.'_partitioned_reads.files.list',$readGroup.'_partitioned_reads.files.list.ok',$readGroup.'_read_partitions',$readGroup.'_recursive_trinity.cmds',$readGroup.'_recursive_trinity.cmds.completed',$readGroup.'_recursive_trinity.cmds.ok',$readGroup.'_right.fa.ok',$readGroup.'_Trinity.fasta',$readGroup.'_Trinity.timing');
#

is_deeply(\@observedOutput,\@expectedOutput,'trinity::trinityRun - output list - single mode');
#
## expected content test

$cmd = 'grep -c "^>" '.$trinitySingleOutDir.$readGroup.'_Trinity.fasta';
#print $cmd;
$expectedAnswer="8";
$observedAnswer=`$cmd`;
chomp($observedAnswer);
is($observedAnswer,$expectedAnswer,'trinity::trinityRun- output content - single mode');

1;

#exit;
#__END__