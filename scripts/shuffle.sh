#!/bin/bash -

## Print a header
SCRIPT_NAME="Shuffle"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}

## Constructing a test file
SEQx1000=$(mktemp)
for ((i=1 ; i<=1000 ; i++)) ; do
    printf "@%s%d\nAAGG\n+\nGGGG\n" "seq" ${i}
done > "${SEQx1000}"

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
"${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --shuffle --output fill the passed file (1% chance fail) 
OUTPUT=$(mktemp)
DESCRIPTION="--shuffle --output fill the passed file (1‰ chance of failure)"
"${VSEARCH}" --shuffle "${SEQx1000}" --output "${OUTPUT}" &> /dev/null
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
"${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --randseed 666 \
	     --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --randseed products constant output
OUTPUT=$(mktemp)
DESCRIPTION="--randseed products constant output"
RANDSEED_OUTPUT=$("${VSEARCH}" --shuffle "${SEQx1000}" --randseed 666 \
			       --output "${OUTPUT}" &> /dev/null)
CLASSIC_OUTPUT=$("${VSEARCH}" --shuffle "${SEQx1000}" --randseed 666 \
			      --output "${OUTPUT}" &> /dev/null)
[[ "${RANDSEED_OUTPUT}" == "${CLASSIC_OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --randseed 0 products different outputs (tiny chances of failure)
OUTPUT=$(mktemp)
DESCRIPTION="--randseed 0 products different outputs (tiny chances of failure)"
[[ $("${VSEARCH}" --shuffle "${SEQx1000}" --randseed 0 --output "${OUTPUT}" 2>&1) == \
$("${VSEARCH}" --shuffle "${SEQx1000}" --randseed 0 --output "${OUTPUT}" 2>&1) ]]
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
"${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel 'lab' \
	     --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel products correct labels #1
OUTPUT=$(mktemp)
DESCRIPTION="--relabel products correct labels #1"
"${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel 'lab' \
	     --output "${OUTPUT}" &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == ">lab1" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel products correct labels #2
OUTPUT=$(mktemp)
DESCRIPTION="--relabel products correct labels #2"
"${VSEARCH}" --shuffle "${SEQx1000}" --relabel 'lab' \
	     --output "${OUTPUT}" &> /dev/null
[[ $(sed "7q;d" "${OUTPUT}") == ">lab4" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel should not be used with relabel_sha
OUTPUT=$(mktemp)
DESCRIPTION="--relabel is accepted"
"${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel 'lab' \
	     --output "${OUTPUT}" &> /dev/null && \
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
"${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel 'lab' --relabel_keep \
	     --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_keep products correct labels
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_keep products correct labels"
"${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel 'lab' --relabel_keep \
	     --output "${OUTPUT}" &> /dev/null
[[ $(awk 'NR==1 {print $1}' "${OUTPUT}") == ">lab1" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_keep should not be used with other labelling options
for OPTION in "--relabel_sha1" "--relabel_md5" ; do
    DESCRIPTION="--relabel_keep should not be used with ${OPTION}"
    "${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel 'lab' "${OPTION}" \
		 --output - &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#                               --relabel_md5                                 #
#                                                                             #
#*****************************************************************************#

## --relabel_md5 is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_md5 is accepted"
"${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel_md5 \
	     --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_md5 products correct labels
DESCRIPTION="--relabel_md5 products correct labels"
[[ $("${VSEARCH}" --shuffle <(printf '>a\nAAAA\n') --relabel_md5 \
		  --output - 2> /dev/null \
	    | awk -F "[>]" '{printf $2}') == \
   $(printf "AAAA" | md5sum - | awk '{printf $1}') ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --relabel_md5 original labels are shuffled (1‰ chance of failure)
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_md5 original labels are shuffled (1‰ chance of failure)"
"${VSEARCH}" --shuffle "${SEQx1000}" --relabel_md5 --output "${OUTPUT}" &> /dev/null
[[ $(awk 'NR==1 {print $2}' "${OUTPUT}") != "seq1" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_md5 should not be used with other labelling options
for OPTION in "--relabel 'lab'" "--relabel_sha1" ; do
    DESCRIPTION="--relabel_keep should not be used with ${OPTION}"
    "${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel_md5 ${OPTION} \
		 --output - &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#                               --relabel_sha1                                #
#                                                                             #
#*****************************************************************************#

## --relabel_sha1 is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_sha1 is accepted"
"${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel_sha1 \
	     --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_sha1 products correct labels
DESCRIPTION="--relabel_sha1 products correct labels"
INPUT=$("${VSEARCH}" --shuffle <(printf '>a\nAAAA\n') --relabel_sha1 \
		     --output - 2> /dev/null | awk -F "[>]" '{printf $2}')
SHA1=$(printf "AAAA" | sha1sum - | awk '{printf $1}')
[[ "${INPUT}" == "${SHA1}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --relabel_sha1 original labels are shuffled (1‰ chance of failure)
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_sha1 original labels are shuffled (1‰ chance of failure)"
"${VSEARCH}" --shuffle "${SEQx1000}" --relabel_sha1 \
	     --output "${OUTPUT}" &> /dev/null
[[ $(awk 'NR==1 {print $2}' "${OUTPUT}") != "seq1" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_sha1 should not be used with other labelling options
for OPTION in "--relabel 'lab'" "--relabel_md5" ; do
    DESCRIPTION="--relabel_keep should not be used with ${OPTION}"
    "${VSEARCH}" --shuffle <(printf ">a\nAAAA\n") --relabel_sha1 ${OPTION} \
		 --output - &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#                                  --sizeout                                  #
#                                                                             #
#*****************************************************************************#

## --sizeout is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--sizeout is accepted"
"${VSEARCH}" --shuffle <(printf '>a;size=5;\nAAAA\n') --relabel 'lab' \
	     --output "${OUTPUT}" --sizeout &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizeout output is correct with --relabel
OUTPUT=$(mktemp)
DESCRIPTION="--sizeout output is correct with --relabel"
[[ $("${VSEARCH}" --shuffle <(printf '>a;size=5;\nAAAA\n') --relabel 'lab' \
		  --sizeout --output - 2> /dev/null | \
	    sed "1q;d") == \
   ">lab1;size=5;" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                   --topn                                    #
#                                                                             #
#*****************************************************************************#

## --topn is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--topn is accepted"
"${VSEARCH}" --shuffle <(printf '>a\nAAAA\n') --output "${OUTPUT}" \
	     --topn 1 &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --topn truncate the output
OUTPUT=$(mktemp)
DESCRIPTION="--topn truncate the output"
"${VSEARCH}" --shuffle <(printf '>a\nAAAA\n>b\nAAAA\n>c\nAAAA\n') \
	     --output "${OUTPUT}" --topn 2 &> /dev/null
(( $(wc -l < "${OUTPUT}") == "4" )) && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                  --xsize                                    #
#                                                                             #
#*****************************************************************************#

## --xsize is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--xsize is accepted"
"${VSEARCH}" --shuffle <(printf '>a;size=5;\nAAAA\n') --output "${OUTPUT}" \
	     --xsize &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --xsize output is correct with --relabel
OUTPUT=$(mktemp)
DESCRIPTION="--xsize output is correct with --relabel"
[[ $("${VSEARCH}" --shuffle <(printf '>a;size=5;\nAAAA\n') --xsize \
		  --output - 2> /dev/null | \
	    sed "1q;d") == \
   ">a" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

rm "${SEQx1000}"
