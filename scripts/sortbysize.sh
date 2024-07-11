#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="sortbysize"
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
## The valid options for the sortbysize command are:
## --bzip2_decompress --fasta_width --fastq_ascii --fastq_qmax
## --fastq_qmin --gzip_decompress --label_suffix --lengthout --log
## --maxseqlength --maxsize --minseqlength --minsize --no_progress
## --notrunclabels --output --quiet --relabel --relabel_keep
## --relabel_md5 --relabel_self --relabel_sha1 --sample --sizein
## --sizeout --threads --topn --xee --xlength --xsize

#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------------- output
DESCRIPTION="--sortbysize requires --output"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sortbysize fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--sortbysize outputs in fasta format"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">s1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize empty input -> empty output"
printf "" | \
    "${VSEARCH}" \
        --sortbysize - \
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

# (from issue 38) sort by size ...
DESCRIPTION="--sortbysize single entry, no sorting"
${VSEARCH} \
    --sortbysize <(printf ">s1;size=2\nA\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=2A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize sorts by size (already ordered)"
${VSEARCH} \
    --sortbysize <(printf ">s1;size=2\nA\n>s2;size=1\nT\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=2A>s2;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize sorts by size (reverse order)"
${VSEARCH} \
    --sortbysize <(printf ">s2;size=1\nT\n>s1;size=2\nA\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=2A>s2;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ... then by label
DESCRIPTION="--sortbysize sorts by size then by label (already ordered)"
${VSEARCH} \
    --sortbysize <(printf ">s1;size=1\nA\n>s2;size=1\nT\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=1A>s2;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize sorts by size then by label (reverse order)"
${VSEARCH} \
    --sortbysize <(printf ">s2;size=1\nT\n>s1;size=1\nA\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=1A>s2;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ... then by input order
DESCRIPTION="--sortbysize sorts by size then by label then by input order (reversed sequence order)"
${VSEARCH} \
    --sortbysize <(printf ">s1;size=1\nT\n>s1;size=1\nA\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=1T>s1;size=1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize sorts by size then by label then by input order (normal sequence order)"
${VSEARCH} \
    --sortbysize <(printf ">s1;size=1\nA\n>s1;size=1\nT\n") \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1;size=1A>s1;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- median length

# The sortbysize command outputs on the stderr or in a log file the
# median abundance value of processed fasta sequences. To refactor the
# piece of code that performs this computation, I need to write
# tests. Note that the --sizein option is not necessary.

DESCRIPTION="--sortbysize median abundance is written to stderr"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -q "^Median abundance:" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize median abundance (empty input)"
printf "" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize median abundance (single entry)"
printf ">s1;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize median abundance (null abundances are errors)"
printf ">s1;size=0\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sortbysize median abundance (missing abundances are assumed to be ';size=1')"
printf ">s1;size=\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does return an average "(9 + 1) / 2 = 5"
DESCRIPTION="--sortbysize median abundance (average of two entries)"
printf ">s1;size=9\nA\n>s2;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does return an average, but:
#  - fprintf rounding ("%.0f\n") (1 + 2) / 2 = 1.5 ~ 2
#  - Banker's rounding (round half to even)
DESCRIPTION="--sortbysize median abundance (rounded average of two entries #1)"
printf ">s1;size=2\nA\n>s2;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does return an average, but:
#  - fprintf rounding ("%.0f\n") (1 + 4) / 2 = 2.5 ~ 2
#  - Banker's rounding (round half to even)
DESCRIPTION="--sortbysize median abundance (rounded average of two entries #2)"
printf ">s1;size=4\nA\n>s2;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does return an average, but:
#  - fprintf rounding ("%.0f\n") (1 + 6) / 2 = 3.5 ~ 4
#  - Banker's rounding (round half to even)
DESCRIPTION="--sortbysize median abundance (rounded average of two entries #3)"
printf ">s1;size=6\nA\n>s2;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# odd-sized list of entries (returns the middle point entry)
DESCRIPTION="--sortbysize median abundance (odd number of entries)"
printf ">s1;size=3\nA\n>s2;size=2\nA\n>s3;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# even-sized list of entries:
# - returns the average of entries around the middle point,
# - average is either round or has a remainder of 0.5
# - fprintf rounds half to the closest even value
DESCRIPTION="--sortbysize median abundance (even number of entries)"
printf ">s1;size=4\nA\n>s2;size=3\nA\n>s3;size=2\nA\n>s4;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# even-sized list of entries, all abundance values are set to one
DESCRIPTION="--sortbysize median abundance (same abundance for all entries)"
printf ">s1;size=1\nA\n>s2;size=1\nA\n>s3;size=1\nA\n>s4;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# even-sized list of entries (reversed-order abundances)
DESCRIPTION="--sortbysize median abundance (even, reversed-order abundances)"
printf ">s1;size=1\nA\n>s2;size=2\nA\n>s3;size=3\nA\n>s4;size=4\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# odd-sized list of entries (reversed-order abundances)
DESCRIPTION="--sortbysize median abundance (odd, reversed-order abundances)"
printf ">s1;size=1\nA\n>s2;size=2\nA\n>s3;size=3\nA\n>s4;size=4\nA\n>s5;size=5\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# when using --quiet, the median is not printed
DESCRIPTION="--sortbysize median abundance is not printed when --quiet"
printf ">s1;size=6\nA\n>s2;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -qw "^Median" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# when using --log, the median is printed in the log file
DESCRIPTION="--sortbysize --log median abundance is printed to a log"
printf ">s1;size=6\nA\n>s2;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null \
        --log - 2>/dev/null | \
    grep -qw "^Median" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize median abundance is computed after maxsize"
printf ">s1;size=6\nA\n>s2;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --maxsize 5 \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize median abundance is computed after minsize"
printf ">s1;size=6\nA\n>s2;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --minsize 3 \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 6" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize median abundance is computed before topn"
printf ">s1;size=6\nA\n>s2;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --topn 1 \
        --output /dev/null 2>&1 > /dev/null | \
    grep -qw "Median abundance: 4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------------- maxsize
DESCRIPTION="--sortbysize accepts --maxsize"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=1\nAA\n") \
    --quiet \
    --maxsize 2 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --maxsize discards abundances greater than value (<)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=1\nAA\n") \
    --quiet \
    --maxsize 2 \
    --output - | \
    grep -qw ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --maxsize discards abundances greater than value (=)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=2\nAA\n") \
    --quiet \
    --maxsize 2 \
    --output - | \
    grep -qw ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --maxsize discards abundances greater than value (>)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --maxsize 2 \
    --output - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------------- minsize
DESCRIPTION="--sortbysize accepts --minsize"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --minsize 2 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --minsize discards abundances lesser than value (>)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --minsize 2 \
    --output - | \
    grep -qw ">s1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --minsize discards abundances lesser than value (=)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=2\nAA\n") \
    --quiet \
    --minsize 2 \
    --output - | \
    grep -qw ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --minsize discards abundances lesser than value (<)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=1\nAA\n") \
    --quiet \
    --minsize 2 \
    --output - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sortbysize --minsize equals --maxsize (select a specific abundance value)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=2\nAA\n") \
    --quiet \
    --minsize 2 \
    --maxsize 2 \
    --output - | \
    grep -qw ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --minsize greater than --maxsize (always empty output)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=2\nAA\n") \
    --quiet \
    --minsize 3 \
    --maxsize 2 \
    --output - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------------- topn
DESCRIPTION="--sortbysize accepts --topn"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --topn 1 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --topn must be greater than zero"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --topn 0 \
    --output - /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sortbysize --topn can be larger than the number of entries"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --topn 2 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --topn can be larger than the number of entries (no effect on output)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --topn 2 \
    --output - | \
    awk '{if ($1 ~ /^>/) {entries++}} END {exit entries == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --topn can be equal to the number of entries (no effect on output)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n>s2;size=1\nTT\n") \
    --quiet \
    --topn 2 \
    --output - | \
    awk '{if ($1 ~ /^>/) {entries++}} END {exit entries == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --topn keeps n first entries"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n>s2;size=1\nTT\n") \
    --quiet \
    --topn 1 \
    --output - | \
    awk '{if ($1 ~ /^>/) {entries++}} END {exit entries == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --topn is applied after size filtering (--maxsize)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nA\n>s2;size=1\nT\n") \
    --maxsize 2 \
    --quiet \
    --topn 1 \
    --output - | \
    grep -qw ">s2;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --topn is applied after size filtering (--minsize)"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=4\nA\n>s2;size=2\nT\n>s3;size=1\nC\n") \
    --maxsize 3 \
    --minsize 2 \
    --quiet \
    --topn 1 \
    --output - | \
    grep -qw ">s2;size=2" && \
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

DESCRIPTION="--sortbysize --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --sortbysize - \
        --bzip2_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --bzip2_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --sortbysize - \
        --bzip2_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fasta_width

DESCRIPTION="--sortbysize --fasta_width is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --fasta_width 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --fasta_width wraps fasta output"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --fasta_width 1 \
        --output - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--sortbysize --fastq_ascii is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --fastq_ascii 33 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--sortbysize --fastq_qmax is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --fastq_qmax 41 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --fastq_qmax has no effect"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --fastq_qmax 40 \
        --output - | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--sortbysize --fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --fastq_qmin 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --fastq_qmin has no effect"
printf "@s\nA\n+\nH\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --fastq_qmin 40 \
        --output - | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--sortbysize --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --sortbysize - \
        --gzip_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --gzip_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --sortbysize - \
        --gzip_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--sortbysize --label_suffix is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --label_suffix "_suffix" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --label_suffix adds the suffix 'string' to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --label_suffix "_suffix" \
        --output - | \
    grep -wq ">s_suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --label_suffix adds the suffix 'string' (before annotations)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --label_suffix "_suffix" \
        --lengthout \
        --output - | \
    grep -wq ">s_suffix;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--sortbysize --lengthout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --lengthout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --lengthout adds length annotations to output"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --lengthout \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--sortbysize --log is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --log /dev/null \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --log writes to a file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --output /dev/null \
        --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --log does not prevent messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --output /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- maxseqlength

DESCRIPTION="--sortbysize --maxseqlength is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --maxseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--sortbysize --maxseqlength removes sequences longer than n"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --maxseqlength 1 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- minseqlength

DESCRIPTION="--sortbysize --minseqlength is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--sortbysize --minseqlength removes sequences shorter than n"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --minseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--sortbysize --no_progress is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --no_progress \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--sortbysize --no_progress removes progressive report on stderr (no visible effect)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --no_progress \
        --output /dev/null 2>&1 | \
    grep -iq "^sorting" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--sortbysize --notrunclabels is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --notrunclabels \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --notrunclabels preserves full headers"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --notrunclabels \
        --output - | \
    grep -wq ">s extra" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--sortbysize --quiet is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --quiet eliminates all (normal) messages to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--sortbysize --quiet allows error messages to be sent to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --quiet2 \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--sortbysize --relabel is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel renames sequence (label + ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel renames sequence (empty label, only ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "" \
        --output - | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel cannot combine with --relabel_md5"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --relabel_md5 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel cannot combine with --relabel_sha1"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --relabel_sha1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--sortbysize --relabel_keep is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_keep renames and keeps original sequence name"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output - | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--sortbysize --relabel_md5 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_md5 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_md5 relabels using MD5 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--sortbysize --relabel_sha1 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_sha1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_sha1 relabels using SHA1 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--sortbysize --relabel_self is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_self \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_self relabels using sequence as label"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--sortbysize --sample is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --sample "ABC" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --sample adds sample name to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --sample "ABC" \
        --output - | \
    grep -qw ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--sortbysize --sizein is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --sizein \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --sizein is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --sizein \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --sizein (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize size annotations are present in output (with --sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --sizein \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize size annotations are present in output (without --sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

# When using --relabel, --relabel_self, --relabel_md5 or --relabel_sha1,
# preserve and report abundance annotations to the output fasta file
# (using the pattern ';size=integer;').

DESCRIPTION="--sortbysize --sizeout is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --sizeout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --sizeout is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --sizeout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --sizeout missing size annotations are not added (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize size annotations are present in output (with --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --sizeout \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize size annotations are present in output (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## add abundance annotations
DESCRIPTION="--sortbysize --relabel no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_self no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_self --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_md5 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_md5 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_sha1 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_sha1 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## preserve abundance annotations
DESCRIPTION="--sortbysize --relabel no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_self no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_self --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_md5 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_md5 --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_sha1 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --relabel_sha1 --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--sortbysize --threads is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --threads 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --threads > 1 triggers a warning (not multithreaded)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --threads 2 \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--sortbysize --xee is accepted"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --xee \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --xee removes expected error annotations from input"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --xee \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--sortbysize --xlength is accepted"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --xlength \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --xlength removes length annotations from input"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --xlength \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --xlength removes length annotations (input), lengthout adds them (output)"
printf ">s;length=2\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --xlength \
        --lengthout \
        --quiet \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

DESCRIPTION="--sortbysize --xsize is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --xsize \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sortbysize --xsize removes abundance annotations from input"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --xsize \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does not work as expected!
# DESCRIPTION="--sortbysize --xsize removes abundance annotations (input), sizeout adds them (output)"
# printf ">s;size=2\nA\n" | \
#     "${VSEARCH}" \
#         --sortbysize - \
#         --xsize \
#         --quiet \
#         --sizeout \
#         --output - | \
#     grep -wq ">s;size=1" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then
    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --sortbysize <(printf ">s1\nA\n>s2\nAA\n") \
        --output /dev/null 2> /dev/null
    DESCRIPTION="--sortbysize valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--sortbysize valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0

# status: complete (v2.28.1, 2024-06-05)
