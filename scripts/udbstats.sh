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
