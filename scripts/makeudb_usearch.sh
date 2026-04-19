#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="makeudb_usearch"
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

## vsearch --makeudb_usearch fastafile --output outputfile [options]

## a 32-nt sequence satisfies the default --minseqlength (32)
SEQ="ACGTACGTACGTACGTACGTACGTACGTACGT"

DESCRIPTION="--makeudb_usearch is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--makeudb_usearch reads from stdin (-)"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--makeudb_usearch reads from a regular file"
TMPFA=$(mktemp)
printf ">s\n%s\n" "${SEQ}" > "${TMPFA}"
"${VSEARCH}" \
    --makeudb_usearch "${TMPFA}" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--makeudb_usearch fails if input file does not exist"
"${VSEARCH}" \
    --makeudb_usearch /no/such/file \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--makeudb_usearch fails if input file is not readable"
TMPFA=$(mktemp)
printf ">s\n%s\n" "${SEQ}" > "${TMPFA}"
chmod u-r "${TMPFA}"
"${VSEARCH}" \
    --makeudb_usearch "${TMPFA}" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMPFA}" && rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--makeudb_usearch fails with non-fasta input"
printf "not a fasta file\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --output is mandatory
DESCRIPTION="--makeudb_usearch fails without --output"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--output writes to a regular file"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
[[ -s "${TMPUDB}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--output fails if destination is not writable"
TMPDIR=$(mktemp -d)
chmod u-w "${TMPDIR}"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output "${TMPDIR}/out.udb" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMPDIR}" && rm -rf "${TMPDIR}"
unset TMPDIR


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## by default, vsearch truncates sequence headers at the first space
DESCRIPTION="--makeudb_usearch truncates headers at first space by default"
TMPUDB=$(mktemp)
TMPFA=$(mktemp)
printf ">s1 extra header\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output "${TMPFA}" \
    --quiet 2> /dev/null
grep -qx ">s1" "${TMPFA}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPFA}"
unset TMPUDB TMPFA

## UDB files are binary and start with a magic signature 0x55444246
DESCRIPTION="--makeudb_usearch produces a binary UDB file"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --dbmask: none | dust | soft (default: dust)

DESCRIPTION="--dbmask is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask dust \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--dbmask accepts 'none'"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--dbmask accepts 'dust'"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask dust \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--dbmask accepts 'soft'"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask soft \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--dbmask rejects invalid values"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask invalid \
        --output /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## with --dbmask none, a low-complexity sequence is NOT masked (stays uppercase)
DESCRIPTION="--dbmask none leaves low-complexity sequence unmasked"
TMPUDB=$(mktemp)
printf ">s\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## with --dbmask dust (default), low-complexity regions become lowercase
DESCRIPTION="--dbmask dust soft-masks low-complexity regions (lowercase)"
TMPUDB=$(mktemp)
printf ">s\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask dust \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx "tttttttttttttttttttttttttttttttt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --hardmask: replace masked nucleotides with Ns

DESCRIPTION="--hardmask is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --hardmask \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --hardmask replaces masked nucleotides with Ns (with default dust)
DESCRIPTION="--hardmask replaces masked nucleotides with Ns"
TMPUDB=$(mktemp)
printf ">s\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --hardmask \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx "NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --wordlength: integer in [3, 15] (default: 8)

DESCRIPTION="--wordlength is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --wordlength 8 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--wordlength accepts minimum value (3)"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --wordlength 3 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--wordlength accepts maximum value (15)"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --wordlength 15 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--wordlength rejects value below minimum (2)"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --wordlength 2 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--wordlength rejects value above maximum (16)"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --wordlength 16 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --wordlength is recorded in the resulting UDB file
DESCRIPTION="--wordlength is stored in the UDB file"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --wordlength 10 \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" 2>&1 | \
    grep -qE "Word width[[:space:]]+10" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --bzip2_decompress: restricted to stdin

DESCRIPTION="--bzip2_decompress reads a bzip2-compressed pipe"
if command -v bzip2 > /dev/null 2>&1 ; then
    printf ">s\n%s\n" "${SEQ}" | bzip2 | \
        "${VSEARCH}" \
            --makeudb_usearch - \
            --bzip2_decompress \
            --output /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
else
    success "${DESCRIPTION} (bzip2 unavailable, skipped)"
fi

## --gzip_decompress: restricted to stdin

DESCRIPTION="--gzip_decompress reads a gzip-compressed pipe"
if command -v gzip > /dev/null 2>&1 ; then
    printf ">s\n%s\n" "${SEQ}" | gzip | \
        "${VSEARCH}" \
            --makeudb_usearch - \
            --gzip_decompress \
            --output /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
else
    success "${DESCRIPTION} (gzip unavailable, skipped)"
fi

## --log: write messages to a file

DESCRIPTION="--log is accepted"
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output /dev/null \
        --log "${TMPLOG}" 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG

DESCRIPTION="--log writes to the specified file"
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output /dev/null \
        --log "${TMPLOG}" 2> /dev/null
[[ -s "${TMPLOG}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG

## --maxseqlength: discard sequences longer than integer (default 50,000)

DESCRIPTION="--maxseqlength is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --maxseqlength 100 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--maxseqlength discards sequences above the threshold"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --maxseqlength 10 \
        --output /dev/null 2>&1 | \
    grep -qE "maxseqlength[[:space:]]+10:[[:space:]]+1[[:space:]]+sequence[[:space:]]+discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --minseqlength: discard sequences shorter than integer (default 32)

DESCRIPTION="--minseqlength is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --minseqlength 1 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--minseqlength discards sequences below the threshold"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --minseqlength 100 \
        --output /dev/null 2>&1 | \
    grep -qE "minseqlength[[:space:]]+100:[[:space:]]+1[[:space:]]+sequence[[:space:]]+discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## by default (minseqlength 32), a 8-nt sequence is discarded
DESCRIPTION="default --minseqlength (32) discards short sequences"
printf ">s\nACGTACGT\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output /dev/null 2>&1 | \
    grep -qE "minseqlength[[:space:]]+32:[[:space:]]+1[[:space:]]+sequence[[:space:]]+discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --no_progress: suppress progress indicator on stderr

DESCRIPTION="--no_progress is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --no_progress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notrunclabels: retain whole headers

DESCRIPTION="--notrunclabels is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --notrunclabels \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notrunclabels retains whole headers"
TMPUDB=$(mktemp)
TMPFA=$(mktemp)
printf ">s1 extra header\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --notrunclabels \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output "${TMPFA}" \
    --quiet 2> /dev/null
grep -qx ">s1 extra header" "${TMPFA}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPFA}"
unset TMPUDB TMPFA

## --quiet: suppress informational messages on stdout/stderr

DESCRIPTION="--quiet is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--quiet suppresses stderr output"
TMPERR=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output /dev/null \
        --quiet 2> "${TMPERR}"
[[ ! -s "${TMPERR}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPERR}"
unset TMPERR

## combination: --notrunclabels and --dbmask none
DESCRIPTION="--notrunclabels combined with --dbmask is accepted"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --notrunclabels \
        --dbmask none \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## --threads: accepted but command is not multithreaded

DESCRIPTION="--threads is accepted (ignored, no observable effect)"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --threads 2 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## makeudb_usearch reads fasta (not fastq), so fastq-related options are
## rejected
DESCRIPTION="--fastq_ascii is rejected"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --fastq_ascii 33 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## abundance is not stored in UDB files, so --sizein is rejected by
## makeudb_usearch
DESCRIPTION="--sizein is rejected (abundance not stored in UDB)"
printf ">s;size=5;\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --sizein \
        --output /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fasta_width is meant for output of fasta files, not for UDB output
DESCRIPTION="--fasta_width is rejected"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --fasta_width 0 \
        --output /dev/null \
        --quiet 2> /dev/null && \
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
    UDB=$(mktemp)
    printf "@s\nACGTACGT\n+\nIIIIIIII\n" > "${FASTQ}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --makeudb_usearch "${FASTQ}" \
        --threads 2 \
        --minseqlength 1 \
        --output "${UDB}" \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--makeudb_usearch valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--makeudb_usearch valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTQ}" "${UDB}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


unset SEQ
exit 0
