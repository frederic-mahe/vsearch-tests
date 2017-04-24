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

## Constructing a test file
ALL_IDENTICAL=$(mktemp)
for ((i=1 ; i<=10 ; i++)) ; do
    printf "@%s%d\nAAGG\n+\nGGGG\n" "seq" ${i}
done > "${ALL_IDENTICAL}"

## Is vsearch installed?
VSEARCH=$(which vsearch)
DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] && success "${DESCRIPTION}" || failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                   General                                   #
#                                                                             #
#*****************************************************************************#

## --shuffle is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--shuffle is accepted"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --shuffle --output fill the passed file
OUTPUT=$(mktemp)
DESCRIPTION="--shuffle --output fill the passed file"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --output "${OUTPUT}" &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                                 --randseed                                  #
#                                                                             #
#*****************************************************************************#

## --randseed is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--randseed is accepted"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --randseed 666 --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --randseed output is different from classic output
OUTPUT=$(mktemp)
DESCRIPTION="--randseed output is different from classic output"
[[ $("${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --randseed 666 --output - 2> /dev/null) == \
$("${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --output - 2> /dev/null) ]]
success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --randseed products constant output
OUTPUT=$(mktemp)
DESCRIPTION="--randseed products constant output"
[[ $("${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --randseed 666 --output "${OUTPUT}" &> /dev/null) == \
$("${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --randseed 666 --output "${OUTPUT}" &> /dev/null) ]]
success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"
