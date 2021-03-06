#!/usr/bin/perl

###################################################################################################################################
#
# Copyright 2014-2017 IRD-CIRAD-INRA-ADNid
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
# Version 3 written by Cecile Monat, Christine Tranchant, Laura Helou, Abdoulaye Diallo, Julie Orjuela-Bouniol, Sebastien Ravel, Gautier Sarah, and Francois Sabot
#
###################################################################################################################################

#Will test if checkFormat.pm works correctly
use strict;
use warnings;
use Test::More 'no_plan'; #Number of tests, to modify if new tests implemented. Can be changed as 'no_plan' instead of tests=>11 .
use Test::Deep;
use Data::Dumper;
use lib qw(../../modules/);

########################################
#Test of the use of checkFormat modules
########################################

use_ok('localConfig') or exit;
use_ok('checkFormat') or exit;
can_ok('checkFormat','checkFormatVcf');
can_ok('checkFormat','checkFormatFasta');
can_ok('checkFormat','checkFormatFastq');
can_ok('checkFormat','checkFormatSamOrBam');

use localConfig;
use checkFormat;

my $expectedData="$toggle/data/expectedData/";
my $configFile="$toggle/exampleConfigs/SNPdiscoveryPaired.config.txt";

#########################################
#Remove files and directory created by previous test
#########################################
my $testingDir="$toggle/dataTest/checkFormatTestDir";
my $creatingDirCom="rm -Rf $testingDir ; mkdir -p $testingDir";                                    #Allows to have a working directory for the tests
system($creatingDirCom) and die ("ERROR: $0 : Cannot execute the command $creatingDirCom\n$!\n");

chdir $testingDir or die ("ERROR: $0 : Cannot go into the new directory with the command \"chdir $testingDir\"\n$!\n");

#######################################
#Creating the IndividuSoft.txt file
#######################################
my $creatingCommand="echo \"checkFormat\nTEST\" > individuSoft.txt";
system($creatingCommand) and die ("ERROR: $0: Cannot create the individuSoft.txt file with the command $creatingCommand \n$!\n");

#######################################
#Cleaning the logs for the test
#######################################
my $cleaningCommand="rm -Rf checkFormat_TEST_log.*";
system($cleaningCommand) and die ("ERROR: $0: Cannot clean the previous log files for this test with the command $cleaningCommand \n$!\n");


#######################################
#charge needed test files into variables
#######################################

#Fastq file
my $fastqFile=$expectedData."RC3_1.fastq";

#Sam file
my $samFile=$expectedData."RC3.BWASAMPE.sam";

#Bam file
my $bamFile=$expectedData."RC3.PICARDTOOLSSORT.bam";

#VCF file
my $vcfFile=$expectedData."GATKHAPLOTYPECALLER.vcf";

#Fasta files
my $reference=$expectedData."correctReference.fasta";
my $wrongFasta=$expectedData."wrongReference.fasta";

########################################
#File Format test
########################################
########################################
#checkFormat::checkFormatFastq
########################################
is(checkFormat::checkFormatFastq($fastqFile),'1', 'checkFormat::checkFormatFastq - OK');

########################################
#checkFormat::checkFormatSamOrBam
########################################
is (checkFormat::checkFormatSamOrBam($samFile),'1', 'checkFormat::checkFormatSamOrBam - sam format');
is (checkFormat::checkFormatSamOrBam($bamFile),'2', 'checkFormat::checkFormatSamOrBam - bam format');

########################################
#checkFormat::checkFormatFasta
########################################
is (checkFormat::checkFormatFasta($reference),'1','checkFormat::checkFormatFasta - Format Ok');
is (checkFormat::checkFormatFasta($wrongFasta),'0','checkFormat::checkFormatFasta - Format not Ok, warnings send');

########################################
#checkFormat::checkFormatVcf test TODO add test negatif
########################################
is (checkFormat::checkFormatVcf($vcfFile),'1','checkFormat::checkFormatVcf - vcf file');
#isnt (toolbox::checkVcfFormat($samFile),'1','Test for checkVcfFormat - sam file');
