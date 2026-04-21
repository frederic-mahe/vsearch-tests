#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastx_filter"
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

## vsearch --fastx_filter inputfile [--reverse inputfile] (--fastaout
## | --fastaout_discarded | --fastqout | --fastqout_discarded
## --fastaout_rev | --fastaout_discarded_rev | --fastqout_rev |
## --fastqout_discarded_rev) outputfile [options]

DESCRIPTION="--fastx_filter is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter reads from stdin (-)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter reads from a regular file"
TMP=$(mktemp)
printf ">s1\nA\n" > "${TMP}"
"${VSEARCH}" \
    --fastx_filter "${TMP}" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_filter fails if input file does not exist"
"${VSEARCH}" \
    --fastx_filter /no/such/file \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter fails if input file is not readable"
TMP=$(mktemp)
printf ">s1\nA\n" > "${TMP}"
chmod u-r "${TMP}"
"${VSEARCH}" \
    --fastx_filter "${TMP}" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastx_filter accepts fasta input"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter accepts fastq input"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter fails with input that is not FASTA or FASTQ"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter fails without any output option"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## each of the four output options (fasta-compatible) is accepted
## as sole output option for fasta input
for OPT in --fastaout --fastaout_discarded ; do
    DESCRIPTION="--fastx_filter accepts ${OPT} as sole output option (fasta input)"
    printf ">s1\nA\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            "${OPT}" /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

## fastq-compatible output options are accepted with fastq input
for OPT in --fastaout --fastaout_discarded --fastqout --fastqout_discarded ; do
    DESCRIPTION="--fastx_filter accepts ${OPT} as sole output option (fastq input)"
    printf "@s1\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            "${OPT}" /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## Format is auto-detected.
DESCRIPTION="--fastx_filter: fasta input is auto-detected"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter: fastq input is auto-detected"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Without filters, all sequences pass through unchanged.
DESCRIPTION="--fastx_filter: fasta input without filter is passed through unchanged"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter: fastq input without filter is passed through unchanged"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==4' | \
    grep -qx "IIII" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Fastq input can be converted to fasta.
DESCRIPTION="--fastx_filter: fastq input can be written to --fastaout"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Fasta input cannot be written to --fastqout (quality scores missing).
DESCRIPTION="--fastx_filter: --fastqout rejects fasta input"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## Default minimum length is 1.
DESCRIPTION="--fastx_filter: default fastq_minlen is 1 (empty fasta sequence is discarded)"
printf ">s1\n\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ---------- trimming ----------

## --fastq_stripleft: applies to both fasta and fastq input
DESCRIPTION="--fastx_filter --fastq_stripleft is accepted (fastq input)"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_stripleft is accepted (fasta input)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 1 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_stripleft removes bases from the 5' end (fasta)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripleft 2 \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "GT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_stripright
DESCRIPTION="--fastx_filter --fastq_stripright removes bases from the 3' end (fasta)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripright 2 \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_stripright discards reads reduced to zero length"
printf ">s1\nAC\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_stripright 2 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_truncee (requires quality; rejected with fasta input)
DESCRIPTION="--fastx_filter --fastq_truncee is accepted (fastq input)"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee 1.0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_truncee rejects fasta input"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee 1.0 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_truncee truncates at the first EE-exceeding position"
printf "@s1\nACGT\n+\nII!!\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee 0.5 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_truncee_rate
DESCRIPTION="--fastx_filter --fastq_truncee_rate is accepted (fastq input)"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 0.01 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_truncee_rate rejects fasta input"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncee_rate 0.01 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_trunclen
DESCRIPTION="--fastx_filter --fastq_trunclen truncates reads (fasta)"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_trunclen 2 \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_trunclen discards reads shorter than the threshold"
printf ">s1\nAC\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_trunclen 4 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_trunclen_keep
DESCRIPTION="--fastx_filter --fastq_trunclen_keep keeps reads shorter than the threshold"
printf ">s1\nAC\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_trunclen_keep 4 \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_truncqual
DESCRIPTION="--fastx_filter --fastq_truncqual truncates at the first low-quality base"
printf "@s1\nACGT\n+\nII!!\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_truncqual 1 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- filtering ----------

## --fastq_maxee (requires quality; rejected with fasta input)
DESCRIPTION="--fastx_filter --fastq_maxee discards reads above the threshold"
printf "@s1\nACGT\n+\n!!!!\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_maxee 0.5 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxee rejects fasta input"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_maxee 1.0 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_maxee_rate
DESCRIPTION="--fastx_filter --fastq_maxee_rate rejects fasta input"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_maxee_rate 0.1 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_maxlen (applies to both fasta and fastq)
DESCRIPTION="--fastx_filter --fastq_maxlen keeps sequences of exactly that length"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_maxlen 4 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxlen discards longer sequences"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_maxlen 3 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_maxns
DESCRIPTION="--fastx_filter --fastq_maxns 0 discards reads containing any N (fasta)"
printf ">s1\nANCG\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_maxns 0 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxns keeps reads with at most that many Ns"
printf ">s1\nANNG\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_maxns 2 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_minlen
DESCRIPTION="--fastx_filter --fastq_minlen discards shorter sequences (fasta)"
printf ">s1\nAC\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minlen 3 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_minlen keeps sequences of exactly that length"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minlen 4 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_minqual (requires quality; rejected with fasta input)
DESCRIPTION="--fastx_filter --fastq_minqual discards reads containing a lower-quality base"
printf "@s1\nACGT\n+\nIII!\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 1 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_minqual rejects fasta input"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minqual 1 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --maxsize / --minsize
DESCRIPTION="--fastx_filter --minsize discards sequences with a smaller abundance"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sizein \
        --minsize 5 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --maxsize discards sequences with a larger abundance"
printf ">s1;size=10\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sizein \
        --maxsize 5 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------- output ----------

## --fastaout_discarded (applies to any input)
DESCRIPTION="--fastx_filter --fastaout_discarded receives discarded sequences"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minlen 2 \
        --fastaout_discarded - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastqout_discarded (rejected with fasta input)
DESCRIPTION="--fastx_filter --fastqout_discarded rejects fasta input"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastqout_discarded /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastqout_discarded receives discarded sequences (fastq)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_minlen 2 \
        --fastqout_discarded - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --reverse: pairs are kept together
DESCRIPTION="--fastx_filter --reverse is accepted"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf "@s1\nA\n+\nI\n" > "${FORWARD}"
printf "@s1\nT\n+\nI\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastx_filter "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastqout /dev/null \
    --fastqout_rev /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE

DESCRIPTION="--fastx_filter: if one mate fails, both reads of the pair are discarded"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf "@r1\nACGT\n+\n!!!!\n" > "${FORWARD}"
printf "@r1\nACGT\n+\nIIII\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastx_filter "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastq_maxee 0.01 \
    --fastqout /dev/null \
    --fastqout_rev - \
    --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE

DESCRIPTION="--fastx_filter --reverse fails if reverse file does not exist"
FORWARD=$(mktemp)
printf "@s1\nA\n+\nI\n" > "${FORWARD}"
"${VSEARCH}" \
    --fastx_filter "${FORWARD}" \
    --reverse /no/such/file \
    --fastqout /dev/null \
    --fastqout_rev /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${FORWARD}"
unset FORWARD

DESCRIPTION="--fastx_filter --fastaout_rev is accepted with --reverse"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf ">s1\nA\n" > "${FORWARD}"
printf ">s1\nT\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastx_filter "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastaout /dev/null \
    --fastaout_rev /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE

DESCRIPTION="--fastx_filter --fastaout_discarded_rev is accepted with --reverse"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf ">s1\nA\n" > "${FORWARD}"
printf ">s1\nT\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastx_filter "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastaout /dev/null \
    --fastaout_discarded_rev /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE

## --eeout / --fastq_eeout (synonyms; require quality)
DESCRIPTION="--fastx_filter --eeout adds ;ee= annotation to fastq output"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --eeout \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qE "^@s1;ee=[0-9.]+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --eeout rejects fasta input"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --eeout \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_eeout rejects fasta input"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_eeout \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --sizein / --sizeout
DESCRIPTION="--fastx_filter --sizein --sizeout preserves the abundance annotation"
printf ">s1;size=5\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sizein \
        --sizeout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --sizeout without --sizein sets size=1"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sizeout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --bzip2_decompress
DESCRIPTION="--fastx_filter --bzip2_decompress reads a bzip2-compressed stream"
printf ">s1\nA\n" | bzip2 | \
    "${VSEARCH}" \
        --fastx_filter - \
        --bzip2_decompress \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --gzip_decompress
DESCRIPTION="--fastx_filter --gzip_decompress reads a gzip-compressed stream"
printf ">s1\nA\n" | gzip | \
    "${VSEARCH}" \
        --fastx_filter - \
        --gzip_decompress \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fasta_width
DESCRIPTION="--fastx_filter --fasta_width folds long sequences in fasta output"
printf ">s1\nACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fasta_width 4 \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fasta_width 0 suppresses folding"
printf ">s1\nACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fasta_width 0 \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGTACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_ascii
DESCRIPTION="--fastx_filter --fastq_ascii 33 is accepted (fastq input)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_ascii 33 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_ascii 64 is accepted (fastq input)"
printf "@s1\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_ascii 64 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_ascii rejects values other than 33 or 64"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_ascii 50 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_qmax
DESCRIPTION="--fastx_filter --fastq_qmax fails when a quality is above it"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_qmax 0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_qmin
DESCRIPTION="--fastx_filter --fastq_qmin fails when a quality is below it"
printf "@s1\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_qmin 1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --label_suffix
DESCRIPTION="--fastx_filter --label_suffix appends a suffix to the header"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --label_suffix ";tag=x" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;tag=x" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --lengthout
DESCRIPTION="--fastx_filter --lengthout adds a ;length= annotation"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --lengthout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --log
DESCRIPTION="--fastx_filter --log writes a non-empty log file"
TMP=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null \
        --log "${TMP}" 2> /dev/null
[[ -s "${TMP}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

## --no_progress
DESCRIPTION="--fastx_filter --no_progress is accepted"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --no_progress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notrunclabels
DESCRIPTION="--fastx_filter --notrunclabels retains full header (fasta)"
printf ">s1 suffix\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --notrunclabels \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1 suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --quiet
DESCRIPTION="--fastx_filter --quiet silences stderr messages"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --relabel
DESCRIPTION="--fastx_filter --relabel replaces headers with a prefix + ticker"
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --relabel "new:" \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk '/^>/' | \
    tr "\n" " " | \
    grep -qx ">new:1 >new:2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_keep
DESCRIPTION="--fastx_filter --relabel --relabel_keep retains old identifier"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --relabel "new:" \
        --relabel_keep \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">new:1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_md5
DESCRIPTION="--fastx_filter --relabel_md5 replaces header with an MD5 digest"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --relabel_md5 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_self
DESCRIPTION="--fastx_filter --relabel_self replaces header with the sequence"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --relabel_self \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_sha1
DESCRIPTION="--fastx_filter --relabel_sha1 replaces header with a SHA1 digest"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --relabel_sha1 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sample
DESCRIPTION="--fastx_filter --sample appends ;sample= to the header"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sample "abc" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;sample=abc" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xee
DESCRIPTION="--fastx_filter --xee strips an ee= annotation"
printf ">s1;ee=0.1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --xee \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xlength
DESCRIPTION="--fastx_filter --xlength strips a length= annotation"
printf ">s1;length=1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --xlength \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xsize
DESCRIPTION="--fastx_filter --xsize strips a size= annotation"
printf ">s1;size=3\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --xsize \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## option interactions
DESCRIPTION="--fastx_filter --sizeout --relabel preserves abundance after relabeling"
printf ">s1;size=5\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sizein \
        --sizeout \
        --relabel "new:" \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">new:1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --label_suffix --lengthout applies both to the header"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --label_suffix ";tag=x" \
        --lengthout \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;tag=x;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## --threads: command is not multithreaded; option has no effect
DESCRIPTION="--fastx_filter --threads is accepted (option has no effect)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --threads 2 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## combining mutually exclusive relabel options must fail
DESCRIPTION="--fastx_filter rejects --relabel combined with --relabel_md5"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --relabel X \
        --relabel_md5 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter rejects --relabel_md5 combined with --relabel_sha1"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --relabel_md5 \
        --relabel_sha1 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## options that belong to other commands
DESCRIPTION="--fastx_filter rejects --label (belongs to fastx_getseq)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --label "s1" \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter rejects --subseq_start (belongs to fastx_getsubseq)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --subseq_start 1 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    LOG=$(mktemp)
    FORWARD=$(mktemp)
    REVERSE=$(mktemp)
    printf "@s\nA\n+\nI\n" > "${FORWARD}"
    printf "@s\nT\n+\nI\n" > "${REVERSE}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastx_filter "${FORWARD}" \
        --reverse "${REVERSE}" \
        --fastaout /dev/null \
        --fastaout_discarded /dev/null \
        --fastqout /dev/null \
        --fastqout_discarded /dev/null \
        --fastaout_rev /dev/null \
        --fastaout_discarded_rev /dev/null \
        --fastqout_rev /dev/null \
        --fastqout_discarded_rev /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastx_filter valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_filter valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FORWARD}" "${REVERSE}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
