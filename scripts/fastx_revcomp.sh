#!/bin/bash -

## Print a header
SCRIPT_NAME="fastx_revcomp"
LINE=$(printf "%76s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    exit 1
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
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## vsearch --fastx_revcomp inputfile (--fastaout | --fastqout) outputfile [options]


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

# none

#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    LOG=$(mktemp)
    FASTQ=$(mktemp)
    printf "@s\nAAAAAA\n+\nIIIIII\n" > "${FASTQ}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastx_revcomp "${FASTQ}" \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastx_revcomp valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_revcomp valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTQ}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0


#*****************************************************************************#
#                                                                             #
#                                  Arguments                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_revcomp command is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastqout /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp accepts a fastq file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastqout /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp accepts a fasta file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastaout /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp fastq in, fastq out"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastqout - | \
    grep -qw "@s" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp fastq in, fasta out"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastaout - | \
    grep -qw ">s" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp fasta in, fasta out"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastaout - | \
    grep -qw ">s" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp fasta in, fastq out (not possible, fatal error)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastqout - > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp fastq in, fastq out, rev-comp nucleotides"
for NUC in A C G T N ; do
    printf "@s\n%s\n+\nI\n" ${NUC} | \
        "${VSEARCH}" \
            --fastx_revcomp - \
            --quiet \
            --fastqout - 2> /dev/null | \
        grep -qw "$(tr "ACGTN" "TGCAN" <<< "${NUC}")" || \
            failure "${DESCRIPTION}"
done && success "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp fastq in, fasta out, rev-comp nucleotides"
for NUC in A C G T N ; do
    printf "@s\n%s\n+\nI\n" ${NUC} | \
        "${VSEARCH}" \
            --fastx_revcomp - \
            --quiet \
            --fastaout - 2> /dev/null | \
        grep -qw "$(tr "ACGTN" "TGCAN" <<< "${NUC}")" || \
            failure "${DESCRIPTION}"
done && success "${DESCRIPTION}"

DESCRIPTION="--fastx_revcomp fasta in, fasta out, rev-comp nucleotides"
for NUC in A C G T N ; do
    printf ">s\n%s\n" ${NUC} | \
        "${VSEARCH}" \
            --fastx_revcomp - \
            --quiet \
            --fastaout - 2> /dev/null | \
        grep -qw "$(tr "ACGTN" "TGCAN" <<< "${NUC}")" || \
            failure "${DESCRIPTION}"
done && success "${DESCRIPTION}"

DESCRIPTION="--fastq_revcomp fastq in, fastq out (more complex)"
printf "@s\nGTCA\n+\nFGHI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastqout - 2> /dev/null | \
    tr "\n" " " | \
    grep -qw "@s TGAC + IHGF" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_revcomp fastq in, fasta out (more complex)"
printf "@s\nGTCA\n+\nFGHI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastaout - 2> /dev/null | \
    tr "\n" " " | \
    grep -qw ">s TGAC" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_revcomp fasta in, fasta out (more complex)"
printf ">s\nGTCA\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --quiet \
        --fastaout - 2> /dev/null | \
    tr "\n" " " | \
    grep -qw ">s TGAC" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --label_suffix string
#   When using --fastx_revcomp or --fastq_mergepairs, add the suffix
#   string to sequence headers.

DESCRIPTION="--fastq_revcomp label_suffix option"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_revcomp - \
        --label_suffix "_suffix" \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qw "@s_suffix" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Reverse complementation
#   --fastx_revcomp FILENAME    Reverse-complement seqs in FASTA or FASTQ file
#  Parameters
#   --fastq_ascii INT           FASTQ input quality score ASCII base char (33)
#   --fastq_qmax INT            maximum base quality value for FASTQ input (41)
#   --fastq_qmin INT            minimum base quality value for FASTQ input (0)
#  Output
#   --fastaout FILENAME         FASTA output filename
#   --fastqout FILENAME         FASTQ output filename
#   --label_suffix STRING       Label to append to identifier in the output

exit 0
