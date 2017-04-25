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
#                         Options --bzip2_decompress                          #
#                                                                             #
#*****************************************************************************#

## bzip2 is installed
OUTPUT=$(mktemp)
DESCRIPTION="bzip2 is installed"
which bzip2 > "${OUTPUT}"
[[ -s "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --bzip2 is accepted
DESCRIPTION="--bzip2_decompress is accepted"
"${VSEARCH}" --fastq_chars <(cat "${ALL_IDENTICAL}" | bzip2) --bzip2_decompress  &> /dev/null && \
    success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                          Options --gzip_decompress                          #
#                                                                             #
#*****************************************************************************#

## gzip is installed
OUTPUT=$(mktemp)
DESCRIPTION="gzip is installed"
which gzip > "${OUTPUT}"
[[ -s "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --gzip_decompress is accepted
DESCRIPTION="--gzip_decompress is accepted"
"${VSEARCH}" --fastq_chars <(cat "${ALL_IDENTICAL}" | gzip) --gzip_decompres &> /dev/null && \
    success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"

## --gzip_decompress does not modify output
DESCRIPTION="--gzip_decompress does not modify output"
[[ $("${VSEARCH}" --fastq_chars  <(cat "${ALL_IDENTICAL}" | gzip) --gzip_decompres &> /dev/null) ==\
		$("${VSEARCH}" --fastq_chars "${ALL_IDENTICAL}" &>/dev/null) ]] &&
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
    "${VSEARCH}" "${OPTION}" 2> /dev/null > /dev/null && \
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
"${VSEARCH}" --fastq_chars  "${ALL_IDENTICAL}" --maxseqlength 2 &> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --maxseqlength actually discard sequences
#OUTPUT=$(mktemp)
#DESCRIPTION="--maxseqlength actually discard sequences"
#"${VSEARCH}" --fastq_chars  "${ALL_IDENTICAL}" --maxseqlength 2 2> "${OUTPUT}"
#NB_OF_SEQ_READ=$(awk 'NR==5 {print $2}' "${OUTPUT}")
#    [[ "${NB_OF_SEQ_READ}" == 2 ]] && \
#    success "${DESCRIPTION}" || \
#	failure "${DESCRIPTION}"

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
printf '@a\nAAAA\n+\naaaa\n' | \
    "${VSEARCH}" --fastq_chars - --quiet 2> "${OUTPUT}"
COUNT=$(wc -l < "${OUTPUT}")
[[ "${COUNT}" = "12" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

rm "${ALL_IDENTICAL}"
exit 0
