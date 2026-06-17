#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="Test clustering options"
LINE=$(printf "%76s\n" " " | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "%bFAIL%b: %s\n" "${RED}" "${NO_COLOR}" "${1}"
    # exit 1
}

success () {
    printf "%bPASS%b: %s\n" "${GREEN}" "${NO_COLOR}" "${1}"
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

## a sequence long enough to survive the default minimum length
SEQ="ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT"

## each output option fails if its target file cannot be opened for
## writing (write-protected file)
for OPT in --centroids --uc --alnout --samout --userout --blast6out \
           --matched --notmatched --otutabout --mothur_shared_out --biomout ; do
    DESCRIPTION="--cluster_fast ${OPT} fails if unable to open output file for writing"
    TMP=$(mktemp) && chmod u-w "${TMP}"  # remove write permission
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 0.97 \
            "${OPT}" "${TMP}" \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP
done
unset OPT

## --fastapairs, --qsegout and --tsegout cannot be used alone, so they
## are paired with a writable --alnout
for OPT in --fastapairs --qsegout --tsegout ; do
    DESCRIPTION="--cluster_fast ${OPT} fails if unable to open output file for writing"
    TMP=$(mktemp) && chmod u-w "${TMP}"  # remove write permission
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 0.97 \
            --alnout /dev/null \
            "${OPT}" "${TMP}" \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP
done
unset OPT

## --clusters takes a prefix and appends a number to it; it fails when
## the resulting file cannot be created (here the target directory does
## not exist)
DESCRIPTION="--cluster_fast --clusters fails if unable to open output file for writing"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --clusters ./nonexistent_directory/prefix \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --relabel_self relabels each centroid with its own sequence
## (--qmask none keeps the sequence uppercase, so it matches SEQ)
DESCRIPTION="--cluster_fast --relabel_self relabels centroids with their sequence"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --qmask none \
        --relabel_self \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_sha1 relabels each centroid with the SHA1 digest of its
## sequence
DESCRIPTION="--cluster_fast --relabel_sha1 relabels centroids with a SHA1 digest"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --relabel_sha1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qxE ">[0-9a-f]{40}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_md5 relabels each centroid with the MD5 digest of its
## sequence
DESCRIPTION="--cluster_fast --relabel_md5 relabels centroids with an MD5 digest"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --relabel_md5 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qxE ">[0-9a-f]{32}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## with no input sequences, the log reports zero clusters and zero
## singletons
DESCRIPTION="--cluster_fast reports zero clusters and singletons in the log for empty input"
LOG=$(mktemp)
printf "" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --centroids /dev/null \
        --log "${LOG}" \
        --quiet 2> /dev/null
grep -q "Clusters: 0" "${LOG}" && \
grep -q "Singletons: 0" "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${LOG}"
unset LOG

## --hardmask only acts on soft-masked (lowercase) regions, so it
## interacts with --qmask soft; the combination must be accepted
## (exercises the soft-mask hardmasking path for the database)
DESCRIPTION="--cluster_fast --qmask soft combined with --hardmask is accepted"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --qmask soft \
        --hardmask \
        --centroids /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset SEQ

# note: vsearch uses two distinct message prefixes, which is expected
# and not an inconsistency to fix here:
# - "vsearch: ..." is emitted by the command-line parser (getopt) for
#   argument-parsing errors (e.g. "vsearch: option '--clusters'
#   requires an argument"), following the usual program-name
#   convention.
# - "WARNING: ..." is emitted by vsearch itself for non-fatal runtime
#   warnings about the data (e.g. "WARNING: N invalid characters
#   stripped from FASTA file").
# Both prefixes are exercised by tests above.

exit 0
