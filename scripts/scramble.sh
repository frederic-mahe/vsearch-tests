#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="scramble"
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

## valgrind is only useful here if it can actually run the binary under
## test. When it dies before reaching main -- a uprobe on the dynamic
## loader does that, and so does a sanitizer-instrumented binary -- it
## still reports "ERROR SUMMARY: 0 errors" and "in use at exit: 0
## bytes", which would silently turn every valgrind check below into a
## pass. Probe it once here, so those checks are skipped, not passed.
VALGRIND_WORKS=false
if which valgrind > /dev/null 2>&1 ; then
    VALGRIND_PROBE=$(valgrind "${VSEARCH}" --version 2>&1)
    [[ "${VALGRIND_PROBE}" == *"ERROR SUMMARY"* && \
       "${VALGRIND_PROBE}" != *"Process terminating"* ]] && \
        VALGRIND_WORKS=true
    unset VALGRIND_PROBE
fi


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------------- output
DESCRIPTION="--scramble requires an output option"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--scramble errors if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --fastaout "${TMP}" 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--scramble accepts --fastaout"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble accepts --fastqout (fastq input)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --scramble - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble accepts both output options in one run (fastq input)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --scramble - \
        --fastaout /dev/null \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble rejects --fastqout with fasta input (no quality scores)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--scramble minimal working example (empty input)"
printf "" | \
    "${VSEARCH}" \
        --scramble - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--scramble minimal working example (single fasta sequence)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--scramble reads and returns fasta"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--scramble minimal working example (single fastq sequence)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --scramble - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--scramble reads fastq and returns fasta"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--scramble accepts a file as input"
TMP=$(mktemp)
printf ">s\nA\n" > "${TMP}"
"${VSEARCH}" \
    --scramble "${TMP}" \
    --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

## ---------------------------------------------------------- compressed input
DESCRIPTION="--scramble reads gzip-compressed input"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --scramble - \
        --gzip_decompress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble reads bzip2-compressed input"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --scramble - \
        --bzip2_decompress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                     invariants (the null-model contract)                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--scramble preserves the number of entries"
printf ">s1\nACGTACGTAC\n>s2\nAAACCCGGGTTT\n>s3\nGATTACA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    grep -c "^>" | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## scrambling must not reorder entries; that is --shuffle's job
DESCRIPTION="--scramble preserves the order and names of the entries"
printf ">s1\nACGTACGTAC\n>s2\nAAACCCGGGTTT\n>s3\nGATTACA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    grep "^>" | \
    tr -d "\n" | \
    grep -qx ">s1>s2>s3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble preserves the length of each sequence"
printf ">s1\nACGTACGTAC\n>s2\nAAACCCGGGTTT\n>s3\nGATTACA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    awk '/^>/ {next} {printf "%d ", length($0)}' | \
    grep -qx "10 12 7 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## per-entry composition: sorted residues of output == sorted residues of input
DESCRIPTION="--scramble preserves the nucleotide composition of each sequence"
compare_compositions() {
    local input="${1}"
    local output
    output=$(printf "%s" "${input}" | \
                 "${VSEARCH}" \
                     --scramble - \
                     --quiet \
                     --fastaout -)
    diff \
        <(printf "%s" "${input}" | awk '!/^>/' | \
              while read -r SEQ ; do
                  echo "${SEQ}" | fold -w1 | sort | tr -d "\n" ; echo
              done) \
        <(printf "%s" "${output}" | awk '!/^>/' | \
              while read -r SEQ ; do
                  echo "${SEQ}" | fold -w1 | sort | tr -d "\n" ; echo
              done) > /dev/null
}
compare_compositions ">s1\nACGTACGTAC\n>s2\nAAACCCGGGTTT\n>s3\nGATTACA\n" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble preserves per-residue case (masked fraction)"
compare_compositions ">s1\naaaCCCgggTTT\n" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble preserves ambiguous nucleotide symbols (IUPAC, N)"
compare_compositions ">s1\nRYSWKMBDHVNACGT\n" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset -f compare_compositions


#*****************************************************************************#
#                                                                             #
#                       randomization actually happens                       #
#                                                                             #
#*****************************************************************************#

## a 60-nt non-repetitive sequence has a vanishing probability of
## scrambling to itself, whatever the (free) seed
DESCRIPTION="--scramble changes the nucleotide order (long sequence, free seed)"
SEQ="AACGTTGCAAGGCTATTCGACCTGAAACGTGTTCAAGCATGACCGTTAGGCATCAATGCC"
printf ">s1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    grep -qx "${SEQ}" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

## only one possible arrangement
DESCRIPTION="--scramble passes homopolymers through unchanged"
printf ">s1\nAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">s1AAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble handles a length-1 sequence"
printf ">s1\nG\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">s1G" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## either order is a valid scramble; only composition and exit status
## are checked
DESCRIPTION="--scramble handles a length-2 sequence"
printf ">s1\nGT\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    tr -d "\n" | \
    grep -Eqx ">s1(GT|TG)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## pinned: an entry with an empty sequence yields a lone header line
DESCRIPTION="--scramble passes empty sequences through"
printf ">s1\n\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              reproducibility                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--scramble accepts --randseed"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --randseed 1 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble a fixed --randseed produces constant output"
SEED=666
INPUT=">s1\nACGTACGTAC\n>s2\nAAACCCGGGTTT\n>s3\nGATTACA\n"
FIRST=$(printf "%b" "${INPUT}" | \
            "${VSEARCH}" \
                --scramble - \
                --quiet \
                --randseed ${SEED} \
                --fastaout -)
SECOND=$(printf "%b" "${INPUT}" | \
             "${VSEARCH}" \
                 --scramble - \
                 --quiet \
                 --randseed ${SEED} \
                 --fastaout -)
[[ "${FIRST}" == "${SECOND}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEED FIRST SECOND

DESCRIPTION="--scramble different seeds produce different outputs"
FIRST=$(printf "%b" "${INPUT}" | \
            "${VSEARCH}" \
                --scramble - \
                --quiet \
                --randseed 1 \
                --fastaout -)
SECOND=$(printf "%b" "${INPUT}" | \
             "${VSEARCH}" \
                 --scramble - \
                 --quiet \
                 --randseed 2 \
                 --fastaout -)
[[ "${FIRST}" != "${SECOND}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset FIRST SECOND INPUT

## special seed value
DESCRIPTION="--scramble accepts --randseed 0 (free seed)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --randseed 0 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## a given --randseed yields the same result on any platform: every
## draw goes through the in-house portable generator and bounded-draw
## helpers (utils/random.hpp), never through std::shuffle or
## std::uniform_int_distribution (both implementation-defined). This
## test pins one exact output, so any change to the cross-platform
## pseudo-random generator, to the per-entry sub-stream seeding, or to
## the Fisher-Yates loop is caught.
DESCRIPTION="--scramble --randseed 1 produces a fixed, cross-platform output"
printf ">s1\nACGTACGTAC\n>s2\nAAACCCGGGTTT\n>s3\nGATTACA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --randseed 1 \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">s1GACCTTCAGA>s2TCCGATATAGCG>s3GTCATAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## each entry is scrambled with its own sub-stream derived from the
## seed and the entry ordinal, so the presence of quality values does
## not shift the draws: fasta output from a fastq file and from the
## equivalent fasta file must be identical for a given seed
DESCRIPTION="--scramble same seed scrambles identically with or without quality"
FIRST=$(printf "@s1\nACGTACGTAC\n+\nIIIIHHHHGG\n" | \
            "${VSEARCH}" \
                --scramble - \
                --quiet \
                --randseed 1 \
                --fastaout -)
SECOND=$(printf ">s1\nACGTACGTAC\n" | \
             "${VSEARCH}" \
                 --scramble - \
                 --quiet \
                 --randseed 1 \
                 --fastaout -)
[[ "${FIRST}" == "${SECOND}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset FIRST SECOND


#*****************************************************************************#
#                                                                             #
#                                    fastq                                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--scramble fastq output has a valid @/+ structure"
printf "@s1\nACGTACGTAC\n+\nIIIIHHHHGG\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --randseed 1 \
        --fastqout - | \
    awk 'NR == 1 {exit ($0 ~ /^@s1$/) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble fastq output sequence and quality have the same length"
printf "@s1\nACGTACGTAC\n+\nIIIIHHHHGG\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastqout - | \
    awk 'NR == 2 {seq = $0} NR == 4 {exit (length(seq) == length($0)) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## quality is never scrambled: the quality string must be copied
## through byte-identically, preserving the positional quality profile
## (and the expected error) of each entry, while the pairing between
## each nucleotide and its quality value is deliberately broken
DESCRIPTION="--scramble copies the quality string through unchanged"
printf "@s1\nACGTACGTAC\n+\nIIIIHHHHGG\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --randseed 1 \
        --fastqout - | \
    awk 'NR == 4' | \
    grep -qx "IIIIHHHHGG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble accepts --fastq_ascii 64"
printf "@s1\nACGT\n+\nhhhh\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fastq_ascii 64 \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               scramble_kmer                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--scramble accepts --scramble_kmer 1"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --scramble_kmer 1 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --scramble_kmer 1 output is identical to the default"
FIRST=$(printf ">s1\nACGTACGTAC\n" | \
            "${VSEARCH}" \
                --scramble - \
                --quiet \
                --randseed 1 \
                --fastaout -)
SECOND=$(printf ">s1\nACGTACGTAC\n" | \
             "${VSEARCH}" \
                 --scramble - \
                 --quiet \
                 --randseed 1 \
                 --scramble_kmer 1 \
                 --fastaout -)
[[ "${FIRST}" == "${SECOND}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset FIRST SECOND

DESCRIPTION="--scramble accepts --scramble_kmer 2"
printf ">s\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --scramble_kmer 2 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble accepts --scramble_kmer 9 (upper bound)"
printf ">s\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --scramble_kmer 9 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## vertex ids of the sampler's de Bruijn graph are (k-1)-mers packed
## into 8 bytes, hence the documented cap of 9: a surprising refusal
## worth pinning
DESCRIPTION="--scramble rejects --scramble_kmer 10 (above the documented cap)"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --scramble - \
        --scramble_kmer 10 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## GATTACA's dinucleotide de Bruijn graph admits exactly two Eulerian
## paths, spelling GATTACA and GACATTA: any other output would break
## the dinucleotide-count contract
DESCRIPTION="--scramble --scramble_kmer 2 samples an Eulerian path (GATTACA)"
printf ">s\nGATTACA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --scramble_kmer 2 \
        --fastaout - | \
    awk 'NR == 2' | \
    grep -Eqx "GATTACA|GACATTA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## at k = 3, GATTACA's Eulerian path is unique: output equal to input
## is the documented, correct behaviour
DESCRIPTION="--scramble --scramble_kmer 3 unique-path sequence passes through"
printf ">s\nGATTACA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --scramble_kmer 3 \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">sGATTACA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## a sequence holding at most one k-mer (length <= k) is documented to
## pass through unchanged
DESCRIPTION="--scramble --scramble_kmer 9 short sequence passes through"
printf ">s\nGATTACA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --scramble_kmer 9 \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">sGATTACA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --scramble_kmer 2 preserves dinucleotide counts"
SEQ="AACGTTGCAAGGCTATTCGACCTGAAACGTGTTCAAGCATGACCGTTAGGCATCAATGCC"
OUTPUT=$(printf ">s\n%s\n" "${SEQ}" | \
             "${VSEARCH}" \
                 --scramble - \
                 --quiet \
                 --scramble_kmer 2 \
                 --fastaout - | \
             awk 'NR == 2')
diff \
    <(echo "${SEQ}" | \
          awk '{for (i = 1; i < length($0); i++) print substr($0, i, 2)}' | sort) \
    <(echo "${OUTPUT}" | \
          awk '{for (i = 1; i < length($0); i++) print substr($0, i, 2)}' | sort) \
    > /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ OUTPUT

## the first and last k-1 nucleotides spell the start and end vertices
## of the Eulerian path: they always keep their positions
DESCRIPTION="--scramble --scramble_kmer 3 preserves the first and last 2 nt"
printf ">s\nAACGTTGCAAGGCTATTCGACCTGAAACGTGTTCAAGCATGACCGTTAGGCATCAATGCC\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --scramble_kmer 3 \
        --fastaout - | \
    awk 'NR == 2' | \
    grep -Eqx "AA.*CC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --scramble_kmer 2 a fixed --randseed produces constant output"
FIRST=$(printf ">s\nAACGTTGCAAGGCTATTCGACCTGAAACGTGTTCAAGCATGACC\n" | \
            "${VSEARCH}" \
                --scramble - \
                --quiet \
                --randseed 7 \
                --scramble_kmer 2 \
                --fastaout -)
SECOND=$(printf ">s\nAACGTTGCAAGGCTATTCGACCTGAAACGTGTTCAAGCATGACC\n" | \
             "${VSEARCH}" \
                 --scramble - \
                 --quiet \
                 --randseed 7 \
                 --scramble_kmer 2 \
                 --fastaout -)
[[ "${FIRST}" == "${SECOND}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset FIRST SECOND

## same portable-RNG binding as the k = 1 pin above, now also covering
## the arborescence and slice-shuffling draws of the Eulerian sampler
DESCRIPTION="--scramble --scramble_kmer 2 --randseed 1 fixed, cross-platform output"
printf ">s1\nAAACCCGGGTTTACGTACGTAC\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --randseed 1 \
        --scramble_kmer 2 \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">s1AACCCGTTAACGGTTACGGTAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --scramble_kmer 2 copies the quality string through unchanged"
printf "@s1\nAACGTTGCAAGGCTATTCGA\n+\nIIHHGGFFEEDDCCBBAA98\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --randseed 1 \
        --scramble_kmer 2 \
        --fastqout - | \
    awk 'NR == 4' | \
    grep -qx "IIHHGGFFEEDDCCBBAA98" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble rejects --scramble_kmer 0"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --scramble - \
        --scramble_kmer 0 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--scramble rejects a negative --scramble_kmer"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --scramble - \
        --scramble_kmer -1 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--scramble rejects a non-numeric --scramble_kmer"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --scramble - \
        --scramble_kmer A \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             secondary options                               #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--scramble --sizeout adds abundance annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --sizeout \
        --fastaout - | \
    grep -qx ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## abundance annotations are always parsed, with or without --sizein
DESCRIPTION="--scramble --sizeout preserves abundance annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --sizeout \
        --fastaout - | \
    grep -qx ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --sizein --sizeout preserves abundance annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --sizein \
        --sizeout \
        --fastaout - | \
    grep -qx ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --xsize strips abundance annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --xsize \
        --fastaout - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --relabel relabels the entries"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --relabel "label" \
        --fastaout - | \
    grep "^>" | \
    tr -d "\n" | \
    grep -qx ">label1>label2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --relabel_keep keeps the old label after the new"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --fastaout - | \
    grep -qx ">label1 s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --relabel_md5 relabels with an md5 digest"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --relabel_md5 \
        --fastaout - | \
    grep -Eqx ">[0-9a-f]{32}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --relabel_sha1 relabels with a sha1 digest"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --relabel_sha1 \
        --fastaout - | \
    grep -Eqx ">[0-9a-f]{40}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --relabel_self relabels with the sequence itself"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --relabel_self \
        --fastaout - | \
    tr -d "\n" | \
    grep -qx ">AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --label_suffix appends to the label"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --label_suffix ";suffix" \
        --fastaout - | \
    grep -qx ">s;suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --lengthout adds length annotations"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --lengthout \
        --fastaout - | \
    grep -qx ">s;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --sample adds sample annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --sample "ABC" \
        --fastaout - | \
    grep -qx ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --xee removes expected-error annotations"
printf ">s;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --xee \
        --fastaout - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --xlength removes length annotations"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --xlength \
        --fastaout - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --fasta_width wraps fasta output"
printf ">s\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --fasta_width 5 \
        --fastaout - | \
    awk 'END {exit (NR == 3) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --notrunclabels is accepted (labels never truncated)"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --notrunclabels \
        --fastaout - | \
    grep -qx ">s extra" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble --quiet silences stderr"
OUTPUT=$(printf ">s\nA\n" | \
             "${VSEARCH}" \
                 --scramble - \
                 --quiet \
                 --fastaout /dev/null 2>&1)
[[ -z "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

DESCRIPTION="--scramble --log writes to a file"
TMP=$(mktemp)
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --log "${TMP}" \
        --fastaout /dev/null 2> /dev/null
[[ -s "${TMP}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--scramble accepts --no_progress"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --no_progress \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--scramble accepts --threads 1"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --scramble - \
        --quiet \
        --threads 1 \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if [[ "${VALGRIND_WORKS}" == "true" ]] ; then
    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --scramble <(printf ">s1\nACGTACGTAC\n") \
        --fastaout /dev/null 2> /dev/null
    DESCRIPTION="--scramble valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--scramble valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP

    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --scramble <(printf "@s1\nACGTACGTAC\n+\nIIIIHHHHGG\n") \
        --fastqout /dev/null 2> /dev/null
    DESCRIPTION="--scramble valgrind fastq (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--scramble valgrind fastq (no errors)"
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

## - the pinned cross-platform outputs (">s1GACCTTCAGA..." at k = 1,
##   ">s1AACCCGTTAACGGTTACGGTAC" at k = 2) bind the in-house portable
##   generator (utils/random.hpp), the per-entry sub-stream seeding,
##   the Fisher-Yates loop, and (k = 2) the Eulerian sampler's
##   arborescence and slice-shuffling draws; both were generated with
##   the first --scramble implementation (2026-08-31)
## - this script must not be added to run_all_tests.sh before a
##   vsearch release ships --scramble: every test would fail with
##   "unknown option" against released binaries

exit 0

# status: complete (pending first vsearch release with --scramble, 2026-08-31)
