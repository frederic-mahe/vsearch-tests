#!/bin/bash -

## Print a header
SCRIPT_NAME="fastx_subsample"
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

## ------------------------------------------------------------------- fastaout

DESCRIPTION="--fastx_subsample accepts --fastaout"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample requires at least one output file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample requires a subsampling value"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample fails if unable to open output file for writing (fasta)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

# Cannot subsample more reads than in the original sample
DESCRIPTION="--fastx_subsample rejects empty input (--fastaout)"
printf "" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample discards empty fasta sequences"
printf ">s1\nA\n>s2\n\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout outputs in fasta format (fasta input)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout outputs in fasta format (fastq input)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- fastqout

DESCRIPTION="--fastx_subsample accepts --fastqout"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample fails if unable to open output file for writing (fastq)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastqout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

# Cannot subsample more reads than in the original sample
DESCRIPTION="--fastx_subsample rejects empty input (--fastqout)"
printf "" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample discards empty fastq sequences"
printf "@s\nA\n+\nI\n@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout outputs in fastq format (fastq input)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastqout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq "@sA+I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout rejects fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample can output both fasta and fastq"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- sample_size

DESCRIPTION="--fastx_subsample accepts --sample_size"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size can be equal to input size"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size can be smaller than input size"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Cannot subsample more reads than in the original sample
DESCRIPTION="--fastx_subsample --sample_size cannot be larger than input size"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 2 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# Cannot subsample more reads than in the original sample
DESCRIPTION="--fastx_subsample --sample_size cannot be larger than input size (error message)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 2 \
        --fastaout /dev/null 2>&1 | \
    grep -qi "Fatal" &&
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size cannot be zero"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 0 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size can be larger than int8 max"
MAX=128
(for ((i = 0 ; i <= MAX ; i++)) ; do
     printf ">s1\nA\n"
 done
) | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size ${MAX} \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset MAX

DESCRIPTION="--fastx_subsample --sample_size can be larger than uint8 max"
MAX=256
(for ((i = 0 ; i <= MAX ; i++)) ; do
     printf ">s1\nA\n"
 done
) | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size ${MAX} \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset MAX

DESCRIPTION="--fastx_subsample --sample_size can be larger than int16 max"
MAX=32768
(for ((i = 0 ; i <= MAX ; i++)) ; do
     printf ">s1\nA\n"
 done
) | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size ${MAX} \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset MAX

DESCRIPTION="--fastx_subsample --sample_size can be larger than uint16 max"
MAX=65536
(for ((i = 0 ; i <= MAX ; i++)) ; do
     printf ">s1\nA\n"
 done
) | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size ${MAX} \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset MAX

## too slow, too much memory
# DESCRIPTION="--fastx_subsample --sample_size can be larger than int32 max"
# MAX=2147483648
# (for ((i = 0 ; i <= MAX ; i++)) ; do
#      printf ">s1\nA\n"
#  done
# ) | \
#     "${VSEARCH}" \
#         --fastx_subsample - \
#         --sample_size ${MAX} \
#         --fastaout /dev/null 2> /dev/null && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"
# unset MAX

## too slow, too much memory
# DESCRIPTION="--fastx_subsample --sample_size can be larger than uint32 max"
# MAX=4294967296
# (for ((i = 0 ; i <= MAX ; i++)) ; do
#      printf ">s1\nA\n"
#  done
# ) | \
#     "${VSEARCH}" \
#         --fastx_subsample - \
#         --sample_size ${MAX} \
#         --fastaout /dev/null 2> /dev/null && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"
# unset MAX

# leading zeroes are ignored
DESCRIPTION="--fastx_subsample --sample_size accepts leading zeroes"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 01 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size rejects floats"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1.0 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size rejects non-integers"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size A \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size extracts n sequences (n = 1)"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size extracts n sequences (n = 2)"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 2 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- sample_pct

DESCRIPTION="--fastx_subsample accepts --sample_pct"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 100.0 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct accepts integers (100)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 100.0 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note: null percentage outputs nothing to fastaout_discarded
DESCRIPTION="--fastx_subsample --sample_pct accepts a null value"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 0.0 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct accepts floats (100.0)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 100.0 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct accepts floats with many digits (1/3rd)"
printf ">s1\nA\n>s2\nC\n>s3\nG\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 33.333333333333333 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct accepts leading zeroes"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 0100 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct rejects non-integers"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct A \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct extracts a percentage of sequences (2 out of 2)"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 100.0 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct extracts a percentage of sequences (1 out of 2)"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 50.0 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct extracts a percentage of sequences (1 out of 4)"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 25.0 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct extracts a percentage of sequences (1 out of 5)"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n>s5\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 20.0 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct extracts a percentage of sequences (1 out of 8)"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n>s5\nA\n>s6\nC\n>s7\nG\n>s8\nT\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 12.5 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# less predictable output for small data set sizes
DESCRIPTION="--fastx_subsample --sample_pct some percentages are hard to represent (1/3rd)"
printf ">s1\nA\n>s2\nC\n>s3\nG\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 33.33 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct some percentages are hard to represent (1/6th)"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n>s5\nA\n>s6\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 16.66 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# Cannot subsample more reads than in the original sample
DESCRIPTION="--fastx_subsample --sample_pct cannot be larger than 100"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 200.0 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# Cannot subsample more reads than in the original sample
DESCRIPTION="--fastx_subsample --sample_pct cannot be larger than 100 (error message)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 200.0 \
        --fastaout /dev/null 2>&1 | \
    grep -qi "Fatal" &&
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# final number of reads = 100 * 10.9 / 100.0 = 10.9 -> 10 (not 11)
DESCRIPTION="--fastx_subsample --sample_pct final number of reads is floored, not rounded"
for i in {1..100} ; do
    printf ">s%s\nA\n" ${i}
done | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 10.9 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 10 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

# subsampling properties:
# - output size is equal to target size
# - input order is preserved
# - sum of entries remains constant (without --sizein)
# - sum of reads remains constant (with --sizein and --sizeout)
# - entries are no duplicated
# - entries are no lost

DESCRIPTION="--fastx_subsample output size is equal to target size"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n>s5\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 3 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample input order is preserved"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n>s5\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 3 \
        --fastaout - 2> /dev/null | \
    grep "^>" | \
    sort --check=quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample sum of entries remains constant"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n>s5\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 3 \
        --fastaout - \
        --fastaout_discarded - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 5 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample sum of reads remains constant"
printf ">s1;size=5\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 3 \
        --sizein \
        --sizeout \
        --fastaout - \
        --fastaout_discarded - 2> /dev/null | \
    awk -F "=" '/^>/ {s += $2} END {exit s == 5 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample entries are not duplicated or lost"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n>s5\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 3 \
        --fastaout - \
        --fastaout_discarded - 2> /dev/null | \
    grep "^>" | \
    sort --unique | \
    awk -F "=" 'END {exit NR == 5 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## when subsampling with a given seed two fastq files with the same
## number of reads per file, then the same reads will be
## selected. This is important for paired-end files that need to
## remain in sync (R1-R2). In this test, R1 and R2 subsamplings must
## be identical (same reads, same order):
DESCRIPTION="--fastx_subsample selects the same reads in paired-end fastq files (--sample_size)"
SEED=1
cmp --quiet \
    <(for i in {01..10} ; do
          printf "@s%s\nA\n+\nI\n" ${i}
      done | \
          "${VSEARCH}" \
              --fastx_subsample - \
              --randseed ${SEED} \
              --sample_size 3 \
              --fastqout - 2> /dev/null) \
     <(for i in {01..10} ; do
           printf "@s%s\nA\n+\nI\n" ${i}
       done | \
           "${VSEARCH}" \
               --fastx_subsample - \
               --randseed ${SEED} \
               --sample_size 3 \
               --fastqout - 2> /dev/null) && \
           success "${DESCRIPTION}" || \
               failure "${DESCRIPTION}"
unset SEED

DESCRIPTION="--fastx_subsample selects the same reads in paired-end fastq files (--sample_pct)"
SEED=1
cmp --quiet \
    <(for i in {01..10} ; do
          printf "@s%s\nA\n+\nI\n" ${i}
      done | \
          "${VSEARCH}" \
              --fastx_subsample - \
              --randseed ${SEED} \
              --sample_pct 30.0 \
              --fastqout - 2> /dev/null) \
     <(for i in {01..10} ; do
           printf "@s%s\nA\n+\nI\n" ${i}
       done | \
           "${VSEARCH}" \
               --fastx_subsample - \
               --randseed ${SEED} \
               --sample_pct 30.0 \
               --fastqout - 2> /dev/null) && \
           success "${DESCRIPTION}" || \
               failure "${DESCRIPTION}"
unset SEED


## when subsampling with a given seed two fastq files with a different
## number of reads per file, then the different reads will be
## selected. In this test, there are 10 reads in the first fastq file
## and 9 reads in the second, so subsamplings must be different:
DESCRIPTION="--fastx_subsample depends on the number of reads in the fastq file (--sample_size)"
SEED=1
cmp --quiet \
    <(for i in {01..10} ; do
          printf "@s%s\nA\n+\nI\n" ${i}
      done | \
          "${VSEARCH}" \
              --fastx_subsample - \
              --randseed ${SEED} \
              --sample_size 3 \
              --fastqout - 2> /dev/null) \
     <(for i in {01..9} ; do
           printf "@s%s\nA\n+\nI\n" ${i}
       done | \
           "${VSEARCH}" \
               --fastx_subsample - \
               --randseed ${SEED} \
               --sample_size 3 \
               --fastqout - 2> /dev/null) && \
           failure "${DESCRIPTION}" || \
               success "${DESCRIPTION}"
unset SEED

DESCRIPTION="--fastx_subsample depends on the number of reads in the fastq file (--sample_pct)"
SEED=1
cmp --quiet \
    <(for i in {01..10} ; do
          printf "@s%s\nA\n+\nI\n" ${i}
      done | \
          "${VSEARCH}" \
              --fastx_subsample - \
              --randseed ${SEED} \
              --sample_pct 30.0 \
              --fastqout - 2> /dev/null) \
     <(for i in {01..9} ; do
           printf "@s%s\nA\n+\nI\n" ${i}
       done | \
           "${VSEARCH}" \
               --fastx_subsample - \
               --randseed ${SEED} \
               --sample_pct 30.0 \
               --fastqout - 2> /dev/null) && \
           failure "${DESCRIPTION}" || \
               success "${DESCRIPTION}"
unset SEED


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------- fastaout_discarded

DESCRIPTION="--fastx_subsample accepts --fastaout_discarded"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastaout_discarded /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout_discarded works with --fastaout"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastaout_discarded /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout_discarded works with --fastqout (fastq input)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastqout /dev/null \
        --fastaout_discarded /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample fails if unable to open output file for writing (--fastaout_discarded)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastaout_discarded ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--fastx_subsample --fastaout_discarded outputs in fasta format (fasta input)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastaout_discarded - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout_discarded outputs in fasta format (fastq input)"
printf "@s\nA\n+\nI\n@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastaout_discarded - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout_discarded is empty if sample size = input size"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastaout_discarded - 2> /dev/null | \
    tr -d "\n" | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout_discarded = input size - sample size"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastaout_discarded - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout_discarded is empty if pct is null"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 0.0 \
        --fastaout /dev/null \
        --fastaout_discarded - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout_discarded is not empty if pct is greater than null"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 0.001 \
        --fastaout /dev/null \
        --fastaout_discarded - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------- fastqout_discarded

DESCRIPTION="--fastx_subsample accepts --fastqout_discarded"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastqout_discarded /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded accepts fastq"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastqout_discarded /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded rejects fasta"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastqout_discarded /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded works with --fastaout"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastqout_discarded /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded works with --fastqout (fastq input)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastqout /dev/null \
        --fastqout_discarded /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample fails if unable to open output file for writing (--fastqout_discarded)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastqout /dev/null \
        --fastqout_discarded ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--fastx_subsample --fastqout_discarded outputs in fastq format (fastq input)"
printf "@s\nA\n+\nI\n@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastqout_discarded - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq "@sA+I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded is empty if sample size = input size"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastqout_discarded - 2> /dev/null | \
    tr -d "\n" | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded = input size - sample size"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastqout_discarded - 2> /dev/null | \
    awk '/^@/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded is empty if pct is null"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 0.0 \
        --fastaout /dev/null \
        --fastqout_discarded - 2> /dev/null | \
    awk '/^@/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded is not empty if pct is greater than null"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 0.001 \
        --fastaout /dev/null \
        --fastqout_discarded - 2> /dev/null | \
    awk '/^@/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# use four output files at the same time (must be fastq input)
DESCRIPTION="--fastx_subsample can output to four files at the same time"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --fastaout_discarded /dev/null \
        --fastqout /dev/null \
        --fastqout_discarded /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- randseed

DESCRIPTION="--fastx_subsample accepts --randseed"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --randseed 1 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample a fix --randseed produces constant output"
SEED=1
OUTPUT1=$(
    printf ">s1\nA\n>s2\nA\n>s3\nA\n>s4\nA\n" | \
        "${VSEARCH}" \
            --fastx_subsample - \
            --sample_size 1 \
            --quiet \
            --randseed ${SEED} \
            --fastaout -
       )
OUTPUT2=$(
    printf ">s1\nA\n>s2\nA\n>s3\nA\n>s4\nA\n" | \
        "${VSEARCH}" \
            --fastx_subsample - \
            --sample_size 1 \
            --quiet \
            --randseed ${SEED} \
            --fastaout -
       )
[[ "${OUTPUT1}" == "${OUTPUT2}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
unset SEED OUTPUT1 OUTPUT2

DESCRIPTION="--fastx_subsample accepts --randseed 0 (free seed)"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --randseed 0 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--fastx_subsample accepts --sizein"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --sizein \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sizein (fasta input)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --sizein \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sizein (fastq input)"
printf "@s;size=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --sizein \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# entries without annotations are silently assumed to be of size=1 
DESCRIPTION="--fastx_subsample --sizein (missing annotations are set to size=1)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --sizein \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sample size == input size
DESCRIPTION="--fastx_subsample --sizein takes into account annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 2 \
        --sizein \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">s;size=2A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sample size < input size, output size is not updated
DESCRIPTION="--fastx_subsample --sizein (output size is not updated)"
printf ">s;size=3\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 2 \
        --sizein \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">s;size=3A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sizein --sizeout (output size is updated)"
printf ">s;size=3\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 2 \
        --sizein \
        --sizeout \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">s;size=2A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

# The valid options for the fastx_subsample command are:
# --bzip2_decompress --fasta_width --fastaout --fastaout_discarded
# --fastq_ascii --fastq_qmax --fastq_qmin --fastqout
# --fastqout_discarded --gzip_decompress --label_suffix --lengthout
# --log --no_progress --notrunclabels --quiet --randseed --relabel
# --relabel_keep --relabel_md5 --relabel_self --relabel_sha1
# --sample --sample_pct --sample_size --sizein --sizeout --threads
# --xee --xlength --xsize

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--fastx_subsample --bzip2_decompress is accepted"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --bzip2_decompress \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --bzip2_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --bzip2_decompress \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fasta_width

DESCRIPTION="--fastx_subsample --fasta_width is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fasta_width 1 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fasta_width wraps fasta output"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fasta_width 1 \
        --fastaout - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--fastx_subsample --fastq_ascii is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastq_ascii 33 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--fastx_subsample --fastq_qmax is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastq_qmax 41 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# J = 41, the read should be removed?
DESCRIPTION="--fastx_subsample --fastq_qmax has no effect"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastq_qmax 40 \
        --fastaout - | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--fastx_subsample --fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastq_qmin 1 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastq_qmin has no effect"
printf "@s\nA\n+\nH\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastq_qmin 40 \
        --fastaout - | \
    tr -d "\n" | \
    grep -wq ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--fastx_subsample --gzip_decompress is accepted"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --gzip_decompress \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --gzip_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --gzip_decompress \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--fastx_subsample --label_suffix is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --label_suffix "_suffix" \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --label_suffix adds the suffix 'string' to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --label_suffix "_suffix" \
        --fastaout - | \
    grep -wq ">s_suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --label_suffix adds the suffix 'string' (before annotations)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --label_suffix "_suffix" \
        --lengthout \
        --fastaout - | \
    grep -wq ">s_suffix;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--fastx_subsample --lengthout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --lengthout \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --lengthout adds length annotations to output"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --lengthout \
        --fastaout - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--fastx_subsample --log is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --log /dev/null \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --log writes to a file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null \
        --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --log does not prevent messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --fastaout /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--fastx_subsample --no_progress is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --no_progress \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--fastx_subsample --no_progress removes progressive report on stderr (no visible effect)"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --no_progress \
        --fastaout /dev/null 2>&1 | \
    grep -iq "^subsampling" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--fastx_subsample --notrunclabels is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --notrunclabels \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --notrunclabels preserves full headers"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --notrunclabels \
        --fastaout - | \
    grep -wq ">s extra" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--fastx_subsample --quiet is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --quiet eliminates all (normal) messages to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --quiet allows error messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --quiet2 \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--fastx_subsample --relabel is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel renames sequence (label + ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --fastaout - | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel renames sequence (empty label, only ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "" \
        --fastaout - | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel cannot combine with --relabel_md5"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --relabel_md5 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel cannot combine with --relabel_sha1"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --relabel_sha1 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--fastx_subsample --relabel_keep is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_keep renames and keeps original sequence name"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --fastaout - | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--fastx_subsample --relabel_md5 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_md5 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_md5 relabels using MD5 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_md5 \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--fastx_subsample --relabel_self is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_self \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_self relabels using sequence as label"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_self \
        --fastaout - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--fastx_subsample --relabel_sha1 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_sha1 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_sha1 relabels using SHA1 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_sha1 \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--fastx_subsample --sample is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --sample "ABC" \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample adds sample name to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --sample "ABC" \
        --fastaout - | \
    grep -qw ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

DESCRIPTION="--fastx_subsample --sizeout is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --sizeout \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sizeout is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --sizeout \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sizeout missing size annotations are not added (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastaout - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# no --sizein, so all entries are size=1, --sizeout writes that value to the output
DESCRIPTION="--fastx_subsample size annotations are present in output (with --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --sizeout \
        --fastaout - | \
    grep -qw ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample size annotations are present in output (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --fastaout - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## add abundance annotations
DESCRIPTION="--fastx_subsample --relabel no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --fastaout - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --sizeout \
        --fastaout - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_self no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_self \
        --fastaout - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_self --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_self \
        --sizeout \
        --fastaout - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_md5 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_md5 \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_md5 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_sha1 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_sha1 \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_sha1 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## preserve abundance annotations
DESCRIPTION="--fastx_subsample --relabel no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --fastaout - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel --sizeout updates size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel "label" \
        --sizeout \
        --fastaout - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_self no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_self \
        --fastaout - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_self --sizeout updates size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_self \
        --sizeout \
        --fastaout - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_md5 no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_md5 \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_md5 --sizeout updates size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --fastaout - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_sha1 no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_sha1 \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_sha1 --sizeout updates size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --fastaout - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--fastx_subsample --threads is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --threads 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --threads > 1 triggers a warning (not multithreaded)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --threads 2 \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--fastx_subsample --xee is accepted"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --xee \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --xee removes expected error annotations from input"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --xee \
        --sample_size 1 \
        --quiet \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--fastx_subsample --xlength is accepted"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --xlength \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --xlength removes length annotations from input"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --xlength \
        --sample_size 1 \
        --quiet \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --xlength removes length annotations (input), lengthout adds them (output)"
printf ">s;length=2\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --xlength \
        --sample_size 1 \
        --lengthout \
        --quiet \
        --fastaout - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

DESCRIPTION="--fastx_subsample --xsize is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --xsize \
        --sample_size 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --xsize removes abundance annotations from input"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --xsize \
        --sample_size 1 \
        --quiet \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#


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
        --fastx_subsample <(printf "@s;size=100\nA\n+\nI\n") \
        --sample_size 10 \
        --sizein \
        --quiet \
        --sizeout \
        --fastqout /dev/null \
        --fastaout /dev/null \
        --fastqout_discarded /dev/null \
        --fastaout_discarded /dev/null
    DESCRIPTION="--fastx_subsample valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_subsample valgrind (no errors)"
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

# - modify --sample_size so it accepts a value of zero? (nothing in
#   --fastaout or --fastqout)
# - --sample_pct 0.0 output nothing in discarded, update doc to state
#   --'strictly greater than 0.0'
# - --fastq_qmax/qmin have no effect??


exit 0
