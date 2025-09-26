#!/bin/bash -

## Print a header
SCRIPT_NAME="fastq parsing"
line=$(printf "%76s\n" | tr " " "-")
printf "# %s %s\n" "${line:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    exit 1
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}

## use the first binary in $PATH by default, unless user wants
## to test another binary
VSEARCH=$(which vsearch 2> /dev/null)
[[ "${1}" ]] && VSEARCH="${1}"

DESCRIPTION="check if vsearch is executable"
[[ -x "${VSEARCH}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#               Fastq valid and invalid examples (Cocks, 2010)                #
#                                                                             #
#*****************************************************************************#

## valid fastq files
find ./data/ -name "*.fastq" ! -name "error*" -print | \
    sort | \
    while read f ; do
        DESCRIPTION="fastq parsing: $(basename ${f}) is a valid file"
        "${VSEARCH}" \
            --fastq_chars "${f}" \
            --quiet && \
            success  "${DESCRIPTION}" || \
                failure "${DESCRIPTION}"
    done

## invalid fastq files
find ./data/ -name "error*.fastq" -print | \
    sort | \
    while read f ; do
        DESCRIPTION="fastq parsing: $(basename ${f}) is an invalid file"
        "${VSEARCH}" \
            --fastq_chars "${f}" \
            --quiet 2> /dev/null && \
            failure "${DESCRIPTION}" || \
                success "${DESCRIPTION}"
    done


exit 0
