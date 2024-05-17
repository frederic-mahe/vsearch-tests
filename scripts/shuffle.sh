#!/bin/bash -

## Print a header
SCRIPT_NAME="shuffling options"
LINE=$(printf "%076s\n" | tr " " "-")
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

DESCRIPTION="--shuffle requires --output"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--shuffle fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --output ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--shuffle minimal working example (empty input)"
printf "" | \
    "${VSEARCH}" \
        --shuffle - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle minimal working example (single fasta sequence)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle reads and returns fasta"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output - | \
    tr -d "\n" | \
    grep -qw ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle minimal working example (single fastq sequence)"
printf "@\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle reads fastq and returns fasta"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output - | \
    tr -d "\n" | \
    grep -qw ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle accepts identical sequences"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle returns the same number of sequences"
printf ">s1\nA\n>s2\nA\n>s3\nA\n>s4\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output - | \
    awk '/^>/ {s++} END {exit s == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle does not return duplicates"
printf ">s1\nA\n>s2\nA\n>s3\nA\n>s4\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output - | \
    grep "^>" | \
    sort | \
    uniq --repeated | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# sort(output) == input
DESCRIPTION="--shuffle sorted output is the same as input"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output - | \
    paste - - | \
    sort | \
    tr -d "\t" | \
    tr -d "\n" | \
    grep -qw ">s1A>s2C>s3G>s4T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle accepts duplicated identifiers"
printf ">s1\nA\n>s1\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------------------- topn

DESCRIPTION="--shuffle accepts --topn"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --topn 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --topn must be greater than zero"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --topn 0 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--shuffle --topn can be larger than the number of entries"
printf ">s\nA\n" | \
    "${VSEARCH}" \
    --shuffle - \
    --quiet \
    --topn 2 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --topn can be larger than the number of entries (no effect on output)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --topn 2 \
        --output - | \
    awk '{if ($1 ~ /^>/) {entries++}} END {exit entries == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --topn can be equal to the number of entries (no effect on output)"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --topn 2 \
        --output - | \
    awk '{if ($1 ~ /^>/) {entries++}} END {exit entries == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --topn keeps n first entries"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --topn 1 \
        --output - | \
    awk '{if ($1 ~ /^>/) {entries++}} END {exit entries == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- randseed

DESCRIPTION="--shuffle accepts --randseed"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --randseed 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle a fix --randseed produces constant output"
SEED=1
OUTPUT1=$(
    printf ">s1\nA\n>s2\nA\n>s3\nA\n>s4\nA\n" | \
        "${VSEARCH}" \
            --shuffle - \
            --quiet \
            --randseed ${SEED} \
            --output -
       )
OUTPUT2=$(
    printf ">s1\nA\n>s2\nA\n>s3\nA\n>s4\nA\n" | \
        "${VSEARCH}" \
            --shuffle - \
            --quiet \
            --randseed ${SEED} \
            --output -
       )
[[ "${OUTPUT1}" == "${OUTPUT2}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
unset SEED OUTPUT1 OUTPUT2

DESCRIPTION="--shuffle accepts --randseed 0 (free seed)"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --randseed 0 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## for each secondary option below, write two tests: 1) accepts
## option, 2) check basic option effect (if applicable)

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--shuffle --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --shuffle - \
        --bzip2_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --bzip2_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --shuffle - \
        --bzip2_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fasta_width

DESCRIPTION="--shuffle --fasta_width is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --fasta_width 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --fasta_width wraps fasta output"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --fasta_width 1 \
        --output - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--shuffle --fastq_ascii is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --fastq_ascii 33 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--shuffle --fastq_qmax is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --fastq_qmax 41 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --fastq_qmax has no effect"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --fastq_qmax 40 \
        --output - | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--shuffle --fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --fastq_qmin 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --fastq_qmin has no effect"
printf "@s\nA\n+\nH\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --fastq_qmin 40 \
        --output - | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--shuffle --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --shuffle - \
        --gzip_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --gzip_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --shuffle - \
        --gzip_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

# 
DESCRIPTION="--shuffle --label_suffix is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --label_suffix "_suffix" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --label_suffix adds the suffix 'string' to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --label_suffix "_suffix" \
        --output - | \
    grep -wq ">s_suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --label_suffix adds the suffix 'string' (before annotations)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --label_suffix "_suffix" \
        --lengthout \
        --output - | \
    grep -wq ">s_suffix;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--shuffle --lengthout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --lengthout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --lengthout adds length annotations to output"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --lengthout \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--shuffle --log is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --log /dev/null \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --log writes to a file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output /dev/null \
        --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --log does not prevent messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --output /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- maxseqlength

DESCRIPTION="--shuffle --maxseqlength is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --maxseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--shuffle --maxseqlength removes sequences longer than n"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --maxseqlength 1 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- minseqlength

DESCRIPTION="--shuffle --minseqlength is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--shuffle --minseqlength removes sequences shorter than n"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --minseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--shuffle --no_progress is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --no_progress \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--shuffle --no_progress removes progressive report on stderr (no visible effect)"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --no_progress \
        --output /dev/null 2>&1 | \
    grep -iq "^shuffling" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--shuffle --notrunclabels is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --notrunclabels \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --notrunclabels preserves full headers"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --notrunclabels \
        --output - | \
    grep -wq ">s extra" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--shuffle --quiet is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --quiet eliminates all (normal) messages to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--shuffle --quiet allows error messages to be sent to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --quiet2 \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--shuffle --relabel is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel renames sequence (label + ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel renames sequence (empty label, only ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "" \
        --output - | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel cannot combine with --relabel_md5"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --relabel_md5 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel cannot combine with --relabel_sha1"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --relabel_sha1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--shuffle --relabel_keep is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_keep renames and keeps original sequence name"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output - | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--shuffle --relabel_md5 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_md5 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_md5 relabels using MD5 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_sha1

DESCRIPTION="--shuffle --relabel_sha1 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_sha1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_sha1 relabels using SHA1 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--shuffle --relabel_self is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_self \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_self relabels using sequence as label"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--shuffle --sample is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --sample "ABC" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --sample adds sample name to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --sample "ABC" \
        --output - | \
    grep -qw ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--shuffle --sizein is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --sizein \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --sizein is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --sizein \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --sizein (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle size annotations are present in output (with --sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --sizein \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle size annotations are present in output (without --sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

# When using --relabel, --relabel_self, --relabel_md5 or --relabel_sha1,
# preserve and report abundance annotations to the output fasta file
# (using the pattern ';size=integer;').

DESCRIPTION="--shuffle --sizeout is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --sizeout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --sizeout is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --sizeout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --sizeout missing size annotations are not added (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle size annotations are present in output (with --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --sizeout \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle size annotations are present in output (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## add abundance annotations
DESCRIPTION="--shuffle --relabel no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_self no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_self --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_md5 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_md5 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_sha1 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_sha1 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## preserve abundance annotations
DESCRIPTION="--shuffle --relabel no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_self no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_self --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_md5 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_md5 --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_sha1 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --relabel_sha1 --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--shuffle --threads is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --threads 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --threads > 1 triggers a warning (not multithreaded)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --threads 2 \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--shuffle --xee is accepted"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --xee \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --xee removes expected error annotations from input"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --xee \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--shuffle --xlength is accepted"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --xlength \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --xlength removes length annotations from input"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --xlength \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --xlength removes length annotations (input), lengthout adds them (output)"
printf ">s;length=2\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --xlength \
        --lengthout \
        --quiet \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

DESCRIPTION="--shuffle --xsize is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --xsize \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--shuffle --xsize removes abundance annotations from input"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --xsize \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does not work as expected!
# DESCRIPTION="--shuffle --xsize removes abundance annotations (input), sizeout adds them (output)"
# printf ">s;size=2\nA\n" | \
#     "${VSEARCH}" \
#         --shuffle - \
#         --xsize \
#         --quiet \
#         --sizeout \
#         --output - | \
#     grep -wq ">s;size=1" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"

exit 0

# status: complete (v2.28.1, 2024-05-17)
