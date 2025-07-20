#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="uchime3_denovo"
LINE=$(printf -- "-%.0s" {1..76})
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

## vsearch (--uchime_denovo | --uchime2_denovo | --uchime3_denovo)
## fastafile (--chimeras | --nonchimeras | --uchimealns | --uchimeout)
## outputfile [options]

# --uchime3_denovo filename

# Detect chimeras present in the fasta-formatted filename, using the
# UCHIME2 algorithm. The only difference from --uchime2_denovo is that
# the default minimum abundance skew (--abskew) is set to 16.0 rather
# than 2.0.


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


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    LOG=$(mktemp)
    QUERY=$(mktemp)
    #        1...5...10...15...20...25...30...35
    A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"
    B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
    A_END=$(rev <<< ${A_START})
    B_END=$(rev <<< ${B_START})
    (
        printf ">parentA;size=50\n%s\n" "${A_START}${A_END}"
        printf ">parentB;size=49\n%s\n" "${B_START}${B_END}"
        printf ">chimeraAB;size=1\n%s\n" "${A_START}${B_END}"
    ) > "${QUERY}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --uchime3_denovo "${QUERY}" \
        --chimeras /dev/null \
        --nonchimeras /dev/null \
        --borderline /dev/null \
        --uchimealns /dev/null \
        --uchimeout /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--uchime3_denovo valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--uchime3_denovo valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${QUERY}"
    unset A_START B_START A_END B_END LOG QUERY DESCRIPTION
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
