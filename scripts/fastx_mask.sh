#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastx_mask"
LINE=$(printf -- "-%.0s" {1..76})
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

## vsearch --fastx_mask fastxfile (--fastaout | --fastqout) outputfile [options]

DESCRIPTION="--fastx_mask is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask reads from stdin (-)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask reads from a file"
TMPFA=$(mktemp)
printf ">s1\nACGT\n" > "${TMPFA}"
"${VSEARCH}" \
    --fastx_mask "${TMPFA}" \
    --fastaout /dev/null \
    --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--fastx_mask fails if input file does not exist"
"${VSEARCH}" \
    --fastx_mask /no/such/file \
    --fastaout /dev/null \
    --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask fails without an output option"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastaout is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout - writes to stdout"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout is accepted with fastq input"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout - writes to stdout"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout - \
        --qmask none \
        --quiet 2>/dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout fails with fasta input"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastaout and --fastqout can be used together"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# coverage: mask.cc (unable to open fasta output file)
DESCRIPTION="--fastaout fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout "${TMP}" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

# coverage: mask.cc (unable to open fastq output file)
DESCRIPTION="--fastqout fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout "${TMP}" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastaout with fastq input drops the quality scores"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout and --fastqout together produce both output streams"
TMPFA=$(mktemp)
TMPFQ=$(mktemp)
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout "${TMPFA}" \
        --fastqout "${TMPFQ}" \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null
[[ -s "${TMPFA}" ]] && [[ -s "${TMPFQ}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPFA}" "${TMPFQ}"
unset TMPFA TMPFQ


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

# ten A's followed by GCATGC: DUST masks the poly-A run
DESCRIPTION="--fastx_mask default masking is dust (low-complexity region is lowercased)"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "aaaaaaaaaaGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask non-low-complexity sequence is unchanged"
printf ">s1\nACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask empty fasta input produces empty output"
printf "" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask multiple sequences are all output"
printf ">s1\nACGT\n>s2\nTGCA\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask sequence header is preserved"
printf ">myseq1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">myseq1" && \
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
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask dust \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask soft is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask soft \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask none is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask with no argument fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--qmask with invalid value fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask invalid \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--qmask dust lowercases low-complexity region in fasta input"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask dust \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "aaaaaaaaaaGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask dust lowercases low-complexity region in fastq input"
printf "@s1\nAAAAAAAAAAGCATGC\n+\nIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout - \
        --qmask dust \
        --quiet 2>/dev/null | \
    grep -qx "aaaaaaaaaaGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask dust does not alter quality scores"
printf "@s1\nAAAAAAAAAAGCATGC\n+\nIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout - \
        --qmask dust \
        --quiet 2>/dev/null | \
    awk "NR==4" | \
    grep -qx "IIIIIIIIIIIIIIII" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask none leaves uppercase sequence unchanged"
printf ">s1\nACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask none preserves existing lowercase letters"
printf ">s1\naaGCATGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "aaGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask soft preserves existing lowercase letters"
printf ">s1\naaGCATGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout /dev/null \
        --hardmask \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--hardmask with --qmask dust replaces low-complexity region with Ns (fasta)"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask dust \
        --hardmask \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "NNNNNNNNNNGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--hardmask with --qmask dust replaces low-complexity region with Ns (fastq)"
printf "@s1\nAAAAAAAAAAGCATGC\n+\nIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout - \
        --qmask dust \
        --hardmask \
        --quiet 2>/dev/null | \
    grep -qx "NNNNNNNNNNGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--hardmask with --qmask soft replaces existing lowercase with Ns"
printf ">s1\naaGCATGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --hardmask \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "AAAAAAAAAAGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--hardmask with --qmask soft and all-uppercase input leaves sequence unchanged"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask soft \
        --hardmask \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "AAAAAAAAAAGCATGC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--hardmask output sequence contains no lowercase letters"
printf ">s1\nAAAAAAAAAAGCATGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask dust \
        --hardmask \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -v "^>" | \
    grep -q "[a-z]" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --max_unmasked_pct and --min_unmasked_pct

DESCRIPTION="--max_unmasked_pct is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --max_unmasked_pct 100 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--min_unmasked_pct is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --min_unmasked_pct 0 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--max_unmasked_pct with no argument fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --max_unmasked_pct \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--min_unmasked_pct with no argument fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --min_unmasked_pct \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--max_unmasked_pct with non-numeric value fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --max_unmasked_pct abc \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--min_unmasked_pct with non-numeric value fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --min_unmasked_pct abc \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--max_unmasked_pct 100 retains all sequences"
printf ">s1\nACGT\n>s2\nTGCA\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --max_unmasked_pct 100 \
        --quiet 2>/dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--min_unmasked_pct 0 retains all sequences"
printf ">s1\nACGT\n>s2\nTGCA\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --min_unmasked_pct 0 \
        --quiet 2>/dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# atGC: 2 masked (at) out of 4 = 50% unmasked; fails min_unmasked_pct 100
DESCRIPTION="--min_unmasked_pct 100 filters out partially masked sequences"
printf ">s1\natGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask soft \
        --min_unmasked_pct 100 \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# atGC: 2 uppercase (GC) out of 4 = 50% unmasked
DESCRIPTION="--min_unmasked_pct 50 keeps sequence with exactly 50% unmasked"
printf ">s1\natGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask soft \
        --fasta_width 0 \
        --min_unmasked_pct 50 \
        --quiet 2>/dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--min_unmasked_pct 51 discards sequence with 50% unmasked"
printf ">s1\natGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask soft \
        --min_unmasked_pct 51 \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--max_unmasked_pct 50 keeps sequence with exactly 50% unmasked"
printf ">s1\natGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask soft \
        --fasta_width 0 \
        --max_unmasked_pct 50 \
        --quiet 2>/dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--max_unmasked_pct 49 discards sequence with 50% unmasked"
printf ">s1\natGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask soft \
        --max_unmasked_pct 49 \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# --max_unmasked_pct 0 keeps only sequences where every residue is masked
DESCRIPTION="--max_unmasked_pct 0 discards a fully-unmasked sequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --max_unmasked_pct 0 \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--min_unmasked_pct 100 keeps a fully-unmasked sequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --min_unmasked_pct 100 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# both filters combined: only sequences whose unmasked fraction lies in
# the [25%, 75%] window are kept; atGC (50%) passes, ACGT (100%) and
# atgc (0%) do not
DESCRIPTION="--min_unmasked_pct and --max_unmasked_pct combine as a range"
printf ">s1\nACGT\n>s2\natGC\n>s3\natgc\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask soft \
        --fasta_width 0 \
        --min_unmasked_pct 25 \
        --max_unmasked_pct 75 \
        --quiet 2>/dev/null | \
    grep "^>" | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--max_unmasked_pct > 100 fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --max_unmasked_pct 101 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--min_unmasked_pct < 0 fails"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --min_unmasked_pct -1 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# coverage: mask.cc (stderr message when min_unmasked_pct discards sequences)
# atGC: 2 lowercase + 2 uppercase = 50% unmasked; 50% < 51% -> discarded
DESCRIPTION="--min_unmasked_pct discards are reported on stderr"
printf ">s1\natGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask soft \
        --min_unmasked_pct 51 \
        2>&1 | \
    grep -q "sequences with less than" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# coverage: mask.cc (stderr message when max_unmasked_pct discards sequences)
# ACGT: all uppercase = 100% unmasked; 100% > 49% -> discarded
DESCRIPTION="--max_unmasked_pct discards are reported on stderr"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --max_unmasked_pct 49 \
        2>&1 | \
    grep -q "sequences with more than" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# coverage: mask.cc (log message when min_unmasked_pct discards sequences)
DESCRIPTION="--min_unmasked_pct discards are written to --log"
TMPLOG=$(mktemp)
printf ">s1\natGC\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask soft \
        --min_unmasked_pct 51 \
        --log "${TMPLOG}" \
        --quiet 2>/dev/null
grep -q "sequences with less than" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG

# coverage: mask.cc (log message when max_unmasked_pct discards sequences)
DESCRIPTION="--max_unmasked_pct discards are written to --log"
TMPLOG=$(mktemp)
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --max_unmasked_pct 49 \
        --log "${TMPLOG}" \
        --quiet 2>/dev/null
grep -q "sequences with more than" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG


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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --quiet 2>/dev/null | \
    awk "NR==2 {exit length(\$0) != 80}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta_width 10 folds sequence at 10 characters"
printf ">s1\nACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 10 \
        --quiet 2>/dev/null | \
    awk "NR==2 {exit length(\$0) != 10}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --bzip2_decompress

DESCRIPTION="--bzip2_decompress reads bzip2-compressed fasta from stdin"
printf ">s1\nACGT\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --bzip2_decompress \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--bzip2_decompress reads bzip2-compressed fastq from stdin"
printf "@s1\nACGT\n+\nIIII\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout - \
        --bzip2_decompress \
        --qmask none \
        --quiet 2>/dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--bzip2_decompress fails on an uncompressed input pipe"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
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
        --fastx_mask - \
        --fastaout - \
        --gzip_decompress \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--gzip_decompress reads gzip-compressed fastq from stdin"
printf "@s1\nACGT\n+\nIIII\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout - \
        --gzip_decompress \
        --qmask none \
        --quiet 2>/dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# gzip detects an uncompressed stream and passes it through unchanged
DESCRIPTION="--gzip_decompress passes through an uncompressed input pipe"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --gzip_decompress \
        --qmask none \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_ascii

DESCRIPTION="--fastq_ascii 33 is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --qmask none \
        --fastq_ascii 33 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# quality '@' = ASCII 64, offset 64 -> quality score 0
DESCRIPTION="--fastq_ascii 64 is accepted"
printf "@s1\nACGT\n+\n@@@@\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --qmask none \
        --fastq_ascii 64 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# offset is restricted to either 33 or 64
DESCRIPTION="--fastq_ascii with a value other than 33 or 64 fails"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --qmask none \
        --fastq_ascii 50 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_qmax

DESCRIPTION="--fastq_qmax is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --qmask none \
        --fastq_qmax 41 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_qmax has no effect on sequence content"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout - \
        --qmask none \
        --fastq_qmax 41 \
        --quiet 2>/dev/null | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# with offset 33, fastq_qmax + fastq_ascii must fit in the ASCII range,
# i.e. qmax <= 93
DESCRIPTION="--fastq_qmax above 93 (with default offset 33) fails"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --qmask none \
        --fastq_qmax 94 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_qmin

DESCRIPTION="--fastq_qmin is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --qmask none \
        --fastq_qmin 0 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_qmin has no effect on sequence content"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout - \
        --qmask none \
        --fastq_qmin 0 \
        --quiet 2>/dev/null | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# the minimum accepted quality score cannot exceed the maximum (default
# --fastq_qmax is 41)
DESCRIPTION="--fastq_qmin greater than --fastq_qmax fails"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --qmask none \
        --fastq_qmin 50 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# with default offset 33, fastq_qmin must keep the ASCII sum >= 33
DESCRIPTION="--fastq_qmin below 0 (with default offset 33) fails"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastqout /dev/null \
        --qmask none \
        --fastq_qmin -1 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --label_suffix

DESCRIPTION="--label_suffix appends suffix to sequence header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout /dev/null \
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
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --log "${TMPLOG}" \
        2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG

## --no_progress

DESCRIPTION="--no_progress is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --no_progress \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notrunclabels

DESCRIPTION="--notrunclabels preserves full header including space"
printf ">s1 some description\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --quiet 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--quiet does not suppress fatal error messages"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout "${TMP}" \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --relabel "seq" \
        --relabel_keep \
        --quiet 2>/dev/null | \
    grep -qx ">seq1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_md5

# MD5 of "ACGT" (uppercase, U->T applied) = f1f8f4bf413b16ad135722aa4591043e
DESCRIPTION="--relabel_md5 replaces header with MD5 digest of the sequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout /dev/null \
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
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --relabel_md5 \
        --quiet 2>/dev/null | \
    grep -qx ">f1f8f4bf413b16ad135722aa4591043e" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel_md5 converts sequence to upper case before computing the digest"
printf ">s1\nacgt\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizein reads existing size annotation; --sizeout propagates it"
printf ">s1;size=5\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
        --qmask none \
        --fasta_width 0 \
        --sizein \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizein without size annotation in header defaults to size=1"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout /dev/null \
        --qmask none \
        --threads 1 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xee

DESCRIPTION="--xee strips ee annotation from header"
printf ">s1;ee=0.5\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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
        --fastx_mask - \
        --fastaout - \
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

# --output belongs to --maskfasta (the deprecated command); --fastx_mask
# writes through --fastaout and/or --fastqout instead
DESCRIPTION="--fastx_mask rejects --output"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_mask - \
        --output /dev/null \
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
    FASTQ=$(mktemp)
    printf "@s\nAAAAAA\n+\nIIIIII\n" > "${FASTQ}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastx_mask "${FASTQ}" \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastx_mask valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_mask valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTQ}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
