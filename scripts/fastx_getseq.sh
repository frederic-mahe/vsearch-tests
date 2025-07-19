#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fastx_getseq"
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

## vsearch --fastx_getseq fastafile (--fastaout | --fastqout | --notmatched | --notmatchedfq) outputfile --label label [options]


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## The --fastx_getseq command requires the header to match a label
## specified with the --label option
DESCRIPTION="--fastx_getseq: keep fastq entries with headers matching --label"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --quiet \
    --fastqout - | \
    grep -qw "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: discard fastq entries with headers mismatching --label"
printf "@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --quiet \
    --fastqout - | \
    grep -qw "@s2" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## These matches are not case-sensitive
DESCRIPTION="--fastx_getseq: keep fastq entries with headers matching --label (case-insensitive)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "S1" \
    --quiet \
    --fastqout - | \
    grep -qw "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: keep fastq entries with headers matching --label (case is not modified)"
printf "@S1\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --quiet \
    --fastqout - | \
    grep -qw "@S1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## If the --label_substr_match option is given, the label may be a
## substring located anywhere in the header
DESCRIPTION="--fastx_getseq: --label_substr_match keep fastq entries with headers superstrings of --label"
printf "@s11\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --label_substr_match \
    --quiet \
    --fastqout - | \
    grep -qw "@s11" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: --label_substr_match keep fastq entries with headers superstrings of --label (located anywhere)"
printf "@1s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --label_substr_match \
    --quiet \
    --fastqout - | \
    grep -qw "@1s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## The headers in the input file are truncated at the first space or
## tab character unless the --notrunclabels option is given.
DESCRIPTION="--fastx_getseq: keep fastq entries with headers matching --label after truncation (space)"
printf "@s1 suffix\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --quiet \
    --fastqout - | \
    grep -qw "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: keep fastq entries with headers matching --label after truncation (tab)"
printf "@s1\tsuffix\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --quiet \
    --fastqout - | \
    grep -qw "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: discard fastq entries with full-length headers mismatching --label (no truncation)"
printf "@s1 suffix\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --notrunclabels \
    --label "s1" \
    --quiet \
    --fastqout - | \
    grep -q "^@s1 suffix$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: keep fastq entries with headers superstrings of --label no truncation (prefix position)"
printf "@s1 suffix\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --notrunclabels \
    --label "s1" \
    --label_substr_match \
    --quiet \
    --fastqout - | \
    grep -q "^@s1 suffix$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: keep fastq entries with headers superstrings of --label no truncation (suffix position)"
printf "@prefix s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --notrunclabels \
    --label "s1" \
    --label_substr_match \
    --quiet \
    --fastqout - | \
    grep -q "^@prefix s1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## The matching sequences will be written to the files specified with
## the --fastaout and --fastqout options, in FASTA and FASTQ format,
## respectively. Sequences that do not match are written to the files
## specified with the --notmatched and --notmatchedfq options,
## respectively.



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
    LOG=$(mktemp)
    FASTQ=$(mktemp)
    printf "@s1\nA\n+\nI\n" > "${FASTQ}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastx_getseq "${FASTQ}" \
        --label "s1" \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --notmatched /dev/null \
        --notmatchedfq /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastx_getseq valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_getseq valgrind (no errors)"
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

