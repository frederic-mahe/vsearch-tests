#!/bin/bash -

## Print a header
SCRIPT_NAME="version"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    # exit 1
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

# Output version information and a citation for the VSEARCH
# publication. Show the status of the support for gzip- and
# bzip2-compressed input files.

DESCRIPTION="--version is a valid command"
"${VSEARCH}" \
    --version > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--version outputs version number to stderr"
"${VSEARCH}" \
    --version 2>&1 > /dev/null | \
    grep -Eq "^vsearch v[0-9]+\.[0-9]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--version outputs citation to stdout"
"${VSEARCH}" \
    --version 2> /dev/null | \
    grep -q "PeerJ" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--version outputs support for gzip to stdout"
"${VSEARCH}" \
    --version 2> /dev/null | \
    grep -q "gzip" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--version outputs support for bzip2 to stdout"
"${VSEARCH}" \
    --version 2> /dev/null | \
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

# The valid options for the version command are: --log --quiet --threads

## ------------------------------------------------------------------------ log

DESCRIPTION="--version --log is accepted"
"${VSEARCH}" \
    --version \
    --log /dev/null > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--version --log writes to a file"
"${VSEARCH}" \
    --version \
    --log - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--version --log does not prevent messages to be sent to stderr"
"${VSEARCH}" \
    --version \
    --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--version --quiet is accepted"
"${VSEARCH}" \
    --version \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--version --quiet eliminates all (normal) messages to stderr"
"${VSEARCH}" \
    --version \
    --quiet 1> /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--version --quiet allows error messages to be sent to stderr"
"${VSEARCH}" \
    --version \
    --quiet \
    --quiet2 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--version --threads is accepted"
"${VSEARCH}" \
    --version \
    --threads 1 > /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--version --threads > 1 triggers a warning (not multithreaded)"
"${VSEARCH}" \
    --version \
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
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
