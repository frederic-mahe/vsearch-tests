#!/bin/bash -

## Print a header
SCRIPT_NAME="Test options"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    exit -1
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}

## Is vsearch installed?
VSEARCH=$(which vsearch)
DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] && success "${DESCRIPTION}" || failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                        Options --version and --help                         #
#                                                                             #
#*****************************************************************************#

## Return status should be 0 after -h and -v (GNU standards)
for OPTION in "-h" "-v" ; do
    DESCRIPTION="return status should be 0 after ${OPTION}"
    "${VSEARCH}" "${OPTION}" 2> /dev/null > /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done

#*****************************************************************************#
#                                                                             #
#                                Options --log                                #
#                                                                             #
#*****************************************************************************#

## --log is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--log is accepted"
printf '@a_1\nACGT\n+\n@JJh\n' | \
"${VSEARCH}" --fastq_chars - --log "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --log actually fill a file
OUTPUT=$(mktemp)
DESCRIPTION="--log actually fill a file"
printf '@a_1\nACGT\n+\n@JJh\n' | \
"${VSEARCH}" --fastq_chars - --log "${OUTPUT}" &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                               Options --quiet                               #
#                                                                             #
#*****************************************************************************#

## --quiet is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--quiet is accepted"
printf '@a_1\nACGT\n+\n@JJh\n' | \
    "${VSEARCH}" --fastq_chars - --quiet 2> "${OUTPUT}"
[[ -s "${OUTPUT}" ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"



exit 0
