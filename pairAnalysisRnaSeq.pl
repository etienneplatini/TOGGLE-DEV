#!/opt/perl-5.16.2/bin/perl


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
use warnings;
use lib qw(/data/projects/Floripalm/STAGE-SOUHILA/TOGGLE/Modules);
use localConfig;
use Data::Dumper;



use cutadapt;
use fastqc;
use fastqUtils;
use pairing;
use toolbox;
use fastxToolkit;
use tophat;
use cufflinks;

##########################################
# recovery of initial informations/files
##########################################
my $initialDir = $ARGV[0];                                                                                  # recovery of the name of the directory to analyse
my $fileConf = $ARGV[1];                                                                                    # recovery of the name of the software.configuration.txt file
my $refFastaFile = $ARGV[2];                                                                                # recovery of the reference file
my $gffFile = $ARGV[3];
my $annotGffFile = $ARGV[4];
$refFastaFile =~ /^([^\.]+)\./;                                                                    # catch o,ly the file name without the file extension and store it into $prefixRef variable
my $prefixRef = $1;

toolbox::existsDir($initialDir);                                                                            # check if this directory exists




##########################################
# Creation of IndividuSoft.txt for creation of logs files later
##########################################
my @pathIndividu = toolbox::extractPath($initialDir);
my $individu = $pathIndividu[0];
chdir "$initialDir";
my $infosFile = "individuSoft.txt";
#my $infosFile = "$pathIndividu[1]/individuSoft.txt";
open (F1, ">",$infosFile) or die ("ERROR: $0 : Cannot open the file $infosFile\n$!\n");
print F1 "$individu\n";
print F1 "Initialization\n";


my $indivName = `head -n 1 individuSoft.txt`;
chomp $indivName;

my $logFile=$indivName."_Global"."_log";
open (LOG, ">",$logFile) or die ("ERROR: $0 : Cannot open the file $logFile\n$!\n");
print LOG "#########################################\nINFOS: Paired sequences analysis started\n#########################################\n\n";

toolbox::checkFile($fileConf);                                                                              # check if this file exists
toolbox::checkFile($refFastaFile);                                                                          # check if the reference file exists

my $optionref = toolbox::readFileConf($fileConf); 


### Create the Arborescence
toolbox::makeDir("$initialDir/0_PAIRING_FILES/");
toolbox::makeDir("$initialDir/1_FASTQC/");
toolbox::makeDir("$initialDir/11_FASTX/");
toolbox::makeDir("$initialDir/2_CUTADAPT/");
toolbox::makeDir("$initialDir/3_PAIRING_SEQUENCES/");
toolbox::makeDir("$initialDir/4_MAPPING/");
toolbox::makeDir("$initialDir/41_CUFFLINKS/");
toolbox::makeDir("$initialDir/5_PICARDTOOLS/");
toolbox::makeDir("$initialDir/6_SAMTOOLS/");
toolbox::makeDir("$initialDir/7_GATK/");


### Copy fastq into 0_PAIRING_FILES/    
my $copyCom = "cp $initialDir/*.fastq $initialDir/0_PAIRING_FILES/.";                               # command to move the initial fastq files into the directory appropriate for the pipeline
toolbox::run($copyCom);                                                                             # move the files
  
my $removeCom = "rm $initialDir/*.fastq";                                                            # command to remove the files in the main directory
toolbox::run($removeCom); 




### Check the number of fastq
my $initialsFiles = toolbox::readDir($initialDir."/0_PAIRING_FILES/");                               # read it to recover files in it
##DEBUG print LOG "INFOS: toolbox::ReadDir : @$initialsFiles\n";
##DEBUG print LOG "----------------------------------------\n";
my @initialsFiles = @$initialsFiles;

if (@$initialsFiles != 2)                                                                            # check if the number of files in the direcory is two as excpected for pair analysis
{
    toolbox::exportLog("ERROR: $0 : The directory ".$initialDir."/0_PAIRING_FILES/ don't contain the right number of files\n",1);
}





# to all files on
for (my $i=0; $i<=$#initialsFiles; $i++)
{
    ##########################################
    # fastqUtils::checkNumberByWC
    ##########################################
    print LOG "INFOS: $0 : Checking sequences number on file $initialsFiles[$i]\n";

    #print F1 "checkNumberByWC\n";
    my $numberOfReads = fastqUtils::checkNumberByWC($initialsFiles[$i]);                                      # check the number of sequences
    print LOG "INFOS: $0 : Number of reads: $numberOfReads\n";
    ##########################################
    # fastqUtils::checkEncodeByASCIIcontrol
    ##########################################
    my $phred33Control = fastqUtils::checkEncodeByASCIIcontrol($initialsFiles[$i]);                           # check the encode format (PHRED 33 or 64)
    print LOG "INFOS: $0 : Return 1 if PHRED33, 0 if PHRED64: $phred33Control\n";
    print LOG "----------------------------------------\n";
    ##########################################
    # fastqUtils::changeEncode
    ##########################################
    if ( not $phred33Control )                                                                          # if encode format is PHRED 64 then convert it in PHRED 33
    {
        print LOG "INFOS: $0 : Change encoding quality from 64 to 33\n";
        print LOG "----------------------------------------\n";
        my $tmpFile=$initialsFiles[$i]."sanger.tmp";
        fastqUtils::changeEncode($initialsFiles[$i],$tmpFile,64,33);                                    # change encode from PHRED 64 to PHRED 33
        my $moveCom="mv $tmpFile $initialsFiles[$i]";
        system($moveCom) and die ("ERROR: $0 : Cannot create the file with the good quality with the command $moveCom \n$!\n");     
    }
    ##########################################
    # fastqc::execution
    ##########################################
    print LOG "INFOS: $0 : Start FASTQC\n";
    print F1 "FastQC\n";
    my @fileAndPath = toolbox::extractPath($initialsFiles[$i]);                                               # recovery of file name and path to have it
    print LOG "INFOS: $0 : File: $fileAndPath[0]\n";
    ##DEBUG print LOG "INFOS extract path: $fileAndPath[1]\n";
    my $newDir = toolbox::changeDirectoryArbo($initialDir,1);                                                  # change for the FASTQC directory
    ##DEBUG print LOG "CHANGE DIRECTORY TO $newDir\n";
    fastqc::execution($initialsFiles[$i],$newDir);                                                            # run fastQC program on current file
    ##########################################
    # fastqc::parse
    ##########################################
    my $fastqcStats = fastqc::parse($newDir);                                                               # parse fastQC file to get statistics of fastqc
    print LOG "INFOS statistics of fastqc: \n";
    print LOG Dumper ($fastqcStats);
    print LOG "----------------------------------------\n";
    ##########################################
    # fastxToolkit::fastxTrimmer                                                                        
    ##########################################
    print LOG "INFOS: $0 : start fastx_trimmer\n";
    print F1 "fastxTrimmer\n";                                             
    print LOG "INFOS: $0 : File: $fileAndPath[0]\n";
    ##DEBUG print LOG "INFOS extract path: $fileAndPath[1]\n";

    
    my $softParameters = toolbox::extractHashSoft($optionref,"fastx_trimmer");                              # get options for fastqx_trimmer
 
    $newDir = toolbox::changeDirectoryArbo($initialDir,11);                                              # change for the trimmer directory
    ##DEBUG print LOG "CHANGE DIRECTORY TO $newDir\n";
    my $fileBasename=toolbox::extractName($initialsFiles[$i]);                                              # get the fastq filename without the complete path and the extension
    my $fileTrimmed= $newDir."/".$fileBasename.".FASTXTRIMMER.fastq";                                       # define the filename generated by trimmer 
    fastxToolkit::fastxTrimmer($initialsFiles[$i],$fileTrimmed,$softParameters);
}

##########################################
# cutadapt::createConfFile
##########################################
print LOG "INFOS: $0 : Start cutadapt create configuration file\n";
print F1 "cutadapt\n";
my $newDir = toolbox::changeDirectoryArbo($initialDir,2);                                                   # change for the cutadapt directory
my $cutadaptDir = $newDir;                                                                                  # to keep the information of cutadapt folder for the following analysis
##DEBUG print LOG "CHANGE DIRECTORY TO $newDir\n";
my $fileAdaptator = "$toggle/adaptator.txt";     # /!\ ARGV[3] et si non reseignÃ© ce fichier lÃ , mais on le place oÃ¹ ?
toolbox::checkFile($fileAdaptator);
my $cutadaptSpecificFileConf = "$newDir"."/cutadapt.conf";                                                  # name for the cutadapt specific configuration file

my $softParameters = toolbox::extractHashSoft($optionref, "cutadapt");                                     # recovery of specific informations for cutadapt

##DEBUG print LOG "DEBUG: optionref\n";
##DEBUG print LOG Dumper ($optionref);
cutadapt::createConfFile($fileAdaptator, $cutadaptSpecificFileConf, $softParameters);                            # create the configuration file specific to cutadapt software

my $trimmedFiles=toolbox::readDir($initialDir."/11_FASTX/");
my @trimmedFiles=@$trimmedFiles;
##DEBUG print LOG Dumper(@trimmedFiles);

# A FAIRE SUR TOUT LES FICHIERS
for (my $i=0; $i<=$#trimmedFiles; $i++)
{
    ##########################################
    # cutadapt::execution
    ##########################################
    print LOG "INFOS: $0 : Start cutadapt execution on file $trimmedFiles[$i]\n";
    $newDir = toolbox::changeDirectoryArbo($initialDir,2);                                                  # change for the cutadapt directory
    ##DEBUG print LOG "CHANGE DIRECTORY TO $newDir\n";
    my $fileWithoutExtention = toolbox::extractName($trimmedFiles[$i]);                                      # extract name of file without the extention
    my $fileOut = "$newDir"."/"."$fileWithoutExtention".".CUTADAPT.fastq";                                  # name for the output file of cutadapt execution
    cutadapt::execution($trimmedFiles[$i],$cutadaptSpecificFileConf,$fileOut);                               # run cutadapt program on current file
}

##########################################
# pairing::repairing
##########################################
print LOG "----------------------------------------\n";
print LOG "INFOS: $0 : Start pairing sequences\n";
print F1 "PairingSequences\n";
$newDir = toolbox::changeDirectoryArbo($initialDir,3);                                                      # change for the pairing_sequences directory
my $repairingDir = $newDir;                                                                                 # to keep the information of repairing folder for the following analysis
##DEBUG print LOG "CHANGE DIRECTORY TO $newDir\n";
my $cutadaptList = toolbox::readDir($cutadaptDir);                                                          # read it to recover files in it
##DEBUG print LOG "INFOS toolbox ReadDir: @$cutadaptList\n";
my @cutadaptList = @$cutadaptList;
my @finalCutadaptList;


for (my $i=0; $i<=$#cutadaptList; $i++)
{
    if ($cutadaptList[$i]=~m/cutadapt.conf/)
    {
        next;
    }
    else
    {
        push (@finalCutadaptList,"$cutadaptList[$i]");
    }
}

pairing::repairing($finalCutadaptList[0],$finalCutadaptList[1],$newDir);                                                    # from two de-paired files, forward + reverse, will create three files, forward, reverse and singl

##########################################
# tophat::bowtieBuild
##########################################
print LOG "----------------------------------------\n";
print LOG "INFOS: $0 : Start BOWTIEBUILD\n";
print F1 "BOWTIEBUILD\n";
$newDir = toolbox::changeDirectoryArbo($initialDir,4);                                                  # change for the Mapper direcotry
my $tophatDir = $newDir;                                                                                # to keep the information of tophat folder for the following analysis
##DEBUG
print LOG "CHANGE DIRECTORY TO $newDir\n";

$softParameters = toolbox::extractHashSoft($optionref, "bowtieBuild");                              # recovery of specific parameters of bowtiebuild index

#tophat::bowtieBuild($refFastaFile,$softParameters);                                           # indexation of Reference sequences file



##########################################
# tophat::bowtie2Build
##########################################
print LOG "----------------------------------------\n";
print LOG "INFOS: $0 : Start BOWTIE2-BUILD\n";
print F1 "BOWTIE2BUILD\n";
$newDir = toolbox::changeDirectoryArbo($initialDir,4);                                                  # change for the Mapper direcotry
$tophatDir = $newDir;                                                                                # to keep the information of tophat folder for the following analysis
##DEBUG
print LOG "CHANGE DIRECTORY TO $newDir\n";
$softParameters = toolbox::extractHashSoft($optionref, "bowtie2-build");                              # recovery of specific parameters of bowtie2build index
my $refIndex=tophat::bowtie2Build($refFastaFile,$softParameters);                                           # indexation of Reference sequences file



##########################################
# tophat::tophat2
##########################################

print LOG "INFOS: $0 : start tophat2\n";
print F1 "tophat2\n";
$newDir = toolbox::changeDirectoryArbo($initialDir,4);
$tophatDir = $newDir;
##DEBUG print LOG "CHANGE DIRECTORY TO $newDir\n";

my $repairingList = toolbox::readDir($repairingDir);
##DEBUGprint LOG "INFOS toolbox ReadDir: @$repairingList\n";
my @repairingList = @$repairingList;

$softParameters = toolbox::extractHashSoft($optionref,"tophat2");                                       # recovery of specific parameters of tophat2 aln
my $tophatdirOut = $newDir;   #créer le répertoire des résultats de topaht

print LOG "INFOS tophats argument: $tophatdirOut,$refIndex,$repairingList[0],$repairingList[1],$gffFile";
tophat::tophat2($tophatdirOut,$refIndex,$repairingList[0],$repairingList[1],$gffFile,$softParameters);


##########################################
# cufflinks::execution
##########################################

print LOG "INFOS: $0 : start execution\n";
print F1 "execution\n";
$newDir = toolbox::changeDirectoryArbo($initialDir,41);
my $cufflinksDir = $newDir;
##DEBUG print LOG "CHANGE DIRECTORY TO $newDir\n";

my $mappingList = toolbox::readDir($tophatDir);
##DEBUGprint LOG "INFOS toolbox ReadDir: @$tophatList\n";
my @mappingList = @$mappingList;

$softParameters = toolbox::extractHashSoft($optionref,"cufflinks");                                       # recovery of specific parameters of tophat2 aln
my $cufflinksdirOut = $newDir;   #créer le répertoire des résultats de cufflinks

cufflinks::execution($cufflinksdirOut,$mappingList[0],$annotGffFile,$softParameters);


print LOG "#########################################\nINFOS: Paired sequences analysis done correctly\n#########################################\n";

close F1;
close LOG;

exit;
