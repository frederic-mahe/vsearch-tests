#!/bin/bash -

## Print a header
SCRIPT_NAME="fastx_uniques"
LINE=$(printf "%76s\n" | tr " " "-")
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

## --fastx_uniques is accepted
DESCRIPTION="--fastx_uniques is accepted"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------- mandatory output file: fastaout or fastqout or tabbedout

DESCRIPTION="--fastx_uniques requires an output file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques requires an output file (fasta in, fastaout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques fails if unable to open output file for writing (fasta in, fastaout)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--fastx_uniques requires an output file (fastq in, fastqout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques fails if unable to open output file for writing (fastq in, fastqout)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastqout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--fastx_uniques requires an output file (fastq in, fastaout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques fails if unable to open output file for writing (fastq in, fastaout)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--fastx_uniques fastqout requires fastq input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques tabbedout requires fastq input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --tabbedout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques requires an output file (fastq in, tabbedout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --tabbedout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques fails if unable to open output file for writing (fastq in, tabbedout)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --tabbedout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--fastx_uniques accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques accepts fastq input"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques rejects non-fasta input (#1)"
printf "\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques rejects non-fasta input (#2)"
printf "\n>s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2> /dev/null  && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques accepts a single fasta entry"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# accept entries shorter than 32 nucleotides by default
DESCRIPTION="--fastx_uniques accepts short fasta entry"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques discards an empty fasta entry"
printf ">s\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# attempt to trigger a special case of seqcmp()
DESCRIPTION="--fastx_uniques compare two empty fasta entries"
printf ">s1\n>s2\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# attempt to trigger a special case of seqcmp()
DESCRIPTION="--fastx_uniques compare two fasta entries (one is empty)"
printf ">s1\nA\n>s2\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------- options for simpler tests: --quiet and --minseqlength

DESCRIPTION="--fastx_uniques outputs stderr messages"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --quiet removes stderr messages"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# keep empty fasta entries
DESCRIPTION="--fastx_uniques --minseqlength 0 (keep empty fasta entries)"
printf ">s\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 0 \
        --quiet \
        --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------- test general behaviour

## --fastx_uniques outputs data
DESCRIPTION="--fastx_uniques outputs data"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastx_uniques outputs expected results
DESCRIPTION="--fastx_uniques outputs expected results (in fasta format)"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --fastx_uniques takes terminal gaps into account (substring aren't merged)
DESCRIPTION="--fastx_uniques takes terminal gaps into account"
printf ">s1\nAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastx_uniques replicate sequences are not sorted by
## alphabetical order of headers. Identical sequences receive the
## header of the first sequence of their group (s2 before s1)
DESCRIPTION="--fastx_uniques identical seqs receive the header of the first seq of the group"
printf ">s2\nA\n>s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s2@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --fastx_uniques distinct sequences are sorted by
## alphabetical order of headers (s1 before s2)
DESCRIPTION="--fastx_uniques distinct sequences are sorted by header alphabetical order"
printf ">s2\nA\n>s1\nG\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@G@>s2@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --fastx_uniques distinct sequences are not sorted by
## alphabetical order of DNA strings (G before A)
DESCRIPTION="--fastx_uniques distinct sequences are not sorted by DNA alphabetical order"
printf ">s2\nA\n>s1\nG\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@G@>s2@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# sort by decreasing abundance: s1 > s2 and s2 > s1
DESCRIPTION="--fastx_uniques sort clusters by decreasing abundance (natural order)"
printf ">s1;size=3\nA\n>s2;size=1\nC\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=3@A@>s2;size=1@C@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques sort clusters by decreasing abundance (reversed input order)"
printf ">s1;size=1\nA\n>s2;size=3\nC\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s2;size=3@C@>s1;size=1@A@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# same abundance, compare headers: s1 > s2 and s2 > s1
DESCRIPTION="--fastx_uniques then sort clusters by comparing headers (natural order)"
printf ">s1;size=2\nA\n>s2;size=2\nC\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@A@>s2;size=2@C@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques then sort clusters by comparing headers (reversed input order)"
printf ">s2;size=2\nA\n>s1;size=2\nC\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@C@>s2;size=2@A@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# same abundance, same headers, compare input order: s1 > s2 and s2 > s1
DESCRIPTION="--fastx_uniques then sort clusters by input order (natural order)"
printf ">s1;size=2\nC\n>s1;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@C@>s1;size=2@A@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques then sort clusters by input order (reversed input order)"
printf ">s1;size=2\nA\n>s1;size=2\nC\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1;size=2@A@>s1;size=2@C@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastx_uniques sequence comparison is case insensitive
DESCRIPTION="--fastx_uniques sequence comparison is case insensitive"
printf ">s1\nA\n>s2\na\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --fastx_uniques preserves the case of the first occurrence of each sequence
DESCRIPTION="--fastx_uniques preserves the case of the first occurrence of each sequence"
printf ">s1\na\n>s2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@a@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --fastx_uniques T and U are considered the same
DESCRIPTION="--fastx_uniques T and U are considered the same"
printf ">s1\nT\n>s2\nU\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@T@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --fastx_uniques does not replace U with T in its output
DESCRIPTION="--fastx_uniques does not replace U with T in its output"
printf ">s1\nU\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s1@U@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --fastx_uniques accepts more than 1,024 unique sequences
## (trigger reallocation)
DESCRIPTION="--fastx_uniques accepts more than 1,024 unique sequences"
(for i in {1..1025} ; do
    printf ">s%d\n" ${i}
    yes A | head -n ${i}
 done) | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------- report average fastq quality values

DESCRIPTION="--fastx_uniques reports average quality score (singleton)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@I@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques reports average quality score (doubleton, same value)"
printf "@s\nA\n+\nI\n@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@I@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques reports average quality score (doubleton, I+J)"
printf "@s\nA\n+\nI\n@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@I@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## average of quality values? no, otherwise it would report 'I'
DESCRIPTION="--fastx_uniques reports average quality score (doubleton, H + J)"
printf "@s\nA\n+\nH\n@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@H@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# average Q20 ('5') + Q30 ('?') = Q22 ('7')
# p = Q20 + Q30  = 10^-2 + 10^-3 = 5.5.10^-3
# Q = -10 log p = 22.596373105 ~ 22.6
# (Q22 < 22.6 < Q23) -> Q22 ('7', conservative rounding or simple truncation)
DESCRIPTION="--fastx_uniques reports average quality score (doubleton, 5 + ?)"
printf "@s\nA\n+\n?\n@s\nA\n+\n5\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@7@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## offset 64, Q22 -> 'V'
DESCRIPTION="--fastx_uniques reports average quality score (doubleton, T + ^, offset 64)"
printf "@s\nA\n+\nT\n@s\nA\n+\n^\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastq_ascii 64 \
        --fastq_asciiout 64 \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@V@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# special case when Q < 2: Q0 ('!') and Q1 ('"')
# average Q1 ('"') + Q1 ('"') = Q1 ('"')
# p = 0.75 + 0.75 = 0.75
# Q = -10 log p ~ 1.25
# (Q1 < 1.25 < Q2) -> Q1 ('"')
# reason: log 1 = 0 and log 0 = -INF
DESCRIPTION="--fastx_uniques reports average quality score (special case for Q < 2)"
printf "@s\nA\n+\n\"\n@s\nA\n+\n\"\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@\"@" && \
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
        --fastx_uniques - \
        --maxuniquesize 2 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts lesser dereplicated sizes (<)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts equal dereplicated sizes (=)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize rejects greater dereplicated sizes (>)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize must be an integer (not a double)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 1.0 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize must be an integer (not a char)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize A \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize must be a positive integer"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize -1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize must be greater than zero"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 0 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts a value of 1 (no dereplication)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 1 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts large values (2^8)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 256 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts large values (2^16)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 65536 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize accepts large values (2^32)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 4294967296 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# combine with sizein
DESCRIPTION="--maxuniquesize --sizein accepts lesser dereplicated sizes (<)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --maxuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize --sizein accepts equal dereplicated sizes (=)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --maxuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize --sizein rejects greater dereplicated sizes (>)"
printf ">s;size=3\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --maxuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize restricts number of clusters (without --quiet)"
printf ">s1\nA\n>s2\nA\n>s3\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 2 \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--maxuniquesize restricts number of clusters (with --log)"
printf ">s1\nA\n>s2\nA\n>s3\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxuniquesize 2 \
        --log /dev/null \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## -------------------------------------------------------------- minuniquesize

# minimum abundance for output from dereplication

DESCRIPTION="--minuniquesize is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize rejects lesser dereplicated sizes (<)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts equal dereplicated sizes (=)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts greater dereplicated sizes (>)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize must be an integer (not a double)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 1.0 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize must be an integer (not a char)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize A \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize must be a positive integer"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize -1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize must be greater than zero"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 0 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts a value of 1"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 1 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts large values (2^8)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 256 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts large values (2^16)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 65536 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize accepts large values (2^32)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 4294967296 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# combine with sizein
DESCRIPTION="--minuniquesize --sizein rejects lesser dereplicated sizes (<)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --minuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize --sizein accepts equal dereplicated sizes (=)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --minuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize --sizein accepts greater dereplicated sizes (>)"
printf ">s;size=3\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --minuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# combine min-max? normal, same, inverted
DESCRIPTION="--minuniquesize --maxuniquesize accepts dereplicated sizes (normal usage)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 2 \
        --maxuniquesize 4 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--minuniquesize --maxuniquesize accepts dereplicated sizes (same threshold)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 3 \
        --maxuniquesize 3 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# should warn that minuniquesize > maxuniquesize (output always empty)?
DESCRIPTION="--minuniquesize --maxuniquesize rejects dereplicated sizes (swapped threshold)"
printf ">s\nA\n>s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 3 \
        --maxuniquesize 2 \
        --quiet \
        --fastaout - | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize restricts number of clusters (without --quiet)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 2 \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--minuniquesize restricts number of clusters (with --log)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minuniquesize 2 \
        --log /dev/null \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------------- strand

## --strand is accepted
DESCRIPTION="--strand is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --strand both \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --strand both allow dereplication of strand plus and minus (--fastx_uniques)
DESCRIPTION="--strand allow dereplication of strand plus and minus (--fastx_uniques)"
printf ">s1;size=1;\nA\n>s2;size=1;\nT\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --sizeout \
        --strand both \
        --quiet \
        --fastaout - | \
    grep -wqE ">s1;size=2;?" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --strand plus does not change default behaviour
DESCRIPTION="--strand plus does not change default behaviour"
printf ">s1;size=1;\nA\n>s2;size=1;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --sizeout \
        --quiet \
        --strand plus \
        --fastaout - | \
    grep -wqE ">s1;size=2;?" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --strand fails if an unknown argument is given
DESCRIPTION="--strand fails if an unknown argument is given"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --strand unknown \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--sizein is accepted (no size annotation)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sizein is accepted (size annotation)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sizein (no size in, no size out)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sizein --sizeout assumes size=1 (no size annotation)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --sizeout \
        --fastaout - | \
    grep -qw ">s;size=1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sizein propagates size annotations (sizeout is implied)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --fastaout - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--fastx_uniques --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --bzip2_decompress \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques rejects compressed stdin (bzip2)"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --bzip2_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --bzip2_decompress \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --bzip2_decompress rejects uncompressed stdin"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --bzip2_decompress \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------------------------------------------------------------- fasta_width

# Fasta files produced by vsearch are wrapped (sequences are written on
# lines of integer nucleotides, 80 by default). Set the value to zero to
# eliminate the wrapping.

DESCRIPTION="--fastx_uniques --fasta_width is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fasta_width 1 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# 80 nucleotides, expect 2 lines (header + one sequence line)
DESCRIPTION="--fastx_uniques fasta output is not wrapped (80 nucleotides or less)"
printf ">s\n%80s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 81 nucleotides, expect 3 lines
DESCRIPTION="--fastx_uniques fasta output is wrapped (81 nucleotides or more)"
printf ">s\n%81s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fasta_width is accepted (empty input)"
printf "" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fasta_width 80 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fasta_width 2^32 is accepted"
printf ">s\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fasta_width $(( 2 ** 32 )) \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 2 nucleotides, expect 3 lines
DESCRIPTION="--fastx_uniques --fasta_width 1 (1 nucleotide per line)"
printf ">s\nTT\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 2 \
        --fasta_width 1 \
        --quiet \
        --fastaout - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expect 81 nucleotides on the second line
DESCRIPTION="--fastx_uniques --fasta_width 0 (no wrapping)"
printf ">s\n%81s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fasta_width 0 \
        --quiet \
        --fastaout - | \
    awk 'NR == 2 {exit length($1) == 81 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--fastx_uniques --fastq_ascii is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_ascii 33 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_ascii 64 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 64 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_ascii values other than 33 and 64 are rejected"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 63 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------- fastq_asciiout

# --fastq_asciiout positive integer
#          When using --fastq_convert, --sff_convert or --fasta2fastq, define the ASCII character number used as the basis for the FASTQ quality score when writing FASTQ output files.  The  default is 33. Only 33 and 64 are valid arguments.

DESCRIPTION="--fastx_uniques --fastq_asciiout is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_asciiout 33 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_asciiout 33 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_asciiout 33 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_asciiout 64 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_asciiout 64 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_asciiout values other than 33 and 64 are rejected"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_asciiout 63 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_asciiout (33 in, 33 out)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --fastq_asciiout 33 \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@I@" &&\
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_asciiout (64 in, 64 out)"
printf "@s\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --fastq_asciiout 33 \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@h@" &&\
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ## no effect?
# DESCRIPTION="--fastx_uniques --fastq_asciiout (33 in, 64 out)"
# printf "@s\nA\n+\nI\n" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --fastq_ascii 33 \
#         --fastq_asciiout 64 \
#         --quiet \
#         --fastqout - | \
#     tr "\n" "@" | \
#     grep -qw "@s@A@+@h@" &&\
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"

# ## no effect?
# DESCRIPTION="--fastx_uniques --fastq_asciiout (64 in, 33 out)"
# printf "@s\nA\n+\nh\n" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --fastq_ascii 64 \
#         --fastq_asciiout 33 \
#         --quiet \
#         --fastqout - | \
#     tr "\n" "@" | \
#     grep -qw "@s@A@+@I@" &&\
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--fastx_uniques --fastq_qmax is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax 41 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmax accepts lower quality values (H = 39)"
printf "@s\nA\n+\nH\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax 40 \
        --quiet \
        --fastqout - | \
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmax accepts equal quality values (I = 40)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax 40 \
        --quiet \
        --fastqout - | \
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_qmax does not reject higher quality values (J = 41)
DESCRIPTION="--fastx_uniques --fastq_qmax is ignored and has no effect"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax 40 \
        --quiet \
        --fastqout - | \
     grep -qw "@s" && \
     success "${DESCRIPTION}" || \
         failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmax must be a positive integer"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax -1 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmax can be set to zero"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax 0 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmax can be set to 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --fastq_qmax 93 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmax cannot be greater than 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --fastq_qmax 94 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmax can be set to 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 64 \
        --fastq_qmax 62 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmax cannot be greater than 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 64 \
        --fastq_qmax 63 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmaxout

DESCRIPTION="--fastx_uniques --fastq_qmaxout is accepted"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmaxout 41 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout caps output quality values at 41 (default)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmaxout 41 \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@J@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ## fastq_qmaxout has no effect!
# DESCRIPTION="--fastx_uniques --fastq_qmaxout caps output quality values at 40"
# printf "@s\nA\n+\nJ\n" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --fastq_qmaxout 40 \
#         --quiet \
#         --fastqout - | \
#     tr "\n" "@" | \
#     grep -qw "@s@A@+@I@" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout must be a positive integer"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmaxout -1 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout can be set to zero"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmaxout 0 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout can be set to 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --fastq_qmaxout 93 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout cannot be greater than 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --fastq_qmaxout 94 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout can be set to 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 64 \
        --fastq_qmaxout 62 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ## missing check in vsearch!
# DESCRIPTION="--fastx_uniques --fastq_qmaxout cannot be greater than 62 (offset 64)"
# printf "@s\nA\n+\nI\n" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --fastq_ascii 64 \
#         --fastq_qmaxout 63 \
#         --quiet \
#         --fastqout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
#         success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout can be greater than fastq_qmax"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax 40 \
        --fastq_qmaxout 41 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout can be smaller than fastq_qmax"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax 40 \
        --fastq_qmaxout 39 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout can be greater than fastq_qmin"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 10 \
        --fastq_qmaxout 11 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmaxout can be smaller than fastq_qmin"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 11 \
        --fastq_qmaxout 10 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--fastx_uniques --fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 0 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmin accepts higher quality values (0 = 15)"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 14 \
        --quiet \
        --fastqout - | \
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmin accepts equal quality values (0 = 15)"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 15 \
        --quiet \
        --fastqout - | \
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_qmin does not reject lower quality values (0 = 15)
DESCRIPTION="--fastx_uniques --fastq_qmin is ignored and has no effect"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 16 \
        --quiet \
        --fastqout - | \
     grep -qw "@s" && \
     success "${DESCRIPTION}" || \
         failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmin must be a positive integer"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin -1 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmin can be set to zero (default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 0 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmin can be lower than fastq_qmax (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 40 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## allows to select only reads with a specific Q value
DESCRIPTION="--fastx_uniques --fastq_qmin can be equal to fastq_qmax (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 41 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qmin cannot be higher than fastq_qmax (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 42 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# but not higher, as it cannot be greater than qmax
DESCRIPTION="--fastx_uniques --fastq_qmin can be set to 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --fastq_qmin 93 \
        --fastq_qmax 93 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# but not higher, as it cannot be greater than qmax
DESCRIPTION="--fastx_uniques --fastq_qmin can be set to 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 64 \
        --fastq_qmin 62 \
        --fastq_qmax 62 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qminout

DESCRIPTION="--fastx_uniques --fastq_qminout is accepted"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qminout 0 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout floors output quality values at 0 (default)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qminout 0 \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@J@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ## fastq_qminout has no effect!
# DESCRIPTION="--fastx_uniques --fastq_qminout floors output quality values at 16 (0 = 15)"
# printf "@s\nA\n+\n0\n" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --fastq_qminout 16 \
#         --quiet \
#         --fastqout - | \
#     tr "\n" "@" | \
#     grep -qw "@s@A@+@I@" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"

## fix: should vsearch accept negative values? 
DESCRIPTION="--fastx_uniques --fastq_qminout must be a positive integer"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qminout -1 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout can be set to zero"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qminout 0 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Fatal error: The argument to --fastq_qminout cannot be larger than --fastq_qmaxout
DESCRIPTION="--fastx_uniques --fastq_qminout can be lower than fastq_qmaxout (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qminout 40 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout can be equal to fastq_qmaxout (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qminout 41 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout cannot be larger than fastq_qmaxout (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qminout 42 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout can be set to 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 33 \
        --fastq_qminout 93 \
        --fastq_qmaxout 93 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout can be set to 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_ascii 64 \
        --fastq_qminout 62 \
        --fastq_qmaxout 62 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## missing check in vsearch!
# DESCRIPTION="--fastx_uniques --fastq_qminout cannot be greater than 62 (offset 64)"
# printf "@s\nA\n+\nI\n" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --fastq_ascii 64 \
#         --fastq_qminout 63 \
#         --fastq_qmaxout 63 \
#         --quiet \
#         --fastqout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
#         success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout can be greater than fastq_qmax"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax 40 \
        --fastq_qminout 41 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout can be smaller than fastq_qmax"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmax 40 \
        --fastq_qminout 39 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout can be greater than fastq_qmin"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 10 \
        --fastq_qminout 11 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qminout can be smaller than fastq_qmin"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qmin 11 \
        --fastq_qminout 10 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- fastq_qout_max

DESCRIPTION="--fastx_uniques --fastq_qout_max is accepted"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qout_max \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qout_max reports highest quality score (singleton)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qout_max \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@I@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qout_max reports highest quality score (doubleton)"
printf "@s\nA\n+\nI\n@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qout_max \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@J@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --fastq_qout_max reports highest quality score (doubleton, different order)"
printf "@s\nA\n+\nJ\n@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qout_max \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@J@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## take into account 'K' (Q42), but limit best value to 'J' Q41?
DESCRIPTION="--fastx_uniques --fastq_qout_max reports highest quality score (cap values at 41 by default)"
printf "@s\nA\n+\nK\n@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastq_qout_max \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qw "@s@A@+@J@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--fastx_uniques --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --gzip_decompress \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques rejects compressed stdin (gzip)"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --gzip_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --gzip_decompress \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# more flexible than bzip2
DESCRIPTION="--fastx_uniques --gzip_decompress accepts uncompressed stdin"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --gzip_decompress \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques rejects --bzip2_decompress + --gzip_decompress"
printf "" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --bzip2_decompress \
        --gzip_decompress \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--fastx_uniques --label_suffix is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --label_suffix "suffix" \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --label_suffix adds suffix (fasta in, fasta out)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --label_suffix ";suffix" \
        --fastaout - | \
    grep -qw ">s;suffix" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --label_suffix adds suffix (fastq in, fasta out)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --label_suffix ";suffix" \
        --fastaout - | \
    grep -qw ">s;suffix" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --label_suffix adds suffix (fastq in, fastq out)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --label_suffix ";suffix" \
        --fastqout - | \
    grep -qw "@s;suffix" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --label_suffix adds suffix (empty suffix string)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --label_suffix "" \
        --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--fastx_uniques --lengthout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --lengthout \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --lengthout adds length annotations to output"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --lengthout \
        --fastaout - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# lengthout + sizeout? is the order relevant?
DESCRIPTION="--fastx_uniques --lengthout --sizeout add annotations to output (size first)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --lengthout \
        --sizeout \
        --fastaout - | \
    grep -wq ">s;size=1;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--fastx_uniques --log is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --log /dev/null \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --log writes to a file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout /dev/null \
        --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --log does not prevent messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques accepts empty input (0 unique sequences)"
printf "" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --fastaout /dev/null \
        --log - 2> /dev/null | \
    grep -q "0 unique sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- maxseqlength

DESCRIPTION="--fastx_uniques --maxseqlength is accepted"
printf ">s\n%81s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxseqlength 81 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --maxseqlength accepts shorter lengths (<)"
printf ">s\n%80s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxseqlength 81 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --maxseqlength accepts equal lengths (=)"
printf ">s\n%81s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxseqlength 81 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--fastx_uniques --maxseqlength rejects longer sequences (>)"
printf ">s\n%82s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxseqlength 81 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --maxseqlength accepts shorter lengths (--log)"
printf ">s\n%80s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxseqlength 81 \
        --log /dev/null \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --maxseqlength discards longer lengths (--log)"
printf ">s\n%80s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxseqlength 79 \
        --log /dev/null \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --maxseqlength must be an integer"
printf ">s\n%81s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --maxseqlength A \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# ## missing check in vsearch code!
# DESCRIPTION="--fastx_uniques --maxseqlength must be a positive integer"
# printf ">s\n%81s\n" | tr " " "A" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --maxseqlength -1 \
#         --quiet \
#         --fastaout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

# ## missing check in vsearch code! 
# DESCRIPTION="--fastx_uniques --maxseqlength must be greater than zero"
# printf ">s\n%81s\n" | tr " " "A" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --maxseqlength 0 \
#         --quiet \
#         --fastaout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

## --------------------------------------------------------------- minseqlength

DESCRIPTION="--fastx_uniques --minseqlength is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# note: the 'sequence discarded' message is not silenced by --quiet
DESCRIPTION="--fastx_uniques --minseqlength rejects shorter sequences (<)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 2 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --minseqlength accepts equal lengths (=)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 2 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --minseqlength accepts longer sequences (>)"
printf ">s\nAAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 1 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --minseqlength accepts longer sequences (--log)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 1 \
        --log /dev/null \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --minseqlength discards short sequences (--log)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 3 \
        --log /dev/null \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --minseqlength must be an integer"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength A \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# ## missing check in vsearch code!
# DESCRIPTION="--fastx_uniques --minseqlength must be a positive integer"
# printf ">s\nA\n" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --minseqlength -1 \
#         --quiet \
#         --fastaout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

# ## missing check in vsearch code!
# DESCRIPTION="--fastx_uniques --minseqlength must be greater than zero"
# printf ">s\nA\n" | \
#     "${VSEARCH}" \
#         --fastx_uniques - \
#         --minseqlength 0 \
#         --quiet \
#         --fastaout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

# combine min/maxseqlength (normal, equal, swapped)
DESCRIPTION="--fastx_uniques --minseqlength --maxseqlength (normal usage)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 1 \
        --maxseqlength 2 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --minseqlength --maxseqlength (equal)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 2 \
        --maxseqlength 2 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --minseqlength --maxseqlength (swapped threshold)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 2 \
        --maxseqlength 1 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--fastx_uniques --no_progress is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --no_progress \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--fastx_uniques --no_progress removes progressive report on stderr (no visible effect)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --no_progress \
        --fastaout /dev/null 2>&1 | \
    grep -iq "^sorting" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--fastx_uniques --notrunclabels is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --notrunclabels \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --notrunclabels preserves full fasta headers"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --notrunclabels \
        --fastaout - | \
    grep -wq ">s extra" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques truncates fastq headers (tab)"
printf "@s header\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    grep -wq "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques truncates fastq headers (tab)"
printf "@s\theader\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    grep -wq "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --notrunclabels preserves full fastq headers (space)"
printf "@s extra\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --notrunclabels \
        --fastqout - | \
    grep -wq "@s extra" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --notrunclabels preserves full fastq headers (space)"
printf "@s\textra\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --notrunclabels \
        --quiet \
        --fastqout - | \
    grep -Ewq "@s[[:blank:]]extra" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# always truncate headers at first "\0" or "\n" or "\r"
DESCRIPTION="--fastx_uniques truncates fastq headers after CR"
printf "@s\rheader\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    grep -q "header" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --notrunclabels truncates fastq headers after CR"
printf "@s\rheader\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --notrunclabels \
        --quiet \
        --fastqout - | \
    grep -q "header" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques truncates fastq headers after NULL char"
printf "@s\0header\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - | \
    grep -q "header" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --notrunclabels truncates fastq headers after NULL char"
printf "@s\0header\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --notrunclabels \
        --quiet \
        --fastqout - | \
    grep -q "header" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ---------------------------------------------------------------------- quiet

DESCRIPTION="--fastx_uniques --quiet is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --quiet eliminates all (normal) messages to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --quiet allows error messages to be sent to stderr"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --quiet2 \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--fastx_uniques --relabel is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel renames sequence (label + ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --fastaout - | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel renames sequence (empty label, only ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "" \
        --fastaout - | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel cannot combine with --relabel_md5"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --relabel_md5 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel cannot combine with --relabel_sha1"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --relabel_sha1 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--fastx_uniques --relabel_keep is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_keep renames and keeps original sequence name"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --fastaout - | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--fastx_uniques --relabel_md5 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_md5 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_md5 relabels using MD5 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_md5 \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--fastx_uniques --relabel_self is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_self \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_self relabels using sequence as label"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_self \
        --fastaout - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--fastx_uniques --relabel_sha1 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_sha1 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_sha1 relabels using SHA1 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_sha1 \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--fastx_uniques --sample is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --sample "ABC" \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --sample adds sample name to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --sample "ABC" \
        --fastaout - | \
    grep -qw ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

# When using --relabel, --relabel_self, --relabel_md5 or --relabel_sha1,
# preserve and report abundance annotations to the output fasta file
# (using the pattern ';size=integer;').

DESCRIPTION="--fastx_uniques --sizeout is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --sizeout \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --sizeout is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --sizeout \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --sizeout missing size annotations are not added (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# without sizein, annotations are discarded, and replaced with dereplication results
DESCRIPTION="--fastx_uniques size annotations are replaced (without sizein, with sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --sizeout \
        --fastaout - | \
    grep -qw ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques size annotations are replaced (with sizein and sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --sizeout \
        --fastaout - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques size annotations are left untouched (without sizein and sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## add abundance annotations
DESCRIPTION="--fastx_uniques --relabel no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --fastaout - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --fastaout - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_self no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_self \
        --fastaout - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_self --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_self \
        --sizeout \
        --fastaout - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_md5 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_md5 \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_md5 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_sha1 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_sha1 \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_sha1 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## preserve abundance annotations
DESCRIPTION="--fastx_uniques --relabel no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --fastaout - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel --sizeout updates size annotations (without sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --fastaout - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel --sizeout updates size annotations (with sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --relabel "label" \
        --sizeout \
        --fastaout - | \
    grep -qw ">label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_self no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_self \
        --fastaout - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_self --sizeout updates size annotations (without sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_self \
        --sizeout \
        --fastaout - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_self --sizeout preserves size annotations (with sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --relabel_self \
        --sizeout \
        --fastaout - | \
    grep -qw ">A;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_md5 no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_md5 \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_md5 --sizeout updates size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_md5 --sizeout preserves size annotations (with sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_sha1 no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_sha1 \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_sha1 --sizeout updates size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --relabel_sha1 --sizeout preserves size annotations (with sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ tabbedout

#   Column 1 contains the original label/header of the sequence.  Column 2  contains  the label of the output sequence which is equal to the label/header of the first sequence in each cluster, but potentially relabelled. Column 3 contains the cluster number, starting from 0. Column 4 contains the sequence number within each cluster, starting at 0. Column 5 contains the number of sequences in the cluster. Column 6 contains the original label/header of the first sequence in the cluster before any potential relabelling. This option is only valid for the --fastx_uniques command.

## --tabbedout is accepted
DESCRIPTION="--tabbedout is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --tabbedout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques fails if unable to open tabbedout file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --tabbedout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

## --tabbedout fails if no output redirection is given (filename, device or -)
DESCRIPTION="--tabbedout fails if no output redirection is given"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --tabbedout &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --tabbedout outputs data
DESCRIPTION="--tabbedout outputs data"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout returns a tab-delimited table with 6 fields"
printf "@s\nA\n+\nI\n@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'NF != 6 {c += 1} END {exit c == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# s1	s1	0	0	2	s1
# s2	s1	0	1	2	s1
DESCRIPTION="--tabbedout returns a row for each input sequence"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    cut -f 1 | \
    tr "\n" "@" | \
    grep -qw "s1@s2@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 1 contains the original label/header of the sequence"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk '{exit $1 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 2 contains the label of the first sequence in the cluster"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'NR == 2 {exit $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 2 contains the label of the first sequence in the cluster (relabel)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "seed_" \
        --tabbedout - | \
    awk 'NR == 2 {exit $2 == "seed_1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 3 contains the cluster number, starting from 0 (1 cluster)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'END {exit $3 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 3 contains the cluster number, starting from 0 (2 clusters)"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'END {exit $3 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 3 contains the cluster number, starting from 0 (3 clusters)"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nI\n@s3\nG\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'END {exit $3 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 3 contains the cluster number, starting from 0 (4 clusters)"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nI\n@s3\nG\n+\nI\n@s4\nT\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'END {exit $3 == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 4 contains the sequence number within each cluster (starting at 0)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'END {exit $4 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 4 contains the sequence number within each cluster (cluster of two)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'END {exit $4 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 4 contains the sequence number within each cluster (cluster of three)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n@s3\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'END {exit $4 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 4 contains the sequence number within each cluster (restarts at zero)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n@s3\nA\n+\nI\n@s4\nC\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'END {exit $4 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 5 contains the number of sequences in the cluster (cluster of one)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'BEGIN {c = 0} $5 != 1 {c += 1} END {exit c == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 5 contains the number of sequences in the cluster (cluster of two)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'BEGIN {c = 0} $5 != 2 {c += 1} END {exit c == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 5 contains the number of sequences in the cluster (cluster of three)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n@s3\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'BEGIN {c = 0} $5 != 3 {c += 1} END {exit c == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 5 contains the number of sequences in the cluster (restart at one)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n@s3\nC\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'NR == 3 {exit $5 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 6 contains the original label of the first sequence in the cluster"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --tabbedout - | \
    awk 'NR == 2 {exit $6 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 6 contains the original label of the first sequence in the cluster (relabel)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --relabel "seed_" \
        --tabbedout - | \
    awk 'NR == 2 {exit $6 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--fastx_uniques --threads is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --threads 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --threads > 1 triggers a warning (not multithreaded)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --threads 2 \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------------- topn

## --topn is accepted
DESCRIPTION="--topn is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --topn 1 \
        --fastaout /dev/null 2> /dev/null &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn keeps only n sequences
DESCRIPTION="--topn keeps only n sequences"
printf ">s1\nA\n>s2\nG\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --topn 1 \
        --fastaout - | \
    awk '/^>/ {c += 1} END {exit c == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn returns only the n most abundant sequences (s2 in this example)
DESCRIPTION="--topn returns only the n most abundant sequences"
printf ">s1;size=1;\nA\n>s2;size=2;\nC\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --quiet \
        --topn 1 \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qw ">s2;size=2;@C@" &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn returns only the n most abundant sequences after full length
## dereplication (s1 in this example)
DESCRIPTION="--topn returns the n most abundant sequences after full-length dereplication"
printf ">s1;size=1;\nA\n>s2;size=2;\nC\n>s3;size=2;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --sizeout \
        --quiet \
        --topn 1 \
        --fastaout - | \
    tr "\n" "@" | \
    grep -qwE ">s1;size=3;?@A@" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn fails with negative arguments
DESCRIPTION="--topn fails with negative arguments"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --topn "-1" \
        --fastaout /dev/null 2> /dev/null &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn zero should return no sequence or fail (only values > 0
## should be accepted)
DESCRIPTION="--topn zero should return no sequence (or fail)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --topn 0 \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --topn fails with non-numerical argument
DESCRIPTION="--topn fails with non-numerical argument"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --topn A \
        --fastaout /dev/null 2> /dev/null &&\
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --topn accepts abundance values equal to 2^32
DESCRIPTION="--topn accepts abundance values equal to 2^32"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --topn $(( 2 ** 32 )) \
        --fastaout /dev/null 2> /dev/null &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# special case when 'relabel_count == opt_topn'
DESCRIPTION="--topn --relabel (topn is used to stop output iteration)"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nI\n@s3\nG\n+\nI\n@s4\nT\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --relabel "seed_" \
        --topn 3 \
        --quiet \
        --fastqout - | \
    awk '/^@/ {c +=1} END {exit c == 3 ? 0 : 1}' && \
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
        --fastx_uniques - \
        --uc /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques fails if unable to open uc file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --uc ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

## --uc fails if no output redirection is given (filename, device or -)
DESCRIPTION="--uc fails if no output redirection is given"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --uc &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc outputs data
DESCRIPTION="--uc outputs data"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns a tab-delimited table with 10 fields
DESCRIPTION="--uc returns a tab-delimited table with 10 fields"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    awk 'NF != 10 {c += 1} END {exit c == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns only lines starting with S, C or H
DESCRIPTION="--uc returns only lines starting with S, C or H"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    grep -q "^[^HCS]" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc returns a S line (centroid) and a C lines (cluster) for each input sequence
DESCRIPTION="--uc returns a S line (centroid) and a C lines (cluster) for each sequence"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
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
        --fastx_uniques - \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc returns a H line (first column) when there is a hit
DESCRIPTION="--uc returns a H line when there is a hit"
printf ">a\nA\n>b\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns the expected number of S lines (two centroids)
DESCRIPTION="--uc returns the expected number of S lines (centroids)"
printf ">s1\nA\n>s2\nA\n>s3\nG\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    awk '/^S/ {c += 1} END {exit c == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns the expected number of C lines (two clusters)
DESCRIPTION="--uc returns the expected number of C lines (clusters)"
printf ">s1\nA\n>s2\nA\n>s3\nG\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    awk '/^C/ {c += 1} END {exit c == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc cluster numbering is zero-based (first cluster is number zero)
DESCRIPTION="--uc cluster numbering is zero-based (2nd column = 0)"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
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
        --fastx_uniques - \
        --quiet \
        --uc - | \
    awk '$2 > n {n = $2} END {exit n == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc cluster size is correct for C line (3rd column)
DESCRIPTION="--uc cluster size is correct for C line (3rd column)"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    awk '/^C/ {exit $3 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid length is correct for S line (3rd column)
DESCRIPTION="--uc centroid length is correct for S line (3rd column) #1"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    awk '/^S/ {exit $3 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid length is correct for S line (3rd column)
DESCRIPTION="--uc centroid length is correct for S line (3rd column) #2"
printf ">s1\nAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    awk '/^S/ {exit $3 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc hit length is correct in (H line, 3rd column)
DESCRIPTION="--uc hit length is correct in (H line, 3rd column) #1"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    awk '/^H/ {exit $3 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc hit length is correct in (H line, 3rd column)
DESCRIPTION="--uc hit length is correct in (H line, 3rd column) #2"
printf ">s1\nAA\n>s2\nAA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --uc - | \
    awk '/^H/ {exit $3 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# # 5. Match orientation + or - (H), or set to ’*’ (S, C).
DESCRIPTION="--uc strand orientation is correct (H line, 5th column)"
printf ">s1;size=1;\nA\n>s2;size=1;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --sizeout \
        --strand both \
        --quiet \
        --fastaout /dev/null \
        --uc - | \
    awk '/^H/ {exit $5 == "+" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uc strand orientation is correct (H line, 5th column, reverse strand)"
printf ">s1;size=1;\nA\n>s2;size=1;\nT\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --sizeout \
        --strand both \
        --quiet \
        --fastaout /dev/null \
        --uc - | \
    awk '/^H/ {exit $5 == "-" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## trigger reallocation of extra space for uc or tabbedout
DESCRIPTION="--fastx_uniques accepts more than 1,024 unique sequences (--uc)"
(for i in {1..1025} ; do
    printf ">s%d\n" ${i}
    yes A | head -n ${i}
 done) | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastaout /dev/null \
        --uc /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--fastx_uniques --xee is accepted"
printf ">s;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xee \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --xee removes expected error annotations from input"
printf ">s;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xee \
        --quiet \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--fastx_uniques --xlength is accepted"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xlength \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --xlength removes length annotations from input"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xlength \
        --quiet \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --xlength accepts input without length annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xlength \
        --quiet \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_uniques --xlength removes length annotations (input), lengthout adds them (output)"
printf ">s;length=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xlength \
        --lengthout \
        --quiet \
        --fastaout - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

## --xsize is accepted
DESCRIPTION="--xsize is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xsize \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize strips abundance values"
printf ">s;size=1;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizein \
        --xsize \
        --quiet \
        --fastaout - | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--xsize strips abundance values (without --sizein)"
printf ">s;size=1;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xsize \
        --quiet \
        --fastaout - | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# xsize + sizein + sizeout + relabel_keep: ?
DESCRIPTION="--xsize + sizeout (new size)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xsize \
        --quiet \
        --sizeout \
        --fastaout - | \
    grep -wq ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + sizein (no size)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizeout \
        --xsize \
        --quiet \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + sizein + sizeout (new size)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --sizeout \
        --xsize \
        --quiet \
        --fastaout - | \
    grep -wq ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + sizein + sizeout + relabel_keep (keep old size)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --relabel_keep \
        --sizein \
        --xsize \
        --quiet \
        --sizeout \
        --fastaout - | \
    grep -wq ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# xsize + sizein + sizeout + notrunclabels: ?
DESCRIPTION="sizeout + notrunclabels (trim and reinsert new size at the end)"
printf ">s;size=2; extra\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --notrunclabels \
        --quiet \
        --sizeout \
        --fastaout - | \
    grep -wq ">s; extra;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="sizein + sizeout + notrunclabels (trim and reinsert old size at the end)"
printf ">s;size=2; extra\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --notrunclabels \
        --quiet \
        --sizein \
        --sizeout \
        --fastaout - | \
    grep -wq ">s; extra;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + sizein + sizeout + notrunclabels (trim and reinsert old size at the end)"
printf ">s;size=2; extra\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --notrunclabels \
        --quiet \
        --xsize \
        --sizein \
        --sizeout \
        --fastaout - | \
    grep -wq ">s; extra;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + notrunclabels (without space, no final ;)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xsize \
        --notrunclabels \
        --quiet \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + notrunclabels (without space, final ;)"
printf ">s;size=2;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xsize \
        --notrunclabels \
        --quiet \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + notrunclabels (with space and final ;)"
printf ">s;size=2; \nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xsize \
        --notrunclabels \
        --quiet \
        --fastaout - | \
    grep -wq ">s; " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize + notrunclabels (with space and no final ;)"
printf ">s;size=2 \nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xsize \
        --notrunclabels \
        --quiet \
        --fastaout - | \
    grep -wq ">s;size=2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# vsearch truncates removes annotations, but keeps dangling ";" 
DESCRIPTION="--xsize + notrunclabels (no size, no space, and final ;)"
printf ">s;\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --xsize \
        --notrunclabels \
        --quiet \
        --fastaout - | \
    grep -wq ">s;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--output is rejected"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
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
        --fastx_uniques <(printf ">s1\nA\n>s2\nA\n") \
        --uc /dev/null \
        --fastaout /dev/null 2> /dev/null
    DESCRIPTION="--fastx_uniques valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_uniques valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP
fi

## issue with:
# --fastqout /dev/null \
# --tabbedout /dev/null \


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#

## TODO:
# - missing checks in vsearch code (min/max mismatches)
# - fastq_asciiout (33 -> 64) or (64 -> 33) does not re-encode quality values?

exit 0
