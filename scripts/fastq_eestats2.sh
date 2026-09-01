#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastq_eestats2"
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

## valgrind is only useful here if it can actually run the binary under
## test. When it dies before reaching main -- a uprobe on the dynamic
## loader does that, and so does a sanitizer-instrumented binary -- it
## still reports "ERROR SUMMARY: 0 errors" and "in use at exit: 0
## bytes", which would silently turn every valgrind check below into a
## pass. Probe it once here, so those checks are skipped, not passed.
VALGRIND_WORKS=false
if which valgrind > /dev/null 2>&1 ; then
    VALGRIND_PROBE=$(valgrind "${VSEARCH}" --version 2>&1)
    [[ "${VALGRIND_PROBE}" == *"ERROR SUMMARY"* && \
       "${VALGRIND_PROBE}" != *"Process terminating"* ]] && \
        VALGRIND_WORKS=true
    unset VALGRIND_PROBE
fi


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## vsearch --fastq_eestats2 fastqfile --output outputfile [options]

DESCRIPTION="--fastq_eestats2 is a valid command"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 requires --output"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --output accepts a regular file"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output "${TMP}" 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastq_eestats2 --output accepts /dev/null"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --output accepts - (stdout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --output requires an argument"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 reads from stdin with -"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 reads from a file argument"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > "${TMP}"
"${VSEARCH}" \
    --fastq_eestats2 "${TMP}" \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------- output stream behaviour

DESCRIPTION="--fastq_eestats2 does not write the table to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -q "^Length" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 writes a banner to stderr (without --quiet)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 empty input is accepted"
printf "" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 empty input reports 0 reads"
printf "" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^0 reads" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 rejects fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 accepts empty read"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------- table format/header

## summary preamble: "<N> reads, max len <L>, avg <A>"
DESCRIPTION="--fastq_eestats2 output starts with a summary line reporting read count"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    head -n 1 | \
    grep -qE "^1 reads" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 summary reports max length"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    head -n 1 | \
    grep -q "max len 3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 summary reports average length"
printf "@s1\nAA\n+\nII\n@s2\nAAAA\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    head -n 1 | \
    grep -q "avg 3.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 output contains a Length column header"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^Length" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 output contains MaxEE column headers"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    grep -q "MaxEE" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 default ee_cutoffs include 0.50"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    grep -q "MaxEE 0.50" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 default ee_cutoffs include 1.00"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    grep -q "MaxEE 1.00" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 default ee_cutoffs include 2.00"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    grep -q "MaxEE 2.00" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## default length cutoffs: 50, 100, ... up to longest sequence
DESCRIPTION="--fastq_eestats2 default length cutoffs start at 50"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^[[:space:]]+50[[:space:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## with reads of length 120, default length cutoffs should be 50, 100
DESCRIPTION="--fastq_eestats2 default length cutoffs step by 50"
(
    printf "@s\nA%119s\n" " " | tr " " "A"
    printf "+\nI%119s\n" " " | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^[[:space:]]+100[[:space:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- table content

DESCRIPTION="--fastq_eestats2 retains a read when its EE is below the cutoff"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,1,1" \
        --ee_cutoffs "1.0" \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^[[:space:]]+1[[:space:]]+1\([[:space:]]*100\.0%\)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 discards a read when its EE exceeds the cutoff"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,1,1" \
        --ee_cutoffs "0.5" \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^[[:space:]]+1[[:space:]]+0\([[:space:]]*0\.0%\)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 retained count scales with read pool"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,1,1" \
        --ee_cutoffs "1.0" \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^[[:space:]]+1[[:space:]]+2\([[:space:]]*100\.0%\)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 reports percentage (50%)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,1,1" \
        --ee_cutoffs "0.5" \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "[[:space:]]50\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## truncation length longer than a read: read not retained
DESCRIPTION="--fastq_eestats2 does not retain reads shorter than truncation length"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "2,2,1" \
        --ee_cutoffs "1.0" \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^[[:space:]]+2[[:space:]]+0\([[:space:]]*0\.0%\)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------------- ee_cutoffs

DESCRIPTION="--fastq_eestats2 --ee_cutoffs is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "0.5,1.0,2.0" \
        --length_cutoffs "1,1,1" \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs accepts a single value"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "1.0" \
        --length_cutoffs "1,1,1" \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs accepts integer values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "1" \
        --length_cutoffs "1,1,1" \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs changes column headers"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "0.1" \
        --length_cutoffs "1,1,1" \
        --output - \
        --quiet 2> /dev/null | \
    grep -q "MaxEE 0.10" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs produces one column per value"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "0.5,1.0,2.0,3.0,4.0" \
        --length_cutoffs "1,1,1" \
        --output - \
        --quiet 2> /dev/null | \
    grep -o "MaxEE" | \
    awk 'END {exit (NR == 5) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs rejects empty argument"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs rejects non-numeric value"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "abc" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs rejects zero"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "0" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs rejects negative values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "-1.0" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs rejects trailing comma"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "1.0," \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --ee_cutoffs rejects a non-numeric list"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --ee_cutoffs "abc" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------ length_cutoffs

DESCRIPTION="--fastq_eestats2 --length_cutoffs is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,1,1" \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## The grammar is exactly "shortest,longest,increment" (or "*" for the
## longest), with no whitespace anywhere. std::sscanf used to tolerate it
## wherever a %d conversion began, so "1,*, 10" parsed while "1, *, 10" did
## not --- an artefact of the format string, not a documented grammar.
DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects whitespace before a value"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,*, 1" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects whitespace after a separator"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1, 1, 1" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects a trailing separator"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,1,1," \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects an empty argument"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## a value that does not fit in an int is rejected rather than wrapping:
## an out-of-range integer is undefined behaviour for the scanf family
DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects a value out of the int range"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,1,99999999999999999999" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects * in the first field"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "*,1,1" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs accepts * as max"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,*,1" \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs * uses the longest sequence"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,*,1" \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^[[:space:]]+2[[:space:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs generates one row per step"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,3,1" \
        --ee_cutoffs "1.0" \
        --output - \
        --quiet 2> /dev/null | \
    awk '/^[[:space:]]+[0-9]+[[:space:]]/ {c++} END {print c}' | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs increment is respected"
printf "@s\nAAAAA\n+\nIIIII\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,5,2" \
        --ee_cutoffs "1.0" \
        --output - \
        --quiet 2> /dev/null | \
    awk '/^[[:space:]]+[0-9]+[[:space:]]/ {c++} END {print c}' | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## when the range doesn't neatly align with the increment, first cutoff is honored
DESCRIPTION="--fastq_eestats2 --length_cutoffs first value is the minimum"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "2,3,1" \
        --ee_cutoffs "1.0" \
        --output - \
        --quiet 2> /dev/null | \
    awk '/^[[:space:]]+[0-9]+[[:space:]]/ {print $1; exit}' | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects single value"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects two values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,2" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects four values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,2,3,4" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects zero increment"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,2,0" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects min > max"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "2,1,1" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects negative values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "-1,1,1" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects floating-point values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1.0,1.0,1.0" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --length_cutoffs rejects * as min"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "*,*,1" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## The count table is sized and indexed as length_steps * ee_cutoffs_count.
## Both the allocation size and the x * ee_count + y index used to be computed
## in 32-bit arithmetic, so a table with more than 2^31 cells overflowed the
## int (pull request 644 widens both to size_t):
## https://github.com/torognes/vsearch/pull/644
##
## Triggering the overflow is impractical for a black-box test: length_steps is
## capped by the actual longest read (min of the read length and the
## --length_cutoffs maximum), so a huge declared --length_cutoffs range with a
## short read does nothing. A genuine overflow needs either a ~2 Gb read or
## tens of thousands of --ee_cutoffs values, i.e. an allocation on the order of
## 16 Gb. Like issues 630 and 631, no deterministic test is written; this note
## documents the fix. (A large-but-safe table, e.g. --length_cutoffs "1,20000,1"
## with five --ee_cutoffs, stays below the 2^31 limit and so would pass on both
## the buggy and the fixed build, making it a smoke test rather than a
## regression test.)

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--fastq_eestats2 --fastq_ascii is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --fastq_ascii 33 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --fastq_ascii accepts 64"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --fastq_ascii 64 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --fastq_ascii rejects values other than 33 or 64"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --fastq_ascii 50 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## with ascii 33, 'I' is Q40 -> EE ~= 1e-4, retained at cutoff 0.5
## with ascii 64, 'I' is Q9 -> EE ~= 0.13, still retained at cutoff 0.5
## so retention cannot distinguish ascii 33/64 here.  Verify that the shift
## changes whether a low-EE cutoff retains the read: '0' (ASCII 48) is Q15
## under ascii 33 (EE=0.031, retained at cutoff 0.05) and invalid under
## ascii 64 (Q=-16).
DESCRIPTION="--fastq_eestats2 --fastq_ascii 33 is the default"
printf "@s\nA\n+\nH\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --length_cutoffs "1,1,1" \
        --ee_cutoffs "0.001" \
        --output - \
        --quiet 2> /dev/null | \
    grep -qE "^[[:space:]]+1[[:space:]]+1\([[:space:]]*100\.0%\)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--fastq_eestats2 --fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --fastq_qmin 0 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --fastq_qmin rejects qualities below fastq_qmin"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --fastq_qmin 1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--fastq_eestats2 --fastq_qmax is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --fastq_qmax 41 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --fastq_qmax rejects qualities above fastq_qmax"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --fastq_qmax 40 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 rejects --fastq_qmin > --fastq_qmax"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --fastq_qmin 40 \
        --fastq_qmax 20 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--fastq_eestats2 --bzip2_decompress accepts bzip2 compressed input"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --bzip2_decompress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 rejects bzip2-compressed stdin without --bzip2_decompress"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --bzip2_decompress accepts empty compressed input"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --bzip2_decompress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--fastq_eestats2 --gzip_decompress accepts gzip compressed input"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --gzip_decompress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 rejects gzip-compressed stdin without --gzip_decompress"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --gzip_decompress accepts empty compressed input"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --gzip_decompress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 rejects --bzip2_decompress combined with --gzip_decompress"
printf "" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --bzip2_decompress \
        --gzip_decompress \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--fastq_eestats2 --log is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null \
        --log /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --log writes to the log file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null \
        --log - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --log + --quiet silences stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null \
        --quiet \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# the "N reads" summary above the cutoff table used to print
# "0 reads, max len 0, avg -nan" in the log on an empty input, while
# --output correctly printed "0 reads"; both destinations now share
# the --output form (regression test: needs a vsearch more recent
# than v2.31.0)
DESCRIPTION="--fastq_eestats2 --log header on an empty input is 0 reads"
printf "" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output /dev/null \
        --log - 2> /dev/null | \
    grep -qx "0 reads" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--fastq_eestats2 --no_progress is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --no_progress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--fastq_eestats2 --no_progress removes progressive report on stderr (no visible effect)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --no_progress \
        --output /dev/null 2>&1 | \
    grep -iq "^reading" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--fastq_eestats2 --quiet is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --quiet \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --quiet eliminates all (normal) messages to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --quiet does not alter the --output table"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "^Length" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------------- threads

DESCRIPTION="--fastq_eestats2 --threads 1 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --threads 1 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats2 --threads > 1 triggers a warning (not multithreaded)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --threads 2 \
        --output /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## options that belong to other commands
for OPT in --id --minseqlength --sizein --sizeout --relabel --fastq_maxee --fastq_trunclen ; do
    DESCRIPTION="--fastq_eestats2 rejects ${OPT}"
    printf "@s\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastq_eestats2 - \
            "${OPT}" 1 \
            --output /dev/null 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--fastq_eestats2 cannot be combined with --fastq_eestats"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --fastq_eestats - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if [[ "${VALGRIND_WORKS}" == "true" ]] ; then

    LOG=$(mktemp)
    FASTQ=$(mktemp)
    printf "@s\nA\n+\nI\n" > "${FASTQ}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastq_eestats2 "${FASTQ}" \
        --ee_cutoffs "0.5,1.0,2.0" \
        --length_cutoffs "50,*,50" \
        --output /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastq_eestats2 valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastq_eestats2 valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTQ}"
fi


#*****************************************************************************#
#                                                                             #
#                          additional coverage                                #
#                                                                             #
#*****************************************************************************#

## --output fails if the target file cannot be opened for writing
DESCRIPTION="--fastq_eestats2 --output errors if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"  # remove write permission
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --output "${TMP}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
