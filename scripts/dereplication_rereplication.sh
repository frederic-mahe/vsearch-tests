#!/bin/bash -

## Print a header
SCRIPT_NAME="Dereplication/rereplication options"
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

## Is vsearch installed?
VSEARCH=$(which vsearch)
DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] &> /dev/null && success "${DESCRIPTION}" || failure "${DESCRIPTION}"

if [[ ${OSTYPE} =~ darwin ]] ; then
    md5sum() { md5 -r ; }
    sha1sum() { shasum ; }
fi

#*****************************************************************************#
#                                                                             #
#                              --derep_fullength                              #
#                                                                             #
#*****************************************************************************#

## --derep_fulllength is accepted
DESCRIPTION="--derep_fulllength is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_fulllength - --output - &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --derep_fulllength fill a file
DESCRIPTION="--derep_fulllength fill a file"
OUTPUT=$(mktemp)
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ -s "${OUTPUT}" ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_fulllength outputs expected results
DESCRIPTION="--derep_fulllength outputs expected results"
OUTPUT=$(mktemp)
printf ">s\nA\n>d\nA\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s\nA") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_fulllength outputs expected results (alphabetical order)
## Sort by alphabet but only takes order in account when dereplecating
## (first will be the remaining)
DESCRIPTION="--derep_fulllength outputs expected results (alphabetical order)"
OUTPUT=$(mktemp)
printf ">c\nA\n>b\nG\n>a\nG\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">b\nG\n>c\nA\n") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_fulllength outputs expected results (case insensitive)
DESCRIPTION="--derep_fulllength outputs expected results (case insensitive)"
OUTPUT=$(mktemp)
printf ">s\nA\n>d\ng\n>f\nA\n>h\nG\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">d\ng\n>s\nA") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_fulllength outputs expected results (T = U)
DESCRIPTION="--derep_fulllength outputs expected results (T = U)"
OUTPUT=$(mktemp)
printf ">s\nT\n>d\nu\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s\nT") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                --derep_prefix                               #
#                                                                             #
#*****************************************************************************#

## --derep_prefix is accepted
DESCRIPTION="--derep_prefix is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output - &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --derep_prefix fill a file
DESCRIPTION="--derep_prefix fill a file"
OUTPUT=$(mktemp)
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ -s "${OUTPUT}" ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix outputs expected results
DESCRIPTION="--derep_prefix outputs expected results"
OUTPUT=$(mktemp)
printf ">s\nACGTAAA\n>d\nACGT\n" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s\nACGTAAA") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix outputs expected results (alphabetical order)
## Sort by alphabet but only takes order in account when dereplecating
## (first will be the remaining)
DESCRIPTION="--derep_prefix outputs expected results (alphabetical order)"
OUTPUT=$(mktemp)
printf ">c\nACGTAAA\n>b\nACGT\n>a\nCCC" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a\nCCC\n>c\nACGTAAA") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix clusters prefix with the shortest prefixed sequence
DESCRIPTION="--derep_prefix clusters prefix with the shortest prefixed sequence"
OUTPUT=$(mktemp)
printf ">a;size=1;\nCCAA\n>b;size=3;\nCCGAA\n>c;size=1;\nCC" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=2;\nCCAA\n>b;size=3;\nCCGAA\n") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix then clusters prefix with the most abundant sequence
DESCRIPTION="--derep_prefix then clusters prefix with the most abundant sequence"
OUTPUT=$(mktemp)
printf ">a;size=1;\nCCGG\n>b;size=2;\nCCAA\n>c;size=1;\nCC" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=1;\nCCGG\n>b;size=3;\nCCAA\n") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix then clusters prefix with the first sequence in alphabetical order
DESCRIPTION="--derep_prefix then clusters prefix with the first sequence in alphabetical order"
OUTPUT=$(mktemp)
printf ">b;size=1;\nCCAA\n>a;size=1;\nCCGG\n>c;size=1;\nCC" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=2;\nCCGG\n>b;size=1;\nCCAA\n") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix finally clusters prefix with the first sequence in file
DESCRIPTION="--derep_prefix finally clusters prefix with the first sequence in file"
OUTPUT=$(mktemp)
printf ">a;size=1;\nCCGG\n>a;size=1;\nCCAA\n>a;size=1;\nCC" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=2;\nCCGG\n>a;size=1;\nCCAA\n") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix outputs expected results (case insensitive)
DESCRIPTION="--derep_prefix outputs expected results (case insensitive)"
OUTPUT=$(mktemp)
printf ">b\nACGTAAA\n>a\nacgt\n" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">b\nACGTAAA") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --derep_prefix outputs expected results (T = U)
DESCRIPTION="--derep_prefix outputs expected results (T = U)"
OUTPUT=$(mktemp)
printf ">s\nTUTUTT\n>d\nTUTU\n" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s\nTUTUTT") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

#*****************************************************************************#
#                                                                             #
#                               --maxuniquesize                               #
#                                                                             #
#*****************************************************************************#

## --maxuniquesize is accepted
DESCRIPTION="--maxuniquesize is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output - --maxuniquesize 2 &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --maxuniquesize outputs expected results
DESCRIPTION="--maxuniquesize outputs expected results"
OUTPUT=$(mktemp)
printf ">s;size=3;\nAAAA\n>d;size=2;\nGG" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --sizein --maxuniquesize 2 --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">d;size=2;\nGG") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --maxuniquesize discard sequence after (de)replication is made
DESCRIPTION="--maxuniquesize discard sequence after (de)replication is made"
OUTPUT=$(mktemp)
printf ">s;size=5;\nAAGT\n>d;size=2;\nAA>f;size=4;\nACGT" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
                 --sizein --maxuniquesize 4 --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">f;size=4;\nACGT") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --maxuniquesize discard sequence after (de)replication is made
DESCRIPTION="--maxuniquesize discard sequence after (de)replication is made"
OUTPUT=$(mktemp)
printf ">s;size=5;\nAAGT\n>d;size=2;\nAA\n>f;size=4;\nACGT" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --sizein --sizeout --maxuniquesize 4 --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">f;size=4;\nACGT") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --maxuniquesize fails if negative argument
DESCRIPTION="--maxuniquesize fails if negative argument"
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output - --maxuniquesize -1 &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"

## --maxuniquesize fails if 0 given
DESCRIPTION="--maxuniquesize fails if 0 given"
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output - --maxuniquesize 0 &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               --minuniquesize                               #
#                                                                             #
#*****************************************************************************#

## --minuniquesize is accepted
DESCRIPTION="--minuniquesize is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output - --minuniquesize 2 &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --minuniquesize outputs expected results
DESCRIPTION="--minuniquesize outputs expected results"
OUTPUT=$(mktemp)
printf ">s;size=3;\nAAAA\n>d;size=2;\nGG" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --sizein --minuniquesize 3 --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s;size=3;\nAAAA") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --minuniquesize discard sequence after (de)replication is made
DESCRIPTION="--minuniquesize discard sequence after (de)replication is made"
OUTPUT=$(mktemp)
printf ">s;size=4;\nAAGT\n>d;size=2;\nAA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --sizein --sizeout --minuniquesize 3 --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s;size=6;\nAAGT") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --minuniquesize fails if negative argument
DESCRIPTION="--minuniquesize fails if negative argument"
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output - --minuniquesize -1 &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"

## --minuniquesize fails if 0 given
DESCRIPTION="--minuniquesize fails if 0 given"
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output - --minuniquesize 0 &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                  --output                                   #
#                                                                             #
#*****************************************************************************#

## --output is accepted
DESCRIPTION="--output is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" --derep_prefix - --output - &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 --relabel                                   #
#                                                                             #
#*****************************************************************************#

## Creating a long sequence for probabilistc tests in relabel
SEQx1000=$(mktemp)
for ((i=1 ; i<=1000 ; i++)) ; do
    printf "@%s%d\nAAGG\n+\nGGGG\n" "seq" ${i}
done > "${SEQx1000}"

## --relabel is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--relabel is accepted"
"${VSEARCH}" --derep_prefix <(printf ">a\nAAAA\n") --relabel 'lab' \
	         --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel products correct labels #1
OUTPUT=$(mktemp)
DESCRIPTION="--relabel products correct labels #1"
printf ">a\nAAAA\n" |\
    "${VSEARCH}" --derep_prefix - --relabel 'lab' \
	             --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == ">lab1" ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel products correct labels #2
OUTPUT=$(mktemp)
DESCRIPTION="--relabel products correct labels #2"
printf ">s\nACGT\n>s\nCGTA\n>s\nGTAC\n" | \
    "${VSEARCH}" --derep_prefix - --relabel 'lab' \
	             --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(sed "5q;d" "${OUTPUT}") == ">lab3" ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel should not be used with other labelling options
for OPTION in "--relabel_md5" "--relabel_sha1" ; do
    DESCRIPTION="--relabel should not be used with ${OPTION}"
    "${VSEARCH}" --derep_prefix <(printf ">a\nAAAA\n") --relabel 'lab' ${OPTION} \
		         --output - --minseqlength 1 &> /dev/null && \
        failure "${DESCRIPTION}" || \
	        success "${DESCRIPTION}"
done

#*****************************************************************************#
#                                                                             #
#                               --relabel_keep                                #
#                                                                             #
#*****************************************************************************#

## --relabel_keep is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_keep is accepted"
"${VSEARCH}" --derep_prefix <(printf ">a\nAAAA\n") --relabel 'lab' --relabel_keep \
	         --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_keep products correct labels
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_keep products correct labels"
"${VSEARCH}" --derep_prefix <(printf ">a\nAAAA\n") --relabel 'lab' --relabel_keep \
	         --output "${OUTPUT}" --minseqlength 1 &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == ">lab1 a" ]] && \
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
"${VSEARCH}" --derep_prefix <(printf ">a\nAAAA\n") --relabel_md5 \
	         --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_md5 products correct labels
DESCRIPTION="--relabel_md5 products correct labels"
[[ $("${VSEARCH}" --derep_prefix <(printf '>a\nAAAA\n') --relabel_md5 \
		          --output - --minseqlength 1 2> /dev/null \
	        | awk -F "[>]" '{printf $2}') == \
                                          $(printf "AAAA" | md5sum | awk '{printf $1}') ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --relabel_md5 original labels are shuffled (1‰ chance of failure)
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_md5 original labels are shuffled (1‰ chance of failure)"
"${VSEARCH}" --derep_prefix "${SEQx1000}" --relabel_md5 --minseqlength 1 \
	         --output "${OUTPUT}" &> /dev/null
[[ $(awk 'NR==1 {print $2}' "${OUTPUT}") != "seq1" ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_md5 should not be used with other labelling options
for OPTION in "--relabel 'lab'" "--relabel_sha1" ; do
    DESCRIPTION="--relabel_keep should not be used with ${OPTION}"
    "${VSEARCH}" --derep_prefix <(printf ">a\nAAAA\n") --relabel_md5 ${OPTION} \
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
"${VSEARCH}" --derep_prefix <(printf ">a\nAAAA\n") --relabel_sha1 \
	         --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_sha1 products correct labels
DESCRIPTION="--relabel_sha1 products correct labels"
INPUT=$("${VSEARCH}" --derep_prefix <(printf '>a\nAAAA\n') --relabel_sha1 \
		             --minseqlength 1 --output - 2> /dev/null | \
	           awk -F "[>]" '{printf $2}')
SHA1=$(printf "AAAA" | sha1sum | awk '{printf $1}')
[[ "${INPUT}" == "${SHA1}" ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --relabel_sha1 original labels are shuffled (1‰ chance of failure)
OUTPUT=$(mktemp)
DESCRIPTION="--relabel_sha1 original labels are shuffled (1‰ chance of failure)"
"${VSEARCH}" --derep_prefix "${SEQx1000}" --relabel_sha1 \
	         --minseqlength 1 --output "${OUTPUT}" &> /dev/null
[[ $(awk 'NR==1 {print $2}' "${OUTPUT}") != "seq1" ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --relabel_sha1 should not be used with other labelling options
for OPTION in "--relabel 'lab'" "--relabel_md5" ; do
    DESCRIPTION="--relabel_keep should not be used with ${OPTION}"
    "${VSEARCH}" --derep_prefix <(printf ">a\nAAAA\n") --relabel_sha1 ${OPTION} \
		         --output - &> /dev/null && \
        failure "${DESCRIPTION}" || \
	        success "${DESCRIPTION}"
done

rm "${SEQx1000}"


#*****************************************************************************#
#                                                                             #
#                               --rereplicate                                 #
#                                                                             #
#*****************************************************************************#

## --rereplicate is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--rereplicate is accepted"
printf ">a\nAAAA\n" | \
    "${VSEARCH}" --rereplicate - --output "${OUTPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --rereplicate correctly rereplicate
OUTPUT=$(mktemp)
DESCRIPTION="--rereplicate correctly rereplicate"
printf ">a;size=2;\nAAAA\n" | \
    "${VSEARCH}" --rereplicate - --output "${OUTPUT}" &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a\nAAAA\n>a\nAAAA") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --rereplicate correctly rereplicate #1
OUTPUT=$(mktemp)
DESCRIPTION="--rereplicate correctly rereplicate #1"
printf ">a;size=2;\nAAAA\n" | \
    "${VSEARCH}" --rereplicate - --output "${OUTPUT}" &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a\nAAAA\n>a\nAAAA") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --rereplicate correctly rereplicate #2
OUTPUT=$(mktemp)
DESCRIPTION="--rereplicate correctly rereplicate #2"
printf ">a\nAAAA\n" | \
    "${VSEARCH}" --rereplicate - --output "${OUTPUT}" &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a\nAAAA") ]] &&
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                 --sizein                                    #
#                                                                             #
#*****************************************************************************#

## --sizein is accepted
OUTPUT=$(mktemp)
DESCRIPTION="--rereplicate is accepted"
printf ">a\nAAAA\n" | \
    "${VSEARCH}" --rereplicate - --output "${OUTPUT}" --sizein &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizein is mandatory to process abundance with --rereplicate
OUTPUT=$(mktemp)
DESCRIPTION="--sizein is mandatory to process abundance --rereplicate"
printf ">a;size=3;\nAAAA\n" | \
    "${VSEARCH}" --rereplicate - --output "${OUTPUT}" &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=3;\nAAAA\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizein allow to take abundance in account with --rereplicate
OUTPUT=$(mktemp)
DESCRIPTION="--sizein allow to take abundance in account with --rereplicate"
printf ">a;size=3;\nAAAA\n" | \
    "${VSEARCH}" --rereplicate - --output "${OUTPUT}" --sizein &> /dev/null
[[ $(cat "${OUTPUT}") == \
                      $(printf ">a\nAAAA\n>a\nAAAA\n>a\nAAAA\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizein is mandatory to process abundance with --derep_prefix
OUTPUT=$(mktemp)
DESCRIPTION="--sizein is mandatory to process abundance --derep_prefix"
printf ">a;size=3;\nAACC\n>a;size=2;\nAA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=3;\nAACC\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizein sizein allow to take abundance in account with --derep_prefix
OUTPUT=$(mktemp)
DESCRIPTION="--sizein sizein allow to take abundance in account with --derep_prefix"
printf ">a;size=3;\nAACC\n>a;size=2;\nAA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=5;\nAACC\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizein is mandatory to process abundance with --derep_fullength
OUTPUT=$(mktemp)
DESCRIPTION="--sizein is mandatory to process abundance --derep_fulllength"
printf ">a;size=3;\nAA\n>b;size=2;\nAA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=3;\nAA\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizein allow to take abundance in account with --derep_fullength
OUTPUT=$(mktemp)
DESCRIPTION="--sizein allow to take abundance in account with --derep_fulllength"
printf ">a;size=3;\nAA\n>a;size=2;\nAA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=5;\nAA\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                 --sizeout                                   #
#                                                                             #
#*****************************************************************************#

## --sizeout is accepted
DESCRIPTION="--sizeout is accepted"
printf ">a\nAAAA\n" | \
    "${VSEARCH}" --rereplicate - --output - --sizeout &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --sizeout completes missing abundance scores
OUTPUT=$(mktemp)
DESCRIPTION="--sizeout completes missing abundance scores"
printf ">a;size=3;\nAAAA\n>b\nCCCC\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" \
		         --sizein --sizeout --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=3;\nAAAA\n>b;size=1;\nCCCC\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizeout is mandatory to write down abundance with --derep_prefix
OUTPUT=$(mktemp)
DESCRIPTION="--sizeout is mandatory to write down abundance --derep_prefix"
printf ">a;size=3;\nAACC\n>a;size=2;\nAA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=3;\nAACC\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizeout allow to take abundance in account with --derep_prefix
OUTPUT=$(mktemp)
DESCRIPTION="--sizeout allow to take abundance in account with --derep_prefix"
printf ">a;size=3;\nAACC\n>a;size=2;\nAA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=5;\nAACC\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizeout is mandatory to write down abundance with --derep_fullength
OUTPUT=$(mktemp)
DESCRIPTION="--sizeout is mandatory to write down abundance --derep_fulllength"
printf ">a;size=3;\nAA\n>b;size=2;\nAA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=3;\nAA\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --sizeout allow to take abundance in account with --derep_fullength
OUTPUT=$(mktemp)
DESCRIPTION="--sizeout allow to take abundance in account with --derep_fulllength"
printf ">a;size=3;\nAA\n>a;size=2;\nAA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" \
		         --minseqlength 1 --sizein --sizeout &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">a;size=5;\nAA\n") ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                  --strand                                   #
#                                                                             #
#*****************************************************************************#

## --strand is accepted
DESCRIPTION="--strand is accepted"
printf ">a\nAAAA\n" | \
    "${VSEARCH}" --derep_fulllength - --output - --strand both &> /dev/null &&\
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --strand both allow dereplication of strand plus and minus (--derep_fulllength)
OUTPUT=$(mktemp)
DESCRIPTION="--strand allow dereplication of strand plus and minus (--derep_fulllength)"
printf ">s1;size=1;\nTAGC\n>s2;size=1;\nGCTA" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --strand both \
		         --sizein --sizeout --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1;size=2;\nTAGC\n") ]] &&\
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --strand plus does not change default behaviour
OUTPUT=$(mktemp)
DESCRIPTION="--strand plus does not change default behaviour"
printf ">s1;size=1;\nTAGC\n>s2;size=1;\nGCTA" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --strand plus \
		         --sizein --sizeout --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1;size=1;\nTAGC\n>s2;size=1;\nGCTA") ]] &&\
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --strand allow dereplication of strand plus and minus (--derep_prefix)
OUTPUT=$(mktemp)
DESCRIPTION="--strand allow dereplication of strand plus and minus (--derep_prefix)"
printf ">s1;size=1;\nTAGCAA\n>s2;size=1;\nGCTA" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --strand both \
		         --sizein --sizeout --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1;size=2;\nTAGCAA\n") ]] &&\
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --strand fails if unknown argument is given
DESCRIPTION="--strand fails if unknown argument is given"
printf ">a\nAAAA\n" | \
    "${VSEARCH}" --derep_fulllength - --output - --strand bonjour &> /dev/null &&\
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                                   --topn                                    #
#                                                                             #
#*****************************************************************************#

## --topn is accepted
DESCRIPTION="--topn is accepted"
printf ">a\nAAAA\n" | \
    "${VSEARCH}" --derep_fulllength - --output - --topn 2 &> /dev/null &&\
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --topn discard sequences
OUTPUT=$(mktemp)
DESCRIPTION="--topn discard sequences"
printf ">s1;size=1;\nAAAA\n>s2;size=2;\nCCCC\n>s3;size=3;\nGGGG\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --topn 2 \
		         --sizein --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s3;size=3;\nGGGG\n>s2;size=2;\nCCCC\n") ]] &&\
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --topn discard sequences after processings (derep_fulllength)
OUTPUT=$(mktemp)
DESCRIPTION="--topn discard sequences after processings (derep_fulllength)"
printf ">s1;size=5;\nAAAA\n>s2;size=3;\nCCCC\n>s3;size=3;\nCCCC\n" | \
    "${VSEARCH}" --derep_fulllength - --output "${OUTPUT}" --topn 1 \
		         --sizein --sizeout --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s2;size=6;\nCCCC") ]] &&\
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --topn discard sequences after processings (derep_prefix)
OUTPUT=$(mktemp)
DESCRIPTION="--topn discard sequences after processings (derep_prefix)"
printf ">s1;size=5;\nAAAA\n>s2;size=3;\nCCCC\n>s3;size=3;\nCC\n" | \
    "${VSEARCH}" --derep_prefix - --output "${OUTPUT}" --topn 1 \
		         --sizein --sizeout --minseqlength 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s2;size=6;\nCCCC") ]] &&\
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --topn fails with negative arguments
DESCRIPTION="--topn fails with negative arguments"
printf ">a\nAAAA\n" | \
    "${VSEARCH}" --derep_fulllength - --output - --topn -1 &> /dev/null &&\
    failure "${DESCRIPTION}" || \
	    succes "${DESCRIPTION}"

## --topn fails with null arguments
DESCRIPTION="--topn fails with null arguments"
printf ">a\nAAAA\n" | \
    "${VSEARCH}" --derep_fulllength - --output - --topn 0 &> /dev/null &&\
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                                    --uc                                     #
#                                                                             #
#*****************************************************************************#

## --uc is accepted
DESCRIPTION="--uc is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --uc - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc fails if no output redirection is given (filename, device or -)
DESCRIPTION="--uc fails if no output redirection is given"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --uc &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc outputs data
DESCRIPTION="--uc outputs data"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns no H line (first column) when there is no hit
DESCRIPTION="--uc returns no H line when there is no hit"
printf ">a\nA\n>b\nG\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc returns a H line (first column) when there is a hit
DESCRIPTION="--uc returns a H line when there is a hit"
printf ">a\nA\n>b\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc returns the expected number of S lines (centroids)
DESCRIPTION="--uc returns the expected number of S lines (centroids)"
printf ">s1\nA\n>s2\nA\n>s3\nG\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --quiet \
        --uc - | \
    awk '/^S/ {c += 1} END {exit c == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc number of cluster records is correct in 1st column
DESCRIPTION="--uc number of cluster records is correct in 1st column"
OUTPUT=$(mktemp)
printf ">s1\nAA\n>s2\nAA\n>s3\nGG\n" | \
    "${VSEARCH}" --derep_fulllength - --uc "${OUTPUT}" --minseqlength 1 &> /dev/null
NUMBER_OF_CLUSTERS=$(grep -c "^C" "${OUTPUT}")
(( "${NUMBER_OF_CLUSTERS}" == 2 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --uc cluster number is correct in 2nd column #1
DESCRIPTION="--uc cluster number is correct in 2nd column #1"
OUTPUT=$(mktemp)
printf ">s1\nGGGG\n" | \
    "${VSEARCH}" --derep_fulllength - --uc "${OUTPUT}" --minseqlength 1 &> /dev/null
CLUSTER_NUMBER=$(awk '/^C/ {v = $2} END {print v}' "${OUTPUT}")
(( "${CLUSTER_NUMBER}" == 0 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --uc cluster number is correct in 2nd column #2
DESCRIPTION="--uc cluster number is correct in 2nd column #2"
OUTPUT=$(mktemp)
printf ">s1\nGG\n>s2\nAA\n>s3\nAA\n" | \
    "${VSEARCH}" --derep_fulllength - --uc "${OUTPUT}" --minseqlength 1 &> /dev/null
CLUSTER_NUMBER=$(awk '/^C/ {v = $2} END {print v}' "${OUTPUT}")
(( "${CLUSTER_NUMBER}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --uc cluster size is correct in 3rd column
DESCRIPTION="--uc cluster number is correct in 3rd column"
OUTPUT=$(mktemp)
printf ">s1\nAA\n>s2\nAA\n" | \
    "${VSEARCH}" --derep_fulllength - --uc "${OUTPUT}" --minseqlength 1 &> /dev/null
CLUSTER_SIZE=$(awk '/^C/ {v = $3} END {print v}' "${OUTPUT}")
[[ "${CLUSTER_SIZE}" == "2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --uc centroid length is correct in 3rd column #1
DESCRIPTION="--uc centroid length is correct in 3rd column #1"
OUTPUT=$(mktemp)
printf ">s1\nG\n" | \
    "${VSEARCH}" --derep_fulllength - --uc "${OUTPUT}" --minseqlength 1 &> /dev/null
CENTROID_LENGTH=$(awk '/^S/ {v = $3} END {print v}' "${OUTPUT}")
(( "${CENTROID_LENGTH}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTIONz}"
rm "${OUTPUT}"

## --uc centroid length is correct in 3rd column #2
DESCRIPTION="--uc centroid length is correct in 3rd column #2"
OUTPUT=$(mktemp)
"${VSEARCH}" \
    --derep_fulllength <(printf ">s1\nGG\n") \
    --minseqlength 1 \
    --uc "${OUTPUT}" &> /dev/null
CENTROID_LENGTH=$(awk '/^S/ {v = $3} END {print v}' "${OUTPUT}")
(( "${CENTROID_LENGTH}" == 2 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --uc hit length is correct in 3rd column #1
DESCRIPTION="--uc hit length is correct in 3rd column #1"
HIT_LENGTH=$(printf ">s1\nAA\n>s2\nAA\n" | \
		            "${VSEARCH}" --derep_fulllength - --uc - \
				                 --minseqlength 1 2> /dev/null | \
		            awk '/^H/ {v = $3} END {print v}' -)
[[ "${HIT_LENGTH}" == "2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc hit length is correct in 3rd column #2
DESCRIPTION="--uc hit length is correct in 3rd column #2"
HIT_LENGTH=$(printf ">s1\nA\n>s2\nA\n" | "${VSEARCH}" --derep_fulllength - --uc - \
		                                              --minseqlength 1 2> /dev/null | \
		            awk '/^H/ {v = $3} END {print v}' -)
(( "${HIT_LENGTH}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc similarity percentage is correct in 4th column
DESCRIPTION="--uc similarity percentage is correct in 4th column"
SIMILARITY_PERCENTAGE=$(printf ">s2\nAA\n>s3\nAA\n" | \
			                   "${VSEARCH}" --derep_fulllength - --uc - \
					                        --minseqlength 1 2> /dev/null | \
			                   awk '/^H/ {v = $4} END {print v}' -)
[[ "${SIMILARITY_PERCENTAGE}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc match orientation is correct in 5th column with H (+)
DESCRIPTION="--uc match orientation is correct in 5th column with H (+)"
MATCH_ORIENTATION=$(printf ">s1;size=1;\nAA\n>s2;size=1;\nAA\n" | \
			               "${VSEARCH}" --derep_fulllength - --uc - \
					                    --minseqlength 1 2> /dev/null | \
			               awk '/^H/ {v = $5} END {print v}' -)
[[ "${MATCH_ORIENTATION}" == "+" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc match orientation is correct in 5th column with H (-)
DESCRIPTION="--uc match orientation is correct in 5th column with H (-)"
MATCH_ORIENTATION=$(printf ">s1;size=1;\nGACT\n>s2;size=1;\nAGTC\n" | \
			               "${VSEARCH}" --derep_fulllength - --uc - --strand both \
					                    --minseqlength 1 2> /dev/null | \
			               awk '/^H/ {v = $5} END {print v}' -)

[[ "${MATCH_ORIENTATION}" == "-" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc match orientation is * in 5th column with S
DESCRIPTION="--uc match orientation is correct in 5th column with S"
MATCH_ORIENTATION=$(printf ">s1;size=1;\nGA" | \
			               "${VSEARCH}" --derep_fulllength - --uc - \
			                            --minseqlength 1 2> /dev/null | \
                           awk '/^S/ {v = $5} END {print v}' -)
[[ "${MATCH_ORIENTATION}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc match orientation is * in 5th column with C
DESCRIPTION="--uc match orientation is correct in 5th column with C"
MATCH_ORIENTATION=$(printf ">s1\nAA\n" | \
			               "${VSEARCH}" --derep_fulllength - --uc - \
					                    --minseqlength 1 2> /dev/null | \
			               awk '/^C/ {v = $5} END {print v}' -)
[[ "${MATCH_ORIENTATION}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 6th column is * with C
DESCRIPTION="--uc 6th column is * with C"
COLUMN_6=$(printf ">s1\nAA\n" | \
		          "${VSEARCH}" --derep_fulllength - --uc - \
			                   --minseqlength 1 2> /dev/null | \
		          awk '/^C/ {v = $6} END {print v}' -)
[[ "${COLUMN_6}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 6th column is * with S
OUTPUT=$(mktemp)
DESCRIPTION="--uc 6th column is * with S"
printf ">s1\nAA\n" | \
    "${VSEARCH}" --derep_fulllength - --uc "${OUTPUT}" --minseqlength 1 &> /dev/null
COLUMN_6=$(awk '/^S/ {v = $6} END {print v}' "${OUTPUT}")
[[ "${COLUMN_6}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --uc 6th column is 0 with H
DESCRIPTION="--uc 6th column is 0 with H"
COLUMN_6=$(printf ">s1\nAA\n>s2\nAA\n" | \
		          "${VSEARCH}" --derep_fulllength - --uc - \
			                   --minseqlength 1 2> /dev/null | \
		          awk '/^H/ {v = $6} END {print v}' -)
(( "${COLUMN_6}" == 0 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 7th column is * with C
DESCRIPTION="--uc 7th column is * with C"
COLUMN_7=$(printf ">s1\nAA\n" | \
		          "${VSEARCH}" --derep_fulllength - --uc - \
			                   --minseqlength 1 2> /dev/null | \
		          awk '/^C/ {v = $7} END {print v}' -)
[[ "${COLUMN_7}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 7th column is * with S
DESCRIPTION="--uc 7th column is * with S"
COLUMN_7=$(printf ">s1\nAA\n" | \
		          "${VSEARCH}" --derep_fulllength - --uc - \
			                   --minseqlength 1 2> /dev/null | \
		          grep "^S" - | \
                  awk -F "\t" '{if (NR == 1) {print $7}}')
[[ "${COLUMN_7}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 7th column is 0 with H
DESCRIPTION="--uc 7th column is 0 with H"
COLUMN_7=$(printf ">s1\nAA\n>s2\nAA\n" | \
		          "${VSEARCH}" --derep_fulllength - --uc - \
			                   --minseqlength 1 2> /dev/null | \
		          awk '/^H/ {v = $7} END {print v}' -)
[[ "${COLUMN_7}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 8th collumn is * with S
DESCRIPTION="--uc 8th collumn is * with S"
COLUMN_8=$(printf ">s1\nAA\n" | \
		          "${VSEARCH}" --derep_fulllength - --uc - \
			                   --minseqlength 1 2> /dev/null | \
		          awk '/^S/ {v = $8} END {print v}' -)
[[ "${COLUMN_8}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 8th collumn is * with C
DESCRIPTION="--uc 8th collumn is * with C"
COLUMN_8=$(printf ">s1\nAA\n" | \
		          "${VSEARCH}" --derep_fulllength - --uc - \
			                   --minseqlength 1 2> /dev/null | \
		          awk '/^C/ {v = $8} END {print v}' -)
[[ "${COLUMN_8}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 8th collumn is * with H
DESCRIPTION="--uc 8th collumn is * with H"
COLUMN_8=$(printf ">s1\nAA\n>s2\nAA\n" | \
		          "${VSEARCH}" --derep_fulllength - --uc - \
			                   --minseqlength 1 2> /dev/null | \
		          awk '/^H/ {v = $8} END {print v}' -)
[[ "${COLUMN_8}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc query sequence's label is correct in 9th column with H
DESCRIPTION="--uc query sequence's label is correct in 9th column with H"
QUERY_LABEL=$(printf ">s1\nAA\n>s2\nAA\n" | \
		             "${VSEARCH}" --derep_fulllength - --uc - \
				                  --minseqlength 1 2> /dev/null | \
		             awk '/^H/ {v = $9} END {print v}' -)
[[ "${QUERY_LABEL}" == "s2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid sequence's label is correct in 9th column with S
DESCRIPTION="--uc centroid sequence's label is correct in 9th column with S"
CENTROID_LABEL=$(printf ">s1\nAA\n" | \
			            "${VSEARCH}" --derep_fulllength - --uc - \
				                     --minseqlength 1 2> /dev/null | \
			            awk '/^S/ {v = $9} END {print v}' -)
[[ "${CENTROID_LABEL}" == "s1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid sequence's label is correct in 9th column with C
DESCRIPTION="--uc centroid sequence's label is correct in 9th column with C"
CENTROID_LABEL=$(printf ">s1\nAA\n" | \
			            "${VSEARCH}" --derep_fulllength - --uc - \
				                     --minseqlength 1 2> /dev/null | \
			            awk '/^C/ {v = $9} END {print v}' -)
[[ "${CENTROID_LABEL}" == "s1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid sequence's label is correct in 10th column with H
DESCRIPTION="--uc centroid sequence's label is correct in 10th column with H"
CENTROID_LABEL=$(printf ">s1\nAA\n>s2\nAA\n" | \
			            "${VSEARCH}" --derep_fulllength - --uc - \
				                     --minseqlength 1 2> /dev/null | \
			            awk '/^H/ {v = $10} END {print v}' -)
[[ "${CENTROID_LABEL}" == "s1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 10th column is * with C (it is different than * only for H records)
DESCRIPTION="--uc 10th column is * with C"
printf ">s1\nA\n" | \
	"${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 --quiet | \
    awk '/^C/ {v = $10} END {exit v ~ "*" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 10th column is * with S
DESCRIPTION="--uc 10th column is * with S"
CENTROID_LABEL=$(printf ">a_3\nAAAA\n>b_3\nAAAC\n>c_3\nAACC\n>d_3\nAGCC\n" | \
			            "${VSEARCH}" --derep_fulllength - --uc - \
				                     --minseqlength 1 2> /dev/null | \
			            awk '/^S/ {v = $10} END {print v}' -)
[[ "${CENTROID_LABEL}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                   --xsize                                   #
#                                                                             #
#*****************************************************************************#

## --xsize is accepted
DESCRIPTION="--xsize is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --xsize \
        --output - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xsize strips abundance values (removes the ";size=INT[;]" annotations)
DESCRIPTION="--xsize strips abundance values"
printf ">s;size=1;\nA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --sizein --xsize \
        --quiet \
        --output - | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

exit 0
