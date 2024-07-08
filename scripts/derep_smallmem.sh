#!/bin/bash -

## Print a header
SCRIPT_NAME="derep_smallmem"
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

## --derep_smallmem is accepted
DESCRIPTION="--derep_smallmem is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# cannot read from a pipe, as data must be read twice
DESCRIPTION="--derep_smallmem cannot read data from a pipe"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_smallmem - \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------- mandatory output file: fastaout

DESCRIPTION="--derep_smallmem requires an output file"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem requires an output file (fasta in, fastaout)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem fails if unable to open output file for writing (fasta in, fastaout)"
INPUT=$(mktemp)
printf ">s\nA\n" > ${INPUT}
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_smallmem ${INPUT} \
        --fastaout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP} ${INPUT}
unset TMP INPUT

DESCRIPTION="--derep_smallmem requires an output file (fastq in, fastaout)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem fails if unable to open output file for writing (fastq in, fastaout)"
INPUT=$(mktemp)
printf "@s\nA\n+\nI\n" > ${INPUT}
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
"${VSEARCH}" \
    --derep_smallmem ${INPUT} \
    --fastaout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP} ${INPUT}
unset TMP INPUT

DESCRIPTION="--derep_smallmem can read but not write fastq"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem accepts empty input"
TMP=$(mktemp)
printf "" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem accepts fastq input"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem rejects non-fasta input (#1)"
TMP=$(mktemp)
printf "\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem rejects non-fasta input (#2)"
TMP=$(mktemp)
printf "\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2> /dev/null  && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem accepts a single fasta entry"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# accept entries shorter than 32 nucleotides by default
DESCRIPTION="--derep_smallmem accepts short fasta entry"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem discards an empty fasta entry"
TMP=$(mktemp)
printf ">s\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# attempt to trigger a special case of seqcmp()
DESCRIPTION="--derep_smallmem compare two empty fasta entries"
TMP=$(mktemp)
printf ">s1\n>s2\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# attempt to trigger a special case of seqcmp()
DESCRIPTION="--derep_smallmem compare two fasta entries (one is empty)"
TMP=$(mktemp)
printf ">s1\nA\n>s2\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ---------------------- options for simpler tests: --quiet and --minseqlength

DESCRIPTION="--derep_smallmem outputs stderr messages"
TMP=$(mktemp)
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --quiet removes stderr messages"
TMP=$(mktemp)
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# keep empty fasta entries
DESCRIPTION="--derep_smallmem --minseqlength 0 (keep empty fasta entries)"
TMP=$(mktemp)
printf ">s\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 0 \
    --quiet \
    --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------- test general behaviour

## --derep_smallmem outputs data
DESCRIPTION="--derep_smallmem outputs data"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --derep_smallmem outputs expected results
DESCRIPTION="--derep_smallmem outputs expected results (in fasta format)"
TMP=$(mktemp)
printf ">s1\nA\n>s2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem identical seqs receive the header of the first seq of the group"
TMP=$(mktemp)
printf ">s2\nA\n>s1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s2@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# The output is written in the order that the sequences first appear
# in the input, and not in descending abundance order
DESCRIPTION="--derep_smallmem dereplicated sequences are not sorted by decreasing abundance"
TMP=$(mktemp)
printf ">s2\nA\n>s1\nC\n>s3\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s2@A@>s1@C@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --derep_smallmem distinct sequences are not sorted by
## alphabetical order of headers (s1 before s2)
DESCRIPTION="--derep_smallmem distinct sequences are not sorted by header alphabetical order"
TMP=$(mktemp)
printf ">s2\nA\n>s1\nG\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s2@A@>s1@G@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --derep_smallmem distinct sequences are not sorted by
## alphabetical order of DNA strings (G before A)
DESCRIPTION="--derep_smallmem distinct sequences are not sorted by DNA alphabetical order"
TMP=$(mktemp)
printf ">s1\nG\n>s2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@G@>s2@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# no sorting by decreasing abundance: s1 > s2 and s2 > s1
DESCRIPTION="--derep_smallmem does not sort clusters by decreasing abundance (natural order)"
TMP=$(mktemp)
printf ">s1;size=3\nA\n>s2;size=1\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=3@A@>s2;size=1@C@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem does not sort clusters by decreasing abundance (reversed input order)"
TMP=$(mktemp)
printf ">s1;size=1\nA\n>s2;size=3\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=1@A@>s2;size=3@C@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# same abundance, compare headers: s1 > s2 and s2 > s1
DESCRIPTION="--derep_smallmem does not sort clusters by comparing headers (natural order)"
TMP=$(mktemp)
printf ">s1;size=2\nA\n>s2;size=2\nC\n" > ${TMP}
    "${VSEARCH}" \
        --derep_smallmem ${TMP} \
        --sizein \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@A@>s2;size=2@C@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem then sort clusters by comparing headers (reversed input order)"
TMP=$(mktemp)
printf ">s2;size=2\nA\n>s1;size=2\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s2;size=2@A@>s1;size=2@C@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# same abundance, same headers, compare input order: s1 > s2 and s2 > s1
DESCRIPTION="--derep_smallmem sorts clusters by input order (natural order)"
TMP=$(mktemp)
printf ">s1;size=2\nC\n>s1;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@C@>s1;size=2@A@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem then sort clusters by input order (reversed input order)"
TMP=$(mktemp)
printf ">s1;size=2\nA\n>s1;size=2\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@A@>s1;size=2@C@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --derep_smallmem sequence comparison is case insensitive
DESCRIPTION="--derep_smallmem sequence comparison is case insensitive"
TMP=$(mktemp)
printf ">s1\nA\n>s2\na\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --derep_smallmem preserves the case of the first occurrence of each sequence
DESCRIPTION="--derep_smallmem preserves the case of the first occurrence of each sequence"
TMP=$(mktemp)
printf ">s1\na\n>s2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@a@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --derep_smallmem T and U are considered the same
DESCRIPTION="--derep_smallmem T and U are considered the same"
TMP=$(mktemp)
printf ">s1\nT\n>s2\nU\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@T@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --derep_smallmem does not replace U with T in its output
DESCRIPTION="--derep_smallmem does not replace U with T in its output"
TMP=$(mktemp)
printf ">s1\nU\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@U@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --derep_smallmem accepts more than 1,024 unique sequences
## (trigger reallocation)
DESCRIPTION="--derep_smallmem accepts more than 1,024 unique sequences"
TMP=$(mktemp)
(for i in {1..1025} ; do
    printf ">s%d\n" ${i}
    yes A | head -n ${i}
 done) > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --------------------------------------------------------------------- median

DESCRIPTION="--derep_smallmem outputs a median cluster size"
TMP=$(mktemp)
printf ">s1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2>&1 | \
    grep -q "median" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (empty entry, no median)"
TMP=$(mktemp)
printf "" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2>&1 | \
    grep -q "median" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (single entry, median = 1)"
TMP=$(mktemp)
printf ">s1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (single entry with size annotation, median = 2)"
TMP=$(mktemp)
printf ">s1;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (two entries, median = 1)"
TMP=$(mktemp)
printf ">s1\nA\n>s2\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (two entries with equal size annotations, median = 2)"
TMP=$(mktemp)
printf ">s1;size=2\nA\n>s2;size=2\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## Banker's rounding (round half to even)
DESCRIPTION="--derep_smallmem median (1 + 2 -> median = 2)"
TMP=$(mktemp)
printf ">s1;size=1\nA\n>s2;size=2\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (1 + 3 -> median = 2)"
TMP=$(mktemp)
printf ">s1;size=1\nA\n>s2;size=3\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (1 + 4 -> median = 2)"
TMP=$(mktemp)
printf ">s1;size=1\nA\n>s2;size=4\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (1 + 5 -> median = 3)"
TMP=$(mktemp)
printf ">s1;size=1\nA\n>s2;size=5\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (1 + 6 -> median = 4)"
TMP=$(mktemp)
printf ">s1;size=1\nA\n>s2;size=6\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (1 + 7 -> median = 4)"
TMP=$(mktemp)
printf ">s1;size=1\nA\n>s2;size=7\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (1 + 8 -> median = 4)"
TMP=$(mktemp)
printf ">s1;size=1\nA\n>s2;size=8\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem median (1 + 9 -> median = 5)"
TMP=$(mktemp)
printf ">s1;size=1\nA\n>s2;size=9\nC\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## trigger specific case for coverage
DESCRIPTION="--derep_smallmem cluster size is smaller than the candidate size for the median"
TMP=$(mktemp)
printf ">s1\nA\n>s2\nC\n>s3\nA\n>s4\nC\n>s5\nG\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null 2>&1 | \
    grep -q "median 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------- maxuniquesize

# maximum abundance for output from dereplication

DESCRIPTION="--maxuniquesize is accepted"
TMP=$(mktemp)
printf ">s1\nA\n>s2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 2 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize accepts lesser dereplicated sizes (<)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize accepts equal dereplicated sizes (=)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize rejects greater dereplicated sizes (>)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize must be an integer (not a double)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 1.0 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize must be an integer (not a char)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize A \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize must be a positive integer"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize -1 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize must be greater than zero"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 0 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize accepts a value of 1 (no dereplication)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 1 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize accepts large values (2^8)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 256 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize accepts large values (2^16)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 65536 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize accepts large values (2^32)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 4294967296 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize accepts large values (2^32)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 4294967296 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# combine with sizein
DESCRIPTION="--maxuniquesize --sizein accepts lesser dereplicated sizes (<)"
TMP=$(mktemp)
printf ">s;size=1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --maxuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize --sizein accepts equal dereplicated sizes (=)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --maxuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize --sizein rejects greater dereplicated sizes (>)"
TMP=$(mktemp)
printf ">s;size=3\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --maxuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize restricts number of clusters (without --quiet)"
TMP=$(mktemp)
printf ">s1\nA\n>s2\nA\n>s3\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 2 \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--maxuniquesize restricts number of clusters (with --log)"
TMP=$(mktemp)
printf ">s1\nA\n>s2\nA\n>s3\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxuniquesize 2 \
    --log /dev/null \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## -------------------------------------------------------------- minuniquesize

# minimum abundance for output from dereplication

DESCRIPTION="--minuniquesize is accepted"
TMP=$(mktemp)
printf ">s1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 1 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize rejects lesser dereplicated sizes (<)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize accepts equal dereplicated sizes (=)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize accepts greater dereplicated sizes (>)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize must be an integer (not a double)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 1.0 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize must be an integer (not a char)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize A \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize must be a positive integer"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize -1 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize must be greater than zero"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 0 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize accepts a value of 1"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 1 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize accepts large values (2^8)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 256 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize accepts large values (2^16)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 65536 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize accepts large values (2^32)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 4294967296 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize accepts large values (2^32)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 4294967296 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# combine with sizein
DESCRIPTION="--minuniquesize --sizein rejects lesser dereplicated sizes (<)"
TMP=$(mktemp)
printf ">s;size=1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --minuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize --sizein accepts equal dereplicated sizes (=)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --minuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize --sizein accepts greater dereplicated sizes (>)"
TMP=$(mktemp)
printf ">s;size=3\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --minuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# combine min-max? normal, same, inverted
DESCRIPTION="--minuniquesize --maxuniquesize accepts dereplicated sizes (normal usage)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 2 \
    --maxuniquesize 4 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize --maxuniquesize accepts dereplicated sizes (same threshold)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 3 \
    --maxuniquesize 3 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# should warn that minuniquesize > maxuniquesize (output always empty)?
DESCRIPTION="--minuniquesize --maxuniquesize rejects dereplicated sizes (swapped threshold)"
TMP=$(mktemp)
printf ">s\nA\n>s\nA\n>s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 3 \
    --maxuniquesize 2 \
    --quiet \
    --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize restricts number of clusters (without --quiet)"
TMP=$(mktemp)
printf ">s1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 2 \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--minuniquesize restricts number of clusters (with --log)"
TMP=$(mktemp)
printf ">s1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minuniquesize 2 \
    --log /dev/null \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --------------------------------------------------------------------- strand

## --strand is accepted
DESCRIPTION="--strand is accepted"
TMP=$(mktemp)
printf ">s1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --strand both \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --strand both allow dereplication of strand plus and minus (--derep_smallmem)
DESCRIPTION="--strand allow dereplication of strand plus and minus (--derep_smallmem)"
TMP=$(mktemp)
printf ">s1;size=1;\nA\n>s2;size=1;\nT\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --sizeout \
    --strand both \
    --quiet \
    --fastaout - | \
    grep -wqE ">s1;size=2;?" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --strand plus does not change default behaviour
DESCRIPTION="--strand plus does not change default behaviour"
TMP=$(mktemp)
printf ">s1;size=1;\nA\n>s2;size=1;\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --sizeout \
    --quiet \
    --strand plus \
    --fastaout - | \
    grep -wqE ">s1;size=2;?" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --strand fails if an unknown argument is given
DESCRIPTION="--strand fails if an unknown argument is given"
TMP=$(mktemp)
printf ">s1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --strand unknown \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --------------------------------------------------------------------- sizein

DESCRIPTION="--sizein is accepted (no size annotation)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--sizein is accepted (size annotation)"
TMP=$(mktemp)
printf ">s;size=1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--sizein (no size in, no size out)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--sizein --sizeout assumes size=1 (no size annotation)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --sizeout \
    --fastaout - | \
    grep -qw ">s;size=1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--sizein propagates size annotations (sizeout is implied)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --fastaout - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--derep_smallmem --bzip2_decompress is accepted (empty input)"
TMP=$(mktemp)
printf "" | bzip2 --stdout > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --bzip2_decompress \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem accepts compressed input (bzip2)"
TMP=$(mktemp)
printf ">s\nA\n" | bzip2 --stdout > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --bzip2_decompress is accepted (empty input)"
TMP=$(mktemp)
printf "" | bzip2 --stdout > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --bzip2_decompress \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --bzip2_decompress accepts compressed input"
TMP=$(mktemp)
printf ">s\nA\n" | bzip2 --stdout > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --bzip2_decompress \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --bzip2_decompress rejects uncompressed input"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --bzip2_decompress \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ---------------------------------------------------------------- fasta_width

# Fasta files produced by vsearch are wrapped (sequences are written on
# lines of integer nucleotides, 80 by default). Set the value to zero to
# eliminate the wrapping.

DESCRIPTION="--derep_smallmem --fasta_width is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fasta_width 1 \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# 80 nucleotides, expect 2 lines (header + one sequence line)
DESCRIPTION="--derep_smallmem fasta output is not wrapped (80 nucleotides or less)"
TMP=$(mktemp)
printf ">s\n%080s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# 81 nucleotides, expect 3 lines
DESCRIPTION="--derep_smallmem fasta output is wrapped (81 nucleotides or more)"
TMP=$(mktemp)
printf ">s\n%081s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fasta_width is accepted (empty input)"
TMP=$(mktemp)
printf "" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fasta_width 80 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fasta_width 2^32 is accepted"
TMP=$(mktemp)
printf ">s\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fasta_width $(( 2 ** 32 )) \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# 2 nucleotides, expect 3 lines
DESCRIPTION="--derep_smallmem --fasta_width 1 (1 nucleotide per line)"
TMP=$(mktemp)
printf ">s\nTT\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 2 \
    --fasta_width 1 \
    --quiet \
    --fastaout - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# expect 81 nucleotides on the second line
DESCRIPTION="--derep_smallmem --fasta_width 0 (no wrapping)"
TMP=$(mktemp)
printf ">s\n%081s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fasta_width 0 \
    --quiet \
    --fastaout - | \
    awk 'NR == 2 {exit length($1) == 81 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--derep_smallmem --fastq_ascii is accepted"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 33 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_ascii 33 is accepted"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 33 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_ascii 64 is accepted"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 64 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_ascii values other than 33 and 64 are rejected"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 63 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--derep_smallmem --fastq_qmax is accepted"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmax 41 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmax accepts lower quality values (H = 39)"
TMP=$(mktemp)
printf "@s\nA\n+\nH\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmax 40 \
    --quiet \
    --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmax accepts equal quality values (I = 40)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmax 40 \
    --quiet \
    --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## fastq_qmax has no effect!
# DESCRIPTION="--derep_smallmem --fastq_qmax rejects higher quality values (J = 41)"
# TMP=$(mktemp)
# printf "@s\nA\n+\nJ\n" > ${TMP}
# "${VSEARCH}" \
#     --derep_smallmem ${TMP} \
#     --fastq_qmax 40 \
#     --quiet \
#     --fastaout - | \
#     grep -q "." && \
#     failure "${DESCRIPTION}" || \
#         success "${DESCRIPTION}"
# rm -f ${TMP}
# unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmax must be a positive integer"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmax -1 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmax can be set to zero"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmax 0 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmax can be set to 93 (offset 33)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 33 \
    --fastq_qmax 93 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmax cannot be greater than 93 (offset 33)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 33 \
    --fastq_qmax 94 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmax can be set to 62 (offset 64)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 64 \
    --fastq_qmax 62 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmax cannot be greater than 62 (offset 64)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 64 \
    --fastq_qmax 63 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--derep_smallmem --fastq_qmin is accepted"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmin 0 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmin accepts higher quality values (0 = 15)"
TMP=$(mktemp)
printf "@s\nA\n+\n0\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmin 14 \
    --quiet \
    --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmin accepts equal quality values (0 = 15)"
TMP=$(mktemp)
printf "@s\nA\n+\n0\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmin 15 \
    --quiet \
    --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# ## fastq_qmin has no effect!
# DESCRIPTION="--derep_smallmem --fastq_qmin rejects lower quality values (0 = 15)"
# TMP=$(mktemp)
# printf "@s\nA\n+\n0\n" > ${TMP}
# "${VSEARCH}" \
#     --derep_smallmem ${TMP} \
#     --fastq_qmin 16 \
#     --quiet \
#     --fastaout - | \
#     grep -q "." && \
#     failure "${DESCRIPTION}" || \
#         success "${DESCRIPTION}"
# rm -f ${TMP}
# unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmin must be a positive integer"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmin -1 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmin can be set to zero (default)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmin 0 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmin can be lower than fastq_qmax (41 by default)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmin 40 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## allows to select only reads with a specific Q value
DESCRIPTION="--derep_smallmem --fastq_qmin can be equal to fastq_qmax (41 by default)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmin 41 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --fastq_qmin cannot be higher than fastq_qmax (41 by default)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmin 42 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# but not higher, as it cannot be greater than qmax
DESCRIPTION="--derep_smallmem --fastq_qmin can be set to 93 (offset 33)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 33 \
    --fastq_qmin 93 \
    --fastq_qmax 93 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# but not higher, as it cannot be greater than qmax
DESCRIPTION="--derep_smallmem --fastq_qmin can be set to 62 (offset 64)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_ascii 64 \
    --fastq_qmin 62 \
    --fastq_qmax 62 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--derep_smallmem --gzip_decompress is accepted (empty input)"
TMP=$(mktemp)
printf "" | gzip --stdout > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --gzip_decompress \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem accepts compressed input (gzip)"
TMP=$(mktemp)
printf ">s\nA\n" | gzip --stdout > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --gzip_decompress is accepted (empty input)"
TMP=$(mktemp)
printf ""  | gzip --stdout > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --gzip_decompress \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --gzip_decompress accepts compressed stdin"
TMP=$(mktemp)
printf ">s\nA\n" | gzip --stdout > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --gzip_decompress \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# more flexible than bzip2
DESCRIPTION="--derep_smallmem --gzip_decompress accepts uncompressed input"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --gzip_decompress \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem rejects --bzip2_decompress + --gzip_decompress"
TMP=$(mktemp)
printf "" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --bzip2_decompress \
    --gzip_decompress \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--derep_smallmem --label_suffix is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --label_suffix "suffix" \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --label_suffix adds suffix (fasta in, fasta out)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --label_suffix ";suffix" \
    --fastaout - | \
    grep -qw ">s;suffix" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --label_suffix adds suffix (fastq in, fasta out)"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --label_suffix ";suffix" \
    --fastaout - | \
    grep -qw ">s;suffix" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --label_suffix adds suffix (empty suffix string)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --label_suffix "" \
    --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--derep_smallmem --lengthout is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --lengthout \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --lengthout adds length annotations to output"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --lengthout \
    --fastaout - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# lengthout + sizeout? is the order relevant?
DESCRIPTION="--derep_smallmem --lengthout --sizeout add annotations to output (size first)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --lengthout \
    --sizeout \
    --fastaout - | \
    grep -wq ">s;size=1;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ------------------------------------------------------------------------ log

DESCRIPTION="--derep_smallmem --log is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --log /dev/null \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --log writes to a file"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout /dev/null \
    --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --log does not prevent messages to be sent to stderr"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null \
    --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem accepts empty input (0 unique sequences)"
TMP=$(mktemp)
printf "" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastaout /dev/null \
    --log - 2> /dev/null | \
    grep -q "0 unique sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --------------------------------------------------------------- maxseqlength

DESCRIPTION="--derep_smallmem --maxseqlength is accepted"
TMP=$(mktemp)
printf ">s\n%081s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxseqlength 81 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --maxseqlength accepts shorter lengths (<)"
TMP=$(mktemp)
printf ">s\n%080s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxseqlength 81 \
    --quiet \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --maxseqlength accepts equal lengths (=)"
TMP=$(mktemp)
printf ">s\n%081s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxseqlength 81 \
    --quiet \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--derep_smallmem --maxseqlength rejects longer sequences (>)"
TMP=$(mktemp)
printf ">s\n%082s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxseqlength 81 \
    --quiet \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --maxseqlength accepts shorter lengths (--log)"
TMP=$(mktemp)
printf ">s\n%080s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxseqlength 81 \
    --log /dev/null \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --maxseqlength discards longer lengths (--log)"
TMP=$(mktemp)
printf ">s\n%080s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxseqlength 79 \
    --log /dev/null \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --maxseqlength must be an integer"
TMP=$(mktemp)
printf ">s\n%081s\n" | tr " " "A" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --maxseqlength A \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# ## missing check in vsearch code!
# DESCRIPTION="--derep_smallmem --maxseqlength must be a positive integer"
# TMP=$(mktemp)
# printf ">s\n%081s\n" | tr " " "A" > ${TMP}
# "${VSEARCH}" \
#     --derep_smallmem ${TMP} \
#     --maxseqlength -1 \
#     --quiet \
#     --fastaout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"
# rm -f ${TMP}
# unset TMP

# ## missing check in vsearch code! 
# DESCRIPTION="--derep_smallmem --maxseqlength must be greater than zero"
# TMP=$(mktemp)
# printf ">s\n%081s\n" | tr " " "A" > ${TMP}
# "${VSEARCH}" \
#     --derep_smallmem ${TMP} \
#     --maxseqlength 0 \
#     --quiet \
#     --fastaout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"
# rm -f ${TMP}
# unset TMP

## --------------------------------------------------------------- minseqlength

DESCRIPTION="--derep_smallmem --minseqlength is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 1 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--derep_smallmem --minseqlength rejects shorter sequences (<)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 2 \
    --quiet \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --minseqlength accepts equal lengths (=)"
TMP=$(mktemp)
printf ">s\nAA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 2 \
    --quiet \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --minseqlength accepts longer sequences (>)"
TMP=$(mktemp)
printf ">s\nAAA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 1 \
    --quiet \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --minseqlength accepts longer sequences (--log)"
TMP=$(mktemp)
printf ">s\nAA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 1 \
    --log /dev/null \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --minseqlength discards short sequences (--log)"
TMP=$(mktemp)
printf ">s\nAA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 3 \
    --log /dev/null \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --minseqlength must be an integer"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength A \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --minseqlength must be a positive integer"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength -1 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## missing check in vsearch code!
# DESCRIPTION="--derep_smallmem --minseqlength must be greater than zero"
# TMP=$(mktemp)
# printf ">s\nA\n" > ${TMP}
# "${VSEARCH}" \
#     --derep_smallmem ${TMP} \
#     --minseqlength 0 \
#     --quiet \
#     --fastaout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"
# rm -f ${TMP}
# unset TMP

# combine min/maxseqlength (normal, equal, swapped)
DESCRIPTION="--derep_smallmem --minseqlength --maxseqlength (normal usage)"
TMP=$(mktemp)
printf ">s\nAA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 1 \
    --maxseqlength 2 \
    --quiet \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --minseqlength --maxseqlength (equal)"
TMP=$(mktemp)
printf ">s\nAA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 2 \
    --maxseqlength 2 \
    --quiet \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --minseqlength --maxseqlength (swapped threshold)"
TMP=$(mktemp)
printf ">s\nAA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --minseqlength 2 \
    --maxseqlength 1 \
    --quiet \
    --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--derep_smallmem --no_progress is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --no_progress \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## note: progress is not written to the log file
DESCRIPTION="--derep_smallmem --no_progress removes progressive report on stderr (no visible effect)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --no_progress \
    --fastaout /dev/null 2>&1 | \
    grep -iq "^dereplicating" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--derep_smallmem --notrunclabels is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --notrunclabels \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --notrunclabels preserves full headers"
TMP=$(mktemp)
printf ">s extra\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --notrunclabels \
    --fastaout - | \
    grep -wq ">s extra" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--derep_smallmem --quiet is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --quiet eliminates all (normal) messages to stderr"
TMP=$(mktemp)
printf ">s extra\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --quiet allows error messages to be sent to stderr"
TMP=$(mktemp)
printf ">s extra\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --quiet2 \
    --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## -------------------------------------------------------------------- relabel

DESCRIPTION="--derep_smallmem --relabel is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel renames sequence (label + ticker)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --fastaout - | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel renames sequence (empty label, only ticker)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "" \
    --fastaout - | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel cannot combine with --relabel_md5"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --relabel_md5 \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel cannot combine with --relabel_sha1"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --relabel_sha1 \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--derep_smallmem --relabel_keep is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --relabel_keep \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_keep renames and keeps original sequence name"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --relabel_keep \
    --fastaout - | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--derep_smallmem --relabel_md5 is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_md5 \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_md5 relabels using MD5 hash of sequence"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_md5 \
    --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--derep_smallmem --relabel_self is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_self \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_self relabels using sequence as label"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_self \
    --fastaout - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--derep_smallmem --relabel_sha1 is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_sha1 \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_sha1 relabels using SHA1 hash of sequence"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_sha1 \
    --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## --------------------------------------------------------------------- sample

DESCRIPTION="--derep_smallmem --sample is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --sample "ABC" \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --sample adds sample name to sequence headers"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --sample "ABC" \
    --fastaout - | \
    grep -qw ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## -------------------------------------------------------------------- sizeout

# When using --relabel, --relabel_self, --relabel_md5 or --relabel_sha1,
# preserve and report abundance annotations to the output fasta file
# (using the pattern ';size=integer;').

DESCRIPTION="--derep_smallmem --sizeout is accepted (no size)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --sizeout \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --sizeout is accepted (with size)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --sizeout \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --sizeout missing size annotations are not added (no size)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# without sizein, annotations are discarded, and replaced with dereplication results
DESCRIPTION="--derep_smallmem size annotations are replaced (without sizein, with sizeout)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --sizeout \
    --fastaout - | \
    grep -qw ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem size annotations are replaced (with sizein and sizeout)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --sizeout \
    --fastaout - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem size annotations are left untouched (without sizein and sizeout)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastaout - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## add abundance annotations
DESCRIPTION="--derep_smallmem --relabel no size annotations (without --sizeout)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --fastaout - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel --sizeout adds size annotations"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --sizeout \
    --fastaout - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_self no size annotations (without --sizeout)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_self \
    --fastaout - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_self --sizeout adds size annotations"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_self \
    --sizeout \
    --fastaout - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_md5 no size annotations (without --sizeout)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_md5 \
    --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_md5 --sizeout adds size annotations"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_md5 \
    --sizeout \
    --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_sha1 no size annotations (without --sizeout)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_sha1 \
    --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_sha1 --sizeout adds size annotations"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_sha1 \
    --sizeout \
    --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## preserve abundance annotations
DESCRIPTION="--derep_smallmem --relabel no size annotations (without --sizeout)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --fastaout - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel --sizeout updates size annotations (without sizein)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel "label" \
    --sizeout \
    --fastaout - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel --sizeout updates size annotations (with sizein)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --relabel "label" \
    --sizeout \
    --fastaout - | \
    grep -qw ">label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_self no size annotations (without --sizeout)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_self \
    --fastaout - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_self --sizeout updates size annotations (without sizein)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_self \
    --sizeout \
    --fastaout - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_self --sizeout preserves size annotations (with sizein)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --relabel_self \
    --sizeout \
    --fastaout - | \
    grep -qw ">A;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_md5 no size annotations (without --sizeout)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_md5 \
    --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_md5 --sizeout updates size annotations"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_md5 \
    --sizeout \
    --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_md5 --sizeout preserves size annotations (with sizein)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --relabel_md5 \
    --sizeout \
    --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_sha1 no size annotations (without --sizeout)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_sha1 \
    --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_sha1 --sizeout updates size annotations"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --relabel_sha1 \
    --sizeout \
    --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --relabel_sha1 --sizeout preserves size annotations (with sizein)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --quiet \
    --relabel_sha1 \
    --sizeout \
    --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## -------------------------------------------------------------------- threads

DESCRIPTION="--derep_smallmem --threads is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --threads 1 \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --threads > 1 triggers a warning (not multithreaded)"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --threads 2 \
    --quiet \
    --fastaout /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ------------------------------------------------------------------------ xee

DESCRIPTION="--derep_smallmem --xee is accepted"
TMP=$(mktemp)
printf ">s;ee=1.00\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xee \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --xee removes expected error annotations from input"
TMP=$(mktemp)
printf ">s;ee=1.00\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xee \
    --quiet \
    --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## -------------------------------------------------------------------- xlength

DESCRIPTION="--derep_smallmem --xlength is accepted"
TMP=$(mktemp)
printf ">s;length=1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xlength \
    --quiet \
    --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --xlength removes length annotations from input"
TMP=$(mktemp)
printf ">s;length=1\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xlength \
    --quiet \
    --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --xlength accepts input without length annotations"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xlength \
    --quiet \
    --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_smallmem --xlength removes length annotations (input), lengthout adds them (output)"
TMP=$(mktemp)
printf ">s;length=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xlength \
    --lengthout \
    --quiet \
    --fastaout - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

## ---------------------------------------------------------------------- xsize

## --xsize is accepted
DESCRIPTION="--xsize is accepted"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xsize \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize strips abundance values"
TMP=$(mktemp)
printf ">s;size=1;\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizein \
    --xsize \
    --quiet \
    --fastaout - | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize strips abundance values (without --sizein)"
TMP=$(mktemp)
printf ">s;size=1;\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xsize \
    --quiet \
    --fastaout - | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# xsize + sizein + sizeout + relabel_keep: ?
DESCRIPTION="--xsize + sizeout (new size)"
TMP=$(mktemp)
printf ">s;size=2;\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xsize \
    --quiet \
    --sizeout \
    --fastaout - | \
    grep -wq ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize + sizein (no size)"
TMP=$(mktemp)
printf ">s;size=2;\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizeout \
    --xsize \
    --quiet \
    --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize + sizein + sizeout (new size)"
TMP=$(mktemp)
printf ">s;size=2;\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --sizeout \
    --xsize \
    --quiet \
    --fastaout - | \
    grep -wq ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize + sizein + sizeout + relabel_keep (keep old size)"
TMP=$(mktemp)
printf ">s;size=2;\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --relabel_keep \
    --sizein \
    --xsize \
    --quiet \
    --sizeout \
    --fastaout - | \
    grep -wq ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# xsize + sizein + sizeout + notrunclabels: ?
DESCRIPTION="sizeout + notrunclabels (trim and reinsert new size at the end)"
TMP=$(mktemp)
printf ">s;size=2; extra\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --notrunclabels \
    --quiet \
    --sizeout \
    --fastaout - | \
    grep -wq ">s; extra;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="sizein + sizeout + notrunclabels (trim and reinsert old size at the end)"
TMP=$(mktemp)
printf ">s;size=2; extra\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --notrunclabels \
    --quiet \
    --sizein \
    --sizeout \
    --fastaout - | \
    grep -wq ">s; extra;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize + sizein + sizeout + notrunclabels (trim and reinsert old size at the end)"
TMP=$(mktemp)
printf ">s;size=2; extra\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --notrunclabels \
    --quiet \
    --xsize \
    --sizein \
    --sizeout \
    --fastaout - | \
    grep -wq ">s; extra;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize + notrunclabels (without space, no final ;)"
TMP=$(mktemp)
printf ">s;size=2\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xsize \
    --notrunclabels \
    --quiet \
    --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize + notrunclabels (without space, final ;)"
TMP=$(mktemp)
printf ">s;size=2;\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xsize \
    --notrunclabels \
    --quiet \
    --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize + notrunclabels (with space and final ;)"
TMP=$(mktemp)
printf ">s;size=2; \nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xsize \
    --notrunclabels \
    --quiet \
    --fastaout - | \
    grep -wq ">s; " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--xsize + notrunclabels (with space and no final ;)"
TMP=$(mktemp)
printf ">s;size=2 \nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xsize \
    --notrunclabels \
    --quiet \
    --fastaout - | \
    grep -wq ">s;size=2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

# vsearch truncates removes annotations, but keeps dangling ";" 
DESCRIPTION="--xsize + notrunclabels (no size, no space, and final ;)"
TMP=$(mktemp)
printf ">s;\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --xsize \
    --notrunclabels \
    --quiet \
    --fastaout - | \
    grep -wq ">s;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_asciiout is rejected"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_asciiout 33 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--fastq_qmaxout is rejected"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qmaxout 41 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--fastq_qminout is rejected"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qminout 10 \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--fastq_qout_max is rejected"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --fastq_qout_max \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--fastqout is rejected"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--output is rejected"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--tabbedout is rejected"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --tabbedout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--uc is rejected"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --uc /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--topn is rejected"
TMP=$(mktemp)
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --derep_smallmem ${TMP} \
    --quiet \
    --topn 1 \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm -f ${TMP}
unset TMP


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then
    TMP=$(mktemp)
    INPUT=$(mktemp)
    printf ">s1\nA\n>s2\nA\n" > ${INPUT}
    valgrind \
        --log-file=${TMP} \
        --leak-check=full \
        "${VSEARCH}" \
        --derep_smallmem ${INPUT} \
        --strand both \
        --log /dev/null \
        --fastaout /dev/null 2> /dev/null
    DESCRIPTION="--derep_smallmem valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" ${TMP} && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--derep_smallmem valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" ${TMP} && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f ${TMP} ${INPUT}
    unset TMP INPUT
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#

# Risk of hash collision: it is not verified that grouped sequences
# are identical, however the probability that two different sequences
# are grouped in a dataset of 1 000 000 000 unique sequences is
# approximately 1e-21. Memory footprint is appr. 24 bytes times the
# number of unique sequence.

## TODO:
# - missing checks in vsearch code (min/max mismatches)

exit 0

