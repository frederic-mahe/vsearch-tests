#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastx_getseq"
LINE=$(printf -- "-%.0s" {1..76})
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

## vsearch --fastx_getseq fastafile (--fastaout | --fastqout | --notmatched | --notmatchedfq) outputfile --label label [options]

DESCRIPTION="--fastx_getseq is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq reads from stdin (-)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq reads from a regular file"
TMP=$(mktemp)
printf ">s1\nA\n" > "${TMP}"
"${VSEARCH}" \
    --fastx_getseq "${TMP}" \
    --label "s1" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getseq fails if input file does not exist"
"${VSEARCH}" \
    --fastx_getseq /no/such/file \
    --label "s1" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq fails if input file is not readable"
TMP=$(mktemp)
printf ">s1\nA\n" > "${TMP}"
chmod u-r "${TMP}"
"${VSEARCH}" \
    --fastx_getseq "${TMP}" \
    --label "s1" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getseq fails with input that is not FASTA or FASTQ"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq fails without --label"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq fails without any output option"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq accepts an empty label argument"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq fails when --label_substr_match is given without --label"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label_substr_match \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


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
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: discard fastq entries with headers mismatching --label"
printf "@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --quiet \
    --fastqout - | \
    grep -qx "@s2" && \
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
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: keep fastq entries with headers matching --label (case is not modified)"
printf "@S1\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --quiet \
    --fastqout - | \
    grep -qx "@S1" && \
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
    grep -qx "@s11" && \
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
    grep -qx "@1s1" && \
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
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: keep fastq entries with headers matching --label after truncation (tab)"
printf "@s1\tsuffix\nA\n+\nI\n" | \
    "${VSEARCH}" \
    --fastx_getseq - \
    --label "s1" \
    --quiet \
    --fastqout - | \
    grep -qx "@s1" && \
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

## fasta input/output (default behaviour with fasta input)
DESCRIPTION="--fastx_getseq: keep fasta entries with headers matching --label"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: matching sequence is emitted unchanged (fasta)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: matching sequence preserves quality scores (fastq)"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==4' | \
    grep -qx "IIII" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: only matching entries are kept (multiple inputs)"
printf ">s1\nA\n>s2\nC\n>s3\nT\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s2" \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk '/^>/' | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: all entries matching the same --label are extracted"
printf ">s1\nA\n>s1\nC\n>s2\nT\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk '/^>/' | \
    wc -l | \
    grep -qw "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: no match produces empty --fastaout"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "unknown" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --label: already exercised in default-behaviour tests above. Two more
## cases to confirm that --label does not match partial tokens inside a
## truncated header, and that control characters in the label are accepted.
DESCRIPTION="--fastx_getseq: --label does not match a partial header token"
printf ">s12\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq: --label accepts mixed case strings"
printf ">AbCd\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "aBcD" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">AbCd" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastaout
DESCRIPTION="--fastaout is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout writes to stdout with -"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout accepts a fastq input (drops quality)"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout "${TMP}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

## --fastqout
DESCRIPTION="--fastqout is accepted with fastq input"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout writes to stdout with -"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout fails with fasta input"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastqout fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastqout "${TMP}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

## --notmatched
DESCRIPTION="--notmatched is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notmatched /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatched writes non-matching entries to stdout"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notmatched - \
        --quiet 2> /dev/null | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatched does not contain the matching entry"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notmatched - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--notmatched with fastq input drops quality scores"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notmatched - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatched fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notmatched "${TMP}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

## --notmatchedfq
DESCRIPTION="--notmatchedfq is accepted with fastq input"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notmatchedfq /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatchedfq writes non-matching fastq entries"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notmatchedfq - \
        --quiet 2> /dev/null | \
    grep -qx "@s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatchedfq fails with fasta input"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notmatchedfq /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--notmatchedfq fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notmatchedfq "${TMP}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

## combinations: matched and not-matched written in parallel
DESCRIPTION="--fastaout and --notmatched together split matched and non-matched"
TMP1=$(mktemp)
TMP2=$(mktemp)
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout "${TMP1}" \
        --notmatched "${TMP2}" \
        --quiet 2> /dev/null
grep -qx ">s1" "${TMP1}" && \
grep -qx ">s2" "${TMP2}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP1}" "${TMP2}"
unset TMP1 TMP2

DESCRIPTION="--fastqout and --notmatchedfq together split matched and non-matched"
TMP1=$(mktemp)
TMP2=$(mktemp)
printf "@s1\nA\n+\nI\n@s2\nC\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastqout "${TMP1}" \
        --notmatchedfq "${TMP2}" \
        --quiet 2> /dev/null
grep -qx "@s1" "${TMP1}" && \
grep -qx "@s2" "${TMP2}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP1}" "${TMP2}"
unset TMP1 TMP2

## --label_substr_match
DESCRIPTION="--label_substr_match is accepted"
printf ">abc\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "b" \
        --label_substr_match \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_substr_match makes a substring label a match"
printf ">abcd\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "bc" \
        --label_substr_match \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">abcd" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_substr_match is not case-sensitive"
printf ">aBCd\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "bc" \
        --label_substr_match \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">aBCd" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --bzip2_decompress
DESCRIPTION="--bzip2_decompress accepts a bzip2-compressed pipe"
printf ">s1\nA\n" | bzip2 | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --bzip2_decompress \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --gzip_decompress
DESCRIPTION="--gzip_decompress accepts a gzip-compressed pipe"
printf ">s1\nA\n" | gzip | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --gzip_decompress \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fasta_width
DESCRIPTION="--fasta_width is accepted"
printf ">s1\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fasta_width 5 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta_width folds long sequences"
printf ">s1\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fasta_width 5 \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGTA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta_width 0 suppresses folding"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fasta_width 0 \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    wc -c | \
    grep -qw "85" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_ascii
DESCRIPTION="--fastq_ascii 33 is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastq_ascii 33 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_ascii 64 is accepted"
printf "@s1\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastq_ascii 64 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_ascii rejects a value other than 33 or 64"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastq_ascii 99 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_qmax: accepted but not enforced by --fastx_getseq
DESCRIPTION="--fastq_qmax is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastq_qmax 50 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_qmin: accepted but not enforced by --fastx_getseq
DESCRIPTION="--fastq_qmin is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastq_qmin 0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --label_suffix
DESCRIPTION="--label_suffix is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --label_suffix ";tag=x" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_suffix appends the suffix to the header"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --label_suffix ";tag=x" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;tag=x" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --lengthout
DESCRIPTION="--lengthout is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --lengthout \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--lengthout adds a ;length= annotation"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --lengthout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --log
DESCRIPTION="--log is accepted"
TMP=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --log "${TMP}" \
        --fastaout /dev/null 2> /dev/null
[[ -s "${TMP}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

## --no_progress
DESCRIPTION="--no_progress is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --no_progress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notrunclabels (partially tested above; here we confirm matching works)
DESCRIPTION="--notrunclabels is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --notrunclabels \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --quiet
DESCRIPTION="--quiet is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--quiet silences stderr messages"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --relabel
DESCRIPTION="--relabel is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --relabel "new:" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel replaces matching headers with a prefix + ticker"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --relabel "new:" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">new:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_keep
DESCRIPTION="--relabel_keep retains the old identifier after a space"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --relabel "new:" \
        --relabel_keep \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">new:1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_md5
DESCRIPTION="--relabel_md5 replaces header with an MD5 digest"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --relabel_md5 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_self
DESCRIPTION="--relabel_self replaces header with the sequence itself"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --relabel_self \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_sha1
DESCRIPTION="--relabel_sha1 replaces header with a SHA1 digest"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --relabel_sha1 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sample
DESCRIPTION="--sample is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --sample "abc" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sample appends ;sample= to the header"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --sample "abc" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;sample=abc" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizein / --sizeout
DESCRIPTION="--sizein and --sizeout preserve an existing abundance annotation"
printf ">s1;size=5\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1;size=5" \
        --sizein \
        --sizeout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizeout without --sizein sets size=1"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --sizeout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xee
DESCRIPTION="--xee strips an ee= annotation from the header"
printf ">s1;ee=0.1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1;ee=0.1" \
        --xee \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xlength
DESCRIPTION="--xlength strips a length= annotation from the header"
printf ">s1;length=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1;length=1" \
        --xlength \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xsize
DESCRIPTION="--xsize strips a size= annotation from the header"
printf ">s1;size=3\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1;size=3" \
        --xsize \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## --threads: command is single-threaded; option is accepted but has no effect
DESCRIPTION="--threads is accepted (option has no effect)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --threads 2 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## options from other fastx_gets* commands that do not apply to --fastx_getseq
DESCRIPTION="--fastx_getseq rejects --labels"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --labels "${TMP}" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getseq rejects --label_word"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --label_word "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq rejects --label_field"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --label_field "abc" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseq rejects --subseq_start"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseq - \
        --label "s1" \
        --subseq_start 2 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

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

