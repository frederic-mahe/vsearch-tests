#!/bin/bash -

## Print a header
SCRIPT_NAME="help"
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

# none

#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

# Display help text with brief information about all commands and
# options.

DESCRIPTION="--help is a valid command"
"${VSEARCH}" \
    --help > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--help is a valid command (-h)"
"${VSEARCH}" \
    -h > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--help outputs help message to stdout"
"${VSEARCH}" \
    --help 2> /dev/null | \
    grep -q "^Usage" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--help outputs help message to stdout (-h)"
"${VSEARCH}" \
    -h 2> /dev/null | \
    grep -q "^Usage" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--help outputs version number to stderr"
"${VSEARCH}" \
    --help 2>&1 > /dev/null | \
    grep -Eq "^vsearch v[0-9]+\.[0-9]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--help outputs version number to stderr (-h)"
"${VSEARCH}" \
    -h 2>&1 > /dev/null | \
    grep -Eq "^vsearch v[0-9]+\.[0-9]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--help outputs citation to stdout"
"${VSEARCH}" \
    --help 2> /dev/null | \
    grep -q "PeerJ" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--help outputs support for gzip to stdout"
"${VSEARCH}" \
    --help 2> /dev/null | \
    grep -q "gzip" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--help outputs support for bzip2 to stdout"
"${VSEARCH}" \
    --help 2> /dev/null | \
    grep -q "bzip2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

# none

#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

# The valid options for the help command are: --log --quiet --threads

## ------------------------------------------------------------------------ log

DESCRIPTION="--help --log is accepted"
"${VSEARCH}" \
    --help \
    --log /dev/null > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--help --log writes to a file"
"${VSEARCH}" \
    --help \
    --log - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--help --log does not prevent messages to be sent to stderr"
"${VSEARCH}" \
    --help \
    --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--help --quiet is accepted"
"${VSEARCH}" \
    --help \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--help --quiet eliminates all (normal) messages to stderr"
"${VSEARCH}" \
    --help \
    --quiet 1> /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--help --quiet allows error messages to be sent to stderr"
"${VSEARCH}" \
    --help \
    --quiet \
    --quiet2 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--help --threads is accepted"
"${VSEARCH}" \
    --help \
    --threads 1 > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--help --threads > 1 triggers a warning (not multithreaded)"
"${VSEARCH}" \
    --help \
    --threads 2 2>&1 > /dev/null | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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
    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --help > /dev/null 2> /dev/null
    DESCRIPTION="--help valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--help valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
