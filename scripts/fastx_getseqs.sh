#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastx_getseqs"
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

## vsearch --fastx_getseqs fastafile (--fastaout | --fastqout | --notmatched | --notmatchedfq) outputfile (--label label  --labels labelfile | --label_word label | --label_words labelfile) [options]

DESCRIPTION="--fastx_getseqs is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs reads from stdin (-)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs reads from a regular file"
TMP=$(mktemp)
printf ">s1\nA\n" > "${TMP}"
"${VSEARCH}" \
    --fastx_getseqs "${TMP}" \
    --label "s1" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getseqs fails if input file does not exist"
"${VSEARCH}" \
    --fastx_getseqs /no/such/file \
    --label "s1" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs fails if input file is not readable"
TMP=$(mktemp)
printf ">s1\nA\n" > "${TMP}"
chmod u-r "${TMP}"
"${VSEARCH}" \
    --fastx_getseqs "${TMP}" \
    --label "s1" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getseqs fails with input that is not FASTA or FASTQ"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs fails without any label option"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs fails without any output option"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## mutual exclusion of label-selection options
DESCRIPTION="--fastx_getseqs rejects --label combined with --labels"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --labels "${TMP}" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getseqs rejects --label combined with --label_word"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --label_word "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs rejects --label combined with --label_words"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --label_words "${TMP}" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getseqs rejects --labels combined with --label_word"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --labels "${TMP}" \
        --label_word "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_getseqs rejects --label_word combined with --label_words"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_word "s1" \
        --label_words "${TMP}" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_getseqs: keep entries with headers matching --label"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs: discard entries with headers mismatching --label"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s2" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs: --label matching is not case-sensitive"
printf ">S1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">S1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs: default truncates headers at the first space"
printf ">s1 extra\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs: default truncates headers at the first tab"
printf ">s1\textra\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs: keep fastq entries with header field matching --label_word"
printf "@s;field1=s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_field "field1" \
        --label_word "s1" \
        --quiet \
        --fastaout - | \
    grep -qx ">s;field1=s1" && \
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
    grep -qx ">s;field1=s1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --label
DESCRIPTION="--label is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label accepts an empty string argument"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label matches only one name at a time"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk '/^>/' | \
    wc -l | \
    grep -qw "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --labels
DESCRIPTION="--labels is accepted"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --labels "${TMP}" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--labels extracts every listed label"
TMP=$(mktemp)
printf "s1\ns3\n" > "${TMP}"
printf ">s1\nA\n>s2\nC\n>s3\nT\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --labels "${TMP}" \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk '/^>/' | \
    wc -l | \
    grep -qw "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--labels matching is not case-sensitive"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
printf ">S1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --labels "${TMP}" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">S1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--labels accepts an empty labels file"
TMP=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --labels "${TMP}" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--labels fails if the labels file does not exist"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --labels /no/such/file \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--labels fails if the labels file is not readable"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
chmod u-r "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --labels "${TMP}" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

## --label_word
DESCRIPTION="--label_word is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_word "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_word matches a whole word in the header"
printf ">abc;def\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_word "abc" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">abc;def" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_word does not match a partial token"
printf ">abcd\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_word "abc" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--label_word is case-sensitive"
printf ">ABC\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_word "abc" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--label_word treats underscore as a non-alphanumeric delimiter"
printf ">foo_bar\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_word "foo" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">foo_bar" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --label_words
DESCRIPTION="--label_words is accepted"
TMP=$(mktemp)
printf "s1\n" > "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_words "${TMP}" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

## Note: vsearch 2.30.6 appears to silently skip the first line of a
## --label_words file (see 'notes' at the end of this script). Tests below
## use a throwaway first line so the target words are on lines 2+.
DESCRIPTION="--label_words extracts entries matching any of the listed words"
TMP=$(mktemp)
printf "ignored_first_line\nabc\nxyz\n" > "${TMP}"
printf ">s1;abc\nA\n>s2;foo\nC\n>s3;xyz\nT\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_words "${TMP}" \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk '/^>/' | \
    wc -l | \
    grep -qw "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--label_words is case-sensitive"
TMP=$(mktemp)
printf "ignored_first_line\nABC\n" > "${TMP}"
printf ">s1;abc\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_words "${TMP}" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--label_words fails if the file does not exist"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_words /no/such/file \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --label_field
DESCRIPTION="--label_field is accepted"
printf ">s1;abc=123\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_field "abc" \
        --label_word "123" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_field matches a word inside a named field"
printf ">s1;abc=123\nA\n>s2;abc=999\nC\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_field "abc" \
        --label_word "123" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;abc=123" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_field discards entries whose named field does not match"
printf ">s1;abc=123\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label_field "xyz" \
        --label_word "123" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --label_substr_match
DESCRIPTION="--label_substr_match is accepted"
printf ">abc\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "b" \
        --label_substr_match \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_substr_match allows --label to match inside the header"
printf ">abcd\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "bc" \
        --label_substr_match \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">abcd" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_substr_match allows --labels entries to match inside the header"
TMP=$(mktemp)
printf "bc\n" > "${TMP}"
printf ">abcd\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --labels "${TMP}" \
        --label_substr_match \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">abcd" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

## --notrunclabels
DESCRIPTION="--notrunclabels keeps the full header for --label matching"
printf ">s1 suffix\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1 suffix" \
        --notrunclabels \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "^>s1 suffix$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastaout
DESCRIPTION="--fastaout writes to stdout with -"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout fails if unable to open the output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
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
        --fastx_getseqs - \
        --label "s1" \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout writes to stdout with -"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout fails with fasta input"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --notmatched
DESCRIPTION="--notmatched writes non-matching entries"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --notmatched - \
        --quiet 2> /dev/null | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatched does not contain matching entries"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --notmatched - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--notmatched fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --notmatched "${TMP}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

## --notmatchedfq
DESCRIPTION="--notmatchedfq writes non-matching fastq entries"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --notmatchedfq - \
        --quiet 2> /dev/null | \
    grep -qx "@s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatchedfq fails with fasta input"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
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
printf ">s1\nA\n" | bzip2 | \
    "${VSEARCH}" \
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
        --label "s1" \
        --fastq_ascii 33 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_ascii rejects a value other than 33 or 64"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastq_ascii 99 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_qmax / --fastq_qmin: accepted but not enforced by --fastx_getseqs
DESCRIPTION="--fastq_qmax is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastq_qmax 50 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_qmin is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastq_qmin 0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --label_suffix
DESCRIPTION="--label_suffix appends the suffix to the header"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --label_suffix ";tag=x" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;tag=x" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --lengthout
DESCRIPTION="--lengthout adds a ;length= annotation"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --lengthout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --log
DESCRIPTION="--log writes to the given file"
TMP=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
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
        --fastx_getseqs - \
        --label "s1" \
        --no_progress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --quiet
DESCRIPTION="--quiet silences stderr messages"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --relabel
DESCRIPTION="--relabel replaces matching headers with a prefix + ticker"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
        --label "s1" \
        --relabel_sha1 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sample
DESCRIPTION="--sample appends ;sample= to the header"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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
        --fastx_getseqs - \
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

## --subseq_start and --subseq_end belong to --fastx_getsubseq and should
## not be accepted here.
DESCRIPTION="--fastx_getseqs rejects --subseq_start"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --subseq_start 2 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_getseqs rejects --subseq_end"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --label "s1" \
        --subseq_end 2 \
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

## vsearch 2.30.6 (Jan 2026) silently ignores the first word in a
## --label_words file: with a single-word file 'abc\n' the header '>s1;abc'
## does not match, but with 'xyz\nabc\n' it does. A leading empty line in
## the same file triggers a segmentation fault. Tests above work around
## this by placing the target words on line 2 and later; the behaviour
## should be flagged for human review.


exit 0

