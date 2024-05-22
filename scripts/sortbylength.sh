#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="sortbylength"
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


## vsearch 2.28.1
## The valid options for the sortbylength command are:
## --bzip2_decompress --fasta_width --fastq_ascii --fastq_qmax
## --fastq_qmin --gzip_decompress --label_suffix --lengthout --log
## --maxseqlength --minseqlength --no_progress
## --notrunclabels --output --quiet --relabel --relabel_keep
## --relabel_md5 --relabel_self --relabel_sha1 --sample --sizein
## --sizeout --threads --topn --xee --xlength --xsize


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------------- output
DESCRIPTION="--sortbylength requires --output"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sortbylength fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--sortbylength outputs in fasta format"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">s1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength empty input -> empty output"
printf "" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------------- sorting

DESCRIPTION="--sortbylength single entry, no sorting"
${VSEARCH} \
    --sortbylength <(printf ">s1\nA\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# (from issue 38) sort by length ...
DESCRIPTION="--sortbylength sorts by length (already ordered)"
${VSEARCH} \
    --sortbylength <(printf ">s2\nAA\n>s1\nT\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s2AA>s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength sorts by length (reverse order)"
${VSEARCH} \
    --sortbylength <(printf ">s1\nA\n>s2\nTT\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s2TT>s1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ... then by size
DESCRIPTION="--sortbylength sorts by size (already ordered)"
${VSEARCH} \
    --sortbylength <(printf ">s1;size=2\nA\n>s2;size=1\nT\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=2A>s2;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength sorts by size (reverse order)"
${VSEARCH} \
    --sortbylength <(printf ">s2;size=1\nT\n>s1;size=2\nA\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=2A>s2;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ... then by label
DESCRIPTION="--sortbylength sorts by size then by label (already ordered)"
${VSEARCH} \
    --sortbylength <(printf ">s1;size=1\nA\n>s2;size=1\nT\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=1A>s2;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength sorts by size then by label (reverse order)"
${VSEARCH} \
    --sortbylength <(printf ">s2;size=1\nT\n>s1;size=1\nA\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=1A>s2;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ... then by input order
DESCRIPTION="--sortbylength sorts by size then by label then by input order (reversed sequence order)"
${VSEARCH} \
    --sortbylength <(printf ">s1;size=1\nT\n>s1;size=1\nA\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=1T>s1;size=1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength sorts by size then by label then by input order (normal sequence order)"
${VSEARCH} \
    --sortbylength <(printf ">s1;size=1\nA\n>s1;size=1\nT\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=1A>s1;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- median length

# The sortbylength command outputs on the stderr or in a log file the
# median length of processed fasta sequences. To refactor the
# piece of code that performs this computation, I need to write
# tests. Note that the --sizein option is not necessary.

DESCRIPTION="--sortbylength median length is written to stderr"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -q "^Median length:" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength median length (empty input)"
printf "" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength median length (single entry)"
printf ">s1\nAA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength median length (null length is ok)"
printf ">s1\n\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does return an average "(9 + 1) / 2 = 5"
DESCRIPTION="--sortbylength median length (average of two entries)"
printf ">s1\nAAAAAAAAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does return an average, but:
#  - fprintf rounding ("%.0f\n") (1 + 2) / 2 = 1.5 ~ 2
#  - Banker's rounding (round half to even)
DESCRIPTION="--sortbylength median length (rounded average of two entries #1)"
printf ">s1\nAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does return an average, but:
#  - fprintf rounding ("%.0f\n") (1 + 4) / 2 = 2.5 ~ 2
#  - Banker's rounding (round half to even)
DESCRIPTION="--sortbylength median length (rounded average of two entries #2)"
printf ">s1\nAAAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does return an average, but:
#  - fprintf rounding ("%.0f\n") (1 + 6) / 2 = 3.5 ~ 4
#  - Banker's rounding (round half to even)
DESCRIPTION="--sortbylength median length (rounded average of two entries #3)"
printf ">s1\nAAAAAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# odd-sized list of entries (returns the middle point entry)
DESCRIPTION="--sortbylength median length (odd number of entries)"
printf ">s1\nAAA\n>s2\nAA\n>s3\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# even-sized list of entries:
# - returns the average of entries around the middle point,
# - average is either round or has a remainder of 0.5
# - fprintf rounds half to the closest even value
DESCRIPTION="--sortbylength median length (even number of entries)"
printf ">s1\nAAAA\n>s2\nAAA\n>s3\nAA\n>s4\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# even-sized list of entries, all sequences have a length of one
DESCRIPTION="--sortbylength median length (same length for all entries)"
printf ">s1\nA\n>s2\nA\n>s3\nA\n>s4\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# even-sized list of entries (reversed-order lengths)
DESCRIPTION="--sortbylength median length (even, reversed-order lengths)"
printf ">s1\nA\n>s2\nAA\n>s3\nAAA\n>s4\nAAAA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# odd-sized list of entries (reversed-order lengths)
DESCRIPTION="--sortbylength median length (odd, reversed-order lengths)"
printf ">s1\nA\n>s2\nAA\n>s3\nAAA\n>s4\nAAAA\n>s5\nAAAAA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -iqw "median length: 3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# when using --quiet, the median is not printed
DESCRIPTION="--sortbylength median length is not printed when --quiet"
printf ">s1\nAAAAAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -iqw "^Median" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# when using --log, the median is printed in the log file
DESCRIPTION="--sortbylength --log median length is printed to a log"
printf ">s1\nAAAAAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null \
        --log - 2>/dev/null | \
    grep -iqw "^Median" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------- maxseqlength

DESCRIPTION="--sortbylength --maxseqlength is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --maxseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--sortbylength --maxseqlength removes sequences longer than n"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --maxseqlength 1 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--sortbylength --maxseqlength keeps sequences of length n"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --maxseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">sAA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --maxseqlength keeps sequences shorter than n"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --maxseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------- minseqlength

DESCRIPTION="--sortbylength --minseqlength is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--sortbylength --minseqlength removes sequences shorter than n"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --minseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--sortbylength --minseqlength keeps sequences of length n"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --minseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">sAA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --minseqlength keeps sequences longer than n"
printf ">s\nAAA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --minseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">sAAA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ----------------------------------------------------------------------- topn
DESCRIPTION="--sortbylength accepts --topn"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --topn 1 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --topn must be greater than zero"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --topn 0 \
    --output - /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sortbylength --topn can be larger than the number of entries"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --topn 2 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --topn can be larger than the number of entries (no effect on output)"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --topn 2 \
    --output - | \
    awk '{if ($1 ~ /^>/) {entries++}} END {exit entries == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --topn can be equal to the number of entries (no effect on output)"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=3\nAA\n>s2;size=1\nTT\n") \
    --quiet \
    --topn 2 \
    --output - | \
    awk '{if ($1 ~ /^>/) {entries++}} END {exit entries == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --topn keeps n first entries"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=3\nAA\n>s2;size=1\nTT\n") \
    --quiet \
    --topn 1 \
    --output - | \
    awk '{if ($1 ~ /^>/) {entries++}} END {exit entries == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## for each secondary option below, write at least two tests: 1)
## accepts option, 2) check basic option effect (if applicable)

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--sortbylength --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --sortbylength - \
        --bzip2_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --bzip2_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --sortbylength - \
        --bzip2_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fasta_width

DESCRIPTION="--sortbylength --fasta_width is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --fasta_width 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --fasta_width wraps fasta output"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --fasta_width 1 \
        --output - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--sortbylength --fastq_ascii is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --fastq_ascii 33 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--sortbylength --fastq_qmax is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --fastq_qmax 41 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --fastq_qmax has no effect"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --fastq_qmax 40 \
        --output - | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--sortbylength --fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --fastq_qmin 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --fastq_qmin has no effect"
printf "@s\nA\n+\nH\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --fastq_qmin 40 \
        --output - | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--sortbylength --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --sortbylength - \
        --gzip_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --gzip_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --sortbylength - \
        --gzip_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix
 
DESCRIPTION="--sortbylength --label_suffix is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --label_suffix "_suffix" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --label_suffix adds the suffix 'string' to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --label_suffix "_suffix" \
        --output - | \
    grep -wq ">s_suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --label_suffix adds the suffix 'string' (before annotations)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --label_suffix "_suffix" \
        --lengthout \
        --output - | \
    grep -wq ">s_suffix;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--sortbylength --lengthout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --lengthout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --lengthout adds length annotations to output"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --lengthout \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--sortbylength --log is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --log /dev/null \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --log writes to a file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --output /dev/null \
        --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --log does not prevent messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --output /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--sortbylength --no_progress is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --no_progress \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--sortbylength --no_progress removes progressive report on stderr (no visible effect)"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --no_progress \
        --output /dev/null 2>&1 | \
    grep -iq "^sorting" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--sortbylength --notrunclabels is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --notrunclabels \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --notrunclabels preserves full headers"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --notrunclabels \
        --output - | \
    grep -wq ">s extra" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--sortbylength --quiet is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --quiet eliminates all (normal) messages to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--sortbylength --quiet allows error messages to be sent to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --quiet2 \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--sortbylength --relabel is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel renames sequence (label + ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel renames sequence (empty label, only ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "" \
        --output - | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel cannot combine with --relabel_md5"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --relabel_md5 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel cannot combine with --relabel_sha1"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --relabel_sha1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--sortbylength --relabel_keep is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_keep renames and keeps original sequence name"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output - | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--sortbylength --relabel_md5 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_md5 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_md5 relabels using MD5 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--sortbylength --relabel_sha1 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_sha1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_sha1 relabels using SHA1 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--sortbylength --relabel_self is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_self \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_self relabels using sequence as label"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--sortbylength --sample is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --sample "ABC" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --sample adds sample name to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --sample "ABC" \
        --output - | \
    grep -qw ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--sortbylength --sizein is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --sizein \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --sizein is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --sizein \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --sizein (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength size annotations are present in output (with --sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --sizein \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength size annotations are present in output (without --sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

# When using --relabel, --relabel_self, --relabel_md5 or --relabel_sha1,
# preserve and report abundance annotations to the output fasta file
# (using the pattern ';size=integer;').

DESCRIPTION="--sortbylength --sizeout is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --sizeout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --sizeout is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --sizeout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --sizeout missing size annotations are not added (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength size annotations are present in output (with --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --sizeout \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength size annotations are present in output (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## add abundance annotations
DESCRIPTION="--sortbylength --relabel no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_self no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_self --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_md5 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_md5 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_sha1 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_sha1 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## preserve abundance annotations
DESCRIPTION="--sortbylength --relabel no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_self no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_self --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_md5 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_md5 --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_sha1 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --relabel_sha1 --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--sortbylength --threads is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --threads 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --threads > 1 triggers a warning (not multithreaded)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --threads 2 \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--sortbylength --xee is accepted"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --xee \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --xee removes expected error annotations from input"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --xee \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--sortbylength --xlength is accepted"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --xlength \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --xlength removes length annotations from input"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --xlength \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --xlength removes length annotations (input), lengthout adds them (output)"
printf ">s;length=2\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --xlength \
        --lengthout \
        --quiet \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

DESCRIPTION="--sortbylength --xsize is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --xsize \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbylength --xsize removes abundance annotations from input"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --xsize \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does not work as expected!
# DESCRIPTION="--sortbylength --xsize removes abundance annotations (input), sizeout adds them (output)"
# printf ">s;size=2\nA\n" | \
#     "${VSEARCH}" \
#         --sortbylength - \
#         --xsize \
#         --quiet \
#         --sizeout \
#         --output - | \
#     grep -wq ">s;size=1" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------------- maxsize
DESCRIPTION="--sortbylength rejects --maxsize"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=1\nAA\n") \
    --quiet \
    --maxsize 2 \
    --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------------- minsize
DESCRIPTION="--sortbylength rejects --minsize"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --minsize 2 \
    --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

exit 0

# status: complete (v2.28.1, 2024-05-21)
