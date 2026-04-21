#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="cluster_unoise"
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


# vsearch --cluster_unoise fastafile (--alnout | --biomout |
# --blast6out | --centroids | --clusters | --mothur_shared_out |
# --msaout | --otutabout | --profile | --samout | --uc | --userout)
# filename [options]


#*****************************************************************************#
#                                                                             #
#                             mandatory options                               #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--cluster_unoise is accepted"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise reads from stdin (-)"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise reads from a regular file"
TMP=$(mktemp)
printf ">s1;size=16\nAAAAAAAAAAAA\n" > "${TMP}"
"${VSEARCH}" \
    --cluster_unoise "${TMP}" \
    --sizein \
    --minseqlength 1 \
    --centroids /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--cluster_unoise fails if input file does not exist"
"${VSEARCH}" \
    --cluster_unoise /no/such/file \
    --sizein \
    --minseqlength 1 \
    --centroids /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise fails if input file is not readable"
TMP=$(mktemp)
printf ">s1;size=16\nAAAAAAAAAAAA\n" > "${TMP}"
chmod u-r "${TMP}"
"${VSEARCH}" \
    --cluster_unoise "${TMP}" \
    --sizein \
    --minseqlength 1 \
    --centroids /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--cluster_unoise accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise accepts fasta input"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise accepts fastq input"
printf "@s1;size=16\nAAAAAAAAAAAA\n+\nIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise rejects input that is not fasta or fastq"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise fails without any output option"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## Unlike other cluster commands, --cluster_unoise does not require --id.
DESCRIPTION="--cluster_unoise does not require --id"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## each listed output option accepted alone
for OPT in --alnout --biomout --blast6out --centroids --mothur_shared_out --msaout --otutabout --profile --samout --uc --userout ; do
    DESCRIPTION="--cluster_unoise accepts ${OPT} as sole output option"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --minseqlength 1 \
            "${OPT}" /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_unoise accepts --clusters as sole output option"
PREFIX=$(mktemp -d)/c
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
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

## Default --minsize is 8: less abundant sequences are discarded.
DESCRIPTION="--cluster_unoise default --minsize is 8 (lower abundance discarded)"
printf ">s1;size=7\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise default --minsize is 8 (size=8 is kept)"
printf ">s1;size=8\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "^>s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Sequences without --sizein are treated as size=1 and discarded by default.
DESCRIPTION="--cluster_unoise without --sizein discards all sequences (default minsize=8)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## Default masking is dust: output sequences are lowercased.
DESCRIPTION="--cluster_unoise default masking is dust (output is lowercased)"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Default strand is plus.
DESCRIPTION="--cluster_unoise default strand is plus (reverse complement not matched)"
printf ">s1;size=16\nAAAATTTT\n>s2;size=8\nAAAATTTT\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
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

DESCRIPTION="--cluster_unoise --centroids outputs fasta format"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --clusterout_id adds ;clusterid= to centroid headers"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --clusterout_id \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "clusterid=0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --clusterout_sort sorts --centroids by decreasing abundance"
printf ">a;size=8\nAAAAAAAAAAAA\n>b;size=16\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --clusterout_sort \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -q "^>b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --clusters writes one file per cluster"
TMPDIR_=$(mktemp -d)
PREFIX="${TMPDIR_}/c"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --clusters "${PREFIX}" \
        --quiet 2> /dev/null
[[ -f "${PREFIX}0" && -f "${PREFIX}1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -rf "${TMPDIR_}"
unset PREFIX TMPDIR_

DESCRIPTION="--cluster_unoise --consout writes consensus sequences"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --consout - \
        --quiet 2> /dev/null | \
    grep -qi "^a\{12\}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for V in 0 1 2 3 4 ; do
    DESCRIPTION="--cluster_unoise --iddef accepts ${V}"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --iddef "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_unoise --iddef rejects value 5"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --iddef 5 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --maxaccepts accepts a positive integer"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --maxaccepts 3 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --maxrejects accepts a positive integer"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --maxrejects 16 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --minsize is accepted"
printf ">s1;size=2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minsize 1 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --minsize 1 keeps all sequences"
printf ">s1;size=1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minsize 1 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "^>s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --minsize 100 discards lower-abundance sequences"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minsize 100 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --msaout writes an MSA with a consensus"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --msaout - \
        --quiet 2> /dev/null | \
    grep -qx ">consensus" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --profile outputs a profile header per cluster"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --profile - \
        --quiet 2> /dev/null | \
    grep -q "^>centroid=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for V in none dust soft ; do
    DESCRIPTION="--cluster_unoise --qmask accepts ${V}"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --qmask "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_unoise --qmask rejects unknown value"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --qmask unknown \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --qmask none preserves upper case output"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --qmask none \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --sizein reads abundance from headers"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --sizeout \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=16" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --sizeorder is accepted (requires --maxaccepts > 1)"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --sizeorder \
        --maxaccepts 2 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --sizeout adds ;size= to centroid headers"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --sizeout \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=32" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for V in plus both ; do
    DESCRIPTION="--cluster_unoise --strand accepts ${V}"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --strand "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_unoise --strand rejects unknown value"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --strand unknown \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --uc emits S, H, and C records"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --uc - \
        --quiet 2> /dev/null | \
    awk '{print $1}' | \
    sort -u | \
    tr "\n" " " | \
    grep -qx "C H S " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --unoise_alpha accepts a real value"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --unoise_alpha 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --unoise_alpha accepts the default value 2.0"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --unoise_alpha 2.0 \
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

DESCRIPTION="--cluster_unoise --alnout writes a pairwise alignment block"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --alnout - \
        --quiet 2> /dev/null | \
    grep -q "Query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --blast6out has 12 tab-separated columns"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --blast6out - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NF != 12 {exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --biomout writes biom 1.0 JSON"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --biomout - \
        --quiet 2> /dev/null | \
    grep -q "Biological Observation Matrix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --fasta_width 0 disables line folding"
printf ">s1;size=16\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --fasta_width 0 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "a\{36\}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --fastapairs writes fasta-format pairs"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --fastapairs - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --matched writes matching queries"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --matched - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --mothur_shared_out writes a shared header"
printf ">s1;sample=A;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --mothur_shared_out - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -q "numOtus" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --notmatched writes non-matching queries"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --notmatched - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --otutabout writes an OTU table header"
printf ">s1;sample=A;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --otutabout - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -q "^#OTU ID" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --output_no_hits is accepted"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --output_no_hits \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --qsegout writes aligned query fragment"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --qsegout - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --tsegout writes aligned target fragment"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --tsegout - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --rowlen is accepted"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --rowlen 8 \
        --alnout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --samheader adds \@HD header to --samout"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --samheader \
        --samout - \
        --quiet 2> /dev/null | \
    grep -q "^@HD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --userfields --userout selects output fields"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --userfields query+target+id \
        --userout - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NF != 3 {exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- header manipulation ----------

DESCRIPTION="--cluster_unoise --label_suffix appends to headers"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --label_suffix ";tag=x" \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q ";tag=x" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --lengthout adds ;length= to headers"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --lengthout \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q ";length=12" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --notrunclabels retains full header"
printf ">s1;size=16 suffix\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minsize 1 \
        --minseqlength 1 \
        --notrunclabels \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q " suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --relabel replaces headers with prefix + ticker"
printf ">s1;size=16\nAAAAAAAAAAAA\n>s2;size=16\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --relabel "c:" \
        --centroids - \
        --quiet 2> /dev/null | \
    awk '/^>/' | \
    tr "\n" " " | \
    grep -qx ">c:1 >c:2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --relabel_keep retains old identifier"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --relabel "new:" \
        --relabel_keep \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "^>new:1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --relabel_md5 replaces header with MD5 digest"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --relabel_md5 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --relabel_self replaces header with sequence"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --qmask none \
        --minseqlength 1 \
        --relabel_self \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --relabel_sha1 replaces header with SHA1 digest"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --relabel_sha1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --sample adds ;sample= to headers"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --sample "abc" \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q ";sample=abc" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --xlength strips a length= annotation"
printf ">s1;size=16;length=12\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --xlength \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q ";length=" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --xsize strips a size= annotation"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
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
    DESCRIPTION="--cluster_unoise ${OPT} is accepted"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --minseqlength 1 \
            "${OPT}" 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_unoise --hardmask replaces masked regions with Ns"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --hardmask \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "N\{12\}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for OPT in --leftjust --rightjust --n_mismatch --self --selfid --top_hits_only ; do
    DESCRIPTION="--cluster_unoise ${OPT} is accepted"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
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
    DESCRIPTION="--cluster_unoise --wordlength accepts ${V}"
    printf ">s1;size=16\nAAAAAAAAAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --minseqlength 1 \
            --wordlength "${V}" \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_unoise --wordlength rejects value 2"
printf ">s1;size=16\nAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --wordlength 2 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------- rejection filters ----------

for OPT in --maxdiffs --maxgaps --maxhits --maxsubs ; do
    DESCRIPTION="--cluster_unoise ${OPT} is accepted"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --minseqlength 1 \
            "${OPT}" 2 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

for OPT in --maxid --maxqt --minqt --maxsl --minsl --maxsizeratio --minsizeratio --mid --query_cov --target_cov --weak_id ; do
    DESCRIPTION="--cluster_unoise ${OPT} is accepted"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --minseqlength 1 \
            "${OPT}" 0.5 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_unoise --maxseqlength discards long sequences"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --maxseqlength 5 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --minseqlength discards short sequences"
printf ">s1;size=16\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 10 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

for OPT in --maxqsize --mintsize ; do
    DESCRIPTION="--cluster_unoise ${OPT} is accepted"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
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

DESCRIPTION="--cluster_unoise --log writes a log file"
TMP=$(mktemp)
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --log "${TMP}" \
        --centroids /dev/null 2> /dev/null
grep -q "vsearch" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--cluster_unoise --no_progress is accepted"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --no_progress \
        --centroids /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --quiet silences stderr messages"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --threads accepts a positive integer"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --threads 2 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- decompression ----------

DESCRIPTION="--cluster_unoise --gzip_decompress reads gzip-compressed stdin"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | gzip | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --gzip_decompress \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise --bzip2_decompress reads bzip2-compressed stdin"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | bzip2 | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --bzip2_decompress \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- option interactions ----------

DESCRIPTION="--cluster_unoise --sizeout --relabel preserves size after relabeling"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --sizeout \
        --relabel "c:" \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">c:1;size=16" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --id is in the valid options list but UNOISE uses --unoise_alpha for
## acceptance; --id is silently accepted with no observable effect.
DESCRIPTION="--cluster_unoise --id is accepted (no effect on the UNOISE algorithm)"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --id 0.97 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

for OPT in --band --hspw --minhsp --slots --xdrop_nw ; do
    DESCRIPTION="--cluster_unoise accepts ignored option ${OPT} (integer arg)"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --minseqlength 1 \
            "${OPT}" 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_unoise accepts ignored option --fulldp"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --fulldp \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise accepts ignored option --pattern"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --pattern "xxx" \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise accepts ignored option --cons_truncate"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
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
for OPT in --usersort --subseq_start --label ; do
    DESCRIPTION="--cluster_unoise rejects ${OPT}"
    printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_unoise - \
            --sizein \
            --minseqlength 1 \
            "${OPT}" 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_unoise rejects --relabel combined with --relabel_md5"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --relabel X \
        --relabel_md5 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise rejects --relabel_md5 combined with --relabel_sha1"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --sizein \
        --minseqlength 1 \
        --relabel_md5 \
        --relabel_sha1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_unoise cannot be combined with --cluster_fast"
printf ">s1;size=16\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_unoise - \
        --cluster_fast - \
        --id 1.0 \
        --sizein \
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
    printf ">s1;size=16\nA\n>s2;size=8\nA\n" > "${FASTA}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        "${VSEARCH}" \
        --cluster_unoise "${FASTA}" \
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
    DESCRIPTION="--cluster_unoise valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--cluster_unoise valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTA}"
fi


exit 0
