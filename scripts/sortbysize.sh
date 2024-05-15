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

## see also issue 28 for some initial tests

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

## ----------------------------------------------------------------------- topn
DESCRIPTION="--sortbysize accepts --topn"
"${VSEARCH}" \
    --sortbysize <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --topn 1 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 sorting                                     #
#                                                                             #
#*****************************************************************************#

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


#*****************************************************************************#
#                                                                             #
#                            median abundance                                 #
#                                                                             #
#*****************************************************************************#

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

exit 0
