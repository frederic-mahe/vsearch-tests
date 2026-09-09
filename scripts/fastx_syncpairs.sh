#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastx_syncpairs"
LINE=$(printf "%76s\n" " " | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

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
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------- option is valid

DESCRIPTION="--fastx_syncpairs is a valid command"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- reverse

DESCRIPTION="--fastx_syncpairs requires --reverse"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------- mandatory output file

DESCRIPTION="--fastx_syncpairs requires an output file"
REVERSE=$(mktemp)
printf "@s\nA\n+\nI\n" > "${REVERSE}"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout as the only output (fastq in)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastaout as the only output (fastq in)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastaout_rev as the only output"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout_rev /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout_rev as the only output (fastq in)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout_rev /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                          input and output formats                           #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs accepts fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf ">s\nA\n") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs fastqout requires fastq input (fasta in)"
REVERSE=$(mktemp)
printf ">s\nA\n" > "${REVERSE}"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs fastqout_rev requires fastq input (fasta in)"
REVERSE=$(mktemp)
printf ">s\nA\n" > "${REVERSE}"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout_rev /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs fastqout_orphans requires fastq input (fasta in)"
REVERSE=$(mktemp)
printf ">s\nA\n" > "${REVERSE}"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout_orphans /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs fastqout_orphans_rev requires fastq input (fasta in)"
REVERSE=$(mktemp)
printf ">s\nA\n" > "${REVERSE}"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout_orphans_rev /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs rejects a mix of fasta forward and fastq reverse"
REVERSE=$(mktemp)
printf "@s\nA\n+\nI\n" > "${REVERSE}"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs rejects a mix of fastq forward and fasta reverse"
REVERSE=$(mktemp)
printf ">s\nA\n" > "${REVERSE}"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs writes fasta output from fastq input (drops quality)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs writes fastq output from fastq input"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs errors if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"  # remove write permission
REVERSE=$(mktemp)
printf "@s\nA\n+\nI\n" > "${REVERSE}"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout "${TMP}" 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_syncpairs accepts empty input (both forward and reverse)"
printf "" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## a non-empty forward with an empty reverse: every forward read is an
## orphan, no pair is synchronized
DESCRIPTION="--fastx_syncpairs accepts a non-empty forward with an empty reverse"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs sends a forward read to orphans when the reverse is empty"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## an empty forward with a non-empty reverse: every reverse read is an
## orphan, no pair is synchronized
DESCRIPTION="--fastx_syncpairs accepts an empty forward with a non-empty reverse"
printf "" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf ">s\nA\n") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## when both inputs are empty the format cannot be determined, and fastq
## output is accepted (and remains empty)
DESCRIPTION="--fastx_syncpairs accepts empty forward and reverse with --fastqout"
printf "" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "") \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## the effective format follows the non-empty input file: an empty
## forward with a fastq reverse allows fastq output
DESCRIPTION="--fastx_syncpairs allows fastq output when only the reverse is non-empty"
printf "" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@r\nTT\n+\nII\n") \
        --fastqout_rev /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs writes fastq reverse orphans when the forward is empty"
printf "" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@r\nTT\n+\nII\n") \
        --fastqout_orphans_rev - 2> /dev/null | \
    grep -qx "@r" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs rejects fastq output when the non-empty input is fasta"
printf "" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf ">r\nTT\n") \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs errors if the forward input file does not exist"
"${VSEARCH}" \
    --fastx_syncpairs /no/such/file \
    --reverse <(printf "@s\nA\n+\nI\n") \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs errors if the reverse input file does not exist"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse /no/such/file \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs errors if the forward input file is not readable"
FORWARD=$(mktemp)
printf "@s\nA\n+\nI\n" > "${FORWARD}"
chmod u-r "${FORWARD}"
"${VSEARCH}" \
    --fastx_syncpairs "${FORWARD}" \
    --reverse <(printf "@s\nA\n+\nI\n") \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${FORWARD}" && rm -f "${FORWARD}"
unset FORWARD

DESCRIPTION="--fastx_syncpairs errors if the reverse input file is not readable"
REVERSE=$(mktemp)
printf "@s\nA\n+\nI\n" > "${REVERSE}"
chmod u-r "${REVERSE}"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${REVERSE}" && rm -f "${REVERSE}"
unset REVERSE


#*****************************************************************************#
#                                                                             #
#                          synchronization behaviour                          #
#                                                                             #
#*****************************************************************************#

## The forward file gives the output order. Forward holds a then b, the
## reverse file holds b then a; the synced reverse reads must come out in
## the forward order (a's mate, then b's mate).

DESCRIPTION="--fastx_syncpairs emits synced forward reads in forward order"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@b 2:N:0:1\nTT\n+\nII\n@a 2:N:0:1\nGG\n+\nII\n") \
        --fastaout - 2> /dev/null | \
    grep "^>" | \
    tr -d '\n' | \
    grep -q ">a 1:N:0:1>b 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs reorders the reverse reads to match the forward order"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@b 2:N:0:1\nTT\n+\nII\n@a 2:N:0:1\nGG\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_rev - 2> /dev/null | \
    grep -v "^>" | \
    tr -d '\n' | \
    grep -qx "GGTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs discards orphans by default (forward-only read absent)"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout - 2> /dev/null | \
    grep -q "^>b" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs synchronizes the shared read despite an orphan"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout - 2> /dev/null | \
    grep -qx ">a 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs writes all four fastq lines for a synced read"
printf "@s\nACGT\n+\nHHII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nTGCA\n+\nIIHH\n") \
        --fastqout - 2> /dev/null | \
    tr '\n' ' ' | \
    grep -qx "@s ACGT + HHII " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## reordering the reverse reads must keep each quality string attached
## to its own read
DESCRIPTION="--fastx_syncpairs keeps each reverse quality with its read when reordering"
printf "@a\nAA\n+\nII\n@b\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@b\nTT\n+\nJJ\n@a\nGG\n+\nHH\n") \
        --fastqout /dev/null \
        --fastqout_rev - 2> /dev/null | \
    tr '\n' ' ' | \
    grep -qx "@a GG + HH @b TT + JJ " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## final report on stderr: "n pairs synchronized, x forward and y
## reverse orphan reads"
DESCRIPTION="--fastx_syncpairs reports pairs and orphans on stderr"
printf "@a\nAA\n+\nII\n@b\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a\nTT\n+\nII\n@z\nGG\n+\nII\n") \
        --fastaout /dev/null 2>&1 > /dev/null | \
    grep -q "1 pairs synchronized, 1 forward and 1 reverse orphan reads" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs reports zero pairs when no reads match"
printf "@a\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@z\nTT\n+\nII\n") \
        --fastaout /dev/null 2>&1 > /dev/null | \
    grep -q "0 pairs synchronized, 1 forward and 1 reverse orphan reads" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               orphan outputs                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs writes forward orphans to --fastaout_orphans"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -qx ">b 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs writes reverse orphans to --fastaout_orphans_rev"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n@d 2:N:0:1\nGG\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans_rev - 2> /dev/null | \
    grep -qx ">d 2:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout_orphans (fastq in)"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastqout /dev/null \
        --fastqout_orphans - 2> /dev/null | \
    grep -qx "@b 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout_orphans_rev (fastq in)"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n@d 2:N:0:1\nGG\n+\nII\n") \
        --fastqout /dev/null \
        --fastqout_orphans_rev - 2> /dev/null | \
    grep -qx "@d 2:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## an orphan output alone (no synced output) is a valid invocation
DESCRIPTION="--fastx_syncpairs accepts --fastaout_orphans as the only output"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout_orphans - 2> /dev/null | \
    grep -qx ">b 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout_orphans as the only output"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastqout_orphans - 2> /dev/null | \
    grep -qx "@b 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastaout_orphans_rev as the only output"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n@d 2:N:0:1\nGG\n+\nII\n") \
        --fastaout_orphans_rev - 2> /dev/null | \
    grep -qx ">d 2:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout_orphans_rev as the only output"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n@d 2:N:0:1\nGG\n+\nII\n") \
        --fastqout_orphans_rev - 2> /dev/null | \
    grep -qx "@d 2:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## forward orphans are written in the order of the forward file
DESCRIPTION="--fastx_syncpairs writes forward orphans in forward-file order"
printf "@b\nAA\n+\nII\n@a\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@z\nTT\n+\nII\n") \
        --fastaout_orphans - 2> /dev/null | \
    grep "^>" | \
    tr -d '\n' | \
    grep -qx ">b>a" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## reverse orphans are written in the order of the reverse file
DESCRIPTION="--fastx_syncpairs writes reverse orphans in reverse-file order"
printf "@m\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@d\nTT\n+\nII\n@c\nGG\n+\nII\n") \
        --fastaout_orphans_rev - 2> /dev/null | \
    grep "^>" | \
    tr -d '\n' | \
    grep -qx ">d>c" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               mate matching                                 #
#                                                                             #
#*****************************************************************************#

## a multi-character label that ends in neither a separator nor a mate
## number is used verbatim as the matching key (no suffix is stripped)
DESCRIPTION="--fastx_syncpairs matches a multi-character label with no mate marker"
printf "@xy\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@xy\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs matches Casava 1.8+ headers (differ after a space)"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs matches old /1 and /2 headers by default"
printf "@a/1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a/2\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --read_separators is accepted"
printf "@a_1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a_2\nTT\n+\nII\n") \
        --read_separators "_" \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --read_separators matches a custom separator"
printf "@a_1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a_2\nTT\n+\nII\n") \
        --read_separators "_" \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs treats /1 /2 as orphans when separator excluded"
printf "@a/1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a/2\nTT\n+\nII\n") \
        --read_separators "_" \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -qx ">a/1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## a tab, like a space, always ends the matching key
DESCRIPTION="--fastx_syncpairs matches headers that differ after a tab"
printf "@a\t1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a\t2\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## the mate number is only stripped when preceded by a separator
## character: a1 and a2 are distinct keys
DESCRIPTION="--fastx_syncpairs does not strip a mate number without its separator"
printf "@a1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a2\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -qx ">a1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## only 1 and 2 are mate numbers: /3 is kept verbatim in the key, so
## two reads labelled a/3 share the key a/3 and form a pair
DESCRIPTION="--fastx_syncpairs does not treat /3 as a mate marker"
printf "@a/3\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a/3\nTT\n+\nII\n") \
        --fastaout - 2> /dev/null | \
    grep -qx ">a/3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## a/1 strips to the key a, so it pairs with a read labelled just a
DESCRIPTION="--fastx_syncpairs matches a /1 read with a bare label"
printf "@a/1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## corner case: a label that is only a mate marker strips to an empty
## key, so /1 and /2 pair with each other
DESCRIPTION="--fastx_syncpairs pairs reads whose whole label is a mate marker"
printf "@/1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@/2\nTT\n+\nII\n") \
        --fastaout - 2> /dev/null | \
    grep -qx ">/1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --read_separators accepts a set of characters, any of which may
## introduce the mate number
DESCRIPTION="--fastx_syncpairs --read_separators accepts a set of separators"
printf "@a_1\nAA\n+\nII\n@b:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a_2\nTT\n+\nII\n@b:2\nGG\n+\nII\n") \
        --read_separators "_:" \
        --fastaout - 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## an empty separator set disables mate-marker stripping entirely
DESCRIPTION="--fastx_syncpairs --read_separators empty string disables stripping"
printf "@a/1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a/2\nTT\n+\nII\n") \
        --read_separators "" \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -qx ">a/1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## whitespace always ends the matching key, even when --read_separators
## names a different separator set
DESCRIPTION="--fastx_syncpairs --read_separators does not disable whitespace handling"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --read_separators "_" \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             duplicate labels                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs rejects duplicate labels in the reverse file"
REVERSE=$(mktemp)
printf "@a 2:N:0:1\nTT\n+\nII\n@a 2:N:0:1\nGG\n+\nII\n" > "${REVERSE}"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs rejects duplicate labels in the forward file"
REVERSE=$(mktemp)
printf "@a 2:N:0:1\nTT\n+\nII\n" > "${REVERSE}"
printf "@a 1:N:0:1\nAA\n+\nII\n@a 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

## duplicate forward labels are only rejected when they create an
## ambiguous pairing; two forward orphans sharing a label are harmless
## and are written out unchanged
DESCRIPTION="--fastx_syncpairs keeps duplicate forward orphans (no shared mate)"
printf "@a 1:N:0:1\nAA\n+\nII\n@a 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@z 2:N:0:1\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -c "^>a" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              secondary options                              #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs --fasta_width wraps fasta output"
printf "@s\nAAAAAA\n+\nIIIIII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nAAAAAA\n+\nIIIIII\n") \
        --fasta_width 3 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {next} {if (length($0) > 3) exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --fasta_width 0 does not wrap fasta output"
printf "@s\nAAAAAAAAAA\n+\nIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nAAAAAAAAAA\n+\nIIIIIIIIII\n") \
        --fasta_width 0 \
        --fastaout - 2> /dev/null | \
    grep -qx "AAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --fastq_ascii 33 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 33 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --fastq_ascii 64 is accepted"
printf "@s\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nh\n") \
        --fastq_ascii 64 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## quality scores are not inspected, so --fastq_qmax is accepted but
## ignored: a quality higher than the given limit is not rejected
DESCRIPTION="--fastx_syncpairs --fastq_qmax is accepted but ignored"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmax 0 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --fastq_qmax does not corrupt the output"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nACGT\n+\nIIII\n") \
        --fastq_qmax 0 \
        --fastqout - 2> /dev/null | \
    tr '\n' ' ' | \
    grep -qx "@s ACGT + IIII " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --fastq_qmin is accepted but ignored"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 41 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --gzip_decompress reads gzip-compressed input"
REV=$(mktemp)
printf "@s\nA\n+\nI\n" | gzip > "${REV}"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --gzip_decompress \
        --reverse "${REV}" \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${REV}"
unset REV

DESCRIPTION="--fastx_syncpairs --bzip2_decompress reads bzip2-compressed input"
REV=$(mktemp)
printf "@s\nA\n+\nI\n" | bzip2 > "${REV}"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --bzip2_decompress \
        --reverse "${REV}" \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${REV}"
unset REV

DESCRIPTION="--fastx_syncpairs --log writes a log file"
LOG=$(mktemp)
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null \
        --log "${LOG}" 2> /dev/null
[[ -s "${LOG}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${LOG}"
unset LOG

DESCRIPTION="--fastx_syncpairs --log reports pairs and orphans"
LOG=$(mktemp)
printf "@a\nAA\n+\nII\n@b\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a\nTT\n+\nII\n@z\nGG\n+\nII\n") \
        --fastaout /dev/null \
        --log "${LOG}" 2> /dev/null
grep -q "1 pairs synchronized, 1 forward and 1 reverse orphan reads" "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${LOG}"
unset LOG

DESCRIPTION="--fastx_syncpairs --no_progress is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --no_progress \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## when stderr is not a terminal, the progress indicator is limited to a
## final "100%" line whether or not --no_progress is used, so only the
## integrity of the output can be checked here
DESCRIPTION="--fastx_syncpairs --no_progress does not corrupt the output"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nACGT\n+\nIIII\n") \
        --no_progress \
        --fastqout - 2> /dev/null | \
    tr '\n' ' ' | \
    grep -qx "@s ACGT + IIII " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## the command is not multithreaded: --threads is accepted but has no
## effect
DESCRIPTION="--fastx_syncpairs --threads is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --threads 1 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --threads does not corrupt the output"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nACGT\n+\nIIII\n") \
        --threads 1 \
        --fastqout - 2> /dev/null | \
    tr '\n' ' ' | \
    grep -qx "@s ACGT + IIII " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --threads 2 warns that only one thread is used"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --threads 2 \
        --fastqout /dev/null 2>&1 > /dev/null | \
    grep -q "does not support multithreading" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --quiet runs silently on stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs rejects --fastq_ascii values other than 33 or 64"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 42 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs rejects --threads values greater than 1024"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --threads 1025 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## The header annotation options are all rejected for this command, and
## fastx_syncpairs.cpp depends on that: OutputAnnotations' abundance field is
## read only by fprint_header_annotations(), gated on --sizeout, so the
## command skips the ;size= parse unless --sizeout is given. Pin the
## rejections here; if one of them is ever added to the allow-list, the
## abundance has to start being parsed again for it.
DESCRIPTION="--fastx_syncpairs rejects --sizeout"
REVERSE=$(mktemp)
printf "@s\nA\n+\nI\n" > "${REVERSE}"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout /dev/null \
        --sizeout 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs rejects --xsize"
REVERSE=$(mktemp)
printf "@s\nA\n+\nI\n" > "${REVERSE}"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout /dev/null \
        --xsize 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs rejects --relabel"
REVERSE=$(mktemp)
printf "@s\nA\n+\nI\n" > "${REVERSE}"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout /dev/null \
        --relabel "seq" 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"

DESCRIPTION="--fastx_syncpairs rejects an unrelated option (--join_padgap)"
REVERSE=$(mktemp)
printf "@s\nA\n+\nI\n" > "${REVERSE}"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse "${REVERSE}" \
        --fastqout /dev/null \
        --join_padgap NNN 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${REVERSE}"


exit 0
