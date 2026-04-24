#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastx_getsubseq"
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

## vsearch --fastx_getsubseq fastafile (--fastaout | --fastqout | --notmatched | --notmatchedfq) outputfile --label label [--subseq_start position] [--subseq_end position] [options]

DESCRIPTION="--fastx_getsubseq is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getsubseq reads from stdin (-)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getsubseq reads from a regular file"
TMP=$(mktemp)
printf ">s1\nACGT\n" > "${TMP}"
"${VSEARCH}" \
    --fastx_getsubseq "${TMP}" \
    --label "s1" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getsubseq fails if input file does not exist"
"${VSEARCH}" \
    --fastx_getsubseq /no/such/file \
    --label "s1" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getsubseq fails if input file is not readable"
TMP=$(mktemp)
printf ">s1\nACGT\n" > "${TMP}"
chmod u-r "${TMP}"
"${VSEARCH}" \
    --fastx_getsubseq "${TMP}" \
    --label "s1" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getsubseq fails with input that is not FASTA or FASTQ"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getsubseq accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getsubseq fails without --label"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getsubseq fails without any output option"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## Default behaviour: with no --subseq_start/--subseq_end, the full matching
## sequence is extracted.
DESCRIPTION="--fastx_getsubseq: without subseq bounds extracts the whole sequence"
printf ">s1\nACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Default --subseq_start is 1
DESCRIPTION="--fastx_getsubseq: default --subseq_start is position 1"
printf ">s1\nACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_end 4 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Default --subseq_end is the last position
DESCRIPTION="--fastx_getsubseq: default --subseq_end is the last position"
printf ">s1\nACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 5 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Manpage example: --label "seq1" --subseq_start 3 --subseq_end 6 -> GTAC
DESCRIPTION="--fastx_getsubseq: manpage example produces the expected subsequence"
printf ">seq1\nACGTACGT\n>seq2\nTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "seq1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "GTAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## only matching entries are written to --fastaout
DESCRIPTION="--fastx_getsubseq: non-matching entries are not written to --fastaout"
printf ">s1\nACGTACGT\n>s2\nTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s2" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## matching with fastq input preserves the corresponding quality scores
DESCRIPTION="--fastx_getsubseq: fastq input trims the quality string to the subseq range"
printf "@s1\nACGTACGT\n+\nABCDEFGH\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==4' | \
    grep -qx "CDEF" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --label
DESCRIPTION="--label is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label matching is not case-sensitive"
printf ">S1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">S1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label truncates the header at the first space for matching"
printf ">s1 extra\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --label_substr_match
DESCRIPTION="--label_substr_match is accepted"
printf ">abcd\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "bc" \
        --label_substr_match \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_substr_match allows --label to match inside the header"
printf ">abcd\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "bc" \
        --label_substr_match \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">abcd" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --subseq_start
DESCRIPTION="--subseq_start is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 2 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--subseq_start 1 keeps the first base"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 1 \
        --subseq_end 1 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--subseq_start rejects zero"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 0 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--subseq_start rejects a negative value"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start "-1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--subseq_start rejects a non-numeric argument"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start "abc" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## start position beyond the sequence length yields an empty subsequence
DESCRIPTION="--subseq_start beyond the sequence length yields an empty subsequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 10 \
        --subseq_end 20 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --subseq_end
DESCRIPTION="--subseq_end is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_end 2 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--subseq_end rejects zero"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_end 0 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --subseq_end beyond the sequence length is clamped to the last position
DESCRIPTION="--subseq_end beyond the sequence length is clamped to the last position"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 2 \
        --subseq_end 100 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "CGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --subseq_start must be <= --subseq_end
DESCRIPTION="--subseq_start greater than --subseq_end fails"
printf ">s1\nACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 6 \
        --subseq_end 3 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--subseq_start equal to --subseq_end yields a single base"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 3 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "G" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --subseq_start at the last position yields the last base
DESCRIPTION="--subseq_start at the last position yields the last base"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 4 \
        --subseq_end 4 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## explicit bounds spanning the full sequence yield the full sequence
DESCRIPTION="--subseq_start 1 and --subseq_end equal to the length yield the full sequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 1 \
        --subseq_end 4 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## the trimmed subsequence has the expected length (end - start + 1)
DESCRIPTION="--fastx_getsubseq: trimmed subsequence length is (end - start + 1)"
printf ">s1\nACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 4 \
        --subseq_end 9 \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk 'NR==2 {print length($0)}' | \
    grep -qx "6" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq trimming: the quality prefix before --subseq_start is removed,
## the suffix after --subseq_end is removed
DESCRIPTION="--fastx_getsubseq: fastq quality is trimmed from the left (prefix removed)"
printf "@s1\nACGTACGT\n+\nABCDEFGH\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==4' | \
    grep -qx "CDEFGH" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getsubseq: fastq quality is trimmed from the right (suffix removed)"
printf "@s1\nACGTACGT\n+\nABCDEFGH\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_end 4 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==4' | \
    grep -qx "ABCD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq trimming: the trimmed sequence and quality strings have matching lengths
DESCRIPTION="--fastx_getsubseq: fastq trimmed sequence and quality have the same length"
printf "@s1\nACGTACGT\n+\nABCDEFGH\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 2 \
        --subseq_end 5 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2 || NR==4 {print length($0)}' | \
    sort -u | \
    wc -l | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastaout
DESCRIPTION="--fastaout writes to stdout with -"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout "${TMP}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

## --fastqout
DESCRIPTION="--fastqout is accepted with fastq input"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout fails with fasta input"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --notmatched
DESCRIPTION="--notmatched writes non-matching entries"
printf ">s1\nACGTACGT\n>s2\nTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --notmatched - \
        --quiet 2> /dev/null | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notmatched entries are written in full, not trimmed to the subseq
## range. This matches the manpage: "Non-matching sequences are written
## in full to --notmatched and/or --notmatchedfq".
DESCRIPTION="--fastx_getsubseq: --notmatched entries are written in full (not trimmed)"
printf ">s1\nACGTACGT\n>s2\nTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --fastaout /dev/null \
        --notmatched - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk '/^>s2/ {getline; print}' | \
    grep -qx "TTTTTTTTTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notmatched preserves the header of non-matching entries
DESCRIPTION="--notmatched preserves the header of non-matching entries"
printf ">s1\nACGTACGT\n>s2\nTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --fastaout /dev/null \
        --notmatched - \
        --quiet 2> /dev/null | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notmatched preserves the relative order of non-matching entries
DESCRIPTION="--notmatched preserves the order of non-matching entries"
printf ">s1\nACGT\n>s2\nTTTT\n>s3\nGGGG\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout /dev/null \
        --notmatched - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    awk '/^>/' | \
    tr '\n' ',' | \
    grep -qx ">s2,>s3," && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## when the --label is not found, all entries are sent to --notmatched
DESCRIPTION="--notmatched captures every entry when no header matches --label"
printf ">s1\nACGT\n>s2\nTTTT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "no_such_label" \
        --fastaout /dev/null \
        --notmatched - \
        --quiet 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## headers written to --notmatched are truncated at the first space by default
DESCRIPTION="--notmatched truncates headers at the first space by default"
printf ">s1 description\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "other" \
        --notmatched - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notrunclabels retains the full header in --notmatched
DESCRIPTION="--notrunclabels preserves full headers in --notmatched"
printf ">s1 description\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "other" \
        --notrunclabels \
        --notmatched - \
        --quiet 2> /dev/null | \
    grep -qx ">s1 description" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastaout and --notmatched work together: matching entries are trimmed,
## non-matching entries are written in full
DESCRIPTION="--fastaout and --notmatched together partition the input correctly"
printf ">s1\nACGTACGT\n>s2\nTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --fastaout - \
        --notmatched - \
        --fasta_width 0 \
        --quiet 2> /dev/null | \
    tr '\n' ',' | \
    grep -qx ">s1,GTAC,>s2,TTTTTTTT," && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatched fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --notmatched "${TMP}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

## --notmatchedfq
DESCRIPTION="--notmatchedfq writes non-matching fastq entries"
printf "@s1\nACGTACGT\n+\nIIIIIIII\n@s2\nTTTTTTTT\n+\nJJJJJJJJ\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --notmatchedfq - \
        --quiet 2> /dev/null | \
    grep -qx "@s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notmatchedfq entries are written in full: the sequence is not trimmed
DESCRIPTION="--notmatchedfq sequence is written in full (not trimmed)"
printf "@s1\nACGTACGT\n+\nIIIIIIII\n@s2\nTTTTTTTTTT\n+\n1234567890\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --fastqout /dev/null \
        --notmatchedfq - \
        --quiet 2> /dev/null | \
    awk '/^@s2/ {getline; print}' | \
    grep -qx "TTTTTTTTTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notmatchedfq entries are written in full: the quality string is not trimmed
DESCRIPTION="--notmatchedfq quality string is written in full (not trimmed)"
printf "@s1\nACGTACGT\n+\nIIIIIIII\n@s2\nTTTTTTTTTT\n+\n1234567890\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --fastqout /dev/null \
        --notmatchedfq - \
        --quiet 2> /dev/null | \
    awk '/^@s2/ {getline; getline; getline; print}' | \
    grep -qx "1234567890" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatchedfq fails with fasta input"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --notmatchedfq /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --bzip2_decompress
DESCRIPTION="--bzip2_decompress accepts a bzip2-compressed pipe"
printf ">s1\nACGT\n" | bzip2 | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --bzip2_decompress \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --gzip_decompress
DESCRIPTION="--gzip_decompress accepts a gzip-compressed pipe"
printf ">s1\nACGT\n" | gzip | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --gzip_decompress \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fasta_width
DESCRIPTION="--fasta_width 0 suppresses folding"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
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
        --fastx_getsubseq - \
        --label "s1" \
        --fastq_ascii 33 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_ascii rejects a value other than 33 or 64"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastq_ascii 99 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_qmax / --fastq_qmin: accepted but not enforced by --fastx_getsubseq
DESCRIPTION="--fastq_qmax is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastq_qmax 50 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_qmin is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastq_qmin 0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --label_suffix
DESCRIPTION="--label_suffix appends the suffix to the header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --label_suffix ";tag=x" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;tag=x" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --lengthout reports the length of the trimmed subsequence
DESCRIPTION="--lengthout reports the length of the extracted subsequence"
printf ">s1\nACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --lengthout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --log
DESCRIPTION="--log writes to the given file"
TMP=$(mktemp)
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
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
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --no_progress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notrunclabels
DESCRIPTION="--notrunclabels keeps the full header for --label matching"
printf ">s1 suffix\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1 suffix" \
        --notrunclabels \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "^>s1 suffix$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --quiet
DESCRIPTION="--quiet silences stderr messages"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --relabel
DESCRIPTION="--relabel replaces matching headers with a prefix + ticker"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --relabel "new:" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">new:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_keep
DESCRIPTION="--relabel_keep retains the old identifier after a space"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --relabel "new:" \
        --relabel_keep \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">new:1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_md5: MD5 is computed from the trimmed subsequence
DESCRIPTION="--relabel_md5 replaces header with an MD5 digest"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --relabel_md5 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_self: header is replaced by the trimmed subsequence
DESCRIPTION="--relabel_self replaces header with the extracted subsequence"
printf ">s1\nACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --subseq_start 3 \
        --subseq_end 6 \
        --relabel_self \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">GTAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_sha1
DESCRIPTION="--relabel_sha1 replaces header with a SHA1 digest"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --relabel_sha1 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sample
DESCRIPTION="--sample appends ;sample= to the header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --sample "abc" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;sample=abc" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizein / --sizeout
DESCRIPTION="--sizein and --sizeout preserve an existing abundance annotation"
printf ">s1;size=5\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1;size=5" \
        --sizein \
        --sizeout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizeout without --sizein sets size=1"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --sizeout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xee
DESCRIPTION="--xee strips an ee= annotation from the header"
printf ">s1;ee=0.1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1;ee=0.1" \
        --xee \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xlength
DESCRIPTION="--xlength strips a length= annotation from the header"
printf ">s1;length=1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1;length=1" \
        --xlength \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xsize
DESCRIPTION="--xsize strips a size= annotation from the header"
printf ">s1;size=3\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
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
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
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

## multiple-label options are specific to --fastx_getseqs and should not be
## accepted here.
DESCRIPTION="--fastx_getsubseq rejects --labels"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --labels "${TMP}" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getsubseq rejects --label_word"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --label_word "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getsubseq rejects --label_field"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getsubseq - \
        --label "s1" \
        --label_field "abc" \
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
    printf "@s1\nACG\n+\nIII\n" > "${FASTQ}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastx_getsubseq "${FASTQ}" \
        --label "s1" \
        --subseq_start 2 \
        --subseq_end 2 \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --notmatched /dev/null \
        --notmatchedfq /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastx_getsubseq valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_getsubseq valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTQ}"
fi


exit 0
