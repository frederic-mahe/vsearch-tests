#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="cluster_fast"
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


# vsearch --cluster_fast fastafile --id real (--alnout | --biomout |
# --blast6out | --centroids | --clusters | --mothur_shared_out |
# --msaout | --otutabout | --profile | --samout | --uc | --userout)
# filename [options]


#*****************************************************************************#
#                                                                             #
#                             mandatory options                               #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--cluster_fast is accepted"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast reads from stdin (-)"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast reads from a regular file"
TMP=$(mktemp)
printf ">s1\nAAAA\n" > "${TMP}"
"${VSEARCH}" \
    --cluster_fast "${TMP}" \
    --id 1.0 \
    --minseqlength 1 \
    --centroids /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--cluster_fast fails if input file does not exist"
"${VSEARCH}" \
    --cluster_fast /no/such/file \
    --id 1.0 \
    --minseqlength 1 \
    --centroids /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast fails if input file is not readable"
TMP=$(mktemp)
printf ">s1\nAAAA\n" > "${TMP}"
chmod u-r "${TMP}"
"${VSEARCH}" \
    --cluster_fast "${TMP}" \
    --id 1.0 \
    --minseqlength 1 \
    --centroids /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--cluster_fast accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast accepts fasta input"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast accepts fastq input"
printf "@s1\nAAAA\n+\nIIII\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast rejects input that is not fasta or fastq"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast fails without --id"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast fails without any output option"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --id accepts boundary values
for V in 0 0.0 0.5 1 1.0 ; do
    DESCRIPTION="--cluster_fast --id accepts value ${V}"
    printf ">s1\nAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_fast --id rejects negative value"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id -0.1 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --id rejects value greater than 1.0"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.1 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --id rejects non-numeric value"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id abc \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## each listed output option accepted alone (--clusters uses a prefix path)
for OPT in --alnout --biomout --blast6out --centroids --mothur_shared_out --msaout --otutabout --profile --samout --uc --userout ; do
    DESCRIPTION="--cluster_fast accepts ${OPT} as sole output option"
    printf ">s1\nAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_fast accepts --clusters as sole output option"
PREFIX=$(mktemp -d)/c
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
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

## Input sequences are sorted by decreasing length before clustering:
## the longer sequence becomes the centroid.
DESCRIPTION="--cluster_fast sorts input by decreasing length (longer seeds cluster)"
printf ">short\nAAAA\n>long\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.5 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -qx ">long" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Default masking is dust: output sequences are lowercased.
DESCRIPTION="--cluster_fast default masking is dust (output is lowercased)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "aaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Default strand is plus: reverse-complement matches are not detected.
DESCRIPTION="--cluster_fast default strand is plus (reverse complement not matched)"
printf ">s1\nAAAATTTT\n>s2\nAAAATTTT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --uc - \
        --quiet 2> /dev/null | \
    grep -c "^C" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Default minseqlength is 32: shorter sequences are discarded.
DESCRIPTION="--cluster_fast default minseqlength is 32 (short sequences discarded)"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## Default maxaccepts is 1.
DESCRIPTION="--cluster_fast default maxaccepts is 1 (first match wins)"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n>s3\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
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

## --centroids: write cluster centroid sequences in fasta format
DESCRIPTION="--cluster_fast --centroids outputs fasta format"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --centroids reports one centroid per cluster"
printf ">s1\nAAAAAAAAAAAA\n>s2\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --clusterout_id: add cluster identifier to centroid/consout/profile headers
DESCRIPTION="--cluster_fast --clusterout_id adds ;clusterid= to centroid headers"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --clusterout_id \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;clusterid=0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --clusterout_id is accepted with --consout"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --clusterout_id \
        --consout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --clusterout_sort: sort some outputs by decreasing abundance
DESCRIPTION="--cluster_fast --clusterout_sort sorts --centroids by decreasing abundance"
printf ">a;size=1\nAAAAAAAAAAAA\n>b;size=5\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
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

## --clusters: write each cluster to a separate fasta file with prefix
DESCRIPTION="--cluster_fast --clusters writes one file per cluster using prefix"
TMPDIR_=$(mktemp -d)
PREFIX="${TMPDIR_}/c"
printf ">s1\nAAAAAAAAAAAA\n>s2\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --clusters "${PREFIX}" \
        --quiet 2> /dev/null
[[ -f "${PREFIX}0" && -f "${PREFIX}1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -rf "${TMPDIR_}"
unset PREFIX TMPDIR_

DESCRIPTION="--cluster_fast --clusters accepts '-' as prefix"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --clusters - \
        --quiet > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --clusters fails if prefix argument is missing"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --clusters > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --consout: write cluster consensus sequences to filename
DESCRIPTION="--cluster_fast --consout writes consensus sequences"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --consout - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qi "^a\{12\}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --iddef: change the identity definition used with --id
for V in 0 1 2 3 4 ; do
    DESCRIPTION="--cluster_fast --iddef accepts ${V}"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 1.0 \
            --iddef "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_fast --iddef rejects value 5"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --iddef 5 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --iddef rejects negative value"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --iddef -1 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --maxaccepts: maximum number of matching targets to accept
DESCRIPTION="--cluster_fast --maxaccepts accepts a positive integer"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --maxaccepts 3 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --maxaccepts 0 accepted (with --maxrejects 0 searches full db)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --maxrejects: maximum number of non-matching targets
DESCRIPTION="--cluster_fast --maxrejects accepts a positive integer"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --maxrejects 16 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --msaout: multiple sequence alignment per cluster
DESCRIPTION="--cluster_fast --msaout writes an MSA with a consensus"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --msaout - \
        --quiet 2> /dev/null | \
    grep -qx ">consensus" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --profile: nucleotide frequency per cluster position
DESCRIPTION="--cluster_fast --profile outputs a profile header per cluster"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --profile - \
        --quiet 2> /dev/null | \
    grep -q "^>centroid=s1;seqs=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --qmask: masking method
for V in none dust soft ; do
    DESCRIPTION="--cluster_fast --qmask accepts ${V}"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 1.0 \
            --qmask "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_fast --qmask rejects unknown value"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --qmask unknown \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --qmask none preserves upper case output"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --qmask none \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizein: read abundance annotations from headers
DESCRIPTION="--cluster_fast --sizein is accepted"
printf ">s1;size=2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --sizein \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizeorder: tiebreaker using abundance; requires --maxaccepts > 1
DESCRIPTION="--cluster_fast --sizeorder is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --sizeorder \
        --maxaccepts 2 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizeout: add size= annotations
DESCRIPTION="--cluster_fast --sizeout adds ;size= to centroid headers"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --sizeout \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizein + --sizeout: propagate existing abundance
DESCRIPTION="--cluster_fast --sizein --sizeout preserves existing abundance"
printf ">s1;size=3\nAAAAAAAAAAAA\n>s2;size=2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --sizein \
        --sizeout \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --strand: plus or both
for V in plus both ; do
    DESCRIPTION="--cluster_fast --strand accepts ${V}"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 1.0 \
            --strand "${V}" \
            --minseqlength 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset V

DESCRIPTION="--cluster_fast --strand rejects unknown value"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --strand unknown \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --strand both matches reverse complement"
printf ">s1\nAAAATTTTGGGG\n>s2\nCCCCAAAATTTT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --strand both \
        --minseqlength 1 \
        --uc - \
        --quiet 2> /dev/null | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc: uclust-like tab-separated format with S/H/C record types
DESCRIPTION="--cluster_fast --uc emits S records for cluster seeds"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --uc - \
        --quiet 2> /dev/null | \
    grep -q "^S" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --uc emits H records for hits"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --uc - \
        --quiet 2> /dev/null | \
    grep -q "^H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --uc emits C records for cluster summaries"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --uc - \
        --quiet 2> /dev/null | \
    grep -q "^C" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             secondary options                               #
#                                                                             #
#*****************************************************************************#

## ---------- output formats ----------

DESCRIPTION="--cluster_fast --alnout writes a pairwise alignment block"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --alnout - \
        --quiet 2> /dev/null | \
    grep -q "Query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --blast6out has 12 tab-separated columns"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --blast6out - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NF != 12 {exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --biomout writes JSON (biom 1.0 format)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --biomout - \
        --quiet 2> /dev/null | \
    grep -q "Biological Observation Matrix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --fasta_width 0 disables line folding"
printf ">s1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --fasta_width 0 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "a\{36\}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --fasta_width folds long lines"
printf ">s1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --fasta_width 10 \
        --minseqlength 1 \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "a\{10\}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --fastapairs writes fasta-format pairs"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --fastapairs - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --matched writes matching queries"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --matched - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --mothur_shared_out writes a shared-format header"
printf ">s1;sample=A\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --mothur_shared_out - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -q "numOtus" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --notmatched writes non-matching queries"
printf ">s1\nAAAAAAAAAAAA\n>s2\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --notmatched - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --otutabout writes an OTU table header"
printf ">s1;sample=A\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --otutabout - \
        --quiet 2> /dev/null | \
    awk 'NR==1' | \
    grep -q "^#OTU ID" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --output_no_hits is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --output_no_hits \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --qsegout writes aligned query fragment"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --qsegout - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -q "^>s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --tsegout writes aligned target fragment"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --tsegout - \
        --centroids /dev/null \
        --quiet 2> /dev/null | \
    grep -q "^>s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --rowlen sets --alnout line width"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --rowlen 8 \
        --alnout /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --samheader adds \@HD header to --samout"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --samheader \
        --samout - \
        --quiet 2> /dev/null | \
    grep -q "^@HD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --userfields --userout selects output fields"
printf ">s1\nAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --userfields query+target+id \
        --userout - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NF != 3 {exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- header manipulation ----------

DESCRIPTION="--cluster_fast --label_suffix appends to sequence headers"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --label_suffix ";tag=x" \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;tag=x" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --lengthout adds ;length= to headers"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --lengthout \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;length=12" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --notrunclabels retains full header"
printf ">s1 suffix\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --notrunclabels \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1 suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --relabel replaces headers with prefix + ticker"
printf ">s1\nAAAAAAAAAAAA\n>s2\nCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
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

DESCRIPTION="--cluster_fast --relabel_keep retains old identifier"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel "new:" \
        --relabel_keep \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">new:1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --relabel_md5 replaces header with MD5 digest"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel_md5 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --relabel_self replaces header with sequence"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --qmask none \
        --relabel_self \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">AAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --relabel_sha1 replaces header with SHA1 digest"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel_sha1 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --sample adds ;sample= to headers"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --sample "abc" \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;sample=abc" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --xlength strips a length= annotation"
printf ">s1;length=12\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --xlength \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --xsize strips a size= annotation"
printf ">s1;size=3\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
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

DESCRIPTION="--cluster_fast --gapext accepts a penalty string"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --gapext 2I/1E \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --gapopen accepts a penalty string"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --gapopen 20I/2E \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --hardmask replaces masked regions with Ns"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --hardmask \
        --centroids - \
        --quiet 2> /dev/null | \
    awk 'NR==2' | \
    grep -qx "N\{12\}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --idprefix is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --idprefix 4 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --idsuffix is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --idsuffix 4 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --leftjust is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --leftjust \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --rightjust is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --rightjust \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --match is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --match 3 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --mismatch is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --mismatch -3 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --mincols is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --mincols 1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## wordlength = 15 is too slow and requires too much memory
DESCRIPTION="--cluster_fast --wordlength accepts a value in [3, 15]"
for V in 3 8 ; do
    printf ">s1\nAAAAAAAAAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 1.0 \
            --minseqlength 1 \
            --wordlength "${V}" \
            --centroids /dev/null \
            --quiet 2> /dev/null || \
        failure "${DESCRIPTION} (wordlength=${V})"
done
success "${DESCRIPTION}"
unset V

DESCRIPTION="--cluster_fast --wordlength rejects value 2"
printf ">s1\nAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --wordlength 2 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --wordlength rejects value 16"
printf ">s1\nAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --wordlength 16 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --minwordmatches accepts a non-negative integer"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --minwordmatches 0 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- rejection filters ----------

for OPT in --maxdiffs --maxgaps --maxsubs ; do
    DESCRIPTION="--cluster_fast ${OPT} is accepted"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" 2 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_fast --maxhits is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --maxhits 5 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --maxhits 0 is accepted (unlimited)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --maxhits 0 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for OPT in --maxid --maxqt --minqt --maxsl --minsl --maxsizeratio --minsizeratio --mid --query_cov --target_cov ; do
    DESCRIPTION="--cluster_fast ${OPT} is accepted"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" 0.5 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

for OPT in --maxqsize --mintsize ; do
    DESCRIPTION="--cluster_fast ${OPT} is accepted"
    printf ">s1;size=3\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
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

DESCRIPTION="--cluster_fast --maxseqlength discards long sequences"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --maxseqlength 5 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --minseqlength discards short sequences"
printf ">s1\nAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 10 \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --weak_id is accepted (lower than --id)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.9 \
        --weak_id 0.5 \
        --minseqlength 1 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --self is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --self \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --selfid is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --selfid \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --top_hits_only is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --top_hits_only \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --n_mismatch is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --n_mismatch \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- runtime behaviour ----------

DESCRIPTION="--cluster_fast --log writes a log file"
TMP=$(mktemp)
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --log "${TMP}" \
        --centroids /dev/null 2> /dev/null
grep -q "vsearch" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--cluster_fast --no_progress is accepted"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --no_progress \
        --centroids /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --quiet silences stderr messages"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --centroids /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --threads accepts a positive integer"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --threads 2 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- decompression ----------

DESCRIPTION="--cluster_fast --gzip_decompress reads gzip-compressed stdin"
printf ">s1\nAAAAAAAAAAAA\n" | gzip | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --gzip_decompress \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast --bzip2_decompress reads bzip2-compressed stdin"
printf ">s1\nAAAAAAAAAAAA\n" | bzip2 | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --bzip2_decompress \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------- option interactions ----------

DESCRIPTION="--cluster_fast --sizeout --relabel preserves size after relabeling"
printf ">s1;size=3\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
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

DESCRIPTION="--cluster_fast --label_suffix --lengthout applies both to headers"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --label_suffix ";tag=x" \
        --lengthout \
        --centroids - \
        --quiet 2> /dev/null | \
    grep -qx ">s1;tag=x;length=12" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

for OPT in --band --hspw --minhsp --slots --xdrop_nw ; do
    DESCRIPTION="--cluster_fast accepts ignored option ${OPT} (integer arg)"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

DESCRIPTION="--cluster_fast accepts ignored option --fulldp (no arg)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --fulldp \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast accepts ignored option --pattern (string arg)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --pattern "xxx" \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cluster_fast accepts ignored option --cons_truncate (warns)"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
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
for OPT in --usersort --unoise_alpha --minsize --subseq_start --label ; do
    DESCRIPTION="--cluster_fast rejects ${OPT}"
    printf ">s1\nAAAAAAAAAAAA\n" | \
        "${VSEARCH}" \
            --cluster_fast - \
            --id 1.0 \
            --minseqlength 1 \
            "${OPT}" 1 \
            --centroids /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OPT

## combining mutually exclusive relabel options must fail
DESCRIPTION="--cluster_fast rejects --relabel combined with --relabel_md5"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel X \
        --relabel_md5 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cluster_fast rejects --relabel_md5 combined with --relabel_sha1"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 1.0 \
        --minseqlength 1 \
        --relabel_md5 \
        --relabel_sha1 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## combining two main commands must fail
DESCRIPTION="--cluster_fast cannot be combined with --cluster_size"
printf ">s1\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --cluster_size - \
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
        --cluster_fast "${FASTA}" \
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
    DESCRIPTION="--cluster_fast valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--cluster_fast valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTA}"
fi


exit 0
