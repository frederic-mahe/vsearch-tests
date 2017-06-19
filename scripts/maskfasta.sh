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
#                               General options                               #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastaout is accepted"
OUTPUT=$(mktemp)
vsearch --fastaout "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastaout is accepted with fastx_mask"
OUTPUT=$(mktemp)
printf '>seq1\nA\n' | \
vsearch --fastx_mask - --fastaout "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastaout fails if no filename given"
vsearch --fastaout &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastqout is accepted"
OUTPUT=$(mktemp)
vsearch --fastqout "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastqout is accepted with fastx_mask"
OUTPUT=$(mktemp)
printf '@seq1\nA\n+\n!' | \
vsearch --fastx_mask - --fastqout "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastqout fails if no filename given"
vsearch --fastqout &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--qmask is accepted"
printf '@seq1\nA\n+\n!\n' | \
vsearch --qmask none &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask fails if argument given is not valid"
vsearch --qmask 6T &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

exit 0
