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
for ((i=1 ; i<=100 ; i++)) ; do
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

## --randseed 0 products different outputs (may fail if very unlucky)
OUTPUT=$(mktemp)
DESCRIPTION="--randseed 0 products different outputs (may fail if very unlucky)"
[[ $("${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --randseed 0 --output "${OUTPUT}" 2>&1) == \
$("${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --randseed 0 --output "${OUTPUT}" 2>&1) ]]
success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                                 --relabel                                   #
#                                                                             #
#*****************************************************************************#

## --relabel is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--relabel is accepted"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel 'lab' --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel products correct labels #1
OUTPUT=$(mktemp)
DESCRIPTION="--relabel products correct labels #1"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel 'lab' --output "${OUTPUT}" &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == ">lab1" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel products correct labels #2
OUTPUT=$(mktemp)
DESCRIPTION="--relabel products correct labels #2"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel 'lab' --output "${OUTPUT}" &> /dev/null
[[ $(sed "7q;d" "${OUTPUT}") == ">lab4" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                               --relabel_keep                                #
#                                                                             #
#*****************************************************************************#

## --relabel_keep is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_keep is accepted"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel 'lab' --relabel_keep --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_keep products correct labels
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_keep products correct labels"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel 'lab' --relabel_keep --output "${OUTPUT}" &> /dev/null
[[ $(awk 'NR==1 {print $1}' "${OUTPUT}") == ">lab1" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_keep original labels are shuffled (1% chance fail)
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_keep original labels are shuffled (1% chance fail)"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel 'lab' --relabel_keep --output "${OUTPUT}" &> /dev/null
[[ $(awk 'NR==1 {print $2}' "${OUTPUT}") != "seq1" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                               --relabel_md5                                 #
#                                                                             #
#*****************************************************************************#

## --relabel_md5 is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_md5 is accepted"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel_md5 --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_md5 products correct labels
# OUTPUT=$(mktemp)
# DESCRIPTION="--relabel_md5 products correct labels"
# "${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel_md5 --output "${OUTPUT}" &> /dev/null
# [[ $(awk 'NR==1 {print $1}' "${OUTPUT}") == ">lab1" ]] && \
#     success "${DESCRIPTION}" || \
# 	failure "${DESCRIPTION}"
# rm "${OUTPUT}"

## --relabel_md5 original labels are shuffled
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_md5 original labels are shuffled"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel_md5 --output "${OUTPUT}" &> /dev/null
[[ $(awk 'NR==1 {print $2}' "${OUTPUT}") != "seq1" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                               --relabel_sha1                                #
#                                                                             #
#*****************************************************************************#

## --relabel_sha1 is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_sha1 is accepted"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel_sha1 --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_sha1 products correct labels
# OUTPUT=$(mktemp)
# DESCRIPTION="--relabel_sha1 products correct labels"
# "${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel_sha1 --output "${OUTPUT}" &> /dev/null
# [[ $(awk 'NR==1 {print $1}' "${OUTPUT}") == ">lab1" ]] && \
#     success "${DESCRIPTION}" || \
# 	failure "${DESCRIPTION}"
# rm "${OUTPUT}"

## --relabel_sha1 original labels are shuffled
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_sha1 original labels are shuffled"
"${VSEARCH}" --shuffle "${ALL_IDENTICAL}" --relabel_sha1 --output "${OUTPUT}" &> /dev/null
[[ $(awk 'NR==1 {print $2}' "${OUTPUT}") != "seq1" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                                  --sizeout                                  #
#                                                                             #
#*****************************************************************************#

## --sizeout is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--sizeout is accepted"
"${VSEARCH}" --shuffle <(printf '>a_;size=5;\nAAAA\n') --relabel 'lab' --output "${OUTPUT}" --sizeout &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizeout output is correct with --relabel
# OUTPUT=$(mktemp)
# DESCRIPTION="--sizeout output is correct with --relabel"
# "${VSEARCH}" --shuffle <(printf '>a_;size=5;\nAAAA\n') --relabel 'lab' --output "${OUTPUT}" 
# cat "${OUTPUT}"
# [[ $(awk '{print $2}' "${OUTPUT}") == ">lab1;size=5;" ]] && \
#     success "${DESCRIPTION}" || \
# 	failure "${DESCRIPTION}"
# rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                                   --topn                                    #
#                                                                             #
#*****************************************************************************#

## --topn is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--topn is accepted"
"${VSEARCH}" --shuffle <(printf '>a\nAAAA\n') --output "${OUTPUT}" --topn 1 &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --topn truncate the output
OUTPUT=$(mktemp)
DESCRIPTION="--topn truncate the output"
"${VSEARCH}" --shuffle <(printf '>a\nAAAA\n>b\nAAAA\n>c\nAAAA\n') --output "${OUTPUT}" --topn 2 &> /dev/null
(( $(wc -l < "${OUTPUT}") == "4" )) && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

