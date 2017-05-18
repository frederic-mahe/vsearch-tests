printf "@s1\nACGT\n+\nGGGG" |
"${VSEARCH}" --fastq_stats - --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"#!/bin/bash -

## Print a header
SCRIPT_NAME="fastq_stats all tests"
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
#                                  --fastaout                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastaout is accepted"
printf "@s1\nA\n+\nG" |
"${VSEARCH}" --fastx_subsample - --fastaout - --sample_size 1 &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout fill a file"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG" |
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout change fastq to fasta"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG" |
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout change fastq to fasta"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG" |
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout fasta to fasta is correct"
OUTPUT=$(mktemp)
printf ">s1\nA" |
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                             --fastaout_discarded                            #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastaout_discarded is accepted"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA" |
    "${VSEARCH}" --fastx_subsample - --fastaout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastaout - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout_discarded fill a file"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA" |
    "${VSEARCH}" --fastx_subsample - --fastaout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastaout - &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout_discarded discard sequences from the input (fasta)"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA" |
    "${VSEARCH}" --fastx_subsample - --fastaout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastaout - &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] ||
    [[ $(cat "${OUTPUT}") == $(printf ">s2\nA") ]] && \
	success  "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout_discarded discard sequences from the input (fastq)"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG" |
    "${VSEARCH}" --fastx_subsample - --fastaout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastaout - &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] ||
    [[ $(cat "${OUTPUT}") == $(printf ">s2\nA") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout_discarded discard sequences from the input (fastq)"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG" |
    "${VSEARCH}" --fastx_subsample - --fastaout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastaout - &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] ||
    [[ $(cat "${OUTPUT}") == $(printf ">s2\nA") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                --fastq_ascii                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastq_ascii is accepted"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" |
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --sizein &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## those 2 tests should fail because Qscores are outside 0-41 range specified by default
## see fastq_qmax
DESCRIPTION="--fastx_subsample --fastq_ascii fails when Qscore is outside specified range +64"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\na\n" |
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --sizein &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_ascii fails when Qscore is outside specified range +33"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" |
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 64 --sizein &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                --fastq_qmax                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastq_qmax is accepted"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA\n" |
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --fastq_qmax 10 &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmax is accepted"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n@s2\nA\n+\n-\n" |
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastqout "${OUTPUT}" \
		 --fastq_ascii 33 --fastq_qmax 1 --sizein --sizeout && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
cat "${OUTPUT}"
rm "${OUTPUT}"
