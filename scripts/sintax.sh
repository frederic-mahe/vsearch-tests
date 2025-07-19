#!/bin/bash -

## Print a header
SCRIPT_NAME="sintax"
LINE=$(printf "%076s\n" | tr " " "-")
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

## vsearch --sintax fastafile --db fastafile --tabbedout outputfile
## [--sintax_cutoff real] [options]


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

    SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAA"  # 39 nt
    LOG=$(mktemp)
    QUERY=$(mktemp)
    DB=$(mktemp)
    printf ">q\n%s\n" "${SEQ}" > "${QUERY}"
    printf ">s;tax=d:d,p:p,c:c,o:o,f:f,g:g,s:s,t:t\n%s\n" "${SEQ}" > "${DB}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --sintax "${QUERY}" \
        --db "${DB}" \
        --minseqlength 1 \
        --tabbedout /dev/null \
        --strand both \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--sintax valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--sintax valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${QUERY}" "${DB}"
    unset SEQ LOG QUERY DB DESCRIPTION
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#

## To Do List:
## 
## - make a script to transform silva (use silva slv tax), Unite,
##   GreenGenes and the barcode of life into a format usable by sintax,
## - test if results are subject-order dependent (users should be able
##   to use a fix seed).

exit 0
