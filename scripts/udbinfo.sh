#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="udbinfo"
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

## vsearch --udbinfo udbfile [options]

SEQ="ACGTACGTACGTACGTACGTACGTACGTACGT"

DESCRIPTION="--udbinfo is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--udbinfo fails if UDB file does not exist"
"${VSEARCH}" \
    --udbinfo /no/such/file \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--udbinfo fails with a non-UDB input file"
TMPFA=$(mktemp)
printf ">s\n%s\n" "${SEQ}" > "${TMPFA}"
"${VSEARCH}" \
    --udbinfo "${TMPFA}" \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--udbinfo fails if input file is not readable"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
chmod u-r "${TMPUDB}"
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMPUDB}" && rm -f "${TMPUDB}"
unset TMPUDB

## --udbinfo rejects a pipe as input (UDB detection requires stat-able file)
DESCRIPTION="--udbinfo rejects a pipe as input"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo - \
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

## NOTE: according to the manpage, --udbinfo writes information to stdout,
## but in practice the output is written to stderr (see src/udb.cc). The
## tests below match the actual behaviour.

DESCRIPTION="--udbinfo reports the number of sequences (Seqs)"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" 2>&1 | \
    grep -qE "Seqs[[:space:]]+1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--udbinfo reports the word width (default 8)"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" 2>&1 | \
    grep -qE "Word width[[:space:]]+8" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--udbinfo reports a non-default word width (10)"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
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

DESCRIPTION="--udbinfo reports the alphabet as nt"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" 2>&1 | \
    grep -qE "Alpha[[:space:]]+nt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## number of sequences grows with input
DESCRIPTION="--udbinfo reports the correct count for a 2-sequence UDB"
TMPUDB=$(mktemp)
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" 2>&1 | \
    grep -qE "Seqs[[:space:]]+2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB


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
    --udbinfo "${TMPUDB}" \
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
    --udbinfo "${TMPUDB}" \
    --log "${TMPLOG}" 2> /dev/null
[[ -s "${TMPLOG}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

DESCRIPTION="--log captures the info block"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" \
    --quiet \
    --log "${TMPLOG}" 2> /dev/null
grep -qE "Seqs[[:space:]]+1" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

## --quiet: suppress messages

DESCRIPTION="--quiet is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--quiet suppresses the info block"
TMPUDB=$(mktemp)
TMPERR=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" \
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
    --udbinfo "${TMPUDB}" \
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

## --output is not accepted (udbinfo does not take an output file)
DESCRIPTION="--output is rejected"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --no_progress is not accepted by udbinfo (there is no progress to hide)
DESCRIPTION="--no_progress is rejected"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udbinfo "${TMPUDB}" \
    --no_progress \
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
    --udbinfo "${TMPUDB}" \
    --wordlength 8 \
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
        --udbinfo "${UDB}" \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--udbinfo valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--udbinfo valgrind (no errors)"
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
