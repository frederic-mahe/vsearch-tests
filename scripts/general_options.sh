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

## Creating a bzip2 file
## We write in tmp file that we then zip and erase
## Then we create a handle for the compressed file created
BZIP2_FILE=$(mktemp)
for ((i=1 ; i<=100 ; i++)) ; do
    printf ">%s%d\nAAGG\n+\nAAGG\n" "seq" ${i}
done > "${BZIP2_FILE}"
bzip2 "${BZIP2_FILE}" -c > BZIP2_FILE_NAME
rm "${BZIP2_FILE}"
BZIP2_FILE=BZIP2_FILE_NAME

## --bzip2 is accepted
#DESCRIPTION="--bzip2 is accepted"
#printf "${BZIP2_FILE}" | \
#"${VSEARCH}" --fastq_chars - --bzip2_decompress &> /dev/null && \
#    success "${DESCRIPTION}" || \
#       failure "${DESCRIPTION}"

## Removing bzip2 file
rm "${BZIP2_FILE}"

#*****************************************************************************#
#                                                                             #
#                         Options --bzip2_decompress                          #
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

## Creating a gzip file
## We write in tmp file that we then zip and erase
## Then we create a handle for the compressed file created
GZIP_FILE=$(mktemp)
for ((i=1 ; i<=100 ; i++)) ; do
    printf ">%s%d\nAAGG\n+\nAAGG\n" "seq" ${i}
done > "${GZIP_FILE}"
gzip "${GZIP_FILE}" -c > GZIP_FILE_NAME
rm "${GZIP_FILE}"
GZIP_FILE=GZIP_FILE_NAME

## --gzip is accepted
DESCRIPTION="--gzip is accepted"
printf "${GZIP_FILE}" | \
"${VSEARCH}" --fastq_chars - --gzip_decompress &> /dev/null && \
    success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"

## Removing gzip file
rm "${GZIP_FILE}"


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

exit 0
