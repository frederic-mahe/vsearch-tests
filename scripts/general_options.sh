#!/bin/bash -

## Print a header
SCRIPT_NAME="General options"
LINE=$(printf "%76s\n" | tr " " "-")
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
ALL_IDENTICAL=$(mktemp)
for ((i=1 ; i<=10 ; i++)) ; do
    printf "@%s%d\nAAGG\n+\nGGGG\n" "seq" ${i}
done > "${ALL_IDENTICAL}"


#*****************************************************************************#
#                                                                             #
#                                 Input tests                                 #
#                                                                             #
#*****************************************************************************#

## vsearch accepts classical inputs
INPUT=$(mktemp)
DESCRIPTION="vsearch accepts classical inputs"
printf "@a\nA\n+\nI\n" > "${INPUT}"
"${VSEARCH}" --fastq_chars "${INPUT}" &>/dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${INPUT}"

## vsearch accepts sub-process inputs
DESCRIPTION="vsearch accepts sub-process inputs"
"${VSEARCH}" --fastq_chars <(printf "@a\nA\n+\nI\n") &>/dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## vsearch accepts inputs from pipes (/dev/stdin)
DESCRIPTION="vsearch accepts inputs from pipes (/dev/stdin)"
printf "@a\nA\n+\nI\n" | \
    "${VSEARCH}" --fastq_chars /dev/stdin &>/dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## vsearch accepts inputs from pipes
DESCRIPTION="vsearch accepts inputs from pipes"
printf "@a\nA\n+\nI\n" | "${VSEARCH}" --fastq_chars - &>/dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## vsearch accepts inputs from named pipes
DESCRIPTION="vsearch accepts inputs from named pipes"
mkfifo fifoTestInput123
"${VSEARCH}" --fastq_chars fifoTestInput123 &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}" &
printf "@a\nA\n+\na\n" > fifoTestInput123
rm fifoTestInput123


#*****************************************************************************#
#                                                                             #
#                                 fastq tests                                 #
#                                                                             #
#*****************************************************************************#

## vsearch should not accepts empty sequences
DESCRIPTION="vsearch should not accepts empty sequences"
"${VSEARCH}" --fastq_chars <(printf "@a\n\n+\n\n") &>/dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                         Options --bzip2_decompress                          #
#                                                                             #
#*****************************************************************************#

## bzip2 is installed
DESCRIPTION="bzip2 is installed"
which bzip2 &> /dev/null && success "${DESCRIPTION}" || failure "${DESCRIPTION}"

# ## --bzip2 is accepted
# DESCRIPTION="--bzip2_decompress is accepted"
# "${VSEARCH}" --fastq_chars <(printf "@a\nA\n+\nI\n" | bzip2) \
#              --bzip2_decompress &> /dev/null && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                          Options --gzip_decompress                          #
#                                                                             #
#*****************************************************************************#

## gzip is installed
DESCRIPTION="gzip is installed"
which gzip &> /dev/null && success "${DESCRIPTION}" || failure "${DESCRIPTION}"

## --gzip is accepted
DESCRIPTION="--gzip_decompress is accepted"
"${VSEARCH}" --fastq_chars <(printf "@a\nA\n+\nI\n" | gzip) \
	     --gzip_decompress &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --gzip_decompress does not modify output
DESCRIPTION="--gzip_decompress does not modify output"
GZIP_OUTPUT=$("${VSEARCH}" --fastq_chars <(printf "@a\nA\n+\nI\n" | gzip) \
			   --gzip_decompres 2>&1)
CLASSIC_OUTPUT=$("${VSEARCH}" --fastq_chars <(printf "@a\nA\n+\nI\n") 2>&1 )
[[ "${GZIP_OUTPUT}" == "${CLASSIC_OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                        Options --version and --help                         #
#                                                                             #
#*****************************************************************************#

## Return status should be 0 after -h and -v (GNU standards)
for OPTION in "-h" "-v" ; do
    DESCRIPTION="return status should be 0 after ${OPTION}"
    "${VSEARCH}" "${OPTION}" &> /dev/null && \
	success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#                            Option --maxseqlength                            #
#                                                                             #
#*****************************************************************************#

## --maxseqlength is accepted
DESCRIPTION="--maxseqlength is accepted"
"${VSEARCH}" --fastq_chars  "${ALL_IDENTICAL}" \
	     --maxseqlength 2 &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --maxseqlength actually discard sequences
OUTPUT=$(mktemp)
DESCRIPTION="--maxseqlength actually discard sequences"
"${VSEARCH}" --shuffle  <(printf ">a\nAAAA\n>b\nAA\n>c\nA\n") --maxseqlength 2 \
	     --output "${OUTPUT}" &> /dev/null
NB_OF_SEQ_READx2=$(echo $(wc -l < "${OUTPUT}"))
   [[ "${NB_OF_SEQ_READx2}" == 4 ]] && \
   success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                            Option --minseqlength                            #
#                                                                             #
#*****************************************************************************#

## --minseqlength is accepted
DESCRIPTION="--minseqlength is accepted"
"${VSEARCH}" --fastq_chars  "${ALL_IDENTICAL}" \
	     --minseqlength 2 &> /dev/null && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"

## --minseqlength actually discard sequences
OUTPUT=$(mktemp)
DESCRIPTION="--minseqlength actually discard sequences"
"${VSEARCH}" --shuffle  <(printf ">a\nAAAA\n>b\nAA\n>c\nA\n") --minseqlength 2 \
	     --output "${OUTPUT}" &> /dev/null
NB_OF_SEQ_READx2=$(echo $(wc -l < "${OUTPUT}"))
   [[ "${NB_OF_SEQ_READx2}" == 4 ]] && \
   success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"
rm "${OUTPUT}"


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
DESCRIPTION="--quiet is accepted"
printf '@a\nACGT\n+\n@JJh\n' | \
    "${VSEARCH}" --fastq_chars - --quiet &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --quiet actually shrink the output
OUTPUT=$(mktemp)
DESCRIPTION="--quiet actually shrink the output"
printf '@a\nA\n+\nI\n' | \
    "${VSEARCH}" --fastq_chars - --quiet 2> "${OUTPUT}"
COUNT=$(wc -l < "${OUTPUT}")
(( "${COUNT}" == 12 )) && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

rm "${ALL_IDENTICAL}"
exit 0
