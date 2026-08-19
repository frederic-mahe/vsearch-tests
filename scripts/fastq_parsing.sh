#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastq parsing"
line=$(printf "%76s\n" " " | tr " " "-")
printf "# %s %s\n" "${line:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "%bFAIL%b: %s\n" "${RED}" "${NO_COLOR}" "${1}"
    exit 1
}

success () {
    printf "%bPASS%b: %s\n" "${GREEN}" "${NO_COLOR}" "${1}"
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
    while read -r f ; do
        DESCRIPTION="fastq parsing: $(basename "${f}") is a valid file"
        "${VSEARCH}" \
            --fastq_chars "${f}" \
            --quiet && \
            success  "${DESCRIPTION}" || \
                failure "${DESCRIPTION}"
    done

## invalid fastq files
find ./data/ -name "error*.fastq" -print | \
    sort | \
    while read -r f ; do
        DESCRIPTION="fastq parsing: $(basename "${f}") is an invalid file"
        "${VSEARCH}" \
            --fastq_chars "${f}" \
            --quiet 2> /dev/null && \
            failure "${DESCRIPTION}" || \
                success "${DESCRIPTION}"
    done


#*****************************************************************************#
#                                                                             #
#                        Illegal character diagnostics                        #
#                                                                             #
#*****************************************************************************#

## The four wordings the FASTQ parser can emit. Each is pinned in full,
## including the reported line number, because the message is assembled from
## three places: the wording, the printable/unprintable branch, and
## fastq_fatal()'s "Invalid line N in FASTQ file: " prefix.

DESCRIPTION="fastq parsing: an illegal printable sequence character is named"
printf '@s\nAZA\n+\nIII\n' | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet 2>&1 > /dev/null | \
    grep -qx "Fatal error: Invalid line 2 in FASTQ file: Illegal sequence character 'Z'" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq parsing: an illegal unprintable sequence character is reported by number"
printf '@s\nA\x01A\n+\nIII\n' | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet 2>&1 > /dev/null | \
    grep -qx "Fatal error: Invalid line 2 in FASTQ file: Illegal sequence character (unprintable, no 1)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## a space is the *only* printable character a quality line can reject: every
## other byte from 33 to 126 is a legal quality symbol
DESCRIPTION="fastq parsing: a space in a quality line is named as an illegal character"
printf '@s\nAAA\n+\nI I\n' | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet 2>&1 > /dev/null | \
    grep -qx "Fatal error: Invalid line 4 in FASTQ file: Illegal quality character ' '" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq parsing: an illegal unprintable quality character is reported by number"
printf '@s\nAAA\n+\nI\x01I\n' | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet 2>&1 > /dev/null | \
    grep -qx "Fatal error: Invalid line 4 in FASTQ file: Illegal quality character (unprintable, no 1)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


exit 0
