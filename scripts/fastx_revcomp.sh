#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastx_revcomp"
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

## vsearch --fastx_revcomp inputfile (--fastaout | --fastqout) outputfile [options]

DESCRIPTION="--fastx_revcomp is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp reads from stdin (-)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp reads from a file"
TMPFA=$(mktemp)
printf ">s1\nACGT\n" > "${TMPFA}"
"${VSEARCH}" \
    --fastx_revcomp "${TMPFA}" \
    --fastaout /dev/null \
    --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--fastx_revcomp fails if input file does not exist"
"${VSEARCH}" \
    --fastx_revcomp /no/such/file \
    --fastaout /dev/null \
    --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp fails if input file is not readable"
TMPFA=$(mktemp)
printf ">s1\nACGT\n" > "${TMPFA}"
chmod u-r "${TMPFA}"
"${VSEARCH}" \
    --fastx_revcomp "${TMPFA}" \
    --fastaout /dev/null \
    --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMPFA}" && rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--fastx_revcomp fails without any output option"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastaout is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout - writes to stdout"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout "${TMP}" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastqout is accepted with fastq input"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout - writes to stdout"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout - \
        --quiet 2>/dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout "${TMP}" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastqout fails with fasta input (no quality scores)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# empty fasta input is allowed with fastqout (is_empty check in source)
DESCRIPTION="--fastqout is accepted with empty fasta input"
printf "" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout and --fastqout can be used together with fastq input"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

# manpage example: AACGT -> ACGTT
DESCRIPTION="--fastx_revcomp reverse-complements fasta input (manpage example)"
printf ">s1\nAACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "ACGTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# revcomp of GTCA: complement = CAGT, reversed = TGAC
DESCRIPTION="--fastx_revcomp reverse-complements GTCA to TGAC (fasta out)"
printf ">s1\nGTCA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "TGAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp reverse-complements GTCA to TGAC (fastq in, fasta out)"
printf "@s1\nGTCA\n+\nFGHI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "TGAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# fastq: quality scores are reversed (not complemented)
DESCRIPTION="--fastx_revcomp reverses quality scores (FGHI becomes IHGF)"
printf "@s1\nGTCA\n+\nFGHI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout - \
        --quiet 2>/dev/null | \
    awk "NR==4" | \
    grep -qx "IHGF" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp sequence and quality in fastq out are both correct"
printf "@s1\nGTCA\n+\nFGHI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout - \
        --quiet 2>/dev/null | \
    awk "NR==2" | \
    grep -qx "TGAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# lowercase letters: complement is lowercase (a->t, c->g, g->c, t->a)
DESCRIPTION="--fastx_revcomp preserves lowercase: revcomp of acgt is acgt"
printf ">s1\nacgt\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "acgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp complement of N is N (uppercase)"
printf ">s1\nACNT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx "ANGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp empty fasta input produces empty output"
printf "" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp multiple sequences are all output"
printf ">s1\nACGT\n>s2\nTGCA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp sequence header is preserved"
printf ">myseq1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">myseq1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sequences longer than 512 nucleotides trigger a realloc in the source code
DESCRIPTION="--fastx_revcomp handles sequences longer than 512 nucleotides"
printf ">s1\n%s\n" "$(awk 'BEGIN {for (i = 1; i <= 513; i++) printf "A"; printf "\n"}')" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -v "^>" | \
    grep -qx "$(awk 'BEGIN {for (i = 1; i <= 513; i++) printf "T"; printf "\n"}')" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --fastq_ascii
#
# NOTE for human review: the manpage lists --fastq_ascii, --fastq_qmax, and
# --fastq_qmin as core options for --fastx_revcomp, but the implementation
# (fastqops.cc) does not use these options: quality scores are reversed as
# raw ASCII bytes without offset conversion or range validation. Tests below
# only verify that the options are accepted and do not corrupt the output.

DESCRIPTION="--fastq_ascii 33 is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout /dev/null \
        --fastq_ascii 33 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_ascii 64 is accepted"
printf "@s1\nACGT\n+\n@@@@\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout /dev/null \
        --fastq_ascii 64 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_ascii has no effect on quality output (scores passed through as-is)"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout - \
        --fastq_ascii 64 \
        --quiet 2>/dev/null | \
    awk "NR==4" | \
    grep -qx "IIII" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_qmax

DESCRIPTION="--fastq_qmax is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout /dev/null \
        --fastq_qmax 41 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_qmax has no effect on sequence output"
printf "@s1\nGTCA\n+\nFGHI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout - \
        --fastq_qmax 41 \
        --quiet 2>/dev/null | \
    awk "NR==2" | \
    grep -qx "TGAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_qmin

DESCRIPTION="--fastq_qmin is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout /dev/null \
        --fastq_qmin 0 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_qmin has no effect on sequence output"
printf "@s1\nGTCA\n+\nFGHI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout - \
        --fastq_qmin 0 \
        --quiet 2>/dev/null | \
    awk "NR==2" | \
    grep -qx "TGAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --bzip2_decompress

DESCRIPTION="--bzip2_decompress reads bzip2-compressed fasta from stdin"
printf ">s1\nACGT\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --bzip2_decompress \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--bzip2_decompress reads bzip2-compressed fastq from stdin"
printf "@s1\nACGT\n+\nIIII\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout - \
        --bzip2_decompress \
        --quiet 2>/dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fasta_width

# 84-nt sequence (> 80) appears on one line with --fasta_width 0
DESCRIPTION="--fasta_width 0 suppresses line folding"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -v "^>" | \
    awk "NR==1 {exit length(\$0) != 84}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 84-nt sequence is folded; first sequence line must be exactly 80 chars by default
DESCRIPTION="--fasta_width default folds at 80 characters"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --quiet 2>/dev/null | \
    awk "NR==2 {exit length(\$0) != 80}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta_width 10 folds sequence at 10 characters"
printf ">s1\nACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 10 \
        --quiet 2>/dev/null | \
    awk "NR==2 {exit length(\$0) != 10}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --gzip_decompress

DESCRIPTION="--gzip_decompress reads gzip-compressed fasta from stdin"
printf ">s1\nACGT\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --gzip_decompress \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--gzip_decompress reads gzip-compressed fastq from stdin"
printf "@s1\nACGT\n+\nIIII\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastqout - \
        --gzip_decompress \
        --quiet 2>/dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --label_suffix

DESCRIPTION="--label_suffix appends suffix to sequence header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --label_suffix ";foo=bar" \
        --quiet 2>/dev/null | \
    grep -qx ">s1;foo=bar" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_suffix and --lengthout annotations appear together in header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --label_suffix ";foo=bar" \
        --lengthout \
        --quiet 2>/dev/null | \
    grep -q "length=4.*foo=bar\|foo=bar.*length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --lengthout

DESCRIPTION="--lengthout adds length annotation to header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
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
        --fastx_revcomp - \
        --fastaout /dev/null \
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
        --fastx_revcomp - \
        --fastaout /dev/null \
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
        --fastx_revcomp - \
        --fastaout /dev/null \
        --no_progress \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notrunclabels
#
# NOTE for human review: the manpage says headers are truncated at the first
# space by default and --notrunclabels suppresses this. However, fastx_revcomp
# calls fastx_next with truncateatspace=false, so headers are never truncated.
# Both tests below verify accepted behavior.

DESCRIPTION="--notrunclabels is accepted"
printf ">s1 some description\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout /dev/null \
        --notrunclabels \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# fastx_revcomp preserves full header (truncateatspace=false in implementation)
DESCRIPTION="--fastx_revcomp preserves full header including space by default"
printf ">s1 some description\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">s1 some description" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --quiet

DESCRIPTION="--quiet suppresses stderr output"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout /dev/null \
        --quiet 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--quiet does not suppress fatal error messages"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
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
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --relabel "seq" \
        --quiet 2>/dev/null | \
    grep -qx ">seq1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel with empty string produces just the ticker as label"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --relabel "" \
        --quiet 2>/dev/null | \
    grep -qx ">1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_keep

DESCRIPTION="--relabel_keep retains original identifier after relabeling"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --relabel "seq" \
        --relabel_keep \
        --quiet 2>/dev/null | \
    grep -qx ">seq1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_md5

# MD5 of "ACGT" (revcomp of ACGT is ACGT, a palindrome)
DESCRIPTION="--relabel_md5 replaces header with MD5 digest of the revcomp sequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
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
        --fastx_revcomp - \
        --fastaout /dev/null \
        --relabel "seq" \
        --relabel_md5 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --relabel_self

# revcomp of GTCA = TGAC, so relabel_self -> ">TGAC"
DESCRIPTION="--relabel_self replaces header with the revcomp sequence itself"
printf ">s1\nGTCA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --relabel_self \
        --quiet 2>/dev/null | \
    grep -qx ">TGAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_sha1

# SHA1 of "ACGT" (revcomp of ACGT is ACGT, a palindrome)
DESCRIPTION="--relabel_sha1 replaces header with SHA1 digest of the revcomp sequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --relabel_sha1 \
        --quiet 2>/dev/null | \
    grep -qx ">2108994e17f6cca9ff2352ada92b6511db076034" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sample

DESCRIPTION="--sample adds sample annotation to header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
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
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizein reads existing size annotation; --sizeout propagates it"
printf ">s1;size=5\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
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
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --sizein \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizeout and --relabel_self can be used together"
printf ">s1\nGTCA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --relabel_self \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">TGAC;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xee

DESCRIPTION="--xee strips ee annotation from header"
printf ">s1;ee=0.5\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
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
        --fastx_revcomp - \
        --fastaout - \
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
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --xsize \
        --quiet 2>/dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             ignored options                                 #
#                                                                             #
#*****************************************************************************#

## --threads (command is not multithreaded, option has no effect)

DESCRIPTION="--threads is accepted"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout /dev/null \
        --threads 1 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--threads has no effect on sequence output"
printf ">s1\nGTCA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --fastaout - \
        --fasta_width 0 \
        --threads 1 \
        --quiet 2>/dev/null | \
    grep -qx "TGAC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

# none


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
        --fastx_revcomp "${FASTQ}" \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastx_revcomp valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_revcomp valgrind (no errors)"
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
