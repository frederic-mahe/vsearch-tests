#!/bin/bash -

## Print a header
SCRIPT_NAME="fastx_revcomp all tests"
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
#                                  Arguments                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_revcomp is accepted"
printf "@s1\nACGT\n+\nGGGG" | "${VSEARCH}" --fastx_revcomp - --fastqout - --fastaout - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastqout fill a file"
OUTPUT=$(mktemp)
printf "@s1\nACGT\n+\nGGGG" | "${VSEARCH}" --fastx_revcomp - --fastqout "${OUTPUT}" &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastq_stats --fastaout fill a file"
OUTPUT=$(mktemp)
printf "@s1\nACGT\n+\nGGGG" | "${VSEARCH}" --fastx_revcomp - --fastaout "${OUTPUT}" &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastq_stats --fastaout fill a file"
OUTPUT=$(mktemp)
printf "@s1\nACGT\n+\nGGGG" | "${VSEARCH}" --fastx_revcomp - --fastaout "${OUTPUT}" &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastq_stats fails if fasta sequence given with --fastqout option"
printf ">s1\nACGT" | "${VSEARCH}" --fastx_revcomp - --fastqout - &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats reversing-complementing to fasta is correct"
OUTPUT=$(mktemp)
printf ">s1\nGTCA" | "${VSEARCH}" --fastx_revcomp - --fastaout "${OUTPUT}" &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nTGAC") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastq_stats reversing-complementing to fastq is correct"
OUTPUT=$(mktemp)
printf "@s1\nGTCA\n+\nFGHI" | "${VSEARCH}" --fastx_revcomp - --fastqout "${OUTPUT}" &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf "@s1\nTGAC\n+\nIHGF") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastq_stats reversing-complementing fastq to fasta is correct"
OUTPUT=$(mktemp)
printf "@s1\nGTCA\n+\nFGHI" | "${VSEARCH}" --fastx_revcomp - --fastaout "${OUTPUT}" &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nTGAC") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

exit 0
