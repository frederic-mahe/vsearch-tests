#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="vsearch (no command)"
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

## valgrind is only useful here if it can actually run the binary under
## test. When it dies before reaching main -- a uprobe on the dynamic
## loader does that, and so does a sanitizer-instrumented binary -- it
## still reports "ERROR SUMMARY: 0 errors" and "in use at exit: 0
## bytes", which would silently turn every valgrind check below into a
## pass. Probe it once here, so those checks are skipped, not passed.
VALGRIND_WORKS=false
if which valgrind > /dev/null 2>&1 ; then
    VALGRIND_PROBE=$(valgrind "${VSEARCH}" --version 2>&1)
    [[ "${VALGRIND_PROBE}" == *"ERROR SUMMARY"* && \
       "${VALGRIND_PROBE}" != *"Process terminating"* ]] && \
        VALGRIND_WORKS=true
    unset VALGRIND_PROBE
fi


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
    grep -qw "man" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# WARNING: Options given, but no valid command specified.
DESCRIPTION="vsearch warns if an option is used without a command"
"${VSEARCH}" \
    --sizein 2>&1 > /dev/null | \
    grep -iq "^warning" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="vsearch names the missing command in that warning"
"${VSEARCH}" \
    --sizein 2>&1 > /dev/null | \
    grep -qx "WARNING: Options given, but no valid command specified." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## warnings emitted while parsing the command line reach stderr only:
## --log is not open yet at that point
DESCRIPTION="vsearch --log does not receive the no-command warning"
"${VSEARCH}" \
    --sizein \
    --log - 2> /dev/null | \
    grep -qi "warning" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --quiet does not suppress warnings ("suppress messages to stdout and
## stderr, except for warnings and error messages")
DESCRIPTION="vsearch --quiet does not suppress the no-command warning"
"${VSEARCH}" \
    --sizein \
    --quiet 2>&1 > /dev/null | \
    grep -qx "WARNING: Options given, but no valid command specified." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="vsearch does not duplicate the no-command warning"
"${VSEARCH}" \
    --sizein 2>&1 > /dev/null | \
    grep -c "WARNING: Options given, but no valid command specified." | \
    grep -qx "1" && \
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
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if [[ "${VALGRIND_WORKS}" == "true" ]] ; then
    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" 2> /dev/null
    DESCRIPTION="vsearch valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="vsearch valgrind (no errors)"
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
