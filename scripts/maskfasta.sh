#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="maskfasta"
LINE=$(printf "%76s\n" | tr " " "-")
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


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## vsearch --maskfasta fastafile --output outputfile [options]


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#


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


exit 0


## see issue 30 for more tests

#*****************************************************************************#
#                                                                             #
#                               Maskfasta                                     #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--maskfasta is accepted"
OUTPUT=$(mktemp)
printf '>seq1\nA\n' | \
    "${VSEARCH}" --maskfasta - --output "${OUTPUT}"  &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--maskfasta fails if argument given is not valid"
OUTPUT=$(mktemp)
"${VSEARCH}" --maskfasta OUTEST --output "${OUTPUT}"  &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--maskfasta if no argument"
OUTPUT=$(mktemp)
"${VSEARCH}" --output "${OUTPUT}" --maskfasta  &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--qmask is accepted with none"
"${VSEARCH}" --qmask none &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask is accepted with dust"
"${VSEARCH}" --qmask dust &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask is accepted with soft"
"${VSEARCH}" --qmask soft &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask is not accepted with no arguments"
"${VSEARCH}" --qmask  &> /dev/null && \
    failure "${DESCRIPTION}" ||  \
        success "${DESCRIPTION}"

DESCRIPTION="--qmask with no arguments gives an error message"
ERROR=$("${VSEARCH}" --qmask  2>&1> /dev/null)
[[ -n "${ERROR}" ]] && \
    success "${DESCRIPTION}" ||  \
        failure "${DESCRIPTION}"
unset "ERROR"

DESCRIPTION="--qmask is accepted with invalid argument"
"${VSEARCH}" --qmask "toto" &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# Example taken from Morgulis et al. (2006) Journal of Computational
# Biology, 13(5), 1028-1040
#
# Middle part should stay the same
DESCRIPTION="--maskfasta --qmask none output is correct"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | \
                "${VSEARCH}" --maskfasta - --qmask none --output - 2>/dev/null \
                             --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"

# Middle part should be lowercased
DESCRIPTION="--maskfasta --qmask dust output is correct"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
MIDDLE_LC=$(echo $MIDDLE | tr [:upper:] [:lower:])
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE_LC} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | \
                "${VSEARCH}" --maskfasta - --qmask dust --output - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Middle part is identified as a maskable region but should stay the same
DESCRIPTION="--maskfasta --qmask soft output is correct"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | \
                "${VSEARCH}" --maskfasta - --qmask soft --output - 2>/dev/null \
                             --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"

# Middle part should stay the same
DESCRIPTION="--maskfasta --hardmask --qmask none output is correct"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | \
                "${VSEARCH}" --maskfasta - --qmask none --output - 2>/dev/null\
                             --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"

# Middle part is identified as a maskable region but should stay the same
DESCRIPTION="--maskfasta --hardmask --qmask soft output is correct"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | \
                "${VSEARCH}" --maskfasta - --qmask soft --output - 2>/dev/null\
                             --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"

# Middle part is identified as a maskable region and is replaced with Ns
DESCRIPTION="--maskfasta --hardmask --qmask dust output is correct"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn"        
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | \
                "${VSEARCH}" --maskfasta - --qmask dust --output - --fasta_width 0 2>/dev/null\
                             --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"

exit 0
