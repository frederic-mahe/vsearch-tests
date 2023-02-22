#!/bin/bash -

## Print a header
SCRIPT_NAME="derep_fulllength"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    # exit 1
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
#                             --derep_fulllength                              #
#                                                                             #
#*****************************************************************************#

## ---------------------------- command --derep_fulllength and mandatory output

## --derep_fulllength is accepted
DESCRIPTION="--derep_fulllength is accepted"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_fulllength requires --output
DESCRIPTION="--derep_fulllength requires --output"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength rejects non-fasta input (#1)"
printf "\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength rejects non-fasta input (#2)"
printf "\n>s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output /dev/null 2> /dev/null  && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength accepts a single fasta entry"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# discard entries shorter than 32 nucleotides by default
DESCRIPTION="--derep_fulllength discards a short fasta entry"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output - 2> /dev/null | \
    grep -qw ">s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength discards an empty fasta entry"
printf ">s\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output - 2> /dev/null | \
    grep -qw ">s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ---------------------- options for simpler tests: --quiet and --minseqlength

DESCRIPTION="--derep_fulllength outputs stderr messages"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength --quiet removes stderr messages"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength --minseqlength 1 (keep very short fasta entries)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# keep empty fasta entries
DESCRIPTION="--derep_fulllength --minseqlength 0 (keep empty fasta entries)"
printf ">s\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 0 \
        --quiet \
        --output - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ----------------------------------------------------- test general behaviour

## --derep_fulllength outputs data
DESCRIPTION="--derep_fulllength outputs data"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --quiet \
        --minseqlength 1 \
        --output - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --derep_fulllength outputs expected results
DESCRIPTION="--derep_fulllength outputs expected results (in fasta format)"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_fulllength takes terminal gaps into account (substring aren't merged)
DESCRIPTION="--derep_fulllength takes terminal gaps into account"
printf ">s1\nAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --derep_fulllength replicate sequences are not sorted by
## alphabetical order of headers. Identical sequences receive the
## header of the first sequence of their group (s2 before s1)
DESCRIPTION="--derep_fulllength identical seqs receive the header of the first seq of the group"
printf ">s2\nA\n>s1\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s2@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_fulllength distinct sequences are sorted by
## alphabetical order of headers (s1 before s2)
DESCRIPTION="--derep_fulllength distinct sequences are sorted by header alphabetical order"
printf ">s2\nA\n>s1\nG\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@G@>s2@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_fulllength distinct sequences are not sorted by
## alphabetical order of DNA strings (G before A)
DESCRIPTION="--derep_fulllength distinct sequences are not sorted by DNA alphabetical order"
printf ">s2\nA\n>s1\nG\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@G@>s2@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_fulllength sequence comparison is case insensitive
DESCRIPTION="--derep_fulllength sequence comparison is case insensitive"
printf ">s1\nA\n>s2\na\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_fulllength preserves the case of the first occurrence of each sequence
DESCRIPTION="--derep_fulllength preserves the case of the first occurrence of each sequence"
printf ">s1\na\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@a@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_fulllength T and U are considered the same
DESCRIPTION="--derep_fulllength T and U are considered the same"
printf ">s1\nT\n>s2\nU\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@T@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --derep_fulllength does not replace U with T in its output
DESCRIPTION="--derep_fulllength does not replace U with T in its output"
printf ">s1\nU\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s1@U@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#               --bzip2_decompress and --gzip_decompress                      #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--derep_fulllength rejects compressed stdin (bzip2)"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --bzip2_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength --bzip2_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --bzip2_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength --bzip2_decompress rejects uncompressed stdin"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --bzip2_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength rejects compressed stdin (gzip)"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength --gzip_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength --gzip_decompress rejects uncompressed stdin"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--derep_fulllength rejects --bzip2_decompress + --gzip_decompress"
printf "" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --bzip2_decompress \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               --fasta_width                                 #
#                                                                             #
#*****************************************************************************#

# Fasta files produced by vsearch are wrapped (sequences are written on
# lines of integer nucleotides, 80 by default). Set the value to zero to
# eliminate the wrapping.

# - no option: test a seq with 80 nucleotides (observe lack of wrapping)
# - no option: test a seq with more than 80 nucleotides (observe wrapping)
# - option is accepted
# - accept value of 2^32?
# - set value to 1 (observe wrapping)
# - set value to 0 (observe lack of wrapping)


#*****************************************************************************#
#                                                                             #
#                                  --strand                                   #
#                                                                             #
#*****************************************************************************#

## --strand is accepted
DESCRIPTION="--strand is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --strand both \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --strand both allow dereplication of strand plus and minus (--derep_fulllength)
DESCRIPTION="--strand allow dereplication of strand plus and minus (--derep_fulllength)"
printf ">s1;size=1;\nA\n>s2;size=1;\nT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --sizein \
        --sizeout \
        --minseqlength 1 \
        --strand both \
        --quiet \
        --output - | \
    grep -wqE ">s1;size=2;?" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --strand plus does not change default behaviour
DESCRIPTION="--strand plus does not change default behaviour"
printf ">s1;size=1;\nA\n>s2;size=1;\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --sizein \
        --sizeout \
        --quiet \
        --strand plus \
        --output - | \
    grep -wqE ">s1;size=2;?" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --strand fails if an unknown argument is given
DESCRIPTION="--strand fails if an unknown argument is given"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --strand unknown \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                   --topn                                    #
#                                                                             #
#*****************************************************************************#

## --topn is accepted
DESCRIPTION="--topn is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --topn 1 \
        --output /dev/null 2> /dev/null &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn keeps only n sequences
DESCRIPTION="--topn keeps only n sequences"
printf ">s1\nA\n>s2\nG\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
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
        --derep_fulllength - \
        --minseqlength 1 \
        --sizein \
        --quiet \
        --topn 1 \
        --output - | \
    tr "\n" "@" | \
    grep -q "^>s2;size=2;@C@$" &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn returns only the n most abundant sequences after full length
## dereplication (s1 in this example)
DESCRIPTION="--topn returns the n most abundant sequences after full-length dereplication"
printf ">s1;size=1;\nA\n>s2;size=2;\nC\n>s3;size=2;\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --sizein \
        --sizeout \
        --quiet \
        --topn 1 \
        --output - | \
    tr "\n" "@" | \
    grep -qE "^>s1;size=3;?@A@$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn fails with negative arguments
DESCRIPTION="--topn fails with negative arguments"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --topn "-1" \
        --output /dev/null 2> /dev/null &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --topn zero should return no sequence or fail (only values > 0
## should be accepted)
DESCRIPTION="--topn zero should return no sequence (or fail)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
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
        --derep_fulllength - \
        --topn A \
        --output /dev/null 2> /dev/null &&\
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --topn accepts abundance values equal to 2^32
DESCRIPTION="--topn accepts abundance values equal to 2^32"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --topn $(( 2 ** 32 )) \
        --output /dev/null 2> /dev/null &&\
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                    --uc                                     #
#                                                                             #
#*****************************************************************************#

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
        --derep_fulllength - \
        --minseqlength 1 \
        --uc /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc fails if no output redirection is given (filename, device or -)
DESCRIPTION="--uc fails if no output redirection is given"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --uc &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc outputs data
DESCRIPTION="--uc outputs data"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
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
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '/^H/ {exit $3 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                   --xsize                                   #
#                                                                             #
#*****************************************************************************#

## --xsize is accepted
DESCRIPTION="--xsize is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --xsize \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xsize strips abundance values (removes the ";size=INT[;]" annotations)
DESCRIPTION="--xsize strips abundance values"
printf ">s;size=1;\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --sizein \
        --xsize \
        --quiet \
        --output - | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --xsize strips abundance values (removes the ";size=INT[;]" annotations)
DESCRIPTION="--xsize strips abundance values (without --sizein)"
printf ">s;size=1;\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --xsize \
        --quiet \
        --output - | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

exit 0

## TODO:
# sizein + no sizeout = xsize: change output order?
# xsize + sizein + sizeout: ?
# xsize + sizein + sizeout + notrunclabels: ?
# xsize + sizein + sizeout + relabel_keep: ?

## list of options available when using the --derep_fulllength command

# fasta_width
# log
# maxseqlength
# maxuniquesize
# minseqlength
# minuniquesize
# no_progress
# notrunclabels
# relabel
# relabel_keep
# relabel_md5
# relabel_self
# relabel_sha1
# sample
# sizein
# sizeout
# strand
# threads
# topn
# uc
# xee
# xsize


## options tested:

# bzip2_decompress
# gzip_decompress
# quiet
# output
