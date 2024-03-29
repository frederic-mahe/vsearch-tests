#!/bin/bash -

## Print a header
SCRIPT_NAME="sorting options"
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

## Constructing a test file
SEQx1000=$(mktemp)
for ((i=1 ; i<=1000 ; i++)) ; do
    printf "@%s%d\nAAGG\n+\nGGGG\n" "seq" ${i}
done > "${SEQx1000}"

if [[ ${OSTYPE} =~ darwin ]] ; then
    md5sum() { md5 -r ; }
    sha1sum() { shasum ; }
fi


#*****************************************************************************#
#                                                                             #
#                                   General                                   #
#                                                                             #
#*****************************************************************************#

# --sortbylength is accepted
DESCRIPTION="--sortbylength is accepted"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output - &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --output create and fill a file
OUTPUT=$(mktemp)
DESCRIPTION="--output create and fill a file"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output "${OUTPUT}" &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --sortbylength sorts the output
OUTPUT=$(mktemp)
DESCRIPTION="--sortbylength sorts the output"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n>c\nCAAAA\n>b\nGAA\n") \
	     --output "${OUTPUT}" &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">c\nCAAAA\n>a\nAAAA\n>b\nGAA") ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --sortbysize is accepted
DESCRIPTION="--sortbysize is accepted"
"${VSEARCH}" --sortbysize <(printf ">a;size=5;\nAAAA\n") --output - &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --sortbysize abundance default value is 1 when abundance value is missing
DESCRIPTION="--sortbysize abundance default value is 1 when abundance value is missing"
OUTPUT1=$("${VSEARCH}" --sortbysize <(printf ">b\nA\n>a;size=1;\nA\n") \
		       --output - &> /dev/null)
OUTPUT2=$("${VSEARCH}" --sortbysize <(printf ">a\nA\n>b;size=1;\nA\n") \
		       --output - &> /dev/null)
[[ "${OUTPUT1}" == "${OUTPUT2}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --output create and fill a file
OUTPUT=$(mktemp)
DESCRIPTION="--output create and fill a file"
"${VSEARCH}" --sortbysize <(printf ">a;size=5;\nAAAA\n") --output "${OUTPUT}" \
    &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --sortbysize sorts the output
OUTPUT=$(mktemp)
DESCRIPTION="--sortbysize sorts the output"
"${VSEARCH}" --sortbysize <(printf ">a;size=5;\nAA\n>c;size=10;\nCA\n>b;size=1;\nGA\n") \
	     --output "${OUTPUT}" &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">c;size=10;\nCA\n>a;size=5;\nAA\n>b;size=1;\nGA") ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                  --maxsize                                  #
#                                                                             #
#*****************************************************************************#

# --maxsize is accepted
DESCRIPTION="--maxsize is accepted"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - --maxsize 5 \
    &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --maxsize discard sequences
OUTPUT=$(mktemp)
DESCRIPTION="--maxsize discard sequences"
"${VSEARCH}" --sortbysize <(printf ">a;size=2;\nAA\n>c;size=3;\nAA\n>b;size=4;\nAA\n") \
	     --output "${OUTPUT}" --maxsize 3 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">c;size=3;\nAA\n>a;size=2;\nAA\n") ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --maxsize fail if used with sortbylength
DESCRIPTION="--maxsize fail if used with sortbylength"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output - --maxsize 5 \
    &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# --maxsize fail if used with negative integers
DESCRIPTION="--maxsize fail if used with negative integers"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output - --maxsize -1 \
    &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# --maxsize fail if used with 0
DESCRIPTION="--maxsize fail if used with 0"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output - --maxsize 0 \
    &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# --maxsize fail if used with a character
DESCRIPTION="--maxsize fail if used a character"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output - --maxsize "e" \
    &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                  --minsize                                  #
#                                                                             #
#*****************************************************************************#

# --minsize is accepted
DESCRIPTION="--minsize is accepted"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - --minsize 5 \
    &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --minsize discard sequences
OUTPUT=$(mktemp)
DESCRIPTION="--minsize discard sequences"
"${VSEARCH}" --sortbysize <(printf ">a;size=2;\nAA\n>c;size=3;\nAA\n>b;size=4;\nAA\n") \
	     --output "${OUTPUT}" --minsize 3 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">b;size=4;\nAA\n>c;size=3;\nAA") ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --minsize fail if used with sortbylength
DESCRIPTION="--minsize fail if used with sortbylength"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output - --minsize 5 \
    &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# --minsize fail if used with negative integers
DESCRIPTION="--minsize fail if used with negative integers"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output - --minsize -1 \
    &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# --minsize fail if used with 0
DESCRIPTION="--minsize fail if used with 0"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output - --minsize 0 \
    &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# --minsize fail if used with a character
DESCRIPTION="--minsize fail if used a character"
"${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --output - --minsize "e" \
    &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                  --relabel                                  #
#                                                                             #
#*****************************************************************************#

# --relabel is accepted
DESCRIPTION="--relabel is accepted"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - --relabel 'lab' \
    &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --relabel products correct labels
OUTPUT=$(mktemp)
DESCRIPTION="--relabel products correct labels"
"${VSEARCH}" --sortbysize <(printf ">a\nA\n") --output "${OUTPUT}" \
	     --relabel 'lab' &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == ">lab1" ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --relabel products correct labels
OUTPUT=$(mktemp)
DESCRIPTION="--relabel products correct labels"
"${VSEARCH}" --sortbylength <(printf ">a\nA\n>b\nAA\n") --output "${OUTPUT}" \
	     --relabel 'lab' &> /dev/null
[[ $(sed "3q;d" "${OUTPUT}") == ">lab2" ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel should not be used with other labelling options
for OPTION in "--relabel_md5" "--relabel_sha1" ; do
    DESCRIPTION="--relabel should not be used with ${OPTION}"
    "${VSEARCH}" --sortbylength <(printf ">a\nAAAA\n") --relabel 'lab' ${OPTION} \
		 --output - &> /dev/null && \
	failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#                                 --relabel_keep                              #
#                                                                             #
#*****************************************************************************#

# --relabel_keep is accepted
DESCRIPTION="--relabel_keep is accepted"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - --relabel 'lab' \
	     --relabel_keep &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --relabel_keep products correct labels #1
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_keep products correct labels #1"
"${VSEARCH}" --sortbysize <(printf ">a\nA\n") --output "${OUTPUT}" \
	     --relabel 'lab' --relabel_keep &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == ">lab1 a" ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --relabel_keep products correct labels #2
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_keep products correct labels #2"
"${VSEARCH}" --sortbylength <(printf ">a\nAA\n>b\nAAA\n>c\nAAAA\n") \
	     --relabel 'lab' --output "${OUTPUT}" --relabel_keep &> /dev/null
[[ $(sed "5q;d" "${OUTPUT}") == ">lab3 a" ]] &&
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                  --relabel_md5                              #
#                                                                             #
#*****************************************************************************#

# --relabel_md5 is accepted
DESCRIPTION="--relabel_md5 is accepted"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - --relabel_md5 \
    &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --relabel_md5 products correct labels #1
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_md5 products correct labels #1"
"${VSEARCH}" --sortbysize <(printf ">a\nA\n") --output "${OUTPUT}" \
	     --relabel_md5 &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}" | awk -F "[>]" '{print $2}') == \
    $(printf "A" | md5sum | awk '{print $1}') ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --relabel_md5 products correct labels #2
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_md5 products correct labels #2"
"${VSEARCH}" --sortbylength <(printf ">a\nAA\n>b\nAAA\n>c\nAAAA\n") \
	     --output "${OUTPUT}" --relabel_md5 &> /dev/null
[[ $(sed "5q;d" "${OUTPUT}" | awk -F "[>]" '{print $2}') == \
    $(printf "AA" | md5sum | awk '{print $1}') ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_md5 should not be used with other labelling options
for OPTION in "--relabel 'lab'" "--relabel_sha1" ; do
    DESCRIPTION="--relabel_md5 should not be used with ${OPTION}"
    "${VSEARCH}" --sortbylength <(printf ">a\nA\n") --relabel_md5 ${OPTION} \
		 --output - &> /dev/null && \
	failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#                                 --relabel_sha1                              #
#                                                                             #
#*****************************************************************************#

# --relabel_sha1 is accepted
DESCRIPTION="--relabel_sha1 is accepted"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - --relabel_sha1 \
    &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --relabel_sha1 products correct labels #1
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_sha1 products correct labels #1"
"${VSEARCH}" --sortbysize <(printf ">a\nA\n") --output "${OUTPUT}" \
	     --relabel_sha1 &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}" | awk -F "[>]" '{print $2}') == \
    $(printf "A" | sha1sum | awk '{print $1}') ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --relabel_sha1 products correct labels #
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_sha1 products correct labels #2"
"${VSEARCH}" --sortbylength <(printf ">a\nAA\n>b\nAAA\n>c\nAAAA\n") \
	     --output "${OUTPUT}" --relabel_sha1 &> /dev/null
[[ $(sed "5q;d" "${OUTPUT}" | awk -F "[>]" '{print $2}') == \
    $(printf "AA" | sha1sum | awk '{print $1}') ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_sha1 should not be used with other labelling options
for OPTION in "--relabel 'lab'" "--relabel_md5" ; do
    DESCRIPTION="--relabel_sha1 should not be used with ${OPTION}"
    "${VSEARCH}" --sortbylength <(printf ">a\nA\n") --relabel_sha1 ${OPTION} \
		 --output - &> /dev/null && \
	failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#                                 --sizeout                                   #
#                                                                             #
#*****************************************************************************#

# --sizeout is accepted
DESCRIPTION="--sizeout is accepted"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - --relabel 'lab' \
	     --sizeout &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --sizeout products correct labels #1
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_sha1 products correct labels #1"
"${VSEARCH}" --sortbysize <(printf ">a;size=5;\nA\n") --output "${OUTPUT}" \
	     --relabel 'lab' --sizeout &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == ">lab1;size=5;" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --sizeout products correct labels #2
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_sha1 products correct labels #2"
"${VSEARCH}" --sortbysize <(printf ">a;size=1;\nA\n>b;size=10;\nA\n>c;size=5;\nA\n") \
	     --output "${OUTPUT}" --relabel 'lab' --sizeout &> /dev/null
[[ $(sed "5q;d" "${OUTPUT}") == ">lab3;size=1;" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"
unset "OUTPUT" "DESCRIPTION"


#*****************************************************************************#
#                                                                             #
#                                  --topn                                     #
#                                                                             #
#*****************************************************************************#

# --topn is accepted
DESCRIPTION="--topn is accepted"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - \
	     --topn 3 &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --topn fails if negative number given
DESCRIPTION="--topn fails if negative number given"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - \
	     --topn -1 &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --topn select sequences with the best abundance score
OUTPUT=$(mktemp)
DESCRIPTION="--topn select sequences with the best abundance score"
"${VSEARCH}" --sortbysize <(printf ">a;size=1;\nA\n>b;size=10;\nA\n>c;size=5;\nA\n") \
	     --output "${OUTPUT}" --topn 2 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">b;size=10;\nA\n>c;size=5;\nA") ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --topn select largest sequences
OUTPUT=$(mktemp)
DESCRIPTION="--topn select largest sequences"
"${VSEARCH}" --sortbylength <(printf ">a\nAAA\n>b\nAA\n>c\nA\n") \
	     --output "${OUTPUT}" --topn 2 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a\nAAA\n>b\nAA") ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --topn select sequences with the best abundance score over their size
OUTPUT=$(mktemp)
DESCRIPTION="--topn select sequences with the best abundance score over their size"
"${VSEARCH}" --sortbysize <(printf ">a;size=1;\nAAAAA\n>b;size=3;\nA\n>c;size=2;\nAAAA\n") \
	     --output "${OUTPUT}" --topn 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">b;size=3;\nA") ]]
success "${DESCRIPTION}" || \
    failure "${DESCRIPTION}"
rm "${OUTPUT}"

# --topn select largest sequences when size is equal
OUTPUT=$(mktemp)
DESCRIPTION="--topn select largest sequences when size is equal"
"${VSEARCH}" --sortbysize <(printf ">a;size=1;\nAAA\n>b;size=1;\nA\n>c;size=1;\nAA\n") \
	     --output "${OUTPUT}" --topn 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=1;\nAAA") ]]
success "${DESCRIPTION}" || \
    failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                                  --xsize                                    #
#                                                                             #
#*****************************************************************************#

# --xsize is accepted
DESCRIPTION="--xsize is accepted"
"${VSEARCH}" --sortbysize <(printf ">a\nAAAA\n") --output - \
	     --xsize &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# --xsize strip the abundance score
OUTPUT=$(mktemp)
DESCRIPTION="--xsize strip the abundance score"
"${VSEARCH}" --sortbysize <(printf ">a;size=1;\nA\n>b;size=10;\nA\n>c;size=5;\nA\n") \
	     --output "${OUTPUT}" --xsize &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">b;size=10;\n>c;size=5;\nA\n>a;size=1;\nA") ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

rm "${SEQx1000}"

exit 0
