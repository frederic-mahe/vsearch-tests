#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="masking options"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}


## Is vsearch installed?
VSEARCH=$(which vsearch)
DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] && success "${DESCRIPTION}" || failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               Maskfasta                                     #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--maskfasta is accepted"
OUTPUT=$(mktemp)
printf '>seq1\nA\n' | \
    vsearch --maskfasta - --output "${OUTPUT}"  &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--maskfasta if argument given is not valid"
OUTPUT=$(mktemp)
    vsearch --maskfasta OUTEST --output "${OUTPUT}"  &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--maskfasta if no argument"
OUTPUT=$(mktemp)
    vsearch --output "${OUTPUT}" --maskfasta  &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
    rm "${OUTPUT}"

DESCRIPTION="--qmask is accepted with none"
vsearch --qmask none &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask is not accepted with no arguments"
    vsearch --qmask  &> /dev/null && \
    failure "${DESCRIPTION}" ||  \
         success "${DESCRIPTION}"

DESCRIPTION="--qmask is accepted with no arguments"
ERROR=$(vsearch --qmask  2>&1> /dev/null)
[[ -n $ERROR ]]      && \
    success "${DESCRIPTION}" ||  \
         failure "${DESCRIPTION}"

DESCRIPTION="--qmask is accepted with invalid argument"
vsearch --qmask "toto" &> /dev/null && \
	failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"

DESCRIPTION="--maskfasta --qmask none output is correct"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
		vsearch --maskfasta - --qmask none \
			--output - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta --qmask dust output is correct"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
		vsearch --maskfasta - --qmask dust \
			--output - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCtaaaacttaaagtataataataataaaattaaaaaaaaaTGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta --qmask soft output is correct"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
		vsearch --maskfasta - --qmask soft \
			--output - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta --hardmask is accepted"
printf ">seq1\nA\n" | \
    vsearch --maskfasta - --output - --hardmask &>/dev/null && \
    success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta --hardmask --qmask none output is correct"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
		vsearch --maskfasta - --hardmask --qmask none --output - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta --hardmask --qmask soft output is correct"
OUTPUT=$(printf ">seq1\nacctGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCctgg\n" | \
		vsearch --maskfasta - --hardmask --qmask soft --output - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nNNNNGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCNNNN\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta --hardmask --qmask dust output is correct"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
		vsearch --maskfasta - --hardmask --qmask dust \
			--output - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNTGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                fastx_mask                                   #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask is accepted"
OUTPUT=$(mktemp)
printf '>seq1\nA\n' | \
    vsearch --fastx_mask - --fastaout "${OUTPUT}"  &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_mask if argument given is not valid"
OUTPUT=$(mktemp)
    vsearch --fastx_mask OUTEST --output "${OUTPUT}"  &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_mask if no argument"
OUTPUT=$(mktemp)
    vsearch --output "${OUTPUT}" --fastx_mask  &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
    rm "${OUTPUT}"

DESCRIPTION="--fastx_mask --fastaout is accepted"
printf ">seq1\nACG" | \
    vsearch --fastx_mask - fastaout - &> /dev/null 
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --fastqout is accepted"
printf "@seq1\nACG\n+\n!!!" | \
    vsearch --fastx_mask - fastqout - &> /dev/null 
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --qmask none output is correct for a fasta input"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
    vsearch --fastx_mask - --qmask none --fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --qmask dust output is correct for a fasta input"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
		vsearch --fastx_mask - --qmask dust \
			--fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCtaaaacttaaagtataataataataaaattaaaaaaaaaTGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --qmask soft output is correct for a fasta input"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
		vsearch --fastx_mask - --qmask soft \
			--fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            fastq harsmask off                               #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask --qmask none output is correct for a fastq input"
OUTPUT=$(printf '@seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n' | \
		vsearch --fastx_mask - --qmask none --fastqout - --fasta_width 0 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --qmask soft output is correct for a fastq input"
OUTPUT=$(printf '@seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n') | vsearch --fastx_mask - --qmask soft --fastqout - --fasta_width 0 2>/dev/null
[[ "${OUTPUT}" == \
   $(printf '@seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --qmask dust output is correct for a fastq input"
OUTPUT=$(printf '@seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n' | vsearch --fastx_mask - --qmask dust --fastqout - --fasta_width 0 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nACCTGCACATTGTGCACATGTACCCtaaaacttaaagtataataataataaaattaaaaaaaaaTGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            fasta harsmask on                                #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask --qmask none --hardmask output is correct for a fasta input"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
		vsearch --fastx_mask - --qmask none \
			--fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --qmask soft --hardmask output is correct for a fasta input"
OUTPUT=$(printf ">seq1\nACCtgcACATTGTGCACATGTACCCTaaaaCTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATgacCCCACTCCTGG\n" | vsearch --fastx_mask - --qmask soft --hardmask --fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf     ">seq1\nACCNNNACATTGTGCACATGTACCCTNNNNCTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATNNNCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --qmask dust --hardmask output is correct for a fasta input"
OUTPUT=$(printf ">seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n" | \
		vsearch --fastx_mask - --qmask dust --hardmask \
			--fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
   $(printf ">seq1\nACCTGCACATTGTGCACATGTACCCNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNTGCTACAGTATGACCCCACTCCTGG\n") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            fastq harsmask on                                #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask --qmask none --hardmask output is correct for a fastq input"
OUTPUT=$(printf '@seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n' | \
		vsearch --fastx_mask - --qmask none --hardmask --fastqout - --fasta_width 0 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --qmask soft --hardmask output is correct for a fastq input"
OUTPUT=$(printf '@seq1\nACCtcgACATTGTGCACATGTACCCTaaaaCTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGAccccACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n' | \
		vsearch --fastx_mask - --qmask soft --hardmask --fastqout - --fasta_width 0 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nACCNNNACATTGTGCACATGTACCCTNNNNCTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGANNNNACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --qmask dust --hardmask output is correct for a fastq input"
OUTPUT=$(printf '@seq1\nACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n' | \
		vsearch --fastx_mask - --qmask dust --hardmask --fastqout - --fasta_width 0 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nACCTGCACATTGTGCACATGTACCCNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNTGCTACAGTATGACCCCACTCCTGG\n+\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"





#*****************************************************************************#
#                                                                             #
#                            max/min_unmasked_pct                             #    
#                                                                             #
#*****************************************************************************#



DESCRIPTION="--fastx_mask --max_unmasked_pct is accepted"
printf '>seq1\natGC' | \
		vsearch --fastx_mask - --qmask soft --hardmask --max_unmasked_pct 0 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct is accepted"
printf '>seq1\natGC' | \
		vsearch --fastx_mask - --qmask soft --hardmask --min_unmasked_pct 0 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="--fastx_mask --max_unmasked_pct fails if no argument given"
printf '>seq1\natGC' | \
		vsearch --fastx_mask - --qmask soft --hardmask --max_unmasked_pct --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct fails if no argument given"
printf '>seq1\natGC' | \
		vsearch --fastx_mask - --qmask soft --hardmask --min_unmasked_pct --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct fails if value given is false"
printf '>seq1\natGC' | \
		vsearch --fastx_mask - --qmask soft --hardmask --max_unmasked_pct toto --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct fails if value given is false"
printf '>seq1\natGC' | \
		vsearch --fastx_mask - --qmask soft --hardmask --min_unmasked_pct toto --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct gives the correct result"
OUTPUT=$(printf '>seq1\natGC\n>seq2\na' | \
		vsearch --fastx_mask - --qmask soft --hardmask --max_unmasked_pct 49 --fastaout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>seq2\nN') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="--fastx_mask --min_unmasked_pct gives the correct result"
OUTPUT=$(printf '>seq1\natGC\n>seq2\na' | \
		vsearch --fastx_mask - --qmask soft --hardmask --min_unmasked_pct 50 --fastaout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>seq1\nNNGC') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="--fastx_mask --max_unmasked_pct fails if value is greater than 100"
printf '>seq1\natGC\n>seq2\na' | \
		vsearch --fastx_mask - --qmask soft --hardmask --max_unmasked_pct 110 --fastaout - &>/dev/null &&
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct fails if value is greater than 100"
printf '>seq1\natGC\n>seq2\na' | \
		vsearch --fastx_mask - --qmask soft --hardmask --min_unmasked_pct 110 --fastaout - &>/dev/null &&
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct --min_unmasked_pct fails if value between min and 0 with min less than 0"
printf '>seq1\natGC\n>seq2\na' | \
		vsearch --fastx_mask - --qmask soft --hardmask --fastaout - --max_unmasked_pct \-10 --min_unmasked_pct \-40 &>/dev/null &&
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="--fastx_mask --max_unmasked_pct --min_unmasked_pct fails if min between 100 and max with max greater than 100"
printf '>seq1\natGC\n>seq2\na' | \
		vsearch --fastx_mask - --qmask soft --hardmask --max_unmasked_pct 140 --min_unmasked_pct 110 --fastaout - &>/dev/null &&
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct fails if value greater than 100"
printf '>seq1\natGC\n>seq2\na' | \
		vsearch --fastx_mask - --qmask soft --hardmask --fastaout - --max_unmasked_pct \-1 &>/dev/null &&
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="--fastx_mask --max_unmasked_pct --min_unmasked_pct fails if min less than 0"
printf '>seq1\natGC\n>seq2\na' | \
		vsearch --fastx_mask - --qmask soft --hardmask --min_unmasked_pct \-1 --fastaout - &>/dev/null &&
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct --max_unmasked_pct fails if min greater than max"
printf '>seq1\natGC\n>seq2\na' | \
		vsearch --fastx_mask - --qmask soft --hardmask --min_unmasked_pct 60 --max_unmasked_pct 40 --fastaout - &>/dev/null &&
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

