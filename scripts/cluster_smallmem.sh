#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="cluster_smallmem"
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


# vsearch --cluster_smallmem fastafile --id real (--alnout | --biomout
# | --blast6out | --centroids | --clusters | --mothur_shared_out |
# --msaout | --otutabout | --profile | --samout | --uc | --userout)
# filename [options]


#*****************************************************************************#
#                                                                             #
#                             mandatory options                               #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--cluster_smallmem is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem reads from stdin (-)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem reads from a regular file"
TMP=$(mktemp)
printf ">s1\nAAAAAAAAAAAA\n" > "${TMP}"
"${VSEARCH}" \
    --cluster_smallmem "${TMP}" \
    --id 1.0 \
    --minseqlength 1 \
    --centroids /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--cluster_smallmem fails if input file does not exist"
"${VSEARCH}" \
    --cluster_smallmem /no/such/file \
    --id 1.0 \
    --minseqlength 1 \
    --centroids /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem fails if input file is not readable"
TMP=$(mktemp)
printf ">s1\nAAAAAAAAAAAA\n" > "${TMP}"
chmod u-r "${TMP}"
"${VSEARCH}" \
    --cluster_smallmem "${TMP}" \
    --id 1.0 \
    --minseqlength 1 \
    --centroids /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--cluster_smallmem accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem accepts fasta input"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem accepts fastq input"
printf "@s1\nAAAAAAAAAAAA\n+\nIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem rejects input that is not fasta or fastq"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem fails without --id"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem fails without any output option"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## Sequences must be sorted by decreasing length unless --usersort is given.
DESCRIPTION="--cluster_smallmem fails when input is not sorted by decreasing length"
printf ">s1\nAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --usersort allows any input order"
printf ">s1\nAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --usersort \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem accepts input sorted by decreasing length"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem accepts input of equal-length sequences"
printf ">a\nAAAAAAAAAAAA\n>b\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --id boundary values
for V in 0 0.5 1 ; do
    DESCRIPTION="--cluster_smallmem --id accepts value ${V}"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_smallmem --id rejects negative value"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id -0.1 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --id rejects value greater than 1.0"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.1 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## each listed output option accepted alone
for OPT in --alnout --biomout --blast6out --centroids --mothur_shared_out --msaout --otutabout --profile --samout --uc --userout ; do
    DESCRIPTION="--cluster_smallmem accepts ${OPT} as sole output option"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_smallmem accepts --clusters as sole output option"
PREFIX=$(mktemp -d)/c
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --clusters "${PREFIX}" \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -rf "$(dirname "${PREFIX}")"
unset PREFIX


#*****************************************************************************#
#                                                                             #
#                             default behaviour                               #
#                                                                             #
#*****************************************************************************#

## Sequences are processed in input order (no sorting step).
DESCRIPTION="--cluster_smallmem processes sequences in input order (first becomes centroid)"
printf ">first\nAAAAAAAAAAAA\n>second\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -qx ">first" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## With --usersort, first sequence is the centroid even when shorter.
DESCRIPTION="--cluster_smallmem --usersort first sequence becomes centroid"
printf ">short\nAAAAAAAAAAAA\n>long\nAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 0.5 \
        --usersort \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -qx ">short" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Default masking is dust: output sequences are lowercased.
DESCRIPTION="--cluster_smallmem default masking is dust (output is lowercased)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Default strand is plus.
DESCRIPTION="--cluster_smallmem default strand is plus (reverse complement not matched)"
printf ">s1\nAAAATTTT\n>s2\nAAAATTTT\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --uc - \
        --quiet 2> /dev/null | \
    grep -c "^C" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               core options                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--cluster_smallmem --centroids outputs fasta format"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --clusterout_id adds ;clusterid= to centroid headers"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --clusterout_id \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;clusterid=0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --clusterout_sort sorts --centroids by decreasing abundance"
printf ">a;size=1\nAAAAAAAAAAAA\n>b;size=5\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --sizein \
        --minseqlength 1 \
        --clusterout_sort \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -qx ">b;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --clusters writes one file per cluster"
TMPDIR_=$(mktemp -d)
PREFIX="${TMPDIR_}/c"
printf ">s1\nAAAAAAAAAAAA\n>s2\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --clusters "${PREFIX}" \
        --quiet 2> /dev/null
[[ -f "${PREFIX}0" && -f "${PREFIX}1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -rf "${TMPDIR_}"
unset PREFIX TMPDIR_

DESCRIPTION="--cluster_smallmem --consout writes consensus sequences"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --consout - \
        --quiet 2> /dev/null | \
    grep -qi "^a\{12\}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for V in 0 1 2 3 4 ; do
    DESCRIPTION="--cluster_smallmem --iddef accepts ${V}"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --iddef "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_smallmem --iddef rejects value 5"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --iddef 5 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --maxaccepts accepts a positive integer"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --maxaccepts 3 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --maxrejects accepts a positive integer"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --maxrejects 16 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --msaout writes an MSA with a consensus"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --msaout - \
        --quiet 2> /dev/null | \
    grep -qx ">consensus" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --profile outputs a profile header per cluster"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --profile - \
        --quiet 2> /dev/null | \
    grep -q "^>centroid=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for V in none dust soft ; do
    DESCRIPTION="--cluster_smallmem --qmask accepts ${V}"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --qmask "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_smallmem --qmask rejects unknown value"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --qmask unknown \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --qmask none preserves upper case output"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --qmask none \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --sizein reads abundance from headers"
printf ">s1;size=2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --sizein \
        --sizeout \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --sizeorder is accepted (requires --maxaccepts > 1)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --sizeorder \
        --maxaccepts 2 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --sizeout adds ;size= to centroid headers"
printf ">a\nAAAAAAAAAAAA\n>b\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --sizeout \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">a;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --sizein --sizeout preserves existing abundance"
printf ">a;size=3\nAAAAAAAAAAAA\n>b;size=2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --sizein \
        --sizeout \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">a;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for V in plus both ; do
    DESCRIPTION="--cluster_smallmem --strand accepts ${V}"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --strand "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_smallmem --strand rejects unknown value"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --strand unknown \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --strand both matches reverse complement"
printf ">s1\nAAAATTTTGGGG\n>s2\nCCCCAAAATTTT\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --strand both \
        --minseqlength 1 \
        --uc - \
        --quiet 2> /dev/null | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --uc emits S, H, and C records"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --uc - \
        --quiet 2> /dev/null | \
    awk '{print $1}' | \
    sort -u | \
    tr "\n" " " | \
    grep -qx "C H S " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --usersort is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --usersort \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             secondary options                               #
#                                                                             #
#*****************************************************************************#

## ---------- output formats ----------

DESCRIPTION="--cluster_smallmem --alnout writes a pairwise alignment block"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --alnout - \
        --quiet 2> /dev/null | \
    grep -q "Query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --blast6out has 12 tab-separated columns"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --blast6out - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NF != 12 {exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --biomout writes biom 1.0 JSON"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --biomout - \
        --quiet 2> /dev/null | \
    grep -q "Biological Observation Matrix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --fasta_width 0 disables line folding"
printf ">s1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --fasta_width 0 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "a\{36\}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --fastapairs writes fasta-format pairs"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --fastapairs - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --matched writes matching queries"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --matched - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --mothur_shared_out writes a shared header"
printf ">s1;sample=A\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --mothur_shared_out - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -q "numOtus" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --notmatched writes non-matching queries"
printf ">s1\nAAAAAAAAAAAA\n>s2\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --notmatched - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --otutabout writes an OTU table header"
printf ">s1;sample=A\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --otutabout - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -q "^#OTU ID" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --output_no_hits is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --output_no_hits \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --qsegout writes aligned query fragment"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --qsegout - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --tsegout writes aligned target fragment"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --tsegout - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --rowlen is accepted"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --rowlen 8 \
        --alnout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --samheader adds \@HD header to --samout"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --samheader \
        --samout - \
        --quiet 2> /dev/null | \
    grep -q "^@HD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --userfields --userout selects output fields"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --userfields query+target+id \
        --userout - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NF != 3 {exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- header manipulation ----------

DESCRIPTION="--cluster_smallmem --label_suffix appends to headers"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --label_suffix ";tag=x" \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;tag=x" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --lengthout adds ;length= to headers"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --lengthout \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;length=12" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --notrunclabels retains full header"
printf ">s1 suffix\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --notrunclabels \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1 suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --relabel replaces headers with prefix + ticker"
printf ">s1\nAAAAAAAAAAAA\n>s2\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel "c:" \
        --centroids - \
        --quiet 2> /dev/null | \
    awk '/^>/' | \
    tr "\n" " " | \
    grep -qx ">c:1 >c:2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --relabel_keep retains old identifier"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel "new:" \
        --relabel_keep \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">new:1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --relabel_md5 replaces header with MD5 digest"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel_md5 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --relabel_self replaces header with sequence"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --qmask none \
        --minseqlength 1 \
        --relabel_self \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --relabel_sha1 replaces header with SHA1 digest"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel_sha1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --sample adds ;sample= to headers"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --sample "abc" \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;sample=abc" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --xlength strips a length= annotation"
printf ">s1;length=12\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --xlength \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --xsize strips a size= annotation"
printf ">s1;size=3\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --sizein \
        --minseqlength 1 \
        --xsize \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- alignment parameters ----------

for OPT in --gapext --gapopen --idprefix --idsuffix --match --mismatch --mincols --minwordmatches ; do
    DESCRIPTION="--cluster_smallmem ${OPT} is accepted"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_smallmem --hardmask replaces masked regions with Ns"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --hardmask \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "N\{12\}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for OPT in --leftjust --rightjust --n_mismatch --self --selfid --top_hits_only ; do
    DESCRIPTION="--cluster_smallmem ${OPT} is accepted"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

## wordlength = 15 is too slow and requires too much memory
for V in 3 8 ; do
    DESCRIPTION="--cluster_smallmem --wordlength accepts ${V}"
    printf ">s1\nAAAAAAAAAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --minseqlength 1 \
            --wordlength "${V}" \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_smallmem --wordlength rejects value 2"
printf ">s1\nAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --wordlength 2 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------- rejection filters ----------

for OPT in --maxdiffs --maxgaps --maxhits --maxsubs ; do
    DESCRIPTION="--cluster_smallmem ${OPT} is accepted"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" 2 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

for OPT in --maxid --maxqt --minqt --maxsl --minsl --maxsizeratio --minsizeratio --mid --query_cov --target_cov --weak_id ; do
    DESCRIPTION="--cluster_smallmem ${OPT} is accepted"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" 0.5 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_smallmem --maxseqlength discards long sequences"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --maxseqlength 5 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --minseqlength discards short sequences"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 10 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

for OPT in --maxqsize --mintsize ; do
    DESCRIPTION="--cluster_smallmem ${OPT} is accepted"
    printf ">s1;size=3\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --sizein \
            --minseqlength 1 \
            "${OPT}" 2 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

## ---------- runtime behaviour ----------

DESCRIPTION="--cluster_smallmem --log writes a log file"
TMP=$(mktemp)
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --log "${TMP}" \
        --centroids /dev/null 2> /dev/null
grep -q "vsearch" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--cluster_smallmem --no_progress is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --no_progress \
        --centroids /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --quiet silences stderr messages"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --threads accepts a positive integer"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --threads 2 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- decompression ----------

DESCRIPTION="--cluster_smallmem --gzip_decompress reads gzip-compressed stdin"
printf ">s1\nAAAAAAAAAAAA\n" | gzip | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --gzip_decompress \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem --bzip2_decompress reads bzip2-compressed stdin"
printf ">s1\nAAAAAAAAAAAA\n" | bzip2 | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --bzip2_decompress \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- option interactions ----------

DESCRIPTION="--cluster_smallmem --sizeout --relabel preserves size after relabeling"
printf ">s1;size=3\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --sizein \
        --sizeout \
        --relabel "c:" \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">c:1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

for OPT in --band --hspw --minhsp --slots --xdrop_nw ; do
    DESCRIPTION="--cluster_smallmem accepts ignored option ${OPT} (integer arg)"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_smallmem accepts ignored option --fulldp"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --fulldp \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem accepts ignored option --pattern"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --pattern "xxx" \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem accepts ignored option --cons_truncate"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --cons_truncate \
        --centroids /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## options that belong to other commands
for OPT in --unoise_alpha --minsize --subseq_start --label ; do
    DESCRIPTION="--cluster_smallmem rejects ${OPT}"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_smallmem - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_smallmem rejects --relabel combined with --relabel_md5"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel X \
        --relabel_md5 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem rejects --relabel_md5 combined with --relabel_sha1"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel_md5 \
        --relabel_sha1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_smallmem cannot be combined with --cluster_fast"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
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

    ## memory leak in userfields: fixed in 2fde5472
    LOG=$(mktemp)
    FASTA=$(mktemp)
    printf ">s1\nA\n>s2\nA\n" > "${FASTA}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        "${VSEARCH}" \
        --cluster_smallmem "${FASTA}" \
        --minseqlength 1 \
        --id 0.5 \
        --alnout /dev/null \
        --biomout /dev/null \
        --blast6out /dev/null \
        --centroids /dev/null \
        --consout /dev/null \
        --fastapairs /dev/null \
        --log /dev/null \
        --matched /dev/null \
        --msaout /dev/null \
        --notmatched /dev/null \
        --otutabout /dev/null \
        --profile /dev/null \
        --samout /dev/null \
        --strand both \
        --uc /dev/null \
        --userout /dev/null \
        --userfields query+target+id 2> /dev/null
    DESCRIPTION="--cluster_smallmem valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--cluster_smallmem valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTA}"
fi


exit 0
