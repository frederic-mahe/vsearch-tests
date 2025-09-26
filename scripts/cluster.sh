#!/bin/bash -

## Print a header
SCRIPT_NAME="Test clustering options"
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


#*****************************************************************************#
#                                                                             #
#                             --cluster_fast                                  #
#                                                                             #
#*****************************************************************************#

## lots of basic tests missing here...

## --cluster_fast --clusters accepts filename '-'
DESCRIPTION="--cluster_fast --clusters accepts filename '-'"
printf ">s\nA\n" | \
    "${VSEARCH}" --cluster_fast - --id 1 --clusters - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --cluster_fast --clusters fails if filename is missing
DESCRIPTION="--cluster_fast --clusters fails if filename is missing"
printf ">s\nA\n" | \
    "${VSEARCH}" --cluster_fast - --id 1 --clusters > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --cluster_fast --clusters fails with an error message if filename is missing
DESCRIPTION="--cluster_fast --clusters fails with an error message if filename is missing"
printf ">s\nA\n" | \
    "${VSEARCH}" --cluster_fast - --id 1 --clusters 2>&1 > /dev/null | \
    grep -q "vsearch: option '--clusters' requires an argument" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --cluster_fast warns if input sequences contain non-DNA letters
DESCRIPTION="--cluster_fast warns if input sequences contain non-DNA letters"
printf ">s\nMALIPD\n" | \
    "${VSEARCH}" --cluster_fast - --id 1 --clusters - 2>&1 > /dev/null | \
    grep -q "WARNING: 3 invalid characters stripped from FASTA file" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# TODO:
# - use the same prefix for warnings (mix of WARNING: or vsearch:)

exit 0
