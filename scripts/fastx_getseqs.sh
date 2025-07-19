#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fastx_getseqs"
LINE=$(printf -- "-%.0s" {1..76})
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

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
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## vsearch --fastx_getseqs fastafile (--fastaout | --fastqout | --notmatched | --notmatchedfq) outputfile (--label label  --labels labelfile | --label_word label | --label_words labelfile) [options]


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_getseqs: keep fastq entries with header field matching --label_word"
printf "@s;field1=s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_field "field1" \
        --label_word "s1" \
        --quiet \
        --fastaout - | \
    grep -qw ">s;field1=s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs: discard fastq entries with header field mismatching --label_word"
printf "@s;field1=s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_field "field1" \
        --label_word "s2" \
        --quiet \
        --fastaout - | \
    grep -qw ">s;field1=s1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

# none

#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    ## memory leak (commit a9c42713: field_buffer was not freed)
    LOG=$(mktemp)
    FASTQ=$(mktemp)
    printf "@s;field1=s1\nA\n+\nI\n" > "${FASTQ}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastx_getseqs "${FASTQ}" \
        --label_field "field1" \
        --label_word "s1" \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --notmatched /dev/null \
        --notmatchedfq /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastx_getseqs --label_field valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_getseqs --label_field valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTQ}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0

