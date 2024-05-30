#!/bin/bash -

## Print a header
SCRIPT_NAME="vsearch (no command)"
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
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

## ---------------------------------------------------- without a valid command

DESCRIPTION="vsearch works without any command"
"${VSEARCH}" > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="vsearch outputs version number to stderr"
"${VSEARCH}" 2>&1 > /dev/null | \
    grep -Eq "^vsearch v[0-9]+\.[0-9]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="vsearch outputs help to stderr"
"${VSEARCH}" 2>&1 | \
    grep -iq "help" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="vsearch mentions --help (stderr)"
"${VSEARCH}" 2>&1 | \
    grep -q "\-\-help" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="vsearch mentions man vsearch (stderr)"
"${VSEARCH}" 2>&1 | \
    grep -wq "man" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# WARNING: Options given, but no valid command specified.
DESCRIPTION="vsearch warns if an option is used without a command"
"${VSEARCH}" \
    --sizein 2>&1 > /dev/null | \
    grep -iq "^warning" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------- with extra commands

DESCRIPTION="vsearch accepts duplicated commands"
"${VSEARCH}" \
    --version --version > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="vsearch rejects mixed commands"
"${VSEARCH}" \
    --version --help > /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
