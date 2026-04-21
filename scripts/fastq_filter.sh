#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastq_filter"
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

## vsearch --fastq_filter fastqfile [--reverse fastqfile] (--fastaout
## | --fastaout_discarded | --fastqout | --fastqout_discarded
## --fastaout_rev | --fastaout_discarded_rev | --fastqout_rev |
## --fastqout_discarded_rev) outputfile [options]

DESCRIPTION="--fastq_filter is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter reads from stdin (-)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter reads from a regular file"
TMP=$(mktemp)
printf "@s1\nA\n+\nI\n" > "${TMP}"
"${VSEARCH}" \
    --fastq_filter "${TMP}" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastq_filter fails if input file does not exist"
"${VSEARCH}" \
    --fastq_filter /no/such/file \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter fails if input file is not readable"
TMP=$(mktemp)
printf "@s1\nA\n+\nI\n" > "${TMP}"
chmod u-r "${TMP}"
"${VSEARCH}" \
    --fastq_filter "${TMP}" \
    --fastaout /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastq_filter rejects fasta input"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter fails with input that is not FASTA or FASTQ"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter fails without any output option"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## at least one output option must be specified: each should be
## accepted as a sole output.
for OPT in --fastaout --fastaout_discarded --fastqout --fastqout_discarded ; do
    DESCRIPTION="--fastq_filter accepts ${OPT} as sole output option"
    printf "@s1\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastq_filter - \
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

## When no trimming/filtering options are given, all sequences are
## written to --fastqout unchanged.
DESCRIPTION="--fastq_filter: without filters, all sequences are kept (fastqout)"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter: kept sequence in fastqout preserves bases"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter: kept sequence in fastqout preserves quality"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==4' | \
    grep -qx "IIII" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Output may be written in fasta format (quality scores are dropped).
DESCRIPTION="--fastq_filter: --fastaout converts fastq input to fasta"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## The default minimum length is 1, so an empty sequence is discarded.
DESCRIPTION="--fastq_filter: default fastq_minlen is 1 (empty sequence is discarded)"
printf "@s1\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastqout - \
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

## --fastq_stripleft
DESCRIPTION="--fastq_filter --fastq_stripleft is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_stripleft 1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_stripleft removes bases from the 5' end"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_stripleft 2 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "GT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_stripleft trims quality accordingly"
printf "@s1\nACGT\n+\n!I!I\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_stripleft 2 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==4' | \
    grep -qx "!I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_stripleft discards reads reduced to zero length"
printf "@s1\nAC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_stripleft 2 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_stripleft rejects a negative value"
printf "@s1\nAC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_stripleft -1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_stripright
DESCRIPTION="--fastq_filter --fastq_stripright is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_stripright 1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_stripright removes bases from the 3' end"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_stripright 2 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_stripright discards reads reduced to zero length"
printf "@s1\nAC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_stripright 2 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_truncee
DESCRIPTION="--fastq_filter --fastq_truncee is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee 1.0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_truncee truncates at the first EE-exceeding position"
printf "@s1\nACGT\n+\nII!!\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee 0.5 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_truncee 0 truncates to zero length (discarded by default minlen)"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee 0 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_truncee_rate
DESCRIPTION="--fastq_filter --fastq_truncee_rate is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncee_rate 0.01 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_trunclen
DESCRIPTION="--fastq_filter --fastq_trunclen is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen 2 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_trunclen truncates reads to the given length"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen 2 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_trunclen discards reads shorter than the given length"
printf "@s1\nAC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen 4 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_trunclen_keep
DESCRIPTION="--fastq_filter --fastq_trunclen_keep is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen_keep 2 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_trunclen_keep truncates reads to the given length"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen_keep 2 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_trunclen_keep keeps reads shorter than the given length"
printf "@s1\nAC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen_keep 4 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_truncqual
DESCRIPTION="--fastq_filter --fastq_truncqual is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncqual 1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_truncqual truncates at the first low-quality base"
printf "@s1\nACGT\n+\nII!!\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_truncqual 1 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- filtering ----------

## --fastq_maxee
DESCRIPTION="--fastq_filter --fastq_maxee is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxee 1.0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxee keeps reads below the threshold"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxee 1.0 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxee discards reads above the threshold"
printf "@s1\nACGT\n+\n!!!!\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxee 0.5 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_maxee_rate
DESCRIPTION="--fastq_filter --fastq_maxee_rate is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxee_rate 0.1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxee_rate discards reads with a rate above the threshold"
printf "@s1\nACGT\n+\n!!!!\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxee_rate 0.1 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_maxlen
DESCRIPTION="--fastq_filter --fastq_maxlen is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxlen 10 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxlen keeps sequences of exactly that length"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxlen 4 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxlen discards longer sequences"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxlen 3 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_maxns
DESCRIPTION="--fastq_filter --fastq_maxns is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxns 0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxns 0 discards reads containing any N"
printf "@s1\nANCG\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxns 0 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxns keeps reads with at most that many Ns"
printf "@s1\nANNG\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_maxns 2 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_minlen
DESCRIPTION="--fastq_filter --fastq_minlen is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minlen 2 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minlen keeps sequences of exactly that length"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minlen 4 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minlen discards shorter sequences"
printf "@s1\nAC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minlen 3 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_minqual
DESCRIPTION="--fastq_filter --fastq_minqual is accepted"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minqual discards reads containing a lower-quality base"
printf "@s1\nACGT\n+\nIII!\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 1 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minqual keeps reads whose minimum quality is at the threshold"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minqual 40 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --maxsize / --minsize (work together with --sizein)
DESCRIPTION="--fastq_filter --minsize is accepted"
printf "@s1;size=5\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --sizein \
        --minsize 1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --minsize discards sequences with a smaller abundance"
printf "@s1;size=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --sizein \
        --minsize 5 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --maxsize is accepted"
printf "@s1;size=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --sizein \
        --maxsize 5 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --maxsize discards sequences with a larger abundance"
printf "@s1;size=10\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --sizein \
        --maxsize 5 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------- output ----------

## --fastaout_discarded
DESCRIPTION="--fastq_filter --fastaout_discarded receives discarded sequences (fasta)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minlen 2 \
        --fastaout_discarded - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastqout_discarded
DESCRIPTION="--fastq_filter --fastqout_discarded receives discarded sequences (fastq)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minlen 2 \
        --fastqout_discarded - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastaout / --fastqout (both kept and discarded written to separate streams)
DESCRIPTION="--fastq_filter: fastqout receives only passing sequences"
printf "@s1\nA\n+\nI\n@s2\nAC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minlen 2 \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk '/^@/' | \
    grep -qx "@s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --reverse: pairs are kept together
DESCRIPTION="--fastq_filter --reverse is accepted"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf "@s1\nA\n+\nI\n" > "${FORWARD}"
printf "@s1\nT\n+\nI\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastq_filter "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastqout /dev/null \
    --fastqout_rev /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE

DESCRIPTION="--fastq_filter: if forward read fails, both reads of the pair are discarded"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf "@r1\nACGT\n+\n!!!!\n" > "${FORWARD}"
printf "@r1\nACGT\n+\nIIII\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastq_filter "${FORWARD}" \
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

DESCRIPTION="--fastq_filter: if both reads pass, both are kept"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf "@r1\nACGT\n+\nIIII\n" > "${FORWARD}"
printf "@r1\nACGT\n+\nIIII\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastq_filter "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastq_maxee 1.0 \
    --fastqout /dev/null \
    --fastqout_rev - \
    --quiet 2> /dev/null | \
    grep -qx "@r1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE

DESCRIPTION="--fastq_filter --reverse fails if reverse file does not exist"
FORWARD=$(mktemp)
printf "@s1\nA\n+\nI\n" > "${FORWARD}"
"${VSEARCH}" \
    --fastq_filter "${FORWARD}" \
    --reverse /no/such/file \
    --fastqout /dev/null \
    --fastqout_rev /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${FORWARD}"
unset FORWARD

## --fastaout_rev, --fastqout_rev, --fastaout_discarded_rev, --fastqout_discarded_rev
## are accepted when --reverse is provided.
DESCRIPTION="--fastq_filter --fastaout_rev is accepted with --reverse"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf "@s1\nA\n+\nI\n" > "${FORWARD}"
printf "@s1\nT\n+\nI\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastq_filter "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastaout /dev/null \
    --fastaout_rev /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE

DESCRIPTION="--fastq_filter --fastaout_discarded_rev is accepted with --reverse"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf "@s1\nA\n+\nI\n" > "${FORWARD}"
printf "@s1\nT\n+\nI\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastq_filter "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastaout /dev/null \
    --fastaout_discarded_rev /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE

DESCRIPTION="--fastq_filter --fastqout_discarded_rev is accepted with --reverse"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf "@s1\nA\n+\nI\n" > "${FORWARD}"
printf "@s1\nT\n+\nI\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastq_filter "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastqout /dev/null \
    --fastqout_discarded_rev /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE

## --eeout / --fastq_eeout (synonyms)
DESCRIPTION="--fastq_filter --eeout adds ;ee= annotation"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --eeout \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qE "^@s1;ee=[0-9.]+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_eeout adds ;ee= annotation"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_eeout \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qE "^@s1;ee=[0-9.]+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizein / --sizeout
DESCRIPTION="--fastq_filter --sizein --sizeout preserves the abundance annotation"
printf "@s1;size=5\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --sizein \
        --sizeout \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --sizeout without --sizein sets size=1"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --sizeout \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --bzip2_decompress
DESCRIPTION="--fastq_filter --bzip2_decompress reads a bzip2-compressed stream"
printf "@s1\nA\n+\nI\n" | bzip2 | \
    "${VSEARCH}" \
        --fastq_filter - \
        --bzip2_decompress \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --gzip_decompress
DESCRIPTION="--fastq_filter --gzip_decompress reads a gzip-compressed stream"
printf "@s1\nA\n+\nI\n" | gzip | \
    "${VSEARCH}" \
        --fastq_filter - \
        --gzip_decompress \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fasta_width
DESCRIPTION="--fastq_filter --fasta_width is accepted"
printf "@s1\nACGTACGT\n+\nIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fasta_width 4 \
        --fastaout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fasta_width folds long sequences in fasta output"
printf "@s1\nACGTACGT\n+\nIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fasta_width 4 \
        --fastaout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_ascii
DESCRIPTION="--fastq_filter --fastq_ascii 33 is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_ascii 33 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_ascii 64 is accepted"
printf "@s1\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_ascii 64 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_ascii rejects values other than 33 or 64"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_ascii 50 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_qmax
DESCRIPTION="--fastq_filter --fastq_qmax is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 41 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_qmax fails when a quality is above it"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_qmin
DESCRIPTION="--fastq_filter --fastq_qmin is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmin 0 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_qmin fails when a quality is below it"
printf "@s1\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmin 1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --label_suffix
DESCRIPTION="--fastq_filter --label_suffix appends a suffix to the header"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --label_suffix ";tag=x" \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1;tag=x" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --lengthout
DESCRIPTION="--fastq_filter --lengthout adds a ;length= annotation"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --lengthout \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --log
DESCRIPTION="--fastq_filter --log writes a non-empty log file"
TMP=$(mktemp)
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastqout /dev/null \
        --log "${TMP}" 2> /dev/null
[[ -s "${TMP}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

## --no_progress
DESCRIPTION="--fastq_filter --no_progress is accepted"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --no_progress \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --quiet
DESCRIPTION="--fastq_filter --quiet silences stderr messages"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastqout /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --relabel
DESCRIPTION="--fastq_filter --relabel replaces headers with a prefix + ticker"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --relabel "new:" \
        --fastqout - \
        --quiet 2> /dev/null | \
    awk '/^@/' | \
    tr "\n" " " | \
    grep -qx "@new:1 @new:2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_keep
DESCRIPTION="--fastq_filter --relabel --relabel_keep retains old identifier"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --relabel "new:" \
        --relabel_keep \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@new:1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_md5
DESCRIPTION="--fastq_filter --relabel_md5 replaces header with an MD5 digest"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --relabel_md5 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qE "^@[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_self
DESCRIPTION="--fastq_filter --relabel_self replaces header with the sequence"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --relabel_self \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel_sha1
DESCRIPTION="--fastq_filter --relabel_sha1 replaces header with a SHA1 digest"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --relabel_sha1 \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qE "^@[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sample
DESCRIPTION="--fastq_filter --sample appends ;sample= to the header"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --sample "abc" \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1;sample=abc" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xee
DESCRIPTION="--fastq_filter --xee strips an ee= annotation"
printf "@s1;ee=0.1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --xee \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xlength
DESCRIPTION="--fastq_filter --xlength strips a length= annotation"
printf "@s1;length=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --xlength \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --xsize
DESCRIPTION="--fastq_filter --xsize strips a size= annotation"
printf "@s1;size=3\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --xsize \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## option interactions
DESCRIPTION="--fastq_filter --sizeout --relabel preserves abundance after relabeling"
printf "@s1;size=5\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --sizein \
        --sizeout \
        --relabel "new:" \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@new:1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --label_suffix --lengthout applies both to the header"
printf "@s1\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --label_suffix ";tag=x" \
        --lengthout \
        --fastqout - \
        --quiet 2> /dev/null | \
    grep -qx "@s1;tag=x;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## --threads: command is not multithreaded; option has no effect
DESCRIPTION="--fastq_filter --threads is accepted (option has no effect)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --threads 2 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## combining mutually exclusive relabel options must fail
DESCRIPTION="--fastq_filter rejects --relabel combined with --relabel_md5"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --relabel X \
        --relabel_md5 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter rejects --relabel_md5 combined with --relabel_sha1"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --relabel_md5 \
        --relabel_sha1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## options that belong to other commands
DESCRIPTION="--fastq_filter rejects --label (belongs to fastx_getseq)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --label "s1" \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter rejects --subseq_start (belongs to fastx_getsubseq)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --subseq_start 1 \
        --fastqout /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter rejects --notrunclabels (fastq_filter does not truncate headers)"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --notrunclabels \
        --fastqout /dev/null \
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
        --fastq_filter "${FORWARD}" \
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
    DESCRIPTION="--fastq_filter valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastq_filter valgrind (no errors)"
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
