#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fastq_eestats all tests"
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
[[ "${VSEARCH}" ]] && success "${DESCRIPTION}" || failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                  basic tests                                #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --alnout --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout is not accepted without id or acceptall"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                                    id tests                                 #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --alnout --id is not accepted without parameter"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is not accepted with wrong parameter"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id 'fail' &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is not accepted with value less than 0"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id \-5.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is not accepted with value more than 1"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id 2.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is not considered if used with acceptall"
OUTPUT=$(printf '>seq1\nAAAAA\n>seq2\nTTTTT\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id 1.0 --acceptall 2>/dev/null | \
    awk '/cols,/ {print $5}')
[[ "${OUTPUT}" == "(0.0%)," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              accepted output                                #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --blast6out --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --blast6out - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --blast6out --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --blast6out - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --fastapairs --acceptall is accepted"
OUTPUT=$(mktemp)
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --fastapairs "${OUTPUT}" --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --fastapairs --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --fastapairs - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --matched --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --matched - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --matched --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --matched - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --notmatched --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --notmatched - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --notmatched --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --notmatched - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --samout --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --samout - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --samout --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --samout - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --uc --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --uc - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --uc --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --uc - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --userout --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --userout - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --userout --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --userout - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                          expected output tests                              #    
#                                                                             #
#*****************************************************************************#
#alnout, blast6out, matched, notmatched, samout, uc, userout
# printf '>seq1\nAAATTA\n>seq2\nAAAAAA\n' | "${VSEARCH}" --allpairs_global - \
#                  --alnout - --id 0.6


DESCRIPTION="--allpairs_global --alnout --id gives the correct result #1"
OUTPUT=$(printf '>seq1\nAAATTA\n>seq2\nAAAAAA\n' | \
		"${VSEARCH}" --allpairs_global - \
			     --alnout - --id 0.6 2>/dev/null | \
		awk '/cols,/ {print $5}')
[[ "${OUTPUT}" == "(66.7%)," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id gives the correct result #2"
OUTPUT=$(printf '>seq1\nAAATTA\n>seq2\nAAAAAA\n' | \
		"${VSEARCH}" --allpairs_global - \
			     --alnout - --id 0.7 2>/dev/null | \
		awk '/cols,/ {print $5}')
[[ "${OUTPUT}" == "" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
