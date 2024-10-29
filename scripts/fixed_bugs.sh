#!/bin/bash -

## Print a header
SCRIPT_NAME="Fixed bugs"
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
    --db <(for i in {1..8} ; do printf ">s\nGTCGCTCCTA\n" ; done) \
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
        --fastaout ${SAMPLE1}
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sample "sample2-ITS1-good" \
        --quiet \
        --fastaout ${SAMPLE2}

cat ${SAMPLE1} ${SAMPLE2} | \
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
rm ${SAMPLE1} ${SAMPLE2}
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
    --db <(for i in {1..32} ; do
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
    grep -wq "${q1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

q1="AAAAAAA"
DESCRIPTION="issue 6: sequence masking (shortest unmasked)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" ${q1}) \
    --quiet \
    --output - | \
    grep -wq "${q1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## DUST masking sets to lowercase
q1="AAAAAAAA"  # minimal length is 8?
DESCRIPTION="issue 6: sequence masking (shortest masked)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" ${q1}) \
    --quiet \
    --output - | \
    grep -wq "${q1,,}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## mix case is converted to uppercase
q1="AaAaAaA"
DESCRIPTION="issue 6: sequence masking (shortest unmasked, mixed case)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" ${q1}) \
    --quiet \
    --output - | \
    grep -wq "${q1^^}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## masked mix case is converted to lowercase
q1="AaAaAaAa"
DESCRIPTION="issue 6: sequence masking (shortest masked, mixed case)"
"${VSEARCH}" \
    --maskfasta <(printf ">q1\n%s\n" ${q1}) \
    --quiet \
    --output - | \
    grep -wq "${q1,,}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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
    grep -Ewq "[ACGT]+${masked_region}[ACGT]+" && \
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
    grep -Ewq "[ACGT]+${masked_region_rev_comp}[ACGT]+" && \
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
    grep -Ewq "${masked_region}" && \
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
    grep -Ewq "[ACGT]+" && \
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
    grep -qw ">s1;size=2" && \
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
    grep -qw ">s1;size=2" && \
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
    grep -qw ">s1;size=2" && \
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
    grep -qw ">s1;size=2" && \
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
    grep -qw ">s1;size=2" && \
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
    grep -qw ">s1;size=2" && \
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
    grep -qw ">t1;size=2" && \
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
    grep -qw ">t1;size=2" && \
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
    grep -qw ">t1;size=2" && \
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
    grep -qw ">chimeraAB;size=1" && \
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
    grep -qw ">chimeraAB" && \
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
    grep -q "vsearch --help" && \
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
    grep -qw "8" && \
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
    grep -qw "1" && \
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
    grep -qw "1" && \
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
    grep -qw "4" && \
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
    grep -qw "2" && \
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
    grep -qw "1" && \
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
    grep -qw "3" && \
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
    grep -qw "4" && \
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
    grep -qw "4" && \
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
    grep -qw "50.0" && \
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
    grep -qw "28.6" && \
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
    grep -qw "100.0" && \
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
    grep -qw "60.0" && \
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
    grep -qw "28.6" && \
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
    grep -qw "query" && \
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
    grep -qw "^Qry" && \
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
    --db <(for i in {1..32} ; do printf ">t%d\nAAT\n" $i ; done ; printf ">t33\nAAA\n") \
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
    --db <(for i in {1..31} ; do printf ">t%d\nAAT\n" $i ; done ; printf ">t33\nAAA\n") \
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
    grep -qw ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength sorts ties by decreasing abundance"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=1\nAA\n>s2;size=2\nTT\n") \
    --quiet \
    --sizein \
    --output - | \
    head -n 1 | \
    grep -qw ">s2;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength sorts ties by decreasing abundance (--sizein is implied)"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=1\nAA\n>s2;size=2\nTT\n") \
    --quiet \
    --output - | \
    head -n 1 | \
    grep -qw ">s2;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength sorts ties by decreasing abundance (if abundance is present)"
"${VSEARCH}" \
    --sortbylength <(printf ">s1\nTT\n>s2\nAA\n") \
    --quiet \
    --output - | \
    head -n 1 | \
    grep -qw ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 28: --sortbylength sorts ties by increasing label"
"${VSEARCH}" \
    --sortbylength <(printf ">s2\nAA\n>s1\nTT\n") \
    --quiet \
    --output - | \
    head -n 1 | \
    grep -qw ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note: sequence order is not used to break ties
DESCRIPTION="issue 28: --sortbylength sorts ties by increasing label (assume unique labels)"
"${VSEARCH}" \
    --sortbylength <(printf ">s1\nTT\n>s1\nAA\n") \
    --quiet \
    --output - | \
    head -n 2 | \
    grep -qw "TT" && \
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
    grep -qw ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 29: --derep_fulllength --minuniquesize discards abundances lesser than value (=)"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n>s2\nA\n") \
    --minseqlength 1 \
    --quiet \
    --minuniquesize 2 \
    --output - | \
    grep -qw ">s1" && \
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
    grep -qw ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 29: --derep_fulllength --maxuniquesize discards abundances greater than value (<)"
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nA\n") \
    --minseqlength 1 \
    --quiet \
    --maxuniquesize 2 \
    --output - | \
    grep -qw ">s1" && \
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
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --output - | \
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --output - | \
    grep -qw "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta (upppercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --output - | \
    grep -qw "aaaaaaaaaaaa" && \
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
    grep -qw "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask none \
    --output - | \
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask none \
    --output - | \
    grep -qw "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none (upppercase, monotonous -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask none \
    --output - | \
    grep -qw "AAAAAAAAAAAA" && \
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
    grep -qw "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask soft \
    --output - | \
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask soft \
    --output - | \
    grep -qw "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft (upppercase, monotonous -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask soft \
    --output - | \
    grep -qw "AAAAAAAAAAAA" && \
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
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask dust \
    --output - | \
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask dust \
    --output - | \
    grep -qw "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust (upppercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask dust \
    --output - | \
    grep -qw "aaaaaaaaaaaa" && \
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
    grep -qw "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --hardmask (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --hardmask \
    --output - | \
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --hardmask (lowercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --hardmask \
    --output - | \
    grep -qw "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --hardmask (upppercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --hardmask \
    --output - | \
    grep -qw "NNNNNNNNNNNN" && \
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
    grep -qw "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none --hardmask (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask none \
    --hardmask \
    --output - | \
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none --hardmask (lowercase, monotonous -> lowercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask none \
    --hardmask \
    --output - | \
    grep -qw "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask none --hardmask (upppercase, monotonous -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask none \
    --hardmask \
    --output - | \
    grep -qw "AAAAAAAAAAAA" && \
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
    grep -qw "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft --hardmask (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask soft \
    --hardmask \
    --output - | \
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft --hardmask (lowercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask soft \
    --hardmask \
    --output - | \
    grep -qw "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask soft --hardmask (upppercase, monotonous -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask soft \
    --hardmask \
    --output - | \
    grep -qw "AAAAAAAAAAAA" && \
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
    grep -qw "acgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust --hardmask (upppercase, complex -> uppercase)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nACGTACGTACGT\n") \
    --quiet \
    --qmask dust \
    --hardmask \
    --output - | \
    grep -qw "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust --hardmask (lowercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\naaaaaaaaaaaa\n") \
    --quiet \
    --qmask dust \
    --hardmask \
    --output - | \
    grep -qw "NNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 30: --maskfasta --qmask dust --hardmask (upppercase, monotonous -> Ns)"
${VSEARCH} \
    --maskfasta <(printf ">s1\nAAAAAAAAAAAA\n") \
    --quiet \
    --qmask dust \
    --hardmask \
    --output - | \
    grep -qw "NNNNNNNNNNNN" && \
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
    grep -wq ">s1U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_fulllength treats T and U as identical (T first)"
${VSEARCH} \
    --derep_fulllength <(printf ">s1\nT\n>s2\nU\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_id treats T and U as identical (U first)"
${VSEARCH} \
    --derep_id <(printf ">s1\nU\n>s2\nT\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_id treats T and U as identical (T first)"
${VSEARCH} \
    --derep_id <(printf ">s1\nT\n>s2\nU\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_prefix treats T and U as identical (U first)"
${VSEARCH} \
    --derep_prefix <(printf ">s1\nU\n>s2\nT\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_prefix treats T and U as identical (T first)"
${VSEARCH} \
    --derep_prefix <(printf ">s1\nT\n>s2\nU\n") \
    --minseqlength 1 \
    --quiet \
    --output - | \
    tr -d "\n" | \
    grep -wq ">s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --fastx_uniques treats T and U as identical (U first)"
${VSEARCH} \
    --fastx_uniques <(printf ">s1\nU\n>s2\nT\n") \
    --minseqlength 1 \
    --quiet \
    --fastaout - | \
    tr -d "\n" | \
    grep -wq ">s1U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --fastx_uniques treats T and U as identical (T first)"
${VSEARCH} \
    --fastx_uniques <(printf ">s1\nT\n>s2\nU\n") \
    --minseqlength 1 \
    --quiet \
    --fastaout - | \
    tr -d "\n" | \
    grep -wq ">s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 35: --derep_smallmem treats T and U as identical (U first)"
TMP_FASTA=$(mktemp)
printf ">s1\nU\n>s2\nT\n" > "${TMP_FASTA}"
${VSEARCH} \
    --derep_smallmem "${TMP_FASTA}" \
    --minseqlength 1 \
    --quiet \
    --fastaout - | \
    tr -d "\n" | \
    grep -wq ">s1U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP_FASTA}"
unset TMP_FASTA

DESCRIPTION="issue 35: --derep_smallmem treats T and U as identical (T first)"
TMP_FASTA=$(mktemp)
printf ">s1\nT\n>s2\nU\n" > "${TMP_FASTA}"
${VSEARCH} \
    --derep_smallmem "${TMP_FASTA}" \
    --minseqlength 1 \
    --quiet \
    --fastaout - | \
    tr -d "\n" | \
    grep -wq ">s1T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP_FASTA}"
unset TMP_FASTA


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
    grep -wq ">s1A" && \
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
    grep -wq ">s1;size=2A" && \
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
    grep -wq ">s1;size=2A" && \
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
    grep -wq ">s1;size=3A" && \
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
    grep -wq ">t1A" && \
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
    grep -wq ">t1;size=1A" && \
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
    grep -wq "1" && \
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
    grep -wq "3" && \
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
    grep -wq "3" && \
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
    grep -wq "2" && \
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
    grep -wq "2" && \
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
    grep -wq "1" && \
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
    grep -wq "3" && \
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
    grep -wq "4" && \
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
    grep -wq "1" && \
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
    grep -wq "1" && \
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
    grep -wq "3" && \
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
    grep -wq "1" && \
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
    grep -wq "2" && \
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
    grep -wq "3" && \
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
    grep -wq "3" && \
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
    grep -wq "4" && \
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
    grep -wq ">s1;size=1AA>s2;size=1T" && \
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
    grep -wq ">s2;size=1AA>s1;size=1T" && \
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
    grep -wq ">s1;size=2AA>s2;size=1TT" && \
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
    grep -wq ">s2;size=2TT>s1;size=1AA" && \
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
    grep -wq ">s1;size=1AA>s2;size=1TT" && \
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
    grep -wq ">s1;size=1TT>s2;size=1AA" && \
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
    grep -wq ">s1;size=2AA>s2;size=1TT" && \
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
    grep -wq ">s2;size=2TT>s1;size=1AA" && \
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
    grep -wq ">s1;size=1AA>s2;size=1TT" && \
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
    grep -wq ">s1;size=1TT>s2;size=1AA" && \
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
    grep -wq ">s1;size=2A" && \
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
    grep -wq ">s1;size=2A" && \
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
    grep -wq ">s1;size=2A" && \
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
    grep -wq ">s1;size=3A" && \
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
 yes A | head -n 16386
 printf ">s2\n"
 yes A | head -n 100) > "${TMP}"
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


#******************************************************************************#
#                                                                              #
#                       Ambiguity in consensus alignment                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/67


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


#******************************************************************************#
#                                                                              #
#               Error in `vsearch': corrupted double-linked list               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/70


#******************************************************************************#
#                                                                              #
#          Error in calculation of the identity using --iddef 3 (MBL)          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/71


#******************************************************************************#
#                                                                              #
#                        Integrate patches from Debian                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/72


#******************************************************************************#
#                                                                              #
#                         Status taxonomy assignment?                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/73


#******************************************************************************#
#                                                                              #
#                  cluster input sequences shorter than 32nt                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/74


#******************************************************************************#
#                                                                              #
#             cluster_fast and msa output for each of the clusters             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/75


#******************************************************************************#
#                                                                              #
#                segfault when running cluster_fast with msaout                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/76


#******************************************************************************#
#                                                                              #
# Segmentation fault when using --uchime_denovo on a large fasta file (9.3 GB) #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/77


#******************************************************************************#
#                                                                              #
#                     Chimera detection progress indicator                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/78


#******************************************************************************#
#                                                                              #
#                        Support for multiple databases                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/79


#******************************************************************************#
#                                                                              #
#                           Generating cluster files                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/80


#******************************************************************************#
#                                                                              #
#                            Space in a header line                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/81


#******************************************************************************#
#                                                                              #
#       Error "No output files specified" when only samout is specified        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/82


#******************************************************************************#
#                                                                              #
#               Wanted: samout with search, not just clustering                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/83


#******************************************************************************#
#                                                                              #
#                     --relabel does not work consistently                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/84


#******************************************************************************#
#                                                                              #
#                Problem with repeats when clustering WGS reads                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/85


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


#******************************************************************************#
#                                                                              #
#                        Vsearch needs a Galaxy wrapper                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/88


#******************************************************************************#
#                                                                              #
#        Consensus output in clustering produces empty fasta sequences         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/89


#******************************************************************************#
#                                                                              #
#                 Dereplication based on prefixes of sequences                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/90


#******************************************************************************#
#                                                                              #
#                       Unable to build on OS X 10.10.3                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/91


#******************************************************************************#
#                                                                              #
#                    MAINT: renaming string.h to xstring.h                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/92


#******************************************************************************#
#                                                                              #
#                   I've made a homebrew package for vsearch                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/93


#******************************************************************************#
#                                                                              #
#                         Sequence profile of clusters                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/94


#******************************************************************************#
#                                                                              #
#             usearch_global sequences that contain repeated kmers             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/95


#******************************************************************************#
#                                                                              #
#                  question about compile time optimizations                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/96


#******************************************************************************#
#                                                                              #
#                Error in `vsearch': double free or corruption                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/97


#******************************************************************************#
#                                                                              #
#              option --minh ignored while using --uchime_denovo               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/98


#******************************************************************************#
#                                                                              #
#                                 Test scripts                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/99


#******************************************************************************#
#                                                                              #
#Use "|" (vertical bar) instead of ";" (semicolon) as separator in FASTA header#
#                                     lines                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/100


#******************************************************************************#
#                                                                              #
#        Reorganize subsampling commands for compatibilty with usearch         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/101


#******************************************************************************#
#                                                                              #
#         Option to sort cluster output files by the size of clusters          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/102


#******************************************************************************#
#                                                                              #
# Option to propagate the cluster identifier to both the consensus and profile #
#                                     files                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/103


#******************************************************************************#
#                                                                              #
#                     Missing output in uchime_denovo mode                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/104


#******************************************************************************#
#                                                                              #
#                                Change license                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/105


#******************************************************************************#
#                                                                              #
#                  Replace CityHash by FarmHash or MetroHash?                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/106


#******************************************************************************#
#                                                                              #
#                     Add header information to sam output                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/107


#******************************************************************************#
#                                                                              #
#                        Warnings reported by cppcheck                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/108


#******************************************************************************#
#                                                                              #
#                  Request regarding abundance labeled output                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/109


#******************************************************************************#
#                                                                              #
#                            details of msa output                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/110


#******************************************************************************#
#                                                                              #
#                Large memory consumption with --fastx_revcomp                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/111


#******************************************************************************#
#                                                                              #
#                                     Typo                                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/112


#******************************************************************************#
#                                                                              #
#                                 Help message                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/113


#******************************************************************************#
#                                                                              #
#              Remove stray ` mark from installation instructions              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/114


#******************************************************************************#
#                                                                              #
#                         Support xz compressed files                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/115


#******************************************************************************#
#                                                                              #
#                           FASTQ version conversion                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/116


#******************************************************************************#
#                                                                              #
#                         Add "-v" option for version                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/117


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


#******************************************************************************#
#                                                                              #
#      Make --fastx_subsample work with FASTQ files, not just FASTA files      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/120


#******************************************************************************#
#                                                                              #
#                      Add relabelling options to shuffle                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/121


#******************************************************************************#
#                                                                              #
#                               sizeorder option                               #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/122


#******************************************************************************#
#                                                                              #
#                       Issue with zlib on version 1.4.0                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/123


#******************************************************************************#
#                                                                              #
#                    Remove dependency on crypto libraries                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/124


#******************************************************************************#
#                                                                              #
#                           Fix example in man page                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/125


#******************************************************************************#
#                                                                              #
#                    realloc() error clustering on v.1.4.1                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/126


#******************************************************************************#
#                                                                              #
#     Fatal error: Cannot determine amount of RAM with 1.4.2 on OSX 10.8.5     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/127


#******************************************************************************#
#                                                                              #
#                Fix alignment bug introduced in version 1.2.17                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/128


#******************************************************************************#
#                                                                              #
#              possible for .uc files to be relabel_sha1-aware?                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/129


#******************************************************************************#
#                                                                              #
#                              add --search_exact                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/130


#******************************************************************************#
#                                                                              #
#                    add --relabel option to --shuffle #121                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/131


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


#******************************************************************************#
#                                                                              #
#                         release vsearch on anacoda?                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/134


#******************************************************************************#
#                                                                              #
#                   error in --fastq_stats on MaxOSX 10.8.5                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/135


#******************************************************************************#
#                                                                              #
#            Allow floating point number argument to threads option            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/136


#******************************************************************************#
#                                                                              #
#                           disable default CXXFLAGS                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/137


#******************************************************************************#
#                                                                              #
#             fastq_convert: fastaout does not work on fastq files             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/138


#******************************************************************************#
#                                                                              #
#                   Remove autoconf files from distribution                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/139


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


#******************************************************************************#
#                                                                              #
#                   quote fasta record names in --uc output                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/141


#******************************************************************************#
#                                                                              #
#    Segfault or fatal error with fastx-commands on compressed input files     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/142


#******************************************************************************#
#                                                                              #
#                          Improved chimera reporting                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/143


#******************************************************************************#
#                                                                              #
#    Optionally compress output to FASTA or FASTQ files with gzip or bzip2     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/144


#******************************************************************************#
#                                                                              #
#vsearch --fastq_stats doesn't report correct values of AvgEE, Rate and RatePct#
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/145


#******************************************************************************#
#                                                                              #
#         Error in installing vsearch 1.9.2 from source on OS X 10.8.5         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/146


#******************************************************************************#
#                                                                              #
#                          Letter case not preserved                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/147


#******************************************************************************#
#                                                                              #
#                         Add --fastq_eestats command                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/148


#******************************************************************************#
#                                                                              #
#                   Incorrect abundance in subsample output                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/149


#******************************************************************************#
#                                                                              #
#                   relabel issue duruing --derep_fulllength                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/150


#******************************************************************************#
#                                                                              #
#                                Rereplication                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/151


#******************************************************************************#
#                                                                              #
#                                usearch_local                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/152


#******************************************************************************#
#                                                                              #
#                  Wrong alignment results in usearch_global                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/153


#******************************************************************************#
#                                                                              #
#                                automake 1.15                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/154


#******************************************************************************#
#                                                                              #
#                     Request: uchime score in fasta label                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/155


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
    exec 2> ${TMP}
    printf ">s\nAAAA\n" | \
        "${VSEARCH}" \
            --fastx_mask - \
            --fastaout /dev/null
    grep -q "Writing output" ${TMP} && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm ${TMP}
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
printf ">s\nAAAA\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --log ${PROGRESS} \
        --fastaout - > /dev/null 2>> ${PROGRESS}
grep -q "Writing output" ${PROGRESS} && \
    failure "${DESCRIPTION}" || \
        success  "${DESCRIPTION}"
rm ${PROGRESS}


#******************************************************************************#
#                                                                              #
#                      Segmentation fault with uchime_ref                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/157


#******************************************************************************#
#                                                                              #
#         Database sequences in lower case are being masked by default         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/158


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


#******************************************************************************#
#                                                                              #
#           Add options to filter sequences and consensus sequences            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/161


#******************************************************************************#
#                                                                              #
#                       inconsistency with merging pairs                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/162


#******************************************************************************#
#                                                                              #
#                              --self doco error?                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/163


#******************************************************************************#
#                                                                              #
#             Do not truncate FASTQ labels (for fastq_mergepairs)              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/164


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
    grep -wq ">s;length=1" && \
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
    grep -wq ">s;length=0" && \
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
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter without --lengthout headers with length are untouched"
printf "@s;length=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --fastaout - | \
    grep -wq ">s;length=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter without --lengthout headers with length are untouched (final ';')"
printf "@s;length=2;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --fastaout - | \
    grep -wq ">s;length=2;" && \
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
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --xlength removes sequence length and dangling ';'"
printf "@s;length=1;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter without --xlength headers with length are untouched"
printf "@s;length=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --fastaout - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter without --xlength headers with length are untouched (final ';')"
printf "@s;length=1;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --fastaout - | \
    grep -wq ">s;length=1;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --xlength is silent if sequence length is missing"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --fastaout - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 165: fastq_filter --xlength dangling ';'"
printf "@s;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet \
        --xlength \
        --fastaout - | \
    grep -wq ">s" && \
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


#******************************************************************************#
#                                                                              #
#   Add idoffset argument for clustering of non-overlapped paired-end reads    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/167


#******************************************************************************#
#                                                                              #
#                  Output expected errors to fasta format too                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/168


#******************************************************************************#
#                                                                              #
#                         Compilation error [Fasta.c]                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/169


#******************************************************************************#
#                                                                              #
#                          Windows Executable Version                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/170


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


#******************************************************************************#
#                                                                              #
#            Indicate matching strand in uc file when dereplicating            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/173


#******************************************************************************#
#                                                                              #
#       Improve error message when FASTQ quality values are out of range       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/174


#******************************************************************************#
#                                                                              #
#               Merge pair fails when there are empty sequences                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/175


#******************************************************************************#
#                                                                              #
#       Compute evalues and bit scores using Karlin-Altschul statistics        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/176


#******************************************************************************#
#                                                                              #
#                       uchime_denovo on very long reads                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/177


#******************************************************************************#
#                                                                              #
#  cluster_smallmem: "Unable to allocate enough memory" error on a very large  #
#                                    dataset                                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/178


#******************************************************************************#
#                                                                              #
#                     Wrong values in the blast6out table                      #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/179


#******************************************************************************#
#                                                                              #
#             New option for trimming the sequence based on maxEE              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/180


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


#******************************************************************************#
#                                                                              #
#           Comparing vsearch chimera detection with uchime - denovo           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/183


#******************************************************************************#
#                                                                              #
#             Segmentation fault when masking very long sequences              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/184


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


#******************************************************************************#
#                                                                              #
#                          Allow shorter word lengths                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/189


#******************************************************************************#
#                                                                              #
#                  Filtering options for fastA sequences also                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/190


#******************************************************************************#
#                                                                              #
#                              typo in the manual                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/191


#******************************************************************************#
#                                                                              #
#            Improve documentation of fastq_stats and fastq_eestats            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/192


#******************************************************************************#
#                                                                              #
#         Add option to write non-chosen subsamples to a separate file         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/193


#******************************************************************************#
#                                                                              #
#          --fastq_stats fails on fastq files with an offset of +64?           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/194


#******************************************************************************#
#                                                                              #
#                         redundancy in read searching                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/195


#******************************************************************************#
#                                                                              #
#                    Document the UC format in the manpage                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/196


#******************************************************************************#
#                                                                              #
#               Extend --fastx_subsample to support FASTQ files                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/197


#******************************************************************************#
#                                                                              #
#                              Update the manpage                              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/198


#******************************************************************************#
#                                                                              #
#       --top_hits_only limited to --matched instead of also --dbmatched       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/199


#******************************************************************************#
#                                                                              #
#                                fulldp option                                 #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/200


#******************************************************************************#
#                                                                              #
#  Missing H record in --uc output when prefix dereplicating two sequences of  #
#                                unequal length                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/201


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
    grep -qE ";size=5;?$" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                            Old versions on conda                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/205


#******************************************************************************#
#                                                                              #
#                       Fatal error when reading ncbi-nr                       #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/206


#******************************************************************************#
#                                                                              #
#            Use cluster number in column 2 on H-lines in uc files             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/207


#******************************************************************************#
#                                                                              #
#                       dereplication option suggestion                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/208


#******************************************************************************#
#                                                                              #
#                         An error when running v2.30                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/209


#******************************************************************************#
#                                                                              #
#                          Sintax taxonomy classifier                          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/210


#******************************************************************************#
#                                                                              #
#                   gapopen and gapext - effect as expected?                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/211


#******************************************************************************#
#                                                                              #
#   FORBIDDEN INTERNAL GAPS and MISSING OF CLUSTERING FOR SEQUENCES WITH THE   #
#                                  LENGTH > 7                                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/212


#******************************************************************************#
#                                                                              #
# Internal gaps occur in alignments even with infinite internal gap penalties  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/213


#******************************************************************************#
#                                                                              #
#                 Improve behaviour with very short sequences                  #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/214


#******************************************************************************#
#                                                                              #
#                   --top_hits_only reports only one top hit                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/215


#******************************************************************************#
#                                                                              #
#  Use "=" in column 8 of uc files with perfect alignment also when ignoring   #
#                                 terminal gaps                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/216


#******************************************************************************#
#                                                                              #
#             Ideas for potential improvement in accuracy or speed             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/217


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


#******************************************************************************#
#                                                                              #
#                    clustering: profiles do not make sense                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/220


#******************************************************************************#
#                                                                              #
#  Output file for --fastq_eestats specified with --output option, not --log   #
#                                    option                                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/221


#******************************************************************************#
#                                                                              #
#                   Port VSEARCH to the POWER8 architecture                    #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/222


#******************************************************************************#
#                                                                              #
#                         Correctly detect named pipes                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/223


#******************************************************************************#
#                                                                              #
#                     Qiime open reference does not work ?                     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/224


#******************************************************************************#
#                                                                              #
#        Add minuniquesize/maxuniquesize to the command --fastx_filter         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/225


#******************************************************************************#
#                                                                              #
#                            fastq_eestats2 feature                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/226


#******************************************************************************#
#                                                                              #
#             Truncate header when converting from FASTQ to FASTA              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/227


#******************************************************************************#
#                                                                              #
#                Overflow in fastq_stats with large FASTQ files                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/228


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


#******************************************************************************#
#                                                                              #
#         Add fastq_maxdiffpct option (% difference for merging pairs)         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/231


#******************************************************************************#
#                                                                              #
#        Recording query reads that fail to cluster as "N" or "No hit"         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/232


#******************************************************************************#
#                                                                              #
#               Progress bar during shuffling always shows 100%                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/233


#******************************************************************************#
#                                                                              #
#                          Add support for udb files                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/234


#******************************************************************************#
#                                                                              #
#         Can we have a function of write to standard output and error         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/235


#******************************************************************************#
#                                                                              #
#                        OTU sequence short than before                        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/236


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


#******************************************************************************#
#                                                                              #
#                           Typo in warning message                            #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/240


#******************************************************************************#
#                                                                              #
#       what should average cluster size be when there are no clusters?        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/241


#******************************************************************************#
#                                                                              #
#                           Add --relabel_ids option                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/242


#******************************************************************************#
#                                                                              #
#                           Dealing with a full disk                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/243


#******************************************************************************#
#                                                                              #
#                          Lifting memory limitation                           #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/244


#******************************************************************************#
#                                                                              #
#         query end position correct in blast6 output when Searching?          #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/245


#******************************************************************************#
#                                                                              #
#                            link broken in README                             #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/246


#******************************************************************************#
#                                                                              #
#                fix link to manpage in README.md to close #246                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/pull/247


#******************************************************************************#
#                                                                              #
#      fastx_subsample: wrong error message when omiting --sample_pct or       #
#                                 --sample_size                                #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/248


#******************************************************************************#
#                                                                              #
#             change the warning message for discarded sequences?              #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/249


#******************************************************************************#
#                                                                              #
#     vsearch help or version should return the latest vsearch publication     #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/250


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

# NM (edit distance) is defined as the sum of mismatches XM and gap
# extensions XG, where it should be the sum of mismatches XM, gap
# extensions XG and gap opens XO, shouldn't it? Unless gap opens are
# included in mismatches, which does not seem to be the case.

# vsearch \
#     --usearch_global <(printf '>q1\nGGGGGGGGGG\n') \
#     --db <(printf '>r1\nGGGGGCCCCGGGGG\n') \
#     --id 0.5 \
#     --quiet \
#     --minseqlength 1 \
#     --samout - \
#     --alnout -

# I think the edit distance should just include the number of
# mismatches and the number of alignment positions with a gap
# symbol. In the example there are 0 mismatches and 4 gap positions,
# so the total edit distance is 4. The edit distance is usually
# defined as the number of simple operations necessary to transform
# one string into another, where the operations usually allowed are
# single nucleotide substitutions, single nucleotide deletions, and
# single nucleotide insertions.

# The edit distance (4 in this example) will usually be identical to
# the total alignment length (16 in this example) minus the number of
# matches (12 in this example).

# Qry  1 + ggggg----ggggg 10
#          |||||    |||||
# Tgt  1 + GGGGGCCCCGGGGG 14

# 14 cols, 10 ids (71.4%), 4 gaps (28.6%)
# q1	0	r1	1	255	5M4D5M	*	0	0	gggggggggg	*	AS:i:71	XN:i:0	XM:i:0	XO:i:1	XG:i:4	NM:i:4	MD:Z:5^CCCC5	YT:Z:UU


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
#                    Compilation warnings with GCC 8.0                         #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/304

## no test


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
    grep -Ewq ">s1;size=2;?" && \
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
    grep -Ewq ">s1;size=3;?" && \
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
    grep -Ewq ">s1" && \
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
    grep -Ewq ">s1;size=2;?" && \
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
    grep -Ewq ">s1;size=2;?" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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
#             Compilation warnings with gcc for vsearch 2.10                   #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/350

## no test


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

# DESCRIPTION="issue 354"
# "${VSEARCH}" \
#     --usearch_global <(printf ">q\nCRA\n") \
#     --db <(printf ">t\nCYW\n") \
#     --quiet \
#     --minseqlength 1 \
#     --id 0.3 \
#     --alnout -


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
    grep -qw "@s" && \
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
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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
    grep -qw "AAATCG@AAATGG" && \
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
        OCTAL=$(printf "\%04o" $(( ${i} + ${OFFSET} )) )
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
        OCTAL=$(printf "\%04o" $(( ${i} + ${OFFSET} )) )
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
    grep -qw "#OTU ID@A1@A2@A3OTU_1@2@1@4" && \
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
    grep -qw ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label matches the full header (not case-sensitive)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label "S1" \
        --fastaout - | \
    grep -qw ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label does not match header with size annotation"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label "s1" \
        --fastaout - | \
    grep -qw ">s1" && \
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
    grep -qw ">s1" && \
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
    grep -qw ">s11" && \
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
    grep -qw ">s11" && \
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
    grep -qw ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label_word matches the label (#2)"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label_word "s1" \
        --fastaout - | \
    grep -qw ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label_word matches the label (and nothing more)"
printf ">s11;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label_word "s1" \
        --fastaout - | \
    grep -qw ">s1;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 488: fastx_getseqs label_word matches the label (case-sensitive)"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_getseqs - \
        --quiet \
        --label_word "S1" \
        --fastaout - | \
    grep -qw ">s1;size=1" && \
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

DESCRIPTION="issue 506: reading query from process substitution and --db from /dev/stdin"
printf ">parentA\nAAAA\n>parentB\nGGGG\n" | \
    "${VSEARCH}" \
        --uchime_ref <(printf ">query\nAAGG\n") \
        --db /dev/stdin \
        --quiet \
        --uchimeout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# flaky test!! remove for now
# DESCRIPTION="issue 506: reading --db from '-' (stdin) is accepted"
# printf ">parentA\nAAAA\n>parentB\nGGGG\n" | \
#     "${VSEARCH}" \
#         --uchime_ref <(printf ">query\nAAGG\n") \
#         --db - \
#         --quiet \
#         --uchimeout /dev/null 2> /dev/null && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"


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
#            vsearch tool detailed option in command line ? (issue 516)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/516

## not testable (yet)


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
    grep -qEx ">s1;size=1;?" && \
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
    grep -qEx ">s1;size=2;?" && \
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
    grep -qEx ">s1;size=1;?" && \
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
    grep -qEx ">s1;size=2;?" && \
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
    grep -qEx ">s1;size=3;?" && \
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
    grep -qEx ">s1;size=3;?" && \
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
    grep -qEx ">s1;size=1;?" && \
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
    grep -qEx ">s1;size=2;?" && \
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
    grep -qEx ">s1;size=3;?" && \
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
    grep -qEx ">s1;size=3;?" && \
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
    grep -qEx ">s1;size=1;?" && \
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
    grep -qEx ">s1;size=2;?" && \
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
    grep -qEx ">s1;size=1;?" && \
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
    grep -qEx ">s1;size=2;?" && \
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
    grep -qEx ">s1;size=3;?" && \
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
    grep -qEx ">s1;size=5;?" && \
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
    grep -qEx ">s1;size=6;?" && \
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
    grep -qEx ">s1;size=6;?" && \
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
    grep -qEx ">s1;size=1;?" && \
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
    grep -qEx ">s1;size=2;?" && \
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
    grep -qEx ">s1;size=6;?" && \
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
    grep -qEx ">s1;size=6;?" && \
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
    grep -qEx ">s1;size=3;?" && \
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
    grep -qEx ">s1;size=5;?" && \
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
DESCRIPTION="issue 523: makeudb_usearch fails to write to a non-seekable output"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --makeudb_usearch /dev/stdin \
        --quiet \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

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
printf ">s1\n%031s\n" | \
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
printf ">s1\n%032s\n" | \
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
printf ">s1\n%010s\n" | \
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
printf ">s1\n%09s\n" | \
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
printf ">s1\n%050000s\n" | \
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
printf ">s1\n%050001s\n" | \
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
printf ">s1\n%032s\n" | \
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
printf ">s1\n%040s\n" | \
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

# TBD


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
    --db <(printf ">t1\n%s%s%s%s\n" "${REVCOMP}") \
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
    --db <(printf ">t1\n%s%s%s%s\n" "${REVCOMP}" "${REVCOMP}") \
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
    --db <(printf ">t1\n%s%s%s%s\n" "${REVCOMP}" "${REVCOMP}" "${REVCOMP}") \
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
    --db <(printf ">t1\n%s%s%s\n" "${SEQUENCE}" "${PADDING}") \
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
    grep -qw ">s_AT_" && \
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
    grep -qw ">s_T_" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ">s_AT_" && \
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
    grep -qw ">s_A_" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ">s_AT_" && \
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
    grep -qw ">s_A_" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ">s_T_" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -qw ".*" && \
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
    grep -wq "@s1_A_+_I_" && \
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
    grep -wq "@s1_A_+_I_" && \
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
    grep -wq "@s1_AA_+_II_" && \
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
    grep -wq ".*" && \
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
    grep -wq "@s1_A_+_I_" && \
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
    grep -wq "@s1_AA_+_II_" && \
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
        grep -wq "@s1_A_+_I_" && \
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
    grep -wq "@s1_A_+_I_" && \
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
    grep -wq ".*" && \
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
    grep -wq '@s1_A_+_!_' && \
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
    grep -wq ".*" && \
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
    grep -wq '@s1_AA_+_!!_' && \
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
    grep -wq ".*" && \
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
    grep -wq "@s1_A_+_I_" && \
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
    grep -wq ".*" && \
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
    grep -wq "@s1_AC_+_JJ_" && \
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
    grep -wq "@s1_A_+_J_" && \
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
    grep -wq ".*" && \
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
    grep -wq "@s1_ACG_+_JJJ_" && \
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
    grep -wq "@s1_AC_+_JJ_" && \
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
    grep -wq "@s1_AC_+_JJ_" && \
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
    grep -wq "@s1_A_+_J_" && \
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
    grep -wq ".*" && \
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
    grep -qw "#OTU ID" && \
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
    cut --fields 1 | \
    tail --lines=+2 | \
    tr "\n" "@" | \
    grep -qw "s1@s2@s3@" && \
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
    cut --fields 1 | \
    tail --lines=+2 | \
    tr "\n" "@" | \
    grep -qw "s1@s2@s3@" && \
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

DESCRIPTION="issue 540: derep_smallmem complains if output filename is missing"
TMP=$(mktemp)
printf ">s\nA\n\n" > "${TMP}"
${VSEARCH} \
    --derep_smallmem "${TMP}" 2>&1 | \
    grep -iq "Output" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${TMP}"
unset TMP


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
    grep -qw ">t1" && \
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
    grep -qw ">t1" && \
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
    grep -qw ">t1" && \
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
    grep -qw ">t1 extra" && \
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
    grep -qw "q1 t1" && \
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
    grep -qw "." && \
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
    grep -qw "q1 *" && \
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
    grep -qw "q1 t1" && \
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
        OCTAL=$(printf "\%04o" $(( ${i} + ${OFFSET} )) )
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
    grep -Eqw ">s;ee=0.00040+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 551: obtaining the expected error for each read (no --eeout)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastaout - | \
    grep -Eqw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## filter with and without --fastq_maxee
DESCRIPTION="issue 551: obtaining the expected error for each read (no EE filtering)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastaout - | \
    grep -Eqw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 551: obtaining the expected error for each read (above EE filtering threshold)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 0.0005 \
        --fastaout - | \
    grep -Eqw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 551: obtaining the expected error for each read (equal EE filtering threshold)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 0.0004 \
        --fastaout - | \
    grep -Eqw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 551: obtaining the expected error for each read (below EE filtering threshold)"
printf "@s\nAAAA\n+\nIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --quiet \
        --fastq_maxee 0.0003 \
        --fastaout - | \
    grep -Eqw ">s" && \
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
    grep -wq "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus keeps common bases (C)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nC\n>q2\nC\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -wq "C" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus keeps common bases (G)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nG\n>q2\nG\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -wq "G" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus keeps common bases (T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nT\n>q2\nT\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -wq "T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus is not case-sensitive (A-a)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nA\n>q2\na\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -wq "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus is not case-sensitive (a-A)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\na\n>q2\nA\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -wq "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout consensus is not case-sensitive (a-a)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\na\n>q2\na\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -wq "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout common bases are uppercased"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\na\n>q2\na\n") \
    --minseqlength 1 \
    --id 1.0 \
    --quiet \
    --consout - | \
    grep -wq "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (2/3rd AA)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAA\n>q2\nAA\n>q3\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout does not pick least common base (1/3rd AC)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAA\n>q2\nAA\n>q3\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AC" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (3/5th AA)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAA\n>q2\nAA\n>q3\nAA\n>q4\nAC\n>q5\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout does not pick least common base (2/5th AC)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAA\n>q2\nAA\n>q3\nAA\n>q4\nAC\n>q5\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AC" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (1/2 AT)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAT\n>q3\nAA\n>q4\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (2/5 AT)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAT\n>q3\nAA\n>q4\nAC\n>q5\nAG\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks most common base (3/9 AT)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAT\n>q3\nAT\n>q4\nAA\n>q5\nAA\n>q6\nAC\n>q7\nAC\n>q8\nAG\n>q9\nAG\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AT" && \
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
    grep -wq "AT" && \
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
    grep -wq "AT" && \
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
    grep -wq "AT" && \
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
    grep -wq "AT" && \
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
    grep -wq "AT" && \
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
    grep -wq "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (A before G)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAG\n>q2\nAA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (A before T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (C before G)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAG\n>q2\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (C before T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout equally common bases are sorted alphabetically (G before T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAT\n>q2\nAG\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AG" && \
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
    grep -wq "AA" && \
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
    grep -wq "AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks any base rather than N (C)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAN\n>q2\nAC\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks any base rather than N (G)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAN\n>q2\nAG\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks any base rather than N (T)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAN\n>q2\nAT\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks any base rather than N (t, case-insensitive)"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nAN\n>q2\nAt\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks N if there are no other base"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nNA\n>q2\nA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "NA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks N if there is only Ns"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nNA\n>q2\nNA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "NA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout picks a base, even if there are several Ns"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nNA\n>q2\nNA\n>q3\nAA\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "AA" && \
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
    grep -wq "CGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="issue 557: consout never picks a gap even if gaps are dominant (3')"
"${VSEARCH}" \
    --cluster_size <(printf ">q1\nCGTA\n>q2\nCGT\n>q3\nCGT\n") \
    --minseqlength 1 \
    --id 0.5 \
    --quiet \
    --consout - | \
    grep -wq "CGT" && \
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
    grep -wq "ATATATATATATATAT" && \
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
    grep -wq "ATATATAT-ATATATAT" && \
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
    grep -qw "GGGAAGCCCAAAGGGGGTGGTGACCGAGTACG" && \
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
    grep -qw ">[*]A" && \
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
    grep -qw ">consensus" && \
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
# already tested in fastq_stats.sh


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
#     vsearch-2.29.0-linux-x86_64-static segmentation fault (issue 574)        #
#                                                                              #
#******************************************************************************#
##
## https://github.com/torognes/vsearch/issues/574

## not testable


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


exit 0


# DONE: issues 1-63 and 549 to 561
# TODO: issue 506 read --db from stream fails in CI runs (works on my machine)
# TODO: issue 529
# TODO: issue 513: make a test with two occurrences of the query in the target sequence
# TODO: issue 547: the way kmer profile scores are computed is not clear at all. I cannot predict it.
# TODO: regex used to strip annotations (^|;)size=[0-9]+(;|$)/;/ fix tests accordingly.
# TODO: fix issue 260 (SAM format)
# TODO: otutabout remaining open-questions (check the actual C++ code):
#       - in the absence of ';sample=abcd1234;' each cluster is assigned to its own sample (matrix diagonal)?
#       - clusters are sorted by decreasing abundance?
#       - show that it work with both --sample and --relabel

