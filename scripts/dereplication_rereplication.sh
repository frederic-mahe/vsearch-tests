#!/bin/bash -

## Print a header
SCRIPT_NAME="Dereplication/rereplication options"
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
[[ "${VSEARCH}" ]] &> /dev/null && success "${DESCRIPTION}" || failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              --derep_fullength                              #
#                                                                             #
#*****************************************************************************#

## --derep_fulllength is accepted
DESCRIPTION="--derep_fulllength is accepted"
printf ">s\nA\n" | \
"${VSEARCH}" --derep_fulllength - --output - &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_fulllength fill a file
DESCRIPTION="--derep_fulllength fill a file"
OUTPUT=$(mktemp)
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ -s "${OUTPUT}" ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_fulllength outputs expected results
DESCRIPTION="--derep_fulllength outputs expected results"
OUTPUT=$(mktemp)
printf ">s\nA\n>d\nA\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s\nA") ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_fulllength outputs expected results (alphabetical order)
## Sort by alphabet but only takes order in account when dereplecating
## (first will be the remaining)
DESCRIPTION="--derep_fulllength outputs expected results (alphabetical order)"
OUTPUT=$(mktemp)
printf ">c\nA\n>b\nG\n>a\nG\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">b\nG\n>c\nA\n") ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_fulllength outputs expected results (case insensitive)
DESCRIPTION="--derep_fulllength outputs expected results (case insensitive)"
OUTPUT=$(mktemp)
printf ">s\nA\n>d\ng\n>f\nA\n>h\nG\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">d\ng\n>s\nA") ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_fulllength outputs expected results (T = U)
DESCRIPTION="--derep_fulllength outputs expected results (T = U)"
OUTPUT=$(mktemp)
printf ">s\nT\n>d\nu\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s\nT") ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                --derep_prefix                               #
#                                                                             #
#*****************************************************************************#

## --derep_prefix is accepted
DESCRIPTION="--derep_prefix is accepted"
printf ">s\nA\n" | \
"${VSEARCH}" --derep_prefix - --output - &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_prefix fill a file
DESCRIPTION="--derep_prefix fill a file"
OUTPUT=$(mktemp)
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ -s "${OUTPUT}" ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix outputs expected results
DESCRIPTION="--derep_prefix outputs expected results"
OUTPUT=$(mktemp)
printf ">s\nACGTAAA\n>d\nACGT\n" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s\nACGTAAA") ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix outputs expected results (alphabetical order)
## Sort by alphabet but only takes order in account when dereplecating
## (first will be the remaining)
DESCRIPTION="--derep_prefix outputs expected results (alphabetical order)"
OUTPUT=$(mktemp)
printf ">c\nACGTAAA\n>b\nACGT\n>a\nCCC" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a\nCCC\n>c\nACGTAAA") ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix outputs expected results (case insensitive)
DESCRIPTION="--derep_prefix outputs expected results (case insensitive)"
OUTPUT=$(mktemp)
printf ">b\nACGTAAA\n>a\nacgt\n" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">b\nACGTAAA") ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix outputs expected results (T = U)
DESCRIPTION="--derep_prefix outputs expected results (T = U)"
OUTPUT=$(mktemp)
printf ">s\nTUTUTT\n>d\nTUTU\n" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s\nTUTUTT") ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                               --maxuniquesize                               #
#                                                                             #
#*****************************************************************************#

## --maxuniquesize is accepted
DESCRIPTION="maxuniquesize is accepted"
printf ">s\nA\n" | \
"${VSEARCH}" --derep_prefix - --output - --maxuniquesize 2 &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --maxuiquesize outputs expected results
DESCRIPTION="--maxuniquesize outputs expected results"
OUTPUT=$(mktemp)
printf ">s;size=3;\nAAAA\n>d;size=2;\nGG" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --sizein --maxuniquesize 2 --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">d;size=2;\nGG") ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# ## --maxuiquesize discard sequence before (de)replication is made
# DESCRIPTION="--maxuiquesize discard sequence before (de)replication is made"
# OUTPUT=$(mktemp)
# printf ">s;size=5;\nAAGT\n>d;size=2;\nAA" | \
#     "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --sizein --maxuniquesize 4 --minseqlength 1 &> /dev/null
# [[ $(cat "${OUTPUT}") == $(printf ">d;size=2;\nAA") ]] &&
#     success "${DESCRIPTION}" || \
# 	failure "${DESCRIPTION}"
# rm "${OUTPUT}"

## --maxuniquesize fails if negative argument
DESCRIPTION="--maxuniquesize fails if negative argument"
printf ">s\nA\n" | \
"${VSEARCH}" --derep_prefix - --output - --maxuniquesize -1 &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --maxuniquesize fails if 0 given
DESCRIPTION="--maxuniquesize fails if 0 given"
printf ">s\nA\n" | \
"${VSEARCH}" --derep_prefix - --output - --maxuniquesize 0 &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

