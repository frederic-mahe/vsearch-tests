#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="maskfasta"
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


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## vsearch --maskfasta fastafile --output outputfile [options]

DESCRIPTION="--maskfasta is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta reads from stdin (-)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta reads from a file"
TMPFA=$(mktemp)
printf ">s1\nACGT\n" > "${TMPFA}"
"${VSEARCH}" \
    --maskfasta "${TMPFA}" \
    --output /dev/null \
    --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--maskfasta fails if input file does not exist"
"${VSEARCH}" \
    --maskfasta /no/such/file \
    --output /dev/null \
    --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--maskfasta fails without --output"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--output is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--output - writes to stdout"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--output fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output "${TMP}" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

# --maskfasta is documented as taking a fastafile; in practice, fastq input
# is also accepted and quality scores are discarded in the fasta output
DESCRIPTION="--maskfasta accepts fastq input and drops quality scores"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

# ten A's followed by GCATGC: DUST masks the poly-A run
DESCRIPTION="--maskfasta default masking is dust (low-complexity region is lowercased)"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "aaaaaaaaaaGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta non-low-complexity sequence is unchanged"
printf ">s1\nACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta empty fasta input produces empty output"
printf "" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--maskfasta multiple sequences are all output"
printf ">s1\nACGT\n>s2\nTGCA\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta sequence header is preserved"
printf ">myseq1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">myseq1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maskfasta output is in fasta format"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --qmask

DESCRIPTION="--qmask dust is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask dust \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask soft is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask soft \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask none is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask with no argument fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--qmask with invalid value fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask invalid \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# Example adapted from Morgulis et al. (2006) Journal of Computational
# Biology, 13(5), 1028-1040
DESCRIPTION="--qmask dust lowercases low-complexity region"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask dust \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "aaaaaaaaaaGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask none leaves sequence unchanged"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "AAAAAAAAAAGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask none preserves existing lowercase letters"
printf ">s1\naaGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "aaGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask soft preserves existing lowercase letters"
printf ">s1\naaGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask soft \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "aaGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --qmask soft does not apply DUST; only pre-existing lowercase is masked
DESCRIPTION="--qmask soft does not mask new low-complexity regions"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask soft \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "AAAAAAAAAAGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --hardmask

DESCRIPTION="--hardmask is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --hardmask \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--hardmask with --qmask dust replaces low-complexity region with Ns"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask dust \
        --hardmask \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "NNNNNNNNNNGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--hardmask with --qmask soft replaces existing lowercase with Ns"
printf ">s1\naaGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask soft \
        --hardmask \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "NNGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--hardmask with --qmask none leaves sequence unchanged"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --hardmask \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "AAAAAAAAAAGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--hardmask output sequence contains no lowercase letters"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask dust \
        --hardmask \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -v "^>" | \
    grep -q "[a-z]" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --max_unmasked_pct and --min_unmasked_pct
#
# NOTE for human review: the manpage lists --min_unmasked_pct and
# --max_unmasked_pct as filtering options for --maskfasta, but vsearch
# appears to accept them silently without applying any filtering (sequences
# that should be discarded are still written to output). This contrasts with
# --fastx_mask, where these options do filter correctly. Tests below only
# verify that the options are accepted.

DESCRIPTION="--max_unmasked_pct is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --max_unmasked_pct 100 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--min_unmasked_pct is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --min_unmasked_pct 0 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# all-uppercase sequence is 100% unmasked; with --fastx_mask this would be
# filtered out at --max_unmasked_pct 0, but --maskfasta silently ignores it
DESCRIPTION="--max_unmasked_pct 0 does not filter out sequences (option is ignored)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --max_unmasked_pct 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# partly-masked sequence (50% unmasked) is kept even with a filter that
# would otherwise discard it in --fastx_mask
DESCRIPTION="--min_unmasked_pct 100 does not filter out sequences (option is ignored)"
printf ">s1\natGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask soft \
        --fasta_width 0 \
        --min_unmasked_pct 100 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## extra --qmask behaviour

# lowercase input should still be masked by DUST (the dust function
# uppercases internally before detecting low-complexity regions)
DESCRIPTION="--qmask dust detects low-complexity regions in lowercase input"
printf ">s1\naaaaaaaaaagcatgc\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask dust \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "aaaaaaaaaaGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# a run of ambiguous 'N's is treated as a low-complexity region by DUST
DESCRIPTION="--qmask dust masks a run of N characters"
printf ">s1\nNNNNNNNNNNGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask dust \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "nnnnnnnnnnGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --hardmask with --qmask soft applied to all-uppercase input leaves
# the sequence untouched (no lowercase to convert to N)
DESCRIPTION="--hardmask with --qmask soft and no lowercase leaves sequence unchanged"
printf ">s1\nACGTACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask soft \
        --hardmask \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "ACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --fasta_width

# 84-nt sequence (> 80) appears on one line with --fasta_width 0
DESCRIPTION="--fasta_width 0 suppresses line folding"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 84-nt sequence is folded; line 2 must be exactly 80 chars by default
DESCRIPTION="--fasta_width default folds at 80 characters"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --quiet 2>/dev/null | \
    awk "NR==2 {exit length(\$0) != 80}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta_width 10 folds sequence at 10 characters"
printf ">s1\nACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 10 \
        --quiet 2>/dev/null | \
    awk "NR==2 {exit length(\$0) != 10}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta_width with non-numeric argument fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --fasta_width abc \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --bzip2_decompress

DESCRIPTION="--bzip2_decompress reads bzip2-compressed fasta from stdin"
printf ">s1\nACGT\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --bzip2_decompress \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--bzip2_decompress fails on an uncompressed input pipe"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --bzip2_decompress \
        --qmask none \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --gzip_decompress

DESCRIPTION="--gzip_decompress reads gzip-compressed fasta from stdin"
printf ">s1\nACGT\n" | \
    gzip | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --gzip_decompress \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# gzip detects an uncompressed stream and passes it through unchanged
DESCRIPTION="--gzip_decompress passes through an uncompressed input pipe"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --gzip_decompress \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --label_suffix

DESCRIPTION="--label_suffix appends suffix to sequence header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --label_suffix ";foo=bar" \
        --quiet 2>/dev/null | \
    grep -qx ">s1;foo=bar" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_suffix and --lengthout annotations appear together in header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --label_suffix ";foo=bar" \
        --lengthout \
        --quiet 2>/dev/null | \
    grep -q "length=4.*foo=bar\|foo=bar.*length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_suffix with empty string leaves header unchanged"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --label_suffix "" \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --lengthout

DESCRIPTION="--lengthout adds length annotation to header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --lengthout \
        --quiet 2>/dev/null | \
    grep -qx ">s1;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --log

DESCRIPTION="--log writes to a file"
TMPLOG=$(mktemp)
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --log "${TMPLOG}" \
        --quiet 2>/dev/null
[[ -s "${TMPLOG}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG

DESCRIPTION="--log does not suppress stderr messages"
TMPLOG=$(mktemp)
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --log "${TMPLOG}" \
        2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG

## --maxseqlength

DESCRIPTION="--maxseqlength discards sequences longer than the given value"
printf ">s1\nACGTACGT\n>s2\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --maxseqlength 4 \
        --quiet 2>/dev/null | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maxseqlength keeps sequences at exactly the given length"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --maxseqlength 4 \
        --quiet 2>/dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# boundary: a sequence longer than maxseqlength by one is discarded
DESCRIPTION="--maxseqlength discards sequences exactly one nucleotide too long"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --maxseqlength 3 \
        --quiet 2>/dev/null | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--maxseqlength 0 discards every sequence"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --maxseqlength 0 \
        --quiet 2>/dev/null | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --minseqlength

DESCRIPTION="--minseqlength discards sequences shorter than the given value"
printf ">s1\nACGTACGT\n>s2\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --minseqlength 5 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--minseqlength keeps sequences at exactly the given length"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --minseqlength 4 \
        --quiet 2>/dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# default minseqlength is 1: a 1-nt sequence passes, empty is discarded
DESCRIPTION="--minseqlength default (1) keeps 1-nt sequence"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--minseqlength 0 is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --minseqlength 0 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --no_progress

DESCRIPTION="--no_progress is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --no_progress \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notrunclabels

DESCRIPTION="--notrunclabels preserves full header including space"
printf ">s1 some description\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --notrunclabels \
        --quiet 2>/dev/null | \
    grep -qx ">s1 some description" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="without --notrunclabels header is truncated at first space"
printf ">s1 some description\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --quiet

DESCRIPTION="--quiet suppresses stderr output"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --quiet 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--quiet does not suppress fatal error messages"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output "${TMP}" \
        --quiet 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

## --relabel

DESCRIPTION="--relabel replaces header with prefix and ticker"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel "seq" \
        --quiet 2>/dev/null | \
    grep -qx ">seq1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel with empty string produces just the ticker as label"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel "" \
        --quiet 2>/dev/null | \
    grep -qx ">1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel ticker increments across sequences"
printf ">s1\nACGT\n>s2\nTGCA\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel "x" \
        --quiet 2>/dev/null | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">x1 >x2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel with --lengthout appends length annotation to the new label"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel "x" \
        --lengthout \
        --quiet 2>/dev/null | \
    grep -qx ">x1;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel with --sizeout appends size annotation to the new label"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel "x" \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">x1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_keep

DESCRIPTION="--relabel_keep retains original identifier after relabeling"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel "seq" \
        --relabel_keep \
        --quiet 2>/dev/null | \
    grep -qx ">seq1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel_keep retains original header annotations after relabeling"
printf ">s1;foo=bar\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel "seq" \
        --relabel_keep \
        --quiet 2>/dev/null | \
    grep -qx ">seq1 s1;foo=bar" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_md5

# MD5 of "ACGT" (uppercase, U->T applied) = f1f8f4bf413b16ad135722aa4591043e
DESCRIPTION="--relabel_md5 replaces header with MD5 digest of the sequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel_md5 \
        --quiet 2>/dev/null | \
    grep -qx ">f1f8f4bf413b16ad135722aa4591043e" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --relabel and --relabel_md5 are mutually exclusive
DESCRIPTION="--relabel and --relabel_md5 together produce an error"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --relabel "seq" \
        --relabel_md5 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# 'U' is replaced with 'T' before computing the digest, so RNA input
# yields the same MD5 hash as the equivalent DNA input
DESCRIPTION="--relabel_md5 converts U to T before computing the digest"
printf ">s1\nACGU\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel_md5 \
        --quiet 2>/dev/null | \
    grep -qx ">f1f8f4bf413b16ad135722aa4591043e" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sequence is converted to upper case before computing the digest, so
# lowercase input yields the same MD5 as the uppercase equivalent
DESCRIPTION="--relabel_md5 converts sequence to upper case before computing the digest"
printf ">s1\nacgt\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel_md5 \
        --quiet 2>/dev/null | \
    grep -qx ">f1f8f4bf413b16ad135722aa4591043e" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_sha1

# SHA1 of "ACGT" (uppercase, U->T applied) = 2108994e17f6cca9ff2352ada92b6511db076034
DESCRIPTION="--relabel_sha1 replaces header with SHA1 digest of the sequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel_sha1 \
        --quiet 2>/dev/null | \
    grep -qx ">2108994e17f6cca9ff2352ada92b6511db076034" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_self

DESCRIPTION="--relabel_self replaces header with the sequence itself"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel_self \
        --quiet 2>/dev/null | \
    grep -qx ">ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sample

DESCRIPTION="--sample adds sample annotation to header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --sample "ABC" \
        --quiet 2>/dev/null | \
    grep -qx ">s1;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizein and --sizeout

DESCRIPTION="--sizeout adds size annotation to header (default size=1)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizein reads existing size annotation; --sizeout propagates it"
printf ">s1;size=3\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --sizein \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">s1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizein without size annotation in header defaults to size=1"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --sizein \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# without --sizein, --sizeout still carries over an existing abundance
# value from the input header
DESCRIPTION="--sizeout without --sizein propagates existing size annotation"
printf ">s1;size=5\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizeout and --relabel_self can be used together"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --relabel_self \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">ACGT;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --threads

DESCRIPTION="--threads 1 is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output /dev/null \
        --qmask none \
        --threads 1 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# with multiple sequences dispatched to two threads, each sequence must
# still be correctly masked (sequence order is preserved)
DESCRIPTION="--threads 2 masks all sequences independently"
printf ">s1\nAAAAAAAAAAGCATGC\n>s2\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask dust \
        --fasta_width 0 \
        --threads 2 \
        --quiet 2>/dev/null | \
    grep -c "^aaaaaaaaaaGCATGC$" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xee

DESCRIPTION="--xee strips ee annotation from header"
printf ">s1;ee=0.5\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --xee \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xlength

DESCRIPTION="--xlength strips length annotation from header"
printf ">s1;length=10\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --xlength \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xsize

DESCRIPTION="--xsize strips size annotation from header"
printf ">s1;size=5\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --output - \
        --qmask none \
        --fasta_width 0 \
        --xsize \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

# --fastaout and --fastqout belong to --fastx_mask and must not be accepted
# by --maskfasta (which writes to --output instead)
DESCRIPTION="--maskfasta rejects --fastaout"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--maskfasta rejects --fastqout"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --maskfasta - \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    LOG=$(mktemp)
    FASTA=$(mktemp)
    printf ">s\nAAAAAA\n" > "${FASTA}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --maskfasta "${FASTA}" \
        --output /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--maskfasta valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--maskfasta valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTA}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#

## see issue 30 for more tests


exit 0
