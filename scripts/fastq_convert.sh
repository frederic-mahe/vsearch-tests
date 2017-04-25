#!/bin/bash -

## Print a header
SCRIPT_NAME="Test options"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    exit -1
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
#                                   General                                   #
#                                                                             #
#*****************************************************************************#

## --fastq_convert is accepted with its necessary arguments
OUTPUT=$(mktemp)
printf "@a\nAAAA\n
DESCRIPTION="--fastq_convert is accepted with its necessary arguments"
"${VSEARCH}" --fastq_convert "${ALL_IDENTICAL}" --fasq_ascii 33 --fastqout &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

rm "${ALL_IDENTICAL}"


