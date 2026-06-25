#!/bin/bash -
# shellcheck disable=SC2015

export LC_NUMERIC=C  # use US/EN decimal separator (.)

## Print a header
SCRIPT_NAME="Fixed bugs"
LINE=$(printf "%76s\n" " " | tr " " "-")
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


#******************************************************************************#
#                                                                              #
#                                regressions                                   #
#                                                                              #
#******************************************************************************#

## bugs not listed as GitHub issues

## commit c4b218ffe84134c42732a5cb752391a4fecc3ed2 (Dec 20, 2023)
## - Change causes a segfault in the case the function is called with a
##   nullptr for the hp argument, which may happen when the blast6out
##   and output_no_hits options are used
## - bug was never part of a release
## - fixed with commit 58a05bef0e3714d8aeca24504e061466b23dab8b (Apr 26, 2024)
DESCRIPTION="regression c4b218ffe (segfault)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAA\n") \
    --db <(printf ">t1\nGG\n") \
    --minseqlength 1 \
    --id 0.97 \
    --quiet \
    --blast6out /dev/null \
    --output_no_hits && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## commit f3cf0ff31c394d6ef2886f6f24425e74e0ebfb35 (Jul, 2024) -
## - Change causes a segfault in the function dbindex_getbitmap:
##   comparison of a reference with nullptr called with a nullptr
## - bug was never part of a release
## - fixed with commit 19425392e6644063c081336fe25114e085e7448e (Sep 25, 2024)
DESCRIPTION="regression f3cf0ff31 (segfault)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\nGCTCCTAC\n") \
    --db <(for ((i=1 ; i<=8 ; i+=1)) ; do printf ">s\nGTCGCTCCTA\n" ; done) \
    --minseqlength 8 \
    --id 0.5 \
    --quiet \
    --uc /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                           vsearch forum issues                               #
#                                                                              #
#******************************************************************************#

## OTU Table Labels (Marita White) 2024-06-26
# how to pass sample names to option otutabout?
# - filenames are trunctated to first hyphen when building OTU tables
# - solution is to use ;sample=NAME annotations
DESCRIPTION="forum (2024-06-26): OTU table labels"
SAMPLE1=$(mktemp)
SAMPLE2=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sample "sample1-ITS1-good" \
        --quiet \
        --fastaout "${SAMPLE1}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sample "sample2-ITS1-good" \
        --quiet \
        --fastaout "${SAMPLE2}"

cat "${SAMPLE1}" "${SAMPLE2}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s\nA\n") \
        --minseqlength 1 \
        --id 1.0 \
        --quiet \
        --otutabout - 2> /dev/null | \
    grep -q "sample[12]-ITS1-good" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${SAMPLE1}" "${SAMPLE2}"
unset SAMPLE1 SAMPLE2

# expect:
# #OTU ID	sample1-ITS1-good	sample2-ITS1-good
# s	1	1


#******************************************************************************#
#                                                                              #
#         Improve selection of unique kmers in query (issue 1)                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/1

## not testable


#******************************************************************************#
#                                                                              #
#                        Parallelisation with pthreads                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/2

## cannot test directly if several threads are created
DESCRIPTION="issue 2: parallelization (search_exact accepts --threads)"
"${VSEARCH}" \
    --search_exact <(printf ">q1\nA\n") \
    --db <(printf ">s1\nA\n>s2\nT\n") \
    --threads 2 \
    --quiet \
    --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#     Vectorization of global alignment - single query vs multiple targets     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/3

## vsearch seem to perform only 16-bit SIMD alignment. Compare a
## single query to 8, 16 or 32 targets simultaneously using SIMD
## instructions. Vectorization cannot be tested directly. The goal
## here is to create a toy-dataset that could fill in the 8, 16 or 32
## comparison channels, making sure that vectorization code is
## executed at least once by our test suite.
DESCRIPTION="issue 3: single query vs multiple targets (32 targets)"
q1="AAACAAGAATACCACGACTAGCAGGAGTATCATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA"

${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(for ((i=1 ; i<=32 ; i+=1)) ; do
               printf ">t%d\n%s\n" ${i} "${q1}"
           done) \
    --maxaccepts 32 \
    --id 0.97 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 32 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset Q1


#******************************************************************************#
#                                                                              #
#                        Clustering similar to usearch                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/4

DESCRIPTION="issue 4: Clustering similar to usearch (version 6)"
s1="AAACAAGAATACCACGACTAGCAGGAGTATCATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA"
s2="AAACAAGAATACCACGACTACCAGGAGTATCATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA"
#          substitution ^
s3="TTAAACACCCAAGCAGACGCCGAGGCGGGAATCATGATACTCCTGGTAGTCGTGGTATTCTTGTTT" # s1 revcomp
${VSEARCH} \
    --cluster_size <(printf ">s1\n%s\n>s3\n%s\n>s2\n%s\n" "${s1}" "${s3}" "${s2}") \
    --id 0.97 \
    --quiet \
    --uc - | \
    awk '{a[$1] += 1}
         END {exit (a["C"] == 2 && a["H"] == 1 && a["S"] == 2) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## expect 2 seeds (S), 1 hit (H), and 2 cluster records (C)
# S	0	66	*	*	*	*	*	s1	*
# H	0	66	98.5	+	0	0	66M	s2	s1
# S	1	66	*	*	*	*	*	s3	*
# C	0	2	*	*	*	*	*	s1	*
# C	1	1	*	*	*	*	*	s3	*

unset s1 s2 s3


#******************************************************************************#
#                                                                              #
#                      Performance comparison to usearch                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/5

## not testable


#******************************************************************************#
#                                                                              #
#                               Sequence masking                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/6

## DUST masking method by Tatusov and Lipman (unpublished),
## originaly implemented as a blast module

## --maskfasta default is to mask using DUST
q1="AAACAAGAATACCACGACTAGCAGGAGTATCATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA"
DESCRIPTION="issue 6: sequence masking (no low-complexity region)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" ${q1}) \
    --quiet \
    --output - | \
    grep -qx "${q1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

q1="AAAAAAA"
DESCRIPTION="issue 6: sequence masking (shortest unmasked)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" ${q1}) \
    --quiet \
    --output - | \
    grep -qx "${q1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## DUST masking sets to lowercase
q1="AAAAAAAA"  # minimal length is 8?
q1_lowercase="$(tr "[:upper:]" "[:lower:]" <<< "${q1}")"
DESCRIPTION="issue 6: sequence masking (shortest masked)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" "${q1}") \
    --quiet \
    --output - | \
    grep -qx "${q1_lowercase}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset q1 q1_lowercase

## mix case is converted to uppercase
q1="AaAaAaA"
q1_uppercase="$(tr "[:lower:]" "[:upper:]" <<< "${q1}")"
DESCRIPTION="issue 6: sequence masking (shortest unmasked, mixed case)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" "${q1}") \
    --quiet \
    --output - | \
    grep -qx "${q1_uppercase}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset q1 q1_uppercase

## masked mix case is converted to lowercase
q1="AaAaAaAa"
q1_lowercase="$(tr "[:upper:]" "[:lower:]" <<< "${q1}")"
DESCRIPTION="issue 6: sequence masking (shortest masked, mixed case)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" "${q1}") \
    --quiet \
    --output - | \
    grep -qx "${q1_lowercase}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset q1 q1_lowercase

## "A Fast and Symmetric DUST Implementation to Mask Low-Complexity DNA
## Sequences" by Morgulis et al. (2006) Journal of Computational
## Biology (https://kodomo.fbb.msu.ru/FBB/year_10/ppt/DUST.pdf)

## DUST is asymmetrical

# DUST masks positions 56–64 in the forward sequence and positions 26–64
# in the reverse complement.  SDUST masks positions 26–64 in both
# cases. The subsequence of length 89 was selected so that the portion
# masked by SDUST is centered with 25 unmasked nucleotides on either
# side.

## masked positions:
#  - 56-64 DUST
#  - 26-64 SDUST
#  - 24-64 vsearch's DUST
#  0....5...10...15...20...25...30...35...40...45...50...55...60...65...70...75...80...85...90
#                            |                                     |
##                           taaaacttaaagtataataataataaaattaaaaaaaaa
q1="ACCTGCACATTGTGCACATGTACCCTAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAATGCTACAGTATGACCCCACTCCTGG"
masked_region="taaaacttaaagtataataataataaaattaaaaaaaaa"
DESCRIPTION="issue 6: sequence masking (Morgulis tests: asymmetry #1)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" ${q1}) \
    --quiet \
    --output - | \
    grep -Eqx "[ACGT]+${masked_region}[ACGT]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## masked positions:
#  - 26-64 DUST
#  - 26-64 SDUST
#  - 24-64 vsearch's DUST
#  0....5...10...15...20...25...30...35...40...45...50...55...60...65...70...75...80...85...90
#                          |                                       |
#                          catttttttttaattttattattattatactttaagtttta
# q2 is the reverse-complement of q1
q2="CCAGGAGTGGGGTCATACTGTAGCATTTTTTTTTAATTTTATTATTATTATACTTTAAGTTTTAGGGTACATGTGCACAATGTGCAGGT"
masked_region_rev_comp="catttttttttaattttattattattatactttaagtttta"
DESCRIPTION="issue 6: sequence masking (Morgulis tests: asymmetry #2)"
"${VSEARCH}" \
    --maskfasta <(printf ">q2\n%s\n" ${q2}) \
    --quiet \
    --output - | \
    grep -Eqx "[ACGT]+${masked_region_rev_comp}[ACGT]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## DUST is context-sensitive:

# The second anomaly we sought to correct is that DUST is context
# sensitive. Two sequences may contain an identical low-complexity
# subsequence, but that subsequence may be masked in one and not in the
# other.

# In the first sequence, the run of Ts has two longer runs of As nearby
# on both sides, while in the second sequence the runs of As are changed
# to some high-complexity sequences. DUST masks both runs of As
# (intervals 26–34 and 61–73) but leaves the run of Ts in the first
# sequence unmasked. However, the run of Ts in the second sequence
# (interval 46–52) is masked by DUST. SDUST masks the run of Ts in both
# cases.

## masked positions:
#  - 26–34 and 61–73 DUST
#  - 26–34 and 46-52 and 61–73 SDUST
#  - 26–34 and 61–73 vsearch's DUST
#  0....5...10...15...20...25...30...35...40...45...50...55...60...65...70...75...80...85...90
#                            |       |           |     |        |           |
#   ACCTGCACATTGTGCACATGTACCCaaaaaaaaaGCGCGCGCGCGTTTTTTTACAGTATGaaaaaaaaaaaaaCCCCACTCCTGG
q1="ACCTGCACATTGTGCACATGTACCCAAAAAAAAAGCGCGCGCGCGTTTTTTTACAGTATGAAAAAAAAAAAAACCCCACTCCTGG"
masked_region="ACCTGCACATTGTGCACATGTACCCaaaaaaaaaGCGCGCGCGCGTTTTTTTACAGTATGaaaaaaaaaaaaaCCCCACT"
DESCRIPTION="issue 6: sequence masking (Morgulis tests: context-sensitive #1)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" ${q1}) \
    --quiet \
    --output - | \
    grep -Eqx "${masked_region}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## masked positions:
#  - 46-52 DUST
#  - 46-52 SDUST
#  - none with vsearch's DUST
#  0....5...10...15...20...25...30...35...40...45...50...55...60...65...70...75...80...85...90
#                                                |     |
#   ACCTGCACATTGTGCACATGTACCCACAGTATCCGCGCGCGCGCGTTTTTTTACAGTATGACAGTATGACAGTCCCCACTCCTGG
q2="ACCTGCACATTGTGCACATGTACCCACAGTATCCTGCACATTGGCTTTTTTTACAGTATGACAGTATGACAGTCCCCACTCCTGG"
DESCRIPTION="issue 6: sequence masking (Morgulis tests: context-sensitive #2)"
"${VSEARCH}" \
    --maskfasta <(printf ">q2\n%s\n" ${q2}) \
    --quiet \
    --output - | \
    grep -Eqx "[ACGT]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## if the number of Ts increases (7 -> 10), then the masking of the
## first series of As is lost
# q1="ACCTGCACATTGTGCACATGTACCCAAAAAAAAAGCGCGCGCGCGTTTTTTTTTTACAGTATGAAAAAAAAAAAAACCCCACTCCTGG"
# masked_region="ACCTGCACATTGTGCACATGTACCCAAAAAAAAAGCGCGCGCGCGttttttttttACAGTATGaaaaaaaaaaaaaCCCC"
# DESCRIPTION="issue 6: sequence masking (Morgulis tests: context-sensitive #3)"
# "${VSEARCH}" \
#     --maskfasta <(printf ">q1\n%s\n" ${q1}) \
#     --quiet \
#     --output -

unset q1 q2 masked_region


#******************************************************************************#
#                                                                              #
#                        Implement more accept options                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/7

## test that both --acceptall and --maxaccepts are accepted
DESCRIPTION="issue 7: --acceptall is available"
"${VSEARCH}" \
    --allpairs_global <(printf ">q1\nAAA\n") \
    --acceptall \
    --quiet \
    --alnout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 7: --acceptall forces the output of all pairwise alignment results"
"${VSEARCH}" \
    --allpairs_global <(printf ">q1\nAAA\n>q2\nCCC\n") \
    --acceptall \
    --quiet \
    --alnout - | \
    grep -qw "0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 7: --maxaccepts is available"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --maxaccepts 1 \
    --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 7: --maxaccepts limits the number of matches (2 matches, accepts 2)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAA\n>t2\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --maxaccepts 2 \
    --blast6out - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 7: --maxaccepts limits the number of matches (2 matches, accepts 1)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAA\n>t2\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --maxaccepts 1 \
    --blast6out - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                             Search both strands                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/8

DESCRIPTION="issue 8: search both strands (default is plus/normal strand)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">s1\nA\n>s2\nT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 8: search both strands (explicit plus strand)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">s1\nA\n>s2\nT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --strand plus \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 8: search both strands"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">s1\nA\n>s2\nT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --strand both \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                 Add support for bzipped/gzipped fasta files                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/9

DESCRIPTION="issue 9: read uncompressed file"
TMP=$(mktemp)
printf ">s1\nA\n>s2\nA\n" > "${TMP}"
"${VSEARCH}" \
    --derep_fulllength "${TMP}" \
    --minseqlength 1 \
    --quiet \
    --sizeout \
    --output - | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"

DESCRIPTION="issue 9: read compressed file (gzip)"
TMP=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | gzip -c > "${TMP}"
"${VSEARCH}" \
    --derep_fulllength "${TMP}" \
    --minseqlength 1 \
    --quiet \
    --sizeout \
    --output - | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"

DESCRIPTION="issue 9: read compressed file (bzip2)"
TMP=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | bzip2 -c > "${TMP}"
"${VSEARCH}" \
    --derep_fulllength "${TMP}" \
    --minseqlength 1 \
    --quiet \
    --sizeout \
    --output - | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"
unset TMP

DESCRIPTION="issue 9: read uncompressed stdin"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 9: read compressed stdin (gzip)"
printf ">s1\nA\n>s2\nA\n" | gzip -c | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --gzip_decompress \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 9: read compressed stdin (bzip2)"
printf ">s1\nA\n>s2\nA\n" | bzip2 -c | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --bzip2_decompress \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                         Prioritized features/options                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/10

## planning, not testable


#******************************************************************************#
#                                                                              #
#                                  Clustering                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/11

DESCRIPTION="issue 11: --cluster_fast is implemented"
"${VSEARCH}" \
    --cluster_fast <(printf ">t1\nAAA\n>t2\nAAC\n") \
    --minseqlength 1 \
    --id 0.6 \
    --quiet \
    --sizeout \
    --centroids - | \
    grep -qx ">t1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 11: --cluster_smallmem is implemented"
"${VSEARCH}" \
    --cluster_smallmem <(printf ">t1\nAAA\n>t2\nAAC\n") \
    --minseqlength 1 \
    --id 0.6 \
    --quiet \
    --sizeout \
    --centroids - | \
    grep -qx ">t1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 11: --cluster_size is implemented"
"${VSEARCH}" \
    --cluster_size <(printf ">t1\nAAA\n>t2\nAAC\n") \
    --minseqlength 1 \
    --id 0.6 \
    --quiet \
    --sizeout \
    --centroids - | \
    grep -qx ">t1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## usearch --cluster_otus is deprecated, replaced with uparse
DESCRIPTION="issue 11: --cluster_otus is not implemented"
"${VSEARCH}" \
    --cluster_otus <(printf ">t1\nAAA\n>t2\nAAC\n") \
    --minseqlength 1 \
    --id 0.6 \
    --quiet \
    --sizeout \
    --centroids /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                              Chimera detection                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/12

# simple (simplest?) positive example
DESCRIPTION="issue 12: --uchime_denovo is implemented"
#        1...5...10...15...20...25...30...35
A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"  # shorter does not work
B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
A_END=$(rev <<< ${A_START})
B_END=$(rev <<< ${B_START})
(
    printf ">parentA;size=50\n%s\n" "${A_START}${A_END}"
    printf ">parentB;size=49\n%s\n" "${B_START}${B_END}"
    printf ">chimeraAB;size=1\n%s\n" "${A_START}${B_END}"
) | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --qmask none \
        --quiet \
        --chimeras - | \
    grep -qx ">chimeraAB;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START B_START A_END B_END

# simple (simplest?) positive example
DESCRIPTION="issue 12: --uchime_ref is implemented"
#        1...5...10...15...20...25...30...35
A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"  # shorter does not work
B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
A_END=$(rev <<< ${A_START})
B_END=$(rev <<< ${B_START})
"${VSEARCH}" \
    --uchime_ref <(printf ">chimeraAB\n%s\n" "${A_START}${B_END}") \
    --db <(printf ">parentA\n%s\n" "${A_START}${A_END}"
           printf ">parentB\n%s\n" "${B_START}${B_END}") \
               --qmask none \
               --quiet \
               --chimeras - | \
    grep -qx ">chimeraAB" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START B_START A_END B_END


#******************************************************************************#
#                                                                              #
#                                Documentation                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/13

## call to vsearch outputs basic help (more than 10 lines)
DESCRIPTION="issue 13: vsearch documentation (call to vsearch outputs basic help)"
"${VSEARCH}" 2>&1 | \
    awk 'END {exit NR > 10 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 13: vsearch documentation (state that vsearch --help exists)"
"${VSEARCH}" 2>&1 | \
    grep -Eq "vsearch[^[:blank:]]* --help" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 13: vsearch documentation (state that man vsearch exists)"
"${VSEARCH}" 2>&1 | \
    grep -q "man vsearch" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 13: vsearch documentation (vsearch --help exists)"
"${VSEARCH}" \
    --help 2> /dev/null | \
    awk 'END {exit NR > 10 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 13: vsearch documentation (vsearch --help mentions manpage)"
"${VSEARCH}" \
    --help 2> /dev/null | \
    grep -q "man vsearch" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                                  Manuscript                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/14

## not testable


#******************************************************************************#
#                                                                              #
#                  Support for long (>15 nt) and gapped seeds                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/15

## --slots is ignored (with a warning)
DESCRIPTION="issue 15: --slots is accepted but ignored"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">s1\nA\n") \
    --slots 2801 \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --blast6out /dev/null 2>&1 | \
    grep -q "WARNING" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --pattern is ignored (with a warning)
DESCRIPTION="issue 15: --pattern is accepted but ignored"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">s1\nA\n") \
    --pattern "10111011" \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --blast6out /dev/null 2>&1 | \
    grep -q "WARNING" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --wordlength is accepted (also accepted by --orient and --udb)
DESCRIPTION="issue 15: --wordlength is accepted"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">s1\nA\n") \
    --wordlength 8 \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#      Vectorization of global alignment - single query vs single target       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/16

## not testable (implementation detail)


#******************************************************************************#
#                                                                              #
#        Convert array of top kmer hits into a min heap priority queue         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/17

## not testable (implementation detail)


#******************************************************************************#
#                                                                              #
#                        Fix values of some userfields                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/18

# tlo = 1, tilo = 3 (ignoring terminal gaps)
#         1  4
# target: ACGT--
#           ||
# query:  --GTCA
#           1  4

# raw score is the sum of match rewards minus mismatch penalties, gap
# openings and gap extensions
DESCRIPTION="issue 18: userfield values are correct (raw)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "raw" \
    --userout - | \
    grep -qx "8" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 18: userfield values are correct (qlo)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "qlo" \
    --userout - | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 18: userfield values are correct (qilo)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "qilo" \
    --userout - | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 18: userfield values are correct (qhi)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "qhi" \
    --userout - | \
    grep -qx "4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 18: userfield values are correct (qihi)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "qihi" \
    --userout - | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 18: userfield values are correct (tlo)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "tlo" \
    --userout - | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 18: userfield values are correct (tilo)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "tilo" \
    --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 18: userfield values are correct (thi)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "thi" \
    --userout - | \
    grep -qx "4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 18: userfield values are correct (tihi)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "tihi" \
    --userout - | \
    grep -qx "4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#           Add option to define identity as including terminal gaps           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/19

## iddef:
# 0.  CD-HIT definition: (matching columns) / (shortest sequence length)
# target: AACGT--
#            ||
# query:  ---GTCA
# expect: 2 / 4
DESCRIPTION="issue 19: --iddef is implemented (0)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nAACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "id0" \
    --userout - | \
    grep -qx "50.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 1.  edit distance: (matching columns) / (alignment length)
# target: AACGT--
#            ||
# query:  ---GTCA
# expect: 2 / 7
DESCRIPTION="issue 19: --iddef is implemented (1)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nAACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "id1" \
    --userout - | \
    grep -qx "28.6" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 2.  edit distance excluding terminal gaps (default definition for --id)
# target: AACGT--
#            ||
# query:  ---GTCA
# expect: 2 / 2
DESCRIPTION="issue 19: --iddef is implemented (2)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nAACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "id2" \
    --userout - | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 3.  Marine Biological Lab definition counting each gap opening
#     (internal or terminal) as a single mismatch, whether or not the gap
#     was extended: 1.0 - [(mismatches + gap openings)/(longest sequence
#     length)]
# target: AACGT--
#            ||
# query:  ---GTCA
# expect: 1 - (2 / 5) = 3 / 5
DESCRIPTION="issue 19: --iddef is implemented (3)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nAACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "id3" \
    --userout - | \
    grep -qx "60.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 4.  BLAST definition, equivalent to --iddef 1 for global pairwise alignments
DESCRIPTION="issue 19: --iddef is implemented (4)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nGTCA\n") \
    --db <(printf ">target\nAACGT\n") \
    --minseqlength 4 \
    --id 0.5 \
    --quiet \
    --userfield "id4" \
    --userout - | \
    grep -qx "28.6" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#      Fix number of columns in blast6out output for non-matching queries      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/20

DESCRIPTION="issue 20: --blast6out outputs 12 columns (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    awk '{exit NF == 12 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 20: --blast6out outputs 12 columns (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --blast6out - | \
    awk '{exit NF == 12 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                Consistency with output_no_hits and uc_allhits                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/21

# - alnout, blast6out, userout, uc
# - match or no match
# - with output_no_hits
# - with uc_allhits
# - with both
# (4 + 4) * 4 = 32 tests
#
# ------------------------------------------------------------------ no options
DESCRIPTION="issue 21: --alnout (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --alnout - | \
    grep -qw "^Qry" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --alnout (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --alnout - | \
    grep -qw "^Qry" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 21: --blast6out (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    grep -qw "^query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --blast6out (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 21: --userout (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --userfields query \
    --userout - | \
    grep -qx "query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --userout (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --userfields query \
    --userout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 21: --uc (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc - | \
    grep -qw "H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --uc (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc - | \
    grep -qw "N" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --------------------------------------------------------- with output_no_hits
DESCRIPTION="issue 21: --alnout --output_no_hits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --alnout - | \
    grep -qw "^Qry" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --alnout --output_no_hits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --alnout - | \
    grep -qw "^Qry" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 21: --blast6out --output_no_hits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --blast6out - | \
    grep -qw "^query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --blast6out --output_no_hits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --blast6out - | \
    grep -q "^query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --userout --output_no_hits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --userfields query \
    --userout - | \
    grep -qw "query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --userout --output_no_hits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --userfields query \
    --userout - | \
    grep -qw "query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --uc --output_no_hits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc - | \
    grep -qw "H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --uc --output_no_hits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc - | \
    grep -qw "N" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ------------------------------------------------------------- with uc_allhits
DESCRIPTION="issue 21: --alnout --uc_allhits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc_allhits \
    --alnout - | \
    grep -qw "^Qry" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --alnout --uc_allhits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc_allhits \
    --alnout - | \
    grep -qx "^Qry" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 21: --blast6out --uc_allhits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc_allhits \
    --blast6out - | \
    grep -qw "^query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --blast6out --uc_allhits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc_allhits \
    --blast6out - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 21: --userout --uc_allhits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc_allhits \
    --userfields query \
    --userout - | \
    grep -qw "query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --userout --uc_allhits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc_allhits \
    --userfields query \
    --userout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 21: --uc --uc_allhits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc_allhits \
    --uc - | \
    grep -qw "H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --uc --uc_allhits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --uc_allhits \
    --uc - | \
    grep -qw "N" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ------------------------------------------ with output_no_hits and uc_allhits

DESCRIPTION="issue 21: --alnout --output_no_hits --uc_allhits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc_allhits \
    --alnout - | \
    grep -qw "^Qry" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --alnout --output_no_hits --uc_allhits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc_allhits \
    --alnout - | \
    grep -qw "^Qry" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 21: --blast6out --output_no_hits --uc_allhits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc_allhits \
    --blast6out - | \
    grep -qw "^query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --blast6out --output_no_hits --uc_allhits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc_allhits \
    --blast6out - | \
    grep -qw "^query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --userout --output_no_hits --uc_allhits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc_allhits \
    --userfields query \
    --userout - | \
    grep -qw "query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --userout --output_no_hits --uc_allhits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc_allhits \
    --userfields query \
    --userout - | \
    grep -qw "query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --uc --output_no_hits --uc_allhits (match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGT\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc_allhits \
    --uc - | \
    grep -qw "H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 21: --uc --output_no_hits --uc_allhits (no match)"
"${VSEARCH}" \
    --usearch_global <(printf ">query\nACGT\n") \
    --db <(printf ">target\nACGA\n") \
    --minseqlength 4 \
    --id 1.0 \
    --quiet \
    --output_no_hits \
    --uc_allhits \
    --uc - | \
    grep -qw "N" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                          Segfault in dereplication                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/22

## not testable (not enough details)


#******************************************************************************#
#                                                                              #
#                     do not wrap alignments when rowlen=0                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/23

## default rowlen is 64
DESCRIPTION="issue 23: --rowlen 0 eliminates wrapping (default rowlen)"
#    1...5...10...15...20...25...30...35...40...45...50...55...60...65...70
SEQ="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" ${SEQ}) \
    --db <(printf ">t\n%s\n" ${SEQ}) \
    --id 1.0 \
    --quiet \
    --alnout - | \
    grep "^Qry" | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="issue 23: --rowlen 0 eliminates wrapping (rowlen 0)"
#    1...5...10...15...20...25...30...35...40...45...50...55...60...65...70
SEQ="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" ${SEQ}) \
    --db <(printf ">t\n%s\n" ${SEQ}) \
    --id 1.0 \
    --quiet \
    --rowlen 0 \
    --alnout - | \
    grep "^Qry" | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ


#******************************************************************************#
#                                                                              #
#                    fix for maxaccepts=0 and maxrejects=0                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/24

DESCRIPTION="issue 24: --maxaccepts 1 match by default"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAA\n>t2\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 24: --maxaccepts limits the number of matches (2 matches, accepts 1)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAA\n>t2\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --maxaccepts 1 \
    --blast6out - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 24: --maxaccepts 0 removes the limit on the number of matches"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAA\n>t2\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --maxaccepts 0 \
    --blast6out - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 24: --maxrejects breaks after 32 bad matches (by default)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(for ((i=1 ; i<=32 ; i+=1)) ; do printf ">t%d\nAAT\n" ${i} ; done ; printf ">t33\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 24: --maxrejects accepts hits after 31 bad matches (by default)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(for ((i=1 ; i<=31 ; i+=1)) ; do printf ">t%d\nAAT\n" ${i} ; done ; printf ">t33\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 24: --maxrejects 1 breaks after 1 bad match"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAT\n>t2\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --maxrejects 1 \
    --blast6out - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 24: --maxrejects 2 breaks after 2 bad matches (2nd target is tested and accepted)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAT\n>t2\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --maxrejects 2 \
    --blast6out - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 24: --maxrejects 0 scans all targets until --maxaccepts is fulfilled"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAT\n>t2\nAAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --maxrejects 0 \
    --blast6out - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#              Implement --cons_truncate clustering output option              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/25

## --msaout, --consout and --cons_truncate

DESCRIPTION="issue 25: --cluster_fast accepts --msaout"
"${VSEARCH}" \
    --cluster_fast <(printf ">q1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --msaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 25: --cluster_fast accepts --consout"
"${VSEARCH}" \
    --cluster_fast <(printf ">q1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 25: --cluster_fast --cons_truncate is not implemented"
"${VSEARCH}" \
    --cluster_fast <(printf ">q1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --cons_truncate /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# Note: msaout and consout outputs are tested in later issues


#******************************************************************************#
#                                                                              #
#                            Minor bug in Makefile                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/26

## not testable (compilation issue)


#******************************************************************************#
#                                                                              #
#                  Shuffling not random on unix with --seed 0                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/27

DESCRIPTION="issue 27: --shuffle --randseed seed always gives the same results"
RUN1=$("${VSEARCH}" \
           --shuffle <(printf ">s1\nA\n>s2\nT\n") \
           --randseed 1 \
           --quiet \
           --output - | \
           md5sum -)
RUN2=$("${VSEARCH}" \
           --shuffle <(printf ">s1\nA\n>s2\nT\n") \
           --randseed 1 \
           --quiet \
           --output - | \
           md5sum -)
[[ "${RUN1}" = "${RUN2}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset RUN1 RUN2

DESCRIPTION="issue 27: --shuffle --randseed 0 to use a PRNG seed"
"${VSEARCH}" \
    --shuffle <(printf ">s1\nA\n>s2\nT\n") \
    --randseed 0 \
    --quiet \
    --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#When sorting, the --minsize and --maxsize options don't work (no change in the#
#                                    output)                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/28

# Fasta entries are sorted by sequence length (--sortbylength). To
# obtain a stable sorting order, ties are sorted by decreasing
# abundance (if present) and label increasing alpha-numerical order
# (--sortbylength). Label sorting assumes that all sequences have
# unique labels.

# (see sortbysize.sh for corresponding tests)

## --------------------------------------------------------------- sortbylength
DESCRIPTION="issue 28: --sortbylength sorts by decreasing sequence length"
"${VSEARCH}" \
    --sortbylength <(printf ">s1\nA\n>s2\nTT\n") \
    --quiet \
    --output - | \
    head -n 1 | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength sorts ties by decreasing abundance"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=1\nAA\n>s2;size=2\nTT\n") \
    --quiet \
    --sizein \
    --output - | \
    head -n 1 | \
    grep -qx ">s2;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength sorts ties by decreasing abundance (--sizein is implied)"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=1\nAA\n>s2;size=2\nTT\n") \
    --quiet \
    --output - | \
    head -n 1 | \
    grep -qx ">s2;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength sorts ties by decreasing abundance (if abundance is present)"
"${VSEARCH}" \
    --sortbylength <(printf ">s1\nTT\n>s2\nAA\n") \
    --quiet \
    --output - | \
    head -n 1 | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength sorts ties by increasing label"
"${VSEARCH}" \
    --sortbylength <(printf ">s2\nAA\n>s1\nTT\n") \
    --quiet \
    --output - | \
    head -n 1 | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note: sequence order is not used to break ties
DESCRIPTION="issue 28: --sortbylength sorts ties by increasing label (assume unique labels)"
"${VSEARCH}" \
    --sortbylength <(printf ">s1\nTT\n>s1\nAA\n") \
    --quiet \
    --output - | \
    head -n 2 | \
    grep -qx "TT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength does not accept --minsize"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=1\nAA\n>s2;size=3\nAA\n") \
    --quiet \
    --minsize 2 \
    --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength does not accept --maxsize"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=3\nAA\n>s2;size=1\nAA\n") \
    --quiet \
    --maxsize 2 \
    --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                    maxuniquesize option for dereplication                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/29

## Note: sizein is not required

## -------------------------------------------------------------- minuniquesize
DESCRIPTION="issue 29: --derep_fulllength accepts --minuniquesize"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --minuniquesize 1 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 29: --derep_fulllength --minuniquesize discards abundances lesser than value (>)"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n>s2\nA\n>s3\nA\n") \
    --minseqlength 1 \
    --quiet \
    --minuniquesize 2 \
    --output - | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 29: --derep_fulllength --minuniquesize discards abundances lesser than value (=)"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n>s2\nA\n") \
    --minseqlength 1 \
    --quiet \
    --minuniquesize 2 \
    --output - | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 29: --derep_fulllength --minuniquesize discards abundances lesser than value (<)"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --minuniquesize 2 \
    --output - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------- maxuniquesize
DESCRIPTION="issue 29: --derep_fulllength accepts --maxuniquesize"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --maxuniquesize 1 \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 29: --derep_fulllength --maxuniquesize discards abundances greater than value (>)"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n>s2\nA\n>s3\nA\n") \
    --minseqlength 1 \
    --quiet \
    --maxuniquesize 2 \
    --output - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 29: --derep_fulllength --maxuniquesize discards abundances greater than value (=)"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n>s2\nA\n") \
    --minseqlength 1 \
    --quiet \
    --maxuniquesize 2 \
    --output - | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 29: --derep_fulllength --maxuniquesize discards abundances greater than value (<)"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --maxuniquesize 2 \
    --output - | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                                Bug in masking                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/30

DESCRIPTION="issue 30: --maskfasta (should not discard sequences)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaa\n>s2\naaaaaaaaaa\n") \
    --quiet \
    --output - | \
    awk '/^>/ {counter += 1} END {exit counter == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none (should not discard sequences)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaa\n>s2\naaaaaaaaaa\n") \
    --quiet \
    --qmask none \
    --output - | \
    awk '/^>/ {counter += 1} END {exit counter == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft (should not discard sequences)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaa\n>s2\naaaaaaaaaa\n") \
    --quiet \
    --qmask soft \
    --output - | \
    awk '/^>/ {counter += 1} END {exit counter == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust (should not discard sequences)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaa\n>s2\naaaaaaaaaa\n") \
    --quiet \
    --qmask dust \
    --output - | \
    awk '/^>/ {counter += 1} END {exit counter == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------- sequence masking
# 1	nohardmask,defaultmasking,lowercase,complex
# 2	nohardmask,defaultmasking,lowercase,monotonous
# 3	nohardmask,defaultmasking,uppercase,complex
# 4	nohardmask,defaultmasking,uppercase,monotonous
DESCRIPTION="issue 30: --maskfasta (lowercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nacgtacgtacgt\n") \
    --quiet \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --output - | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta (upppercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --output - | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 5	nohardmask,none,lowercase,complex
# 6	nohardmask,none,lowercase,monotonous
# 7	nohardmask,none,uppercase,complex
# 8	nohardmask,none,uppercase,monotonous
DESCRIPTION="issue 30: --maskfasta --qmask none (lowercase, complex -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nacgtacgtacgt\n") \
    --quiet \
    --qmask none \
    --output - | \
    grep -qx "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask none \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask none \
    --output - | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none (upppercase, monotonous -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask none \
    --output - | \
    grep -qx "AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 9	nohardmask,soft,lowercase,complex
# 10	nohardmask,soft,lowercase,monotonous
# 11	nohardmask,soft,uppercase,complex
# 12	nohardmask,soft,uppercase,monotonous
DESCRIPTION="issue 30: --maskfasta --qmask soft (lowercase, complex -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nacgtacgtacgt\n") \
    --quiet \
    --qmask soft \
    --output - | \
    grep -qx "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask soft \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask soft \
    --output - | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft (upppercase, monotonous -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask soft \
    --output - | \
    grep -qx "AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 13	nohardmask,dust,lowercase,complex
# 14	nohardmask,dust,lowercase,monotonous
# 15	nohardmask,dust,uppercase,complex
# 16	nohardmask,dust,uppercase,monotonous
DESCRIPTION="issue 30: --maskfasta --qmask dust (lowercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nacgtacgtacgt\n") \
    --quiet \
    --qmask dust \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask dust \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask dust \
    --output - | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust (upppercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask dust \
    --output - | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 17	hardmask,defaultmasking,lowercase,complex
# 18	hardmask,defaultmasking,lowercase,monotonous
# 19	hardmask,defaultmasking,uppercase,complex
# 20	hardmask,defaultmasking,uppercase,monotonous
DESCRIPTION="issue 30: --maskfasta --hardmask (lowercase, complex -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nacgtacgtacgt\n") \
    --quiet \
    --hardmask \
    --output - | \
    grep -qx "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --hardmask (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --hardmask \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --hardmask (lowercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --hardmask \
    --output - | \
    grep -qx "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --hardmask (upppercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --hardmask \
    --output - | \
    grep -qx "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 21	hardmask,none,lowercase,complex
# 22	hardmask,none,lowercase,monotonous
# 23	hardmask,none,uppercase,complex
# 24	hardmask,none,uppercase,monotonous
DESCRIPTION="issue 30: --maskfasta --qmask none --hardmask (lowercase, complex -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nacgtacgtacgt\n") \
    --quiet \
    --qmask none \
    --hardmask \
    --output - | \
    grep -qx "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none --hardmask (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask none \
    --hardmask \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none --hardmask (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask none \
    --hardmask \
    --output - | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none --hardmask (upppercase, monotonous -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask none \
    --hardmask \
    --output - | \
    grep -qx "AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 25	hardmask,soft,lowercase,complex
# 26	hardmask,soft,lowercase,monotonous
# 27	hardmask,soft,uppercase,complex
# 28	hardmask,soft,uppercase,monotonous
DESCRIPTION="issue 30: --maskfasta --qmask soft --hardmask (lowercase, complex -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nacgtacgtacgt\n") \
    --quiet \
    --qmask soft \
    --hardmask \
    --output - | \
    grep -qx "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft --hardmask (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask soft \
    --hardmask \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft --hardmask (lowercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask soft \
    --hardmask \
    --output - | \
    grep -qx "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft --hardmask (upppercase, monotonous -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask soft \
    --hardmask \
    --output - | \
    grep -qx "AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 29	hardmask,dust,lowercase,complex
# 30	hardmask,dust,lowercase,monotonous
# 31	hardmask,dust,uppercase,complex
# 32	hardmask,dust,uppercase,monotonous
DESCRIPTION="issue 30: --maskfasta --qmask dust --hardmask (lowercase, complex -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nacgtacgtacgt\n") \
    --quiet \
    --qmask dust \
    --hardmask \
    --output - | \
    grep -qx "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust --hardmask (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask dust \
    --hardmask \
    --output - | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust --hardmask (lowercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask dust \
    --hardmask \
    --output - | \
    grep -qx "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust --hardmask (upppercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask dust \
    --hardmask \
    --output - | \
    grep -qx "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#   Difference between --blast6out and --userout for evalue and bits fields    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/31

## 11th field. evalue: expectancy-value (not computed for nucleotide
## alignments). Always set to -1.
DESCRIPTION="issue 31: --blast6out evalue is set to -1"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --blast6out - | \
    awk '{exit $11 == -1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 31: --userout evalue is set to -1"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --userfields evalue \
    --userout - | \
    awk '{exit $1 == -1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## 12th field. bits: bit score (not computed for nucleotide
## alignments). Always set to 0.
DESCRIPTION="issue 31: --blast6out bits is set to 0"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --blast6out - | \
    awk '{exit $12 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 31: --userout bits is set to -1"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --userfields bits \
    --userout - | \
    awk '{exit $1 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
# When searching a database against itself, sequence labels are not truncated  #
#                                   correctly                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/32

DESCRIPTION="issue 32: --usearch_global query headers are truncated at first space"
${VSEARCH} \
    --usearch_global <(printf ">q1 junk\nA\n") \
    --db <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --userfields query \
    --userout - | \
    awk 'BEGIN {FS = "\t"} {exit $1 == "q1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 32: --usearch_global query headers are truncated at first space (#2)"
${VSEARCH} \
    --usearch_global <(printf ">q1 junk junk2\nA\n") \
    --db <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --userfields query \
    --userout - | \
    awk 'BEGIN {FS = "\t"} {exit $1 == "q1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 32: --usearch_global target headers are truncated at first space"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1 junk\nA\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --userfields target \
    --userout - | \
    awk 'BEGIN {FS = "\t"} {exit $1 == "t1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 32: --usearch_global target headers are truncated at first space (#2)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1 junk junk2\nA\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --userfields target \
    --userout - | \
    awk 'BEGIN {FS = "\t"} {exit $1 == "t1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#          Difference between --blast6out and --userout for id field           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/33

## 3rd field. id: percentage of identity (real value ranging from 0.0 to 100.0)
DESCRIPTION="issue 33: --blast6out id is set to 0.0 when there is no alignment"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1\nT\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --output_no_hits \
    --blast6out - | \
    awk '{exit $3 == "0.0" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 33: --userout id is set to 0.0 when there is no alignment"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1\nT\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --output_no_hits \
    --userfields id \
    --userout - | \
    awk '{exit $1 == "0.0" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#           Speed-up searching when using the --top_hits_only option           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/34

DESCRIPTION="issue 34: --usearch_global returns multiple hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAC\n>t2\nAAG\n>t3\nAAA\n") \
    --minseqlength 3 \
    --maxaccepts 0 \
    --quiet \
    --id 0.6 \
    --blast6out - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 34: --usearch_global --top_hits_only returns best hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAC\n>t2\nAAG\n>t3\nAAA\n") \
    --minseqlength 3 \
    --maxaccepts 0 \
    --quiet \
    --id 0.6 \
    --top_hits_only \
    --blast6out - | \
    awk 'END {exit $2 == "t3" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#       Should T and U be considered as identical during dereplication?        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/35

DESCRIPTION="issue 35: --derep_fulllength treats T and U as identical (U first)"
${VSEARCH} \
    --derep_fulllength <(printf ">s1\nU\n>s2\nT\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -qw ">s1U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_fulllength treats T and U as identical (T first)"
${VSEARCH} \
    --derep_fulllength <(printf ">s1\nT\n>s2\nU\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -qw ">s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_id treats T and U as identical (U first)"
${VSEARCH} \
    --derep_id <(printf ">s1\nU\n>s2\nT\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -qw ">s1U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_id treats T and U as identical (T first)"
${VSEARCH} \
    --derep_id <(printf ">s1\nT\n>s2\nU\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -qw ">s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_prefix treats T and U as identical (U first)"
${VSEARCH} \
    --derep_prefix <(printf ">s1\nU\n>s2\nT\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -qw ">s1U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_prefix treats T and U as identical (T first)"
${VSEARCH} \
    --derep_prefix <(printf ">s1\nT\n>s2\nU\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -qw ">s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --fastx_uniques treats T and U as identical (U first)"
${VSEARCH} \
    --fastx_uniques <(printf ">s1\nU\n>s2\nT\n") \
    --minseqlength 1 \
    --quiet \
    --fastaout - | \
    tr -d "\n" | \
    grep -qw ">s1U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --fastx_uniques treats T and U as identical (T first)"
${VSEARCH} \
    --fastx_uniques <(printf ">s1\nT\n>s2\nU\n") \
    --minseqlength 1 \
    --quiet \
    --fastaout - | \
    tr -d "\n" | \
    grep -qw ">s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## tested in derep_smallmem.sh


#******************************************************************************#
#                                                                              #
#              Support for --sizein and --sizeout when clustering              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/36

DESCRIPTION="issue 36: --cluster_fast --centroids"
${VSEARCH} \
    --cluster_fast <(printf ">s1\nA\n>s2\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note the absence of a semi-colon at the end (added in version 1.0.1,
# removed some time later)
DESCRIPTION="issue 36: --cluster_fast --centroids --sizeout"
${VSEARCH} \
    --cluster_fast <(printf ">s1\nA\n>s2\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=2A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 36: --cluster_fast --centroids --sizein"
${VSEARCH} \
    --cluster_fast <(printf ">s1;size=2\nA\n>s2;size=1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --sizein \
    --quiet \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=2A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 36: --cluster_fast --centroids --sizeout (size annotation in)"
${VSEARCH} \
    --cluster_fast <(printf ">s1;size=2\nA\n>s2;size=1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=3A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 36: --usearch_global --dbmatched"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --dbmatched - | \
    tr -d "\n" | \
    grep -qx ">t1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 36: --usearch_global --dbmatched --sizeout"
${VSEARCH} \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizeout \
    --dbmatched - | \
    tr -d "\n" | \
    grep -qx ">t1;size=1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#      Check if illegal options are specified for the different commands       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/37

# - unknown option
# - known but not applicable
# - allowed but has no effect (silent)
# - threads > 1 (warning)

DESCRIPTION="issue 37: --fasta2fastq (no illegal option)"
${VSEARCH} \
    --fasta2fastq <(printf ">s1\nA\n") \
    --quiet \
    --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 37: --fasta2fastq (unknown option)"
${VSEARCH} \
    --fasta2fastq <(printf ">s1\nA\n") \
    --unknown_option \
    --quiet \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 37: --fasta2fastq (illegal option)"
${VSEARCH} \
    --fasta2fastq <(printf ">s1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 37: --fasta2fastq (allowed option)"
${VSEARCH} \
    --fasta2fastq <(printf ">s1\nA\n") \
    --threads 1 \
    --quiet \
    --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 37: --fasta2fastq (allowed option with warning)"
${VSEARCH} \
    --fasta2fastq <(printf ">s1\nA\n") \
    --threads 2 \
    --quiet \
    --fastqout /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#               Stable sorting to avoid input-order dependencies               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/38

# stable sort implemented in:
# - sortbysize (size, label, original order),
# - sortbylength (length, size, label, original order),
# - derep_fulllength (size, label, original order),
# - cluster_fast (length, size, label, original order),
# - uchime_denovo (size, label, original order)
#
# (see corresponding test scripts)


#******************************************************************************#
#                                                                              #
# Support for reading from / writing to pipes (input from stdin and output to  #
#                                    stdout)                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/39

# - reading from stdin and compressed stdin has already been tested in issue 9
# - writing to stdout has already been tested in issue 2


#******************************************************************************#
#                                                                              #
#                         Automatic regression testing                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/40

# not testable


#******************************************************************************#
#                                                                              #
#                              Bug in sortbysize                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/41

# not enough details to be tested


#******************************************************************************#
#                                                                              #
#                     Add support for amino acid sequences                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/42

# not implemented yet
# DESCRIPTION="issue 42: --usearch_global accepts amino-acid sequences"
# ${VSEARCH} \
#     --usearch_global <(printf ">q1\nARNDCEQGHILKMFPSTWYV\n") \
#     -db <(printf ">t1\nARNDCEQGHILKMFPSTWYV\n") \
#     --id 1.0 \
#     --quiet \
#     --blast6out /dev/null && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                                     API                                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/43

# cython API for core-functionalities: noy implemented


#******************************************************************************#
#                                                                              #
#             add usearch's fastq_mergepairs function and options              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/44

DESCRIPTION="issue 44: --fastq_mergepairs is implemented"
${VSEARCH} \
    --fastq_mergepairs <(printf "@s\nAAATAAAAAA\n+\nIIIIIIIIII\n") \
    --reverse <(printf "@s\nTTTTTTATTT\n+\nIIIIIIIIII\n") \
    --quiet \
    --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                    Illegal instruction fault on some cpus                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/45

# not testable


#******************************************************************************#
#                                                                              #
#                            Write --help to stdout                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/46

DESCRIPTION="issue 46: --help writes to stdout"
"${VSEARCH}" \
    --help 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 46: --help is cancelled by --quiet"
"${VSEARCH}" \
    --help \
    --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                            allpairs_global option                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/47

DESCRIPTION="issue 47: --allpairs_global is implemented (--id)"
${VSEARCH} \
    --allpairs_global <(printf ">s1\nA\n>s2\nA\n") \
    --quiet \
    --id 1.0 \
    --blast6out - | \
    grep -q "^s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 47: --allpairs_global is implemented (--acceptall)"
${VSEARCH} \
    --allpairs_global <(printf ">s1\nA\n>s2\nA\n") \
    --quiet \
    --acceptall \
    --blast6out - | \
    grep -q "^s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                         Reference Chimera checking.                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/48

# insufficient memory allocated for the alignment sequences (vsearch v1.0.5)
# (data from https://github.com/jooolia/testing_vsearch)
DESCRIPTION="issue 48: --uchime_ref insufficient memory allocated (double free)"
TMP_QUERY=$(mktemp)
(printf ">query\n"
 printf "AGAGAAAGTATGGCCAGTACACCTTTTCCAATTCCAAGTTGTTTGGCTTTTTGAATAAGGCGCTACATTCCTCAGCCGCT"
 printf "CGTTCACCCACTTCCCAGCTGTACTTGACAGCTTCTTCACCTGTTCGTCCCCCAACATCAAACTCAACCATCACAGAATC"
 printf "CGTGTCACCATACCGCACCTTTGCACCTGGAAAGTTCGCCTCTACATATGTCTTTGTCTCTTCAATCATACCCCGACCCC"
 printf "GACATGTTGTC\n"
) > "${TMP_QUERY}"
TMP_DB=$(mktemp)
(printf ">reference\n"
 printf "ATGACTGACATCACGATTTTCCCGACGGATTGGCGTTGTGAGGACGTTATTCCTGACAAGGGTGAATCAT"
 printf "TCTTCAGGATAAACATATTCGGAAAGACCGCTGAAGGAAAGACGGTGTGTGTTCAAACAAAATTCACACC"
 printf "ATACTTTCTTCTAGAAGTTCCGGAATCGTGGAGTCCTGCACGAACAAATCTTTTTATCACGGAAACCGCT"
 printf "AGAGAAAGTATGGCCAGTACACCTTTTCCAATTCCAAGTTGTTTGGCTTTTTGAATAAGGCGCTACATTCCTCAGCCGCT"
 printf "CGTTCACCCACTTCCCAGCTGTACTTGACAGCTTCTTCACCTGTTCGTCCCCCAACATCAAACTCAACCATCACAGAATC"
 printf "ATGAAATACGACGCAATTCGTCCCATGTGTTTGTCTACAAAACGCAAGAATATGTGGGGTTTTGACGGAG"
 printf "GGAAGATGCGGAATATGGTTCAGTTTGTGTTCAAGACGCAGGCGCAACTGAGGAAGGCAAAATACAGGCT"
 printf "GAAGGATCAGTATCAGATTTACGAGTCGTCTGTTGACCCGATTATTCGTGTGTTTCATCTAAGGAATATC"
 printf "AACCCCGCAGATTGGATTCGAGTTTCGAAGGCGTACCCCGCGCAGACACGTATTTCCAATTCGGATATCG"
 printf "AAGTCGAGACATCCTTTCAACATTTGGGACCTGTTGACGACAAGACAGTTCCTCCACTGGTGATCGCGAG"
 printf "TTGGGATATTGAAACTTATAGTAAAGATCGTAAGTTTCCGCTTGCTGAAAATCCAACGGATTATTGTATC"
 printf "CAAATCGCAACGACTTTTCAGAAGTATGGTGAGCCGGAGCCATACAGGCGTGTTGTGGTTTGTTACAAGC"
 printf "AAACTGCACCGGTAGAAGGCGTCGAAATCATCAGTTGTCTCGAAGAATCGGACGTGATGAACACCTGGAT"
 printf "GAAGATTCTTCAGGATGAAAAGACCGATGTGTCTATCGGATACAACACGTGGCAGTACGATCTTCGGTAT"
 printf "GTTCACGGTAGGACTCAGATGTGTGTGGATGATATGACTGGGGAGGATAAGGTAAAATTGAGTAATCTTG"
 printf "GTCGTCTTCTTTCCGGCGGTGGCGAAGTGGTTGAGCGTGATTTGAGTTCCAACGCTTTTGGTCAGAACAA"
 printf "\n"
) > "${TMP_DB}"
${VSEARCH} \
    --uchime_ref "${TMP_QUERY}" \
        --db "${TMP_DB}" \
        --uchimeout /dev/null > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 48: --uchime_ref insufficient memory allocated (free invalid pointer)"
(printf ">reference\n"
 printf "ATGACTGACATCACGATTTTCCCGACGGATTGGCGTTGTGAGGACGTTATTCCTGACAAGGGTGAATCAT"
 printf "TCTTCAGGATAAACATATTCGGAAAGACCGCTGAAGGAAAGACGGTGTGTGTTCAAACAAAATTCACACC"
 printf "ATACTTTCTTCTAGAAGTTCCGGAATCGTGGAGTCCTGCACGAACAAATCTTTTTATCACGGAAACCGCT"
 printf "AGAGAAAGTATGGCCAGTACACCTTTTCCAATTCCAAGTTGTTTGGCTTTTTGAATAAGGCGCTACATTCCTCAGCCGCT"
 printf "CGTTCACCCACTTCCCAGCTGTACTTGACAGCTTCTTCACCTGTTCGTCCCCCAACATCAAACTCAACCATCACAGAATC"
 printf "ATGAAATACGACGCAATTCGTCCCATGTGTTTGTCTACAAAACGCAAGAATATGTGGGGTTTTGACGGAG"
 printf "GGAAGATGCGGAATATGGTTCAGTTTGTGTTCAAGACGCAGGCGCAACTGAGGAAGGCAAAATACAGGCT"
 printf "GAAGGATCAGTATCAGATTTACGAGTCGTCTGTTGACCCGATTATTCGTGTGTTTCATCTAAGGAATATC"
 printf "AACCCCGCAGATTGGATTCGAGTTTCGAAGGCGTACCCCGCGCAGACACGTATTTCCAATTCGGATATCG"
 printf "AAGTCGAGACATCCTTTCAACATTTGGGACCTGTTGACGACAAGACAGTTCCTCCACTGGTGATCGCGAG"
 printf "TTGGGATATTGAAACTTATAGTAAAGATCGTAAGTTTCCGCTTGCTGAAAATCCAACGGATTATTGTATC"
 printf "CAAATCGCAACGACTTTTCAGAAGTATGGTGAGCCGGAGCCATACAGGCGTGTTGTGGTTTGTTACAAGC"
 printf "AAACTGCACCGGTAGAAGGCGTCGAAATCATCAGTTGTCTCGAAGAATCGGACGTGATGAACACCTGGAT"
 printf "GAAGATTCTTCAGGATGAAAAGACCGATGTGTCTATCGGATACAACACGTGGCAGTACGATCTTCGGTAT"
 printf "GTTCACGGTAGGACTCAGATGTGTGTGGATGATATGACTGGGGAGGATAAGGTAAAATTGAGTAATCTTG"
 printf "\n"
) > "${TMP_DB}"
${VSEARCH} \
    --uchime_ref "${TMP_QUERY}" \
        --db "${TMP_DB}" \
        --uchimeout /dev/null > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

rm -f "${TMP_DB}" "${TMP_QUERY}"
unset TMP_DB TMP_QUERY


#******************************************************************************#
#                                                                              #
#             Add --log option to uchime_ref (and other commands?)             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/49

# global option, test on --cut rather than --uchime_ref
DESCRIPTION="issue 49: --cut --log is accepted"
${VSEARCH} \
    --cut <(printf ">s\nACGT\n") \
    --cut_pattern "^GT_" \
    --quiet \
    --fastaout /dev/null \
    --log /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 49: --cut --log is not empty"
${VSEARCH} \
    --cut <(printf ">s\nACGT\n") \
    --cut_pattern "^GT_" \
    --quiet \
    --fastaout /dev/null \
    --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                              Add --quiet option                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/50

# When this option is in effect only errors or warnings are printed to stderr
DESCRIPTION="issue 50: --cut (messages on stderr)"
${VSEARCH} \
    --cut <(printf ">s\nACGT\n") \
    --cut_pattern "^GT_" \
    --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 50: --cut --quiet (nothing on stderr)"
${VSEARCH} \
    --cut <(printf ">s\nACGT\n") \
    --cut_pattern "^GT_" \
    --quiet \
    --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 50: --cut --quiet (warning on stderr)"
${VSEARCH} \
    --cut <(printf ">s\nACGT\n") \
    --cut_pattern "^GT_" \
    --quiet \
    --top_hits_only \
    --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#         Reduce memory requirements for aligning very long sequences          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/51

# not testable


#******************************************************************************#
#                                                                              #
#                Handle alignments of long sequences correctly                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/52

# not testable (test would require a large amount of memory)


#******************************************************************************#
#                                                                              #
#     Incorrect output from chimera detection with the --uchimeout option      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/53

# --uchime_denovo outputs extra lines with score 0.0000 to the file
# specified with the --uchimeout option for some non-chimeric
# sequences
# (unable to reproduce the bug with v1.0.6)
DESCRIPTION="issue 53: --uchime_denovo --uchimeout extra lines"
#        1...5...10...15...20...25...30...35
A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"
B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
A_END=$(rev <<< ${A_START})
B_END=$(rev <<< ${B_START})
TMP=$(mktemp)
(
    printf ">parentA;size=50\n%s\n" "${A_START}${A_END}"
    printf ">parentB;size=49\n%s\n" "${B_START}${B_END}"
    printf ">nonchimeraA;size=1\n%s\n" "${A_START}${A_END}"
) > "${TMP}"
${VSEARCH} \
    --uchime_denovo "${TMP}" \
    --uchimeout /dev/stdout 2> /dev/null | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset A_START B_START A_END B_END TMP


#******************************************************************************#
#                                                                              #
#                  blast6out subject and query hit location.                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/54

# The userfields qlo, qhi, tlo and thi now contain the start and end of
# the query and target sequences. So tlo will always be 1 and thi will
# always be equal to the length of the target. Unless the matching is on
# the reverse strand qlo will always be 1 and qhi will always be equal
# to the length of the query. If the match is on the reverse strand, qhi
# will be 1 and qlo will be equal to length of the query.

# The new qilo, qihi, tilo, and tihi userfields will contain the
# coordinates of the alignment ignoring terminal gaps (like qlo, qhi,
# tlo and thi was previously).

# (assuming that only the query is reverse-complemented)

DESCRIPTION="issue 54: --usearch_global --userout qlo (always 1)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAA\n") \
    --db <(printf ">t1\nAAA\n") \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields qlo \
    --userout - | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout qlo (= qlen if reversed)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nTTT\n") \
    --strand both \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields qlo \
    --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout qilo (first aligned position in the query)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nTTAA\n") \
    --db <(printf ">t1\nAA\n") \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields qilo \
    --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Qry 3 - TTT 1
#         |||
# Tgt 1 + TTT 3
DESCRIPTION="issue 54: --usearch_global --userout qilo (first aligned position in the reversed query)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAAG\n") \
    --db <(printf ">t1\nTTT\n") \
    --strand both \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --alnout - \
    --userfields qilo \
    --userout - | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout qhi (= qlen)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAA\n") \
    --db <(printf ">t1\nAAA\n") \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields qhi \
    --userout - | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout qhi (always 1 if reversed)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nTTT\n") \
    --strand both \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields qhi \
    --userout - | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout qihi (!= qlen)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAAG\n") \
    --db <(printf ">t1\nAAA\n") \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields qihi \
    --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout qihi (last aligned position in the reversed query)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nGAAAG\n") \
    --db <(printf ">t1\nTTT\n") \
    --strand both \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --alnout - \
    --userfields qihi \
    --userout - | \
    grep -qx "4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout tlo (always 1)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAA\n") \
    --db <(printf ">t1\nAAA\n") \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields tlo \
    --userout - | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout tlo (always 1 if reversed)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nTTT\n") \
    --strand both \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields tlo \
    --userout - | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout tilo (first aligned position in the target = 3)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAA\n") \
    --db <(printf ">t1\nTTAA\n") \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields tilo \
    --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout tilo (first aligned position in the target = 1)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAAG\n") \
    --db <(printf ">t1\nTTT\n") \
    --strand both \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --alnout - \
    --userfields tilo \
    --userout - | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout thi (= tlen = 2)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAA\n") \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields thi \
    --userout - | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout thi (= tlen = 3)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nTTT\n") \
    --strand both \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields thi \
    --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout tihi (!= tlen)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAA\n") \
    --db <(printf ">t1\nAAAG\n") \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --userfields tihi \
    --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 54: --usearch_global --userout tihi (last aligned position in the target)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nTTT\n") \
    --db <(printf ">t1\nGAAAG\n") \
    --strand both \
    --minseqlength 2 \
    --id 0.5 \
    --quiet \
    --alnout - \
    --userfields tihi \
    --userout - | \
    grep -qx "4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                     Option to output in SAM format file                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/55

DESCRIPTION="issue 55: --search_exact accepts --samout"
${VSEARCH} \
    --search_exact <(printf ">q1\nT\n") \
    --db <(printf ">t1\nT\n") \
    --quiet \
    --samout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 55: --search_exact --samout outputs data"
${VSEARCH} \
    --search_exact <(printf ">q1\nT\n") \
    --db <(printf ">t1\nT\n") \
    --quiet \
    --samout - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                           Documentation - git link                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/56

# not testable


#******************************************************************************#
#                                                                              #
#     Use "=" to indicate perfect alignment in column 8 of UC output file      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/57

DESCRIPTION="issue 57: --search_exact --uc column 8 is always = (equal sign)"
${VSEARCH} \
    --search_exact <(printf ">q1\nT\n") \
    --db <(printf ">t1\nT\n") \
    --quiet \
    --uc - | \
    awk '{exit $8 == "=" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                      Add a "cluster_abundance" command                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/58

# already tested (issue 11)


#******************************************************************************#
#                                                                              #
#                     Improve help message for clustering                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/59

# not testable


#******************************************************************************#
#                                                                              #
#                 Single Makefile, Autotools and smaller repo                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/60

# not testable


#******************************************************************************#
#                                                                              #
#  cluster_fast should sort by length first, then by abundance and finally by  #
#                              sequence identifier                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/61

# sortbylength (already tested in issue 28)

## --------------------------------------------------------------- cluster_fast
DESCRIPTION="issue 61: --cluster_fast sorts by length"
${VSEARCH} \
    --cluster_fast <(printf ">s1;size=1\nAA\n>s2;size=1\nT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=1AA>s2;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 61: --cluster_fast sorts by length (reverse input order)"
${VSEARCH} \
    --cluster_fast <(printf ">s1;size=1\nT\n>s2;size=1\nAA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s2;size=1AA>s1;size=1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 61: --cluster_fast sorts by length, then by abundance"
${VSEARCH} \
    --cluster_fast <(printf ">s1;size=2\nAA\n>s2;size=1\nTT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=2AA>s2;size=1TT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 61: --cluster_fast sorts by length, then by abundance (reverse input order)"
${VSEARCH} \
    --cluster_fast <(printf ">s1;size=1\nAA\n>s2;size=2\nTT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s2;size=2TT>s1;size=1AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 61: --cluster_fast sorts by length, then by abundance, then by identifier"
${VSEARCH} \
    --cluster_fast <(printf ">s1;size=1\nAA\n>s2;size=1\nTT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=1AA>s2;size=1TT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 61: --cluster_fast sorts by length, then by abundance, then by identifier (reverse input order)"
${VSEARCH} \
    --cluster_fast <(printf ">s2;size=1\nAA\n>s1;size=1\nTT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=1TT>s2;size=1AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- cluster_size
DESCRIPTION="issue 61: --cluster_size sorts by abundance"
${VSEARCH} \
    --cluster_size <(printf ">s1;size=2\nAA\n>s2;size=1\nTT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=2AA>s2;size=1TT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 61: --cluster_size sorts by abundance (reverse input order)"
${VSEARCH} \
    --cluster_size <(printf ">s1;size=1\nAA\n>s2;size=2\nTT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s2;size=2TT>s1;size=1AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 61: --cluster_size sorts by abundance, then by identifier"
${VSEARCH} \
    --cluster_size <(printf ">s1;size=1\nAA\n>s2;size=1\nTT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=1AA>s2;size=1TT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 61: --cluster_size sorts by abundance, then by identifier (reverse input order)"
${VSEARCH} \
    --cluster_size <(printf ">s2;size=1\nAA\n>s1;size=1\nTT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=1TT>s2;size=1AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#    Ignore abundance input for clustering and dereplication if sizein not     #
#                                   specified                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/62

# clustering output must take into account the --sizein option
# (for dereplication: see derep_fulllength.sh)

DESCRIPTION="issue 62: --cluster_size adds abundances (implicit abundances)"
${VSEARCH} \
    --cluster_size <(printf ">s1\nA\n>s2\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=2A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 62: --cluster_size adds abundances (implicit abundances + sizein)"
${VSEARCH} \
    --cluster_size <(printf ">s1\nA\n>s2\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=2A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 62: --cluster_size adds abundances (explicit abundances)"
${VSEARCH} \
    --cluster_size <(printf ">s1;size=2\nA\n>s2;size=1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=2A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 62: --cluster_size adds abundances (explicit abundances + sizein)"
${VSEARCH} \
    --cluster_size <(printf ">s1;size=2\nA\n>s2;size=1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --sizein \
    --sizeout \
    --centroids - | \
    tr -d "\n" | \
    grep -qx ">s1;size=3A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#         Seg Fault or Cannot allocate enough memory on long sequences         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/63

DESCRIPTION="issue 63: --cluster_size accepts large sequences (> 16,000 nucleotides)"
TMP=$(mktemp)
(printf ">s1\n"
 yes A 2>/dev/null | head -n 16386
 printf ">s2\n"
 yes A 2>/dev/null | head -n 100) > "${TMP}"
${VSEARCH} \
    --cluster_fast "${TMP}" \
    --id 0.95 \
    --centroids /dev/null > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP


#******************************************************************************#
#                                                                              #
#          Dereplication: option to use hash values as sequence names          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/64

# the requested feature was implemented as the --relabel_md5 and
# --relabel_sha1 options (hash of the upper-cased, unwrapped sequence),
# extended to both dereplication and sorting; already covered in
# derep_fulllength.sh, sortbylength.sh and sortbysize.sh (see also issue 84)


#******************************************************************************#
#                                                                              #
#                          x permissions on binaries                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/65

# not testable


#******************************************************************************#
#                                                                              #
#       Improve reading of FASTA files, including very long header lines       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/66

## the underlying problem was the length of FASTA header lines (not the
## presence of special characters); vsearch must now read very long
## header lines without aborting
DESCRIPTION="issue 66: very long fasta header lines are accepted (100,000 characters)"
LONG_HEADER=$(head -c 100000 /dev/zero | tr '\0' 'x')
printf ">%s\nACGTACGTACGTACGTACGTACGTACGTACGT\n" "${LONG_HEADER}" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 1 \
        --notrunclabels \
        --quiet \
        --fastaout - | \
    awk '/^>/ {ok = (length($0) == 100001)} END {exit ok ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset LONG_HEADER


#******************************************************************************#
#                                                                              #
#                       Ambiguity in consensus alignment                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/67

## a cluster member matching the centroid on the reverse strand must be
## reverse-complemented in the multiple alignment, otherwise the consensus
## is chimeric (fixed in v1.0.14). Here s2 is the reverse-complement of s1:
## with --strand both they form one cluster and s2 must appear in the same
## orientation as s1 in the alignment.
DESCRIPTION="issue 67: reverse-strand member is reverse-complemented in --msaout"
SEQ="ATGATCGTGTGATCGTGTAGCTGTGCTGTAGCTGTGTAGCT"
RC="AGCTACACAGCTACAGCACAGCTACACGATCACACGATCAT"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${RC}" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.9 \
        --minseqlength 1 \
        --strand both \
        --quiet \
        --msaout - | \
    grep -A 1 "^>s2" | \
    grep -ixq "${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ RC

DESCRIPTION="issue 67: reverse-strand member yields a clean (non-chimeric) consensus"
SEQ="ATGATCGTGTGATCGTGTAGCTGTGCTGTAGCTGTGTAGCT"
RC="AGCTACACAGCTACAGCACAGCTACACGATCACACGATCAT"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${RC}" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.9 \
        --minseqlength 1 \
        --strand both \
        --quiet \
        --consout - | \
    grep -iv "^>" | \
    grep -ixq "${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ RC


#******************************************************************************#
#                                                                              #
#                          adopt semantic versioning                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/68

# not testable


#******************************************************************************#
#                                                                              #
#   malloc: *** error for object 0x7ff2bad003a0: pointer being freed was not   #
#                                   allocated                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/69

## clustering with --msaout and/or --consout triggered an invalid free of
## the cigar strings (msa.cc), causing a crash; fixed in v1.0.13
DESCRIPTION="issue 69: --cluster_fast with --msaout and --consout does not crash"
printf ">a\nATTTGTTTCAGGGTTATTTGAATATCTATAACAACTATTTTA\n>b\nTTGTTTCAGGGTTATTTGAATATCTATAACAACTATTTTAAA\n>c\nTTTGTTTCAGGGTTATTTGAATATCTATAACAACTATTTTAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.8 \
        --minseqlength 1 \
        --quiet \
        --msaout /dev/null \
        --consout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#               Error in `vsearch': corrupted double-linked list               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/70

## same root cause as issue 69 (corrupted double-linked list when freeing
## the cigar strings); fixed in v1.0.13. Here the input yields singleton
## clusters, which also exercised the buggy free loop.
DESCRIPTION="issue 70: --cluster_fast --msaout --consout with singletons does not crash"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --minseqlength 1 \
        --quiet \
        --msaout /dev/null \
        --consout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#          Error in calculation of the identity using --iddef 3 (MBL)          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/71

## the MBL identity (--iddef 3) is 1.0 - [(mismatches + gap openings) /
## longest sequence length]. The denominator must be the longest sequence,
## not the shortest (fixed in v1.0.15). Query (10 nt) aligned to target
## (12 nt) gives 10M2I: 0 mismatches and 1 gap opening, so the identity is
## 1 - (0 + 1)/12 = 0.9167 (91.7%). Using the shortest length (10) would
## wrongly give 1 - 1/10 = 90.0%.
DESCRIPTION="issue 71: --iddef 3 (MBL) uses the longest sequence as denominator"
printf ">q\nAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nAAAAAAAAAATT\n") \
        --id 0.1 \
        --iddef 3 \
        --minseqlength 1 \
        --quiet \
        --userfields id \
        --userout - | \
    grep -qx "91.7" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                        Integrate patches from Debian                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/72

# not testable (packaging: integration of Debian patches)


#******************************************************************************#
#                                                                              #
#                         Status taxonomy assignment?                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/73

# not testable (a question about the status of taxonomy assignment;
# taxonomic classification was later added as the --sintax command)


#******************************************************************************#
#                                                                              #
#                  cluster input sequences shorter than 32nt                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/74

## sequences shorter than 32 nt are discarded by default, but can be
## clustered when --minseqlength is lowered
DESCRIPTION="issue 74: short sequences are discarded with the default --minseqlength (32)"
printf ">a\nACGTACGTAC\n>b\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --centroids /dev/null 2>&1 | \
    grep -q "sequences discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 74: --cluster_fast clusters sequences shorter than 32 nt with --minseqlength 1"
printf ">a\nACGTACGTAC\n>b\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --minseqlength 1 \
        --quiet \
        --centroids - | \
    grep -c "^>" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#             cluster_fast and msa output for each of the clusters             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/75

## clustering and per-cluster multiple alignment are obtained in a single
## run with --msaout (each cluster's alignment is followed by a consensus
## line); the --msaout option itself is also covered in cluster_fast.sh
## and cluster_size.sh
DESCRIPTION="issue 75: --cluster_size --msaout outputs a consensus line per cluster"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --quiet \
        --msaout - | \
    grep -qx ">consensus" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                segfault when running cluster_fast with msaout                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/76

## segfault with --cluster_fast and --msaout (duplicate of issue 69);
## fixed in v1.0.13. The original input was a single cluster of short,
## overlapping reads.
DESCRIPTION="issue 76: --cluster_fast with --msaout only does not crash"
printf ">a\nATTTGTTTCAGGGTTATTTGAATATCTATAACAACTATTTTA\n>b\nTTGTTTCAGGGTTATTTGAATATCTATAACAACTATTTTAAA\n>c\nTTTGTTTCAGGGTTATTTGAATATCTATAACAACTATTTTAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.8 \
        --minseqlength 1 \
        --quiet \
        --msaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
# Segmentation fault when using --uchime_denovo on a large fasta file (9.3 GB) #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/77

# not testable (segmentation fault only triggered by a 9.3 GB input file
# with ~23 million sequences; cannot be reproduced with a small input)


#******************************************************************************#
#                                                                              #
#                     Chimera detection progress indicator                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/78

# not testable (the chimera detection progress indicator exceeded 100%;
# the percentage is printed on stderr and only misbehaved on a very large
# multi-threaded run)


#******************************************************************************#
#                                                                              #
#                        Support for multiple databases                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/79

## multiple databases are supported by concatenating them into a single
## stream, thanks to pipe support (see issue 39), e.g.
## --db <(cat db1.fasta db2.fasta). The query below only matches the
## second database entry.
DESCRIPTION="issue 79: multiple databases via a concatenated stream (process substitution)"
printf ">q\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">d1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>d2\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n") \
        --id 0.9 \
        --minseqlength 1 \
        --quiet \
        --userfields target \
        --userout - | \
    grep -qx "d2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                           Generating cluster files                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/80

## rather than producing thousands of --clusters files, the --uc output
## gives the sequence-to-cluster mapping in a single file: on the H and S
## lines, field 9 is the sequence label and field 2 the cluster number
## (see also the --uc tests in the cluster_*.sh scripts)
DESCRIPTION="issue 80: --uc provides a sequence-to-cluster mapping"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '$1 == "H" || $1 == "S" {print $9"@"$2}' | \
    tr "\n" " " | \
    grep -qx "a@0 b@1 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                            Space in a header line                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/81

## sequence labels are truncated at the first space by default (so the .uc
## and other outputs use only the part before the space); --notrunclabels
## keeps the full header
DESCRIPTION="issue 81: labels are truncated at the first space by default"
printf ">seq1 description here\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    grep -qx ">seq1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 81: --notrunclabels keeps the full header (including text after the space)"
printf ">seq1 description here\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --notrunclabels \
        --quiet \
        --output - | \
    grep -qx ">seq1 description here" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#       Error "No output files specified" when only samout is specified        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/82

## providing only --samout used to fail with "Fatal error: No output files
## specified"; it must now be accepted on its own (fixed in the "summer"
## branch)
DESCRIPTION="issue 82: --cluster_fast with only --samout is accepted"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --minseqlength 1 \
        --quiet \
        --samout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#               Wanted: samout with search, not just clustering                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/83

## --samout is supported with searching, not only with clustering (fixed
## in the "summer" branch): a perfect hit produces a SAM record with the
## query in field 1 and the target in field 3
DESCRIPTION="issue 83: --usearch_global supports --samout"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.9 \
        --minseqlength 1 \
        --quiet \
        --samout - | \
    grep -v "^@" | \
    awk -F "\t" '$1 == "q" && $3 == "t" {found = 1} END {exit found ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                     --relabel does not work consistently                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/84

## --relabel was originally only available for sorting; it was extended so
## that it works consistently across dereplication, clustering centroids
## and chimera-detection outputs (see also issue 64). Basic --relabel
## acceptance is also covered in the command-specific scripts.
DESCRIPTION="issue 84: --relabel works with --derep_fulllength"
printf ">r1;size=2\nACGTACGTACGTACGTACGTACGTACGTACGT\n>r2;size=1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --relabel OTU_ \
        --quiet \
        --output - | \
    grep -qx ">OTU_1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 84: --relabel works with --cluster_size --centroids"
printf ">r1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>r2\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --relabel OTU_ \
        --quiet \
        --centroids - | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">OTU_1 >OTU_2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 84: --relabel works with --uchime_denovo --nonchimeras"
printf ">r1;size=5\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel SEQ_ \
        --quiet \
        --nonchimeras - | \
    grep -qx ">SEQ_1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                Problem with repeats when clustering WGS reads                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/85

# duplicate of issue 95 (repeated k-mers within sequences prevent matches);
# see the test under issue 95 below


#******************************************************************************#
#                                                                              #
#         Option to not ignore terminal gaps when computing consensus          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/86


#******************************************************************************#
#                                                                              #
#              Chimera search with translated protein sequences?               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/87

## vsearch does not support amino-acid sequences; feeding protein
## characters to a command (here chimera detection) strips the invalid
## characters and emits a warning
DESCRIPTION="issue 87: --uchime_denovo strips invalid (protein) characters with a warning"
printf ">s1;size=3\nEFILPQEFILPQEFILPQEFILPQEFILPQEFILPQ\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --nonchimeras /dev/null 2>&1 | \
    grep -q "invalid characters stripped" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                        Vsearch needs a Galaxy wrapper                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/88

# not testable (request for a Galaxy wrapper, external to vsearch)


#******************************************************************************#
#                                                                              #
#        Consensus output in clustering produces empty fasta sequences         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/89

## an empty consensus sequence (a header with no bases) is the correct
## result for a gappy alignment: when at least half of the sequences have a
## gap in a column, the consensus symbol is a gap, and a consensus made of
## only gaps becomes empty after the gaps are removed. Here one long
## centroid and four short, non-overlapping members make gaps the majority
## at every column.
DESCRIPTION="issue 89: a gappy cluster legitimately produces an empty consensus"
printf ">cent\nAAAAAAAAAACCCCCCCCCCGGGGGGGGGGTTTTTTTTTT\n>m1\nAAAAAAAAAA\n>m2\nCCCCCCCCCC\n>m3\nGGGGGGGGGG\n>m4\nTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.1 \
        --minseqlength 1 \
        --quiet \
        --consout - | \
    awk '/^>/ {h++; next} {if (length($0) > 0) b++} END {exit (h == 1 && b == 0) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                 Dereplication based on prefixes of sequences                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/90

# the requested feature was implemented as the --derep_prefix command;
# already covered in derep_prefix.sh


#******************************************************************************#
#                                                                              #
#                       Unable to build on OS X 10.10.3                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/91

# not testable (compilation failure on OS X; resolved by renaming string.h
# to xstring.h, see issue 92)


#******************************************************************************#
#                                                                              #
#                    MAINT: renaming string.h to xstring.h                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/92

# not testable (source-tree maintenance: renaming string.h to xstring.h)


#******************************************************************************#
#                                                                              #
#                   I've made a homebrew package for vsearch                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/93

# not testable (third-party Homebrew package, external to vsearch)


#******************************************************************************#
#                                                                              #
#                         Sequence profile of clusters                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/94

## the requested per-cluster sequence profile was implemented as the
## --profile option, which outputs a matrix with the base counts at each
## alignment column. The --profile option is also covered in cluster_fast.sh
## and cluster_size.sh; here we check the actual counts of the first column.
DESCRIPTION="issue 94: --cluster_size --profile reports per-column base counts"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --quiet \
        --profile - | \
    awk 'NR == 2 {ok = ($1 == 0 && $2 == "A" && $3 == 2)} END {exit ok ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#             usearch_global sequences that contain repeated kmers             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/95

## a query containing repeated k-mers (and therefore very few unique
## 8-mers) could fail to match a very similar database sequence. The query
## below differs from the database sequence by a single mismatch and must
## be found at --id 0.9 (related to issue 85).
DESCRIPTION="issue 95: usearch_global finds matches in sequences with repeated kmers"
printf ">read1\nTAGGTATAGGTATAGGTATAGGTATAGGGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">centroid1\nTAGGTATGGGTATAGGTATAGGTATAGGGA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --strand plus \
        --quiet \
        --userfields target \
        --userout - | \
    grep -qx "centroid1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                  question about compile time optimizations                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/96

# not testable (build-time compiler optimisation flags in the Makefile)


#******************************************************************************#
#                                                                              #
#                Error in `vsearch': double free or corruption                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/97

## "double free or corruption" when writing consensus sequences with
## --cluster_fast --consout (duplicate of issue 69); fixed in v1.0.13
DESCRIPTION="issue 97: --cluster_fast with --consout does not crash"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.99 \
        --minseqlength 1 \
        --quiet \
        --consout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## in the original report --cons_truncate produced "WARNING: Option
## --cons_truncate is ignored"; it is now an implemented option (controls
## terminal gaps in the consensus, see also issue 86 and cluster_fast.sh)
DESCRIPTION="issue 97: --cluster_fast --consout accepts --cons_truncate"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.99 \
        --minseqlength 1 \
        --cons_truncate \
        --quiet \
        --consout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#              option --minh ignored while using --uchime_denovo               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/98

## --minh values above 1.0 (or given as integers) used to be silently
## ignored and reset to the default. They are now accepted (the manpage
## states that values above 1.0 are accepted but uncommon). The effect of
## a high --minh on chimera detection is covered in uchime_denovo.sh.
DESCRIPTION="issue 98: --uchime_denovo accepts --minh above 1.0"
printf ">s1;size=2\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --minh 2.0 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 98: --uchime_denovo accepts an integer --minh value"
printf ">s1;size=2\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --minh 1 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                                 Test scripts                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/99

# not testable (concerns the shebang lines of the bundled test scripts,
# which were meant for bash, not dash)


#******************************************************************************#
#                                                                              #
#Use "|" (vertical bar) instead of ";" (semicolon) as separator in FASTA header#
#                                     lines                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/100

# not testable. The ";" separator is kept for usearch compatibility; a
# different separator can be obtained by piping the output through sed, e.g.
# vsearch --derep_fulllength input.fasta --output - | sed -e "s/;/|/g"


#******************************************************************************#
#                                                                              #
#        Reorganize subsampling commands for compatibilty with usearch         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/101

# the subsampling command was reorganized as --fastx_subsample with the
# options --sample_pct, --sample_size, --fastaout, --randseed, --sizein,
# --sizeout and --xsize; already covered in fastx_subsample.sh


#******************************************************************************#
#                                                                              #
#         Option to sort cluster output files by the size of clusters          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/102

## the --clusterout_sort option orders the consout, profile and msaout
## files by decreasing cluster abundance (also covered in cluster_*.sh)
DESCRIPTION="issue 102: --clusterout_sort orders --consout by decreasing abundance"
printf ">a;size=1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=9\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --sizein \
        --sizeout \
        --clusterout_sort \
        --quiet \
        --consout - | \
    awk '/^>/ {print; exit}' | \
    grep -q "centroid=b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
# Option to propagate the cluster identifier to both the consensus and profile #
#                                     files                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/103

## the --clusterout_id option adds the cluster id to the consout and
## profile header lines (also covered in cluster_*.sh)
DESCRIPTION="issue 103: --clusterout_id adds the cluster id to --consout headers"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --clusterout_id \
        --quiet \
        --consout - | \
    grep -q "clusterid=0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                     Missing output in uchime_denovo mode                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/104

## borderline sequences are excluded from both the --chimeras and
## --nonchimeras output files; the --borderline option was added to capture
## them and the screen/log summary reports their count separately (also
## covered in uchime_denovo.sh)
DESCRIPTION="issue 104: --uchime_denovo reports borderline sequences separately"
printf ">a;size=20\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n>b;size=20\nGGGGGGGGGGGGGGGGTTTTTTTTTTTTTTTT\n>c;size=1\nAAAAAAAAAAAAAAAATTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --borderline /dev/null \
        --nonchimeras /dev/null 2>&1 | \
    grep -q "borderline sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                                Change license                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/105

# not testable (the license was changed to a dual AGPL + 3-clause BSD)


#******************************************************************************#
#                                                                              #
#                  Replace CityHash by FarmHash or MetroHash?                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/106

# not testable (internal choice of hash function; the time spent hashing is
# negligible, so CityHash was kept)


#******************************************************************************#
#                                                                              #
#                     Add header information to sam output                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/107

## the --samheader option adds @HD, @SQ and @PG header lines to the SAM
## output, to ease post-processing with samtools etc. (also covered in
## samout.sh and the search/clustering scripts)
DESCRIPTION="issue 107: --samheader adds header lines to the SAM output"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.9 \
        --minseqlength 1 \
        --samout - \
        --samheader \
        --quiet | \
    grep -q "^@HD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                        Warnings reported by cppcheck                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/108

# not testable (source-code warnings reported by cppcheck)


#******************************************************************************#
#                                                                              #
#                  Request regarding abundance labeled output                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/109

## the consensus output (consout) must include the size= annotation when
## --sizeout is used, for compatibility with usearch and QIIME parsers
## (here two identical size=3 and size=2 sequences give a size=5 cluster)
DESCRIPTION="issue 109: --cluster_size --consout --sizeout adds the size annotation"
printf ">a;size=3\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=2\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --sizein \
        --sizeout \
        --quiet \
        --consout - | \
    grep -q ";size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                            details of msa output                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/110

# not testable (a question: the msa output is a simple alignment of each
# sequence against the centroid/seed, not an all-by-all alignment)


#******************************************************************************#
#                                                                              #
#                Large memory consumption with --fastx_revcomp                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/111

# not testable here (memory leak in --fastx_revcomp, fixed in 1.3.2;
# memory consumption is exercised by the valgrind tests)


#******************************************************************************#
#                                                                              #
#                                     Typo                                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/112

## the version banner contained a typo ("vv1.3.1") in the summer branch;
## it must show a single "v" before the version number
DESCRIPTION="issue 112: the version banner shows a single 'v' (no 'vv' typo)"
"${VSEARCH}" \
    --version 2>&1 | \
    grep -qE "^vsearch v[0-9]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                                 Help message                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/113

## the short option -h must be accepted as an alias for --help
DESCRIPTION="issue 113: -h is accepted as a short option for --help"
"${VSEARCH}" \
    -h 2>&1 | \
    grep -q "usearch_global" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#              Remove stray ` mark from installation instructions              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/114

# not testable (pull request fixing a stray backtick in the installation
# instructions)


#******************************************************************************#
#                                                                              #
#                         Support xz compressed files                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/115

# not testable as a dedicated vsearch feature. xz-compressed files are
# handled indirectly through pipes (see issue 39), e.g.
# vsearch --fastq_chars <(xzcat file.fastq.xz)


#******************************************************************************#
#                                                                              #
#                           FASTQ version conversion                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/116

# FASTQ version conversion (between phred+33 and phred+64) was added as the
# --fastq_convert command; already covered in fastq_convert.sh


#******************************************************************************#
#                                                                              #
#                         Add "-v" option for version                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/117

## the short option -v must report the version (added in 1.5.0)
DESCRIPTION="issue 117: -v is accepted as a short option for the version"
"${VSEARCH}" \
    -v 2>&1 | \
    grep -qE "^vsearch v[0-9]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                          Improve chimera detection                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/118


#******************************************************************************#
#                                                                              #
#                                 Support AVX2                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/119

# not testable (internal SIMD/alignment library choice, e.g. AVX2/parasail)


#******************************************************************************#
#                                                                              #
#      Make --fastx_subsample work with FASTQ files, not just FASTA files      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/120

## --fastx_subsample must work with FASTQ files, not only FASTA (added in
## 1.8.0; also covered in fastx_subsample.sh)
DESCRIPTION="issue 120: --fastx_subsample works on a FASTQ file with --fastqout"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 100 \
        --quiet \
        --fastqout - | \
    tr "\n" "@" | \
    grep -qx "@s1@ACGT@+@IIII@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                      Add relabelling options to shuffle                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/121

# relabelling options were added to --shuffle (in 1.6.0); already covered
# in shuffle.sh


#******************************************************************************#
#                                                                              #
#                               sizeorder option                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/122

## the --sizeorder option (abundance-based greedy clustering, AGC) ranks
## accepted centroids by decreasing abundance instead of by identity; it
## takes effect with --maxaccepts > 1 (also covered in cluster_*.sh)
DESCRIPTION="issue 122: --sizeorder is accepted by the clustering commands"
printf ">a;size=1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=5\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.9 \
        --minseqlength 1 \
        --sizein \
        --sizeorder \
        --maxaccepts 4 \
        --quiet \
        --centroids /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                       Issue with zlib on version 1.4.0                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/123

# not testable (runtime zlib version requirement: zlib 1.2.4 or later is
# needed for gzip support, because of the gzoffset function)


#******************************************************************************#
#                                                                              #
#                    Remove dependency on crypto libraries                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/124

## the dependency on crypto libraries was removed by embedding public-domain
## md5 and sha1 implementations; the digests must still be correct. They are
## computed on the upper-cased, unwrapped sequence and checked here against
## md5sum and sha1sum.
DESCRIPTION="issue 124: --relabel_md5 produces the correct md5 digest"
SEQ="ACGTACGTACGTACGTACGTACGTACGTACGT"
MD5=$(printf "%s" "${SEQ}" | md5sum | cut -d " " -f 1)
printf ">a\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --relabel_md5 \
        --quiet \
        --output - | \
    grep -qx ">${MD5}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ MD5

DESCRIPTION="issue 124: --relabel_sha1 produces the correct sha1 digest"
SEQ="ACGTACGTACGTACGTACGTACGTACGTACGT"
SHA1=$(printf "%s" "${SEQ}" | sha1sum | cut -d " " -f 1)
printf ">a\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --relabel_sha1 \
        --quiet \
        --output - | \
    grep -qx ">${SHA1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ SHA1


#******************************************************************************#
#                                                                              #
#                           Fix example in man page                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/125

# not testable (pull request fixing an example in the man page)


#******************************************************************************#
#                                                                              #
#                    realloc() error clustering on v.1.4.1                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/126

## clustering a file mixing very long sequences (here 15,000 nt) with short
## ones triggered a realloc() error on Linux; it must now run without
## crashing (see also issue 63 for large sequences)
DESCRIPTION="issue 126: --cluster_fast handles very long sequences without crashing"
LONG=$(head -c 15000 /dev/zero | tr '\0' 'A')
printf ">long\n%s\n>s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" "${LONG}" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.95 \
        --iddef 0 \
        --strand both \
        --minseqlength 1 \
        --quiet \
        --centroids /dev/null \
        --uc /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset LONG


#******************************************************************************#
#                                                                              #
#     Fatal error: Cannot determine amount of RAM with 1.4.2 on OSX 10.8.5     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/127

# not testable (platform-specific: "Cannot determine amount of RAM" on
# OS X 10.8.5, fixed in 1.4.4)


#******************************************************************************#
#                                                                              #
#                Fix alignment bug introduced in version 1.2.17                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/128

# not testable (an alignment regression introduced in 1.2.17 and fixed in
# 1.4.6; no minimal reproducer was provided in the issue)


#******************************************************************************#
#                                                                              #
#              possible for .uc files to be relabel_sha1-aware?                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/129

## a user wanted the relabelled (sha1) identifier together with the original
## label. Rather than changing the .uc file (where identical sequences would
## get identical hashes), this was solved with the --relabel_keep option,
## which appends the old label after the new one in the output.
DESCRIPTION="issue 129: --relabel_keep appends the old label after the new sha1 label"
SEQ="ACGTACGTACGTACGTACGTACGTACGTACGT"
SHA1=$(printf "%s" "${SEQ}" | sha1sum | cut -d " " -f 1)
printf ">a\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --relabel_sha1 \
        --relabel_keep \
        --quiet \
        --output - | \
    grep -qx ">${SHA1} a" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ SHA1


#******************************************************************************#
#                                                                              #
#                              add --search_exact                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/130

# the --search_exact command was added (in 1.8.0); already covered in
# search_exact.sh


#******************************************************************************#
#                                                                              #
#                    add --relabel option to --shuffle #121                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/131

# pull request adding the --relabel option to --shuffle (issue 121);
# already covered in shuffle.sh


#******************************************************************************#
#                                                                              #
#                     Implement the search_global command                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/132


#******************************************************************************#
#                                                                              #
#                         Add test for --search_exact                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/133

# not testable (pull request adding a test for --search_exact)


#******************************************************************************#
#                                                                              #
#                         release vsearch on anacoda?                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/134

# not testable (external packaging on conda/anaconda)


#******************************************************************************#
#                                                                              #
#                   error in --fastq_stats on MaxOSX 10.8.5                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/135

# not testable (platform-specific: missing ___exp10 symbol in --fastq_stats
# on OS X 10.8.5)


#******************************************************************************#
#                                                                              #
#            Allow floating point number argument to threads option            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/136

## a floating point argument to --threads must be accepted, for
## compatibility with usearch and QIIME (fixed in 1.8.1)
DESCRIPTION="issue 136: --threads accepts a floating point argument"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --threads 1.0 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                           disable default CXXFLAGS                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/137

# not testable (build configuration: pull request disabling the default
# CXXFLAGS)


#******************************************************************************#
#                                                                              #
#             fastq_convert: fastaout does not work on fastq files             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/138

## --fastq_convert only converts between FASTQ variants; it does not accept
## --fastaout. The FASTQ to FASTA conversion is done with --fastq_filter.
DESCRIPTION="issue 138: --fastq_convert rejects --fastaout"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 138: FASTQ to FASTA conversion is done with --fastq_filter"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastaout - \
        --quiet | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                   Remove autoconf files from distribution                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/139

# not testable (distribution tarball: inclusion of autoconf-generated files
# so that compilation does not require autoconf)


#******************************************************************************#
#                                                                              #
#             escape tabs in fasta names writing output with --uc              #
#                                  (issue 141)                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/140

## vsearch truncates at the first space or tab by default, similar to
## usearch. If the --notrunclabels option is specified, the entire
## line will be read.

## vsearch truncates after a tab
DESCRIPTION="issue 140: truncate headers after a tab"
"${VSEARCH}" \
    --cluster_fast <(printf ">s1\theader\nA\n") \
    --id 0.97 \
    --quiet \
    --minseqlength 1 \
    --uc - | \
    awk -F "\t" '{exit /^S/ && $9 == "s1" && $10 == "*" ? 0 : 1}' && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## vsearch does not truncate after a tab with --notrunclabels
DESCRIPTION="issue 140: do not truncate after a tab with --notrunclabels"
"${VSEARCH}" \
    --cluster_fast <(printf ">s1\theader\nA\n") \
    --id 0.97 \
    --quiet \
    --notrunclabels \
    --minseqlength 1 \
    --uc - | \
    awk -F "\t" '{exit /^S/ && $9 == "s1" && $10 == "header" ? 0 : 1}' && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## vsearch truncates after a space
DESCRIPTION="issue 140: truncate headers after a space"
"${VSEARCH}" \
    --cluster_fast <(printf ">s1 header\nA\n") \
    --id 0.97 \
    --quiet \
    --minseqlength 1 \
    --uc - | \
    awk -F "\t" '{exit /^S/ && $9 == "s1" && $10 == "*" ? 0 : 1}' && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 140: do not truncate after a space with --notrunclabels"
"${VSEARCH}" \
    --cluster_fast <(printf ">s1 header\nA\n") \
    --id 0.97 \
    --quiet \
    --notrunclabels \
    --minseqlength 1 \
    --uc - | \
    awk -F "\t" '{exit /^S/ && $9 == "s1 header" ? 0 : 1}' && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                   quote fasta record names in --uc output                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/141

# pull request about quoting/escaping tabs in fasta record names in the --uc
# output; the adopted resolution (truncate labels at the first space or tab
# by default) is tested under issue 140 above


#******************************************************************************#
#                                                                              #
#    Segfault or fatal error with fastx-commands on compressed input files     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/142

## fastx_mask, fastx_subsample and fastx_revcomp segfaulted or aborted on
## gzip-compressed input; fixed in 1.9.0
DESCRIPTION="issue 142: --fastx_revcomp reads gzip-compressed input (pipe)"
printf ">s1\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --gzip_decompress \
        --quiet \
        --fastaout - | \
    grep -A 1 "^>s1" | \
    grep -qx "GGGGGGGGGGGGGGGGTTTTTTTTTTTTTTTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 142: --fastx_subsample reads gzip-compressed input (pipe)"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --gzip_decompress \
        --sample_pct 100 \
        --quiet \
        --fastaout - | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                          Improved chimera reporting                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/143

## chimera reporting was improved to also report the number and percentage
## of sequences including their abundances ("total sequences"), not only the
## unique sequences (fixed in 1.10.0)
DESCRIPTION="issue 143: --uchime_denovo reports counts for total sequences (with abundances)"
printf ">a;size=20\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n>b;size=20\nGGGGGGGGGGGGGGGGTTTTTTTTTTTTTTTT\n>c;size=1\nAAAAAAAAAAAAAAAATTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --nonchimeras /dev/null 2>&1 | \
    grep -q "total sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#    Optionally compress output to FASTA or FASTQ files with gzip or bzip2     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/144

# vsearch v2.31.0 does not appear to compress output FASTA/FASTQ files by
# itself: writing to a file whose name ends in ".gz" or ".bz2" produces
# plain text, and the source contains no gzip/bzip2 write code. Compressed
# output is obtained by piping through gzip or bzip2, e.g.
# vsearch ... --output - | gzip > output.fasta.gz
# Reading gzip/bzip2-compressed input is supported (see issues 39 and 142).
# NOTE: this differs from the feature request; flagged for human review.


#******************************************************************************#
#                                                                              #
#vsearch --fastq_stats doesn't report correct values of AvgEE, Rate and RatePct#
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/145

## --fastq_stats reported incorrect AvgEE, Rate and RatePct. For a 50 nt
## read with 40 positions at Q40 and 10 at Q10, the expected error is
## 10^-4 x 40 + 10^-1 x 10 = 1.004, so Rate = 1.004 / 50 = 0.020080 (the
## buggy version reported 0.011200).
DESCRIPTION="issue 145: --fastq_stats computes AvgEE / Rate correctly"
SEQ=$(head -c 50 /dev/zero | tr '\0' 'A')
QUAL="$(head -c 40 /dev/zero | tr '\0' 'I')$(head -c 10 /dev/zero | tr '\0' '+')"
printf "@r1\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - \
        --quiet 2>/dev/null | \
    awk '$1 == 50 && $7 == "0.020080" {found = 1} END {exit found ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL


#******************************************************************************#
#                                                                              #
#         Error in installing vsearch 1.9.2 from source on OS X 10.8.5         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/146

# not testable (build error: missing x86intrin.h header when compiling on
# OS X 10.8.5)


#******************************************************************************#
#                                                                              #
#                          Letter case not preserved                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/147

## the letter case of the sequences must be preserved in the output (it was
## not, when mixed-case input was used)
DESCRIPTION="issue 147: letter case is preserved in the output"
printf ">s1\nacgtACGTacgtACGTacgtACGTacgtACGT\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 1 \
        --quiet \
        --fastaout - | \
    grep -A 1 "^>s1" | \
    grep -qx "acgtACGTacgtACGTacgtACGTacgtACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                         Add --fastq_eestats command                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/148

# the --fastq_eestats command was added (in 1.10.0); already covered in
# fastq_eestats.sh


#******************************************************************************#
#                                                                              #
#                   Incorrect abundance in subsample output                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/149

## a user suspected the abundances were wrong in the --fastx_subsample
## output; they are in fact correct: with --sizein and --sizeout the
## abundance annotation is preserved (the reporter retracted the bug)
DESCRIPTION="issue 149: --fastx_subsample preserves abundances with --sizein/--sizeout"
printf ">a;size=5\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 100 \
        --sizein \
        --sizeout \
        --quiet \
        --fastaout - | \
    grep -qx ">a;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                   relabel issue duruing --derep_fulllength                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/150

## the --relabel counter did not increase during --derep_fulllength (every
## unique sequence got the same new label); fixed in 1.9.4
DESCRIPTION="issue 150: --derep_fulllength --relabel increments the counter"
printf ">a\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>b\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n>c\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --relabel denovo \
        --quiet \
        --output - | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">denovo1 >denovo2 >denovo3 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                                Rereplication                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/151

# the --rereplicate command was added (in 1.10.0) to restore multiple copies
# of dereplicated sequences according to their abundance; already covered in
# rereplicate.sh


#******************************************************************************#
#                                                                              #
#                                usearch_local                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/152

# not testable (vsearch does not implement local alignment / usearch_local;
# only global alignment is supported)


#******************************************************************************#
#                                                                              #
#                  Wrong alignment results in usearch_global                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/153

## --fastapairs and --userout (qrow, trow) returned wrong alignments while
## --alnout was correct; fixed. Here the query has a 2 nt insertion relative
## to the target, so the aligned target row (trow) must contain a 2 nt gap at
## the corresponding position.
DESCRIPTION="issue 153: --userout trow shows the correct (gapped) target alignment"
printf ">q\nACGTAGCTAGCTGACCTCGATCGTAGCTAGCTGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.8 \
        --minseqlength 1 \
        --userfields trow \
        --userout - \
        --quiet | \
    grep -qx "ACGTAGCTAGCTGA--TCGATCGTAGCTAGCTGA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                                automake 1.15                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/154

# not testable (build: the autoconf version required a recent automake)


#******************************************************************************#
#                                                                              #
#                     Request: uchime score in fasta label                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/155

## the --fasta_score option (added in 1.10.0) appends the chimera score to
## the FASTA headers of the chimera-detection output (uchime_denovo here)
DESCRIPTION="issue 155: --fasta_score appends the chimera score to the FASTA header"
printf ">a;size=20\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n>b;size=20\nGGGGGGGGGGGGGGGGTTTTTTTTTTTTTTTT\n>c;size=1\nAAAAAAAAAAAAAAAATTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --fasta_score \
        --nonchimeras - \
        --quiet | \
    grep -q ";uchime_denovo=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#             Avoid progress indicator if stderr is not a terminal             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/156
# Avoid updating the progress indicator when stderr is not a terminal

# In practice, stderr is not a tty when --log is used and is a
# file. Maybe the issue should be renamed "Avoid writing progress
# indicator to log file"?

# Currently, vsearch prints progress to stderr if stderr is a tty
# unless the --quiet or --no_progress options are specified.

DESCRIPTION="issue 156: vsearch prints to stderr if stderr is a tty"
printf ">s\nAAAA\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null 2>&1 | \
    grep -q "Writing output" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 156: vsearch prints to stderr if stderr is a redirection to a file"
(
    TMP=$(mktemp)
    exec 2> "${TMP}"
    printf ">s\nAAAA\n" | \
        "${VSEARCH}" \
            --fastx_mask - \
            --fastaout /dev/null
    grep -q "Writing output" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm "${TMP}"
)

DESCRIPTION="issue 156: vsearch does not print to stderr if stderr is a tty and --quiet is used"
printf ">s\nAAAA\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -q "Writing output" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# Progress on current task increases from 0 to 100%. When using
# --no_progress, a line is printed when the task 100% is done without
# any intermediate state
DESCRIPTION="issue 156: vsearch does not print progress to stderr if stderr is a tty and --no_progress is used"
yes ">s@AAAA" | \
    head -n 500 | \
    tr "@" "\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --no_progress \
        --fastaout /dev/null 2>&1 | \
    grep -q -m 1 "100%$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
# I cannot find a way to test for the presence of intermediate
# percentage values, so the counterpart (progress is printed) is not
# properly tested

DESCRIPTION="issue 156: output progress when stderr is a redirection and stdout is a tty"
printf ">s\nAAAA\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - 2>&1 | \
    grep -q "Writing output" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 156: output progress when log, stderr and stdout are ttys"
printf ">seq1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --log - \
        --fastaout - 2>&1 | \
    grep -q "Writing output" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 156: do not output progress when log is a file and stderr is a redirection"
PROGRESS=$(mktemp)
# shellcheck disable=SC2094
printf ">s\nAAAA\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --log "${PROGRESS}" \
        --fastaout - > /dev/null 2>> "${PROGRESS}"
grep -q "Writing output" "${PROGRESS}" && \
    failure "${DESCRIPTION}" || \
        success  "${DESCRIPTION}"
rm "${PROGRESS}"


#******************************************************************************#
#                                                                              #
#                      Segmentation fault with uchime_ref                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/157

## a very short (3 nt) sequence caused a segmentation fault in --uchime_ref;
## fixed in 1.9.8
DESCRIPTION="issue 157: --uchime_ref does not crash on a very short query sequence"
printf ">q\nACG\n" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db <(printf ">t\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --minseqlength 1 \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#         Database sequences in lower case are being masked by default         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/158

## a regression in 1.9.7 caused lower-case database sequences to be fully
## (hard) masked by default; the case should instead be ignored (and the
## sequence dust-masked), so a lower-case database sequence must still match
## an upper-case query. Fixed in 1.9.10.
DESCRIPTION="issue 158: a lower-case database sequence still matches (case is ignored, not hard-masked)"
printf ">q\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nacgtagctagctgatcgatcgtagctagctga\n") \
        --id 0.9 \
        --minseqlength 1 \
        --userfields target \
        --userout - \
        --quiet | \
    grep -qx "t" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#            Remove unaligned part of alignment in uchimealn files             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/159


#******************************************************************************#
#                                                                              #
#                     --relabel not working with --consout                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/160

## --relabel was not applied to the consensus sequences produced by
## --consout; fixed in 1.10.0 (the consensus headers are now relabelled)
DESCRIPTION="issue 160: --relabel is applied to --consout consensus sequences"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --relabel OTU_ \
        --quiet \
        --consout - | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">centroid=OTU_1;seqs=1 >centroid=OTU_2;seqs=1 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#           Add options to filter sequences and consensus sequences            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/161

# closed as a discussion: filtering sequences on length and number of Ns is
# available through the --fastx_filter command, and finer control over the
# consensus can be obtained from the --profile output. Multi-pass clustering
# will not be implemented.


#******************************************************************************#
#                                                                              #
#                       inconsistency with merging pairs                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/162

# not testable (user error, not a bug: the reverse reads were not reverse-
# complemented as --fastq_mergepairs expects)


#******************************************************************************#
#                                                                              #
#                              --self doco error?                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/163

## not a bug (documentation question): --self rejects a hit when the query
## and target labels are identical, while --selfid rejects a hit when the
## query and target sequences are identical ("id" = identity)
DESCRIPTION="issue 163: --self rejects a hit when the labels are identical"
printf ">s1\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --self \
        --userfields target \
        --userout - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 163: --selfid rejects a hit when the sequences are identical"
printf ">q1\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t1\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --selfid \
        --userfields target \
        --userout - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#             Do not truncate FASTQ labels (for fastq_mergepairs)              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/164

## fastq_mergepairs must not truncate the FASTQ labels at the first space by
## default (no need to specify --notrunclabels); fixed in 1.10.1
DESCRIPTION="issue 164: --fastq_mergepairs keeps the full label (no truncation at space)"
FWD=$(mktemp)
REV=$(mktemp)
printf "@read1 somedescription\nGCTAAAGACAATTACATAACATACACGTCAGCACGAAACT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${FWD}"
printf "@read1 somedescription\nCGATTCACACTGGGCCAACAAGTTTCGTGCTGACGTGTAT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${REV}"
"${VSEARCH}" \
    --fastq_mergepairs "${FWD}" \
    --reverse "${REV}" \
    --fastqout - \
    --quiet 2>/dev/null | \
    head -1 | \
    grep -qx "@read1 somedescription" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FWD}" "${REV}"


#******************************************************************************#
#                                                                              #
#                     New option to output sequence length                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/165

## ------------------------------------------------------------------ lengthout

DESCRIPTION="issue 165: fastq_filter --lengthout is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --lengthout \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --lengthout adds sequence length"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --lengthout \
        --fastaout - | \
    grep -qx ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --lengthout adds sequence length without a terminal ';'"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --lengthout \
        --fastaout - | \
    grep -q ">s;length=1;" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 165: derep_fulllength --lengthout is zero when length is null"
printf ">s\n\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 0 \
        --quiet \
        --lengthout \
        --output -  | \
    grep -qx ">s;length=0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --eeout and --lengthout can be used at the same time"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --lengthout \
        --fastaout - | \
    grep "^>s" | \
    grep ";ee=" | \
    grep -q ";length=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --eeout and --lengthout (no extra ';')"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --lengthout \
        --fastaout - | \
    grep -q ";;" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --lengthout replaces sequence length if already present"
printf "@s;length=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --lengthout \
        --fastaout - | \
    grep -qx ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter without --lengthout headers with length are untouched"
printf "@s;length=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --fastaout - | \
    grep -qx ">s;length=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter without --lengthout headers with length are untouched (final ';')"
printf "@s;length=2;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --fastaout - | \
    grep -qx ">s;length=2;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## -------------------------------------------------------------------- xlength

DESCRIPTION="issue 165: fastq_filter --xlength is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --xlength removes sequence length"
printf "@s;length=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --fastaout - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --xlength removes sequence length and dangling ';'"
printf "@s;length=1;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --fastaout - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter without --xlength headers with length are untouched"
printf "@s;length=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --fastaout - | \
    grep -qx ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter without --xlength headers with length are untouched (final ';')"
printf "@s;length=1;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --fastaout - | \
    grep -qx ">s;length=1;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --xlength is silent if sequence length is missing"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --fastaout - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --xlength dangling ';'"
printf "@s;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --fastaout - | \
    grep -qx ">s;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --lengthout and --xlength can be used at the same time (#1)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --lengthout \
        --fastaout - | \
    grep -q ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --lengthout and --xlength can be used at the same time (#2)"
printf "@s;length=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --lengthout \
        --fastaout - | \
    grep -q ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                               Make OTU tables                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/166

# OTU tables can be created directly with the --otutabout and --biomout
# options of usearch_global / the clustering commands; already covered in
# usearch_global.sh and cluster_size.sh


#******************************************************************************#
#                                                                              #
#   Add idoffset argument for clustering of non-overlapped paired-end reads    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/167

# not testable (pull request proposing an --idoffset argument for clustering
# non-overlapped paired-end reads; the option is not present in vsearch)


#******************************************************************************#
#                                                                              #
#                  Output expected errors to fasta format too                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/168

## --eeout (expected errors in the header) used to work only with --fastqout;
## it must also work with --fastaout. Fixed in 1.11.1.
DESCRIPTION="issue 168: --fastq_filter --eeout adds expected errors to FASTA output"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --eeout \
        --fastaout - \
        --quiet | \
    grep -q ";ee=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                         Compilation error [Fasta.c]                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/169

# not testable (compilation error caused by a typo in a BZLIB check in
# fasta.cc)


#******************************************************************************#
#                                                                              #
#                          Windows Executable Version                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/170

# not testable (request for a Windows executable)


#*****************************************************************************#
#                                                                             #
#               Segmentation fault with empty query (issue 171)               #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="issue 171: no segmentation fault when a query is empty"
printf ">seq1\n\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        -db <(printf ">ref1\nACGT\n") \
        --id 0.97 \
        --quiet \
        --alnout - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#        Windows Modifications For Compilation with Visual Studio 2015         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/172

# not testable (pull request with Windows / Visual Studio 2015 build
# modifications)


#******************************************************************************#
#                                                                              #
#            Indicate matching strand in uc file when dereplicating            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/173

## the fifth column of the H lines in the --uc file must contain the matching
## strand (+ or -) when dereplicating with --strand both; fixed in 1.11.1.
## Here the second sequence is the reverse complement of the first, so it
## matches on the minus strand.
DESCRIPTION="issue 173: --derep_fulllength --uc reports the matching strand on H lines"
printf ">a\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n>b\nGGGGGGGGGGGGGGGGTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --strand both \
        --uc - \
        --quiet | \
    awk '$1 == "H" && $5 == "-" {found = 1} END {exit found ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#       Improve error message when FASTQ quality values are out of range       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/174

## the error message for out-of-range FASTQ quality values was improved to
## indicate the offending value and the accepted range (fixed in 2.0.4),
## pointing users towards the --fastq_qmax and related options
DESCRIPTION="issue 174: out-of-range FASTQ quality gives an informative error (value and range)"
printf "@s1\nACGT\n+\n~~~~\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 64 \
        --log /dev/null 2>&1 | \
    grep -q "out of range (0-41)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#               Merge pair fails when there are empty sequences                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/175

## FASTQ entries with an empty sequence used to trigger a fatal error
## ("Empty sequence line"); they are now accepted. Here both the empty entry
## and the normal one are read.
DESCRIPTION="issue 175: an empty FASTQ sequence is accepted (no fatal error)"
printf "@s1\n\n+\n\n@s2\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Read 2 sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#       Compute evalues and bit scores using Karlin-Altschul statistics        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/176

# e-values and bit scores (Karlin-Altschul statistics) are only defined for
# local alignments, while vsearch only performs global alignments. They are
# therefore not computed: the blast6out evalue is always -1 and the bit score
# always 0 (see the test under issue 179).


#******************************************************************************#
#                                                                              #
#                       uchime_denovo on very long reads                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/177

# not testable (a question about chimera detection on very long reads: the
# query is split into 4 parts, with no option to change this number; no bug
# or reproducer)


#******************************************************************************#
#                                                                              #
#  cluster_smallmem: "Unable to allocate enough memory" error on a very large  #
#                                    dataset                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/178

# not testable (memory exhaustion when clustering a very large dataset
# (~37 GB, 64 million sequences); cannot be reproduced with a small input)


#******************************************************************************#
#                                                                              #
#                     Wrong values in the blast6out table                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/179

## not a bug (usearch compatibility): in the --blast6out output the query and
## target start/end columns are not the alignment coordinates. qlo and tlo are
## always 1 (for an alignment), qhi and thi are the alignment length, the
## e-value is always -1 and the bit score always 0 (see issue 176).
DESCRIPTION="issue 179: --blast6out reports fixed start/end coordinates and -1/0 for evalue/bits"
printf ">q\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --blast6out - \
        --quiet | \
    awk -F "\t" '$7 == 1 && $8 == 32 && $9 == 1 && $10 == 32 && $11 == "-1" && $12 == 0 {ok = 1} END {exit ok ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#             New option for trimming the sequence based on maxEE              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/180

## the request to trim a read based on its expected error was implemented as
## the --fastq_truncee option, which truncates the read where the cumulative
## expected error would exceed the given value
DESCRIPTION="issue 180: --fastq_truncee truncates the read at the expected-error threshold"
printf "@s1\nACGTACGTACGT\n+\nIIII++++++++\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee 0.5 \
        --fastaout - \
        --quiet | \
    grep -A 1 "^>s1" | \
    grep -qx "ACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#     N-tails are converted to A-tails in consensus sequences (issue 181)     #
#                                                                             #
#*****************************************************************************#
##
## https://github.com/torognes/vsearch/issues/181

## In vsearch 1.11.1 and older, ambiguous nucleotide symbols (N) were
## replaced with A.

DESCRIPTION="issue 181: N-tails are preserved in consensus sequences"
printf ">s1\nACGTNNN\n>s2\nACGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.5 \
        --minseqlength 1 \
        --quiet \
        --consout -  | \
    grep -q "NNN$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Note: vsearch offers a --fastq_filter --fastq_trunclen_keep positive
# integer that allows to truncate fastq reads, but (as of early 2023)
# there are no option to pad shorter sequences with Ns, or to do the
# same for fasta entries.


#*****************************************************************************#
#                                                                             #
#                --query_cov and --userfield qcov (issue 182)                 #
#                                                                             #
#*****************************************************************************#

# DESCRIPTION="query coverage filtering works (issue 182)"
# QUERY=$(mktemp)
# DATABASE=$(mktemp)
# NOTMATCHED=$(mktemp)
# USEROUT=$(mktemp)
# ALN=$(mktemp)
# COVERAGE="0.90"
# cat > ${QUERY} <<'EOT'
# >query
# CTGGCTCAGG
# EOT

# cat > ${DATABASE} <<'EOT'
# >target
# CTGGCTCAGG
# EOT

# "${VSEARCH}" \
#     --usearch_global ${QUERY} \
#     --db ${DATABASE} \
#     --notmatched ${NOTMATCHED} \
#     --userout ${USEROUT} \
#     --query_cov ${COVERAGE} \
#     --alnout ${ALN} \
#     --id 0.7 \
#     --minseqlength 1 \
#     --rowlen 80 \
#     --output_no_hits \
#     --userfields query+target+id+qcov > /dev/null 2> /dev/null

# ## query_cov: (matches + mismatches) / query sequence length. Internal or terminal gaps are not taken into account.

# echo "userout"
# [[ -s ${USEROUT} ]] && cat ${USEROUT}
# echo "not matched"
# [[ -s ${NOTMATCHED} ]] && cat ${NOTMATCHED}
# echo "alignment"
# [[ -s ${ALN} ]] && cat ${ALN}

# ## Clean
# rm "${QUERY}" "${ALN}" "${NOTMATCHED}" "${USEROUT}" "${DATABASE}"

## hits with a query coverage below --query_cov were wrongly kept in the
## --userout results; fixed. Here the query matches the target over only half
## of its length (qcov = 50%), so it must be excluded at --query_cov 0.95...
DESCRIPTION="issue 182: a hit below --query_cov is excluded from --userout"
printf ">q\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.5 \
        --minseqlength 1 \
        --query_cov 0.95 \
        --userfields query \
        --userout - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ...but kept when the threshold is low enough
DESCRIPTION="issue 182: the same hit is kept when --query_cov is low enough"
printf ">q\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.5 \
        --minseqlength 1 \
        --query_cov 0.4 \
        --userfields qcov \
        --userout - \
        --quiet | \
    grep -qx "50.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#           Comparing vsearch chimera detection with uchime - denovo           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/183

# not testable (user error, not a bug: the input used the UCHIME defline
# format ">name/ab=100.0/" instead of the usearch/vsearch ">name;size=100;"
# format, so abundances were not read; with the correct format chimeras are
# detected as expected)


#******************************************************************************#
#                                                                              #
#             Segmentation fault when masking very long sequences              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/184

## masking very long sequences caused a segmentation fault (due to the use of
## alloca); fixed in 2.0.1
DESCRIPTION="issue 184: --fastx_mask does not crash on a very long sequence"
LONG=$(head -c 50000 /dev/zero | tr '\0' 'A')
printf ">s1\n%s\n" "${LONG}" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset LONG


#******************************************************************************#
#                                                                              #
#                            Implement cluster_otus                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/185


#******************************************************************************#
#                                                                              #
#     --minseqlength and --maxseqlength options do not work for filtering      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/186

## the general --minseqlength / --maxseqlength options do not apply to
## fastq_filter; the --fastq_minlen and --fastq_maxlen options were added to
## fastx_filter and fastq_filter in 2.1.0 to filter on length
DESCRIPTION="issue 186: --fastq_filter --fastq_minlen and --fastq_maxlen filter on length"
printf "@short\nACGT\n+\nIIII\n@mid\nACGTACGTACGT\n+\nIIIIIIIIIIII\n@long\nACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minlen 5 \
        --fastq_maxlen 20 \
        --fastaout - \
        --quiet | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">mid " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                   Illegal instruction (issue 187)                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/187

# compilation issue, nothing to test


#******************************************************************************#
#                                                                              #
#                            Rolling hash function?                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/188

# not testable (internal: the time spent hashing is negligible, so a rolling
# hash function will not be used)


#******************************************************************************#
#                                                                              #
#                          Allow shorter word lengths                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/189

## the --wordlength option was restricted to 7-12; shorter word lengths (down
## to 3) are allowed since version 2.1.0, which helps with very short sequences
DESCRIPTION="issue 189: --wordlength accepts a value as low as 3"
printf ">q\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --wordlength 3 \
        --userfields target \
        --userout - \
        --quiet | \
    grep -qx "t" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                  Filtering options for fastA sequences also                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/190

## filtering options previously limited to FASTQ (e.g. --fastq_maxns) became
## available for FASTA input through the --fastx_filter command in 2.1.0
## (also covered in fastx_filter.sh)
DESCRIPTION="issue 190: --fastx_filter applies --fastq_maxns to FASTA input"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTNNNN\n>b\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_maxns 0 \
        --fastaout - \
        --quiet | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">b " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                              typo in the manual                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/191

# not testable (manual typo: the --quiet description said "stdout and stdout"
# instead of "stdout and stderr"; fixed in 2.0.4)


#******************************************************************************#
#                                                                              #
#            Improve documentation of fastq_stats and fastq_eestats            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/192

# not testable (documentation: the output of --fastq_stats and
# --fastq_eestats is now documented in the manual)


#******************************************************************************#
#                                                                              #
#         Add option to write non-chosen subsamples to a separate file         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/193

## the reads not chosen by --fastx_subsample can be written to a separate file
## with --fastaout_discarded (e.g. to split a dataset into two subsets). Here
## one of two sequences is sampled and the other goes to the discarded file.
DESCRIPTION="issue 193: --fastx_subsample writes non-chosen reads to --fastaout_discarded"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 1 \
        --randseed 1 \
        --fastaout /dev/null \
        --fastaout_discarded - \
        --quiet | \
    grep -c "^>" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#          --fastq_stats fails on fastq files with an offset of +64?           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/194

## not a bug: with phred+64 full-range FASTQ files the quality values can
## exceed the default maximum (41), so --fastq_qmax must be raised. Without
## it the command fails; with --fastq_qmax 62 it succeeds.
DESCRIPTION="issue 194: --fastq_stats errors on out-of-range quality without --fastq_qmax"
printf "@s1\nACGT\n+\n~~~~\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 64 \
        --log /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 194: --fastq_stats succeeds on the same file with --fastq_qmax 62"
printf "@s1\nACGT\n+\n~~~~\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 64 \
        --fastq_qmax 62 \
        --log /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                         redundancy in read searching                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/195

# not testable (a pipeline question, not a bug: searching the original reads
# against the OTUs is needed to recover per-sample abundances lost during
# dereplication)


#******************************************************************************#
#                                                                              #
#                    Document the UC format in the manpage                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/196

# not testable (documentation: the UC format is now documented in the manpage
# for clustering, dereplication and searching)


#******************************************************************************#
#                                                                              #
#               Extend --fastx_subsample to support FASTQ files                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/197

# --fastx_subsample already accepts FASTQ files (with --fastqout, --fastq_qmin,
# --fastq_qmax, --fastq_ascii); only the manual needed updating. Already
# covered in fastx_subsample.sh (see also issue 120)


#******************************************************************************#
#                                                                              #
#                              Update the manpage                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/198

# not testable (documentation: the manpage was updated to describe the
# relabelling options added to --shuffle and the --xsize option)


#******************************************************************************#
#                                                                              #
#       --top_hits_only limited to --matched instead of also --dbmatched       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/199

## --top_hits_only keeps only the hit(s) with the highest identity in the
## --userout (and related) output; it requires --maxaccepts > 1. Here the
## query matches db1 perfectly and db2 with one mismatch: only db1 (the top
## hit) is reported. (For usearch compatibility it does not apply to
## --dbmatched.)
DESCRIPTION="issue 199: --top_hits_only keeps only the best-identity hit in --userout"
printf ">q\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">db1\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n>db2\nTCGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --maxaccepts 2 \
        --maxrejects 0 \
        --top_hits_only \
        --userfields target \
        --userout - \
        --quiet | \
    tr "\n" " " | \
    grep -qx "db1 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                                fulldp option                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/200

## the --fulldp option is always on; it is accepted (and ignored) only for
## compatibility with usearch scripts
DESCRIPTION="issue 200: --fulldp is accepted (always on, ignored)"
printf ">q\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --fulldp \
        --quiet \
        --userout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Missing H record in --uc output when prefix dereplicating two sequences of  #
#                                unequal length                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/201

## --derep_prefix of two sequences of unequal length (one being a prefix of
## the other) must produce an H record in the --uc output for the shorter,
## merged sequence; fixed
DESCRIPTION="issue 201: --derep_prefix writes an H record for the merged shorter sequence"
printf ">a;size=10\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=1\nACGTACGTACGTACGTACGTACGTACGTACG\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --minseqlength 1 \
        --uc - \
        --quiet | \
    awk '$1 == "H" {found = 1} END {exit found ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                             Implement relabel @                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/202


#*****************************************************************************#
#                                                                             #
#         fastq_trunclen and discarded short sequences (issue 203)            #
#                                                                             #
#*****************************************************************************#
##
## https://github.com/torognes/vsearch/issues/203

DESCRIPTION="issue 203: discard entries shorter than --fastq_trunclength value"
printf "@seq1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen 5 \
        --quiet \
        --fastqout - \
        2> /dev/null | \
    grep -q "seq1" && \
    failure "${DESCRIPTION}" || \
        success  "${DESCRIPTION}"

DESCRIPTION="issue 203: keep entries equal or longer than --fastq_trunclength value"
printf "@seq1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen 4 \
        --quiet \
        --fastqout - \
        2> /dev/null | \
    grep -q "seq1" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#        fastx_filter ignores input sequence abundance when relabeling         #
#                              (issue 204)                                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/204
#
# --fastx_filter ignores input sequence abundances when relabeling
# with fasta input, --sizein and --sizeout options

DESCRIPTION="issue 204: fastx_filter reports sizein when relabeling fasta"
printf ">seq1;size=5;\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sizein \
        --relabel_md5 \
        --sizeout \
        --quiet \
        --fastaout - 2> /dev/null | \
    grep -qE ";size=5$" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                            Old versions on conda                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/205

# not testable (request to publish older vsearch versions on conda)


#******************************************************************************#
#                                                                              #
#                       Fatal error when reading ncbi-nr                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/206

## not a bug: vsearch does not work with amino-acid sequences and rejects the
## gap character "-" in sequences with a fatal error (the user was reading the
## NCBI nr protein database)
DESCRIPTION="issue 206: the gap character '-' in a sequence triggers a fatal error"
printf ">s1\nACGT-ACGT\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --minseqlength 1 \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#            Use cluster number in column 2 on H-lines in uc files             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/207

## not a bug (usearch compatibility, documentation updated): on the H lines of
## a --uc file, column 2 holds the ordinal number of the centroid sequence the
## hit matches (column 10), not the cluster number. Here the second sequence
## matches the first (ordinal 0).
DESCRIPTION="issue 207: --uc H line column 2 is the centroid ordinal, pointing to column 10"
printf ">a\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n>b\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.9 \
        --minseqlength 1 \
        --uc - \
        --quiet | \
    awk -F "\t" '$1 == "H" {found = 1; ok = ($2 == "0" && $10 == "a")} END {exit (found && ok) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                       dereplication option suggestion                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/208

# not testable (sample-aware dereplication was not implemented; the suggested
# workflow relies on external scripts to build a sample mapping file)


#******************************************************************************#
#                                                                              #
#                         An error when running v2.30                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/209

# not testable (runtime error caused by linking the binary against a newer
# libstdc++ than available; GLIBCXX_3.4.21 not found)


#******************************************************************************#
#                                                                              #
#                          Sintax taxonomy classifier                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/210

# a SINTAX taxonomy classifier was later added as the --sintax command;
# already covered in sintax.sh


#******************************************************************************#
#                                                                              #
#                   gapopen and gapext - effect as expected?                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/211

# not a bug (alignment question): changing only --gapext has little effect
# because the total number of inserted bases is fixed by the length
# difference; the identity reflects the fixed number of gap columns
# (matches / length of the longer sequence)


#******************************************************************************#
#                                                                              #
#   FORBIDDEN INTERNAL GAPS and MISSING OF CLUSTERING FOR SEQUENCES WITH THE   #
#                                  LENGTH > 7                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/212

# split into issues 213 (internal gaps in msaout) and 214 (short sequences).
# The third reported problem (truncated descriptions in the output) is solved
# by specifying the --notrunclabels option.


#******************************************************************************#
#                                                                              #
# Internal gaps occur in alignments even with infinite internal gap penalties  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/213

# not testable (works as intended): internal gaps may appear in the multiple
# alignment produced by --msaout because it uses the simple center-star method
# (pairwise alignments against the centroid). The pairwise alignments in
# --alnout are correct.


#******************************************************************************#
#                                                                              #
#                 Improve behaviour with very short sequences                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/214

## the kmer-based heuristic can be turned off for very short sequences with
## --minwordmatches 0, allowing them to be searched/clustered; added in 2.3.1
DESCRIPTION="issue 214: --minwordmatches 0 allows matching very short sequences"
printf ">q\nACGTAC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTAC\n") \
        --id 0.9 \
        --minseqlength 1 \
        --minwordmatches 0 \
        --userfields target \
        --userout - \
        --quiet | \
    grep -qx "t" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                   --top_hits_only reports only one top hit                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/215

## --top_hits_only keeps only the best-identity hits, but reporting *all* the
## tied top hits requires lifting the accept/reject limits (--maxaccepts 0,
## --maxrejects 0) and adding --uc_allhits. Here two database sequences match
## the query perfectly and both must be reported.
DESCRIPTION="issue 215: --top_hits_only with --uc_allhits reports all tied top hits"
printf ">q\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">db1\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n>db2\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --top_hits_only \
        --uc_allhits \
        --userfields target \
        --userout - \
        --quiet | \
    sort | \
    tr "\n" " " | \
    grep -qx "db1 db2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Use "=" in column 8 of uc files with perfect alignment also when ignoring   #
#                                 terminal gaps                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/216

## like usearch 6/7, --cluster_fast writes "=" in column 8 of the H lines of
## a --uc file when the sequences are identical once terminal gaps are
## ignored. Here the second sequence is the first plus a 2 nt terminal
## extension, so the alignment is perfect except for the terminal gap.
DESCRIPTION="issue 216: --cluster_fast --uc uses '=' in column 8 when identical ignoring terminal gaps"
printf ">a\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n>b\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGATT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.9 \
        --minseqlength 1 \
        --uc - \
        --quiet | \
    awk -F "\t" '$1 == "H" {found = 1; ok = ($8 == "=")} END {exit (found && ok) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#             Ideas for potential improvement in accuracy or speed             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/217

# not testable (a discussion of ideas for improving accuracy or speed, e.g.
# weighting kmers by frequency or allowing one mismatch per kmer)


#******************************************************************************#
#                                                                              #
#                     Improve multiple sequence alignment                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/218


#******************************************************************************#
#                                                                              #
#            Describe a standard metabarcoding pipeline for vsearch            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/219

# not testable (documentation: an example metabarcoding pipeline was added to
# the VSEARCH wiki)


#******************************************************************************#
#                                                                              #
#                    clustering: profiles do not make sense                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/220

## the --profile output (and its documentation) was fixed in 2.3.4: each row
## has eight integer columns (0-based position, consensus, #A, #C, #G, #T/U,
## #gaps, #ambiguous). Here position 0 has one A and one ambiguous symbol (R),
## so the row is "0 A 1 0 0 0 0 1".
DESCRIPTION="issue 220: --profile has eight columns and counts ambiguous symbols separately"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nRCGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.9 \
        --minseqlength 1 \
        --profile - \
        --quiet | \
    awk -F "\t" 'NR == 2 {ok = (NF == 8 && $1 == 0 && $2 == "A" && $3 == 1 && $7 == 0 && $8 == 1)} END {exit ok ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Output file for --fastq_eestats specified with --output option, not --log   #
#                                    option                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/221

## the statistics table of --fastq_eestats is written to the file given with
## --output (not --log); the help text was corrected in 2.4.0
DESCRIPTION="issue 221: --fastq_eestats writes its table to --output"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet | \
    grep -q "^Pos" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                   Port VSEARCH to the POWER8 architecture                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/222

# not testable (porting to the POWER8 architecture, including AltiVec
# replacements for the SIMD intrinsics)


#******************************************************************************#
#                                                                              #
#                         Correctly detect named pipes                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/223

## named pipes (FIFOs) must be detected and read correctly; fixed in 2.4.0
DESCRIPTION="issue 223: vsearch reads input from a named pipe (FIFO)"
FIFO=$(mktemp -u)
mkfifo "${FIFO}"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${FIFO}" &
"${VSEARCH}" \
    --fastx_uniques "${FIFO}" \
    --minseqlength 1 \
    --fastaout - \
    --quiet | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
wait
rm -f "${FIFO}"


#******************************************************************************#
#                                                                              #
#                     Qiime open reference does not work ?                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/224

# not testable (a QIIME open-reference usage question, redirected to the
# QIIME / VSEARCH forums)


#******************************************************************************#
#                                                                              #
#        Add minuniquesize/maxuniquesize to the command --fastx_filter         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/225

## abundance-based filtering was added to --fastx_filter through the --minsize
## and --maxsize options (in 2.5.0); here the size=1 sequence is removed
DESCRIPTION="issue 225: --fastx_filter --minsize filters on abundance"
printf ">a;size=1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=5\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sizein \
        --minsize 2 \
        --fastaout - \
        --quiet | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">b;size=5 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                            fastq_eestats2 feature                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/226

# the --fastq_eestats2 command (and the --ee_cutoffs / --length_cutoffs
# options) was added in 2.5.0; already covered in fastq_eestats2.sh


#******************************************************************************#
#                                                                              #
#             Truncate header when converting from FASTQ to FASTA              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/227

# closed without a change: the developer decided not to additionally truncate
# FASTQ headers when converting to FASTA ("let the headers be"). The usual
# truncation at the first space still applies unless --notrunclabels is given
# (see issue 81).


#******************************************************************************#
#                                                                              #
#                Overflow in fastq_stats with large FASTQ files                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/228

# not testable (integer overflow in fastq_stats with FASTQ files larger than
# 4 G nucleotides or sequences; cannot be reproduced with a small input)


#******************************************************************************#
#                                                                              #
#                 Compatibility with older versions of usearch                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/229


#******************************************************************************#
#                                                                              #
#  Using Vsearch to produce a consensus OTU table from non-overlapping reads   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/230

# not testable (a usage question: producing a consensus OTU table that counts
# only OTUs detected in both non-overlapping reads is not possible with
# vsearch)


#******************************************************************************#
#                                                                              #
#         Add fastq_maxdiffpct option (% difference for merging pairs)         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/231

## the --fastq_maxdiffpct option sets the maximum percentage of differing
## bases allowed in the overlap when merging pairs. The pair below has one
## mismatch in the overlap: it is rejected at 0.0% but merged at 100%.
DESCRIPTION="issue 231: --fastq_maxdiffpct 0.0 rejects a pair with a mismatch in the overlap"
FWD=$(mktemp)
REV=$(mktemp)
printf "@r\nGCTAAAGACAATTACATAACATACACGTCAGCACGAAACT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${FWD}"
printf "@r\nCGATTCACACTGGGCCAACAAGTTTCGTGCTGACTTGTAT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${REV}"
"${VSEARCH}" \
    --fastq_mergepairs "${FWD}" \
    --reverse "${REV}" \
    --fastq_maxdiffpct 0.0 \
    --fastqout - \
    --quiet 2>/dev/null | \
    grep -q "^@r" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${FWD}" "${REV}"

DESCRIPTION="issue 231: --fastq_maxdiffpct 100 merges the same pair"
FWD=$(mktemp)
REV=$(mktemp)
printf "@r\nGCTAAAGACAATTACATAACATACACGTCAGCACGAAACT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${FWD}"
printf "@r\nCGATTCACACTGGGCCAACAAGTTTCGTGCTGACTTGTAT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${REV}"
"${VSEARCH}" \
    --fastq_mergepairs "${FWD}" \
    --reverse "${REV}" \
    --fastq_maxdiffpct 100 \
    --fastqout - \
    --quiet 2>/dev/null | \
    grep -q "^@r" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FWD}" "${REV}"


#******************************************************************************#
#                                                                              #
#        Recording query reads that fail to cluster as "N" or "No hit"         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/232

## queries that fail to match the reference must be recorded as N records in
## the --uc file when --output_no_hits is specified; fixed in 2.4.3
DESCRIPTION="issue 232: --usearch_global --uc --output_no_hits writes an N record for a no-hit query"
printf ">q\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --output_no_hits \
        --uc - \
        --quiet | \
    awk '$1 == "N" {found = 1} END {exit found ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#               Progress bar during shuffling always shows 100%                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/233

# not testable (cosmetic: the progress indicator during shuffling always
# showed 100%; fixed in 2.4.3)


#******************************************************************************#
#                                                                              #
#                          Add support for udb files                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/234

# support for UDB files was added (--makeudb_usearch, --udbinfo, --udbstats,
# --udb2fasta, and automatic UDB detection by --db); already covered in
# makeudb_usearch.sh


#******************************************************************************#
#                                                                              #
#         Can we have a function of write to standard output and error         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/235

# not testable (a usage question: the on-screen report goes to stderr and can
# be captured with "2> file"; some commands also write to --log or --output)


#******************************************************************************#
#                                                                              #
#                        OTU sequence short than before                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/236

# not testable (a usage question, not a bug: --consout outputs the consensus
# (which can be shorter than the centroid); use --centroids for the full-length
# representative sequence)


#******************************************************************************#
#                                                                              #
#              should --log capture the output of --fastq_chars?               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/237

DESCRIPTION="issue 237: --fastq_chars --log --quiet does no write to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
# when in doubt, --fastq_chars should assume an offset of +33 rather than +64  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/238

DESCRIPTION="issue 238: --fastq_chars guesses quality offset +33 (when ambiguous)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                   shuffle silently converts fastq to fasta                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/239

# --shuffle, --sortbysize and --sortbylength accept fastq input and write
# fasta output; this is now documented behaviour (see the respective
# manpages) and is already covered by the "reads fastq and returns fasta"
# tests in shuffle.sh, sortbysize.sh and sortbylength.sh


#******************************************************************************#
#                                                                              #
#                           Typo in warning message                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/240

## the --shuffle command reads fasta; when invalid characters are stripped the
## warning message must refer to a "fasta" (not "fastq") file
DESCRIPTION="issue 240: --shuffle invalid-character warning refers to a FASTA file"
"${VSEARCH}" \
    --shuffle <(printf ">s\nAAAA;size=12\n") \
    --output /dev/null 2>&1 | \
    grep -qi "invalid characters stripped from FASTA file" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#       what should average cluster size be when there are no clusters?        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/241

## when there are no sequences left to cluster, the average cluster size used
## to be reported as "-nan"; vsearch now simply reports "0 unique sequences"
## without an average, median or max
DESCRIPTION="issue 241: no '-nan' is reported when there are no sequences to dereplicate"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output /dev/null 2>&1 | \
    grep -qi "nan" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                           Add --relabel_ids option                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/242

# not implemented (relabelling with the concatenated IDs of all merged
# sequences); the newly added --derep_id command may help in related cases
# (already covered in derep_id.sh)


#******************************************************************************#
#                                                                              #
#                           Dealing with a full disk                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/243

# in vsearch v2.31.0, writing output to a full device (e.g. --uc /dev/full or
# --output /dev/full) still returns no error message and exit status 0; the
# ENOSPC write failure is not detected. This differs from the behaviour the
# issue asked for; flagged for human review.


#******************************************************************************#
#                                                                              #
#                          Lifting memory limitation                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/244

# not testable (vsearch is not designed for very long sequences (>~10 kbp) or
# the corresponding memory needs; the limitation will not be lifted)


#******************************************************************************#
#                                                                              #
#         query end position correct in blast6 output when Searching?          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/245

# not a bug (clarified by the reporter): in the --blast6out output, column 8
# is qhi (the length of the pairwise alignment), not the end coordinate of the
# alignment in the query sequence. See the test under issue 179.


#******************************************************************************#
#                                                                              #
#                            link broken in README                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/246

# not testable (a broken man-page link in the README was fixed)


#******************************************************************************#
#                                                                              #
#                fix link to manpage in README.md to close #246                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/247

# not testable (pull request fixing the man-page link in README.md, see
# issue 246)


#******************************************************************************#
#                                                                              #
#      fastx_subsample: wrong error message when omiting --sample_pct or       #
#                                 --sample_size                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/248

## when neither --sample_pct nor --sample_size is given, --fastx_subsample
## must report "Specify either --sample_pct or --sample_size" (not the
## misleading "...not both" message)
DESCRIPTION="issue 248: --fastx_subsample error message when neither sample option is given"
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --fastqout /dev/null 2>&1 | \
    grep -qx "Fatal error: Specify either --sample_pct or --sample_size" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#             change the warning message for discarded sequences?              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/249

## the message for sequences discarded because of the default length filter
## was changed from a generic "WARNING" to an informative "minseqlength N:
## X sequence(s) discarded." (with correct singular/plural)
DESCRIPTION="issue 249: discarded-sequences message mentions minseqlength and the count"
printf ">a\nAA\n>b\nA\n" | \
    "${VSEARCH}" \
        --shuffle - \
        --minseqlength 2 \
        --output /dev/null 2>&1 | \
    grep -qx "minseqlength 2: 1 sequence discarded." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#     vsearch help or version should return the latest vsearch publication     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/250

## the vsearch citation (Rognes et al. 2016, PeerJ) is printed with the -v
## and --version options, to make users aware of the published reference
DESCRIPTION="issue 250: -v reports the vsearch publication (PeerJ citation)"
"${VSEARCH}" \
    -v 2>&1 | \
    grep -q "PeerJ" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#   fastq_stats reports 4 possible truncation lengths for a read of length 3   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/251

# not testable here (cosmetic numbering of the --fastq_stats truncation
# table: reported lengths were off by one and a nonsense last line was shown,
# matching usearch; the table layout is not asserted by these tests)



#******************************************************************************#
#                                                                              #
#     fastq_eestats computation of quartiles and median for even number of     #
#                                   records?                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/252

# not testable (documentation: quartiles and median of Q and EE are computed
# with the nearest-rank percentile method)



#******************************************************************************#
#                                                                              #
#                Warning could not find object file symbol for                 #
#                     increment_counters_from_bitmap_sse2                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/253

# not testable (build: cpu.cc must be compiled twice, with and without the
# -DSSSE3 option)



#******************************************************************************#
#                                                                              #
#     cluster_smallmem ignores sequences that contain unknown nucleotides      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/254

# not a bug: the difference with usearch comes from masking, which is on by
# default in vsearch; use --qmask none to disable it (see also issue 158)



#******************************************************************************#
#                                                                              #
#      command allpairs_global should accept the output option fastapairs      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/255

## --fastapairs is a valid output option but was not accepted by
## --allpairs_global, --usearch_global and --search_exact, which failed with a
## non-informative "No output files specified" error; fixed
DESCRIPTION="issue 255: --allpairs_global accepts --fastapairs"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --minseqlength 1 \
        --fastapairs - \
        --quiet | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                       compilation warning with GCC 7.1                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/256

# not testable (compilation warning in results.cc with GCC 7.1/7.2)



#******************************************************************************#
#                                                                              #
#                iddef, wrong definition for BLAST similarity?                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/257

## not a bug (documentation was wrong): the BLAST identity definition
## (--iddef 4) is implemented exactly like --iddef 1 (matches / alignment
## length), not like --iddef 2. The two must give the same value.
DESCRIPTION="issue 257: --iddef 4 (BLAST) gives the same identity as --iddef 1"
ID1=$(printf ">q\nAAAAAAAAAA\n" | "${VSEARCH}" --usearch_global - --db <(printf ">t\nAAAAAAAAAATT\n") --id 0.1 --iddef 1 --minseqlength 1 --userfields id --userout - --quiet 2>/dev/null)
ID4=$(printf ">q\nAAAAAAAAAA\n" | "${VSEARCH}" --usearch_global - --db <(printf ">t\nAAAAAAAAAATT\n") --id 0.1 --iddef 4 --minseqlength 1 --userfields id --userout - --quiet 2>/dev/null)
[ "${ID1}" = "${ID4}" ] && [ "${ID1}" = "83.3" ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset ID1 ID4



#******************************************************************************#
#                                                                              #
#             iddef, clarify the Marine Biological Lab definition              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/258

# documentation clarification of the MBL identity (--iddef 3): each gap
# opening (internal or terminal) counts as a single mismatch. The computation
# itself is covered by the test under issue 71.



#******************************************************************************#
#                                                                              #
#            CIGAR strings differ between samout and other outputs             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/259

## not a bug (documented): the CIGAR string in the SAM output is relative to
## the target (reference) and follows the SAM spec (a count before every
## operation), while the alignment string reported by --userfields caln is
## relative to the query. For the same alignment the two therefore differ.
DESCRIPTION="issue 259: SAM CIGAR (target-relative) differs from caln (query-relative)"
printf ">query\nAAGGGGGGGGGCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">target\nAAGGGGAAAAGGGGCC\n") \
        --minseqlength 1 \
        --id 0.1 \
        --userfields caln \
        --userout - \
        --quiet | \
    grep -qx "6M3I7MD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 259: SAM CIGAR uses the SAM convention (counts, target point of view)"
printf ">query\nAAGGGGGGGGGCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">target\nAAGGGGAAAAGGGGCC\n") \
        --minseqlength 1 \
        --id 0.1 \
        --samout - \
        --quiet | \
    cut -f 6 | \
    grep -qx "6M3D7M1I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#             SAM format: wrong edit distance in optional tags                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/260

## SAM format:
# AS:i:? alignment score (i.e percent identity)
# XN:i:? next best alignment score (always 0?)
# XM:i:? number of mismatches
# XO:i:? number of gap opens (excluding terminal gaps)
# XG:i:? number of gap extensions (excluding terminal gaps)
# NM:i:? edit distance (sum of XM and XG)
# MD:Z:? variant string
# YT:Z:UU string representing alignment type

# Resolution (issue closed, not a bug): the edit distance is the
# number of mismatches plus the number of alignment positions holding a
# gap symbol. Each internal gap of length L contributes L edits, so the
# gap open must NOT be added a second time. vsearch stores the *full*
# internal gap length (open position included) in XG, hence
# NM = XM + XG is already the correct edit distance; adding XO would
# overcount by one per gap. The vsearch-sam(5) manpage documents this:
# XG is "Equivalent to the total length of internal gaps" and NM is the
# "sum of XM and XG (mismatches plus total internal gap length)".

# Qry  1 + ggggg----ggggg 10
#          |||||    |||||
# Tgt  1 + GGGGGCCCCGGGGG 14
# 14 cols, 10 ids (71.4%), 4 gaps (28.6%): edit distance = 0 + 4 = 4

# single internal gap of length 4, no mismatches: the edit distance NM
# equals the number of mismatches (XM) plus the total internal gap
# length (XG), i.e. 0 + 4 = 4
DESCRIPTION="issue 260: SAM NM is the edit distance (mismatches + total internal gap length)"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nGGGGGGGGGG\n') \
    --db <(printf '>r1\nGGGGGCCCCGGGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - 2> /dev/null | \
    tr "\t" "\n" | \
    grep -qx "NM:i:4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# for the same single gap of length 4, XG holds the full internal gap
# length (4, including the gap-opening position), not the number of gap
# extensions excluding opens (which would be 3)
DESCRIPTION="issue 260: SAM XG is the total internal gap length (gap open included)"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nGGGGGGGGGG\n') \
    --db <(printf '>r1\nGGGGGCCCCGGGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - 2> /dev/null | \
    tr "\t" "\n" | \
    grep -qx "XG:i:4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# combined alignment with one mismatch and one internal gap of length 2:
# NM = XM + XG = 1 + 2 = 3. The gap open (XO:i:1) is not added a second
# time, otherwise NM would wrongly be 4
DESCRIPTION="issue 260: SAM NM combines mismatches and gap length without double-counting gap opens"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nTGACGTGAATAGGCTAGCTAGTCAATTCCAGGTACGTACAGGTACA\n') \
    --db <(printf '>r1\nTGACCTGAATAGGCTAGCTAGTCAGGATTCCAGGTACGTACAGGTACA\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - 2> /dev/null | \
    tr "\t" "\n" | \
    grep -qx "NM:i:3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                     Allow users to turn off progress bar                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/261

## the --no_progress option turns off the progress indicator, also for
## interactive (non-pipe) use (see also issue 156)
DESCRIPTION="issue 261: --no_progress is accepted"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --no_progress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                  consensus sequence as clustering centroids                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/262

# not implemented: using the consensus sequence as the cluster centroid would
# be a different clustering algorithm; vsearch keeps the longest or most
# abundant sequence as centroid



#******************************************************************************#
#                                                                              #
#                  Option for minimum cluster size to output                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/263

# open issue (not covered): request for a --min_cluster_size option to avoid
# writing small clusters / singletons



#******************************************************************************#
#                                                                              #
#                               chimera.vsearch                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/264

# not testable (a mothur installation question, not a vsearch bug)



#******************************************************************************#
#                                                                              #
#               VSEARCH clustering sequences with masked regions               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/265

# open issue (not covered): masked regions are included in the alignment
# score (like usearch); --hardmask can be used to give them a zero score



#******************************************************************************#
#                                                                              #
#                     Ability to trim 3' end of sequences                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/266

## the --fastq_stripright option was added (in 2.5.0) to delete a given number
## of bases from the 3' end of the reads (a counterpart to --fastq_stripleft)
DESCRIPTION="issue 266: --fastq_stripright trims bases from the 3' end"
printf "@s1\nACGTACGT\n+\nIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_stripright 3 \
        --fastaout - \
        --quiet | \
    grep -A 1 "^>s1" | \
    grep -qx "ACGTA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#   Segmentation fault with certain characters in FASTQ files (issue 267)      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/267

# The header is empty, the sequence line is empty and the quality line
# contains an extended ascii character (here in octal notation)
DESCRIPTION="issue 267: --fastq_chars segmentation fault (non-ASCII symbols)"
printf "@\n\n+\n\351\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qi "Fatal error" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                         Rereplicate alignment files                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/268

# not a bug: --rereplicate (like other commands) rejects the gap character
# '-' in sequences with a fatal error, so aligned (gapped) fasta files cannot
# be rereplicated (see also issue 206)



#******************************************************************************#
#                                                                              #
#                Write unix man pages in markdown and convert?                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/269

# not testable (documentation tooling: writing manpages in markdown)



#******************************************************************************#
#                                                                              #
#                 losing sequences with vsearch --derep_prefix                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/270

# duplicate of issue 201 (missing H lines in the --derep_prefix uc output),
# fixed in version 2.1.1; see the test under issue 201



#******************************************************************************#
#                                                                              #
#            merge annotation separators in fastq and fasta headers            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/271

# open issue (not covered): when an annotation is added (e.g. ;ee=) to a
# header already ending with ';', two separators ';;' may appear



#******************************************************************************#
#                                                                              #
#  option xsize has no effect with certain commands and options (fastx_filter  #
#                                and chimeras)                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/272

## --xsize (remove the abundance annotation) had no effect with --fastx_filter
## (and with the --chimeras output of the uchime commands); fixed in 2.6.2
DESCRIPTION="issue 272: --fastx_filter --xsize removes the abundance annotation"
printf "@s;size=1;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --xsize \
        --fastqout - \
        --quiet | \
    head -1 | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#   For the fastq_eestats2 option the argument "-" is not treated as stdin     #
#                               (issue 323)                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/273

DESCRIPTION="issue 273: fastq_eestats2 treats \"-\" as stdin"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" --fastq_eestats2 - --output - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                      utax reference dataset vsearch                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/274

## this is a question, not a bug


#******************************************************************************#
#                                                                              #
#       Windows only: Incorrect alignments and consensus sequences after       #
#                                  clustering                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/275

# not testable (Windows-only: different consensus sequences after clustering)



#******************************************************************************#
#                                                                              #
#                             missing option --xee                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/276

## the --xee option (remove the expected-error ";ee=" annotation from headers,
## the counterpart of --eeout) was added in 2.11.0
DESCRIPTION="issue 276: --xee removes the expected-error annotation"
printf "@s;ee=0.5;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --xee \
        --fastqout - \
        --quiet | \
    head -1 | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#   Windows only: Using - as filename meaning stdin or stdout does not work    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/277

# not testable (Windows-only: "-" for stdin/stdout)



#******************************************************************************#
#                                                                              #
#       How to download the executable chimera.vsearch file for windows?       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/278

# not testable (a question about downloading the Windows executable)



#******************************************************************************#
#                                                                              #
#                Support for long database or query sequences?                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/279

# not testable (a question: vsearch becomes very slow for sequences longer
# than a couple of thousand base pairs)



#******************************************************************************#
#                                                                              #
#                   Feature request: online linkable manual                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/280

# not testable (documentation: request for an online HTML manual)



#******************************************************************************#
#                                                                              #
#                    Missing UDB commands in documentation                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/281

# not testable (documentation: the UDB commands were added to the manual)



#******************************************************************************#
#                                                                              #
#           Merging report: clarify the reasons why merging can fail           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/282

# open issue (not covered): clarify the merging-failure categories reported
# by --fastq_mergepairs



#******************************************************************************#
#                                                                              #
#                                    UNOISE                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/283

# the UNOISE amplicon-denoising algorithm was added as the --cluster_unoise
# command; already covered in cluster_unoise.sh



#******************************************************************************#
#                                                                              #
#     Fatal error: No output files specified vsearch (usearch_global with      #
#                                   consout)                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/284

## --consout is a clustering output and is not valid for --usearch_global
## (which performs a search, not clustering); it is rejected as an invalid
## option
DESCRIPTION="issue 284: --usearch_global rejects the clustering option --consout"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.9 \
        --minseqlength 1 \
        --consout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                Port VSEARCH to Linux on the ARM architecture                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/285

# not testable (porting to the ARM architecture, rewriting the SIMD code with
# NEON intrinsics)



#******************************************************************************#
#                                                                              #
#     vsearch --usearch_global always leads to Fatal error: File type not      #
#                                  recognized                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/286

## not a bug: an input that is neither valid FASTA nor FASTQ is rejected with
## "Fatal error: File type not recognized." (the user's file started with
## non-sequence script lines)
DESCRIPTION="issue 286: a non-FASTA/FASTQ input is rejected with 'File type not recognized'"
printf "this is not a sequence file\nrandom text\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGT\n") \
        --id 0.9 \
        --minseqlength 1 \
        --alnout /dev/null 2>&1 | \
    grep -q "File type not recognized" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                                UCHIME2 and 3                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/287

# the UCHIME2 and UCHIME3 chimera-detection algorithms were added as the
# --uchime2_denovo and --uchime3_denovo commands; already covered in
# uchime2_denovo.sh and uchime3_denovo.sh



#******************************************************************************#
#                                                                              #
#             compilation error with any GCC version since Feb. 7              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/288

# not testable (compilation error: invalid const conversion in abundance.cc)



#******************************************************************************#
#                                                                              #
#                          MAINT: Add const modifier                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/289

# not testable (source maintenance pull request adding a const modifier)



#******************************************************************************#
#                                                                              #
#                         Update cluster_unoise in man                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/290

# not testable (documentation pull request updating the cluster_unoise man
# page)



#******************************************************************************#
#                                                                              #
#               Windows only: Cannot read files larger than 4GB                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/291

# not testable (Windows-only: fseek failed on files larger than 4 GB)



#******************************************************************************#
#                                                                              #
#                       Windows only: Some kmers missed                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/292

# not testable (Windows-only: some kmers were missed when indexing)



#******************************************************************************#
#                                                                              #
#                         Loosing OTUs when clustering                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/293

## not a bug: dereplication considers the full sequence length while
## clustering only scores the overlap. Two sequences that differ only by a 3'
## extension are therefore NOT dereplicated (2 unique sequences) but ARE
## clustered together at --id 1.0 (1 cluster).
DESCRIPTION="issue 293: --derep_fulllength keeps prefix-extended sequences separate"
printf ">read1\nACGTAGTCATTTACTGTACTGTACGTTATACGATATGTCTATGCT\n>read2\nACGTAGTCATTTACTGTACTGTACGTTATACGATATGTCTATGCTAAA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --output - \
        --quiet | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 293: --cluster_fast clusters the same sequences together at --id 1.0"
printf ">read1\nACGTAGTCATTTACTGTACTGTACGTTATACGATATGTCTATGCT\n>read2\nACGTAGTCATTTACTGTACTGTACGTTATACGATATGTCTATGCTAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids - \
        --quiet | \
    grep -c "^>" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                           OTU missing in OTU table                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/294

# not testable (a usage question with no minimal reproducer)



#******************************************************************************#
#                                                                              #
#             -search_exact and -usearch_global different outputs              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/295

# not a bug: --search_exact finds only perfectly identical sequences and
# ignores --iddef, whereas --usearch_global uses a heuristic that may
# occasionally miss a perfect match; already covered in search_exact.sh



#******************************************************************************#
#                                                                              #
#                        relabel OTU table IDs question                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/296

# not testable (relabelling OTU-table IDs from an external taxonomy table is
# not a vsearch feature; it requires a custom lookup script)



#******************************************************************************#
#                                                                              #
#            Memory requirements for very large database (> 500GB)             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/297

# not testable (a question: vsearch needs at least ~5 bytes of memory per
# database nucleotide)



#******************************************************************************#
#                                                                              #
#                   usearch_global match potential match bug                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/298

# not a bug: --usearch_global uses a kmer-based heuristic and is not
# guaranteed to find the single best hit with --maxaccepts 1; raise
# --maxaccepts / --maxrejects to find better matches



#******************************************************************************#
#                                                                              #
#                               ECCN for VSEARCH                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/299

# not testable (an export-control classification question; vsearch performs
# no encryption)



#******************************************************************************#
#                                                                              #
#                           Cleaning up whitespaces                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/300

# not testable (source-formatting pull request)



#******************************************************************************#
#                                                                              #
#         vsearch 2.7.0 breaks identify_chimeric_seqs.py (qiime 1.9.1)         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/301

# not testable (could not be reproduced: uchime_denovo and uchime_ref give
# identical results in 2.6.0 and 2.7.0)



#******************************************************************************#
#                                                                              #
#          Minor issue: link to pdf manual on repo splash page broken          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/302

# not testable (a release tag was misnamed, breaking the manual link)



#******************************************************************************#
#                                                                              #
#                        Add the fastx_getseqs command                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/303

# the --fastx_getseqs command was added; already covered in fastx_getseqs.sh



#******************************************************************************#
#                                                                              #
#                    Compilation warnings with GCC 8.0                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/304

## no test


#******************************************************************************#
#                                                                              #
#                     should vsearch support fast5 files?                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/305

# not testable (request to read Oxford Nanopore FAST5/HDF5 files; not
# implemented)



#******************************************************************************#
#                                                                              #
#                Unable to install vsearch on MacOS High Sierra                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/306

# not testable (a user installation/PATH question)



#******************************************************************************#
#                                                                              #
#             Found 2 identical consensus sequences with --id 0.9              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/307

# not testable (not a bug: two input sequences differing by more than the
# threshold start two clusters whose consensus sequences may end up identical)



#******************************************************************************#
#                                                                              #
#                    Unable to sort centroids by abundance                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/308

# not a bug: --clusterout_sort orders the consout, msaout and profile files
# but not --centroids; sort the centroids afterwards with --sortbysize



#******************************************************************************#
#                                                                              #
#                   fastq_pctid option for fastq_mergepairs                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/309

# open issue (not covered): request for a --fastq_pctid option (the inverse
# of --fastq_maxdiffpct)



#******************************************************************************#
#                                                                              #
#                              General formatting                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/310

# not testable (source-formatting pull request)



#******************************************************************************#
#                                                                              #
#                      Missing progress during clustering                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/311

# not testable (not a bug: when reading from a pipe the input size is unknown
# so the progress indicator stays at 0% until finished)



#******************************************************************************#
#                                                                              #
#  Is vsearch suitable to extracting consensus sequence from 700bp ONT MinION  #
#                                    reads?                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/312

# not testable (the center-star multiple alignment is simple and handles
# indels relative to the centroid poorly; a question, not a bug)



#******************************************************************************#
#                                                                              #
#     Feature request: Option to output cluster id on centroid header line     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/313

## the --clusterout_id option also adds the cluster id to the header lines of
## the --centroids output (not only to consout/profile)
DESCRIPTION="issue 313: --clusterout_id adds the cluster id to --centroids headers"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --clusterout_id \
        --centroids - \
        --quiet | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">a;clusterid=0 >b;clusterid=1 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#      Feature request: Option to sort OTU tables by decreasing abundance      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/314

# open issue (not covered): request to sort OTU tables by decreasing
# abundance



#******************************************************************************#
#                                                                              #
#                  Improve wording of fastq_mergepairs report                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/315

# not testable (the merging-report category "potential tandem repeat" was
# reworded to "multiple potential alignments")



#******************************************************************************#
#                                                                              #
#     Feature request: option to exclude terminal gaps with maxdiffs when      #
#                                  searching                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/316

# open issue (not covered): request to exclude terminal gaps from the
# --maxdiffs count when searching



#******************************************************************************#
#                                                                              #
#                      Add an option to output to stdout?                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/317

# not a bug: output is written to stdout by using "-" (or "/dev/stdout", or a
# process substitution) as the filename; combine with --quiet to keep stderr
# clean



#******************************************************************************#
#                                                                              #
#              Potential vulnerabilities identified by Flawfinder              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/318

# not testable (static-analysis warnings, a subset of the clang-tidy
# warnings)



#******************************************************************************#
#                                                                              #
#                   Pass two arguments to --fastq_mergepairs                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/319

# not testable (a shell question: two stdin streams require named pipes or
# process substitutions)



#******************************************************************************#
#                                                                              #
#                   derep_fulllength (default minseqlength)                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/320

## not a bug: the default --minseqlength is 32 for some commands (including
## --derep_fulllength) and 1 for others, for compatibility with usearch 7
DESCRIPTION="issue 320: --derep_fulllength discards sequences shorter than 32 nt by default"
printf ">s\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output /dev/null 2>&1 | \
    grep -q "minseqlength 32: 1 sequence discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                          Warning during compilation                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/321

# not testable (compilation warning, similar to issue 304; fixed in 2.8.1)



#******************************************************************************#
#                                                                              #
#                       Remove chimeras from count_table                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/322

# not testable (a mothur usage question, solved by the user)



#******************************************************************************#
#                                                                              #
#   wrong placement of semicolons in the output of the dereplication command   #
#                              (issue 323)                                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/323

# With abundance annotations in the input, without --sizein:
DESCRIPTION="issue 323: placement of semicolons in dereplicated headers # 1"
printf ">s1;size=2;\nA\n>s2;size=1;\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# With abundance annotations in the input, with --sizein:
DESCRIPTION="issue 323: placement of semicolons in dereplicated headers # 2"
printf ">s1;size=2;\nA\n>s2;size=1;\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --sizein \
        --sizeout \
        --output - | \
    grep -qx ">s1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Without abundance annotation in the input, without --sizeout:
DESCRIPTION="issue 323: placement of semicolons in dereplicated headers # 3"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --output - | \
    grep -Eqx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Without abundance annotation in the input, with --sizeout:
DESCRIPTION="issue 323: placement of semicolons in dereplicated headers # 4"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --sizeout \
        --output - | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# With abundance annotations in the input, with --sizein but no --sizeout:
DESCRIPTION="issue 323: placement of semicolons in dereplicated headers # 5"
printf ">s1;size=2;\nA\n>s2;size=1;\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --sizein \
        --output - | \
    grep -qx ">s1;size=2;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#     derep_fulllength cluster size does not sum up to the original input      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/324

## not a bug: without --sizein and --sizeout the abundances are ignored and the
## header of the first sequence in each cluster is copied unchanged (sizes are
## not summed). Here the size=5 header is kept as-is, ignoring the size=3 one.
DESCRIPTION="issue 324: --derep_fulllength ignores abundances without --sizein/--sizeout"
printf ">s1;size=5\nA\n>s2;size=3\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --output - \
        --quiet | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#              sintax classifier and multiple identical best hits              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/325

# not testable (the sintax algorithm reports only the first of several
# identical best hits; improving it to report the LCA was deferred)



#******************************************************************************#
#                                                                              #
#                  --fastq_mergepairs produces q-scores of 40                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/326

## not a bug: in the overlap region the merged quality scores increase (more
## certainty from two reads), as described by Edgar & Flyvbjerg (2015). Here
## two Q40 ('I') reads merge to Q41 ('J') in the overlap (clipped at the
## default --fastq_qmax of 41).
DESCRIPTION="issue 326: --fastq_mergepairs increases quality scores in the overlap"
FWD=$(mktemp)
REV=$(mktemp)
printf "@r\nGCTAAAGACAATTACATAACATACACGTCAGCACGAAACT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${FWD}"
printf "@r\nCGATTCACACTGGGCCAACAAGTTTCGTGCTGACGTGTAT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${REV}"
"${VSEARCH}" \
    --fastq_mergepairs "${FWD}" \
    --reverse "${REV}" \
    --fastqout - \
    --quiet 2>/dev/null | \
    sed -n "4p" | \
    grep -q "J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FWD}" "${REV}"



#******************************************************************************#
#                                                                              #
#                               Updating CFLAGS                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/327

# not testable (build-configuration pull request)



#******************************************************************************#
#                                                                              #
#        Hits missed when clustering or searching with short sequences         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/328

## vsearch will never report more than one match in each database
## sequence, unless they are on different strands

DESCRIPTION="issue 328: vsearch reports one hit if there is one perfect match"
printf ">s1\nTCAAGATATTTGCTCGGTAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">q1\nTCAAGATATTTGCTCGGTAA\n") \
        --minseqlength 1 \
        --id 0.9 \
        --quiet \
        --userfields target \
        --userout - | \
    awk '{if ($1 == "q1") {hits++} } END {exit hits == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Note: vsearch matches the second occurrence
DESCRIPTION="issue 328: vsearch reports one hit if there are two consecutive perfect matches"
printf ">s1\nTCAAGATATTTGCTCGGTAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">q1\nTCAAGATATTTGCTCGGTAATCAAGATATTTGCTCGGTAA\n") \
        --minseqlength 1 \
        --id 0.9 \
        --quiet \
        --userfields target \
        --userout - | \
    awk '{if ($1 == "q1") {hits++} } END {exit hits == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Second part is a reverse-complement of the first part:
# TCAAGATATTTGCTCGGTAA
# ||||||||||||||||||||
# TCAAGATATTTGCTCGGTAATTACCGAGCAAATATCTTGA
#                     ||||||||||||||||||||
#                     TTACCGAGCAAATATCTTGA
DESCRIPTION="issue 328: vsearch reports two hits if there are on different strands (perfect matches)"
printf ">s1\nTCAAGATATTTGCTCGGTAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">q1\nTCAAGATATTTGCTCGGTAATTACCGAGCAAATATCTTGA\n") \
        --minseqlength 1 \
        --strand both \
        --id 0.9 \
        --quiet \
        --userfields target \
        --userout - | \
    awk '{if ($1 == "q1") {hits++} } END {exit hits == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                 Reduce memory requirements for dereplication                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/329

# not testable (memory-footprint optimization for --derep_fulllength)



#******************************************************************************#
#                                                                              #
#                   Collecting CFLAGS to a central location                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/330

# not testable (build-configuration pull request)



#******************************************************************************#
#                                                                              #
#          --cluster_fast is stuck at clustering step for over 5 days          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/331

# not testable (a very large, non-dereplicated dataset that is too big for the
# clustering algorithm to handle in reasonable time)



#******************************************************************************#
#                                                                              #
#                                 Octave plots                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/332

# open issue (not covered): request for an otutab_octave plotting command



#******************************************************************************#
#                                                                              #
#          Segmentation Fault in --derep_fulllength when --uc is used          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/333

## a segmentation fault occurred with --derep_fulllength when --uc was combined
## with --relabel and --sizeout; fixed in 2.8.3
DESCRIPTION="issue 333: --derep_fulllength with --uc, --relabel and --sizeout does not crash"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --strand plus \
        --sizeout \
        --relabel sample. \
        --uc /dev/null \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#             Further reduce memory requirements for dereplication             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/334

# not testable (further memory-footprint optimization for dereplication)



#******************************************************************************#
#                                                                              #
#            sample IDs containing a - are collapsed for OTU table             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/335

## a sample identifier derived from the header prefix may only contain letters,
## digits and underscores, so it is truncated at the first dash. An explicit
## ";sample=" annotation may contain any printable character except a semicolon
## (dashes are kept).
DESCRIPTION="issue 335: a prefix-derived sample id is truncated at the first dash"
printf ">1-1234.1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">otu1\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.97 \
        --minseqlength 1 \
        --otutabout - \
        --quiet | \
    head -1 | \
    grep -qx "#OTU ID	1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 335: an explicit ;sample= identifier keeps the dash"
printf ">q;sample=1-1234\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">otu1\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.97 \
        --minseqlength 1 \
        --otutabout - \
        --quiet | \
    head -1 | \
    grep -qx "#OTU ID	1-1234" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#  Problem with eestats2 for longer reads (short reads incorrectly accounted)  #
#                             (issue 336)                                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/336

# vsearch is wrongly extending shorter sequences up to the length of
# the longest previously seen sequence, assuming perfect quality for
# the extensions. If all sequences are equally long, the results are
# the same.

## old (before v2.8.5)
# Length         MaxEE 0.50         MaxEE 1.00         MaxEE 2.00
# ------   ----------------   ----------------   ----------------
#      1          2(100.0%)          2(100.0%)          2(100.0%)
#      2          2(100.0%)          2(100.0%)          2(100.0%)


## expected (after v2.8.5)
# Length         MaxEE 0.50         MaxEE 1.00         MaxEE 2.00
# ------   ----------------   ----------------   ----------------
#      1          2(100.0%)          2(100.0%)          2(100.0%)
#      2          1( 50.0%)          1( 50.0%)          1( 50.0%)

DESCRIPTION="issue 336: eestats2: wrong MaxEE when mixing short & long reads (older and wrong output)"
printf "@1\nAA\n+\nAA\n@2\nA\n+\nA\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 /dev/stdin \
        --length_cutoffs 1,2,1 \
        --quiet \
        --output - | \
    grep -Eq " +2( +2\(100.0%\)){3}" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 336: eestats2: wrong MaxEE when mixing short & long reads (expected output)"
printf "@1\nAA\n+\nAA\n@2\nA\n+\nA\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 /dev/stdin \
        --length_cutoffs 1,2,1 \
        --quiet \
        --output - | \
    grep -Eq " +2( +1\( 50.0%\)){3}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 336: eestats2: correct MaxEE for same-length reads"
printf "@1\nAA\n+\nAA\n@2\nAA\n+\nAA\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 /dev/stdin \
        --length_cutoffs 1,2,1 \
        --quiet \
        --output - | \
    grep -Eq " +2( +2\(100.0%\)){3}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                          Add the fastq_join Command                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/337

# the --fastq_join command was added in version 2.9.0; already covered in
# fastq_join.sh



#******************************************************************************#
#                                                                              #
#    derep_fulllength fails to remove the part of the header after the space   #
#                                 (issue 338)                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/338

# The part of the header line from the first space should be ignored
# (unless the --notrunclabels option is in effect)

DESCRIPTION="issue 338: derep_fulllength: header stops at first space"
printf ">header meta data\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --sizeout \
        --quiet \
        --output - | \
    grep -q ">header;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 338: derep_fulllength: notrunclabels includes full header"
printf ">header meta data\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --notrunclabels \
        --sizeout \
        --quiet \
        --output - | \
    grep -q ">header meta data;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#    rereplicate should print a warning if abundance information is missing    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/339

## --rereplicate always assumes abundance information (--sizein is implied);
## when it is missing for some sequences a warning is printed (fixed in 2.12.0)
DESCRIPTION="issue 339: --rereplicate warns when abundance information is missing"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output /dev/null 2>&1 | \
    grep -qi "Missing abundance information" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                 individual manpages for each vsearch command                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/340

# not testable (documentation: per-command manpages, e.g. man
# vsearch-rereplicate, were later added)



#******************************************************************************#
#                                                                              #
#             Illegal instruction error for dereplication command              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/341

# not testable (the pre-compiled binary used -march=native; recompiling on the
# target machine fixes it)



#******************************************************************************#
#                                                                              #
#           detect CPU features at run time, not during compilation            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/342

# not testable (internal: on x86_64 the SSSE3 and SSE2 code paths are both
# compiled and selected at run time)



#******************************************************************************#
#                                                                              #
#                 sha1 hash differs from the one obtained in R                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/343

## not a bug: vsearch computes the standard SHA-1 of the upper-cased sequence
## string (as sha1sum does). The R digest() function gave a different value
## because it hashed a serialized object; use serialize=FALSE in R to match.
DESCRIPTION="issue 343: --relabel_sha1 matches the standard sha1 of the sequence"
SEQ="CAACCCTCAAGCTCTCTTGCTTGGTGTTGGGGCTTCTGCGGCTTCGGCCGCAGGCCCTGAAAAACAGTGGCGGGCTCGCTATAACTCCGAGCGTAGTAATCTCTCTCGCTTTGGAAGTGTAGCGGTTCCCGGCCGTTAAACCCCCCAATTTCTGAAA"
SHA1=$(printf "%s" "${SEQ}" | sha1sum | cut -d " " -f 1)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --relabel_sha1 \
        --output - \
        --quiet | \
    grep -qx ">${SHA1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ SHA1



#******************************************************************************#
#                                                                              #
#                            dereplication question                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/344

# not testable (a question: dereplication ignores taxonomic information and
# keeps the first header among identical sequences)



#******************************************************************************#
#                                                                              #
#                               gist for map.pl                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/345

# not testable (a user shared a gist of a helper script)



#******************************************************************************#
#                                                                              #
#                      Support for the legacy sff format?                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/346

# reading the legacy SFF format was later added as the --sff_convert command;
# already covered in sff_convert.sh



#******************************************************************************#
#                                                                              #
#      which commands could benefit from a 2-bit encoding of nucleotides?      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/347

# not testable (personal notes on a potential 2-bit nucleotide encoding)



#******************************************************************************#
#                                                                              #
#                    implement the command --fastx_uniques?                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/348

# the --fastx_uniques command (dereplication of fasta and fastq files) was
# added; already covered in fastx_uniques.sh



#******************************************************************************#
#                                                                              #
#                Fix sintax.cc: domain should be before kingdom                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/349

# not testable (pull request fixing the taxonomic-rank order in sintax.cc)



#******************************************************************************#
#                                                                              #
#             Compilation warnings with gcc for vsearch 2.10                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/350

## no test


#******************************************************************************#
#                                                                              #
#                       Add link to the BioConda package                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/351

# not testable (pull request adding a BioConda link to the README)



#******************************************************************************#
#                                                                              #
#               Minimal valid SFF files and where to find them?                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/352

# not testable (a request for a minimal SFF file to use for fuzzing the
# --sff_convert command)



#******************************************************************************#
#                                                                              #
#                       Pumping MACOSX_DEPLOYMENT_TARGET                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/353

# not testable (macOS build-configuration pull request)



#******************************************************************************#
#                                                                              #
#            Handling of sequences with ambiguous nucleotide symbols           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/354

# usearch has changed the way it takes into account ambiguous
# nucleotide symbols in pairwise alignments (two wildcard letters
# match each other if they represent at least one identical residue,
# so for example NN matches anything)

# v2.13: Ambiguous nucleotide symbols (MRSVWYHKDBN) will now count as
# matching to other symbols if they have in common at least one of the
# nucleotides (ACGTU) they represent. For example: W will match A and
# T, but also any of MRVHDN. This will be indicated with a + symbol in
# alignments. Identical matches between any of ACGTU will be indicated
# with a | symbol. This is similar to usearch version 8 and later. The
# alignment score for aligning to any ambiguous symbol is still 0.

# IUPAC matches are extensively tested in the script 'cut.sh'

DESCRIPTION="issue 354: ambiguous matches are noted with a symbol + in alignments (W -> A)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\nA\n") \
    --db <(printf ">t\nW\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --alnout - | \
    grep -Eqx "[[:space:]]+[+]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 354: ambiguous matches are noted with a symbol + in alignments (N -> A)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\nA\n") \
    --db <(printf ">t\nN\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --alnout - | \
    grep -Eqx "[[:space:]]+[+]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 354: regular matches are noted with a symbol | in alignments"
"${VSEARCH}" \
    --usearch_global <(printf ">q\nA\n") \
    --db <(printf ">t\nA\n") \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --alnout - | \
    grep -Eqx "[[:space:]]+[|]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#   fastq_stats: corner case when computing truncation percentage (issue 355)  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/355

## Bug in the log produced by fastq_stats with an input sequence of
## length one. Output was:

# Truncate at first Q
#   Len     Q=5    Q=10    Q=15    Q=20
# -----  ------  ------  ------  ------
#     1  100.0%  100.0%  100.0%  100.0%
#     0    0.0%    0.0%    0.0%  1640100.0%

# instead of:

# Truncate at first Q
#   Len     Q=5    Q=10    Q=15    Q=20
# -----  ------  ------  ------  ------
#     1  100.0%  100.0%  100.0%  100.0%

DESCRIPTION="issue 355: fastq_stats: wrong truncation percentage when max length is 1"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -Eq "^[[:blank:]]+0[[:blank:]]+" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#            VSEARCH 2.10.3 produces wrong alignments - Do not use             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/356

# not testable (version 2.10.3 produced wrong alignments and was withdrawn;
# no minimal reproducer was provided)



#******************************************************************************#
#                                                                              #
#                does derep_fulllength support multithreading?                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/357

# not a bug: the dereplication commands (--derep_fulllength and
# --derep_prefix) are single-threaded by design



#******************************************************************************#
#                                                                              #
#      compilation error when preping for afl-fuzz with address sanitizer      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/358

# not testable (build with afl-fuzz and the address sanitizer)



#******************************************************************************#
#                                                                              #
#              Make fastq_filter operate on pairs of fastq files               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/359

## --fastx_filter (and --fastq_filter) can filter paired FASTQ files: the
## reverse file is given with --reverse and written with --fastqout_rev. A
## pair is discarded if either read fails the filter. Here the p1 pair is
## removed because its reverse read has too many expected errors.
DESCRIPTION="issue 359: --fastx_filter discards a pair when its reverse read is rejected"
FWD=$(mktemp)
REV=$(mktemp)
printf "@p1\nACGTACGT\n+\nIIIIIIII\n@p2\nACGTACGT\n+\nIIIIIIII\n" > "${FWD}"
printf "@p1\nACGTACGT\n+\n########\n@p2\nACGTACGT\n+\nIIIIIIII\n" > "${REV}"
"${VSEARCH}" \
    --fastx_filter "${FWD}" \
    --reverse "${REV}" \
    --fastq_maxee 0.5 \
    --fastqout - \
    --fastqout_rev /dev/null \
    --quiet | \
    grep "^@p" | \
    tr "\n" " " | \
    grep -qx "@p2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FWD}" "${REV}"



#******************************************************************************#
#                                                                              #
#                Is there a way of outputting % id to centroid?                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/360

# not a bug: the percentage identity of each member to its centroid is
# available in the fourth column of the H lines of the --uc output



#******************************************************************************#
#                                                                              #
#                               Adapt to FreeBSD                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/361

# not testable (FreeBSD build adaptation)



#******************************************************************************#
#                                                                              #
#       Force weak_id to be a reasonable value when cluster_unoise (0.9)       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/362

# not testable (pull request constraining an internal default for
# --cluster_unoise)



#******************************************************************************#
#                                                                              #
#     Could cluster_fast build consensus based on abundances? (issue 363)      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/363

# vsearch uses the most frequent sequence as the consensus sequence,
# but fails to take sequence abundances into account. In this
# toy-example, the centroid sequence should be AA (abundance of 9),
# even if AT occurs twice (total abundance of 2), only when using the
# --sizein option.

DESCRIPTION="issue 363: cluster_size --consout: consensus sequence is cluster's most abundant sequence"
printf ">s1;size=1\nAT\n>s2;size=9\nAA\n>s3;size=1\nAT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --sizein \
        --id 0.5 \
        --quiet \
        --consout - | \
    tr "\n" "@" | \
    grep -qx ">centroid=s2;size=9;seqs=3@AA@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                       fatal error when running unoise                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/364

# not testable (user error: the failing command was run with usearch, not
# vsearch, and the input was a FASTQ file used where FASTA was expected)


#******************************************************************************#
#                                                                              #
#                  how to compile vsearch for ARM processors?                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/365

# not testable (compiling on the ARM architecture; -march=armv8-a is selected
# instead of -msse2)



#******************************************************************************#
#                                                                              #
#               Handling of empty input files (issue 366)                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/366

## vsearch terminates with a fatal error when running the
## fastq_mergepairs command on an empty input file. It may be more
## appropriate to generate empty output in such cases, instead of
## terminating with an error.

DESCRIPTION="issue 366: --fastq_mergepairs handles empty input"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "") \
    --reverse <(printf "") \
    --fastqout - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="issue 366: --fastq_mergepairs handles empty input (minimal input)"
"${VSEARCH}" \
    --fastq_minovlen 5 \
    --fastq_mergepairs <(printf "@s\nAAAAA\n+\nIIIII\n") \
    --reverse <(printf "@s\nTTTTT\n+\nIIIII\n") \
    --quiet \
    --fastqout - 2> /dev/null | \
    grep -q "^@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="issue 366: --fastq_mergepairs handles empty input (empty input, empty output)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "") \
    --reverse <(printf "") \
    --quiet \
    --fastqout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                Report total reads, not just unique sequences                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/367

## several commands reported only the number of unique (dereplicated)
## sequences; --usearch_global now also reports the total number of query
## sequences when --sizein is used (fixed in 2.13.0)
DESCRIPTION="issue 367: --usearch_global reports the total number of query sequences with --sizein"
printf ">q;size=5\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.9 \
        --minseqlength 1 \
        --sizein \
        --matched /dev/null 2>&1 | \
    grep -q "Matching total query sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#         better error message when fastq quality value above qmax 41          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/368

## a quality value above the default --fastq_qmax (41) now produces an
## informative error suggesting the --fastq_qmax option (fixed in 2.13.0).
## Here 'K' encodes a quality of 42.
DESCRIPTION="issue 368: an informative error is given when a quality value exceeds qmax"
printf "@s\nA\n+\nK\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastqout /dev/null 2>&1 | \
    grep -q "above qmax" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                   vsearch --uchime_ref gzip not supported                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/369

## --uchime_ref must read a gzip-compressed input file (the compression is
## detected automatically from the file content); it failed before with
## "Files compressed with gzip are not supported."
DESCRIPTION="issue 369: --uchime_ref reads a gzip-compressed input file"
GZ=$(mktemp)
printf ">a;size=9\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n" | gzip > "${GZ}"
"${VSEARCH}" \
    --uchime_ref "${GZ}" \
    --db <(printf ">t\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n") \
    --nonchimeras /dev/null \
    --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${GZ}"



#******************************************************************************#
#                                                                              #
#                FASTA headers not properly handled on Windows                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/370

# the carriage return of Windows CR LF line endings was not stripped when
# rewriting FASTA/FASTQ headers, producing illegal headers; fixed in 2.13.3.
# This is tested under issue 371.



#******************************************************************************#
#                                                                              #
#          Different outputs for Windows and Mac / Linux (issue 371)           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/371

## Incorrect parsing of FASTA and FASTQ headers on Windows due to the
## differences in newline characters on Windows vs Mac/Linux (CR LF vs
## LF), solved in version 2.13.3.

# Test a normal situation first
DESCRIPTION="issue 371: correct parsing of headers with LF characters"
printf "@s;size=1;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --xsize \
        --quiet \
        --fastqout - | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# The issue can be replicated on any system (there should be no trailling ";")
DESCRIPTION="issue 371: correct parsing of headers with CR LF characters (issue 371)"
printf "@s;size=1;\r\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --xsize \
        --quiet \
        --fastqout - | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                            FreeBSD port committed                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/372

# not testable (announcement that a FreeBSD ports package is available)



#******************************************************************************#
#                                                                              #
#                               Big endian PPC?                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/373

# not testable (making the code endian-agnostic for big-endian PowerPC)



#******************************************************************************#
#                                                                              #
#                       Unable to open file for reading                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/374

# not testable (a user file-path problem, not a vsearch bug)



#******************************************************************************#
#                                                                              #
#               Suspected incorrect cluster results (issue 375)                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/375

# There are different definitions of what are identical sequences (see
# --iddef). In the example below, s1 and s2 are identical if terminal
# gaps are not taken into account (vsearch's default behavior):

# s1 GGGGTCAAACAGGATTAGATACCCTGGTAG
#        ||||||||||||||||||||||||||
# s2     TCAAACAGGATTAGATACCCTGGTAGAAAA

# Test a normal situation first
DESCRIPTION="issue 375: sequences are identical (neglect terminal gaps)"
SAME="TCAAACAGGATTAGATACCCTGGTAG"
printf ">s1;size=1\nGGGG%s\n>s2;size=1\n%sAAAA" ${SAME} ${SAME} | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.00 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 375: sequences are different (account for terminal gaps)"
SAME="TCAAACAGGATTAGATACCCTGGTAG"
printf ">s1;size=1\nGGGG%s\n>s2;size=1\n%sAAAA" ${SAME} ${SAME} | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.00 \
        --iddef 1 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                  unrecognized function '--cluster_smallmen'                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/376

# not testable (user typo: the command is --cluster_smallmem, with a final m)



#******************************************************************************#
#                                                                              #
#             How to trim paired fastq files that got out-of-sync?             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/377

# not testable (re-synchronising out-of-order paired FASTQ files is not
# implemented; external tools such as repair.sh can be used)



#******************************************************************************#
#                                                                              #
#                    FIX: silence fastq_stats() if --quiet                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/378

# pull request making --fastq_stats respect --quiet; the related behaviour is
# tested under issue 237



#******************************************************************************#
#                                                                              #
#                Reverse complement sequences during clustering                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/379

## clustering on both strands is enabled with --strand both, so a sequence and
## its reverse complement are placed in the same cluster. With the default
## --strand plus they form two clusters.
DESCRIPTION="issue 379: --cluster_size --strand plus keeps a sequence and its revcomp separate"
SEQ="ACGTAGCTAGCTGATCGATCGTAGCTAGCTGA"
RC="TCAGCTAGCTACGATCGATCAGCTAGCTACGT"
printf ">a\n%s\n>b\n%s\n" "${SEQ}" "${RC}" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --strand plus \
        --centroids - \
        --quiet | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ RC

DESCRIPTION="issue 379: --cluster_size --strand both clusters a sequence with its reverse complement"
SEQ="ACGTAGCTAGCTGATCGATCGTAGCTAGCTGA"
RC="TCAGCTAGCTACGATCGATCAGCTAGCTACGT"
printf ">a\n%s\n>b\n%s\n" "${SEQ}" "${RC}" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --minseqlength 1 \
        --strand both \
        --centroids - \
        --quiet | \
    grep -c "^>" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ RC



#******************************************************************************#
#                                                                              #
#                  Having difficulty using evalue in vsearch                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/380

# not a bug: e-values are not computed for nucleotide (global) alignments and
# are always set to -1; use --id and --query_cov instead (see issues 176, 179)



#******************************************************************************#
#                                                                              #
#            Dereplicate entries with identical sequence and label             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/381

# the --derep_id command was added: it dereplicates only when both the label
# and the sequence are identical; already covered in derep_id.sh



#******************************************************************************#
#                                                                              #
#               Garbage consensus sequence in all 2.13 versions                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/382

# not testable (a consensus-sequence bug in the 2.13 series, fixed shortly
# after; no minimal reproducer was provided)



#******************************************************************************#
#                                                                              #
#                           Make OTU table directly?                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/383

# not a bug: OTU tables are produced directly from the clustering and search
# commands with --otutabout, --biomout or --mothur_shared_out (see issue 166)



#******************************************************************************#
#                                                                              #
#   Add option relabel_self to use sequence itself as a label in FASTA/FASTQ   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/384

## the --relabel_self option uses the sequence itself as the new label
DESCRIPTION="issue 384: --relabel_self uses the sequence as the label"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --relabel_self \
        --output - \
        --quiet | \
    grep -qx ">ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#         command sortbysize does not accept the sizein option anymore         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/385

## a regression made --sortbysize reject the --sizein option; fixed
DESCRIPTION="issue 385: --sortbysize accepts the --sizein option"
printf ">s;size=1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --sizein \
        --sizeout \
        --minseqlength 1 \
        --output - \
        --quiet | \
    grep -qx ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                        chimera removal without map.pl                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/386

# not a bug: non-chimeric sequences are written directly with the
# --nonchimeras option of --uchime_denovo / --uchime_ref; map.pl is only used
# in the example pipeline to filter the original (non-dereplicated) reads



#******************************************************************************#
#                                                                              #
#     --fastaout_rev writes Read1 sequence instead of Read2 (issue 387)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/387

# This is limited to the fasta output, fastq output is ok.

DESCRIPTION="issue 387: fastx_filter fastaout_rev returns R2 sequences, not R1"
"${VSEARCH}" \
    --fastx_filter <(printf '@s_1\nA\n+\nI\n') \
    --reverse <(printf '@s_2\nT\n+\nI\n') \
    --fastq_minlen 1 \
    --fastaout /dev/null \
    --fastaout_rev - 2> /dev/null | \
    tr -d "\n" | \
    grep -qx ">s_2T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Varying number of columns in blast6out output file from search (issue 388)  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/388

# Two topics:
#   - with --strand both and --maxaccepts 1, there could be two hits per query,
#   - sometime blast6out does not return the expected 12 columns (bug!)

# topic 1 is already covered by issue #546

# topic 2: check that blast6out returns a tab-separated output with 12 columns:
DESCRIPTION="issue 388: blast6out returns 12 tab-separated columns"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nA\n") \
    --db <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    awk 'BEGIN {FS = "\t"} {exit NF == 12 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                  advice on --maxrejects when --maxaccept=1                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/389

# not testable (the question was reposted on the VSEARCH Forum)



#******************************************************************************#
#                                                                              #
#         merging stats for very small number of reads (low priority)          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/390

## the "Statistics of merged reads" block is now printed only when at least
## one pair is merged. Here no pair merges, so the block must be absent.
DESCRIPTION="issue 390: no merge-statistics block is printed when no pair is merged"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastqout /dev/null 2>&1 | \
    grep -q "Statistics of merged reads" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#             fastx_revcomp: relabel strips abundance annotations              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/391

## --fastx_revcomp used to drop the abundance annotation when relabelling;
## it now keeps it when both a relabel option and --sizeout are used
DESCRIPTION="issue 391: --fastx_revcomp keeps the abundance with --relabel_sha1 and --sizeout"
printf ">s;size=3;\nA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --relabel_sha1 \
        --sizeout \
        --quiet | \
    grep -q ";size=3$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                               vsearch --search                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/392

# not a bug: there is no --search command; vsearch interprets it as
# --search_exact (abbreviation). To build an OTU table, use --usearch_global
# with --otutabout



#******************************************************************************#
#                                                                              #
#     usearch_global search aligning to Ns with 100% identity (issue 393)      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/393

## When this option is enabled, aligning a residue with an N is always
## considered a mismatch.

# impact on: allpairs_global, cluster_fast, cluster_size,
# cluster_smallmem, cluster_unoise, usearch_global

# as of <2025-02-28 ven.>, the concerned source files are:
# align_simd.cc
# linmemalign.cc
# showalign.cc

# pv: Number of positive columns. When working with nucleotide
# sequences, this is equivalent to the number of matches (zero or
# positive integer value).
DESCRIPTION="issue 393: --usearch_global aligns Ns as matches (default)"
printf ">q\nAAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s\nNNN\n") \
        --minseqlength 3 \
        --output_no_hits \
        --id 1.0 \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 393: --usearch_global --n_mismatch aligns Ns as mismatches"
printf ">q\nAAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s\nNNN\n") \
        --minseqlength 3 \
        --output_no_hits \
        --id 1.0 \
        --n_mismatch \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 393: --allpairs_global aligns Ns as matches (default)"
printf ">q\nAAA\n>s\nNNN\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --minseqlength 3 \
        --output_no_hits \
        --quiet \
        --userfields query+pv \
        --userout - | \
    awk '$1 == "q" {exit $2 == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 393: --allpairs_global --n_mismatch aligns Ns as mismatches"
printf ">q\nAAA\n>s\nNNN\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --minseqlength 3 \
        --output_no_hits \
        --n_mismatch \
        --quiet \
        --userfields query+pv \
        --userout - | \
    awk '$1 == "q" {exit $2 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 393: --cluster_fast aligns Ns as matches (default)"
printf ">q\nAAA\n>s\nNNN\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 3 \
        --id 1.0 \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 393: --cluster_fast --n_mismatch aligns Ns as mismatches"
printf ">q\nAAA\n>s\nNNN\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 3 \
        --id 1.0 \
        --n_mismatch \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 393: --cluster_size aligns Ns as matches (default)"
printf ">q\nAAA\n>s\nNNN\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 3 \
        --id 1.0 \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 393: --cluster_size --n_mismatch aligns Ns as mismatches"
printf ">q\nAAA\n>s\nNNN\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 3 \
        --id 1.0 \
        --n_mismatch \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 393: --cluster_smallmem aligns Ns as matches (default)"
printf ">q\nAAA\n>s\nNNN\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --minseqlength 3 \
        --id 1.0 \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 393: --cluster_smallmem --n_mismatch aligns Ns as mismatches"
printf ">q\nAAA\n>s\nNNN\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --minseqlength 3 \
        --id 1.0 \
        --n_mismatch \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 393: --cluster_unoise aligns Ns as matches (default)"
printf ">q;size=32;\nAAA\n>s;size=8;\nNNN\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --minseqlength 3 \
        --id 1.0 \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 393: --cluster_unoise --n_mismatch aligns Ns as mismatches"
printf ">q;size=32;\nAAA\n>s;size=8;\nNNN\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --minseqlength 3 \
        --id 1.0 \
        --n_mismatch \
        --quiet \
        --userfields pv \
        --userout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#          OTU table truncated at OTU_999999 out of ca 5,800,000 OTUs          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/394

# not testable (OTU-table issue reported with ~5.8 million OTUs; cannot be
# reproduced with a small input)



#******************************************************************************#
#                                                                              #
#            Missing minseqlength option to makeudb_usearch command            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/395

## the --minseqlength option was not accepted by --makeudb_usearch, making it
## impossible to include sequences shorter than 32 bp in a UDB file; fixed
DESCRIPTION="issue 395: --makeudb_usearch accepts --minseqlength"
OUT=$(mktemp)
printf ">s\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --minseqlength 1 \
        --output "${OUT}" \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OUT}"



#******************************************************************************#
#                                                                              #
#                           vsearch error (issue 396)                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/396

# This is a copy-paste issue (dashes replaced with utf-8 chars, shell
# breaks). A copy-paste from vsearch_man.pdf does not produce the same
# issue. Nothing to change then.


#******************************************************************************#
#                                                                              #
#                      Fasta Header problem (issue 397)                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/397

# empty issue


#******************************************************************************#
#                                                                              #
#               Bad alignments across gaps in the seed sequence                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/399

# not a bug: --msaout uses a center-star multiple alignment (each sequence is
# aligned to the cluster seed), whose accuracy decreases for low identity
# thresholds or gappy seeds; the pairwise alignments in --alnout are correct
# (see issues 213 and 312)



#******************************************************************************#
#                                                                              #
#                  closed_ref workflow as usearch -closed_ref                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/443

# not testable (a closed-reference workflow question; use --usearch_global
# with --otutabout / --blast6out)



#******************************************************************************#
#                                                                              #
#                              Chimera detection                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/444

# not testable (a question about running chimera detection on representative
# sequences from another clustering tool)



#******************************************************************************#
#                                                                              #
#                     -sample_delim in building OTU Table                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/445

# not a bug: vsearch has no --sample_delim option; the sample name is taken
# from the leading letters, digits and underscores of the header, or from an
# explicit ;sample= term (see issue 335)



#******************************************************************************#
#                                                                              #
#                            static compile vsearch                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/446

# not testable (statically linked Linux binaries are provided in the releases
# since version 2.17.1)



#******************************************************************************#
#                                                                              #
#                              qsegout / tsegout                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/447

## the --qsegout and --tsegout options write the aligned part of the query and
## target sequences (the non-aligned flanks are removed). They do not count as
## output options, so another output (here --userout) must be given. The query
## below has 5 nt and 4 nt flanks around the 32 nt aligned region.
DESCRIPTION="issue 447: --qsegout writes only the aligned part of the query"
printf ">q\nAAAAACGTAGCTAGCTGATCGATCGTAGCTAGCTGATTTT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTAGCTAGCTGATCGATCGTAGCTAGCTGA\n") \
        --id 0.5 \
        --minseqlength 1 \
        --qsegout - \
        --userout /dev/null \
        --quiet | \
    grep -A 1 "^>q" | \
    grep -qx "ACGTAGCTAGCTGATCGATCGTAGCTAGCTGA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                          vsearch compilation issue                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/448

# not testable (build failure caused by a missing automake installation)



#******************************************************************************#
#                                                                              #
#                             set pointer to null                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/449

# not testable (source-maintenance pull request)



#******************************************************************************#
#                                                                              #
#             Output merged fasta sequences from allpairs_global?              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/433

# not a bug: merging overlapping sequences is the job of --fastq_mergepairs;
# FASTA sequences can be converted to fake-quality FASTQ first



#******************************************************************************#
#                                                                              #
#                         Orient seqs by mapping to db                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/434

# the --orient command (orient sequences against a reference database) was
# added; already covered in orient.sh



#******************************************************************************#
#                                                                              #
#                       Speeding up writing of clusters                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/435

# not testable (feature request: multithread the writing of cluster files)



#******************************************************************************#
#                                                                              #
#                 Unmerged reads with short identical overlap                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/436

# not a bug: like issue 430, a short overlap with a possible alternative
# alignment is not merged by the heuristic



#******************************************************************************#
#                                                                              #
#                         permission issue on BigSur?                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/437

# not testable (a macOS environment/permission problem, not a vsearch bug)



#******************************************************************************#
#                                                                              #
#                     Formatting SILVA to use with VSEARCH                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/438

# not testable (a question about reformatting SILVA taxonomy headers with sed)



#******************************************************************************#
#                                                                              #
#          Rare hang when merging fastq files using multiple threads           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/439

# not testable (a rare multi-threading race condition during --fastq_mergepairs)



#******************************************************************************#
#                                                                              #
#        Update documentation to describe behaviour of allpairs_global         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/440

## not a bug (documentation): --allpairs_global compares each sequence only to
## the sequences that come *after* it in the input, not all-against-all. With
## three sequences this yields the pairs a-b, a-c and b-c.
## --threads 1 keeps the pair output order deterministic (with several
## threads the pairs may be emitted in a different order).
DESCRIPTION="issue 440: --allpairs_global compares each sequence to the following ones"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nACGTACGTACGTACGTACGTACGTACGTACGT\n>c\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --threads 1 \
        --id 0.5 \
        --minseqlength 1 \
        --userfields query+target \
        --userout - \
        --quiet | \
    tr "\t" "_" | \
    tr "\n" " " | \
    grep -qx "a_b a_c b_c " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                    Implementation of usearch_global LCA?                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/441

# an LCA option for --usearch_global was added as --lcaout; tested under
# issue 622



#******************************************************************************#
#                                                                              #
#             Warn (and stop) if amino acid sequences are detected             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/414

# vsearch is nucleotide-only: non-ACGTU IUPAC and protein characters are
# stripped from sequences with a warning (see the test under issue 87); there
# are no plans to support amino acid sequences



#******************************************************************************#
#                                                                              #
#                 Add restriction enzyme site cutting options                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/415

# open issue (not covered): request for --cut_left / --cut_right options to
# extract the region between restriction sites



#******************************************************************************#
#                                                                              #
#                       cluster-features-open-reference                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/416

# not a bug: open-reference clustering is closed-reference clustering
# (--usearch_global with --dbmatched/--notmatched) followed by de novo
# clustering of the unmatched reads



#******************************************************************************#
#                                                                              #
#                      add a shell auto-completion script                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/417

# open issue (not covered): request for shell auto-completion scripts



#******************************************************************************#
#                                                                              #
#            fix reverse complement sequence hash when header used             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/418

# not testable (pull request fixing a reverse-complement hashing detail)



#******************************************************************************#
#                                                                              #
#  OTUs with sequences having larger than 97% similarity after clustering at   #
#                                     97%                                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/419

# not a bug: with greedy clustering, two centroids are never >= the threshold
# similar, but non-centroid members of different clusters can be, when they
# lie on the border between clusters



#******************************************************************************#
#                                                                              #
#                       Fix: small typo in the man pages                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/420

# not testable (pull request fixing a man-page typo)



#******************************************************************************#
#                                                                              #
#                   How to save singletons in cluster_fast?                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/421

## not a bug: --cluster_fast does not filter out low-abundance sequences, so
## singletons are kept by default
DESCRIPTION="issue 421: --cluster_fast keeps singletons"
printf ">s1;size=10;\nAAAA\n>s2;size=1;\nTTTT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.5 \
        --minseqlength 1 \
        --centroids - \
        --quiet | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#      fastq_maxee argument not applying for fastx_filter on a FASTA file      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/422

## a quality-based filter such as --fastq_maxee cannot be applied to a FASTA
## file (no quality scores); vsearch now reports a fatal error instead of
## silently ignoring it
DESCRIPTION="issue 422: --fastx_filter --fastq_maxee on a FASTA file is rejected"
printf ">s\nACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_maxee 1.0 \
        --fastaout /dev/null 2>&1 | \
    grep -q "not accepted with the fastx_filter command when the input is a FASTA file" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                           Add search_pcr function                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/423

# open issue (not covered): request for --search_pcr and --search_oligodb



#******************************************************************************#
#                                                                              #
#             --allpairs_global problem with identity calculation              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/424

# not a bug: --allpairs_global computes global alignments but does not show
# (and sometimes does not count) the terminal gaps; adjusting the terminal gap
# penalties changes the reported identity



#******************************************************************************#
#                                                                              #
#                              translated search                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/425

# not testable (translated / amino-acid searches are not supported)



#******************************************************************************#
#                                                                              #
#                      Add option Sample like in Usearch                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/426

## the --sample option adds a ";sample=" identifier to the sequence headers
DESCRIPTION="issue 426: --sample adds a sample identifier to the headers"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sample ABC \
        --fastaout - \
        --quiet | \
    grep -qx ">s1;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                  Vsearch for clustering protein sequences?                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/427

# not testable (protein sequences are not supported)



#******************************************************************************#
#                                                                              #
#                         cluster id in consensus file                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/428

# the --clusterout_id option adds the cluster id to the consout headers;
# tested under issue 103 (and issue 313 for centroids)



#******************************************************************************#
#                                                                              #
#                  incorrect alignment output in --userfields                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/429

## not a bug: in the alignment string reported by --userfields caln (and aln),
## "M" denotes a column that is either a match or a mismatch (only "I" and "D"
## denote gaps), as in usearch. The query and target below differ at their
## first and last 3 bases, giving an identity of 91.0% but an all-"M" caln.
DESCRIPTION="issue 429: caln reports M for both matches and mismatches"
Q="GACTTAATTGGATTGAGCCTTGGTATGGAAACCTACTAAGTGGTAACTTTCAAATTCAGAGAAACCC"
T="CTTTTAATTGGATTGAGCCTTGGTATGGAAACCTACTAAGTGGTAACTTTCAAATTCAGAGAAAGGG"
printf ">query\n%s\n" "${Q}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">target\n%s\n" "${T}") \
        --id 0.5 \
        --minseqlength 1 \
        --userfields caln+id \
        --userout - \
        --quiet | \
    grep -qx "67M	91.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset Q T



#******************************************************************************#
#                                                                              #
#                          Unexpected unmerged reads                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/430

# not a bug: vsearch refuses to merge a pair when it finds a potential
# alternative alignment (based on shared 5-mers), to avoid a wrong merge



#******************************************************************************#
#                                                                              #
#         big difference for clustering otus using vsearch and usearch         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/431

# not testable (usearch --cluster_otus has no direct equivalent in vsearch; a
# methodological question)



#******************************************************************************#
#                                                                              #
#                     Banded Alignments and long sequences                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/400

# open issue (not covered): request for banded pairwise alignment to speed up
# the comparison of longer sequences



#******************************************************************************#
#                                                                              #
#                        Extracting the sequences reads                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/401

# not testable (a usage question: matching sequences can be written with
# --matched / --dbmatched, or extracted with --fastx_getseqs)



#******************************************************************************#
#                                                                              #
#                   groff warnings when creating pdf manual                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/402

# not testable (groff warnings while building the PDF manual)



#******************************************************************************#
#                                                                              #
#                       compilation warning with gcc 10                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/403

# not testable (a maybe-uninitialized warning in sintax.cc with gcc 10)



#******************************************************************************#
#                                                                              #
#             Vsearch crash when input have a non-ASCII character              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/404

## a non-ASCII character in a FASTA/FASTQ header used to crash vsearch; it now
## emits a warning and continues (here U+00EB, octal 303 253)
DESCRIPTION="issue 404: a non-ASCII character in a header gives a warning, not a crash"
printf ">12345;Epichlo\303\253_amarillans\nAAATTTCCCGGGAAAAAATTTCCCGGG\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nAAATTTCCCGGGAAAAAATTTCCCGGG\n") \
        --id 0.9 \
        --minseqlength 1 \
        --blast6out /dev/null 2>&1 | \
    grep -q "Non-ASCII character" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                  Vsearch SINTAX lose taxonomy in whitespace                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/405

## --sintax must recover the complete taxonomy even when a taxonomic value
## contains a space (here the genus "Clostridium sensu stricto"); the
## taxonomy must be part of the header identifier (before the first space)
DESCRIPTION="issue 405: --sintax recovers a taxonomy value that contains spaces"
SEQ="TACGTAGGTGGCAAGCGTTATCCGGAATTATTGGGCGTAAAGCGCGCGTAGGCGGTTTTTTAAGTCTGATGTGAAAGCCC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">12345;tax=d:Bacteria,g:Clostridium sensu stricto\n%s\n" "${SEQ}") \
        --sintax_cutoff 0 \
        --tabbedout - \
        --quiet | \
    grep -q "g:Clostridium sensu stricto" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ



#******************************************************************************#
#                                                                              #
#              different OTU tables following different pipelines              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/406

# not a bug: results from clustering may deviate slightly from a subsequent
# search against the centroids, because of processing order and ties between
# candidate centroids (see issue 419)



#******************************************************************************#
#                                                                              #
#                         --usearch_global and sorting                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/407

# not a bug: output order is only guaranteed with --threads 1; multithreading
# writes results in a variable order



#******************************************************************************#
#                                                                              #
#                       --maxhits 0 differs from USEARCH                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/408

## --maxhits 0 used to return zero hits; it now means unlimited hits (like the
## default and like usearch)
DESCRIPTION="issue 408: --maxhits 0 means unlimited hits"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAA\n>q2\nAA\n") \
    --db <(printf ">s1\nAA\n") \
    --minseqlength 0 \
    --id 1.0 \
    --maxhits 0 \
    --userfields query+target \
    --userout - \
    --quiet | \
    awk 'END {exit (NR > 0) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                        -minsize flag in -cluster_fast                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/409

# not a bug: --cluster_fast has no --minsize option (it never filtered on
# abundance); use --sortbysize or --fastx_filter with --minsize after
# clustering (see also issue 421)



#******************************************************************************#
#                                                                              #
#                   struct sortinfo_s defined inconsistently                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/410

# not testable (a source-code consistency warning)



#******************************************************************************#
#                                                                              #
#               Improve error messages for malformed FASTQ files               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/411

## the error message for a FASTQ entry whose sequence and quality lines differ
## in length is now explicit
DESCRIPTION="issue 411: clear error when FASTQ sequence and quality lines differ in length"
printf "@a\nAA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastqout /dev/null 2>&1 | \
    grep -q "Sequence and quality lines must be equally long" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#         sintax: should the command accept the --minseqlength option?         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/494

## the --sintax command must accept the --minseqlength (and --maxseqlength)
## option; it previously rejected it and silently filtered sequences shorter
## than 32 nucleotides. Fixed.
DESCRIPTION="issue 494: --sintax accepts the --minseqlength option"
SEQ="TACGTAGGTGGCAAGCGTTATCCGGAATTATTGGGCGTAAAGCGCGCGTAGGCGGTTTTTTAAGTCTGATGTGAAAGCCC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">x;tax=d:Bacteria\n%s\n" "${SEQ}") \
        --minseqlength 1 \
        --sintax_cutoff 0 \
        --tabbedout /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ



#******************************************************************************#
#                                                                              #
#                    vsearch search_global time complexity                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/495

# not testable (a question about the time complexity of the search heuristic)



#******************************************************************************#
#                                                                              #
#                 Allow FASTQ files as input to more commands                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/496

# open issue (not covered): request to let more commands (e.g. usearch_global)
# accept FASTQ input



#******************************************************************************#
#                                                                              #
#              Check for SSSE3 should be build time, not run time              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/497

# not testable (build-configuration pull request about SSSE3 detection)



#******************************************************************************#
#                                                                              #
#           Large number of clusters with small number of sequences            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/490

# not testable (a usage question: the number and size of clusters depend
# mostly on the --id threshold and the data quality)



#******************************************************************************#
#                                                                              #
#                 Perfect overlaps not getting merged together                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/491

# not a bug: the ends of the reads must match to be merged; here a non-matching
# tail of T's that would need clipping prevents merging



#******************************************************************************#
#                                                                              #
#                  global alignment and semi-global alignment                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/482

# not testable (a question: vsearch performs global alignment, but the very
# low default terminal gap penalties make it behave like semi-global)



#******************************************************************************#
#                                                                              #
#                          Definition of a read pair                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/483

# not a bug: --fastq_mergepairs pairs reads by their position/index in the two
# files, not by their name (it only checks that both files have the same
# number of reads)



#******************************************************************************#
#                                                                              #
#                       drop in replacement for usearch                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/484

# not testable (a question: vsearch is not a literal drop-in replacement for
# usearch, as not all later usearch commands are implemented)



#******************************************************************************#
#                                                                              #
#                  How is the expected error rate calculated?                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/485

# not a bug: the expected error (EE) is the sum of the per-position error
# probabilities (sum of 10^(-Q/10)), so it can be greater than one



#******************************************************************************#
#                                                                              #
#       Could I only output the names of query and target sequences with       #
#                               usearch_global?                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/486

# not a bug: use --userout with --userfields query+target to output only the
# query and target names



#******************************************************************************#
#                                                                              #
#   Could vsearch standardize the otu table and compute relative abundances    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/487

# open issue (not covered): request for OTU-table normalization and taxonomic
# summaries (otutab_norm / sintax_summary)



#******************************************************************************#
#                                                                              #
#               Optional low memory mode for --derep_fulllength                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/475

# not testable (a feature request for a lower-memory dereplication mode)



#******************************************************************************#
#                                                                              #
#                  derep_fulllength: empty output fasta file                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/476

# not testable (dereplication was killed (out of memory) before writing any
# output; an environment/resource limitation)



#******************************************************************************#
#                                                                              #
#   usearch_global shows different results for the same seq in different db    #
#                                    files                                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/477

# not testable (the kmer-based heuristic can give different results depending
# on the database content and order; not a bug)



#******************************************************************************#
#                                                                              #
#                        error in swarm when clustering                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/478

# not testable (a swarm usage question: abundance annotations require swarm's
# -z option; not a vsearch issue)



#******************************************************************************#
#                                                                              #
#                       fix two GCC 10.2 format warnings                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/471

# not testable (pull request fixing two GCC 10.2 format warnings)



#******************************************************************************#
#                                                                              #
#         derep_fulllength: handling of empty input files and streams          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/472

## --derep_fulllength must handle an empty input gracefully (an empty input was
## wrongly detected as a FASTQ file, causing an error); fixed in 2.21.1
DESCRIPTION="issue 472: --derep_fulllength handles empty input without error"
printf "" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --output /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#                       compute runtime value only once                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/450

# not testable (source-optimization pull request)



#******************************************************************************#
#                                                                              #
#                              Error during make                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/451

# not testable (compilation error when the zlib.h header was unavailable)



#******************************************************************************#
#                                                                              #
#                 Fatal error: Unable to open file for writing                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/452

# not testable (the target directory was not writable by the user; a file-
# permission problem, not a vsearch bug)



#******************************************************************************#
#                                                                              #
#     Abundance information not stripped from headers in --uc output with      #
#                                   --xsize                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/453

## --xsize must also strip the abundance annotation from the labels written to
## the --uc file (it previously kept e.g. "s1;size=5;"); fixed
DESCRIPTION="issue 453: --cluster_size --xsize strips the abundance from the --uc labels"
printf ">s1;size=5;\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 1.0 \
        --minseqlength 1 \
        --xsize \
        --uc - \
        --quiet | \
    awk '$1 == "S" {print $9}' | \
    grep -qx "s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#    Installation - error in sudo make: recipe for target 'fastx.o' failed     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/454

# not testable (compilation error when the zlib.h header was unavailable, see
# issue 451)



#******************************************************************************#
#                                                                              #
#                            Documentation missing                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/455

# not testable (a broken documentation link)



#******************************************************************************#
#                                                                              #
#         Potentially incorrect results on ppc64le with usearch_global         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/456

# not testable (a compiler-optimization bug on the ppc64le architecture,
# caused by an illegal pointer conversion in cpu.cc)



#******************************************************************************#
#                                                                              #
#                              Hints from Lintian                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/457

# not testable (Lintian hints, mostly manual typos)



#******************************************************************************#
#                                                                              #
#                Compilation error with Autoconf 2.70 on Debian                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/458

# not testable (build issue with Autoconf 2.70)



#******************************************************************************#
#                                                                              #
#               Disable maxseqlength and minseqlength by default               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/459

# not a bug (kept as is): vsearch is designed for short sequences and becomes
# slow with long ones, so the default length limits are retained; sequences
# excluded by the limits are reported



#******************************************************************************#
#                                                                              #
#                      About converting read2 FASTQ only                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/460

# not testable (a usage question: non-overlapping pairs cannot be merged; the
# --fastq_join command can join them with a gap of Ns)



#******************************************************************************#
#                                                                              #
#        Feature request --selfmap filename or --self optional filename        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/461

# open issue (not covered): request for a --selfmap option to prevent matches
# between sequences from the same genome/accession



#******************************************************************************#
#                                                                              #
#                Feature request - UDB support with uchime_ref                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/462

## --uchime_ref must accept a UDB database (the file type is detected
## automatically); it previously failed with "File type not recognized."
DESCRIPTION="issue 462: --uchime_ref accepts a UDB database"
UDB=$(mktemp)
printf ">t\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --minseqlength 1 \
        --dbmask dust \
        --output "${UDB}" \
        --quiet
printf ">a;size=9\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${UDB}" \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${UDB}"



#******************************************************************************#
#                                                                              #
#         Version of the make utility to compile the vsearch software          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/463

# not testable (a question about the required make version; the build process
# is not exercised by these tests)



#******************************************************************************#
#                                                                              #
#                   Allow randseed option to sintax command                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/464

## the --randseed option is accepted by the --sintax command (whose algorithm
## has a random element); added in version 2.19.0
DESCRIPTION="issue 464: --sintax accepts the --randseed option"
SEQ="TACGTAGGTGGCAAGCGTTATCCGGAATTATTGGGCGTAAAGCGCGCGTAGGCGGTTTTTTAAGTCTGATGTGAAAGCCC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">x;tax=d:Bacteria\n%s\n" "${SEQ}") \
        --randseed 1 \
        --threads 1 \
        --sintax_cutoff 0 \
        --tabbedout /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ



#******************************************************************************#
#                                                                              #
#    Feature request - normalize samples to the same number of reads in otu    #
#                                    table                                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/465

# open issue (not covered): request for an otutab_rare/otutab_norm-like
# normalization of OTU tables



#******************************************************************************#
#                                                                              #
#                Multithreading support on fastq_filter command                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/466

# not testable (the bottleneck is reading and writing files, not the
# filtering itself, so multithreading would help little)



#******************************************************************************#
#                                                                              #
#     It seemed that vsearch don't have -otutab_stats function in usearch      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/467

# not testable (the usearch --otutab_stats command is not implemented in
# vsearch)



#******************************************************************************#
#                                                                              #
#                       cite Edgar and Flyvbjerg (2015)                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/468

# not testable (documentation pull request adding a citation)



#******************************************************************************#
#                                                                              #
#      fastq_mergepairs randomly fails to finish when called in parallel       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/469

# not testable (a rare multi-threading hang during --fastq_mergepairs)



#******************************************************************************#
#                                                                              #
#                      Fasta Header problem (issue 398)                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/398

# vsearch detects non-ascii characters (128-255) in fasta headers and
# issues a warning for each character

DESCRIPTION="issue 398: detect non-ascii chars in fasta headers and issue a warning"
WARNING="WARNING: Non-ASCII"
"${VSEARCH}" \
    --uchime_ref <(printf ">s1\nAC\n") \
    --db <(printf ">s2×\nAC\n") \
    --nonchimeras /dev/null \
    --quiet 2>&1 | \
    grep -q "${WARNING}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# ************************************************************************** #
#                                                                            #
#               Crash on Windows with some versions of zlib1.dll             #
#                    when reading gzipped files (issue 412)                  #
#                                                                            #
# ************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/412

## already tested in issue 9


# ************************************************************************** #
#                                                                            #
#       Version and binary of vsearch for macOS 11 on ARM (issue 413)        #
#                                                                            #
# ************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/413

## not testable, binaries for macOS ARM64 are available now


# ************************************************************************** #
#                                                                            #
#       small unexpected difference in id3 similarity value (issue 432)      #
#                                                                            #
# ************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/432

## 1 - test large alignment from issue #432

QUERY_SEQ="AGCTCCATTAGCGTATATTAAAATTGTTGCAGTTGAAAAGCTCGTAGTTGGATCTTTGACAGGTGTAGATTTTATTTTTGTTTGGAATCTAAATTTTGAATTAATATCTGTCATTCGTGGCATGGGAAGTAGTGTTTGGCATTTGGCTATGTTGGGTACTGCAGAACAGGAGCATAATTACTTTGAGGAAAGGAGAGCGATTAAGGCAAGCAAGACGTCGTGTATCTAGTAGCATGGAATAATATGATAGGGCTAATTTCTAATTTTTTGTTGGTTTAATGAGATATAGCAATGATTGATAGGGATAGTTGGGGGTGCTAGTATTCAATGGCCAGAGGTGAAATTCTTGGATTCATTGAAGACTGTCTTTAGCGAAAGCATTCACCAAGGATATCTTCT"
TARGET_SEQ="AGCTCCAAGGGCGTACACTAACATTGCTGCTGTTAAAACACTTGTAGTCCGCCTCAGGGATCCAGGTCTGCCGGACGGCCGCCGCGTCGCGCCCCCGCCCCCCCCGCGGCGGGTTACAACCTCCGCGCAGTATGCTCCTGGTCCCGCCCGTTCATCCGGTACKATGGTGCAATCGGCCCCCGCGCGAGGCCCCCTTCAGTGGGCGGCCGAGGCGGTCTCAACACCCGACACGTGTGGTTCCTTGACGCGAGGGGGGGGGGGCTCGCGGCGCGGGGCGGTGTGCSCGGGGGGGGGCGTGGTGCGGTCCGCCGCACCGCGCATCCCCCGGCCCCGGCCCGCACCCGGACCCTCCCCACCGGGGGACGCGGCCCCCGTTGCGCCGTCGGTCTGCTCCCCCCGTCCACCACCGGGGCTCACCGTCCCCGTCACCATGGAAAACTCAGTGTGCCCCAGGCGTTTCGACATTGGCTCCCCCCTTCTCCCCCCCCGCCCCCGCGGCGGCGGGGGGACCGTCCGACCGTACGCCCGTCCATGGAATGTCACAGCATCGACTCAAGGTGGCCACCGCACCGGGACCCCCGCGGTTCCGGAACCGTTTGTTTGTGCTGGCCTTGGAGCCCCTGCCCCGAGGGAACCTGGCGCCCGCGGCCCCCCCCAGCCCGGCGGACCCCGCACGCCCCCCGCGGCCCCCCGGGGCCAAACGGGGCGTTCCGCGGTCCCCGAGGGGGGGTGGGGCCCGCGCCGCTCGCCAGCGAGGGGACCGCTCGGGGCGCAAGGTATGGCGACGCCAGAGGTGAAATTCTCAGACCGCCGCCCGACCCGCGGCGGCGCAGGCGTTCTGCAAGTGCGTGTCCG"

# Find best pairwise alignment, keep id3 matches >= 0.5, expect a
# similarity of 98.7%
#
# Qry 381 + TTCACCAAGGATATCTTCT 399
#             | ||||||   |   ||
# Tgt   1 + AGCTCCAAGGGCGTACACT 19
DESCRIPTION="issue 432: id3 similarity value for large sequences with a small overlap"
"${VSEARCH}" \
    --usearch_global <(printf ">query1\n%s\n" "${QUERY_SEQ}") \
    --threads 1 \
    --quiet \
    --qmask none \
    --dbmask none \
    --notrunclabels \
    --maxaccepts 0 \
    --maxrejects 0 \
    --top_hits_only \
    --db <(printf ">target1\n%s\n" "${TARGET_SEQ}") \
    --id 0.5 \
    --iddef 3 \
    --userfields id3+mism+gaps+opens+tl \
    --userout - | \
    awk '{exit ($1 == 98.7 && $2 == 9 && $3 == 0 && $4 == 0 && $5 == 855) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset QUERY_SEQ TARGET_SEQ

# id3 is defined as such:

# counting each gap opening (internal or terminal) as a single
# mismatch, whether or not the gap was extended: 1.0 - [(mismatches +
# gap openings)/(longest sequence length)]

# In that particular alignment, we have the following values:
#  - mismatches = 9,
#  - gap openings = 2, (two large terminal gaps)
#  - longest sequence length = 855

# The id3 formula simplifies to 1 - (11 / 855) = 98.7%

# However, when using 'userfields' to report the number of gap
# openings ('opens') or columns containing a gap ('gaps'), the
# returned values are null.

# Hypothesis: terminal gaps are not included in the userfields 'gaps'
# and 'opens'

# This is indeed the way usearch works (versions 6 to 11 tested):
# ./usearch11.0.667_i86linux32 \
#     --usearch_global tmp_query \
#     --quiet \
#     --strand plus \
#     --qmask none \
#     --dbmask none \
#     --maxaccepts 0 \
#     --maxrejects 0 \
#     --db tmp_target \
#     --id 1.0 \
#     --userfields id+opens+caln \
#     --userout tmp_userout ; cat tmp_userout

# Let's test vsearch.

## 2 - tiny test showing that terminal gaps are excluded by 'opens' or 'gaps'

SEQ="TTCACCAAGGATATCTTCTTTCACCAAGGATA"

# Qry TTCACCAAGGATATCTTCTTTCACCAAGGATA
#     ||||||||||||||||||||||||||||||||
# Tgt TTCACCAAGGATATCTTCTTTCACCAAGGATA
DESCRIPTION="issue 432: userfields 'opens' excludes terminal gaps (no gap)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQ}") \
    --quiet \
    --qmask none \
    --dbmask none \
    --db <(printf ">t1\n%s\n" "${SEQ}") \
    --id 1.0 \
    --userfields id+opens+caln \
    --userout - | \
    awk '{exit ($1 == 100.0 && $2 == 0 && $3 == "32M") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Qry TTCACCAAGGATATCTTCTTTCACCAAGGATA----
#     ||||||||||||||||||||||||||||||||
# Tgt TTCACCAAGGATATCTTCTTTCACCAAGGATACCCC
DESCRIPTION="issue 432: userfields 'opens' excludes terminal gaps (left gap)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQ}") \
    --quiet \
    --qmask none \
    --dbmask none \
    --db <(printf ">t1\n%sCCCC\n" "${SEQ}") \
    --id 1.0 \
    --userfields id+opens+caln \
    --userout - | \
    awk '{exit ($1 == 100.0 && $2 == 0 && $3 == "32M4I") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Qry ----TTCACCAAGGATATCTTCTTTCACCAAGGATA
#         ||||||||||||||||||||||||||||||||
# Tgt CCCCTTCACCAAGGATATCTTCTTTCACCAAGGATA
DESCRIPTION="issue 432: userfields 'opens' excludes terminal gaps (right gap)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQ}") \
    --quiet \
    --qmask none \
    --dbmask none \
    --db <(printf ">t1\nCCCC%s\n" "${SEQ}") \
    --id 1.0 \
    --userfields id+opens+caln \
    --userout - | \
    awk '{exit ($1 == 100.0 && $2 == 0 && $3 == "4I32M") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Qry ----TTCACCAAGGATATCTTCTTTCACCAAGGATA----
#         ||||||||||||||||||||||||||||||||
# Tgt CCCCTTCACCAAGGATATCTTCTTTCACCAAGGATACCCC
DESCRIPTION="issue 432: userfields 'opens' excludes terminal gaps (left & right gap)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQ}") \
    --quiet \
    --qmask none \
    --dbmask none \
    --db <(printf ">t1\nCCCC%sCCCC\n" "${SEQ}") \
    --id 1.0 \
    --userfields id+opens+caln \
    --userout - | \
    awk '{exit ($1 == 100.0 && $2 == 0 && $3 == "4I32M4I") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Qry TTCACCAAGGATATCTTCTTTCACCAAGGATA
#     ||||||||||||||||||||||||||||||||
# Tgt TTCACCAAGGATATCTTCTTTCACCAAGGATA
DESCRIPTION="issue 432: userfields 'gaps' excludes terminal gaps (no gap)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQ}") \
    --quiet \
    --qmask none \
    --dbmask none \
    --db <(printf ">t1\n%s\n" "${SEQ}") \
    --id 1.0 \
    --userfields id+gaps+caln \
    --userout - | \
    awk '{exit ($1 == 100.0 && $2 == 0 && $3 == "32M") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Qry TTCACCAAGGATATCTTCTTTCACCAAGGATA----
#     ||||||||||||||||||||||||||||||||
# Tgt TTCACCAAGGATATCTTCTTTCACCAAGGATACCCC
DESCRIPTION="issue 432: userfields 'gaps' excludes terminal gaps (left gap)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQ}") \
    --quiet \
    --qmask none \
    --dbmask none \
    --db <(printf ">t1\n%sCCCC\n" "${SEQ}") \
    --id 1.0 \
    --userfields id+gaps+caln \
    --userout - | \
    awk '{exit ($1 == 100.0 && $2 == 0 && $3 == "32M4I") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Qry ----TTCACCAAGGATATCTTCTTTCACCAAGGATA
#         ||||||||||||||||||||||||||||||||
# Tgt CCCCTTCACCAAGGATATCTTCTTTCACCAAGGATA
DESCRIPTION="issue 432: userfields 'gaps' excludes terminal gaps (right gap)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQ}") \
    --quiet \
    --qmask none \
    --dbmask none \
    --db <(printf ">t1\nCCCC%s\n" "${SEQ}") \
    --id 1.0 \
    --userfields id+gaps+caln \
    --userout - | \
    awk '{exit ($1 == 100.0 && $2 == 0 && $3 == "4I32M") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Qry ----TTCACCAAGGATATCTTCTTTCACCAAGGATA----
#         ||||||||||||||||||||||||||||||||
# Tgt CCCCTTCACCAAGGATATCTTCTTTCACCAAGGATACCCC
DESCRIPTION="issue 432: userfields 'gaps' excludes terminal gaps (left & right gap)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQ}") \
    --quiet \
    --qmask none \
    --dbmask none \
    --db <(printf ">t1\nCCCC%sCCCC\n" "${SEQ}") \
    --id 1.0 \
    --userfields id+gaps+caln \
    --userout - | \
    awk '{exit ($1 == 100.0 && $2 == 0 && $3 == "4I32M4I") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset SEQ

# Notes:
#  - similarity remains 100% in all tests,
#  - caln (CIGAR format) is used to check the structure of the alignment,
#  - caln is from the point-of-view of the query sequence


# ************************************************************************** #
#                                                                            #
#              is test suite in sync with vsearch ? (issue 442)              #
#                                                                            #
# ************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/442

## not testable


# ************************************************************************** #
#                                                                            #
#    Fatal error: Invalid line 3 in FASTQ file: '+' line must be empty or    #
#                      identical to header (issue 470)                       #
#                                                                            #
# ************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/470

DESCRIPTION="issue 470: '+' line must be empty or identical to header (empty)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --quiet \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 470: '+' line must be empty or identical to header (equal)"
printf "@s\nA\n+s\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --quiet \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 470: '+' line must be empty or identical to header (unequal)"
printf "@s\nA\n+s1\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats2 - \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# ************************************************************************** #
#                                                                            #
#    Alignment using vsearch, how to output the sequence of the best hit?    #
#                                (issue 473)                                 #
#                                                                            #
# ************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/473

DESCRIPTION="issue 473: use qrow and trow fields to output aligned sequences"
"${VSEARCH}" \
    --usearch_global <(printf ">q\nAAATCG\n") \
    --db <(printf ">s1\nAAATGGA\n") \
    --quiet \
    --minseqlength 1 \
    --id 0.8 \
    --userfields "qrow+trow" \
    --userout - | \
    tr "\t" "@" | \
    grep -qx "AAATCG@AAATGG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# ************************************************************************** #
#                                                                            #
#      support for Illumina RTA3 simplified quality scores? (issue 474)      #
#                                                                            #
# ************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/474

#  !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
#  |                         |    |        |                              |                     |
# 33                        59   64       73                            104                   126
#    |         |          |             |
#    2........12.........23............37
#                                   |         |          |             |
#                                   2........12.........23............37

# |   RTA3 |     |     |
# | offset | +33 | +64 |
# |--------+-----+-----|
# |      2 | '#' | 'B' |
# |     12 | '-' | 'L' |
# |     23 | '8' | 'W' |
# |     37 | 'F' | 'e' |
# |--------+-----+-----|

# |  MiSeq |     |     |
# |   2023 |     |     |
# | offset | +33 | +64 |
# |--------+-----+-----|
# |      2 | '#' | 'B' |
# |     14 | '/' | 'N' |
# |     21 | '6' | 'U' |
# |     27 | '<' | '[' |
# |     32 | 'A' | '`' |
# |     36 | 'E' | 'd' |
# |--------+-----+-----|

for OFFSET in 33 64 ; do

    # NovaSeq and RTA3 (2021)
    for i in 2 12 23 37 ; do
        DESCRIPTION="issue 474: NovaSeq RTA3 quality score ${i} is accepted (offset +${OFFSET})"
        OCTAL=$(printf "\%04o" $(( i + OFFSET )) )
        echo -e "@s\nA\n+\n${OCTAL}\n" | \
            "${VSEARCH}" \
                --fastq_eestats - \
                --fastq_ascii ${OFFSET} \
                --quiet \
                --output /dev/null 2> /dev/null && \
            success "${DESCRIPTION}" || \
                failure "${DESCRIPTION}"
    done

    # NextSeq and RTA3 (2023) observed in August 2023
    for i in 2 14 21 27 32 36 ; do
        DESCRIPTION="issue 474: NextSeq RTA3 quality score ${i} is accepted (offset +${OFFSET})"
        OCTAL=$(printf "\%04o" $(( i + OFFSET )) )
        echo -e "@s\nA\n+\n${OCTAL}\n" | \
            "${VSEARCH}" \
                --fastq_eestats - \
                --fastq_ascii ${OFFSET} \
                --quiet \
                --output /dev/null 2> /dev/null && \
            success "${DESCRIPTION}" || \
                failure "${DESCRIPTION}"
    done

done
unset OCTAL OFFSET DESCRIPTION


# ************************************************************************** #
#                                                                            #
#               not all samples appear in OTU table (issue 479)              #
#                                                                            #
# ************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/479

## three identical sequences, present in three samples
# >s1;size=2;sample=A1;
# A
# >s2;size=1;sample=A2;
# A
# >s3;size=4;sample=A3;
# A

## expected:
# #OTU ID	A1	A2	A3
# OTU_1	2	1	4

DESCRIPTION="issue 479: not all samples appear in OTU table"
printf ">s1;size=2;sample=A1;\nA\n>s2;size=1;sample=A2;\nA\n>s3;size=4;sample=A3;\nA\n" |\
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --quiet \
        --id 0.97 \
        --strand plus \
        --sizein \
        --sizeout \
        --relabel OTU_ \
        --otutabout - | \
    tr -d '\n' | \
    tr "\t" "@" | \
    grep -qx "#OTU ID@A1@A2@A3OTU_1@2@1@4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# ************************************************************************** #
#                                                                            #
#                 optimization flag is set to -O2 (issue 480)                #
#                                                                            #
# ************************************************************************** #
#
## https://github.com/torognes/vsearch/issues/480

## question: not testable


# ************************************************************************** #
#                                                                            #
#         Recover info in fasta header when using sintax (issue 481)         #
#                                                                            #
# ************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/481

HEADER1="UDB018521|SH1140878.08FU;tax=d:Fungi,p:Basidiomycota,c:Agaricomycetes,o:Thelephorales,f:Thelephoraceae,g:Tomentella,s:Tomentella_badia_SH1140878.08FU;"
HEADER2="UDB026255|SH1140865.08FU;tax=d:Fungi,p:Basidiomycota,c:Agaricomycetes,o:Thelephorales,f:Thelephoraceae;"
SEQ1="GTCGCTCCATCCGAGTGTGCTAAAAATGAGGTATGGTCAGTCTGGTCGTATCGAATTTCTAGTATGCGAGGGGGGAGAAGTCGTAACAAGGTAGCC"
SEQ2="$(rev <<< "${SEQ1}")"

DESCRIPTION="issue 481: recover info in fasta header when using sintax (test sintax output #1)"
"${VSEARCH}" \
    --sintax <(printf ">query\n%s\n" "${SEQ1}") \
    --db <(printf ">%s\n%s\n>%s\n%s\n" "${HEADER1}" "${SEQ1}" "${HEADER2}" "${SEQ2}") \
    --quiet \
    --tabbedout - | \
    grep -q "SH1140878.08FU(1.00)[[:space:]]+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 481: recover info in fasta header when using sintax (test sintax output #2)"
"${VSEARCH}" \
    --sintax <(printf ">query\n%s\n" "${SEQ2}") \
    --db <(printf ">%s\n%s\n>%s\n%s\n" "${HEADER1}" "${SEQ1}" "${HEADER2}" "${SEQ2}") \
    --quiet \
    --tabbedout - | \
    grep -q "Thelephoraceae(1.00)[[:space:]]+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset HEADER1 HEADER2 SEQ1 SEQ2


# ************************************************************************** #
#                                                                            #
#             some questions about Extraction options (issue 488)            #
#                                                                            #
# ************************************************************************** #
#
## https://github.com/torognes/vsearch/issues/488

## label must match the entire header (not case-sensitive)
DESCRIPTION="issue 488: fastx_getseqs label matches the full header"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label "s1" \
        --fastaout - | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label matches the full header (not case-sensitive)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label "S1" \
        --fastaout - | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label does not match header with size annotation"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label "s1" \
        --fastaout - | \
    grep -qx ">s1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# label_substr_match: with that option, the label specified with
# --label may match anywhere in the header (not case-sensitive)
DESCRIPTION="issue 488: fastx_getseqs label_substr_match matches part of the header (#1)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label "s1" \
        --label_substr_match \
        --fastaout - | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label_substr_match matches part of the header (#2)"
printf ">s11\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label "s1" \
        --label_substr_match \
        --fastaout - | \
    grep -qx ">s11" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label_substr_match matches part of the header (not case-sensitive)"
printf ">s11\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label "S1" \
        --label_substr_match \
        --fastaout - | \
    grep -qx ">s11" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## label_word matches header with size annotations. Words are defined
## as strings delimited by either the start or end of the header or by
## any symbol that is not a letter (A-Z, a-z) or digit (0-9)
## (case-sensitive)
DESCRIPTION="issue 488: fastx_getseqs label_word matches the label (#1)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label_word "s1" \
        --fastaout - | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label_word matches the label (#2)"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label_word "s1" \
        --fastaout - | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label_word matches the label (and nothing more)"
printf ">s11;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label_word "s1" \
        --fastaout - | \
    grep -qx ">s1;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label_word matches the label (case-sensitive)"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label_word "S1" \
        --fastaout - | \
    grep -qx ">s1;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# ************************************************************************** #
#                                                                            #
#       vsearch fails to assign taxonomy for Fungi ITS seqs (issue 489)      #
#                                                                            #
# ************************************************************************** #
#
## https://github.com/torognes/vsearch/issues/489

CUTOFF="0.9"
Q1="TGAAGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAGGCCT"
TAX="tax=d:d,p:p,c:c,o:o,f:f,g:g,s:s"

# sintax assumes comma-separated taxonomy fields
DESCRIPTION="issue 489: sintax assumes comma-separated taxonomy fields"
printf ">q1\n%s\n" ${Q1} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --sintax_cutoff "${CUTOFF}" \
        --quiet \
        --tabbedout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sintax assumes comma-separated taxonomy fields (no error message if not)
DESCRIPTION="issue 489: sintax assumes comma-separated taxonomy fields (no error message if ';' is used)"
printf ">q1\n%s\n" ${Q1} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX//,/;} ${Q1}) \
        --sintax_cutoff "${CUTOFF}" \
        --quiet \
        --tabbedout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset Q1 TAX CUTOFF


# ************************************************************************** #
#                                                                            #
#  fastq_chars: sequence and quality lines must be equally long (issue 492)  #
#                                                                            #
# ************************************************************************** #
#
## https://github.com/torognes/vsearch/issues/492

DESCRIPTION="issue 492: fastq_chars final newline char '\\\t' is not required"
printf "@s\nA\n+\nI" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet \
        --log /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 492: fastq_chars seq and qual lines must have the same length"
printf "@s\nA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet \
        --log /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# ************************************************************************** #
#                                                                            #
#  sintax: extra tab in tabbedout output when there is no match (issue 493)  #
#                                                                            #
# ************************************************************************** #
#
## https://github.com/torognes/vsearch/issues/493

CUTOFF="0.9"
Q1="TGAAGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAGGCCT"
Q2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
TAX="tax=d:d,p:p,c:c,o:o,f:f,g:g,s:s"

# match: three tabs (four columns) as expected
DESCRIPTION="issue 493: sintax tabbedout 3 tabs (4 cols) when there is a match"
printf ">q1\n%s\n" ${Q1} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --sintax_cutoff "${CUTOFF}" \
        --quiet \
        --tabbedout - | \
    tr -cd '\t' | \
    wc -c | \
    awk '{exit $1 == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# no match: four tabs (five columns) instead of three
DESCRIPTION="issue 493: sintax tabbedout 3 tabs (4 cols) when there is no match"
printf ">q1\n%s\n" ${Q2} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --sintax_cutoff "${CUTOFF}" \
        --quiet \
        --tabbedout - | \
    tr -cd '\t' | \
    wc -c | \
    awk '{exit $1 == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset Q1 Q2 TAX CUTOFF


# ************************************************************************** #
#                                                                            #
#                  More than 7 levels in sintax (issue 498)                  #
#                                                                            #
# ************************************************************************** #
#
## https://github.com/torognes/vsearch/issues/498

# vsearch supports a ninth taxonomy level, strain (t)

Q1="TGAAGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAGGCCT"
Q2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
TAX="tax=d:d,k:k,p:p,c:c,o:o,f:f,g:g,s:s,t:t"

DESCRIPTION="issue 498: --sintax accepts nine levels (dkpcofgst)"
printf ">q1\n%s\n" ${Q1} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --sintax_cutoff 0.9 \
        --quiet \
        --tabbedout - | \
    cut -f 2 | \
    awk -F "," '{exit NF == 9 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 498: --sintax accepts level t (strain)"
printf ">q1\n%s\n" ${Q1} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --sintax_cutoff 0.9 \
        --quiet \
        --tabbedout - | \
    grep -q "t:t(1.00)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 498: --sintax accepts level t (strain) alone"
TAX="tax=t:t"
printf ">q1\n%s\n" ${Q1} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --sintax_cutoff 0.9 \
        --quiet \
        --tabbedout - | \
    grep -q "t:t(1.00)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 498: --sintax rejects unexpected level names (not dkpcofgst)"
TAX="tax=x:x"
printf ">q1\n%s\n" ${Q1} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --sintax_cutoff 0.9 \
        --quiet \
        --tabbedout - | \
    grep -q "x:x(1.00)" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 498: --sintax reorder levels (domain before kingdom)"
TAX="tax=k:k,d:d"
printf ">q1\n%s\n" ${Q1} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --sintax_cutoff 0.9 \
        --quiet \
        --tabbedout - | \
    grep -q "d:d(1.00),k:k(1.00)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset Q1 Q2 TAX


#******************************************************************************#
#                                                                              #
#                   question on edlib vs vsearch (issue 499)                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/499

# question, nothing to test yet


#******************************************************************************#
#                                                                              #
#     fastq --eeout: report more precise expected error values (issue 500)     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/500

# when working with quality values ranging from 0 to 40, the smallest
# possible expected error is 10E-(Q/10) = 1E-4 = 0.0001.

# The possible range of quality values has been extended to 41 with
# Illumina 1.8+, and to 93 with PacBio's HiFi reads. The returned ee
# values should include enough digits to cover Q = 41 (ee =
# 0.000079433), and Q = 93 (ee ~ 0.0000000005012).

# '!' = 0, ee = 1.0
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=0"
printf "@s1\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=1.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '+' = 10, ee = 0.1
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=10"
printf "@s1\nA\n+\n+\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '5' = 20, ee = 0.01
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=20"
printf "@s1\nA\n+\n5\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.01" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '?' = 30, ee = 0.001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=30"
printf "@s1\nA\n+\n?\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'I' = 40, ee = 0.0001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=40"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.0001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'J' = 41, ee = 0.000079433
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=41"
printf "@s1\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.000079" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'S' = 50, ee = 0.00001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=50"
printf "@s1\nA\n+\nS\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 50 \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.00001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ']' = 60, ee = 0.000001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=60"
printf "@s1\nA\n+\n]\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 60 \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.000001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'g' = 70, ee = 0.0000001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=70"
printf "@s1\nA\n+\ng\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 70 \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.0000001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'q' = 80, ee = 0.00000001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=80"
printf "@s1\nA\n+\nq\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 80 \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.00000001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '{' = 90, ee = 0.000000001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=90"
printf "@s1\nA\n+\n{\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 90 \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.000000001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '~' = 93, ee = 0.0000000005012
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=93"
printf "@s1\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 93 \
        --quiet \
        --eeout \
        --fastqout - | \
    grep -q "ee=0.0000000005" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# ------------------------------------------------ same tests for a fasta output

# '!' = 0, ee = 1.0
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=0 (fasta)"
printf "@s1\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=1.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '+' = 10, ee = 0.1
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=10 (fasta)"
printf "@s1\nA\n+\n+\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '5' = 20, ee = 0.01
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=20 (fasta)"
printf "@s1\nA\n+\n5\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.01" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '?' = 30, ee = 0.001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=30 (fasta)"
printf "@s1\nA\n+\n?\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'I' = 40, ee = 0.0001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=40 (fasta)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.0001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'J' = 41, ee = 0.000079433
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=41 (fasta)"
printf "@s1\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.000079" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'S' = 50, ee = 0.00001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=50 (fasta)"
printf "@s1\nA\n+\nS\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 50 \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.00001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ']' = 60, ee = 0.000001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=60 (fasta)"
printf "@s1\nA\n+\n]\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 60 \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.000001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'g' = 70, ee = 0.0000001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=70 (fasta)"
printf "@s1\nA\n+\ng\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 70 \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.0000001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'q' = 80, ee = 0.00000001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=80 (fasta)"
printf "@s1\nA\n+\nq\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 80 \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.00000001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '{' = 90, ee = 0.000000001
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=90 (fasta)"
printf "@s1\nA\n+\n{\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 90 \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.000000001" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '~' = 93, ee = 0.0000000005012
DESCRIPTION="issue 500: --eeout reports enough digits to distinguish Q=93 (fasta)"
printf "@s1\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 93 \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -q "ee=0.0000000005" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#          chimera detection: variable number of chunks (issue 501)            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/501

# question, nothing to test yet


#******************************************************************************#
#                                                                              #
#                         Missing options in --orient                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/502

# not a bug: --orient and --usearch_global are different commands; options
# such as --id, --maxaccepts, --strand, --query_cov, --userfields and
# --leftjust do not apply to --orient (usearch does not offer them either)



#******************************************************************************#
#                                                                              #
#                    UNOISE not using Levenshtein distance?                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/503

# not testable (analysis): for --cluster_unoise vsearch uses the
# Needleman-Wunsch aligner and counts the number of mismatches (substitutions
# and indels) as the distance d, behaving like usearch rather than using a
# strict Levenshtein distance



#******************************************************************************#
#                                                                              #
#       Chimera detection --uchime_ref unexpected behaviour (issue 504)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/504


#******************************************************************************#
#                                                                              #
#           Add Edgar RC (2016) UNOISE2 to references (issue 505)              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/505

# pull request (README.md), nothing to do


#******************************************************************************#
#                                                                              #
#              uchime_ref --db can't read from stdin (issue 506)               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/506

# --db generally does not accept '-' as argument meaning read from
# stdin. This was done intentionally to avoid the use of '-' for
# multiple arguments, which would cause problems.

DESCRIPTION="issue 506: reading --db from process substitutions"
"${VSEARCH}" \
    --uchime_ref <(printf ">query\nAAGG\n") \
    --db <(printf ">parentA\nAAAA\n>parentB\nGGGG\n") \
    --quiet \
    --uchimeout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 506: reading query from '-' (stdin) and --db from process substitution"
printf ">query\nAAGG\n" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db <(printf ">parentA\nAAAA\n>parentB\nGGGG\n") \
        --quiet \
        --uchimeout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# query is read from a regular file rather than a process substitution:
# on FreeBSD, combining a process-substitution query with --db
# /dev/stdin makes vsearch read the wrong stream ("File type not
# recognized"), because /dev/stdin (/dev/fd/0 via fdescfs) and bash
# process substitution both rely on /dev/fd and interact badly. A plain
# file query isolates the --db /dev/stdin path being tested here.
DESCRIPTION="issue 506: reading --db from /dev/stdin (query from a file)"
QUERY=$(mktemp)
printf ">query\nAAGG\n" > "${QUERY}"
printf ">parentA\nAAAA\n>parentB\nGGGG\n" | \
    "${VSEARCH}" \
        --uchime_ref "${QUERY}" \
        --db /dev/stdin \
        --quiet \
        --uchimeout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${QUERY}"

# '-' (read from stdin) is rejected for --db, by design. Before reading
# the database, vsearch calls udb_detect_isudb(), which runs stat() on
# the literal filename to test for a UDB file. stat("-") fails (there is
# no file named '-'), so vsearch stops with a fatal error. Explicit
# stream paths such as /dev/stdin or bash process substitution are real
# paths that stat() can resolve (and are then detected as pipes), which
# is why the tests above work while '-' does not.
DESCRIPTION="issue 506: reading --db from '-' (stdin) is rejected"
printf ">parentA\nAAAA\n>parentB\nGGGG\n" | \
    "${VSEARCH}" \
        --uchime_ref <(printf ">query\nAAGG\n") \
        --db - \
        --quiet \
        --uchimeout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#       Can vsearch combine two clustered-otutab together? (issue 507)         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/507

# Question: if both otutab1 and otutab2 were clustered at 97%
# similarity, what is the best way to combine them into a new otutab
# (otutab3)? If I use otutab1 as a reference, use blast to compare
# otutab2 with it (set 97% similarity), some otu may be aligned while
# others are not. Then relabel the unaligned OTUs bind them to
# otutab1, that’s otutab3 = otutab1 + otutab2-unaligned. Is otutab3
# reliable?

# No, otutab3 is not reliable. There is no easy way to merge
# independent clustering results. Even though all OTUs in otutab3 are
# at least 97% different, there might be sequences assigned to an otu
# in otutab1 that are actually more similar to otus in otutab2 and the
# other way round. So the safest strategy is to group all fasta
# sequences and to run a new clustering.

# Proof:

DESCRIPTION="issue 507: independent clustering results are not mergeable"

S1="TGAAGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAGGCCT"
S2="TGAAGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAAAAAA"
S3="CCCCGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAAAAAA"

# S1 TGAAGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAGGCCT
#        ||||||||||||||||||||||||||||||||||||
# S2 CCCCGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAAAAAA
#        |||||||||||||||||||||||||||||||||||||||||
# S3 TGAAGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAAAAAA

# similarities
# S1 vs S2: 88.9%
# S2 vs S3: 91.1%
# S1 vs S3: 80.0%

# with --id 0.85, 'S1' and 'S2' cluster together. When 'S3' is added,
# 'S3' and 'S2' cluster together, leaving 'S1' alone:

# #OTU ID	A
# s1	3
# s3	4

# For simplicity, all sequences come from a single sample 'A'.

(printf ">s1;size=3;sample=A;\n%s\n" $S1
 printf ">s2;size=1;sample=A;\n%s\n" $S2
 printf ">s3;size=3;sample=A;\n%s\n" $S3
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --quiet \
        --id 0.85 \
        --otutabout - | \
    awk 'BEGIN {FS = "\t"} NR == 3 {exit $1 == "s3" && $2 == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset S1 S2 S3

# Note on short sequences: There needs to be at least 6 shared k-mers
# to start the pairwise alignment, and at least one out of every 16
# k-mers from the query needs to match the target. (k-mers length is 8
# by default, see option --wordlength).


#******************************************************************************#
#                                                                              #
#         segmentation fault when printing out alignments (issue 508)          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/508

# When using the option --clusters "string" option, vsearch outputs
# each cluster to a separate fasta file using the prefix string and a
# ticker (0, 1, 2, etc.) to construct the path and filenames. It needs
# to allocate memory for the longest file name of the clusters files
# (length(string) + a potentially big number).

# If the option --clusters "string" is not used, then opt_clusters is
# a nullptr and vsearch should not try to compute length(nullptr)
# (segmentation fault).

DESCRIPTION="issue 508: cluster_size works with --clusters (no segfault)"
PREFIX=$(mktemp -u | cut -d "." -f 2)
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --uc /dev/null \
        --clusters "tmp${PREFIX}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "tmp${PREFIX}0"

DESCRIPTION="issue 508: cluster_size works without --clusters (no segfault)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --uc /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#      warnings with recent GCC (possible false-positives) (issue 509)         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/509

## compile-time, not testable


#******************************************************************************#
#                                                                              #
#                    vsearch in R markdown issue (issue 510)                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/510

DESCRIPTION="issue 510: vsearch is in path and is executable"
[[ -x "${VSEARCH}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#   Sintax sometimes only outputs the ID with no further columns (issue 511)   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/511

# (similar to issue 493) if the --sintax_cutoff option is not used,
# expect three columns for a match or no match

Q1="TGAAGAGTTTGATCATGGCTCAGATTGAACGCTGGCGGCAGGCCT"
Q2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
TAX="tax=d:d,p:p,c:c,o:o,f:f,g:g,s:s"

# match: two tabs (three columns)
DESCRIPTION="issue 511: sintax tabbedout 2 tabs (3 cols) when there is a match (no cutoff)"
printf ">q1\n%s\n" ${Q1} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --quiet \
        --tabbedout - | \
    tr -cd '\t' | \
    wc -c | \
    awk '{exit $1 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# no match: two tabs (three columns)
DESCRIPTION="issue 511: sintax tabbedout 2 tabs (3 cols) when there is no match (no cutoff)"
printf ">q1\n%s\n" ${Q2} | \
    "${VSEARCH}" \
        --sintax - \
        --dbmask none \
        --db <(printf ">s;%s\n%s\n" ${TAX} ${Q1}) \
        --quiet \
        --tabbedout - | \
    tr -cd '\t' | \
    wc -c | \
    awk '{exit $1 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset Q1 Q2 TAX


#******************************************************************************#
#                                                                              #
#    fastq_mergepairs Fatal error: More reverse reads than forward reads       #
#                                (issue 512)                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/512

DESCRIPTION="issue 512: fastq_mergepairs equal number of reads"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s1_1\nA\n+\nI\n") \
    --reverse <(printf "@s1_2\nT\n+\nI\n") \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 512: fastq_mergepairs more forward reads"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s1_1\nA\n+\nI\n@s2_1\nA\n+\nI\n") \
    --reverse <(printf "@s1_2\nT\n+\nI\n") \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 512: fastq_mergepairs more forward reads (error message)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s1_1\nA\n+\nI\n@s2_1\nA\n+\nI\n") \
    --reverse <(printf "@s1_2\nT\n+\nI\n") \
    --quiet \
    --fastaout /dev/null 2>&1 | \
    grep -q "forward" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 512: fastq_mergepairs more reverse reads"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s1_1\nA\n+\nI\n") \
    --reverse <(printf "@s1_2\nT\n+\nI\n@s2_2\nA\n+\nI\n") \
    --quiet \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 512: fastq_mergepairs more reverse reads (error message)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s1_1\nA\n+\nI\n") \
    --reverse <(printf "@s1_2\nT\n+\nI\n@s2_2\nA\n+\nI\n") \
    --quiet \
    --fastaout /dev/null 2>&1 | \
    grep -q "reverse" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                usearch_global - maxhits only returns one hit                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/513

## not a bug: --usearch_global reports at most one hit per database sequence
## for each query, even when the query motif occurs several times within the
## same target sequence (and even with --maxaccepts 0 --maxrejects 0). A local
## aligner would be needed to report every occurrence (see also issue 328).
DESCRIPTION="issue 513: --usearch_global reports a single hit per target with repeated occurrences"
MOTIF="CATGAGGCTGGTGTAAAGCGG"
printf ">q\n%s\n" "${MOTIF}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nTTTT%sAAAA%sCCCC\n" "${MOTIF}" "${MOTIF}") \
        --id 0.7 \
        --minseqlength 1 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --userfields query+target \
        --userout - \
        --quiet | \
    wc -l | \
    tr -d " " | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset MOTIF



#******************************************************************************#
#                                                                              #
#         combining datasets changes clustering results (issue 514)            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/514

# A given centroid1 can be abundant in a sample A, but close to a more
# abundant centroid2 present in a sample B. If you clusterize A+B,
# then centroid2 captures some or all the reads initially captured by
# centroid1.

# This is illustrated here:
#  - s1 and s2 come from the same sample A,
#  - s3 comes from sample B
#  - when clustering sample A alone, s1 captures s2
#  - when clustering samples A and B, s3 captures s2
#  - s1 ends up smaller than it was when sample B was not included

DESCRIPTION="issue 514: combining datasets changes clustering results"
(
    printf ">s1;size=2 sample=A\nTGATACATAGTATCGTCACATGAAAGGATTGGGTCGGATGTCTCAAACGAATTCG\n"
    # mismatch:                                                   *
    printf ">s2;size=1 sample=A\nTGATACATAGTATCGTCACATGAAAGGATTGGGCCGGATGTCTCAAACGAATTCG\n"
    # mismatch:                                                    *
    printf ">s3;size=3 sample=B\nTGATACATAGTATCGTCACATGAAAGGATTGGGCTGGATGTCTCAAACGAATTCG\n"
) | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --sizein \
        --xsize \
        --quiet \
        --uc - | \
    awk 'BEGIN {FS = "\t"} {if (/^H/) {exit ($9 == "s2" && $10 == "s3") ? 0 : 1}}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#    Include new labels in uc output for dereplication if --relabel option     #
#                                   provided                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/515

# pull request proposing to write the relabelled identifiers to the --uc
# output; it was not merged: the --uc output keeps the original labels. The
# old label can be preserved next to the new one with --relabel_keep (see
# issue 129)



#******************************************************************************#
#                                                                              #
#            vsearch tool detailed option in command line ? (issue 516)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/516

## not testable (yet)


#******************************************************************************#
#                                                                              #
#           Include rows of OTUs with no mapped reads in OTU tables            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/517

## OTUs (database sequences) with no mapped reads are now included in the OTU
## table as all-zero rows, for --otutabout, --biomout and --mothur_shared_out
## (fixed in 2.26.0). Here otu2 has no match and appears with a count of 0.
DESCRIPTION="issue 517: --otutabout includes OTUs with no mapped reads (zero rows)"
printf ">q;sample=A\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">otu1\nAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCC\n>otu2\nGGGGGGGGGGGGGGGGTTTTTTTTTTTTTTTT\n") \
        --id 0.97 \
        --minseqlength 1 \
        --otutabout - \
        --quiet | \
    grep -qx "otu2	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#              EE: document the meaning of expected error values               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/518

# not testable (documentation: the manpage was extended to explain how to
# interpret expected error (EE) values)



#******************************************************************************#
#                                                                              #
#       OTU table with columns for each fasta header instead of samples        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/519

# not a bug: --sample adds a ";sample=name" annotation (without a trailing
# semicolon); when the sample identifier cannot be parsed (e.g. because of
# spaces or extra semicolons in the header) the otutabout columns fall back to
# per-sequence names (see issue 335 for how sample identifiers are derived)



#******************************************************************************#
#                                                                              #
#        Windows binaries: working with compressed files (issue 520)           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/520

## read gzip and bzip2 files, already covered by issue #9


#******************************************************************************#
#                                                                              #
#   --sizein seems having no effect in vsearch --usearch_global (issue 521)    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/521

## We can have queries with size or not, subject with size or not,
## option sizein or not, option sizeout or not, single or multiple
## matches. It corresponds to five boolean variables, and 32 possible
## configurations.

DESCRIPTION="issue 521: usearch_global dbmatched (no size, single match)"
# qsize = False, ssize = False, sizein = False, sizeout = False, multiple = False
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --dbmatched /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (no size, double match)"
# qsize = False, ssize = False, sizein = False, sizeout = False, multiple = True
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n>q2\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --dbmatched /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (no size, sizeout, single match)"
# qsize = False, ssize = False, sizein = False, sizeout = True, multiple = False
# expect a single match ;size=1
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (no size, sizeout, double match)"
# qsize = False, ssize = False, sizein = False, sizeout = True, multiple = True
# expect a double match ;size=2
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n>q2\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (no size, sizein, single match)"
# qsize = False, ssize = False, sizein = True, sizeout = False, multiple = False
# expect a single match ;size=1
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --dbmatched /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (no size, sizein, double match)"
# qsize = False, ssize = False, sizein = True, sizeout = False, multiple = True
# expect a double match ;size=2
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n>q2\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --dbmatched /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (no size, sizein, sizeout, single match)"
# qsize = False, ssize = False, sizein = True, sizeout = True, multiple = False
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (no size, sizein, sizeout, double match)"
# qsize = False, ssize = False, sizein = True, sizeout = True, multiple = True
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n>q2\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (subject size, single match)"
# qsize = False, ssize = True, sizein = False, sizeout = False, multiple = False
# subject's size is left untouched
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n") \
    --db <(printf ">s1;size=3\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (subject size, double match)"
# qsize = False, ssize = True, sizein = False, sizeout = False, multiple = True
# subject's size is left untouched
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n>q2\nAAAA\n") \
    --db <(printf ">s1;size=3\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (subject size, sizeout, single match)"
# qsize = False, ssize = True, sizein = False, sizeout = True, multiple = False
# subject's size is overwritten
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n") \
    --db <(printf ">s1;size=3\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (subject size, sizeout, double match)"
# qsize = False, ssize = True, sizein = False, sizeout = True, multiple = True
# subject's size is overwritten
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n>q2\nAAAA\n") \
    --db <(printf ">s1;size=3\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (subject size, sizein, single match)"
# qsize = False, ssize = True, sizein = True, sizeout = False, multiple = False
# subject's size is left untouched
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n") \
    --db <(printf ">s1;size=3\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (subject size, sizein, double match)"
# qsize = False, ssize = True, sizein = True, sizeout = False, multiple = True
# subject's size is left untouched
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n>q2\nAAAA\n") \
    --db <(printf ">s1;size=3\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (subject size, sizein, sizeout, single match)"
# qsize = False, ssize = True, sizein = True, sizeout = True, multiple = False
# subject's size is overwritten
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n") \
    --db <(printf ">s1;size=3\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (subject size, sizein, sizeout, double match)"
# qsize = False, ssize = True, sizein = True, sizeout = True, multiple = True
# subject's size is overwritten
"${VSEARCH}" \
    --usearch_global <(printf ">q1\nAAAA\n>q2\nAAAA\n") \
    --db <(printf ">s1;size=3\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, single match)"
# qsize = True, ssize = False, sizein = False, sizeout = False, multiple = False
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --dbmatched /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, double match)"
# qsize = True, ssize = False, sizein = False, sizeout = False, multiple = True
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n>q2;size2\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --dbmatched /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, sizeout, single match)"
# qsize = True, ssize = False, sizein = False, sizeout = True, multiple = False
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, sizeout, double match)"
# qsize = True, ssize = False, sizein = False, sizeout = True, multiple = True
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n>q2;size=2\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, sizein, single match)"
# qsize = True, ssize = False, sizein = True, sizeout = False, multiple = False
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --dbmatched /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, sizein, double match)"
# qsize = True, ssize = False, sizein = True, sizeout = False, multiple = True
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n>q2;size=2\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --dbmatched /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, sizein, sizeout, single match)"
# qsize = True, ssize = False, sizein = True, sizeout = True, multiple = False
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, sizein, sizeout, double match)"
# qsize = True, ssize = False, sizein = True, sizeout = True, multiple = True
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n>q2;size=2\nAAAA\n") \
    --db <(printf ">s1\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, subject size, single match)"
# qsize = True, ssize = True, sizein = False, sizeout = False, multiple = False
# subject size is left untouched
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n") \
    --db <(printf ">s1;size=6\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=6" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, subject size, double match)"
# qsize = True, ssize = True, sizein = False, sizeout = False, multiple = True
# subject size is left untouched
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n>q2;size=2\nAAAA\n") \
    --db <(printf ">s1;size=6\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=6" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, subject size, sizeout, single match)"
# qsize = True, ssize = True, sizein = False, sizeout = True, multiple = False
# subject size is overwritten
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n") \
    --db <(printf ">s1;size=6\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, subject size, sizeout, double match)"
# qsize = True, ssize = True, sizein = False, sizeout = True, multiple = True
# subject size is overwritten
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n>q2;size=2\nAAAA\n") \
    --db <(printf ">s1;size=6\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, subject size, sizein, single match)"
# qsize = True, ssize = True, sizein = True, sizeout = False, multiple = False
# subject size is left untouched
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n") \
    --db <(printf ">s1;size=6\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=6" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, subject size, sizein, double match)"
# qsize = True, ssize = True, sizein = True, sizeout = False, multiple = True
# subject size is left untouched
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n>q2;size=2\nAAAA\n") \
    --db <(printf ">s1;size=6\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=6" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, subject size, sizein, sizeout, single match)"
# qsize = True, ssize = True, sizein = True, sizeout = True, multiple = False
# subject size is overwritten
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n") \
    --db <(printf ">s1;size=6\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 521: usearch_global dbmatched (query size, subject size, sizein, sizeout double match)"
# qsize = True, ssize = True, sizein = True, sizeout = True, multiple = True
# subject size is overwritten
"${VSEARCH}" \
    --usearch_global <(printf ">q1;size=3\nAAAA\n>q2;size=2\nAAAA\n") \
    --db <(printf ">s1;size=6\nAAAA\n") \
    --minseqlength 1 \
    --id 0.50 \
    --quiet \
    --sizein \
    --sizeout \
    --dbmatched /dev/stdout | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#   Why FASTQ quality value above qmax is treated as Fatal error? (issue 522)  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/522

DESCRIPTION="issue 522: Q values up to 41 accepted by default"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 522: Q values up to 41 accepted by default (quiet on stderr)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 522: Q values above 41 rejected by default"
printf "@s\nA\n+\nK\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 522: Q values above 41 rejected by default (quiet on stderr)"
printf "@s\nA\n+\nK\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 522: Q values up to 42 accepted with --fastq_qmax 42"
printf "@s\nA\n+\nK\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_qmax 42 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 522: Q values up to 93 accepted with --fastq_qmax 93"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_qmax 93 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 522: Q values error when fastq_qmax > 93"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_qmax 94 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#     maxseqlength is not supported by makeudb_search command (issue 523)      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/523

## command --makeudb_search accepts option --minseqlength. It seems
## logical that it should also accept option --maxseqlength

## UDB needs to write to a seekable file descriptor (pipes, sockets,
## tty devices are not seekable, regular files and most block devices
## generally are)

## It seems like you can seek and write to /dev/null on macOS at least
#DESCRIPTION="issue 523: makeudb_usearch cannot write to a non-seekable output"
#printf ">s1\nA\n" | \
#    "${VSEARCH}" \
#        --makeudb_usearch /dev/stdin \
#        --quiet \
#        --output /dev/null 2> /dev/null && \
#    failure "${DESCRIPTION}" || \
#        success "${DESCRIPTION}"

DESCRIPTION="issue 523: makeudb_usearch can write to a regular file"
TMP_UDB=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --quiet \
        --output "${TMP_UDB}" 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP_UDB}"
unset TMP_UDB

## filter if length < 32
DESCRIPTION="issue 523: makeudb_usearch discards sequences shorter than 32 nucleotides by default (#1)"
TMP_UDB=$(mktemp)
printf ">s1\n%31s\n" " " | \
    tr " " "A" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --quiet \
        --output "${TMP_UDB}" 2>&1 | \
    grep -q "discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP_UDB}"
unset TMP_UDB

## no filter if length >= 32
DESCRIPTION="issue 523: makeudb_usearch discards sequences shorter than 32 nucleotides by default (#2)"
TMP_UDB=$(mktemp)
printf ">s1\n%32s\n" " " | \
    tr " " "A" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --quiet \
        --output "${TMP_UDB}" 2>&1 | \
    grep -q "discarded" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${TMP_UDB}"
unset TMP_UDB

## accepts the minseqlength option
DESCRIPTION="issue 523: makeudb_usearch accepts the --minseqlength option (#1)"
TMP_UDB=$(mktemp)
printf ">s1\n%10s\n" " " | \
    tr " " "A" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --minseqlength 10 \
        --quiet \
        --output "${TMP_UDB}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP_UDB}"
unset TMP_UDB

## accepts the minseqlength option and uses it
DESCRIPTION="issue 523: makeudb_usearch accepts the --minseqlength option (#2)"
TMP_UDB=$(mktemp)
printf ">s1\n%9s\n" " " | \
    tr " " "A" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --minseqlength 10 \
        --quiet \
        --output "${TMP_UDB}" 2>&1 | \
    grep -q "discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP_UDB}"
unset TMP_UDB

## accepts sequences up to 50,000 nucleotides
DESCRIPTION="issue 523: makeudb_usearch accepts sequences with up to 50,000 nucleotides"
TMP_UDB=$(mktemp)
printf ">s1\n%50000s\n" " " | \
    tr " " "A" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --quiet \
        --output "${TMP_UDB}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP_UDB}"
unset TMP_UDB

DESCRIPTION="issue 523: makeudb_usearch discards sequences longer than 50,000 nucleotides"
TMP_UDB=$(mktemp)
printf ">s1\n%50001s\n" " " | \
    tr " " "A" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --quiet \
        --output "${TMP_UDB}" 2>&1 | \
    grep -q "discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP_UDB}"
unset TMP_UDB

## accepts the maxseqlength option
DESCRIPTION="issue 523: makeudb_usearch accepts the --maxseqlength option (#1)"
TMP_UDB=$(mktemp)
printf ">s1\n%32s\n" " " | \
    tr " " "A" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --maxseqlength 40 \
        --quiet \
        --output "${TMP_UDB}" 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP_UDB}"
unset TMP_UDB

## accepts the maxseqlength option and uses it
DESCRIPTION="issue 523: makeudb_usearch accepts the --maxseqlength option (#2)"
TMP_UDB=$(mktemp)
printf ">s1\n%40s\n" " " | \
    tr " " "A" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --maxseqlength 39 \
        --quiet \
        --output "${TMP_UDB}" 2>&1 | \
    grep -q "discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP_UDB}"
unset TMP_UDB


#******************************************************************************#
#                                                                              #
#                Option to output the reason why merging failed                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/524

# open issue (not covered): request for a per-pair report of the reason why
# --fastq_mergepairs failed to merge a read pair (see also issue 282)



#******************************************************************************#
#                                                                              #
#            Build errors with GCC 13 on Debian 13 (issue 525)                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/525

# no tests required


#******************************************************************************#
#                                                                              #
#      fastq_mergepairs: pair-end merge compared with FLASH (issue 526)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/526

## How can I adjust the parameters to get similar results as FLASH?

# vsearch's merging algorithm is more conservative than flash's by
# design. In vsearch, there are three options you can toggle to relax
# some merging parameters:

# - fastq_minovlen: specify the minimum overlap between the merged
#   reads. The default is 10. Must be at least 5.
# - fastq_maxdiffpct: specify the maximum percentage of non-matching
#   nucleotides allowed in the overlap region. The default value is
#   100.0%.
# - fastq_maxdiffs: specify the maximum number of non-matching
#   nucleotides allowed in the overlap region. That option has a strong
#   influence on the merging success rate. The default value is 10.

# There are other more sophisticated rules in the merging algorithm that
# will discard read pairs with a high fraction of mismatches, but these
# rules are not controlled by user-facing variables. So, it is currently
# not possible for end-users to adjust the vsearch's merging algorithm
# parameters to get similar results as flash.


#******************************************************************************#
#                                                                              #
#  fastq_mergepairs: merging stats should be written to log file (issue 527)   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/527

DESCRIPTION="issue 527: fastq_mergepairs does not write header to stdout"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null 2> /dev/null | \
    grep -q "^vsearch" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 527: fastq_mergepairs does not write stats to stdout"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null 2> /dev/null | \
    grep -q "^Statistics" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 527: fastq_mergepairs writes header to stderr"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null 2>&1 | \
    grep -q "^vsearch" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 527: fastq_mergepairs writes stats to stderr"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null 2>&1 | \
    grep -q "^Statistics" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 527: fastq_mergepairs quiet does not writes header to stderr"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --quiet \
    --fastaout /dev/null 2>&1 | \
    grep -q "^vsearch" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 527: fastq_mergepairs quiet writes stats to stderr"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --quiet \
    --fastaout /dev/null 2>&1 | \
    grep -q "^Statistics" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## -------------------------------------------------- quiet = false, log = true

DESCRIPTION="issue 527: fastq_mergepairs writes header to log file"
TMP=$(mktemp)
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null \
    --log "${TMP}" 2> /dev/null
grep -q "^vsearch" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"

DESCRIPTION="issue 527: fastq_mergepairs writes header to stderr (with log)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null \
    --log /dev/null 2>&1 | \
    grep -q "^vsearch" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 527: fastq_mergepairs writes stats to log file"
TMP=$(mktemp)
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null \
    --log "${TMP}" 2> /dev/null
grep -q "^Statistics" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"

DESCRIPTION="issue 527: fastq_mergepairs writes time and memory to log file"
TMP=$(mktemp)
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null \
    --log "${TMP}" 2> /dev/null
grep -q "memory" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"


## --------------------------------------------------- quiet = true, log = true

DESCRIPTION="issue 527: fastq_mergepairs quiet writes header to log file"
TMP=$(mktemp)
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null \
    --quiet \
    --log "${TMP}" 2> /dev/null
grep -q "^vsearch" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"

DESCRIPTION="issue 527: fastq_mergepairs log quiet does not write header to stderr"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null \
    --quiet \
    --log /dev/null 2>&1 | \
    grep -q "^vsearch" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 527: fastq_mergepairs quiet writes time and memory to log file"
TMP=$(mktemp)
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null \
    --quiet \
    --log "${TMP}" 2> /dev/null
grep -q "memory" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"

DESCRIPTION="issue 527: fastq_mergepairs quiet writes stats to log file"
TMP=$(mktemp)
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastaout /dev/null \
    --quiet \
    --log "${TMP}" 2> /dev/null
grep -q "^Statistics" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"


#******************************************************************************#
#                                                                              #
#                 add a DEBUG compilation option (issue 528)                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/528

# A debugging configuration is now available (no test required)


#******************************************************************************#
#                                                                              #
#       Update log file output for --chimeras_denovo command (issue 529)       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/529

# The log file produced by the older uchime commands reports a block of
# scoring parameters (minh, xn, dn, xa, mindiv, id, maxp). The new
# --chimeras_denovo algorithm does not use most of these parameters, so
# they should no longer be reported in its log file. Only the 'id'
# parameter remains relevant and is still reported.

# the 'id' parameter is still reported in the chimeras_denovo log
DESCRIPTION="issue 529: chimeras_denovo log reports the id parameter"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null \
        --log - 2> /dev/null | \
    grep -Eq "[[:space:]]id$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# minh is a uchime-specific parameter, not reported by chimeras_denovo
DESCRIPTION="issue 529: chimeras_denovo log does not report minh"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null \
        --log - 2> /dev/null | \
    grep -Eq "[[:space:]]minh$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# xn is a uchime-specific parameter, not reported by chimeras_denovo
DESCRIPTION="issue 529: chimeras_denovo log does not report xn"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null \
        --log - 2> /dev/null | \
    grep -Eq "[[:space:]]xn$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# dn is a uchime-specific parameter, not reported by chimeras_denovo
DESCRIPTION="issue 529: chimeras_denovo log does not report dn"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null \
        --log - 2> /dev/null | \
    grep -Eq "[[:space:]]dn$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# xa is a uchime-specific parameter, not reported by chimeras_denovo
DESCRIPTION="issue 529: chimeras_denovo log does not report xa"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null \
        --log - 2> /dev/null | \
    grep -Eq "[[:space:]]xa$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# mindiv is a uchime-specific parameter, not reported by chimeras_denovo
DESCRIPTION="issue 529: chimeras_denovo log does not report mindiv"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null \
        --log - 2> /dev/null | \
    grep -Eq "[[:space:]]mindiv$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# maxp is a uchime-specific parameter, not reported by chimeras_denovo
DESCRIPTION="issue 529: chimeras_denovo log does not report maxp"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null \
        --log - 2> /dev/null | \
    grep -Eq "[[:space:]]maxp$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# contrast (non-vacuity check): the uchime_denovo log still reports minh,
# confirming the grep pattern above does match the parameter when present
DESCRIPTION="issue 529: uchime_denovo log still reports minh (contrast)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --quiet \
        --chimeras /dev/null \
        --log - 2> /dev/null | \
    grep -Eq "[[:space:]]minh$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# contrast (non-vacuity check): the uchime_denovo log still reports maxp
# (an integer-formatted parameter), confirming the grep pattern matches
DESCRIPTION="issue 529: uchime_denovo log still reports maxp (contrast)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --quiet \
        --chimeras /dev/null \
        --log - 2> /dev/null | \
    grep -Eq "[[:space:]]maxp$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#     always report the rightmost match if multiple equivalent occurrences     #
#                 are present in target sequence? (issue 530)                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/530

# tilo: first nucleotide of the target aligned with the query
# tihi: last nucleotide of the target aligned with the query
# (ignoring initial gaps, nucleotide numbering starts from 1)

SEQUENCE="TCAAGATATTTGCTCGGTAA"

# t1	1	20
DESCRIPTION="issue 530: report the rightmost match in target sequence (one match)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQUENCE}") \
    --db <(printf ">t1\n%s\n" "${SEQUENCE}") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk -v MATCH_END=$(( ${#SEQUENCE} * 1 )) '{exit $3 == MATCH_END ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# t1	21	40
DESCRIPTION="issue 530: report the rightmost match in target sequence (two matches)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQUENCE}") \
    --db <(printf ">t1\n%s%s\n" "${SEQUENCE}" "${SEQUENCE}") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk -v MATCH_END=$(( ${#SEQUENCE} * 2 )) '{exit $3 == MATCH_END ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# t1	41	60
DESCRIPTION="issue 530: report the rightmost match in target sequence (three matches)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQUENCE}") \
    --db <(printf ">t1\n%s%s%s\n" "${SEQUENCE}" "${SEQUENCE}" "${SEQUENCE}") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk -v MATCH_END=$(( ${#SEQUENCE} * 3 )) '{exit $3 == MATCH_END ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# t1	61	80
DESCRIPTION="issue 530: report the rightmost match in target sequence (four matches)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQUENCE}") \
    --db <(printf ">t1\n%s%s%s%s\n" "${SEQUENCE}" "${SEQUENCE}" "${SEQUENCE}" "${SEQUENCE}") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk -v MATCH_END=$(( ${#SEQUENCE} * 4 )) '{exit $3 == MATCH_END ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## what about matches on the minus strand? One could expect rightmost
## matches, so leftmost from the point of view of the normal
## strand. In practice, vsearch returns rightmost matches with target
## from the point of view of the normal strand. Maybe the rule is to
## return the first perfect match found during backtracking? Only the
## query is reverse-complemented, the target stays the same. That's
## why the returned match is always the rightmost in the target
## sequence.

REVCOMP="TTACCGAGCAAATATCTTGA"

DESCRIPTION="issue 530: report the rightmost match in revcomp target sequence (one match)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQUENCE}") \
    --db <(printf ">t1\n%s\n" "${REVCOMP}") \
    --minseqlength 1 \
    --id 1.0 \
    --strand both \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk -v MATCH_END=$(( ${#SEQUENCE} * 1 )) '{exit $3 == MATCH_END ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 530: report the rightmost match in revcomp target sequence (two matches)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQUENCE}") \
    --db <(printf ">t1\n%s%s\n" "${REVCOMP}" "${REVCOMP}") \
    --minseqlength 1 \
    --id 1.0 \
    --strand both \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk -v MATCH_END=$(( ${#SEQUENCE} * 2 )) '{exit $3 == MATCH_END ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 530: report the rightmost match in revcomp target sequence (three matches)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQUENCE}") \
    --db <(printf ">t1\n%s%s%s\n" "${REVCOMP}" "${REVCOMP}" "${REVCOMP}") \
    --minseqlength 1 \
    --id 1.0 \
    --strand both \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk -v MATCH_END=$(( ${#SEQUENCE} * 3 )) '{exit $3 == MATCH_END ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 530: report the rightmost match in revcomp target sequence (four matches)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQUENCE}") \
    --db <(printf ">t1\n%s%s%s%s\n" "${REVCOMP}" "${REVCOMP}" "${REVCOMP}" "${REVCOMP}") \
    --minseqlength 1 \
    --id 1.0 \
    --strand both \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk -v MATCH_END=$(( ${#SEQUENCE} * 4 )) '{exit $3 == MATCH_END ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset REVCOMP

# When aligning and backtracking, the code will always prefer to match
# the sequences than opening a gap, given that the scores are
# equal. vsearch starts backtracking at the 3' ends of the sequences,
# and in the examples it will always start by matching the sequences
# at the 3' end, hence our observations so far.

# Counter-example: If the target/database sequence in the example has
# some extra non-matching sequence at the 3' end, the first match is
# chosen. This is because these are global alignments and when a gap
# has to be opened at the 3' end anyway, it would rather extend that
# gap than opening an additional gap in 5' end, because the score
# would be better.

## Weirdly, vsearch produces the correct alignment if the long
## sequence is the query, not if it is a db sequence. I am not sure
## why there is an asymmetry here.

PADDING="CCC"

# t1	1	20
DESCRIPTION="issue 530: extending existing gaps is less costly (3' gap, one match)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s\n" "${SEQUENCE}") \
    --db <(printf ">t1\n%s%s\n" "${SEQUENCE}" "${PADDING}") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk '{exit $3 == 20 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# t1	1	20
DESCRIPTION="issue 530: extending existing gaps is less costly (3' gap, two matches)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s%s%s\n" "${SEQUENCE}" "${SEQUENCE}" "${PADDING}") \
    --db <(printf ">t1\n%s\n" "${SEQUENCE}") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk '{exit $3 == 20 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# t1	1	20
DESCRIPTION="issue 530: extending existing gaps is less costly (3' gap, three matches)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s%s%s%s\n" "${SEQUENCE}" "${SEQUENCE}" \
                              "${SEQUENCE}" "${PADDING}") \
    --db <(printf ">t1\n%s\n" "${SEQUENCE}") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk '{exit $3 == 20 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# t1	1	20
DESCRIPTION="issue 530: extending existing gaps is less costly (3' gap, four matches)"
"${VSEARCH}" \
    --usearch_global <(printf ">q1\n%s%s%s%s%s\n" "${SEQUENCE}" "${SEQUENCE}" \
                              "${SEQUENCE}" "${SEQUENCE}" "${PADDING}") \
    --db <(printf ">t1\n%s\n" "${SEQUENCE}") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --userfields target+tilo+tihi \
    --userout - | \
    awk '{exit $3 == 20 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset SEQUENCE REVCOMP PADDING


#******************************************************************************#
#                                                                              #
#  compilation warning with ar: 'u' modifier ignored since 'D' is the default  #
#                                (issue 531)                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/531

# not testable


#******************************************************************************#
#                                                                              #
#  sintax output is sometimes 4 columns and other times 5 columns (issue 532)  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/532

# same as issue 493


#******************************************************************************#
#                                                                              #
#       fastq_stripleft when the resulting length is null (issue 533)          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/533

## ------------------------------------------------------------------ stripleft

DESCRIPTION="issue 533: fastq_stripleft (strip is null)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 0 \
        --quiet \
        --fastaout - | \
    tr "\n" "_" | \
    grep -qx ">s_AT_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft (strip is shorter than sequence length)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --quiet \
        --fastaout - | \
    tr "\n" "_" | \
    grep -qx ">s_T_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft (strip can be equal to sequence length)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft (strip is equal to sequence length, sequence is discarded)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft (strip can be longer than sequence length)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft (strip is longer than sequence length, sequence is discarded)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- stripright

DESCRIPTION="issue 533: fastq_stripright (strip is null)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripright 0 \
        --quiet \
        --fastaout - | \
    tr "\n" "_" | \
    grep -qx ">s_AT_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripright (strip is shorter than sequence length)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripright 1 \
        --quiet \
        --fastaout - | \
    tr "\n" "_" | \
    grep -qx ">s_A_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripright (strip can be equal to sequence length)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripright 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripright (strip is equal to sequence length, sequence is discarded)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripright 2 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripright (strip can be longer than sequence length)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripright 3 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripright (strip is longer than sequence length, sequence is discarded)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripright 3 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------stripleft + stripright

# two parameters: left, right
# four states: null, shorter, equal, longer (than initial sequence)
# = 16 combinations

DESCRIPTION="issue 533: fastq_stripleft + right (both are null)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 0 \
        --fastq_stripright 0 \
        --quiet \
        --fastaout - | \
    tr "\n" "_" | \
    grep -qx ">s_AT_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is null, right is shorter)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 0 \
        --fastq_stripright 1 \
        --quiet \
        --fastaout - | \
    tr "\n" "_" | \
    grep -qx ">s_A_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is null, right is equal) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 0 \
        --fastq_stripright 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is null, right is equal) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 0 \
        --fastq_stripright 2 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is null, right is longer) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 0 \
        --fastq_stripright 3 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is null, right is longer) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 0 \
        --fastq_stripright 3 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is shorter, right is null)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --fastq_stripright 0 \
        --quiet \
        --fastaout - | \
    tr "\n" "_" | \
    grep -qx ">s_T_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is shorter, right is shorter) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --fastq_stripright 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is shorter, right is shorter) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --fastq_stripright 1 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is shorter, right is equal) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --fastq_stripright 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is shorter, right is equal) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --fastq_stripright 2 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is shorter, right is longer) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --fastq_stripright 3 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is shorter, right is longer) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --fastq_stripright 3 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is equal, right is null) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --fastq_stripright 0 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is equal, right is null) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --fastq_stripright 0 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is equal, right is shorter) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --fastq_stripright 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is equal, right is shorter) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --fastq_stripright 1 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is equal, right is equal) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --fastq_stripright 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is equal, right is equal) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --fastq_stripright 2 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is equal, right is longer) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --fastq_stripright 3 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is equal, right is longer) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --fastq_stripright 3 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is longer, right is null) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --fastq_stripright 0 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is longer, right is null) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --fastq_stripright 0 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is longer, right is shorter) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --fastq_stripright 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is longer, right is shorter) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --fastq_stripright 1 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is longer, right is equal) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --fastq_stripright 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is longer, right is equal) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --fastq_stripright 2 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is longer, right is longer) is OK"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --fastq_stripright 3 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (left is longer, right is longer) discard sequence"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --fastq_stripright 3 \
        --quiet \
        --fastaout - | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 533: fastq_stripleft + right (discarded sequences are reported)"
printf ">s\nAT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 3 \
        --fastq_stripright 3 \
        --fastaout /dev/null 2>&1 | \
    grep -Eq "1 sequences{0,1} discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#     forward read trimming and filtering (Minardi et al. 2021) (issue 534)    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/534

# Lasse Krøger Eliassen asked about the correct way to implement
# forward read trimming and filtering, as described in Minardi et
# al. 2021:
# https://onlinelibrary.wiley.com/doi/10.1111/1755-0998.13509

# "Forward reads were trimmed to 200 bp in length approximately
# corresponding to the point at which the lower quartile fell
# below 20. Low quality reads were removed when estimated errors were
# greater than two and truncated if quality scores fell below
# two."

DESCRIPTION="issue 534: fastx_filter accepts short reads"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_A_+_I_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- fastq_trunclen
DESCRIPTION="issue 534: fastq_trunclen trims reads longer than n"
printf "@s1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_trunclen 1 \
        --quiet \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_A_+_I_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: fastq_trunclen does not trim reads equal to n"
printf "@s1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_trunclen 2 \
        --quiet \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_AA_+_II_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: fastq_trunclen discards reads shorter than n"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_trunclen 2 \
        --quiet \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------- fastq_trunclen_keep
DESCRIPTION="issue 534: fastq_trunclen_keep trims reads longer than n"
printf "@s1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_trunclen_keep 1 \
        --quiet \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_A_+_I_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: fastq_trunclen_keep does not trim reads equal to n"
printf "@s1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_trunclen_keep 2 \
        --quiet \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_AA_+_II_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: fastq_trunclen_keep keeps reads shorter than n"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_trunclen_keep 2 \
        --quiet \
        --fastqout - | \
    tr "\n" "_" | \
        grep -qx "@s1_A_+_I_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fastq_maxns
DESCRIPTION="issue 534: maxns 0 keeps reads without Ns"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_maxns 0 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_A_+_I_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: maxns 0 discards reads with Ns"
printf "@s1\nN\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_maxns 0 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------------------------------------------------------------- fastq_maxee
# quality symbol '!' corresponds to an error probability of 1.0
# expected error (EE) is the sum of all error probabilities
DESCRIPTION="issue 534: maxee 1.0 keeps reads with an EE equal or lesser than 1.0"
printf '@s1\nA\n+\n!\n' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 1.0 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx '@s1_A_+_!_' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: maxee 0.9 discards reads with an EE greater than 0.9"
printf '@s1\nA\n+\n!\n' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 0.9 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 534: maxee 2.0 keeps reads with an EE equal or lesser than 2.0"
printf '@s1\nAA\n+\n!!\n' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 2.0 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx '@s1_AA_+_!!_' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: maxee 1.9 discards reads with an EE greater than 1.9"
printf '@s1\nAA\n+\n!!\n' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 1.9 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------ fastq_truncqual
# truncate sequences starting from the first base with the specified
# base quality score value or lower
DESCRIPTION="issue 534: truncqual does not truncate reads without Q =< n"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 39 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_A_+_I_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: truncqual truncates reads with Q =< n"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 40 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 534: truncqual truncates reads at the first base with Q =< n (last position)"
printf "@s1\nACG\n+\nJJI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 40 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_AC_+_JJ_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: truncqual truncates reads at the first base with Q =< n (middle position)"
printf "@s1\nACG\n+\nJIJ\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 40 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_A_+_J_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: truncqual truncates reads at the first base with Q =< n (first position)"
printf "@s1\nACG\n+\nIJJ\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 40 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# ------------------------------------- length filtering is done after trimming

# effects:
# no qual, no len
# qual, no len
# no qual, len
# qual, len

DESCRIPTION="issue 534: length filtering is done after quality trimming (no qual, no len)"
printf "@s1\nACG\n+\nJJJ\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 40 \
        --fastq_trunclen 3 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_ACG_+_JJJ_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: length filtering is done after quality trimming (no qual, len)"
printf "@s1\nACG\n+\nJJJ\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 40 \
        --fastq_trunclen 2 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_AC_+_JJ_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: length filtering is done after quality trimming (qual, no len)"
printf "@s1\nACG\n+\nJJI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 40 \
        --fastq_trunclen 2 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_AC_+_JJ_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 534: length filtering is done after quality trimming (qual, len)"
printf "@s1\nACG\n+\nJIJ\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 40 \
        --fastq_trunclen 1 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx "@s1_A_+_J_" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# initial length is 3, so trunclen 2 should pass, but length is 1 after truncqual
DESCRIPTION="issue 534: length filtering is done after quality trimming (qual > len)"
printf "@s1\nACG\n+\nJIJ\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastq_truncqual 40 \
        --fastq_trunclen 2 \
        --fastqout - | \
    tr "\n" "_" | \
    grep -qx ".*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#         control of 2 separate randseed events in sintax (issue 535)          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/535

## WIP


#******************************************************************************#
#                                                                              #
#               from fasta files to an OTU table (issue 536)                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/536

# check the correctness of OTU tables created by --otutabout

# The manual says:

# Output an OTU table in the classic tab-separated plain text format
# as a matrix containing the abundances of the OTUs in the different
# samples. The first line will start with the string '#OTU ID' and is
# followed by a tab-separated list of all sample identifiers. The
# following lines, one for each OTU, starts with the OTU identifier
# and is followed by a tab-separated list of abundances for that OTU
# in each sample, in the order given on the first line. The OTU and
# sample identifiers are extracted from the FASTA headers of the
# sequences.  The OTUs are represented by the cluster centroids. An
# extra column is added to the right of the table if taxonomy
# information is available for at least one of the OTUs. This column
# will be labelled 'taxonomy' and each row will then contain the
# taxonomy information extracted for that OTU. See the --biomout
# option for further details.

# example:

# #OTU ID	sample1	sample2
# s1	1	1
# s2	0	1
# s3	1	0

# ---------------------------------------------------------------- empty sample

# empty query input produces an OTU table with only a header line (#OTU ID)
DESCRIPTION="issue 536: otutabout accepts empty query input and produces a table"
printf "" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    grep -qx "#OTU ID" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# --------------------------------------------------------------- single sample
# number of columns
DESCRIPTION="issue 536: otutabout accepts a single sample (2-column tsv table)"
printf ">s1;sample=sample1\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'END {exit NF == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# number of lines
DESCRIPTION="issue 536: otutabout accepts a single sample (2-line tsv table)"
printf ">s1;sample=sample1\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sample name
DESCRIPTION="issue 536: otutabout accepts a single sample (sample name)"
printf ">s1;sample=sample1\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" '{exit $2 == "sample1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# cluster name
DESCRIPTION="issue 536: otutabout accepts a single sample (cluster name)"
printf ">s1;sample=sample1\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 2 {exit $1 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# number of reads
DESCRIPTION="issue 536: otutabout accepts a single sample (number of reads)"
printf ">s1;sample=sample1\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 2 {exit $2 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# number of reads (sizein)
DESCRIPTION="issue 536: otutabout accepts a single sample (number of reads with sizein)"
printf ">s1;sample=sample1;size=2\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --sizein \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 2 {exit $2 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# no query-db match? equivalent to an empty query file
# (queries that are not in db are ignored)
DESCRIPTION="issue 536: otutabout accepts a single sample (no match with db sequences)"
printf ">s1;sample=sample1\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s2\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    grep -qw "#OTU ID" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# if input file is not dereplicated, duplicated queries are merged
# #OTU ID	sample1
# s1	2
DESCRIPTION="issue 536: otutabout merges duplicated queries"
printf ">s1;sample=sample1\nAA\n>s1;sample=sample1\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 2 {exit $2 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# otutabout accepts empty sample identifiers
DESCRIPTION="issue 536: otutabout accepts empty sample identifiers"
printf ">s1;sample=\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 1 {exit $2 == "" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# mix situation? technically not a single-sample situation anymore
# #OTU ID		sample1
# s1	1	1
DESCRIPTION="issue 536: otutabout accepts a mix of empty and non-empty sample identifiers"
printf ">s1;sample=\nAA\n>s1;sample=sample1\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 1 {exit ($2 == "" && $3 == "sample1") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note that the empty sample name is sorted first


# ----------------------------------------------------------------- two samples

# two samples:
# #OTU ID	sample1	sample2
# s1	1	1
DESCRIPTION="issue 536: otutabout accepts two samples (common sequence)"
(
    printf ">s1;sample=sample1\nAA\n"
    printf ">s1;sample=sample2\nAA\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 2 {exit ($1 == "s1" && $2 == 1 && $3 == 1) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# two samples, exclusive sequences:
# #OTU ID	sample1	sample2
# s1	1	0
# s2	0	1
DESCRIPTION="issue 536: otutabout accepts two samples (exclusive sequences, three lines)"
(
    printf ">s1;sample=sample1\nAA\n"
    printf ">s2;sample=sample2\nGG\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n>s2\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 536: otutabout accepts two samples (exclusive sequences, absence is zero)"
(
    printf ">s1;sample=sample1\nAA\n"
    printf ">s2;sample=sample2\nGG\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n>s2\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" '$1 == "s1" {exit ($3 == 0) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 536: otutabout accepts two samples (exclusive sequences, presence >= 1)"
(
    printf ">s1;sample=sample1\nAA\n"
    printf ">s2;sample=sample2\nGG\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n>s2\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" '$1 == "s1" {exit ($2 == 1) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 536: otutabout accepts two samples (exclusive sequences, first cluster)"
(
    printf ">s1;sample=sample1\nAA\n"
    printf ">s2;sample=sample2\nGG\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n>s2\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" '$1 == "s1" {exit ($2 == 1 && $3 == 0) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 536: otutabout accepts two samples (exclusive sequences, second cluster)"
(
    printf ">s1;sample=sample1\nAA\n"
    printf ">s2;sample=sample2\nGG\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n>s2\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" '$1 == "s2" {exit ($2 == 0 && $3 == 1) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 536: otutabout accepts two samples (common and exclusive sequences, four lines)"
(
    printf ">s1;sample=sample1\nAA\n>s3;sample=sample1\nCC\n"
    printf ">s1;sample=sample2\nAA\n>s2;sample=sample2\nGG\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n>s2\nGG\n>s3\nCC\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'END {exit NR == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 536: otutabout contains the expected number of reads (same as input)"
(
    printf ">s1;sample=sample1\nAA\n>s3;sample=sample1\nCC\n"
    printf ">s1;sample=sample2\nAA\n>s2;sample=sample2\nGG\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n>s2\nGG\n>s3\nCC\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk 'NR > 1 {for (i=2 ; i<=NF ; i++) {sum += $i}} \
         END {exit sum == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sample names are alpha sorted (input in normal order)
DESCRIPTION="issue 536: otutabout sample names are alpha sorted (two samples, normal input)"
(
    printf ">s1;sample=sample1\nAA\n"
    printf ">s1;sample=sample2\nAA\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 1 {exit ($2 == "sample1" && \
                                $3 == "sample2") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sample names are alpha sorted (input in reverse-order)
DESCRIPTION="issue 536: otutabout sample names are alpha sorted (two samples, reversed input)"
(
    printf ">s1;sample=sample2\nAA\n"
    printf ">s1;sample=sample1\nAA\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 1 {exit ($2 == "sample1" && \
                                $3 == "sample2") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sample names are alpha sorted (input in reverse-order)
DESCRIPTION="issue 536: otutabout sample names are alpha sorted (three samples, reversed input)"
(
    printf ">s1;sample=sample3\nAA\n"
    printf ">s1;sample=sample2\nAA\n"
    printf ">s1;sample=sample1\nAA\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 1 {exit ($2 == "sample1" && \
                                $3 == "sample2" && \
                                $4 == "sample3") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 536: otutabout cluster names are alpha sorted (normal input order)"
(
    printf ">s1;sample=sample1\nAA\n>s3;sample=sample1\nCC\n"
    printf ">s1;sample=sample2\nAA\n>s2;sample=sample2\nGG\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n>s2\nGG\n>s3\nCC\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    cut -f 1 | \
    tail -n +2 | \
    tr "\n" "@" | \
    grep -qx "s1@s2@s3@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 536: otutabout cluster names are alpha sorted (reverse input order)"
(
    printf ">s1;sample=sample1\nAA\n>s3;sample=sample1\nCC\n"
    printf ">s1;sample=sample2\nAA\n>s2;sample=sample2\nGG\n"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s3\nCC\n>s2\nGG\n>s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    cut -f 1 | \
    tail -n +2 | \
    tr "\n" "@" | \
    grep -qx "s1@s2@s3@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# ---------------------------------------------- no sample annotation (diagonal)

# In the absence of a ';sample=' (or ';barcodelabel=') annotation in
# the query header, the sample name is taken from the query header
# itself (the leading run of A-Za-z0-9_ characters). Each query thus
# becomes its own sample.
DESCRIPTION="issue 536: otutabout without sample annotation uses the query name as the sample name"
printf ">s1\nAA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 1 {exit $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# when each query (its own sample) matches a distinct OTU, the table is
# a diagonal matrix:
# #OTU ID	s1	s2	s3
# s1	1	0	0
# s2	0	1	0
# s3	0	0	1
DESCRIPTION="issue 536: otutabout without sample annotation yields a diagonal matrix"
printf ">s1\nAA\n>s2\nGG\n>s3\nCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s1\nAA\n>s2\nGG\n>s3\nCC\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    tr "\t" "@" | \
    tr "\n" "#" | \
    grep -qx "#OTU ID@s1@s2@s3#s1@1@0@0#s2@0@1@0#s3@0@0@1#" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --------------------------------------- OTUs are alpha sorted, not by abundance

# The OTU rows are sorted alphabetically by OTU name (std::set), not by
# decreasing abundance. Here OTU 'aaa' is less abundant than OTU 'bbb'
# but still appears on the first data row because of its name.
# #OTU ID	s
# aaa	1
# bbb	5
DESCRIPTION="issue 536: otutabout sorts OTUs alphabetically, not by decreasing abundance"
printf ">q1;sample=s;size=1\nAA\n>q2;sample=s;size=5\nGG\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">aaa\nAA\n>bbb\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --sizein \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 2 {exit ($1 == "aaa" && $2 == 1) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# the most abundant OTU is not promoted to the first data row
DESCRIPTION="issue 536: otutabout does not place the most abundant OTU first"
printf ">q1;sample=s;size=1\nAA\n>q2;sample=s;size=5\nGG\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">aaa\nAA\n>bbb\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --sizein \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'END {exit ($1 == "bbb" && $2 == 5) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ----------------------------------------------- combine --sample and --relabel

# --sample writes a ';sample=' annotation and --relabel renames the
# sequences; when both are used upstream (here with --fastx_filter),
# otutabout reads the sample name from the annotation and is unaffected
# by the relabeling. The two samples 'alpha' and 'beta' become the
# table columns:
# #OTU ID	alpha	beta
# aaa	1	1
# ggg	1	0
DESCRIPTION="issue 536: otutabout works with both --sample and --relabel (sample columns)"
(
    printf ">x\nAA\n>y\nGG\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --relabel read \
            --sample alpha \
            --quiet \
            --fastaout -
    printf ">x\nAA\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --relabel read \
            --sample beta \
            --quiet \
            --fastaout -
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">aaa\nAA\n>ggg\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" 'NR == 1 {exit ($2 == "alpha" && $3 == "beta") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 536: otutabout works with both --sample and --relabel (abundances)"
(
    printf ">x\nAA\n>y\nGG\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --relabel read \
            --sample alpha \
            --quiet \
            --fastaout -
    printf ">x\nAA\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --relabel read \
            --sample beta \
            --quiet \
            --fastaout -
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">aaa\nAA\n>ggg\nGG\n") \
        --minseqlength 2 \
        --id 1.0 \
        --qmask none \
        --dbmask none \
        --quiet \
        --otutabout - | \
    awk -F "\t" '$1 == "ggg" {exit ($2 == 1 && $3 == 0) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#     --uchime_denovo takes abundance information into account (issue 537)     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/537

DESCRIPTION="issue 537: uchime_denovo takes abundance information into account"
#        1...5...10...15...20...25...30...35
A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"
B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
A_END=$(rev <<< ${A_START})
B_END=$(rev <<< ${B_START})

(
    printf ">parentA;size=50\n%s\n" "${A_START}${A_END}"
    printf ">parentB;size=49\n%s\n" "${B_START}${B_END}"
    printf ">chimeraAB;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --uchime_denovo - \
        --uchimeout /dev/null 2>&1 | \
    grep -q "99 (.*) non-chimeras" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#    how to detect matches containing many ambiguous symbols? (issue 538)      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/538

# Qry  1 + nnnnnnnnnnnnnnnnnnnnnGG 23
#          +++++++++++++++++++++||
# Tgt  1 + GGCATGAACGATACCGATTAAGG 23

# 23 cols, 23 ids (100.0%), 0 gaps (0.0%)

# How to avoid this kind of matches?
# - masking has no effect,
# - minwordmatches (k-mer pre-filtering) has no effect

# When aligning sequences, identical symbols will receive a positive
# match score (default +2). Aligning a pair of symbols where at least
# one of them is an ambiguous symbol (BDHKMNRSVWY) will always result
# in a score of zero.

# So the raw score should be low when compared to the alignment length
# for N-rich queries.

DESCRIPTION="issue 538: usearch_global use raw score to detect N-rich matches"
${VSEARCH} \
    --usearch_global <(printf ">query1\nNNNNNNNNNNNNNNNNNNNNNGG\n") \
    --db <(printf ">target1\nGGCATGAACGATACCGATTAAGG\n") \
    --quiet \
    --minseqlength 23 \
    --id 1.0 \
    --userfields query+alnlen+ids+raw \
    --userout - | \
    awk 'BEGIN {matches = 23 ; score = 2 + 2}
         {exit ($3 == matches && $4 == score) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# query1	23	23	4

# Here the alignment length is 23, the number of matches is 23, and
# yet the raw score is only 2, indicating an alignment with 21
# ambiguous symbols.


#******************************************************************************#
#                                                                              #
#                   more compile-time checks (issue 539)                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/539

## not testable


#******************************************************************************#
#                                                                              #
#               src/derepsmallmem.cc: fix minor typo (issue 540)               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/540

## tested in derep_smallmem.sh


#******************************************************************************#
#                                                                              #
#           Issue encountered when using vsearch --usearch_global              #
#      to generate OTU frequency table src/derepsmallmem.cc (issue 541)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/541

## not enough information


#******************************************************************************#
#                                                                              #
#                     clean-up stale branches (issue 542)                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/542

## not testable


#******************************************************************************#
#                                                                              #
#          --makeudb_usearch truncates fasta headers (issue 543)               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/543

## sequence headers are truncated by default:
DESCRIPTION="issue 543: search_exact truncates headers by default (normal header)"
${VSEARCH} \
    --search_exact <(printf ">q1\nA\n") \
    --db <(printf ">t1\nA\n") \
    --quiet \
    --blast6out - | \
    awk 'BEGIN {FS = "\t"} {exit $2 == "t1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 543: search_exact truncates headers by default (normal header, --notrunclabels)"
${VSEARCH} \
    --search_exact <(printf ">q1\nA\n") \
    --db <(printf ">t1\nA\n") \
    --notrunclabels \
    --quiet \
    --blast6out - | \
    awk 'BEGIN {FS = "\t"} {exit $2 == "t1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 543: search_exact truncates headers by default (truncable header)"
${VSEARCH} \
    --search_exact <(printf ">q1\nA\n") \
    --db <(printf ">t1 extra\nA\n") \
    --quiet \
    --blast6out - | \
    awk 'BEGIN {FS = "\t"} {exit $2 == "t1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 543: search_exact truncates headers by default (truncable header, --notrunclabels)"
${VSEARCH} \
    --search_exact <(printf ">q1\nA\n") \
    --db <(printf ">t1 extra\nA\n") \
    --notrunclabels \
    --quiet \
    --blast6out - | \
    awk 'BEGIN {FS = "\t"} {exit $2 == "t1 extra" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## sequence headers are truncated by default when building UDB:
DESCRIPTION="issue 543: makeudb_usearch truncates headers by default (normal header)"
TMP=$(mktemp)
${VSEARCH} \
    --makeudb_usearch <(printf ">t1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --output "${TMP}"

${VSEARCH} \
    --udb2fasta "${TMP}" \
    --quiet \
    --output - | \
    grep -qx ">t1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"
unset TMP

DESCRIPTION="issue 543: makeudb_usearch truncates headers by default (normal header, --notrunclabels)"
TMP=$(mktemp)
${VSEARCH} \
    --makeudb_usearch <(printf ">t1\nA\n") \
    --notrunclabels \
    --minseqlength 1 \
    --quiet \
    --output "${TMP}"

${VSEARCH} \
    --udb2fasta "${TMP}" \
    --quiet \
    --output - | \
    grep -qx ">t1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"
unset TMP

DESCRIPTION="issue 543: makeudb_usearch truncates headers by default (truncable header)"
TMP=$(mktemp)
${VSEARCH} \
    --makeudb_usearch <(printf ">t1 extra\nA\n") \
    --minseqlength 1 \
    --quiet \
    --output "${TMP}"

${VSEARCH} \
    --udb2fasta "${TMP}" \
    --quiet \
    --output - | \
    grep -qx ">t1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"
unset TMP

DESCRIPTION="issue 543: makeudb_usearch truncates headers by default (truncable header, --notrunclabels)"
TMP=$(mktemp)
${VSEARCH} \
    --makeudb_usearch <(printf ">t1 extra\nA\n") \
    --notrunclabels \
    --minseqlength 1 \
    --quiet \
    --output "${TMP}"

${VSEARCH} \
    --udb2fasta "${TMP}" \
    --quiet \
    --output - | \
    grep -qx ">t1 extra" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"
unset TMP


#******************************************************************************#
#                                                                              #
#      maxseqlength is not supported by uchime_denovo command (issue 544)      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/544

## v2.26: --uchime_denovo supports option --maxseqlength

DESCRIPTION="issue 544: uchime_denovo supports option --maxseqlength"
printf ">s1\nAAA\n" | \
    ${VSEARCH} \
    --uchime_denovo - \
    --quiet \
    --maxseqlength 3 \
    --uchimeout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 544: uchime_denovo maxseqlength keeps sequences <= n"
printf ">s1\nAAA\n" | \
    ${VSEARCH} \
    --uchime_denovo - \
    --quiet \
    --maxseqlength 3 \
    --uchimeout - | \
    grep -q "s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 544: uchime_denovo maxseqlength excludes sequences > n"
printf ">s1\nAAAA\n" | \
    ${VSEARCH} \
    --uchime_denovo - \
    --quiet \
    --maxseqlength 3 \
    --uchimeout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#             vsearch --usearch_global not showing "full alignment"            #
#                  instead only the segment pair (issue 545)                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/545

# Like usearch, vsearch returns semi-global pairwise alignments,
# ignoring terminal gaps

# The alignment of:

# primer query:   ACAGTGACATGGGGACGTAT
# reference:       CAGTGACATGGGGACGTAT...

# is:

# Qry    2 + CAGTGACATGGGGACGTAT 20
#            |||||||||||||||||||
# Tgt    1 + CAGTGACATGGGGACGTAT 19

# and not:

# Qry    1 + ACAGTGACATGGGGACGTAT 20
#             |||||||||||||||||||
# Tgt    1 + -CAGTGACATGGGGACGTAT 19


# alignment starts at position 2 for the query (ignore 5' gap)
DESCRIPTION="issue 545: usearch_global produces semi-global alignments"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACAGTGACATGGGGACGTAT\n") \
    --db <(printf ">t1\nCAGTGACATGGGGACGTAT\n") \
    --minseqlength 1 \
    --quiet \
    --id 0.8 \
    --alnout - | \
    grep -Eq "Qry +2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Once a match is selected, iddef has no effect on the alignment
DESCRIPTION="issue 545: usearch_global iddef has no effect on alignments (id 0)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACAGTGACATGGGGACGTAT\n") \
    --db <(printf ">t1\nCAGTGACATGGGGACGTAT\n") \
    --minseqlength 1 \
    --quiet \
    --iddef 0 \
    --id 0.8 \
    --alnout - | \
    grep -Eq "Qry +2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 545: usearch_global iddef has no effect on alignments (id 1)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACAGTGACATGGGGACGTAT\n") \
    --db <(printf ">t1\nCAGTGACATGGGGACGTAT\n") \
    --minseqlength 1 \
    --quiet \
    --iddef 1 \
    --id 0.8 \
    --alnout - | \
    grep -Eq "Qry +2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 545: usearch_global iddef has no effect on alignments (id 2)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACAGTGACATGGGGACGTAT\n") \
    --db <(printf ">t1\nCAGTGACATGGGGACGTAT\n") \
    --minseqlength 1 \
    --quiet \
    --iddef 2 \
    --id 0.8 \
    --alnout - | \
    grep -Eq "Qry +2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 545: usearch_global iddef has no effect on alignments (id 3)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACAGTGACATGGGGACGTAT\n") \
    --db <(printf ">t1\nCAGTGACATGGGGACGTAT\n") \
    --minseqlength 1 \
    --quiet \
    --iddef 3 \
    --id 0.8 \
    --alnout - | \
    grep -Eq "Qry +2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 545: usearch_global iddef has no effect on alignments (id 4)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACAGTGACATGGGGACGTAT\n") \
    --db <(printf ">t1\nCAGTGACATGGGGACGTAT\n") \
    --minseqlength 1 \
    --quiet \
    --iddef 4 \
    --id 0.8 \
    --alnout - | \
    grep -Eq "Qry +2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#      vsearch --top_hits_only --maxaccepts 1 returns sometimes 2 values       #
#                               (issue 546)                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/546

## The goal is to obtain only one hit per query or no hit, never more.

# simplest case: default parameters, single hit: expect match q1 t1
DESCRIPTION="issue 546: default parameters, search returns single hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --userfields query+target \
    --userout - | \
    tr "\t" " " | \
    grep -qx "q1 t1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------- output_no_hits

# default parameters, no hit
DESCRIPTION="issue 546: default parameters, search returns no hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nCAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --userfields query+target \
    --userout - | \
    grep -qx "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# default parameters, output_no_hits, no hit
DESCRIPTION="issue 546: output_no_hits returns query with no hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nCAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --output_no_hits \
    --userfields query+target \
    --userout - | \
    tr "\t" " " | \
    grep -qx "q1 \*" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# default parameters, output_no_hits, hit
DESCRIPTION="issue 546: output_no_hits returns query with hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --output_no_hits \
    --userfields query+target \
    --userout - | \
    tr "\t" " " | \
    grep -qx "q1 t1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# default parameters, output_no_hits, hit and no hit
DESCRIPTION="issue 546: output_no_hits returns all queries (hit and no hit)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n>q2\nCAG\n") \
    --db <(printf ">t1\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --output_no_hits \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ maxaccept

# maxaccepts controls the number of tested targets

# two hits but maxaccepts is 1 by default: return only one hit
DESCRIPTION="issue 546: two identical targets, maxaccepts=1, report 1 hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n>t2\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# default parameters, two hits, maxaccepts 2
DESCRIPTION="issue 546: two identical targets, maxaccepts=2, report 2 hits"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n>t2\nAAG\n") \
    --minseqlength 3 \
    --maxaccepts 2 \
    --id 1.00 \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# default parameters, two hits, maxaccepts 0
DESCRIPTION="issue 546: two identical targets, maxaccepts=0, report unlimited hits"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n>t2\nAAG\n") \
    --minseqlength 3 \
    --maxaccepts 0 \
    --id 1.00 \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- maxhits

# maxhits controls the overall number of hits reported

# one hit, maxhits=1
DESCRIPTION="issue 546: one target, maxhits=1, reports one hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --maxaccepts 0 \
    --maxhits 1 \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# two hits, maxhits=1
DESCRIPTION="issue 546: two identical targets, maxhits=1, report one hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n>t2\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --maxaccepts 0 \
    --maxhits 1 \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# two hits, maxhits=2
DESCRIPTION="issue 546: two identical targets, maxhits=2, report two hits"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n>t2\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --maxaccepts 0 \
    --maxhits 2 \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# two hits, maxhits=0
DESCRIPTION="issue 546: two identical targets, maxhits=0, report unlimited hits"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n>t2\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --quiet \
    --maxaccepts 0 \
    --maxhits 0 \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- strand

# strand plus or both:
# single hit,
# double hit,
# with or without --maxaccepts limitation
# with or without --maxhits limitation

# all other options use default parameters
DESCRIPTION="issue 546: strand plus: hit only on the normal strand (report one hit)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --strand plus \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 546: strand plus: hits on both strands (report one hit)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACGT\n") \
    --db <(printf ">t1\nACGT\n") \
    --minseqlength 3 \
    --id 1.00 \
    --strand plus \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 546: strand both: hit on the normal strand (report one hit)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n") \
    --minseqlength 3 \
    --id 1.00 \
    --strand both \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# maxaccepts = 1 by default, it has no effect on the number of hits reported
DESCRIPTION="issue 546: strand both: hits on both strands (report two hits)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACGT\n") \
    --db <(printf ">t1\nACGT\n") \
    --minseqlength 3 \
    --id 1.00 \
    --strand both \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# only report hits to the first target
DESCRIPTION="issue 546: strand both, maxaccepts controls the number of tested targets"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACGT\n") \
    --db <(printf ">t1\nACGT\n>t2\nACGT\n") \
    --minseqlength 3 \
    --id 1.00 \
    --strand both \
    --maxaccepts 1 \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# If a query matches both strands of a target, use maxhits to report
# only one hit
DESCRIPTION="issue 546: strand both, maxhits controls the overall number of reported hits"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACGT\n") \
    --db <(printf ">t1\nACGT\n") \
    --minseqlength 3 \
    --id 1.00 \
    --strand both \
    --maxhits 1 \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- top_hits_only

DESCRIPTION="issue 546: default parameters, report all hits"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n>t2\nATG\n") \
    --minseqlength 3 \
    --id 0.50 \
    --maxaccepts 0 \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 546: top_hits_only, report best hit"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n>t2\nATG\n") \
    --minseqlength 3 \
    --id 0.50 \
    --maxaccepts 0 \
    --top_hits_only \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 546: top_hits_only, report best hits"
${VSEARCH} \
    --usearch_global <(printf ">q1\nAAG\n") \
    --db <(printf ">t1\nAAG\n>t2\nAAG\n") \
    --minseqlength 3 \
    --id 0.50 \
    --maxaccepts 0 \
    --top_hits_only \
    --quiet \
    --userfields query+target \
    --userout - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                Issue related to usearch_global match (issue 547)             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/547

# pre-sorting based on kmer profiles and --maxaccepts 1 (default) can
# sometimes lead to the selection of a match with a sequence of lesser
# similarity, but longer (so more kmers in common with the
# query). I've been trying to create a toy-example demonstrating
# that. So far, I've managed to create a 105 bp sequence containing at
# least one copy of all possible 3-mers. I can derive from that
# sequence target 1 (one mismatch) and target 2 (two mismatches and
# some extra terminal nucleotides selected to make target 2's kmer
# profile the best possible match for our query).

# After a couple hours of work, I am still confused about the way kmer
# profiles are computed. I need confirmation from Torbjørn. In my own
# test script, t2 has a kmer profile score of 34. It should be ranked
# lower than t1's score of 38!?

# t1   AGATAGGGACGTGTACCAATCAGCGTTGTTCTGCCTCGTGAATCCGAACATAGGCACTTATTTCGAATCCAGGATAAGGCTAGATGCGCCCTGGGTCCCGGAGTA
#      ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| |||||||||||||||||||||||||||||||||||||
# Q    AGATAGGGACGTGTACCAATCAGCGTTGTTCTGCCTCGTGAATCCGAACATAGGCACTTATTTCGAAACCAGGATAAGGCTAGATGCGCCCTGGGTCCCGGAGTA
#      ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| |||||||||||||| ||||||||||||||||||||||
# t2 AAAGATAGGGACGTGTACCAATCAGCGTTGTTCTGCCTCGTGAATCCGAACATAGGCACTTATTTCGAATCCAGGATAAGGCTACATGCGCCCTGGGTCCCGGAGTAG

Q="AGATAGGGACGTGTACCAATCAGCGTTGTTCTGCCTCGTGAATCCGAACATAGGCACTTATTTCGAAACCAGGATAAGGCTAGATGCGCCCTGGGTCCCGGAGTA"
t1="AGATAGGGACGTGTACCAATCAGCGTTGTTCTGCCTCGTGAATCCGAACATAGGCACTTATTTCGAATCCAGGATAAGGCTAGATGCGCCCTGGGTCCCGGAGTA"
t2="AAAGATAGGGACGTGTACCAATCAGCGTTGTTCTGCCTCGTGAATCCGAACATAGGCACTTATTTCGAATCCAGGATAAGGCTACATGCGCCCTGGGTCCCGGAGTAG"

DESCRIPTION="issue 547: kmer profile filtering can favor longer sequences #1"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${Q}") \
    --db <(printf ">t1\n%s\n>t2\n%s\n" "${t1}" "${t2}") \
    --wordlength 3 \
    --id 0.9 \
    --quiet \
    --userfields query+target+id \
    --userout - | \
    awk '{exit $2 == "t2" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 547: kmer profile filtering can favor longer sequences (fix with maxseqlength)"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${Q}") \
    --db <(printf ">t1\n%s\n>t2\n%s\n" "${t1}" "${t2}") \
    --wordlength 3 \
    --id 0.9 \
    --maxseqlength "${#t1}" \
    --quiet \
    --userfields query+target+id \
    --userout - 2> /dev/null | \
    awk '{exit $2 == "t1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 547: kmer profile filtering can favor longer sequences (fix with maxaccepts)"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${Q}") \
    --db <(printf ">t1\n%s\n>t2\n%s\n" "${t1}" "${t2}") \
    --wordlength 3 \
    --id 0.9 \
    --maxaccepts 2 \
    --quiet \
    --userfields query+target+id \
    --userout - | \
    awk '{exit $2 == "t1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## de Bruijn sequences (shortest possible sequences containing all
## possible 3-mers, repeated only once). Here q1 and t2 are different
## 66-nt long de Bruijn sequences containing the exact same list of
## 3-mers. So, the k-mer profile pre-filter will see them as exactly
## similar (same kmer count, same length):

q1="AAACAAGAATACCACGACTAGCAGGAGTATCATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA"
t2="GGGTGGCGGAGTTGTCGTAGCTGCCGCAGATGACGAATTTCTTATCCTCATACTAACCCACAAAGG"

## first test: t1 == q1 and t& is first in the input
## perfect k-mer match, pre-sorting puts t1 at the top of the list of
## potential matches to q1 to be tested
t1="AAACAAGAATACCACGACTAGCAGGAGTATCATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA"
DESCRIPTION="issue 547: kmer profile filtering favors first de Bruijn sequence (#1)"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">t1\n%s\n>t2\n%s\n" "${t1}" "${t2}") \
    --wordlength 3 \
    --id 0.1 \
    --quiet \
    --userfields query+target+id \
    --userout - | \
    awk '{exit $2 == "t1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## second test: t1 == q1 but t2 is first in the input
## perfect k-mer match, pre-sorting puts t2 at the top of the list of
## potential matches to q1 to be tested
t1="AAACAAGAATACCACGACTAGCAGGAGTATCATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA"
DESCRIPTION="issue 547: kmer profile filtering favors first de Bruijn sequence (#2)"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">t2\n%s\n>t1\n%s\n" "${t2}" "${t1}") \
    --wordlength 3 \
    --id 0.1 \
    --quiet \
    --userfields query+target+id \
    --userout - | \
    awk '{exit $2 == "t2" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# candidates are sorted by kmer counts, then by length, then by input
# order (min_heap.cc:minheap_compare())

unset Q t1 t2


#******************************************************************************#
#                                                                              #
#                       missing userfields options (issue 548)                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/548

# TBD


#******************************************************************************#
#                                                                              #
#        Consequences of using vsearch on NovaSeq data (issue 549)             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/549

# continuation of issue 474
# NextSeq and RTA3 (2023) quality values are: 2, 14, 21, 27, 32, and 36

# 33                        59   64       73                            104                   126
#  |                         |    |        |                              |                     |
#  !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
#    |           |      |     |    |   |
#    2..........14.....21....27...32..36
#                                   |           |      |     |    |   |
#                                   2..........14.....21....27...32..36

# |   RTA3 |     |     |
# | offset | +33 | +64 |
# |--------+-----+-----|
# |      2 | '#' | 'B' |
# |     14 | '/' | 'N' |
# |     21 | '6' | 'U' |
# |     27 | '<' | '[' |
# |     32 | 'A' | '`' |
# |     36 | 'E' | 'd' |
# |--------+-----+-----|

for OFFSET in 33 64 ; do
    for i in 2 14 21 27 32 36 ; do
        DESCRIPTION="issue 549: RTA3 quality score ${i} is accepted (offset +${OFFSET})"
        OCTAL=$(printf "\%04o" $(( i + OFFSET )) )
        echo -e "@s\nA\n+\n${OCTAL}\n" | \
            "${VSEARCH}" \
                --fastq_eestats - \
                --fastq_ascii ${OFFSET} \
                --quiet \
                --output /dev/null 2> /dev/null && \
            success "${DESCRIPTION}" || \
                failure "${DESCRIPTION}"
    done
done
unset OCTAL OFFSET DESCRIPTION


#******************************************************************************#
#                                                                              #
#                 Fix warnings reported by Lintian (issue 550)                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/550

## compilation issues, not testable


#******************************************************************************#
#                                                                              #
#           Obtaining the expected error for each read  (issue 551)            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/551

## questions: how to obtain the EE value for each read? How to use EE to filter reads?

## with and without --eeout
DESCRIPTION="issue 551: obtaining the expected error for each read (--eeout)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --eeout \
        --fastaout - | \
    grep -Eqx ">s;ee=0.00040+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 551: obtaining the expected error for each read (no --eeout)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastaout - | \
    grep -Eqx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## filter with and without --fastq_maxee
DESCRIPTION="issue 551: obtaining the expected error for each read (no EE filtering)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastaout - | \
    grep -Eqx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 551: obtaining the expected error for each read (above EE filtering threshold)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 0.0005 \
        --fastaout - | \
    grep -Eqx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 551: obtaining the expected error for each read (equal EE filtering threshold)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 0.0004 \
        --fastaout - | \
    grep -Eqx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 551: obtaining the expected error for each read (below EE filtering threshold)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 0.0003 \
        --fastaout - | \
    grep -Eqx ">s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#       Question about the query file of -usearch_global command               #
#                when creating OTU tables (issue 552)                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/552

## - --usearch_global accepts fastq input
## - --search_exact accepts fastq input

## ------------------------------------------------------------- usearch_global

DESCRIPTION="issue 552: usearch_global accepts fasta input"
${VSEARCH} \
    --usearch_global <(printf ">q\nA\n") \
    --db <(printf ">t\nA\n") \
    --minseqlength 1 \
    --id 1.00 \
    --quiet \
    --uc - | \
    awk 'END {exit $1 == "H" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 552: usearch_global accepts fastq input"
${VSEARCH} \
    --usearch_global <(printf "@q\nA\n+\nI\n") \
    --db <(printf "@t\nA\n+\nI\n") \
    --minseqlength 1 \
    --id 1.00 \
    --quiet \
    --uc - | \
    awk 'END {exit $1 == "H" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 552: usearch_global accepts fastq input and fasta db"
${VSEARCH} \
    --usearch_global <(printf "@q\nA\n+\nI\n") \
    --db <(printf ">t\nA\n") \
    --minseqlength 1 \
    --id 1.00 \
    --quiet \
    --uc - | \
    awk 'END {exit $1 == "H" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 552: usearch_global accepts fasta input and fastq db"
${VSEARCH} \
    --usearch_global <(printf ">q\nA\n") \
    --db <(printf "@t\nA\n+\nI\n") \
    --minseqlength 1 \
    --id 1.00 \
    --quiet \
    --uc - | \
    awk 'END {exit $1 == "H" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- search_exact

DESCRIPTION="issue 552: search_exact accepts fasta input"
${VSEARCH} \
    --search_exact <(printf ">q\nA\n") \
    --db <(printf ">t\nA\n") \
    --quiet \
    --uc - | \
    awk 'END {exit $1 == "H" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 552: search_exact accepts fastq input"
${VSEARCH} \
    --search_exact <(printf "@q\nA\n+\nI\n") \
    --db <(printf "@t\nA\n+\nI\n") \
    --quiet \
    --uc - | \
    awk 'END {exit $1 == "H" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 552: search_exact accepts fastq input and fasta db"
${VSEARCH} \
    --search_exact <(printf "@q\nA\n+\nI\n") \
    --db <(printf ">t\nA\n") \
    --quiet \
    --uc - | \
    awk 'END {exit $1 == "H" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 552: search_exact accepts fasta input and fastq db"
${VSEARCH} \
    --search_exact <(printf ">q\nA\n") \
    --db <(printf "@t\nA\n+\nI\n") \
    --quiet \
    --uc - | \
    awk 'END {exit $1 == "H" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## expect:
# #OTU ID	S1	S2
# t	1	1
DESCRIPTION="issue 552: usearch_global can map fastq reads onto fasta references (db)"
${VSEARCH} \
    --usearch_global <(printf "@q1;sample=S1\nA\n+\nI\n@q2;sample=S2\nA\n+\nI\n") \
    --db <(printf ">t\nA\n") \
    --minseqlength 1 \
    --id 1.00 \
    --quiet \
    --otutabout - | \
    awk 'END {exit $2 == 1 && $3 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#       Convert Qiime2 database (2 files) into fasta database (1 file)         #
#           for taxonomic assignment in vsearch (issue 553)                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/553

## question, not testable


#******************************************************************************#
#                                                                              #
#                       --weak_id not working (issue 554)                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/554

# It should only report weak hits as long as it is still scanning for
# true hits. Scanning will be terminated when the specified maximum
# number of accepted or rejected hits (specified with maxaccepts and
# maxrejects) has been reached. The results of using weak_id are
# therefore somewhat unpredictable. It's probably only useful to see
# if there are may be any weak hits as long as there are no true hits.

# In the example above there is a true hit, and as long as maxaccepts is
# not more than 1, the weak hit will usually not be reported (unless
# rare cases where it is found before the true hit).

# note that one needs to remove s1 or increase maxaccepts in the example
# above to see the weak hit.

q1="AAACAAGAATACCACGACTAGCAGGAGTATCATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA"
s1="AAACAAGAATACCACGACTAGCAGGAGTATCATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA" # perfect match
s2="AAACAAGAATACCACGACTAGCAGGAGTATGATGATTCCCGCCTCGGCGTCTGCTTGGGTGTTTAA" # weak match (98.5%)
#                    substitution ^
s3="GGGTGGCGGAGTTGTCGTAGCTGCCGCAGATGACGAATTTCTTATCCTCATACTAACCCACAAAGG"  # no match, but 100% of kmers

## -------------------------------------------------------------- normal search

DESCRIPTION="issue 554: without weak_id, no good match (but perfect kmer match)"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s3\n%s\n" "${s3}") \
    --id 1.0 \
    --quiet \
    --uc - | \
    awk '{exit $1 == "N" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: without weak_id, weak match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s2\n%s\n" "${s2}") \
    --id 1.0 \
    --quiet \
    --uc - | \
    awk '{exit $1 == "N" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: without weak_id, good match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s1\n%s\n" "${s1}") \
    --id 1.0 \
    --quiet \
    --uc - | \
    awk '{exit $NF == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: without weak_id, weak match, good match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s2\n%s\n>s1\n%s\n" "${s2}" "${s1}") \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: without weak_id, no match (but perfect kmer), good match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s3\n%s\n>s1\n%s\n" "${s3}" "${s1}") \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: without weak_id, good match, weak match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s1\n%s\n>s2\n%s\n" "${s1}" "${s2}") \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: without weak_id, good match, no match (but perfect kmer)"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s1\n%s\n>s3\n%s\n" "${s1}" "${s3}") \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------ with option --weak_id

DESCRIPTION="issue 554: with weak_id, no good match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s3\n%s\n" "${s3}") \
    --id 1.0 \
    --weak_id 0.98 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: with weak_id, weak match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s2\n%s\n" "${s2}") \
    --id 1.0 \
    --weak_id 0.98 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s2" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: with weak_id, no match (but perfect kmer match)"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s3\n%s\n" "${s3}") \
    --id 1.0 \
    --weak_id 0.98 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: with weak_id, good match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s1\n%s\n" "${s1}") \
    --id 1.0 \
    --weak_id 0.98 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# only one match because of maxaccepts = 1 by default
DESCRIPTION="issue 554: with weak_id, weak match, good match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s2\n%s\n>s1\n%s\n" "${s2}" "${s1}") \
    --id 1.0 \
    --weak_id 0.98 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: with weak_id, no match (but perfect kmer), good match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s3\n%s\n>s1\n%s\n" "${s3}" "${s1}") \
    --id 1.0 \
    --weak_id 0.98 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# only one match because of maxaccepts = 1 by default
DESCRIPTION="issue 554: with weak_id, good match, weak match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s1\n%s\n>s2\n%s\n" "${s1}" "${s2}") \
    --id 1.0 \
    --weak_id 0.98 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 554: with weak_id, good match, no match (but perfect kmer)"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s1\n%s\n>s3\n%s\n" "${s1}" "${s3}") \
    --id 1.0 \
    --weak_id 0.98 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ----------------------------------------- with unlimited accepts and rejects
## expect two matches
DESCRIPTION="issue 554: with weak_id, unlimited accepts and rejects, weak match, good match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s2\n%s\n>s1\n%s\n" "${s2}" "${s1}") \
    --id 1.0 \
    --weak_id 0.98 \
    --maxaccepts 0 \
    --maxrejects 0 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"

DESCRIPTION="issue 554: with weak_id, unlimited accepts and rejects, good match, weak match"
${VSEARCH} \
    --usearch_global <(printf ">q1\n%s\n" "${q1}") \
    --db <(printf ">s1\n%s\n>s2\n%s\n" "${s1}" "${s2}") \
    --id 1.0 \
    --weak_id 0.98 \
    --maxaccepts 0 \
    --maxrejects 0 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset q1 s1 s2 s3

## ----- weak hits are not deduced from maxaccepts but count towards maxrejects
## weak hit is processed first, maxaccepts is still 1, search continues
DESCRIPTION="issue 554: with weak_id, weak hits counts towards maxrejects (find weak hit first, continue)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACGT\n") \
    --db <(printf ">s1\nACGA\n>s2\nACGT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --weak_id 0.75 \
    --maxaccepts 1 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## weak hit is processed first, rejects is incremented, maxrejects == 1, search stops
DESCRIPTION="issue 554: with weak_id, weak hits counts towards maxrejects (find weak hit first, stop)"
${VSEARCH} \
    --usearch_global <(printf ">q1\nACGT\n") \
    --db <(printf ">s1\nACGA\n>s2\nACGT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --weak_id 0.75 \
    --maxaccepts 0 \
    --maxrejects 1 \
    --quiet \
    --blast6out - | \
    awk 'END {exit NR == 1 && $2 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                       Problem building (issue 555)                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/555

## issue when compiling on CentOS 7, not testable


#******************************************************************************#
#                                                                              #
#                   Can't run static binary (issue 556)                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/556

## issue with static binaries, not testable


#******************************************************************************#
#                                                                              #
#             is there a major vote fraction parameter of                      #
#         a vsearch clustered consensus sequence? (issue 557)                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/557

## The consensus algorithm simply chooses the most common base in each
## position, so it could be almost down to 25%. If there are two
## equally common bases, it chooses the first in the alphabet of A, C,
## G, or T. If there are no ordinary bases, but at least one N, it
## uses N. If there are more gap symbols (-) than bases in a column,
## it uses a gap symbol.

## consensus algorithm keeps common bases
DESCRIPTION="issue 557: consout consensus keeps common bases (A)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nA\n>q2\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -qx "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus keeps common bases (C)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nC\n>q2\nC\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -qx "C" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus keeps common bases (G)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nG\n>q2\nG\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -qx "G" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus keeps common bases (T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nT\n>q2\nT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -qx "T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus is not case-sensitive (A-a)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nA\n>q2\na\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -qx "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus is not case-sensitive (a-A)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\na\n>q2\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -qx "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus is not case-sensitive (a-a)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\na\n>q2\na\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -qx "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout common bases are uppercased"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\na\n>q2\na\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -qx "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (2/3rd AA)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAA\n>q2\nAA\n>q3\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout does not pick least common base (1/3rd AC)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAA\n>q2\nAA\n>q3\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AC" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (3/5th AA)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAA\n>q2\nAA\n>q3\nAA\n>q4\nAC\n>q5\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout does not pick least common base (2/5th AC)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAA\n>q2\nAA\n>q3\nAA\n>q4\nAC\n>q5\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AC" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (1/2 AT)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAT\n>q3\nAA\n>q4\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (2/5 AT)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAT\n>q3\nAA\n>q4\nAC\n>q5\nAG\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (3/9 AT)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAT\n>q3\nAT\n>q4\nAA\n>q5\nAA\n>q6\nAC\n>q7\nAC\n>q8\nAG\n>q9\nAG\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (4/13 AT)"
(printf ">s\nAT\n"
 for ((i=1 ; i<=3 ; i++)) ; do
     printf ">s\nAT\n"
     printf ">s\nAA\n"
     printf ">s\nAC\n"
     printf ">s\nAG\n"
 done
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (5/17 AT)"
(printf ">s\nAT\n"
 for ((i=1 ; i<=4 ; i++)) ; do
     printf ">s\nAT\n"
     printf ">s\nAA\n"
     printf ">s\nAC\n"
     printf ">s\nAG\n"
 done
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (6/21 AT)"
(printf ">s\nAT\n"
 for ((i=1 ; i<=5 ; i++)) ; do
     printf ">s\nAT\n"
     printf ">s\nAA\n"
     printf ">s\nAC\n"
     printf ">s\nAG\n"
 done
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (100/397 AT)"
(printf ">s\nAT\n"
 for ((i=1 ; i<=99 ; i++)) ; do
     printf ">s\nAT\n"
     printf ">s\nAA\n"
     printf ">s\nAC\n"
     printf ">s\nAG\n"
 done
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## circa 25.01%
DESCRIPTION="issue 557: consout picks most common base (1000/3997 AT)"
(printf ">s\nAT\n"
 for ((i=1 ; i<=999 ; i++)) ; do
     printf ">s\nAT\n"
     printf ">s\nAA\n"
     printf ">s\nAC\n"
     printf ">s\nAG\n"
 done
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## If there are two equally common bases, it chooses the first in the
## alphabet of A, C, G, or T
DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (A before C)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAC\n>q2\nAA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (A before G)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAG\n>q2\nAA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (A before T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (C before G)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAG\n>q2\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (C before T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (G before T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAG\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## what about lowercase sequences? case-insensitive
DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (case-insensitive)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAC\n>q2\nAa\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# If there are no ordinary bases, but at least one N, it uses N.

DESCRIPTION="issue 557: consout picks any base rather than N (A)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAN\n>q2\nAA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks any base rather than N (C)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAN\n>q2\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks any base rather than N (G)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAN\n>q2\nAG\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks any base rather than N (T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAN\n>q2\nAT\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks any base rather than N (t, case-insensitive)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAN\n>q2\nAt\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks N if there are no other base"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nNA\n>q2\nA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "NA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks N if there is only Ns"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nNA\n>q2\nNA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "NA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks a base, even if there are several Ns"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nNA\n>q2\nNA\n>q3\nAA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# If there are more gap symbols (-) than bases in a column, it uses a
# base nonetheless (different from --msaout!)
DESCRIPTION="issue 557: consout never picks a gap even if gaps are dominant (5')"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nACGT\n>q2\nCGT\n>q3\nCGT\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "CGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout never picks a gap even if gaps are dominant (3')"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nCGTA\n>q2\nCGT\n>q3\nCGT\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -qx "CGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note: opening a gap in the middle of an alignment is hard
DESCRIPTION="issue 557: consout never picks a gap even if gaps are dominant (middle)"
SEQ="ATATATAT"
printf ">q1\n%sC%s\n>q2\n%s%s\n>q3\n%s%s\n" ${SEQ} ${SEQ} ${SEQ} ${SEQ} ${SEQ} ${SEQ} | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --consout - | \
    grep -qx "ATATATATATATATAT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="issue 557: unlike consout, msaout picks a gap if gaps are dominant (middle)"
SEQ="ATATATAT"
printf ">q1\n%sC%s\n>q2\n%s%s\n>q3\n%s%s\n" ${SEQ} ${SEQ} ${SEQ} ${SEQ} ${SEQ} ${SEQ} | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --msaout - | \
    grep -qx "ATATATAT-ATATATAT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## expect:
# >centroid=q1;seqs=2
# 0	T	0	0	0	2	0	0
DESCRIPTION="issue 557: profile output (U is counted as a T) (T first)"
printf ">q1\nT\n>q2\nU\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --profile - | \
    awk 'NR == 2 {exit $6 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: profile output (U is counted as a T) (U first)"
printf ">q1\nU\n>q2\nT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --profile - | \
    awk 'NR == 2 {exit $6 == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: profile output (RSWKMBDHV are counted as a N)"
printf ">q1\nR\n>q2\nS\n>q3\nW\n>q4\nK\n>q5\nM\n>q6\nB\n>q7\nD\n>q8\nH\n>q9\nV\n>q10\nN\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --profile - | \
    awk 'NR == 2 {exit $NF == 10 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: profile output (Y is counted as a N)"
printf ">q1\nY\n>q2\nN\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --id 0.5 \
        --quiet \
        --profile - | \
    awk 'NR == 2 {exit $NF == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## warning: clustering results are sometimes different in debug mode!!
## could be due to threading?


#******************************************************************************#
#                                                                              #
#       usearch_global command eats my sample IDs (issue 558)                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/558

## --otutabout: The OTU and sample identifiers are extracted from the
## FASTA headers of the sequences (see the --sample option).

## --sample value is used as column name
DESCRIPTION="issue 558: usearch_global, use sample IDs in query"
"${VSEARCH}" \
    --usearch_global <(printf ">MS-A;sample=MS-A\nA\n") \
    --db <(printf ">MS-A\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --otutabout - | \
    awk 'NR == 1 {exit $NF == "MS-A" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## sample annotation must be in the query, not db
DESCRIPTION="issue 558: usearch_global, sample IDs in db are not used"
"${VSEARCH}" \
    --usearch_global <(printf ">MS-A\nA\n") \
    --db <(printf ">MS-A;sample=MS-A\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --otutabout - | \
    awk 'NR == 1 {exit $NF == "MS" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## sample string can contain almost any visible character (alpha-num and punctuations)
DESCRIPTION="issue 558: usearch_global, sample IDs are truncated after ';'"
"${VSEARCH}" \
    --usearch_global <(printf ">MS-A;sample=MS;A\nA\n") \
    --db <(printf ">MS-A\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --otutabout - | \
    awk 'NR == 1 {exit $NF == "MS" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 558: usearch_global, sample IDs are truncated after ' ' (space)"
"${VSEARCH}" \
    --usearch_global <(printf ">MS-A;sample=MS A\nA\n") \
    --db <(printf ">MS-A\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --otutabout - | \
    awk 'NR == 1 {exit $NF == "MS" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## If ;sample=ABC is not present, otutabout seems to use the OTU name,
## but truncated... What are the rules?
DESCRIPTION="issue 558: usearch_global, missing sample ID (default to sequence identifier)"
"${VSEARCH}" \
    --usearch_global <(printf ">MS1\nA\n") \
    --db <(printf ">MS-A\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --otutabout - | \
    awk 'NR == 1 {exit $NF == "MS1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 558: usearch_global, missing sample ID (truncate sequence identifier at '-')"
"${VSEARCH}" \
    --usearch_global <(printf ">MS-A\nA\n") \
    --db <(printf ">MS-A\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --otutabout - | \
    awk 'NR == 1 {exit $NF == "MS" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 558: usearch_global, missing sample ID (truncate sequence identifier at ';')"
"${VSEARCH}" \
    --usearch_global <(printf ">MS;A\nA\n") \
    --db <(printf ">MS-A\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --otutabout - | \
    awk 'NR == 1 {exit $NF == "MS" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 558: usearch_global, missing sample ID (truncate sequence identifier at '.')"
"${VSEARCH}" \
    --usearch_global <(printf ">MS.A\nA\n") \
    --db <(printf ">MS-A\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --otutabout - | \
    awk 'NR == 1 {exit $NF == "MS" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# no truncation after a alphabetical, numerical, or '_'
DESCRIPTION="issue 558: usearch_global, missing sample ID (no truncation at '_')"
"${VSEARCH}" \
    --usearch_global <(printf ">MS_A\nA\n") \
    --db <(printf ">MS-A\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --otutabout - | \
    awk 'NR == 1 {exit $NF == "MS_A" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#           USEARCH wants to go open-source? (issue 559)                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/559

## not testable


#******************************************************************************#
#                                                                              #
#                        Adapt for RISC-V (issue 560)                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/560

## not testable


#******************************************************************************#
#                                                                              #
#                vsearch.1: typo choosen -> chosen (issue 561)                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/561

## pull request, not testable


#******************************************************************************#
#                                                                              #
#     centroid sequence length after clustering is different from input        #
#          sequences' length which are all equal to 200n (issue 562)           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/562

## alignment:
# *A  CGGGAAGCCCAAGGGGGGTGGTGACCGAGTACG-
#  B  -GGGAAGCCCAAAGGGGGTGGTGACCGAGTACGC
#  C  -GGGAAGCCCAATGGGGTTGGTGACCGAGTACGC
#     .----------------.---------------.
#     -GGGAAGCCCAAAGGGGGTGGTGACCGAGTACG+  consensus
DESCRIPTION="issue 562: --consout consensus can be shorter than input sequences"
(
    printf ">A\nCGGGAAGCCCAAGGGGGGTGGTGACCGAGTACG\n"
    printf ">B\nGGGAAGCCCAAAGGGGGTGGTGACCGAGTACGC\n"
    printf ">C\nGGGAAGCCCAATGGGGTTGGTGACCGAGTACGC\n"
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.80 \
        --iddef 4 \
        --quiet \
        --consout - | \
    grep -qx "GGGAAGCCCAAAGGGGGTGGTGACCGAGTACG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## msaout:
# >*A
# CGGGAAGCCCAAGGGGGGTGGTGACCGAGTACG-
# >B
# -GGGAAGCCCAAAGGGGGTGGTGACCGAGTACGC
# >C
# -GGGAAGCCCAATGGGGTTGGTGACCGAGTACGC
# >consensus
# -GGGAAGCCCAAAGGGGGTGGTGACCGAGTACG+
DESCRIPTION="issue 562: --msaout a star indicates the centroid"
(
    printf ">A\nCGGGAAGCCCAAGGGGGGTGGTGACCGAGTACG\n"
    printf ">B\nGGGAAGCCCAAAGGGGGTGGTGACCGAGTACGC\n"
    printf ">C\nGGGAAGCCCAATGGGGTTGGTGACCGAGTACGC\n"
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.80 \
        --iddef 4 \
        --quiet \
        --msaout - | \
    grep -qx ">[*]A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 562: --msaout the last fasta entry is the consensus"
(
    printf ">A\nCGGGAAGCCCAAGGGGGGTGGTGACCGAGTACG\n"
    printf ">B\nGGGAAGCCCAAAGGGGGTGGTGACCGAGTACGC\n"
    printf ">C\nGGGAAGCCCAATGGGGTTGGTGACCGAGTACGC\n"
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.80 \
        --iddef 4 \
        --quiet \
        --msaout - | \
    tail -n 2 | \
    grep -qx ">consensus" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# the extra "C" in the beginning is found in a minority of the
# sequences (only A), and is represented by a gap in the consensus
DESCRIPTION="issue 562: --msaout consensus sequence retains gaps"
(
    printf ">A\nCGGGAAGCCCAAGGGGGGTGGTGACCGAGTACG\n"
    printf ">B\nGGGAAGCCCAAAGGGGGTGGTGACCGAGTACGC\n"
    printf ">C\nGGGAAGCCCAATGGGGTTGGTGACCGAGTACGC\n"
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.80 \
        --iddef 4 \
        --quiet \
        --msaout - | \
    tail -n 1 | \
    grep -q "^-" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# positions that do not exist in the centroid (A), like the final "C"
# in sequences B and C, are not included in the consensus
DESCRIPTION="issue 562: --msaout gaps in the centroid are marked with a +"
(
    printf ">A\nCGGGAAGCCCAAGGGGGGTGGTGACCGAGTACG\n"
    printf ">B\nGGGAAGCCCAAAGGGGGTGGTGACCGAGTACGC\n"
    printf ">C\nGGGAAGCCCAATGGGGTTGGTGACCGAGTACGC\n"
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.80 \
        --iddef 4 \
        --quiet \
        --msaout - | \
    tail -n 1 | \
    grep -q "+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 562: --consout consensus does not contain gaps"
(
    printf ">A\nCGGGAAGCCCAAGGGGGGTGGTGACCGAGTACG\n"
    printf ">B\nGGGAAGCCCAAAGGGGGTGGTGACCGAGTACGC\n"
    printf ">C\nGGGAAGCCCAATGGGGTTGGTGACCGAGTACGC\n"
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.80 \
        --iddef 4 \
        --quiet \
        --consout - | \
    grep -q "[+-]" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#     sintax assigns unclassifiable queries to first sequence (issue 563)      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/563

# vsearch --sintax appeared to assign unclassifiable queries to the
# first (or closest) sequence in the database. The reporter could not
# provide a minimal reproducible example, and the developer was unable
# to reproduce the problem. The issue was closed without a fix; there
# is nothing to test.


#******************************************************************************#
#                                                                              #
#              Segfault with derep_id on both strands (issue 565)              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/565

# vsearch 2.28.1 crashed with a segmentation fault when running
# --derep_id on both strands. Fixed in commit a05b2ea.

DESCRIPTION="issue 565: --derep_id --strand both does not segfault"
printf ">s1;size=1;\nA\n>s1;size=1;\nT\n" | \
    "${VSEARCH}" \
        --derep_id - \
        --minseqlength 1 \
        --strand both \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# the two entries share the same identifier and are reverse-complement
# of each other, so on both strands they are dereplicated together
DESCRIPTION="issue 565: --derep_id --strand both dereplicates the two reverse-complement entries"
printf ">s1;size=1;\nA\n>s1;size=1;\nT\n" | \
    "${VSEARCH}" \
        --derep_id - \
        --minseqlength 1 \
        --strand both \
        --sizeout \
        --quiet \
        --output - | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  fastx_uniques: still reachable memory under certain conditions (issue 567)  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/567

# valgrind reports a small amount of still-reachable memory (not a
# definite leak) when --fastx_uniques is used together with --fastqout
# or --tabbedout. This is a minor issue; memory behaviour is covered by
# the valgrind tests, so there is nothing to add here.


#******************************************************************************#
#                                                                              #
#       Unexpected behavior when clustering short sequences (issue 568)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/568

## k-mer prefiltering step as described in the manual:

# That efficient pre-filtering also prevents pairwise alignments with
# very short, or with weakly matching targets, as there needs to be by
# default at least 12 shared k-mers to start the pairwise alignment, and
# at least one out of every 16 k-mers from the query needs to match the
# target.

## situation: sequences are 20 basepairs long (20 + 1 - 8 = up to 13
## 8-mers)

# >2  AGCCGGTAGGACTGAACGTA
#     ||||||||||||||||| ||
# >1  AGCCGGTAGGACTGAACATA

## 10/13 kmers: not enough common 8-mers, no alignment
DESCRIPTION="issue 568: k-mer prefiltering when clustering short sequences (below threshold)"
(
    printf ">2\nAGCCGGTAGGACTGAACGTA\n"
    printf ">1\nAGCCGGTAGGACTGAACATA\n"
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 20 \
        --id 0.8 \
        --iddef 4 \
        --quiet \
        --consout - | \
    awk '/^>/ {c += 1} END {exit c == 1 ? 0 : 1}' && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## 10/13 kmers: lower the number of required 8-mers, alignment
DESCRIPTION="issue 568: k-mer prefiltering when clustering short sequences (lower threshold)"
(
    printf ">2\nAGCCGGTAGGACTGAACGTA\n"
    printf ">1\nAGCCGGTAGGACTGAACATA\n"
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 20 \
        --id 0.8 \
        --iddef 4 \
        --minwordmatches 10 \
        --quiet \
        --consout - | \
    awk '/^>/ {c += 1} END {exit c == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# >2  AGCCGGTAGGACTGAACATG
#     |||||||||||||||||||
# >1  AGCCGGTAGGACTGAACATA

## if the mismatch is in last position (loose only one k-mer)
## 12/13 kmers: just enough common 8-mers, alignment
DESCRIPTION="issue 568: k-mer prefiltering when clustering short sequences (equal to threshold)"
(
    printf ">2\nAGCCGGTAGGACTGAACATG\n"
    printf ">1\nAGCCGGTAGGACTGAACATA\n"
) | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 20 \
        --id 0.8 \
        --iddef 4 \
        --quiet \
        --consout - | \
    awk '/^>/ {c += 1} END {exit c == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#              Very slow processing sintax vsearch/2.28.1 (issue 570)          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/570



#******************************************************************************#
#                                                                              #
#     --fastq_stats returns erroneous cumulated percentage for empty reads     #
#                               (issue 571)                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/571

## v2.29.0 and more recent
## tested in fastq_stats.sh


#******************************************************************************#
#                                                                              #
#   --fastq_stats: remove option --output from the list of accepted options    #
#                               (issue 572)                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/572

## v2.29.0 and more recent
DESCRIPTION="issue 572: --fastq_stats should reject option --output"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#            Mismatches in taxonomic ranks with Sintax (issue 573)             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/573

# A logical bug in the selection of the best lineages could make
# --sintax taxonomic ranks jump between unrelated clades, but only when
# the confidence was below 0.5. Fixed in commit aa94d1c (released in
# v2.29.0). The bug was found with a large private dataset; no minimal
# reproducible example is available.


#******************************************************************************#
#                                                                              #
#     vsearch-2.29.0-linux-x86_64-static segmentation fault (issue 574)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/574

## not testable


#******************************************************************************#
#                                                                              #
#             Is there a way to filter fastq reads based on Qscore             #
#                     before paired end merging? (issue 575)                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/575

# Discard reads having any base with a quality score below the given
# value. The default is 0, which discards none.


## --------------------------------------------------------------- fastx_filter

DESCRIPTION="issue 575: --fastx_filter accepts --fastq_minqual"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastx_filter --fastq_minqual accepts a null value"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 0 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastx_filter --fastq_minqual accepts positive values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastx_filter --fastq_minqual rejects floating values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 1.0 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastx_filter --fastq_minqual rejects negative values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual -1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastx_filter --fastq_minqual rejects non-numerical values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual A \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastx_filter --fastq_minqual rejects empty values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# 'I' = Q40
DESCRIPTION="issue 575: --fastx_filter --fastq_minqual (no effect if Q-value is above threshold)"
printf "@s\nAA\n+\nJI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 39 \
        --quiet \
        --fastaout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'I' = Q40
DESCRIPTION="issue 575: --fastx_filter --fastq_minqual (no effect if Q-value is equal to threshold)"
printf "@s\nAA\n+\nJI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 40  \
        --quiet \
        --fastaout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'I' = Q40
DESCRIPTION="issue 575: --fastx_filter --fastq_minqual (discard if Q-value is below than threshold)"
printf "@s\nAA\n+\nJI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 41 \
        --quiet \
        --fastaout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastx_filter --fastq_minqual null keeps all sequences"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 0 \
        --quiet \
        --fastaout - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '~' = Q93, the largest possible Q value
DESCRIPTION="issue 575: --fastx_filter --fastq_minqual 94 discards all sequences"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_qmax 93 \
        --fastq_minqual 94 \
        --quiet \
        --fastaout - | \
    grep -qx ">s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastx_filter --fastq_minqual rejects fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- fastq_filter

DESCRIPTION="issue 575: --fastq_filter accepts --fastq_minqual"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastq_filter --fastq_minqual accepts a null value"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 0 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastq_filter --fastq_minqual accepts positive values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastq_filter --fastq_minqual rejects floating values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 1.0 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastq_filter --fastq_minqual rejects negative values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual -1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastq_filter --fastq_minqual rejects non-numerical values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual A \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastq_filter --fastq_minqual rejects empty values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# 'I' = Q40
DESCRIPTION="issue 575: --fastq_filter --fastq_minqual (no effect if Q-value is above threshold)"
printf "@s\nAA\n+\nJI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 39 \
        --quiet \
        --fastaout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'I' = Q40
DESCRIPTION="issue 575: --fastq_filter --fastq_minqual (no effect if Q-value is equal to threshold)"
printf "@s\nAA\n+\nJI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 40  \
        --quiet \
        --fastaout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'I' = Q40
DESCRIPTION="issue 575: --fastq_filter --fastq_minqual (discard if Q-value is below than threshold)"
printf "@s\nAA\n+\nJI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 41 \
        --quiet \
        --fastaout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastq_filter --fastq_minqual null keeps all sequences"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 0 \
        --quiet \
        --fastaout - | \
    grep -qx "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '~' = Q93, the largest possible Q value
DESCRIPTION="issue 575: --fastq_filter --fastq_minqual 94 discards all sequences"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 93 \
        --fastq_minqual 94 \
        --quiet \
        --fastaout - | \
    grep -qx ">s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 575: --fastq_filter --fastq_minqual rejects fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#   Why Pairwise alignment (--allpairs_global) only support positive strand?   #
#                               (issue 576)                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/576

# how to match entries that are in the wrong orientation?
DESCRIPTION="issue 576: revcomp input so --allpairs_global can search both strands"
(
    printf ">s1\nAAAA\n>s2\nTTTT\n"
    "${VSEARCH}" \
        --fastx_revcomp <(printf ">s1\nAAAA\n>s2\nTTTT\n") \
        --quiet \
        --label_suffix "_rv" \
        --fastaout -
) | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.75 \
        --iddef 1 \
        --quiet \
        --blast6out - | \
    grep -q "^s1[[:blank:]]s2_rv" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#            --uchime_ref segmentation fault in 2.29.0 (issue 577)             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/577

## bug introduced in June 2024, with commit
## 4d062bf80f2fa1e22bc2b959b51085a88adabd26, first report and data
## provided by user labrat789. Test is flaky so repeat 10 times to
## make sure segfault is observed

QUERIES=$(mktemp)
(
    printf ">q1\nCGCACTACCCCATCAACTTCGTCTTGCCCTCCACCATGATACCGGGTGCCCTCATCATGGACACCGTCATGCTGCTCACGCGCAACTGGATGATCACCGCCCTGGTTGGAGGCGGCGCCTTTGGCCTGCTGTTCTACCCGGGCAACTGGCCCATTTTTGGACCGACCCACCTGCCGCTGGTAGCCGAAGGCGTGCTGCTCTCCCTGGCTGACTACACCGGCTTCCTGTATGTACGCACGGGTACCCCCGAGTACGTGCGGCTGATCGAACAAGGGTCCTTGCGCACATTTGGCGGCCACACCACCGTCATTGCCGCCTTCTTCTCCGCGTTCGTCTCCATGCTCATGTTCTGCGTATGGTGGTACTTTGGCAAACTCTACTGCACCGCCTTCTACTACGTCAAAGGCCCTCGCGGCCGGGTTACCATGAAGAACGACGTCACCGCCTACGGC\n"
    printf ">q2\nCACACTACCCCATCAACTTTGTATTCCCCTCCACCATGATACCTGGAGCGCTGGTCATGGACACCGTCTTGCTGCTCACGCGCAACTGGATGGTTACAGCCCTGATTGGCGGGGGTGCGTTTGGTCTTCTGTTCTACCCCGGCAACTGGCCCATTTTTGGCCCGACCCACCTGCCGCTGGTGGCTGAAGGCGTCCTGCTGTCGGTAGCCGACTACACAGGCTTCCTGTATGTACGCACCGGCACGCCCGAGTACGTGCGCCTGATCGAACAAGGCTCATTGCGAACCTTTGGCGGTCACACCACCGTCATTGCCGCATTCTTCTCCGCCTTCGTCTCCATGCTCATGTTCTGCGTATGGTGGTACTTTGGCAAAGTCTACTGCACCGCCTTCTACTACGTAAAAGGCGCGCGTGGCCGCGTCAGCATGAAGAACGACGTCACCGCATTTGGC\n"
) > "${QUERIES}"

DATABASE=$(mktemp)
(
    printf ">s1\nGGGTTTTACTGGTGGTCGCACTACCCCATCAACTTCGTGTTTCCCTCCACCATGATTCCTGGCGCACTGGTCATGGACACCGTCATGCTGCTCACCCGCAACTGGATGATCACGGCATTGGTTGGAGGTGGCGCGTTTGGGCTGCTGTTCTACCCGGGCAACTGGCCGATCTTCGGGCCGACCCACCTGCCGCTGGTTGCCGAAGGCGTTCTCCTGTCGGTGGCTGACTACACCGGCTTTCTGTATGTACGCACGGGTACCCCTGAGTACGTACGCCTGATCGAACAAGGGTCGCTGCGCACCTTTGGTGGCCACACCACGGTGATTGCCGCGTTCTTCTCCGCGTTTGTCTCCATGCTCATGTTCACCGTATGGTGGTACTTTGGCAAAGTCTACTGCACCGCCTTCTTCTATGTAAAAGGAGCGCGTGGACGCATCTCCATGAAGAACGACGTTACCGCATACGGGGAAGAAGGGTTTccggagggg\n"
    printf ">s2\nGGCTTCTACTGGTGGTCGCACTACCCCATCAACTTTGTATTTCCCTCCACCATGATTCCTGGGGCGCTGATCATGGACACGGTCATGCTGCTCACCCGCAACTGGATGATCACGGCACTGGTAGGCGGGGGCGCATTTGGACTTTTGTTCTACCCTGGCAACTGGCCCATTTTTGGCCCGACCCACCTTCCGCTGGTAGCTGAAGGCGTACTGCTGTCGGTAGCTGACTACACCGGCTTCCTGTATGTACGCACCGGCACGCCCGAGTACGTGCGCCTGATCGAACAAGGCTCGCTGCGAACCTTTGGCGGGCACACTACGGTCATTGCCGCATTCTTCTCCGCGTTTGTCTCCATGCTCATGTTCTGCGTGTGGTGGTACTTTGGCAAAGTCTACTGCACCGCCTTCTACTACGTAAAAGGCGCCCGTGGCCGCGTCAGCATGAAGAACGACGTCACCGCATTTGGCGAAGAAGGCTTTcccgagggg\n"
    printf ">s3\nGGCTTCTACTGGTGGTCGCACTACCCCATCAGCTTCGTCTTCCCCTCCACCATGATACCGGGCGCACTGGTCATGGACACCGTCATGCTGCTCACCCGCAACTGGATGATCACAGCCCTGGTTGGCGGAGGCGCATTCGGACTCCTGTTCTACCCGGGTAACTGGCCCATCTTTGGCCCGACCCACCTGCCGCTGGTAGCCGAAGGCGTATTGTTGTCGGTTGCTGACTACACCGGCTTCCTGTACGTTCGCACCGGCACCCCCGAGTACGTACGCAACATCGAACAAGGCTCACTCAGAACCTTTGGCGGCCACACCACCGTCATCGCCTCATTCTTTGCCGCCTTCGTCTCCATGCTCATGTTCTGCCTCTGGTGGTACTTCGGCAAACTTTACTGCACCGCATTCTTCTACGTCAAAGGAGCCCGTGGCCGCGTCACCATGAAAAACGACGTCACCGCATTTGGCGAAGAAGGCTTTcccgagggg\n"
    printf ">s4\nGGTTTCTACTGGTGGTCGCACTACCCCATGAACTTTGTATTCCCCTCCACCATGATTCCCGGCGCGCTGGTGATGGACACCGTCCTGCTTCTGACGCGCAACTGGATGATCACGGCACTGGTTGGCGGCGGCGCCTTTGGTTTGTTGTTCTATCCTGGCAACTGGACCATCTTCGGGCCGACCCACCTGCCGCTGGTGGCAGAAGGCGTGCTGCTCTCGGTAGCCGACTACACGGGCTTTCTGTATGTCCGTACCGGCACCCCTGAGTACGTGCGACTGATCGAACAAGGGTCACTGCGCACCTTTGGCGGTCACACCACCGTTATCGCCTCCTTCTTCTCCGCGTTCGTCTCCATGCTCATGTTCACCGTCTGGTGGTACTTTGGCAAGGTCTACTGCACCGCCTTCTACTATGTCAAGGGCGCACGCGGCCGTGTCAGCATGAAGAACGACGTGACAGCATTTGGCGAAGAAGGCTTTGCCgagggg\n"
    printf ">s5\nGGCTTCTACTGGTGGTCGCACTACCCCATCAACTTCGTCTTCCCCTCCACCATGATACCGGGCGCACTGGTCATGGACACCGTCATGCTGCTCACCCGCAACTGGATGATCACAGCCCTGGTTGGCGGAGGCGCATTCGGACTCCTGTTCTACCCGGGTAACTGGCCCATCTTTGGCCCGACCCACCTGCCGCTGGCAGCCGAAGGCGTATTGTTGTCGGTTGCTGACTACACCGGCTTCCTGTACGTTCGCACCGGCACCCCCGAGTACGTACGCAACATCGAACAAGGCTCACTCAGAACCTTTGGCGGGCACACCACCGTCATCGCCTCATTCTTTGCCGCCTTCGTCTCCATGCTCATGTTCTGCCTCTGGTGGTACTTCGGCAAACTTTACTGCACCGCATTCTTCTACGTCAAGGGAACCCGTGGCCGTGTCACCATGAAGAACGATGTCACCGCATTTGGGGAAGAAGGCTTCccggagggg\n"
    printf ">s6\nTCGCACTACCCCATCAGCTTCGTCTTCCCCTCCACCATGATACCCGGGGCACTCGTCATGGACACGGTCATGCTCCTGACGCGCAACTGGATGATCACCGCACTGGTAGGCGGCGGCGCCTTTGGCCTGTTGTTCTACCCGGGCAACTGGACCATCTTCGGCCCGACCCACCTGCCGCTGGTAGCTGAAGGCGTACTGCTCTCCGTTGCCGACTACACCGGCTTTTTGTATGTGCGCACCGGCACGCCCGAGTACGTACGGCTGATCGAACAAGGCTCGCTCAGAACCTTTGGCGGCCACACCACGGTCATTGCCTCGTTCTTTGCCGCCTTCGTCTCCATGCTGATGTTCTGCGTCTGGTGGTACTTTGGCAAACTCTACTGCACCGCCTTCTTCTACGTTAAGGGCGCGCGCGGCCGAGTCACCATGAAAAACGACGTCACCGCNTTTGGC\n"
    printf ">s7\nGGATTTTACTGGTGGTCGCACTACCCCATCAACTTCGTCTTCCCCTCCACCATGATTCCTGGAGCACTGATCATGGACACCGTCATGCTGCTCACCCGCAACTGGATGATCACGGCACTGATCGGAGGCGGCGCATTCGGTCTGCTGTTCTACCCTGGCAACTGGCCCATCTTTGGCCCGACCCACCTGCCGCTGGTCGCTGAAGGCGTGCTGCTGTCGGTAGCCGACTACACCGGCTTTTTGTATGTACGCACCGGCACCCCTGAGTACGTGCGCCTGATCGAACAAGGGTCGCTACGAACCTTTGGCGGGCACACCACCGTGATTGCCGCATTCTTCTCCGCATTCGTCTCCATGCTCATGTTCACCGTCTGGTGGTACTTTGGCAAGGTCTACTGCACCGCCTTCTTCTACGTGAAGGGCCCGCGTGGACGCATCTCCATGAAGAACGACGTGACCGCGTATGGCGAAGAAGGGTTTccggagggg\n"
    printf ">s8\nTCGCACTACCCCATCAGCTTCGTCTTCCCCTCCACCATGATCCCGGGCGCACTGGTCATGGACACCGTCATGCTGCTGACCCGCAACTGGATGATCACCGCCCTGGTTGGCGGCGGCGCCTTTGGCCTGCTGTTCTACCCGGGCAACTGGCCCATCTTCGGCCCCACCCACCTGCCGCTGGTAGCCGAAGGCGTCCTGCTGTCAGTAGCCGACTACACCGGCTTCCTGTATGTACGCACCGGCACGCCCGAGTACGTCCGCCTGATCGAACAAGGCTCACTGCGCACCTTTGGCGGCCACACCACCGTGATTGCCTCCTTCTTTGCCGCCTTCGTCTCCATGCTCATGTTCACCGTCTGGTGGTACTTTGGCAAACTCTACTGCAGCGCCTTCTTCTACGTCAAAGGCGCGCGTGGCCGAGTCACCATGAAAAACGACGTCACCGCATTTGGC\n"
    printf ">s9\nTCGCACTACCCCATCAACTTCGTCTTCCCCTCCACCATGATCCCCGGCGCGCTCGTCATGGACACCGTCCTGCTGCTGACGCGCAACTGGATGATCACCGCCCTGGTTGGCGGCGGCGCCTTTGGCCTGCTGTTCTACCCGGGCAACTGGCCCATCTTTGGCCCCACCCACCTGCCGCTGGTGGCTGAAGGCGTCCTGCTCTCGCTGGCCGACTACACCGGCTTCCTGTATGTACGCACCGGCACCCCTGAATACGTGCGGCTGATCGAACAAGGCTCACTGCGCACCTTTGGCGGCCACACCACCGTCATCGCCGCCTTCTTCTCCGCTTTCGTCTCCATGCTCATGTTCTGCGTCTGGTGGTACTTTGGCAAACTCTACTGCACCGCCTTCTACTACGTCAAAGGCCCGCGCGGCCGCGTCACCATGAAAAACGACGTCACCGCCTACGGC\n"
) > "${DATABASE}"

DESCRIPTION="issue 577: --uchime_ref segmentation fault"
for i in {1..10} ; do
    "${VSEARCH}" \
           --uchime_ref "${QUERIES}" \
           --db "${DATABASE}" \
           --chimeras /dev/null \
           2> /dev/null || failure "${DESCRIPTION}"
done && success "${DESCRIPTION}"

rm "${DATABASE}" "${QUERIES}"
unset DATABASE QUERIES


#******************************************************************************#
#                                                                              #
#   SINTAX taxonomic annotation changes when adding domain rank (issue 578)    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/578

# The sintax algorithm has a random element to it and the confidence
# values you see may vary slightly from one run to another unless you
# set a specific random seed with the --randseed option (and possibly
# --threads 1, but it does not seem to matter in that experiment).

## Random seed -> variable results
# - return different probability values (as expected)
# - pick species A, even though B is closer (unexpected!)
# - (if the perfect match is not in first position)
# q	d:D(1.00),p:P(1.00),c:C(1.00),o:O(1.00),f:F(1.00),g:G(1.00),s:speciesA(0.51)	+
# q	d:D(1.00),p:P(1.00),c:C(1.00),o:O(1.00),f:F(1.00),g:G(1.00),s:speciesB(0.58)	+

DESCRIPTION="issue 578: --sintax has a random element (random seed)"
TAXO="d:D,p:P,c:C,o:O,f:F,g:G,s:species"
SEQ="TACTTAATGTTTGCATTATTCTCAGGTTTATTAGGTACAGCATTTTCT"
REF1="${SEQ}"
REF2="${SEQ/T/A}"
RESULTS1=$(mktemp)
RESULTS2=$(mktemp)

function run_with_random_seed() {
    for i in {1..10} ; do
        "${VSEARCH}" \
            --sintax <(printf ">q\n%s\n" "${SEQ}") \
            --db <(
            printf ">s1;tax=%sA;\n%s\n" "${TAXO}" "${REF2}"
            printf ">s2;tax=%sB;\n%s\n" "${TAXO}" "${REF1}") \
                --quiet \
                --threads 1 \
                --tabbedout -
    done
}

run_with_random_seed > "${RESULTS1}"
run_with_random_seed > "${RESULTS2}"

diff -q "${RESULTS1}" "${RESULTS2}" > /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}" || \

rm "${RESULTS1}" "${RESULTS2}"
unset TAXO SEQ REF1 REF2 RESULTS1 RESULTS2 run_with_random_seed


DESCRIPTION="issue 578: --sintax has a random element (fix seed)"
TAXO="d:D,p:P,c:C,o:O,f:F,g:G,s:species"
SEQ="TACTTAATGTTTGCATTATTCTCAGGTTTATTAGGTACAGCATTTTCT"
REF1="${SEQ}"
REF2="${SEQ/T/A}"
RESULTS1=$(mktemp)
RESULTS2=$(mktemp)

function run_with_fix_seed() {
    for i in {1..10} ; do
        "${VSEARCH}" \
            --sintax <(printf ">q\n%s\n" "${SEQ}") \
            --db <(
            printf ">s1;tax=%sA;\n%s\n" "${TAXO}" "${REF2}"
            printf ">s2;tax=%sB;\n%s\n" "${TAXO}" "${REF1}") \
                --quiet \
                --randseed 1 \
                --threads 1 \
                --tabbedout -
    done
}

run_with_fix_seed > "${RESULTS1}"
run_with_fix_seed > "${RESULTS2}"

diff -q "${RESULTS1}" "${RESULTS2}" > /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

rm "${RESULTS1}" "${RESULTS2}"
unset TAXO SEQ REF1 REF2 RESULTS1 RESULTS2 run_with_fix_seed


#******************************************************************************#
#                                                                              #
#    Inconsistent results when using --blast6out or --uc in --usearch_global   #
#                               (issue 580)                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/580

SEQ="CACCGCGGTTATACGAGGGGCTCAAATTGATATT"
REV="AATATCAATTTGAGCCCCTCGTATAACCGCGGTG"  # reverse-complement of SEQ

DESCRIPTION="issue 580: --usearch_global --uc reports best hit by default (single hit)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s\n%s\n" "${SEQ}") \
    --id 1.00 \
    --maxaccepts 0 \
    --quiet \
    --uc - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 580: --usearch_global --uc reports best hit by default (single hit on opposite strand)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s\n%s\n" "${REV}") \
    --id 1.00 \
    --maxaccepts 0 \
    --strand both \
    --quiet \
    --uc - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 580: --usearch_global --uc reports best hit by default (two hits)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}") \
    --id 1.00 \
    --maxaccepts 0 \
    --quiet \
    --uc - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 580: --usearch_global --uc reports best hit by default (hits on both strands)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${REV}") \
    --id 1.00 \
    --maxaccepts 0 \
    --strand both \
    --quiet \
    --uc - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 580: --usearch_global --uc reports best hit by default (two hits on opposite strand)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s1\n%s\n>s2\n%s\n" "${REV}" "${REV}") \
    --id 1.00 \
    --maxaccepts 0 \
    --strand both \
    --quiet \
    --uc - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------- introduce --uc_allhits

DESCRIPTION="issue 580: --usearch_global --uc_allhits reports all hits (single hit)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s\n%s\n" "${SEQ}") \
    --id 1.00 \
    --maxaccepts 0 \
    --quiet \
    --uc_allhits \
    --uc - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 580: --usearch_global --uc_allhits reports all hits (single hit on opposite strand)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s\n%s\n" "${REV}") \
    --id 1.00 \
    --maxaccepts 0 \
    --strand both \
    --quiet \
    --uc_allhits \
    --uc - | \
    awk 'END {exit NR == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 580: --usearch_global --uc_allhits reports all hits (two hits)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}") \
    --id 1.00 \
    --maxaccepts 0 \
    --quiet \
    --uc_allhits \
    --uc - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 580: --usearch_global --uc_allhits reports all hits (hits on both strands)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${REV}") \
    --id 1.00 \
    --maxaccepts 0 \
    --strand both \
    --quiet \
    --uc_allhits \
    --uc - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 580: --usearch_global --uc_allhits reports all hits (two hits on opposite strand)"
"${VSEARCH}" \
    --usearch_global <(printf ">q\n%s\n" "${SEQ}") \
    --db <(printf ">s1\n%s\n>s2\n%s\n" "${REV}" "${REV}") \
    --id 1.00 \
    --maxaccepts 0 \
    --strand both \
    --quiet \
    --uc_allhits \
    --uc - | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset SEQ REV


#******************************************************************************#
#                                                                              #
#             Greengenes2 Database Use with VSEARCH (issue 582)                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/582

## not testable


#******************************************************************************#
#                                                                              #
#     Segmentation fault (core dumped) with --cluster_unoise (issue 583)       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/583

DESCRIPTION="issue 583: --cluster_unoise segmentation fault when there are no clusters"
"${VSEARCH}" \
    --cluster_unoise <(printf ">s\nA\n") \
    --blast6out /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
    failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#            same OTUs identifiers for different samples (issue 585)           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/585

# Can I use vsearch to cluster different samples at the same time and
# have unique otus identifiers appear for all the samples?
DESCRIPTION="issue 585: same OTUs identifiers for different samples"
SAMPLE1=$(mktemp)
SAMPLE2=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sample "sample1" \
        --quiet \
        --fastaout "${SAMPLE1}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sample "sample2" \
        --quiet \
        --fastaout "${SAMPLE2}"

cat "${SAMPLE1}" "${SAMPLE2}" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 0.97 \
        --relabel OTU_ \
        --sizeout \
        --quiet \
        --otutabout - | \
    tr "\t" "@" | \
    grep -qx "OTU_1@1@1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

rm "${SAMPLE1}" "${SAMPLE2}"
unset SAMPLE1 SAMPLE2

# expect:
# #OTU ID	sample1	sample2
# OTU_1	1	1


#******************************************************************************#
#                                                                              #
#   cluster nucleotide sequences with identity=1 but ignoring N (issue 586)    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/586

## context: 100% similarity on whole length (--id 1.0 --iddef 1)
# sequence length: same, different
# mismatch: none, soft (N), hard (different nucleotide)
# position (of the mismatch): 5p, middle, 3p
# order: seed or hit

# notes:
#  - position and order are meaningless when mismatch is none
#  - cluster_size and cluster_smallmem only differ in pre-sorting
#  - length shorter or length longer are mirror cases
#  - length shorter or length longer: there is always a mismatch

clusterize_identical() {
    "${VSEARCH}" \
        --cluster_fast /dev/stdin \
        --minseqlength 1 \
        --qmask none \
        --iddef 1 \
        --id 1.0 \
        --quiet \
        --uc /dev/stdout
}

expect_one_cluster() {
    clusterize_identical | \
        awk '$1 == "C" {count += 1}
             END {exit count == 1 ? 0 : 1}'
}

expect_two_clusters() {
    clusterize_identical | \
        awk '$1 == "C" {count += 1}
             END {exit count == 2 ? 0 : 1}'
}

## ------------------------------------------------------------- positive cases

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: none)"
printf ">s1\nAAA\n>s2\nAAA\n" | \
    expect_one_cluster && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: soft, position: 5p, order: hit)"
printf ">s1\nAAA\n>s2\nNAA\n" | \
    expect_one_cluster && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: soft, position: middle, order: hit)"
printf ">s1\nAAA\n>s2\nANA\n" | \
    expect_one_cluster && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: soft, position: 3p, order: hit)"
printf ">s1\nAAA\n>s2\nAAN\n" | \
    expect_one_cluster && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: soft, position: 5p, order: seed)"
printf ">s1\nNAA\n>s2\nAAA\n" | \
    expect_one_cluster && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: soft, position: middle, order: seed)"
printf ">s1\nANA\n>s2\nAAA\n" | \
    expect_one_cluster && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: soft, position: 3p, order: seed)"
printf ">s1\nAAN\n>s2\nAAA\n" | \
    expect_one_cluster && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- negative cases

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: hard, position: 5p, order: hit)"
printf ">s1\nAAA\n>s2\nTAA\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: hard, position: middle, order: hit)"
printf ">s1\nAAA\n>s2\nATA\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: hard, position: 3p, order: hit)"
printf ">s1\nAAA\n>s2\nAAT\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: hard, position: 5p, order: seed)"
printf ">s1\nTAA\n>s2\nAAA\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: hard, position: middle, order: seed)"
printf ">s1\nATA\n>s2\nAAA\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: same, mismatch: hard, position: 3p, order: seed)"
printf ">s1\nAAT\n>s2\nAAA\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## when length is different, there is always a mismatch
DESCRIPTION="issue 586: cluster identical, ignoring N (length: different, position: 5p, order: hit)"
printf ">s1\nACG\n>s2\nCG\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: different, position: middle, order: hit)"
printf ">s1\nACG\n>s2\nAG\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: different, position: 3p, order: hit)"
printf ">s1\nACG\n>s2\nAC\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: different, position: 5p, order: seed)"
printf ">s1\nCG\n>s2\nACG\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: different, position: middle, order: seed)"
printf ">s1\nAG\n>s2\nACG\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 586: cluster identical, ignoring N (length: different, position: 3p, order: seed)"
printf ">s1\nAC\n>s2\nACG\n" | \
    expect_two_clusters && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset clusterize_identical expect_one_cluster expect_two_clusters

# as expected, substrings are considered as different
DESCRIPTION="issue 586: no clustering of substrings with --iddef 1 --id 1.0"
printf ">s1\nAA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --qmask none \
        --iddef 1 \
        --id 1.0 \
        --quiet \
        --uc - | \
    awk '$1 == "C" {count += 1} END {exit count == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#        Make a fastq_truncee_rate option for fastx_filter (issue 587)         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/587

# for a given position, the expected error rate:
# = (sum of probabilities up to length) / length to position
# = EE / length to position

## --------------------------------------------------------------- fastx_filter

DESCRIPTION="issue 587: --fastx_filter accepts --fastq_truncee_rate"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate accepts null values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 0 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate accepts positive values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate accepts floating values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 1.0 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate rejects negative values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate -1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate rejects non-numerical values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate A \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate rejects empty values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# 'I' = Q40 = 0.0001
DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate (no effect if EE rate is below threshold)"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 0.001 \
        --quiet \
        --fastaout - | \
    grep -qx "AAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '?' = Q30 = 0.001
DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate (no effect if EE rate is equal to threshold)"
printf "@s\nAAA\n+\n???\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 0.001 \
        --quiet \
        --fastaout - | \
    grep -qx "AAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '?' = Q30 = 0.001 ; '>' = Q29 > 0.001
DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate (truncate if EE rate is greater than threshold)"
printf "@s\nAAA\n+\n??>\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 0.001 \
        --quiet \
        --fastaout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate null discards all sequences"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 0 \
        --quiet \
        --fastaout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastx_filter --fastq_truncee_rate rejects fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- fastq_filter

DESCRIPTION="issue 587: --fastq_filter accepts --fastq_truncee_rate"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 1 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate accepts null values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 0 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate accepts positive values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 2 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate accepts floating values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 1.0 \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate rejects negative values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate -1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate rejects non-numerical values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate A \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate rejects empty values"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# 'I' = Q40 = 0.0001
DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate (no effect if EE rate is below threshold)"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 0.001 \
        --quiet \
        --fastaout - | \
    grep -qx "AAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '?' = Q30 = 0.001
DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate (no effect if EE rate is equal to threshold)"
printf "@s\nAAA\n+\n???\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 0.001 \
        --quiet \
        --fastaout - | \
    grep -qx "AAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# '?' = Q30 = 0.001 ; '>' = Q29 > 0.001
DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate (truncate if EE rate is greater than threshold)"
printf "@s\nAAA\n+\n??>\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 0.001 \
        --quiet \
        --fastaout - | \
    grep -qx "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate null discards all sequences"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 0 \
        --quiet \
        --fastaout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 587: --fastq_filter --fastq_truncee_rate rejects fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 1 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#               Fatal error: Illegal option argument (issue 588)               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/588

# "Fatal error: Illegal option argument" is emitted when a numerical
# option receives a value that cannot be parsed as a number. In the
# reported case the value passed to --id was malformed (a user-side
# configuration error, not a vsearch bug). Here we simply document that
# a non-numeric numerical argument is rejected.

DESCRIPTION="issue 588: a non-numeric --id argument triggers 'Illegal option argument'"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGT\n") \
        --id not_a_number \
        --blast6out /dev/null 2>&1 | \
    grep -qF "Illegal option argument" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#           Variable results in pairwise alignment  (issue 589)                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/589

# Using -O3 compilation (specifically -ftree-partial-pre) on
# align_simd.cc introduces a bug in vsearch's sequence pairwise
# alignments. The -O3 option was turned on in commit 6ddea9c on 1
# February 2017, 8 years ago. It was later (in commit d007e76)
# specified at build time.

# Partially fixed in version 2.29.3 by going back to -O2 optimization
# for align_simd.cc.

# expected CIGAR: 'M'; -O3 code gives 'ID'
DESCRIPTION="issue 589: --allpairs_global outputs expected pairwise alignment results"
printf ">s1\nT\n>s2\nG\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --minseqlength 1 \
        --threads 1 \
        --quiet \
        --uc - | \
    awk '/^H/ {exit $8 == "M" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expected CIGAR: '2M'; -O3 code gives 'IMD'
DESCRIPTION="issue 589: --usearch_global outputs expected pairwise alignment results"
"${VSEARCH}" \
    --usearch_global <(printf ">s1\nAA\n") \
    --db <(printf ">s2\nTA\n") \
    --minseqlength 1 \
    --threads 1 \
    --id 0 \
    --wordlength 7 \
    --quiet \
    --uc - | \
    awk '/^H/ {exit $8 == "2M" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expected CIGAR: '=' (since v2.10.4, 'DM2I' before); -O3 code gives 'I2M'
DESCRIPTION="issue 589: --cluster_fast outputs expected pairwise alignment results"
printf ">S1;size=5\nTGT\n>S2;size=1\nCT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --threads 1 \
        --quiet \
        --id 0 \
        --uc - | \
    awk '/^H/ {exit $8 == "=" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expected CIGAR: 'DM2I'; -O3 code gives 'I2M'
DESCRIPTION="issue 589: --cluster_size outputs expected pairwise alignment results"
printf ">S1;size=5\nTGT\n>S2;size=1\nCT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --minseqlength 1 \
        --threads 1 \
        --quiet \
        --id 0 \
        --uc - | \
    awk '/^H/ {exit $8 == "DM2I" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expected CIGAR: 'DM2I'; -O3 code gives 'I2M'
DESCRIPTION="issue 589: --cluster_smallmem outputs expected pairwise alignment results"
printf ">S1;size=5\nTGT\n>S2;size=1\nCT\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --usersort \
        --minseqlength 1 \
        --threads 1 \
        --quiet \
        --id 0 \
        --uc - | \
    awk '/^H/ {exit $8 == "DM2I" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Note: --cluster_unoise did not seem to be impacted by issue #589 (so far)

## --------------------------------------------------- chimera detection

FASTA_INPUT=$(
    # smallest uchime_denovo example? 12 sequences of 32 nucleotides each
    printf ">S1;size=152\n"
    printf "CCGTTGAGTCGGAGCTGCCCTGCGGCACTCCA\n"
    printf ">S2;size=142\n"
    printf "CCTAGTCCACCCGATAGTGCGCGGCACGTTGC\n"
    printf ">S3;size=73\n"
    printf "CATTCCGACTTCCCCGCGTTCTTGGTTGGTCG\n"
    printf ">S4;size=69\n"
    printf "TCCCCGAGTCTGCTCCATAGGCCTTTGAACAC\n"
    printf ">S5;size=50\n"
    printf "TACTCCTTGCTCCGATATGGCCACCCGGTCCG\n"
    printf ">S6;size=33\n"
    printf "GAGAGTCGCCCGCAGCATTCGCACTGCCGGAA\n"
    printf ">S7;size=25\n"
    printf "TCTGGTGCAACAGGGCTCCCAAGCACCCCGAG\n"
    printf ">S8;size=21\n"
    printf "GGCGGAAGTACCTTGACGAGATACACCCTCCG\n"
    printf ">S9;size=14\n"
    printf "CCCGGCCCGGGGCTCCGCGGTGGGGTATTTCT\n"
    printf ">S10;size=8\n"
    printf "TGCCACGGCTCATAGCCAGAGGGTTCGGTCGG\n"
    printf ">S11;size=6\n"
    printf "GGTTGTCATCCGACCAGCCCACGAACTGCGAC\n"
    printf ">S12;size=1\n"
    printf "CGCCGATAACCCCCCCCCTTCCCCTTCGACCC\n")

# When the window size is set to 32 (normal condition), switching to -O3
# produces wrong alignments and wrong chimera scores.
DESCRIPTION="issue 589: --uchime_denovo outputs expected chimera scores"
echo "${FASTA_INPUT}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --sizein \
        --threads 1 \
        --quiet \
        --uchimeout - | \
        tail -n 1 | \
        awk '{exit $1 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 589: --uchime2_denovo outputs expected chimera scores"
echo "${FASTA_INPUT}" | \
    "${VSEARCH}" \
        --uchime2_denovo - \
        --sizein \
        --threads 1 \
        --quiet \
        --uchimeout - | \
        tail -n 1 | \
        awk '{exit $1 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 589: --uchime3_denovo outputs expected chimera scores"
echo "${FASTA_INPUT}" | \
    "${VSEARCH}" \
        --uchime3_denovo - \
        --sizein \
        --threads 1 \
        --quiet \
        --uchimeout - | \
        tail -n 1 | \
        awk '{exit $1 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset FASTA_INPUT


#******************************************************************************#
#                                                                              #
#--top_hits_only missed hits with same identity and query coverage (issue 590) #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/590

# Not a bug: --top_hits_only compares the exact (unrounded) percentages
# of identity. In the report the two hits had the same *displayed*
# identity (rounded to one decimal) but slightly different exact
# identities, so only the truly best one was kept. The complementary
# case where two hits share *exactly* the same identity is covered in
# the issue 603 section below.

DESCRIPTION="issue 590: --top_hits_only keeps only the hit with the strictly highest identity"
SEQ="ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">d1\nTCGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n>d2\nTTGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.5 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --top_hits_only \
        --quiet \
        --userfields target \
        --userout - | \
    tr "\n" " " | \
    grep -qx "d1 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ


#******************************************************************************#
#                                                                              #
#     change in uchime*_denovo results between v2.22 and v2.29 (issue 591)     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/591

# Resolved: from v2.30.0 onwards all three uchime*_denovo algorithms
# implement the UCHIME algorithm correctly. Earlier versions had a
# subtle bug that could wrongly retain a second parent (see issue 606).
# For this input the three algorithms now agree: s3 is not flagged as a
# chimera (score 0.0000, status N).

## original test by Colin Brislawn (https://github.com/qiime2/q2-vsearch/pull/100)
FASTA_INPUT=$(
    printf ">s1;size=5\n"
    printf "AGCTCCAATAGCGTATATTAAAGTTGTTGTGGTTAAAAAGCTCGTAGTTGAACCTTGGGCCTGGCTGGCCGGTCCGCCTC\n"
    printf "ACCGCGTGCACTGGTCCGGCCGGGCCTTTCCCTCTGTGGAACCCCATACCCTTCACTGGGCGTGGCGGGGAAACAGGACA\n"
    printf "TTTACTTTGAAAAAATTAGAGTGCTCCAGGCAGGCCTATGCTCGAATACATTAGCATGGAATAATAAAATAGGACGCGCG\n"
    printf "GTTCTATTTTGTTGGTTTATAGGACCGCCGTAATGATTAATAGGGACAGTCGGGGGCATCAGTATTCAACTGTCAGAGGT\n"
    printf "GAAATTCTTGGATCAGTTGAAGACTAACTACTGCGAAAGCATTTGCCAAGGATGTTTTCA\n"
    printf ">s2;size=3\n"
    printf "AGCTCCAATAGCGTATATTAAAGTTGTTGTGGTTAAAAAGCTCGTAGTTGAACCTTGGGCCTGGCTGGCCGGTCCGCCTC\n"
    printf "ACCGCGTGTACTGGTCCGGCCGGTGAAATTCTTGGATTTATTGAAGACTAACTACTGCGAAAGCATTTGCCAAGGATGTT\n"
    printf "TTCA\n"
    printf ">s3;size=1\n"
    printf "AGCTCCAATAGCGTATATTAAAGTTGTTGTGGTTAAAAAGCTCGTAGTTGAACCTTGGGCCTGGCTGGCCGGTCCGCCTC\n"
    printf "ACCGCGTGCACTGGTCCGGCCGGTGAAATTCTTGGATTTATTGAAGACTAACTACTGCGAAAGCATTTGCCAAGGATGTT\n"
    printf "TTCA\n")

# uchime_denovo: expected results
# 0.0000	s1;size=5	*	*	*	*	*	*	*	*	0	0	0	0	0	0	*	N
# 0.0000	s2;size=3	*	*	*	*	*	*	*	*	0	0	0	0	0	0	*	N
# 0.0000	s3;size=1	*	*	*	*	*	*	*	*	0	0	0	0	0	0	*	N
DESCRIPTION="issue 591: --uchime_denovo produces expected results"
echo "${FASTA_INPUT}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --quiet \
        --uchimeout - | \
    awk 'BEGIN {FS = "\t"} NR == 3 {exit ($1 == 0.0000 && $NF == "N") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# uchime2_denovo: expected results
# 0.0000	s1;size=5	*	*	*	*	*	*	*	*	0	0	0	0	0	0	*	N
# 0.0000	s2;size=3	*	*	*	*	*	*	*	*	0	0	0	0	0	0	*	N
# 0.0000	s3;size=1	*	*	*	*	*	*	*	*	0	0	0	0	0	0	*	N
DESCRIPTION="issue 591: --uchime2_denovo produces expected results"
echo "${FASTA_INPUT}" | \
    "${VSEARCH}" \
        --uchime2_denovo - \
        --quiet \
        --uchimeout - | \
    awk 'BEGIN {FS = "\t"} NR == 3 {exit ($1 == 0.0000 && $NF == "N") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# uchime3_denovo: expected results
# 0.0000	s1;size=5	*	*	*	*	*	*	*	*	0	0	0	0	0	0	*	N
# 0.0000	s2;size=3	*	*	*	*	*	*	*	*	0	0	0	0	0	0	*	N
# 0.0000	s3;size=1	*	*	*	*	*	*	*	*	0	0	0	0	0	0	*	N
DESCRIPTION="issue 591: --uchime3_denovo produces expected results"
echo "${FASTA_INPUT}" | \
    "${VSEARCH}" \
        --uchime3_denovo - \
        --quiet \
        --uchimeout - | \
    awk 'BEGIN {FS = "\t"} NR == 3 {exit ($1 == 0.0000 && $NF == "N") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset FASTA_INPUT


#******************************************************************************#
#                                                                              #
#   Feature request: change --top_hits_only to --top_N_hits_only (issue 592)   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/592

# Feature request to add a --top_N_hits_only N option (keep the N best
# hits). Not implemented: --top_hits_only keeps all hits that share the
# single best identity (see issues 590 and 603). There is nothing to
# test.


#******************************************************************************#
#                                                                              #
#     Element Biosciences AVITI reads can't be PE merged despite good overlap  #
#           and least conservative merging settings (issue 593)                #
#                                                                              #
#******************************************************************************#
#
## https://github.com/torognes/vsearch/issues/593

# question, nothing to test


#******************************************************************************#
#                                                                              #
#      confusing output from --uchime_ref chimera removal (issue 594)          #
#                                                                              #
#******************************************************************************#
#
## https://github.com/torognes/vsearch/issues/594

DESCRIPTION="issue 594: --uchime_denovo reports name of the input file"
TMP_FASTA=$(mktemp)
printf ">s\nT\n" > "${TMP_FASTA}"
"${VSEARCH}" \
    --uchime_denovo "${TMP_FASTA}" \
    --uchimeout /dev/null 2>&1 | \
    grep -q "^Reading file ${TMP_FASTA}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

rm -f "${TMP_FASTA}"
unset TMP_FASTA

# --uchime_ref does not report the name of the input file! It reports
# the name and stats of the database file, which may be confusing
DESCRIPTION="issue 594: --uchime_ref reports name of the database file"
TMP_FASTA=$(mktemp)
TMP_DB=$(mktemp)
printf ">s\nT\n" > "${TMP_FASTA}"
printf ">s\nT\n" > "${TMP_DB}"
"${VSEARCH}" \
    --uchime_ref "${TMP_FASTA}" \
    --db "${TMP_DB}" \
    --uchimeout /dev/null 2>&1 | \
    grep -q "^Reading file ${TMP_DB}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

rm -f "${TMP_FASTA}" "${TMP_DB}"
unset TMP_FASTA TMP_DB


#******************************************************************************#
#                                                                              #
#   Identical sequences are assigned to different clusters in the result of    #
#                       --cluster_fast (issue 595)                             #
#                                                                              #
#******************************************************************************#
#
## https://github.com/torognes/vsearch/issues/595

# In this example provided by GitHub user @tao-bioinfo, sB and sD are
# identical (100% similar), yet they are assigned to two different
# clusters (sA and sC). I was not able to reproduce this with shorter
# sequences. Maybe it depends on k-mer prefiltering?

# Note: using --maxaccepts 0 --maxrejects 0 has no effect on that
# particular case.

## pairwise similarities:
# sB	sD	100.0
# sB	sC	97.6
# sA	sB	97.0
# sA	sD	97.0
# sA	sC	95.8
# sC	sD	97.6

## expect two hits (H) to two different seeds (S):
# H	0	168	97.0	+	0	0	168M	sB	sA
# H	1	168	97.6	+	0	0	168M	sD	sC
DESCRIPTION="issue 595: --cluster_fast identical sequences can be in different clusters"
(
    printf ">sA\nATGCCCCAACTCAACCCCGCACCCTGGCTTGCCATCCTAGTCTTCTCTTGATTAGTTTTCCTAATCGTTATTCCTCCAAAAGTTATAGCCCATTCCTTCCCAAATGAACCGACCCCCCAAAGCACAGAAAAACCTAAAGGGGAACCCTGAAACTGACCATGACACTAA\n"
    printf ">sB\nATGCCCCAACTCAATCCCGCACCCTGGCTTGCCATCCTAGTCTTCTCTTGATTAGTTTTCCTAATCGTTATTCCTCCAAAAGTTATAGCCCACTCTTTCCCAAATGAACCAACCCCTCAAAGCACAGAAAAACCTAAAGGGGAACCCTGAAACTGACCATGACACTAA\n"
    printf ">sC\nATGCCCCAACTCAATCCCGCACCCTGGCTTGCCATCCTAGTCTTCTCTTGATTAGTTTTCCTAATCGTCATCCCTCCAAAAGTTATAGCCCACTCCTTCCCAAACGAACCAACCCCTCAAAGCACAGAAAAACCTAAAGGGGAACCCTGAAACTGACCATGACACTAA\n"
    printf ">sD\nATGCCCCAACTCAATCCCGCACCCTGGCTTGCCATCCTAGTCTTCTCTTGATTAGTTTTCCTAATCGTTATTCCTCCAAAAGTTATAGCCCACTCTTTCCCAAATGAACCAACCCCTCAAAGCACAGAAAAACCTAAAGGGGAACCCTGAAACTGACCATGACACTAA\n"
) | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --quiet \
        --uc - | \
    grep "^H" | \
    cut -f 10 | \
    sort -u | \
    awk 'END {exit NR == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#            --search_exact rejects UDB database (issue 596)                   #
#                                                                              #
#******************************************************************************#
#
## https://github.com/torognes/vsearch/issues/596

# command --search_exact does not support UDB files (documentation)

SEQ=$(printf ">s\nACTGGCTAACTGGCTAACTGGCTAACTGGCTA\n")

DESCRIPTION="issue 596: --search_exact accepts fasta database"
"${VSEARCH}" \
    --search_exact <(echo "${SEQ}") \
    --db <(echo "${SEQ}") \
    --quiet \
    --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 596: --search_exact rejects UDB database"
UDB=$(mktemp)
"${VSEARCH}" \
    --makeudb_usearch <(echo "${SEQ}") \
    --quiet \
    --output "${UDB}"
"${VSEARCH}" \
    --search_exact <(echo "${SEQ}") \
    --db "${UDB}" \
    --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

rm -f "${UDB}"
unset SEQ TMP


#******************************************************************************#
#                                                                              #
#    Add swarm-like tabular output to vsearch clustering options (issue 597)   #
#                                                                              #
#******************************************************************************#
#
## https://github.com/torognes/vsearch/issues/597

# question, nothing to test


#******************************************************************************#
#                                                                              #
#   Lowercases in centroids sequences when using --cluster_fast (issue 598)    #
#                                                                              #
#******************************************************************************#
#
## https://github.com/torognes/vsearch/issues/598

# Lowercase output is due to masking. Masking is automatically applied
# during chimera detection, clustering, masking, pairwise alignment
# and searching. The DUST algorithm masks simple repeats and
# low-complexity regions.

DESCRIPTION="issue 598: --cluster_fast DUST masking by default"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --quiet \
        --centroids - | \
    grep -qx "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="issue 598: --cluster_fast --qmask none (no masking)"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --quiet \
        --qmask none \
        --centroids - | \
    grep -qx "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#           command --makeudb_usearch cannot write to stdout? (issue 599)      #
#                                                                              #
#******************************************************************************#
#
## https://github.com/torognes/vsearch/issues/599

# command can read from a pipe and write to a file
DESCRIPTION="issue 599: --makeudb_usearch can write to a file"
TMP_OUTPUT="$(mktemp)"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --quiet \
        --output "${TMP_OUTPUT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP_OUTPUT}"
unset TMP_OUTPUT

# command can read from a pipe and write to a pipe
# currently:
# Fatal error: Unable to seek in UDB file or invalid UDB file
DESCRIPTION="issue 599: --makeudb_usearch can write to a stream"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --quiet \
        --output /dev/stdout > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#       vsearch --cluster_fast --strand plus/both behaviour (issue 600)        #
#                                                                              #
#******************************************************************************#
#
## https://github.com/torognes/vsearch/issues/600

## In issue 600, offset (shifted) repeats cluster together because the
## shared core aligns perfectly while the non-overlapping ends are
## absorbed by terminal gaps, which are cheap by default. The cost of
## terminal gaps can be raised with the gap-penalty notation
## (vsearch-pairwise_alignment_parameters(7)): the 'E' (extremities)
## symbol sets both terminal contexts at once, 'I' sets internal gaps.

## s1 and s2 share a 20 nt core ("A"x20) but carry distinct 10 nt
## ends. With the default (cheap) terminal gap penalties, the optimal
## alignment uses terminal gaps and reaches 100% identity (terminal
## gaps are excluded from the default identity definition).
DESCRIPTION="issue 600: cheap terminal gaps let offset repeats align at 100%"
printf ">s1\nGGGGGGGGGGAAAAAAAAAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAAAAAAAAAACCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields id \
        --userout - | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Raising the terminal gap penalties (--gapopen 20I/40E and --gapext
## 2I/10E increase the cost of opening and extending terminal gaps)
## makes terminal gaps too expensive: the aligner then prefers an
## end-to-end alignment with mismatches, and the reported identity
## drops well below 100%.
DESCRIPTION="issue 600: expensive terminal gaps prevent offset repeats from aligning at 100%"
printf ">s1\nGGGGGGGGGGAAAAAAAAAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAAAAAAAAAACCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --gapopen 20I/40E \
        --gapext 2I/10E \
        --userfields id \
        --userout - | \
    grep -qx "100.0" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"



#******************************************************************************#
#                                                                              #
#            how to merge fasta sequences that are exact substrings            #
#                   of longer sequences? (issue 601)                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/601

## Goal: options to use to find and merge all fasta entries that are
## exact substrings of longer entries

## Relevant options and parameters:
# --iddef 0 (similarity percentage = (matching columns) / (shortest sequence length))
# --id 1.0 (only merge when shortest sequence is fully aligned with the target, without mismatches)
# --maxdiffs 0 (reject query if it contains gaps)

# expect a 'hit' (H)
DESCRIPTION="issue 601: --cluster_fast merge all substrings (same sequences)"
printf ">s1\nACGT\n>s2\nACGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expect no 'hit' (H)
DESCRIPTION="issue 601: --cluster_fast merge all substrings (different sequences, 5' mismatch)"
printf ">s1\nACGT\n>s2\nTCGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# expect no 'hit' (H)
DESCRIPTION="issue 601: --cluster_fast merge all substrings (different sequences, middle mismatch)"
printf ">s1\nACGT\n>s2\nAGGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# expect no 'hit' (H)
DESCRIPTION="issue 601: --cluster_fast merge all substrings (different sequences, 3' mismatch)"
printf ">s1\nACGT\n>s2\nACGA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (same sequences, reverse strand)"
printf ">s1\nAAAA\n>s2\nTTTT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --strand "both" \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expect no 'hit' (H)
DESCRIPTION="issue 601: --cluster_fast merge all substrings (different sequences)"
printf ">s1\nAAAA\n>s2\nTTCT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --strand "both" \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (prefix)"
printf ">s1\nAAACC\n>s2\nAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (prefix, mismatch in 5')"
printf ">s1\nAAACC\n>s2\nTAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (prefix, mismatch in middle)"
printf ">s1\nAAACC\n>s2\nATA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (prefix, mismatch in 3')"
printf ">s1\nAAACC\n>s2\nAAT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (prefix, reverse strand)"
printf ">s1\nAAACC\n>s2\nTTT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --strand "both" \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (suffix)"
printf ">s1\nCCAAA\n>s2\nAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (suffix, mismatch in 5')"
printf ">s1\nCCAAA\n>s2\nTAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (suffix, mismatch in middle)"
printf ">s1\nCCAAA\n>s2\nATA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (suffix, mismatch in 3')"
printf ">s1\nCCAAA\n>s2\nAAT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (suffix, reverse strand)"
printf ">s1\nCCAAA\n>s2\nTTT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --strand "both" \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (substring)"
printf ">s1\nCCAAACC\n>s2\nAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (substring, mismatch in 5')"
printf ">s1\nCCAAACC\n>s2\nTAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (substring, mismatch in middle)"
printf ">s1\nCCAAACC\n>s2\nATA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (substring, mismatch in 3')"
printf ">s1\nCCAAACC\n>s2\nAAT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (substring, reverse strand)"
printf ">s1\nCCAAACC\n>s2\nTTT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --strand "both" \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expect no hit. Overhang is the same as a mismatch in 5'
DESCRIPTION="issue 601: --cluster_fast merge all substrings (overhang, no merge)"
printf ">s1\nCCAA\n>s2\nGCC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## With iddef 0, gaps in the query are not taken into account when computing similarity
## sequences are merged, even though the query is not an exact substring
# Qry  1 + GGTTCGACGGC---CTGCGCCCCGATGAG 26
#          |||||||||||   |||||||||||||||
# Tgt  1 + GGTTCGACGGCAAACTGCGCCCCGATGAG 29
DESCRIPTION="issue 601: --cluster_fast merge all substrings (gaps in substring do not count)"
printf ">s1\nGGTTCGACGGCAAACTGCGCCCCGATGAGA\n>s2\nGGTTCGACGGCCTGCGCCCCGATGAG\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (prohibit gaps with --gapopen *)"
printf ">s1\nGGTTCGACGGCAAACTGCGCCCCGATGAGA\n>s2\nGGTTCGACGGCCTGCGCCCCGATGAG\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --gapopen "*" \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# reverse strand
DESCRIPTION="issue 601: --cluster_fast merge all substrings (gaps in substring do not count, reverse strand)"
printf ">s1\nGGTTCGACGGCAAACTGCGCCCCGATGAGA\n>s2\nCTCATCGGGGCGCAGGCCGTCGAACC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --strand "both" \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (prohibit gaps with --gapopen *, reverse strand)"
printf ">s1\nGGTTCGACGGCAAACTGCGCCCCGATGAGA\n>s2\nCTCATCGGGGCGCAGGCCGTCGAACC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --gapopen "*" \
        --strand "both" \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## gap in target, no merging
DESCRIPTION="issue 601: --cluster_fast merge all substrings (gaps in substring do not count)"
printf ">s1\nGGTTCGACGGCAAACTGCGCCCCGATGAGAGAGA\n>s2\nGGTTCGACGGAAAACCTGCGCCCCGATGAG\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (prohibit gaps with --maxgaps 0)"
printf ">s1\nGGTTCGACGGCAAACTGCGCCCCGATGAGA\n>s2\nGGTTCGACGGCCTGCGCCCCGATGAG\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --maxgaps 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 601: --cluster_fast merge all substrings (prohibit gaps with --maxdiffs 0)"
printf ">s1\nGGTTCGACGGCAAACTGCGCCCCGATGAGA\n>s2\nGGTTCGACGGCCTGCGCCCCGATGAG\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --id 1.0 \
        --iddef 0 \
        --maxdiffs 0 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#   --gapopen *: increase default value from 1,000 to INT_MAX? (issue 602)     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/602

## expect no merging

# Qry   1 + TTTTTCCTTATGCGTTCCTTTGTTGTTCTCGCAATGTGCGTAATCTAGGTTTCTTAGTAACGCC 64
#           ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
# Tgt   1 + TTTTTCCTTATGCGTTCCTTTGTTGTTCTCGCAATGTGCGTAATCTAGGTTTCTTAGTAACGCC 64
#
# Qry  65 + GCCCACGGTCCTTACCTTATTAACCCTACACCCTTGCCCTTTT-CCCCCCCCCCCTTCTTCCCG 127
#           ||||||||||||||||||||||||||||||||||||||||||| ||||||||||||||||||||
# Tgt  65 + GCCCACGGTCCTTACCTTATTAACCCTACACCCTTGCCCTTTTCCCCCCCCCCCCTTCTTCCCG 128
#
# Qry 128 + ACCTCTGTGCCTAGGGTGTCTCCAGTGTCCCTCCGCGCCCTGTCCCTCGTTTGTTCCCCCCCCG 191
#           ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
# Tgt 129 + ACCTCTGTGCCTAGGGTGTCTCCAGTGTCCCTCCGCGCCCTGTCCCTCGTTTGTTCCCCCCCCG 192
#
# Qry 192 + CGTTTCTGCTATCCCGTTCCATTCTTTCCGATTCACATCGGCC 234
#           |||||||||||||||||||||||||||||||||||||||||||
# Tgt 193 + CGTTTCTGCTATCCCGTTCCATTCTTTCCGATTCACATCGGCC 235

# 235 cols, 234 ids (100.0%), 1 gaps (0.4%)

## With the old default "infinite" penalty value of 1,000, these
## sequences were merged. Commit 96e9cf9e sets the "infinite" penalty
## value to INT_MAX
DESCRIPTION="issue 602: --cluster_fast --gapopen infinite (raise from 1,000 to INT_MAX)"
(
    printf ">s1\n"
    printf "TTTTTCCTTATGCGTTCCTTTGTTGTTCTCGCAATGTGCGTAATCTAGGTTTCTTAGTAACGCCGCCCACGGTCCTTACCTTATTAACCCTACACCCTTGCCCTTTTCCCCCCCCCCCCTTCTTCCCGACCTCTGTGCCTAGGGTGTCTCCAGTGTCCCTCCGCGCCCTGTCCCTCGTTTGTTCCCCCCCCGCGTTTCTGCTATCCCGTTCCATTCTTTCCGATTCACATCGGCC"
    printf "\n"
    printf ">s2\n"
    printf "TTTTTCCTTATGCGTTCCTTTGTTGTTCTCGCAATGTGCGTAATCTAGGTTTCTTAGTAACGCCGCCCACGGTCCTTACCTTATTAACCCTACACCCTTGCCCTTTTCCCCCCCCCCCTTCTTCCCGACCTCTGTGCCTAGGGTGTCTCCAGTGTCCCTCCGCGCCCTGTCCCTCGTTTGTTCCCCCCCCGCGTTTCTGCTATCCCGTTCCATTCTTTCCGATTCACATCGGCC"
    printf "\n"
) | \
    ${VSEARCH} \
        --cluster_fast - \
        --qmask "none" \
        --iddef 0 \
        --id 1.00 \
        --gapopen "*" \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#      Multiple taxonomy hits per OTU despite --top_hits_only (issue 603)      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/603

# Expected behaviour: when several targets share *exactly* the same
# (best) identity, --top_hits_only keeps them all. To obtain a single
# assignment per query, use --maxaccepts 1 or an OTU table. See also
# issue 590.

DESCRIPTION="issue 603: --top_hits_only keeps all targets sharing the same best identity"
SEQ="ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">d1\nTCGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n>d2\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGA\n") \
        --id 0.5 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --top_hits_only \
        --quiet \
        --userfields target \
        --userout - | \
    sort | \
    tr "\n" " " | \
    grep -qx "d1 d2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ


#******************************************************************************#
#                                                                              #
#             Default parameters for pairwise alignment (issue 604)            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/604

# question, nothing to test


#******************************************************************************#
#                                                                              #
#       Update map.pl in wiki vsearch pipeline instructions (issue 605)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/605

# Suggestion to fix a regular expression in the map.pl script of the
# VSEARCH wiki pipeline. This concerns documentation/wiki material, not
# the vsearch binary; there is nothing to test here.


#******************************************************************************#
#                                                                              #
#possible change in uchime*_denovo results between v2.22 and v2.30 (issue 606) #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/606

# uchime*_denovo results changed between v2.22 and v2.30. The developer
# confirmed that the newer behaviour is the correct implementation of
# the UCHIME algorithm (earlier versions had a subtle bug that could
# wrongly retain a second parent). Same topic as issue 591; see the
# (currently commented-out) tests in the issue 591 section above.


#******************************************************************************#
#                                                                              #
#       Can vsearch --uchine_denovo take multithreads option ? (issue 608)     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/608

# question, already tested in uchime_denovo.sh


#******************************************************************************#
#                                                                              #
#             How to set --fastq_qmax for AVITI reads? (issue 610)             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/610

# How-to question about setting --fastq_qmax for Element Biosciences
# AVITI reads (quality values above the default range) during
# --fastq_mergepairs. No bug; there is nothing to test.


#******************************************************************************#
#                                                                              #
#              Median cluster size always 0? #611 (issue 611)                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/611

# - bug introduced in v2.30.1,
# - commands --derep_smallmem and --derep_prefix were not affected,
# - test added to derep_fulllength.sh, derep_id.sh, and fastx_unique.sh


#******************************************************************************#
#                                                                              #
#   cluster_fast command: inaccurate counting of sequences from dereplication  #
#                    to clustering at 100% similarity (issue 612)              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/612

# question, terminal differences are ignored by default

DESCRIPTION="issue 612: --cluster_fast --id 1.00 (expect no clustering)"
(
    ## entries diverge by a single T in 5' position
    echo ">FT100067221L1C001R00101536038"
    echo "CGCCGGTGCTGAGCCACTGGCGCCGGACCACCGACTTCTGCGGCACGGCGACACGGTGACGCAGCTGCACATCGCCGGCGTCCGCGGCGCGCCGCCGCTCCCG"
    echo ">FT100067221L1C002R00500601972"
    echo "TCGCCGGTGCTGAGCCACTGGCGCCGGACCACCGACTTCTGCGGCACGGCGACACGGTGACGCAGCTGCACATCGCCGGCGTCCGCGGCGCGCCGCCGCTCCCG"
) | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 1.00 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 612: --cluster_fast --id 1.00 --iddef 1 (expect clustering)"
(
    ## entries diverge by a single T in 5' position
    echo ">FT100067221L1C001R00101536038"
    echo "CGCCGGTGCTGAGCCACTGGCGCCGGACCACCGACTTCTGCGGCACGGCGACACGGTGACGCAGCTGCACATCGCCGGCGTCCGCGGCGCGCCGCCGCTCCCG"
    echo ">FT100067221L1C002R00500601972"
    echo "TCGCCGGTGCTGAGCCACTGGCGCCGGACCACCGACTTCTGCGGCACGGCGACACGGTGACGCAGCTGCACATCGCCGGCGTCCGCGGCGCGCCGCCGCTCCCG"
) | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 1.00 \
        --iddef 1 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#         option to print progress indicator line by line (issue 613)          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/613

# Feature request to print the progress indicator line by line, so that
# a calling process (e.g. a Python script) can capture progress. Not a
# bug; there is nothing to test.


#******************************************************************************#
#                                                                              #
#     --chimeras_denovo leads to segmentation fault in v2.30.2 (issue 615)     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/615

# --chimeras_denovo (an experimental command) could segfault on certain
# inputs because of a memory-allocation bug caused by miscomputed
# sequence lengths. Fixed in commit 3bc3a87 (v2.30.3). The crash was
# triggered by a specific large dataset that could not be reduced to a
# minimal reproducible example; no small regression test is available.


#******************************************************************************#
#                                                                              #
#  uchime_denovo score different in the fasta file and statistics file (issue  #
#                                     617)                                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/617

# With --uchime_denovo, the score written in the --fasta_score header of
# non-chimeric sequences could be non-zero in some cases when it should
# have been zero (the non-chimeric N/Y status itself was always
# correct). Fixed in commit 2b699b6 (v2.30.4). The bug was reported on a
# specific dataset that could not be reduced to a minimal reproducible
# example; no small regression test is available.


#******************************************************************************#
#                                                                              #
#         userfield trow not working in version 2.30.4 (issue 618)             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/618

# out-of-bound look-ups when printing alignment rows

# The issue had no effect on the alignment results, only on their
# visualization (print).

# The issue was introduced with commit 2196870 and has been present
# since release v2.30.1.

# Root cause: the same index was used for scanning both source sequence
# and destination sequence (aka, the alignment row). This is wrong
# because gaps can be introduced in the destination sequence. Once a gap
# has been introduced, the index is updated, which skips part of the
# source sequence that should not be skipped. It can also lead to
# out-of-bounds reads.

## note: issue first reported for --usearch_global, but tests are done
## with --allpairs_global (easier)

## show that cigar strings are built from the view-point of the target

# insertion in target -> cigar: IM
DESCRIPTION="issue 618: cigar strings are relative to the target sequence (insertion)"
printf ">query\nT\n>target\nTT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields caln \
        --userout - | \
    grep -qx "IM" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# deletion in target -> cigar: DM
DESCRIPTION="issue 618: cigar strings are relative to the target sequence (deletion)"
printf ">query\nTT\n>target\nT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields caln \
        --userout - | \
    grep -qx "DM" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## note: terminal gaps are not represented in pairwise alignments
# insertion in target -> cigar: IM -> deletion in qrow
DESCRIPTION="issue 618: deletion in query, userout qrow is correct"
printf ">query\nT\n>target\nTT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields qrow \
        --userout - | \
    grep -qx "T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# insertion in target -> cigar: IM -> insertion in trow
DESCRIPTION="issue 618: insertion in target, userout trow is correct"
printf ">query\nT\n>target\nTT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields trow \
        --userout - | \
    grep -qx "T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# deletion in target -> cigar: DM -> insertion in qrow
DESCRIPTION="issue 618: deletion in target, userout qrow is correct"
printf ">query\nTT\n>target\nT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields qrow \
        --userout - | \
    grep -qx "T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# deletion in target -> cigar: DM -> deletion in trow
DESCRIPTION="issue 618: insertion in target, userout trow is correct"
printf ">query\nTT\n>target\nT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields trow \
        --userout - | \
    grep -qx "T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## note: internal gaps are represented in pairwise alignments
# insertion in target -> cigar: 4M4I4M -> deletion in qrow
DESCRIPTION="issue 618: deletion in query, userout qrow is correct (middle gap)"
printf ">query\nAAAATTTT\n>target\nAAAAGGGGTTTT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields qrow \
        --userout - | \
    grep -qx "AAAA----TTTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# insertion in target -> cigar: 4M4I4M -> insertion in trow
DESCRIPTION="issue 618: insertion in target, userout trow is correct (middle gap)"
printf ">query\nAAAATTTT\n>target\nAAAAGGGGTTTT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields trow \
        --userout - | \
    grep -qx "AAAAGGGGTTTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# deletion in target -> cigar: 4M4D4M -> insertion in qrow
DESCRIPTION="issue 618: deletion in target, userout qrow is correct (middle gap)"
printf ">query\nAAAAGGGGTTTT\n>target\nAAAATTTT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields qrow \
        --userout - | \
    grep -qx "AAAAGGGGTTTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# deletion in target -> cigar: 4M4D4M -> deletion in trow
DESCRIPTION="issue 618: insertion in target, userout trow is correct (middle gap)"
printf ">query\nAAAAGGGGTTTT\n>target\nAAAATTTT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields trow \
        --userout - | \
    grep -qx "AAAA----TTTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Query alignment output (--userfields qrow) not correct in --usearch_global  #
#                  (version 2.30.1+)  (issue 618)                              #
#                                                                              #
#******************************************************************************#
#
## https://github.com/torognes/vsearch/issues/619

# same as issue 618


# **************************************************************************** #
#                                                                              #
#                    Single linkage clustering (issue 620)                     #
#                                                                              #
# **************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/620

# not testable


# **************************************************************************** #
#                                                                              #
#                       Read demultiplexing (issue 621)                        #
#                                                                              #
# **************************************************************************** #
##
## https://github.com/torognes/vsearch/issues/621

# not testable


#******************************************************************************#
#                                                                              #
#         Segmentation fault : LCA taxonomy classification (issue 622)         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/622

# Wen using the --lcaout option, vsearch --usearch_global can crash
# (segmentation fault) if there are no hits for a query.

DESCRIPTION="issue 622: --usearch_global --lcaout (single hit, query + tab + taxa)"
SEQ="TGATACATAGTATCGTCACATGAAAGGATTGG"
"${VSEARCH}" \
    --usearch_global <(printf ">s1\n%s\n" "${SEQ}") \
    --db <(printf ">s1;tax=k:K,p:P\n%s\n" "${SEQ}") \
    --threads 1 \
    --quiet \
    --id 0.97 \
    --lcaout - | \
    tr "\t" "@" | \
    grep -q "^s1@k:K,p:P$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="issue 622: --usearch_global --lcaout (no hit, no issue)"
SEQ1="TGATACATAGTATCGTCACATGAAAGGATTGG"
SEQ2="CCAATCCTTTCATGTGACGATACTATGTATCA"
"${VSEARCH}" \
    --usearch_global <(printf ">s1\n%s\n" "${SEQ1}") \
    --db <(printf ">s1;tax=k:K,p:P\n%s\n" "${SEQ2}") \
    --threads 1 \
    --quiet \
    --id 0.97 \
    --lcaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ1 SEQ2


DESCRIPTION="issue 622: --usearch_global --lcaout (no hit, query + tab)"
SEQ1="TGATACATAGTATCGTCACATGAAAGGATTGG"
SEQ2="CCAATCCTTTCATGTGACGATACTATGTATCA"
"${VSEARCH}" \
    --usearch_global <(printf ">s1\n%s\n" "${SEQ1}") \
    --db <(printf ">s1;tax=k:K,p:P\n%s\n" "${SEQ2}") \
    --threads 1 \
    --quiet \
    --id 0.97 \
    --lcaout - | \
    tr "\t" "@" | \
    grep -q "^s1@$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ1 SEQ2


#******************************************************************************#
#                                                                              #
#         Saturate k-mer match counter to avoid wraparound (issue 630)         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/630

# The per-target shared-k-mer counter (count_t, an unsigned short) in
# search_topscores was incremented with a plain ++ on the sparse-list
# path. A query sharing more than 65535 distinct k-mers with one target
# wraps that counter back toward 0; the wrapped value can fall below
# minwordmatches, silently dropping the true best target from the
# candidate set. The fix saturates the increment at INT16_MAX (32767),
# matching the SIMD bitmap path.
#
# The test below reproduces the regression, but it is SLOW (~23 s) and
# is therefore kept commented out, as documentation of how to exercise
# the bug. The overflow needs a query sharing >65535 distinct k-mers
# with a target, i.e. two sequences of ~75 kb; confirming the fix then
# requires aligning that ~75 kb self-match. (The candidate-rejection
# path the bug triggers is fast, but the correct path is a full O(L^2)
# alignment, which dominates the runtime.)
#
# The scalar (sparse-list) path is forced with 16 db sequences: a k-mer
# present in a single target then has count 1 < 16/8 = 2, below the
# bitmap threshold. minwordmatches (20000) sits between the wrapped
# value (~distinct - 65536 = ~9286) and the saturation cap (32767): a
# correct vsearch keeps the target (32767 >= 20000) and reports the
# self-match; a wrapping vsearch drops it.
#
# DESCRIPTION="issue 630: k-mer match counter saturates instead of wrapping at 65536"
# DB=$(mktemp)
# QUERY=$(mktemp)
# # DB: one high-diversity target (75000 bp, ~74800 distinct 12-mers)
# # followed by 15 short dummies, for 16 sequences total.
# awk 'BEGIN{
#        b = "ACGT"; srand(1);
#        printf ">T0\n";
#        for (i = 0; i < 75000; i++) printf "%s", substr(b, int(rand() * 4) + 1, 1);
#        printf "\n";
#        for (d = 1; d <= 15; d++) {
#          printf ">dummy%d\n", d;
#          for (i = 0; i < 50; i++) printf "%s", substr(b, int(rand() * 4) + 1, 1);
#          printf "\n";
#        }
#      }' > "${DB}"
# # query is a copy of the big target
# awk '/^>T0$/ {p = 1; print; next} /^>/ {p = 0} p' "${DB}" > "${QUERY}"
# "${VSEARCH}" \
#     --usearch_global "${QUERY}" \
#     --db "${DB}" \
#     --id 0.9 \
#     --wordlength 12 \
#     --minwordmatches 20000 \
#     --maxseqlength 100000 \
#     --qmask none \
#     --dbmask none \
#     --quiet \
#     --userfields query+target \
#     --userout - 2>/dev/null | \
#     grep -qx "T0	T0" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"
# rm -f "${DB}" "${QUERY}"


exit 0


# DONE: issues 1-622 (issues 86, 118, 132, 159, 185, 202, 218, 229, 239, 263, 265, 271, 282, 309, 314, 316, 332, 400, 415, 417, 423, 461, 465, 487, 496, 504, 522, 524, 548, 564, 569, 570, 584, 607, 609, 614 still open)
#
# note: issue 547 reports that --usearch_global may prefer a longer
# target with a worse raw score, mismatch count and percent identity.
# This is driven by the kmer-based candidate selection and ordering
# heuristic used to pick which targets to align, which is an internal
# implementation detail not specified in the manpage. The resulting
# ranking cannot be predicted from the documented parameters alone, so
# no deterministic black-box test is written for it: any assertion
# would lock in undocumented heuristic behaviour rather than a
# specified contract. Left as a documented open question for upstream.