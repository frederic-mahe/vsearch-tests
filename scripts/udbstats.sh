#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="udbstats"
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

## vsearch --udbstats udbfile [options]

SEQ="ACGTACGTACGTACGTACGTACGTACGTACGT"

DESCRIPTION="--udbstats is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--udbstats fails if UDB file does not exist"
"${VSEARCH}" \
    --udbstats /no/such/file \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--udbstats fails with a non-UDB input file"
TMPFA=$(mktemp)
printf ">s\n%s\n" "${SEQ}" > "${TMPFA}"
"${VSEARCH}" \
    --udbstats "${TMPFA}" \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPFA}"
unset TMPFA

## a UDB file must be at least 200 bytes (50 header uint32_t values)
DESCRIPTION="--udbstats fails on a truncated UDB file (< 200 bytes)"
TMPUDB=$(mktemp)
TMPTRUNC=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
head -c 4 "${TMPUDB}" > "${TMPTRUNC}"
"${VSEARCH}" \
    --udbstats "${TMPTRUNC}" \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPTRUNC}"
unset TMPUDB TMPTRUNC

## a ≥ 200 byte non-UDB file passes the size check but fails validation
DESCRIPTION="--udbstats rejects a large non-UDB file (bad signature)"
TMPBAD=$(mktemp)
head -c 600 /dev/urandom > "${TMPBAD}"
"${VSEARCH}" \
    --udbstats "${TMPBAD}" \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPBAD}"
unset TMPBAD

DESCRIPTION="--udbstats fails if input file is not readable"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
chmod u-r "${TMPUDB}"
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMPUDB}" && rm -f "${TMPUDB}"
unset TMPUDB

## --udbstats rejects a pipe as input (UDB detection requires stat-able file)
DESCRIPTION="--udbstats rejects a pipe as input"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats - \
    --quiet < "${TMPUDB}" 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --udbstats also rejects a stat-able pipe (/dev/stdin backed by a FIFO)
DESCRIPTION="--udbstats rejects /dev/stdin when it is a pipe"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
# shellcheck disable=SC2002
cat "${TMPUDB}" | \
    "${VSEARCH}" \
        --udbstats /dev/stdin \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## NOTE: according to the manpage, --udbstats writes its report to stdout,
## but in practice the output is written to stderr (see src/udb.cc). The
## tests below match the actual behaviour.

DESCRIPTION="--udbstats reports the total nucleotide and sequence counts"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" 2>&1 | \
    grep -qE "32 nt in 1 seqs" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--udbstats reports alphabet, word width, slots, and DB accel (via log)"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "Alphabet[[:space:]]+nt" "${TMPLOG}" && \
    grep -qE "Word width[[:space:]]+8" "${TMPLOG}" && \
    grep -qE "Slots" "${TMPLOG}" && \
    grep -qE "DBAccel" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

DESCRIPTION="--udbstats reports a word-frequency distribution table (via log)"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "Size lo" "${TMPLOG}" && \
    grep -qE "Nr. Words" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

## the log header also reports Word ones / Spaced / Hashed / Coded / Stepped
DESCRIPTION="--udbstats reports Word ones / Spaced / Hashed / Coded / Stepped (via log)"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "Word ones[[:space:]]+8" "${TMPLOG}" && \
    grep -qE "Spaced[[:space:]]+No" "${TMPLOG}" && \
    grep -qE "Hashed[[:space:]]+No" "${TMPLOG}" && \
    grep -qE "Coded[[:space:]]+No" "${TMPLOG}" && \
    grep -qE "Stepped[[:space:]]+No" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

## the log reports DB size / Words / Median size / Mean size
DESCRIPTION="--udbstats reports DB size / Words / Median / Mean size (via log)"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "DB size" "${TMPLOG}" && \
    grep -qE "Words$" "${TMPLOG}" && \
    grep -qE "Median size" "${TMPLOG}" && \
    grep -qE "Mean size" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

## the log reports the per-word table header and Max size
DESCRIPTION="--udbstats reports the per-word table header and Max size (via log)"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "iWord" "${TMPLOG}" && \
    grep -qE "sWord" "${TMPLOG}" && \
    grep -qE "Cap" "${TMPLOG}" && \
    grep -qE "Row" "${TMPLOG}" && \
    grep -qE "Max size" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

## the log trailer reports Upper / Lower / Total / Indexed words
DESCRIPTION="--udbstats reports Upper / Lower / Total / Indexed words (via log)"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "[0-9]+[[:space:]]+Upper" "${TMPLOG}" && \
    grep -qE "Lower" "${TMPLOG}" && \
    grep -qE "[0-9]+[[:space:]]+Total$" "${TMPLOG}" && \
    grep -qE "Indexed words" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

## sequence counts reflect the input
DESCRIPTION="--udbstats reports the correct count for a 2-sequence UDB"
TMPUDB=$(mktemp)
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" 2>&1 | \
    grep -qE "64 nt in 2 seqs" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## nine identical sequences make a kmer appear nine times, which exercises
## both the "list sequences for a kmer" inner loop (capped at 8 entries)
## and the trailing "..." marker for buckets with more than 8 matches
DESCRIPTION="--udbstats truncates per-kmer sequence lists above 8 entries"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
TMPFA=$(mktemp)
for i in 1 2 3 4 5 6 7 8 9 ; do
    printf ">s%d\n%s\n" "${i}" "${SEQ}"
done > "${TMPFA}"
"${VSEARCH}" \
    --makeudb_usearch "${TMPFA}" \
    --dbmask none \
    --wordlength 3 \
    --output "${TMPUDB}" \
    --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "\.\.\." "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}" "${TMPFA}"
unset TMPUDB TMPLOG TMPFA

## with ≥ 5 sequences the size-bucket widths grow beyond 1,
## causing both the size_lo column to be populated and size_hi
## to be doubled (rather than incremented from zero)
DESCRIPTION="--udbstats widens size buckets beyond 1 when seqcount ≥ 5"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
TMPFA=$(mktemp)
for i in 1 2 3 4 5 6 7 8 9 ; do
    printf ">s%d\n%s\n" "${i}" "${SEQ}"
done > "${TMPFA}"
"${VSEARCH}" \
    --makeudb_usearch "${TMPFA}" \
    --dbmask none \
    --wordlength 3 \
    --output "${TMPUDB}" \
    --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "^[[:space:]]+3[[:space:]]+4" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}" "${TMPFA}"
unset TMPUDB TMPLOG TMPFA

## word width recorded at UDB creation is reported by udbstats
DESCRIPTION="--udbstats reports a non-default word width (10) in the log"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --wordlength 10 \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "Word width[[:space:]]+10" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

## udbstats formats large count and size values with a 'k' suffix
## (via %9.1fk) instead of the plain %10.1f decimal representation.
## Ten identical ~10,010-nt sequences produce a kmerindexsize of
## ~92,000, which drives the "DB size", "Indexed words" and
## per-bucket "Total size" printouts into the >= 10,000 branch.
DESCRIPTION="--udbstats formats DB size with a 'k' suffix for large UDBs"
TMPFA=$(mktemp)
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
SEQ10K=$(LC_ALL=C tr -dc 'ACGT' < /dev/urandom | head -c 10010)
for i in 1 2 3 4 5 6 7 8 9 10 ; do
    printf ">s%d\n%s\n" "${i}" "${SEQ10K}"
done > "${TMPFA}"
"${VSEARCH}" \
    --makeudb_usearch "${TMPFA}" \
    --dbmask none \
    --output "${TMPUDB}" \
    --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "DB size \([0-9]+\.[0-9]+k\)" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPFA}" "${TMPUDB}" "${TMPLOG}"
unset TMPFA TMPUDB TMPLOG SEQ10K

## the per-bucket "Total size" column also uses the 'k' suffix when
## a bucket accumulates >= 10,000 word occurrences (line 802-803 of
## src/udb.cc). With ten identical large sequences, every shared kmer
## has count = 10 and all fall into the last bucket, whose accumulated
## size exceeds 92,000.
DESCRIPTION="--udbstats formats bucket 'Total size' with a 'k' suffix for full buckets"
TMPFA=$(mktemp)
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
SEQ10K=$(LC_ALL=C tr -dc 'ACGT' < /dev/urandom | head -c 10010)
for i in 1 2 3 4 5 6 7 8 9 10 ; do
    printf ">s%d\n%s\n" "${i}" "${SEQ10K}"
done > "${TMPFA}"
"${VSEARCH}" \
    --makeudb_usearch "${TMPFA}" \
    --dbmask none \
    --output "${TMPUDB}" \
    --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "[0-9]+\.[0-9]+k[[:space:]]+[0-9]+\.[0-9]+[[:space:]]+[0-9]+\.[0-9]+%" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPFA}" "${TMPUDB}" "${TMPLOG}"
unset TMPFA TMPUDB TMPLOG SEQ10K


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --log: write messages to a file

DESCRIPTION="--log is accepted"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --log "${TMPLOG}" 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

DESCRIPTION="--log writes to the specified file"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --log "${TMPLOG}" 2> /dev/null
[[ -s "${TMPLOG}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

## --no_progress

DESCRIPTION="--no_progress is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --no_progress \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --quiet

DESCRIPTION="--quiet is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--quiet suppresses the stats report"
TMPUDB=$(mktemp)
TMPERR=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --quiet 2> "${TMPERR}"
[[ ! -s "${TMPERR}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPERR}"
unset TMPUDB TMPERR


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## --threads: accepted but command is not multithreaded

DESCRIPTION="--threads is accepted (ignored, no observable effect)"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --threads 2 \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## --output is not accepted (udbstats writes its report to stderr, not
## to a named output file)
DESCRIPTION="--output is rejected"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --wordlength is fixed at UDB creation time
DESCRIPTION="--wordlength is rejected"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --wordlength 8 \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --minseqlength is not accepted
DESCRIPTION="--minseqlength is rejected"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbstats "${TMPUDB}" \
    --minseqlength 1 \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    LOG=$(mktemp)
    UDB=$(mktemp)
    printf "@s\nACGTACGT\n+\nIIIIIIII\n" | \
        "${VSEARCH}" \
            --makeudb_usearch - \
            --minseqlength 1 \
            --quiet \
            --output "${UDB}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --udbstats "${UDB}" \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--udbstats valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--udbstats valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${UDB}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


unset SEQ
exit 0
