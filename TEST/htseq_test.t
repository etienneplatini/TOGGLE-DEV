#!/usr/bin/perl -w

###################################################################################################################################
#
# Copyright 2014 IRD-CIRAD
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
# Intellectual property belongs to IRD, CIRAD and South Green developpement plateform
# Written by Cecile Monat, Christine Tranchant, Ayite Kougbeadjo, Cedric Farcy, Mawusse Agbessi, Marilyne Summo, and Francois Sabot
#
###################################################################################################################################


use strict;

#Will test if tophat works correctly
use warnings;
use Test::More 'no_plan'; #Number of tests, to modify if new tests implemented. Can be changed as 'no_plan' instead of tests=>11 .
use Test::Deep;
use lib qw(../Modules/);
use Data::Dumper;

#######################################
#Creating the IndividuSoft.txt file
#######################################
my $creatingCommand="echo \"htseq\nTEST\" > individuSoft.txt";
system($creatingCommand) and die ("ERROR: $0: Cannot create the individuSoft.txt file with the command $creatingCommand \n$!\n");


#######################################
#Cleaning the logs for the test
#######################################
my $cleaningCommand="rm -rf htseq_TEST_log.*";
system($cleaningCommand) and die ("ERROR: $0: Cannot clean the previous log files for this test with the command $cleaningCommand \n$!\n");

########################################
#initialisation and setting configs
########################################
my $testingDir="../DATA-TEST/htseqTestDir";
my $creatingDirCom="rm -rf $testingDir ; mkdir -p $testingDir";                                    #Allows to have a working directory for the tests
system($creatingDirCom) and die ("ERROR: $0 : Cannot execute the command $creatingDirCom\n$!\n");

my $originalBam="../DATA/expectedData/tophat/accepted_hits.SAMTOOLSSORT.bam";
my $bam="$testingDir/accepted_hits.SAMTOOLSSORT.bam";
my $bamCopyCom="cp $originalBam $bam";
system($bamCopyCom) and die ("ERROR: $0 : Cannot copy the bam file $originalBam with the command $bamCopyCom\n$!\n");     #Now we have a bam to be tested

my $OriginalGffRef="../DATA/expectedData/referenceRNASeq.gff3";
my $gffRef="$testingDir/referenceRNASeq.gff3";
my $gffCopyCom="cp $OriginalGffRef $gffRef";
system($gffCopyCom) and die ("ERROR: $0 : Cannot copy the gff Reference $OriginalGffRef with the command $gffCopyCom\n$!\n");     #Now we have a gff to be tested

########################################
#use of module ok
########################################
use_ok('toolbox') or exit;
use_ok('HTSeq') or exit;
can_ok( 'HTSeq','htseqCount');

use toolbox;
use HTSeq;


########################################
#HTSeq::htseqCount
########################################
my %optionsHachees = ("-r" => "name", "-s" => "no", "-t" => "mRNA",  "-m" => "union",  "-i" => "ID",  "-f" => "bam");        # Hash containing informations
my $optionHachees = \%optionsHachees;                           # Ref of the hash

my $htseqcountFile=$testingDir."/accepted_hits.HTSEQCOUNT.txt";
is(HTSeq::htseqCount($bam, $htseqcountFile,$gffRef, $optionHachees),1,'OK for htseqCount RUNNING');


##Test for correct file using md5sum
my $expectedMD5sum="d2c759b28024b0f51d8feeaa65d31205";
my $observedMD5sum=`md5sum $htseqcountFile`;# structure of the test file
my @withoutName = split (" ", $observedMD5sum);     # to separate the structure and the name of the test file
$observedMD5sum = $withoutName[0];       # just to have the md5sum result
is($observedMD5sum,$expectedMD5sum,'Ok for the content of the file generated by htseq-count');