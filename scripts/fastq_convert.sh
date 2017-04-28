#!/bin/bash -

## Print a header
SCRIPT_NAME="fastq_convert"
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

#*****************************************************************************#
#                                                                             #
#                                   General                                   #
#                                                                             #
#*****************************************************************************#

## --fastq_convert is accepted with its necessary arguments
DESCRIPTION="--fastq_convert is accepted with its necessary arguments"
"${VSEARCH}" --fastq_convert <(printf "@a\nA\n+\n1") --fastq_ascii 33 \
	     --fastq_asciiout 64 --fastqout - &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --fastq_convert create and fill a file
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_convert create and fill a file"
"${VSEARCH}" --fastq_convert <(printf "@a\nA\n+\n1") --fastq_ascii 33 \
	     --fastq_asciiout 64 --fastqout "${OUTPUT}" &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --fastq_convert output is correct from 33 to 64
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_convert output is correct from 33 to 64"
"${VSEARCH}" --fastq_convert <(printf '@a\nAAAAAAA\n+\n!#+08<@') --fastq_ascii 33 \
	     --fastq_asciiout 64 --fastqout "${OUTPUT}" &> /dev/null
[[ $(sed "4q;d" "${OUTPUT}") == '@BJOW[_' ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --fastq_convert output is correct from 64 to 33
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_convert output is correct from 64 to 33"
"${VSEARCH}" --fastq_convert <(printf '@a\nAAAAAAA\n+\n@FMX\_`') --fastq_ascii 64 \
	     --fastq_asciiout 33 --fastqout "${OUTPUT}" &> /dev/null
[[ $(sed "4q;d" "${OUTPUT}") == "!'.9=@A" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --fastq_qminout output is correct from 33 to 64
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_qminout output is correct from 33 to 64"
"${VSEARCH}" --fastq_convert <(printf '@a\nAAA\n+\n$(4\n') --fastq_ascii 33 \
	     --fastq_asciiout 64 --fastqout "${OUTPUT}" \
	     --fastq_qminout 8 &> /dev/null
[[ $(sed "4q;d" "${OUTPUT}") == "HHS" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --fastq_qminout output is correct from 64 to 33
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_qminout output is correct from 64 to 33"
"${VSEARCH}" --fastq_convert <(printf '@a\nAAA\n+\n@CH') --fastq_ascii 64 \
	     --fastq_asciiout 33 --fastqout "${OUTPUT}" \
	     --fastq_qminout 4 &> /dev/null
[[ $(sed "4q;d" "${OUTPUT}") == "%%)" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --fastq_qmaxout output is correct from 33 to 64
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_qmaxout output is correct from 33 to 64"
"${VSEARCH}" --fastq_convert <(printf '@a\nAAA\n+\n+14') --fastq_ascii 33 \
	     --fastq_asciiout 64 --fastqout "${OUTPUT}" \
	     --fastq_qmaxout 14 &> /dev/null
[[ $(sed "4q;d" "${OUTPUT}") == "JNN" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --fastq_qmaxout output is correct from 64 to 33
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_qmaxout output is correct from 64 to 33"
"${VSEARCH}" --fastq_convert <(printf '@a\nAAA\n+\nGUW') --fastq_ascii 64 \
	     --fastq_asciiout 33 --fastqout "${OUTPUT}" \
	     --fastq_qmaxout 20 &> /dev/null
[[ $(sed "4q;d" "${OUTPUT}") == "(55" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --fastq_convert fails if quality score are out of specified range #1
DESCRIPTION="--fastq_convert fails if quality score are out of specified range #1"
"${VSEARCH}" --fastq_convert <(printf '@a\nAA\n+\nhJ') --fastq_ascii 33 \
	     --fastq_asciiout 64 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --fastq_convert fails if quality score are out of specified range #2
DESCRIPTION="--fastq_convert fails if quality score are out of specified range #2"
"${VSEARCH}" --fastq_convert <(printf '@a\nAA\n+\n?@') --fastq_ascii 64 \
	     --fastq_asciiout 33 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --fastq_convert fails if offset specified is invalid for input
DESCRIPTION="--fastq_convert fails if offset specified is invalid for input"
"${VSEARCH}" --fastq_convert <(printf '@a\nA\n+\nA') --fastq_ascii 56 \
	     --fastq_asciiout 33 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --fastq_convert fails if offset specified is invalid for output
DESCRIPTION="--fastq_convert fails if offset specified is invalid for output"
"${VSEARCH}" --fastq_convert <(printf '@a\nA\n+\nA') --fastq_ascii 64 \
	     --fastq_asciiout 17 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

exit 0
