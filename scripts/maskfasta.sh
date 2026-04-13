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

# none


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
