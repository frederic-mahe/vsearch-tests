#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastx_syncpairs"
LINE=$(printf "%76s\n" " " | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "%bFAIL%b: %s\n" "${RED}" "${NO_COLOR}" "${1}"
    exit 1
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
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------- option is valid

DESCRIPTION="--fastx_syncpairs is a valid command"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- reverse

DESCRIPTION="--fastx_syncpairs requires --reverse"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------- mandatory output file

DESCRIPTION="--fastx_syncpairs requires an output file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout as the only output (fastq in)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastaout as the only output (fastq in)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastaout_rev as the only output"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout_rev /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout_rev as the only output (fastq in)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout_rev /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                          input and output formats                           #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs accepts fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf ">s\nA\n") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs fastqout requires fastq input (fasta in)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf ">s\nA\n") \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs rejects a mix of fasta forward and fastq reverse"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs rejects a mix of fastq forward and fasta reverse"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf ">s\nA\n") \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs writes fasta output from fastq input (drops quality)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs writes fastq output from fastq input"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs errors if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"  # remove write permission
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout "${TMP}" 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_syncpairs accepts empty input (both forward and reverse)"
printf "" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                          synchronization behaviour                          #
#                                                                             #
#*****************************************************************************#

## The forward file gives the output order. Forward holds a then b, the
## reverse file holds b then a; the synced reverse reads must come out in
## the forward order (a's mate, then b's mate).

DESCRIPTION="--fastx_syncpairs emits synced forward reads in forward order"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@b 2:N:0:1\nTT\n+\nII\n@a 2:N:0:1\nGG\n+\nII\n") \
        --fastaout - 2> /dev/null | \
    grep "^>" | \
    tr -d '\n' | \
    grep -q ">a 1:N:0:1>b 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs reorders the reverse reads to match the forward order"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@b 2:N:0:1\nTT\n+\nII\n@a 2:N:0:1\nGG\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_rev - 2> /dev/null | \
    grep -v "^>" | \
    tr -d '\n' | \
    grep -qx "GGTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs discards orphans by default (forward-only read absent)"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout - 2> /dev/null | \
    grep -q "^>b" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs synchronizes the shared read despite an orphan"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout - 2> /dev/null | \
    grep -qx ">a 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               orphan outputs                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs writes forward orphans to --fastaout_orphans"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -qx ">b 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs writes reverse orphans to --fastaout_orphans_rev"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n@d 2:N:0:1\nGG\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans_rev - 2> /dev/null | \
    grep -qx ">d 2:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout_orphans (fastq in)"
printf "@a 1:N:0:1\nAA\n+\nII\n@b 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastqout /dev/null \
        --fastqout_orphans - 2> /dev/null | \
    grep -qx "@b 1:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs accepts --fastqout_orphans_rev (fastq in)"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n@d 2:N:0:1\nGG\n+\nII\n") \
        --fastqout /dev/null \
        --fastqout_orphans_rev - 2> /dev/null | \
    grep -qx "@d 2:N:0:1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               mate matching                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs matches Casava 1.8+ headers (differ after a space)"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs matches old /1 and /2 headers by default"
printf "@a/1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a/2\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --read_separators is accepted"
printf "@a_1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a_2\nTT\n+\nII\n") \
        --read_separators "_" \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --read_separators matches a custom separator"
printf "@a_1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a_2\nTT\n+\nII\n") \
        --read_separators "_" \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs treats /1 /2 as orphans when separator excluded"
printf "@a/1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a/2\nTT\n+\nII\n") \
        --read_separators "_" \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -qx ">a/1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             duplicate labels                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs rejects duplicate labels in the reverse file"
printf "@a 1:N:0:1\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n@a 2:N:0:1\nGG\n+\nII\n") \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs rejects duplicate labels in the forward file"
printf "@a 1:N:0:1\nAA\n+\nII\n@a 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@a 2:N:0:1\nTT\n+\nII\n") \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## duplicate forward labels are only rejected when they create an
## ambiguous pairing; two forward orphans sharing a label are harmless
## and are written out unchanged
DESCRIPTION="--fastx_syncpairs keeps duplicate forward orphans (no shared mate)"
printf "@a 1:N:0:1\nAA\n+\nII\n@a 1:N:0:1\nCC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@z 2:N:0:1\nTT\n+\nII\n") \
        --fastaout /dev/null \
        --fastaout_orphans - 2> /dev/null | \
    grep -c "^>a" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              secondary options                              #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs --fasta_width wraps fasta output"
printf "@s\nAAAAAA\n+\nIIIIII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nAAAAAA\n+\nIIIIII\n") \
        --fasta_width 3 \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {next} {if (length($0) > 3) exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --fastq_ascii 64 is accepted"
printf "@s\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nh\n") \
        --fastq_ascii 64 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## quality scores are not inspected, so --fastq_qmax is accepted but
## ignored: a quality higher than the given limit is not rejected
DESCRIPTION="--fastx_syncpairs --fastq_qmax is accepted but ignored"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmax 0 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --fastq_qmax does not corrupt the output"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nACGT\n+\nIIII\n") \
        --fastq_qmax 0 \
        --fastqout - 2> /dev/null | \
    tr '\n' ' ' | \
    grep -qx "@s ACGT + IIII " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --fastq_qmin is accepted but ignored"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 41 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_syncpairs --gzip_decompress reads gzip-compressed input"
REV=$(mktemp)
printf "@s\nA\n+\nI\n" | gzip > "${REV}"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --gzip_decompress \
        --reverse "${REV}" \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${REV}"
unset REV

DESCRIPTION="--fastx_syncpairs --bzip2_decompress reads bzip2-compressed input"
REV=$(mktemp)
printf "@s\nA\n+\nI\n" | bzip2 > "${REV}"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --bzip2_decompress \
        --reverse "${REV}" \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${REV}"
unset REV

DESCRIPTION="--fastx_syncpairs --log writes a log file"
LOG=$(mktemp)
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null \
        --log "${LOG}" 2> /dev/null
[[ -s "${LOG}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${LOG}"
unset LOG

DESCRIPTION="--fastx_syncpairs --quiet runs silently on stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_syncpairs rejects an unrelated option (--join_padgap)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_syncpairs - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null \
        --join_padgap NNN 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


exit 0
