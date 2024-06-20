#!/bin/bash -

## Print a header
SCRIPT_NAME="derep_prefix"
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

## ---------------------------- command --derep_prefix and mandatory output

## --derep_prefix is accepted
DESCRIPTION="--derep_prefix is accepted"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## missing check!
# ## --derep_prefix requires --output
# DESCRIPTION="--derep_prefix requires --output"
# printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
#     "${VSEARCH}" \
#         --derep_prefix - \
#         2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--derep_prefix accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## missing check for fastq input
# DESCRIPTION="--derep_prefix rejects fastq input"
# printf "@s\nA\n+\nI\n" | \
#     "${VSEARCH}" \
#         --derep_prefix - \
#         --output /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
#         success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix rejects non-fasta input (#1)"
printf "\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix rejects non-fasta input (#2)"
printf "\n>s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output /dev/null 2> /dev/null  && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix accepts a single fasta entry"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# discard entries shorter than 32 nucleotides by default
DESCRIPTION="--derep_prefix discards a short fasta entry"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output - 2> /dev/null | \
    grep -qw ">s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix discards an empty fasta entry"
printf ">s\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output - 2> /dev/null | \
    grep -qw ">s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# attempt to trigger a special case of seqcmp()
DESCRIPTION="--derep_prefix compare two empty fasta entries"
printf ">s1\n>s2\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# attempt to trigger a special case of seqcmp()
DESCRIPTION="--derep_prefix compare two fasta entries (one is empty)"
printf ">s1\nA\n>s2\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------- options for simpler tests: --quiet and --minseqlength

DESCRIPTION="--derep_prefix outputs stderr messages"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --quiet removes stderr messages"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --minseqlength 1 (keep very short fasta entries)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# keep empty fasta entries
DESCRIPTION="--derep_prefix --minseqlength 0 (keep empty fasta entries)"
printf ">s\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 0 \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------- test general behaviour

## --derep_prefix outputs data
DESCRIPTION="--derep_prefix outputs data"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --quiet \
        --minseqlength 1 \
        --output - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --derep_prefix outputs expected results
DESCRIPTION="--derep_prefix outputs expected results (in fasta format)"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix merges prefixes"
printf ">s1\nAC\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1@AC@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix merges prefixes (negative case)"
printf ">s1\nAC\n>s2\nC\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1@AC@>s2@C@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix merges prefixes with the shortest parent"
printf ">s1\nACG\n>s2\nAG\n>s3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s2;size=2@AG@>s1;size=1@ACG@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix merges prefixes with the shortest parent (different order)"
printf ">s1\nAG\n>s2\nACG\n>s3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@AG@>s2;size=1@ACG@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix merges with the most abundant if equally long"
printf ">s1;size=2\nAC\n>s2;size=1\nAG\n>s3;size=1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --sizeout \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=3@AC@>s2;size=1@AG@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix merges with the most abundant if equally long (different order)"
printf ">s1;size=1\nAC\n>s2;size=2\nAG\n>s3;size=1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --sizeout \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s2;size=3@AG@>s1;size=1@AC@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix uses sequence headers to break ties"
printf ">s1\nAC\n>s2\nAG\n>s3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@AC@>s2;size=1@AG@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix uses sequence headers to break ties (different order)"
printf ">s2\nAC\n>s1\nAG\n>s3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@AG@>s2;size=1@AC@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix uses sequence input order to break ties"
printf ">s\nAC\n>s\nAG\n>s3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s;size=2@AC@>s;size=1@AG@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix uses sequence input order to break ties (different order)"
printf ">s\nAG\n>s\nAC\n>s3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s;size=2@AG@>s;size=1@AC@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_prefix takes terminal gaps into account (substring are merged)
DESCRIPTION="--derep_prefix ignores terminal gaps"
printf ">s1\nAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix sequences are sorted by decreasing abundance"
printf ">s1;size=1\nA\n>s2;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s2;size=2@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_prefix replicate sequences are sorted by
## alphabetical order of headers. Identical sequences receive the
## header of the first sequence of their group (s1 before s2)
DESCRIPTION="--derep_prefix identical seqs receive the header of the first seq of the group"
printf ">s2\nA\n>s1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_prefix distinct sequences are sorted by
## alphabetical order of headers (s1 before s2)
DESCRIPTION="--derep_prefix distinct sequences are sorted by header alphabetical order"
printf ">s2\nA\n>s1\nG\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@G@>s2@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_prefix distinct sequences are not sorted by
## alphabetical order of DNA strings (G before A)
DESCRIPTION="--derep_prefix distinct sequences are not sorted by DNA alphabetical order"
printf ">s2\nA\n>s1\nG\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@G@>s2@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# sort by decreasing abundance: s1 > s2 and s2 > s1
DESCRIPTION="--derep_prefix sort clusters by decreasing abundance (natural order)"
printf ">s1;size=3\nA\n>s2;size=1\nC\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=3@A@>s2;size=1@C@$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix sort clusters by decreasing abundance (reversed input order)"
printf ">s1;size=1\nA\n>s2;size=3\nC\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s2;size=3@C@>s1;size=1@A@$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# same abundance, compare headers: s1 > s2 and s2 > s1
DESCRIPTION="--derep_prefix then sort clusters by comparing headers (natural order)"
printf ">s1;size=2\nA\n>s2;size=2\nC\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@A@>s2;size=2@C@$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix then sort clusters by comparing headers (reversed input order)"
printf ">s2;size=2\nA\n>s1;size=2\nC\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@C@>s2;size=2@A@$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# same abundance, same headers, compare input order: s1 > s2 and s2 > s1
DESCRIPTION="--derep_prefix then sort clusters by input order (natural order)"
printf ">s1;size=2\nC\n>s1;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@C@>s1;size=2@A@$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix then sort clusters by input order (reversed input order)"
printf ">s1;size=2\nA\n>s1;size=2\nC\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@A@>s1;size=2@C@$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --derep_prefix sequence comparison is case insensitive
DESCRIPTION="--derep_prefix sequence comparison is case insensitive"
printf ">s1\nA\n>s2\na\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_prefix preserves the case of the first occurrence of each sequence
DESCRIPTION="--derep_prefix preserves the case of the first occurrence of each sequence"
printf ">s1\na\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@a@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_prefix T and U are considered the same
DESCRIPTION="--derep_prefix T and U are considered the same"
printf ">s1\nT\n>s2\nU\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@T@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_prefix does not replace U with T in its output
DESCRIPTION="--derep_prefix does not replace U with T in its output"
printf ">s1\nU\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@U@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_prefix accepts more than 1,024 unique sequences
## (trigger reallocation)
DESCRIPTION="--derep_prefix accepts more than 1,024 unique sequences"
(for i in {1..1025} ; do
    printf ">s%d\n" ${i}
    yes A | head -n ${i}
 done) | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------- maxuniquesize

# maximum abundance for output from dereplication

DESCRIPTION="--maxuniquesize is accepted"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 2 \
        --quiet \
        --output /dev/null > /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts lesser dereplicated sizes (<)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts equal dereplicated sizes (=)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize rejects greater dereplicated sizes (>)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize must be an integer (not a double)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 1.0 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize must be an integer (not a char)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize A \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize must be a positive integer"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize -1 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize must be greater than zero"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 0 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts a value of 1 (no dereplication)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 1 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts large values (2^8)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 256 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts large values (2^16)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 65536 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts large values (2^32)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 4294967296 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts large values (2^32)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 4294967296 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# combine with sizein
DESCRIPTION="--maxuniquesize --sizein accepts lesser dereplicated sizes (<)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --maxuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize --sizein accepts equal dereplicated sizes (=)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --maxuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize --sizein rejects greater dereplicated sizes (>)"
printf ">s;size=3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --maxuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize restricts number of clusters (without --quiet)"
printf ">s1\nA\n>s2\nA\n>s3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 2 \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize restricts number of clusters (with --log)"
printf ">s1\nA\n>s2\nA\n>s3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxuniquesize 2 \
        --log /dev/null \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## -------------------------------------------------------------- minuniquesize

# minimum abundance for output from dereplication

DESCRIPTION="--minuniquesize is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 1 \
        --quiet \
        --output /dev/null > /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize rejects lesser dereplicated sizes (<)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts equal dereplicated sizes (=)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts greater dereplicated sizes (>)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize must be an integer (not a double)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 1.0 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize must be an integer (not a char)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize A \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize must be a positive integer"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize -1 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize must be greater than zero"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 0 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts a value of 1"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 1 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts large values (2^8)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 256 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts large values (2^16)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 65536 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts large values (2^32)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 4294967296 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts large values (2^32)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 4294967296 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# combine with sizein
DESCRIPTION="--minuniquesize --sizein rejects lesser dereplicated sizes (<)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --minuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize --sizein accepts equal dereplicated sizes (=)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --minuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize --sizein accepts greater dereplicated sizes (>)"
printf ">s;size=3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --minuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# combine min-max? normal, same, inverted
DESCRIPTION="--minuniquesize --maxuniquesize accepts dereplicated sizes (normal usage)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 2 \
        --maxuniquesize 4 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize --maxuniquesize accepts dereplicated sizes (same threshold)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 3 \
        --maxuniquesize 3 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# should warn that minuniquesize > maxuniquesize (output always empty)?
DESCRIPTION="--minuniquesize --maxuniquesize rejects dereplicated sizes (swapped threshold)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 3 \
        --maxuniquesize 2 \
        --quiet \
        --output - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize restricts number of clusters (without --quiet)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 2 \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize restricts number of clusters (with --log)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --minuniquesize 2 \
        --log /dev/null \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--sizein is accepted (no size annotation)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sizein is accepted (size annotation)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sizein (no size in, no size out)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sizein --sizeout assumes size=1 (no size annotation)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --sizeout \
        --output - | \
    grep -qw ">s;size=1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sizein propagates size annotations (sizeout is implied)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--derep_prefix --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --derep_prefix - \
        --bzip2_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix rejects compressed stdin (bzip2)"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --derep_prefix - \
        --bzip2_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --bzip2_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --derep_prefix - \
        --bzip2_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --bzip2_decompress rejects uncompressed stdin"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --bzip2_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------------------------------------------------------------- fasta_width

# Fasta files produced by vsearch are wrapped (sequences are written on
# lines of integer nucleotides, 80 by default). Set the value to zero to
# eliminate the wrapping.

DESCRIPTION="--derep_prefix --fasta_width is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --fasta_width 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# 80 nucleotides, expect 2 lines (header + one sequence line)
DESCRIPTION="--derep_prefix fasta output is not wrapped (80 nucleotides or less)"
printf ">s\n%080s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --quiet \
        --output - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 81 nucleotides, expect 3 lines
DESCRIPTION="--derep_prefix fasta output is wrapped (81 nucleotides or more)"
printf ">s\n%081s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --quiet \
        --output - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --fasta_width is accepted (empty input)"
printf "" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --fasta_width 80 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --fasta_width 2^32 is accepted"
printf ">s\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --fasta_width $(( 2 ** 32 )) \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 2 nucleotides, expect 3 lines
DESCRIPTION="--derep_prefix --fasta_width 1 (1 nucleotide per line)"
printf ">s\nTT\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 2 \
        --fasta_width 1 \
        --quiet \
        --output - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expect 81 nucleotides on the second line
DESCRIPTION="--derep_prefix --fasta_width 0 (no wrapping)"
printf ">s\n%081s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --fasta_width 0 \
        --quiet \
        --output - | \
    awk 'NR == 2 {exit length($1) == 81 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--derep_prefix --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --derep_prefix - \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix rejects compressed stdin (gzip)"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --derep_prefix - \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --gzip_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --derep_prefix - \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# more flexible than bzip2
DESCRIPTION="--derep_prefix --gzip_decompress accepts uncompressed stdin"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix rejects --bzip2_decompress + --gzip_decompress"
printf "" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --bzip2_decompress \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--derep_prefix --label_suffix is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --quiet \
        --label_suffix "suffix" \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --label_suffix adds suffix (fasta in, fasta out)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --quiet \
        --label_suffix ";suffix" \
        --fastaout - | \
    grep -qw ">s;suffix" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --label_suffix adds suffix (empty suffix string)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --quiet \
        --label_suffix "" \
        --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--derep_prefix --lengthout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --lengthout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --lengthout adds length annotations to output"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --lengthout \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# lengthout + sizeout? is the order relevant?
DESCRIPTION="--derep_prefix --lengthout --sizeout add annotations to output (size first)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --lengthout \
        --sizeout \
        --output - | \
    grep -wq ">s;size=1;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--derep_prefix --log is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --log /dev/null \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --log writes to a file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output /dev/null \
        --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --log does not prevent messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --output /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix accepts empty input (0 unique sequences)"
printf "" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --output /dev/null \
        --log - 2> /dev/null | \
    grep -q "0 unique sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- maxseqlength

DESCRIPTION="--derep_prefix --maxseqlength is accepted"
printf ">s\n%081s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --maxseqlength 81 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --maxseqlength accepts shorter lengths (<)"
printf ">s\n%080s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --maxseqlength 81 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --maxseqlength accepts equal lengths (=)"
printf ">s\n%081s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --maxseqlength 81 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--derep_prefix --maxseqlength rejects longer sequences (>)"
printf ">s\n%082s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --maxseqlength 81 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --maxseqlength accepts shorter lengths (--log)"
printf ">s\n%080s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --maxseqlength 81 \
        --log /dev/null \
        --output - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --maxseqlength discards longer lengths (--log)"
printf ">s\n%080s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --maxseqlength 79 \
        --log /dev/null \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --maxseqlength must be an integer"
printf ">s\n%081s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --maxseqlength A \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# ## missing check in vsearch code!
# DESCRIPTION="--derep_prefix --maxseqlength must be a positive integer"
# printf ">s\n%081s\n" | tr " " "A" | \
#     "${VSEARCH}" \
#         --derep_prefix - \
#         --maxseqlength -1 \
#         --quiet \
#         --output /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

# ## missing check in vsearch code! 
# DESCRIPTION="--derep_prefix --maxseqlength must be greater than zero"
# printf ">s\n%081s\n" | tr " " "A" | \
#     "${VSEARCH}" \
#         --derep_prefix - \
#         --maxseqlength 0 \
#         --quiet \
#         --output /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

## --------------------------------------------------------------- minseqlength

DESCRIPTION="--derep_prefix --minseqlength is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--derep_prefix --minseqlength rejects shorter sequences (<)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --minseqlength accepts equal lengths (=)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --minseqlength accepts longer sequences (>)"
printf ">s\nAAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --minseqlength accepts longer sequences (--log)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --log /dev/null \
        --output - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --minseqlength discards short sequences (--log)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 3 \
        --log /dev/null \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --minseqlength must be an integer"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength A \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --minseqlength must be a positive integer"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength -1 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# ## missing check in vsearch code!
# DESCRIPTION="--derep_prefix --minseqlength must be greater than zero"
# printf ">s\nA\n" | \
#     "${VSEARCH}" \
#         --derep_prefix - \
#         --minseqlength 0 \
#         --quiet \
#         --output /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

# combine min/maxseqlength (normal, equal, swapped)
DESCRIPTION="--derep_prefix --minseqlength --maxseqlength (normal usage)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --maxseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --minseqlength --maxseqlength (equal)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 2 \
        --maxseqlength 2 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --minseqlength --maxseqlength (swapped threshold)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 2 \
        --maxseqlength 1 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--derep_prefix --no_progress is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --no_progress \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--derep_prefix --no_progress removes progressive report on stderr (no visible effect)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --no_progress \
        --output /dev/null 2>&1 | \
    grep -iq "^sorting" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--derep_prefix --notrunclabels is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --notrunclabels \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --notrunclabels preserves full headers"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --notrunclabels \
        --output - | \
    grep -wq ">s extra" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--derep_prefix --quiet is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --quiet eliminates all (normal) messages to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --quiet allows error messages to be sent to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --quiet2 \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--derep_prefix --relabel is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel renames sequence (label + ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel renames sequence (empty label, only ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "" \
        --output - | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel cannot combine with --relabel_md5"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --relabel_md5 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel cannot combine with --relabel_sha1"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --relabel_sha1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--derep_prefix --relabel_keep is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_keep renames and keeps original sequence name"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output - | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--derep_prefix --relabel_md5 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_md5 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_md5 relabels using MD5 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--derep_prefix --relabel_self is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_self \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_self relabels using sequence as label"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--derep_prefix --relabel_sha1 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_sha1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_sha1 relabels using SHA1 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--derep_prefix --sample is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sample "ABC" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --sample adds sample name to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sample "ABC" \
        --output - | \
    grep -qw ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

# When using --relabel, --relabel_self, --relabel_md5 or --relabel_sha1,
# preserve and report abundance annotations to the output fasta file
# (using the pattern ';size=integer;').

DESCRIPTION="--derep_prefix --sizeout is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --sizeout is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --sizeout missing size annotations are not added (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# without sizein, annotations are discarded, and replaced with dereplication results
DESCRIPTION="--derep_prefix size annotations are replaced (without sizein, with sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    grep -qw ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix size annotations are replaced (with sizein and sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --sizeout \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix size annotations are left untouched (without sizein and sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## add abundance annotations
DESCRIPTION="--derep_prefix --relabel no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_self no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_self --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_md5 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_md5 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_sha1 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_sha1 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## preserve abundance annotations
DESCRIPTION="--derep_prefix --relabel no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel --sizeout updates size annotations (without sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel --sizeout updates size annotations (with sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_self no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_self --sizeout updates size annotations (without sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_self --sizeout preserves size annotations (with sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_md5 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_md5 --sizeout updates size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_md5 --sizeout preserves size annotations (with sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_sha1 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_sha1 --sizeout updates size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --relabel_sha1 --sizeout preserves size annotations (with sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--derep_prefix --threads is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --threads 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --threads > 1 triggers a warning (not multithreaded)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --threads 2 \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------------- topn

## --topn is accepted
DESCRIPTION="--topn is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --topn 1 \
        --output /dev/null 2> /dev/null &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn keeps only n sequences
DESCRIPTION="--topn keeps only n sequences"
printf ">s1\nA\n>s2\nG\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --topn 1 \
        --output - | \
    awk '/^>/ {c += 1} END {exit c == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn returns only the n most abundant sequences (s2 in this example)
DESCRIPTION="--topn returns only the n most abundant sequences"
printf ">s1;size=1;\nA\n>s2;size=2;\nC\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --topn 1 \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s2;size=2;@C@$" &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--topn returns the n most abundant sequences after full-length dereplication"
printf ">s1;size=1;\nA\n>s2;size=2;\nC\n>s3;size=2;\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --sizeout \
        --quiet \
        --topn 1 \
        --output - | \
    tr "\n" "@" | \
    grep -qE "^>s3;size=3;?@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn fails with negative arguments
DESCRIPTION="--topn fails with negative arguments"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --topn "-1" \
        --output /dev/null 2> /dev/null &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn zero should return no sequence or fail (only values > 0
## should be accepted)
DESCRIPTION="--topn zero should return no sequence (or fail)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --topn 0 \
        --quiet \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --topn fails with non-numerical argument
DESCRIPTION="--topn fails with non-numerical argument"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --topn A \
        --output /dev/null 2> /dev/null &&\
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --topn accepts abundance values equal to 2^32
DESCRIPTION="--topn accepts abundance values equal to 2^32"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --topn $(( 2 ** 32 )) \
        --output /dev/null 2> /dev/null &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------------------------------------------------------------- uc

# Ten tab-separated columns.
# Column content varies with the type of entry (S, H or C):
# 1. Record type: S, H, or C.
# 2. Cluster number (zero-based).
# 3. Sequence length (S, H), or cluster size (C).
# 4. % of similarity with the centroid sequence (H), or set to ’*’ (S, C).
# 5. Match orientation + or - (H), or set to ’*’ (S, C).
# 6. Not used, always set to ’*’ (S, C) or 0 (H).
# 7. Not used, always set to ’*’ (S, C) or 0 (H).
# 8. Not used, always set to ’*’.
# 9. Label of the query sequence (H), or of the centroid sequence (S, C).
# 10. Label of the centroid sequence (H), or set to ’*’ (S, C).

## --uc is accepted
DESCRIPTION="--uc is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --uc /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix fails if unable to open uc file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --uc ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

## --uc fails if no output redirection is given (filename, device or -)
DESCRIPTION="--uc fails if no output redirection is given"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --uc &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc outputs data
DESCRIPTION="--uc outputs data"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns a tab-delimited table with 10 fields
DESCRIPTION="--uc returns a tab-delimited table with 10 fields"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk 'NF != 10 {c += 1} END {exit c == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns only lines starting with S, C or H
DESCRIPTION="--uc returns only lines starting with S, C or H"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    grep -q "^[^HCS]" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc returns a S line (centroid) and a C lines (cluster) for each input sequence
DESCRIPTION="--uc returns a S line (centroid) and a C lines (cluster) for each sequence"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '{if (/^S/) {s += 1} ; if (/^C/) {c += 1}}
         END {exit NR == 2 && c == 1 && s == 1 ? 0 : 1}' && \
             success "${DESCRIPTION}" || \
                 failure "${DESCRIPTION}"

## --uc returns no H line (first column) when there is no hit
DESCRIPTION="--uc returns no H line when there is no hit"
printf ">a\nA\n>b\nG\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc returns a H line (first column) when there is a hit
DESCRIPTION="--uc returns a H line when there is a hit"
printf ">a\nA\n>b\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns the expected number of S lines (two centroids)
DESCRIPTION="--uc returns the expected number of S lines (centroids)"
printf ">s1\nA\n>s2\nA\n>s3\nG\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '/^S/ {c += 1} END {exit c == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns the expected number of C lines (two clusters)
DESCRIPTION="--uc returns the expected number of C lines (clusters)"
printf ">s1\nA\n>s2\nA\n>s3\nG\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '/^C/ {c += 1} END {exit c == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc cluster numbering is zero-based (first cluster is number zero)
DESCRIPTION="--uc cluster numbering is zero-based (2nd column = 0)"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '$2 != 0 {c += 1} END {exit c > 0 ? 1 : 0}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc cluster numbering is zero-based: with two clusters, the
## highest cluster number (n) is 1, for any line
DESCRIPTION="--uc cluster numbering is zero-based (2nd cluster, 2nd column = 1)"
printf ">s1\nG\n>s2\nA\n>s3\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '$2 > n {n = $2} END {exit n == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc cluster size is correct for C line (3rd column)
DESCRIPTION="--uc cluster size is correct for C line (3rd column)"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '/^C/ {exit $3 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid length is correct for S line (3rd column)
DESCRIPTION="--uc centroid length is correct for S line (3rd column) #1"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '/^S/ {exit $3 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid length is correct for S line (3rd column)
DESCRIPTION="--uc centroid length is correct for S line (3rd column) #2"
printf ">s1\nAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '/^S/ {exit $3 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc hit length is correct in (H line, 3rd column)
DESCRIPTION="--uc hit length is correct in (H line, 3rd column) #1"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '/^H/ {exit $3 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc hit length is correct in (H line, 3rd column)
DESCRIPTION="--uc hit length is correct in (H line, 3rd column) #2"
printf ">s1\nAA\n>s2\nAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '/^H/ {exit $3 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--derep_prefix --xee is accepted"
printf ">s;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xee \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --xee removes expected error annotations from input"
printf ">s;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xee \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--derep_prefix --xlength is accepted"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xlength \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --xlength removes length annotations from input"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xlength \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --xlength accepts input without length annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xlength \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_prefix --xlength removes length annotations (input), lengthout adds them (output)"
printf ">s;length=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xlength \
        --lengthout \
        --quiet \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

## --xsize is accepted
DESCRIPTION="--xsize is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xsize \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize strips abundance values"
printf ">s;size=1;\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizein \
        --xsize \
        --quiet \
        --output - | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--xsize strips abundance values (without --sizein)"
printf ">s;size=1;\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xsize \
        --quiet \
        --output - | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# xsize + sizein + sizeout + relabel_keep: ?
DESCRIPTION="--xsize + sizeout (new size)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xsize \
        --quiet \
        --sizeout \
        --output - | \
    grep -wq ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + sizein (no size)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizeout \
        --xsize \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + sizein + sizeout (new size)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --sizeout \
        --xsize \
        --quiet \
        --output - | \
    grep -wq ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + sizein + sizeout + relabel_keep (keep old size)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --relabel_keep \
        --sizein \
        --xsize \
        --quiet \
        --sizeout \
        --output - | \
    grep -wq ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# xsize + sizein + sizeout + notrunclabels: ?
DESCRIPTION="sizeout + notrunclabels (trim and reinsert new size at the end)"
printf ">s;size=2; extra\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --notrunclabels \
        --quiet \
        --sizeout \
        --output - | \
    grep -wq ">s; extra;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="sizein + sizeout + notrunclabels (trim and reinsert old size at the end)"
printf ">s;size=2; extra\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --notrunclabels \
        --quiet \
        --sizein \
        --sizeout \
        --output - | \
    grep -wq ">s; extra;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + sizein + sizeout + notrunclabels (trim and reinsert old size at the end)"
printf ">s;size=2; extra\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --notrunclabels \
        --quiet \
        --xsize \
        --sizein \
        --sizeout \
        --output - | \
    grep -wq ">s; extra;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + notrunclabels (without space, no final ;)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xsize \
        --notrunclabels \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + notrunclabels (without space, final ;)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xsize \
        --notrunclabels \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + notrunclabels (with space and final ;)"
printf ">s;size=2; \nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xsize \
        --notrunclabels \
        --quiet \
        --output - | \
    grep -wq ">s; " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + notrunclabels (with space and no final ;)"
printf ">s;size=2 \nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xsize \
        --notrunclabels \
        --quiet \
        --output - | \
    grep -wq ">s;size=2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# vsearch truncates removes annotations, but keeps dangling ";" 
DESCRIPTION="--xsize + notrunclabels (no size, no space, and final ;)"
printf ">s;\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --xsize \
        --notrunclabels \
        --quiet \
        --output - | \
    grep -wq ">s;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--strand is rejected"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --strand both \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


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
        --derep_prefix <(printf ">s1\nA\n>s2\nA\n") \
        --minseqlength 1 \
        --output /dev/null 2> /dev/null
    DESCRIPTION="--derep_prefix valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--derep_prefix valgrind (no errors)"
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

## TODO:
# - missing check for output files (--output and --uc)
# - missing check for fastq input
# - strand is listed as a valid option, but it is not supported by --derep_prefix
# - missing checks in vsearch code (min/max mismatches)


exit 0

