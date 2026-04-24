#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="usearch_global"
LINE=$(printf -- "-%.0s" {1..76})
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


## vsearch --usearch_global fastxfile --db filename --id real (--alnout |
## --biomout | --blast6out | --fastapairs | --matched |
## --mothur_shared_out | --notmatched | --otutabout | --qsegout |
## --samout | --tsegout | --uc | --userout) filename [options]

## A 40-nt sequence used in most tests; both query and target are
## identical by default, producing a single full-length global match.
## 40 nt is long enough to pass the default k-mer index thresholds
## without needing --minseqlength.
SEQ="ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT"


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global reads query from stdin (-)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --quiet \
        --blast6out - | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global reads query from a regular file"
DB=$(mktemp)
QUERY=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" > "${QUERY}"
"${VSEARCH}" \
    --usearch_global "${QUERY}" \
    --db "${DB}" \
    --id 1.0 \
    --quiet \
    --blast6out - | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERY}"
unset DB QUERY

DESCRIPTION="--usearch_global fails if query file does not exist"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
"${VSEARCH}" \
    --usearch_global /no/such/file \
    --db "${DB}" \
    --id 1.0 \
    --quiet \
    --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global fails if query file is not readable"
DB=$(mktemp)
QUERY=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" > "${QUERY}"
chmod u-r "${QUERY}"
"${VSEARCH}" \
    --usearch_global "${QUERY}" \
    --db "${DB}" \
    --id 1.0 \
    --quiet \
    --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${QUERY}" && rm -f "${QUERY}" "${DB}"
unset DB QUERY

DESCRIPTION="--usearch_global accepts empty query input"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf "" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global accepts fasta query input"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global accepts fastq query input"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf "@q\n%s\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global rejects query that is not fasta or fastq"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf "not a fasta file\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global fails without --db"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --id 1.0 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global fails if --db file does not exist"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db /no/such/file \
        --id 1.0 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global accepts a fasta --db"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global accepts a fastq --db"
DB=$(mktemp)
printf "@d\n%s\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --db can also be a UDB file produced by --makeudb_usearch
DESCRIPTION="--usearch_global accepts a UDB --db"
DB=$(mktemp)
UDB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
"${VSEARCH}" \
    --makeudb_usearch "${DB}" \
    --output "${UDB}" \
    --quiet 2> /dev/null
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${UDB}" \
        --id 1.0 \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${UDB}"
unset DB UDB

DESCRIPTION="--usearch_global fails without --id"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global accepts --id 0.0"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global accepts --id 1.0"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global rejects --id below 0.0"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id -0.1 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global rejects --id above 1.0"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.1 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global fails without any output option"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## each output option listed in the synopsis can be used as the sole
## output option, with the exception of --qsegout and --tsegout (see
## below)
for OPT in --alnout --biomout --blast6out --fastapairs --matched \
           --mothur_shared_out --notmatched --otutabout \
           --samout --uc --userout ; do
    DESCRIPTION="--usearch_global accepts ${OPT} as sole output option"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --usearch_global - \
            --db "${DB}" \
            --id 1.0 \
            "${OPT}" /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset OPT

## manpage claims --qsegout and --tsegout can be used as sole output
## options, but vsearch rejects them with "No output files
## specified". They can still be used alongside another output option
## (see secondary options section). To be reviewed.
for OPT in --qsegout --tsegout ; do
    DESCRIPTION="--usearch_global rejects ${OPT} as sole output option"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --usearch_global - \
            --db "${DB}" \
            --id 1.0 \
            "${OPT}" /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset OPT


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## identical query and target produce a full-length global match
DESCRIPTION="--usearch_global reports a hit when query and target are identical"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q" && $2 == "d" && $3 == "100.0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## a query below the identity threshold produces no hit
DESCRIPTION="--usearch_global reports no hit below the identity threshold"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACCTAACTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## default strand is plus only: a reverse-complemented query does not
## match the forward target (using a non-palindromic sequence)
DESCRIPTION="--usearch_global default searches plus strand only"
DB=$(mktemp)
printf ">d\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" > "${DB}"
printf ">q\nAAATTTTAAAAACCCCCGGGGGTTTTTGATCGATCGATCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.97 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## by default, non-matching queries are not written to --blast6out
DESCRIPTION="--usearch_global does not report non-matching queries by default"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCG\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.97 \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --blast6out reports 12 tab-separated fields per match
DESCRIPTION="--usearch_global --blast6out reports 12 tab-separated fields"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit NF == 12 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --blast6out reports evalue -1 and bit score 0 (always for nucleotide
## alignments)
DESCRIPTION="--usearch_global --blast6out reports evalue -1 and bit score 0"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit ($11 == "-1" && $12 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --uc reports 10 tab-separated fields per record
DESCRIPTION="--usearch_global --uc reports 10 tab-separated fields"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --uc - \
        --quiet | \
    awk -F'\t' '{exit NF == 10 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --uc reports an H record for a matching query
DESCRIPTION="--usearch_global --uc reports an H record for a hit"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --uc - \
        --quiet | \
    awk -F'\t' '{exit $1 == "H" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## default --maxaccepts is 1: only the first accepted target is
## reported, even when several identical targets are present
DESCRIPTION="--usearch_global default --maxaccepts is 1"
DB=$(mktemp)
printf ">d1\n%s\n>d2\n%s\n" "${SEQ}" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out - \
        --quiet | \
    wc -l | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------------- dbmask

for METHOD in none dust soft ; do
    DESCRIPTION="--usearch_global --dbmask ${METHOD} is accepted"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --usearch_global - \
            --db "${DB}" \
            --id 1.0 \
            --dbmask "${METHOD}" \
            --blast6out /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset METHOD

DESCRIPTION="--usearch_global --dbmask invalid is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --dbmask xxx \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- iddef

for DEF in 0 1 2 3 4 ; do
    DESCRIPTION="--usearch_global --iddef ${DEF} is accepted"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --usearch_global - \
            --db "${DB}" \
            --id 1.0 \
            --iddef "${DEF}" \
            --blast6out /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset DEF

DESCRIPTION="--usearch_global --iddef 5 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --iddef 5 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --iddef 2 (default) produces 100% for an exact full-length match
DESCRIPTION="--usearch_global --iddef 2 reports 100.0 for exact match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --iddef 2 \
        --userfields id \
        --userout - \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- maxaccepts

DESCRIPTION="--usearch_global --maxaccepts 1 is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxaccepts 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --maxaccepts caps the number of accepted hits per query
DESCRIPTION="--usearch_global --maxaccepts caps the number of reported hits"
DB=$(mktemp)
printf ">d1\n%s\n>d2\n%s\n>d3\n%s\n" "${SEQ}" "${SEQ}" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxaccepts 2 \
        --blast6out - \
        --quiet | \
    wc -l | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global negative --maxaccepts is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxaccepts -1 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- maxrejects

DESCRIPTION="--usearch_global --maxrejects 32 is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxrejects 32 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## with --maxaccepts 0 --maxrejects 0, the full database is searched
DESCRIPTION="--usearch_global --maxaccepts 0 --maxrejects 0 scans the whole db"
DB=$(mktemp)
printf ">d1\n%s\n>d2\n%s\n>d3\n%s\n" "${SEQ}" "${SEQ}" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --blast6out - \
        --quiet | \
    wc -l | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- qmask

for METHOD in none dust soft ; do
    DESCRIPTION="--usearch_global --qmask ${METHOD} is accepted"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --usearch_global - \
            --db "${DB}" \
            --id 1.0 \
            --qmask "${METHOD}" \
            --blast6out /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset METHOD

DESCRIPTION="--usearch_global --qmask invalid is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --qmask xxx \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- strand

DESCRIPTION="--usearch_global --strand plus is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --strand plus \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --strand both is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --strand both \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --strand both finds a reverse-complemented match (non-palindromic
## sequence)
DESCRIPTION="--usearch_global --strand both matches the reverse complement"
DB=$(mktemp)
printf ">d\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" > "${DB}"
printf ">q\nAAATTTTAAAAACCCCCGGGGGTTTTTGATCGATCGATCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.97 \
        --strand both \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --strand invalid is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --strand xxx \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ threads

DESCRIPTION="--usearch_global --threads 1 is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --threads 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --usearch_global is multi-threaded: --threads > 1 should not produce
## a warning about the command not being multi-threaded
DESCRIPTION="--usearch_global --threads > 1 does not warn about non-multithreaded command"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --threads 2 \
        --blast6out /dev/null 2>&1 | \
    grep -iq "not multi-threaded\|only one thread will be used" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --threads above 1024 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --threads 1025 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global negative --threads is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --threads -1 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                           secondary options                                 #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------------- alnout

DESCRIPTION="--usearch_global --alnout is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --alnout /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --alnout writes a human-readable pairwise alignment including the
## query and target labels
DESCRIPTION="--usearch_global --alnout writes query and target labels"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --alnout - \
        --quiet | \
    grep -q "Query >q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ biomout

DESCRIPTION="--usearch_global --biomout writes a JSON biom document"
DB=$(mktemp)
printf ">otu1\n%s\n" "${SEQ}" > "${DB}"
printf ">q1;sample=s1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --biomout - \
        --quiet | \
    grep -q "Biological Observation Matrix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------- bzip2_decompress

DESCRIPTION="--usearch_global --bzip2_decompress reads bzip2-compressed stdin"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    bzip2 | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --bzip2_decompress \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --bzip2_decompress rejects uncompressed stdin"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --bzip2_decompress \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- dbmatched

DESCRIPTION="--usearch_global --dbmatched writes matched target sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out /dev/null \
        --dbmatched - \
        --quiet | \
    grep -qw ">d" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --dbmatched --sizeout reports the number of matching queries"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
(
    printf ">q1\n%s\n" "${SEQ}"
    printf ">q2\n%s\n" "${SEQ}"
) | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out /dev/null \
        --dbmatched - \
        --sizeout \
        --quiet | \
    grep -qx ">d;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- dbnotmatched

DESCRIPTION="--usearch_global --dbnotmatched writes unmatched target sequences"
DB=$(mktemp)
printf ">d1\n%s\n>d2\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out /dev/null \
        --dbnotmatched - \
        --quiet | \
    grep -qw ">d2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- fasta_width

DESCRIPTION="--usearch_global --fasta_width is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --fasta_width 5 \
        --matched /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --fasta_width folds sequences in the matched output file (here, onto
## multiple lines of at most 5 nt each)
DESCRIPTION="--usearch_global --fasta_width folds matched sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --fasta_width 5 \
        --matched - \
        --quiet | \
    awk '/^>/ {next} {exit length($0) <= 5 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------- gzip_decompress

DESCRIPTION="--usearch_global --gzip_decompress reads gzip-compressed stdin"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    gzip | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --gzip_decompress \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ hardmask

DESCRIPTION="--usearch_global --hardmask is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --hardmask \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ idprefix

DESCRIPTION="--usearch_global --idprefix is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --idprefix 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --idprefix rejects matches where the first N nt of the target do not
## match the query
DESCRIPTION="--usearch_global --idprefix rejects mismatched prefix"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nTCGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --idprefix 1 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ idsuffix

DESCRIPTION="--usearch_global --idsuffix is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --idsuffix 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --idsuffix rejects matches where the last N nt of the target do not
## match the query
DESCRIPTION="--usearch_global --idsuffix rejects mismatched suffix"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --idsuffix 1 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- label_suffix

DESCRIPTION="--usearch_global --label_suffix appends the suffix to matched headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --label_suffix ";x=1" \
        --matched - \
        --quiet | \
    grep -qx ">q;x=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- lca_cutoff

DESCRIPTION="--usearch_global --lca_cutoff is accepted"
DB=$(mktemp)
printf ">d;tax=k:A\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --lca_cutoff 1.0 \
        --lcaout /dev/null \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --lca_cutoff 0.5 is rejected (must be greater than 0.5)"
DB=$(mktemp)
printf ">d;tax=k:A\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --lca_cutoff 0.5 \
        --lcaout /dev/null \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- lcaout

DESCRIPTION="--usearch_global --lcaout writes the taxonomic lineage"
DB=$(mktemp)
printf ">d;tax=k:Archaea\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --lcaout - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q" && $2 ~ /Archaea/) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ leftjust

DESCRIPTION="--usearch_global --leftjust accepts a flush-left alignment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --leftjust \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --leftjust rejects alignments that begin with gaps (query shorter
## than target at the 5' end)
DESCRIPTION="--usearch_global --leftjust rejects alignments starting with gaps"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --leftjust \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- lengthout

DESCRIPTION="--usearch_global --lengthout adds ;length=integer to headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --lengthout \
        --matched - \
        --quiet | \
    grep -qx ">q;length=40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- log

DESCRIPTION="--usearch_global --log writes the version line"
DB=$(mktemp)
LOG=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --log "${LOG}" \
        --blast6out /dev/null \
        --quiet
grep -q "vsearch" "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${LOG}"
unset DB LOG

## ------------------------------------------------------------------ matched

DESCRIPTION="--usearch_global --matched writes matching query sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --matched - \
        --quiet | \
    grep -qw ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- maxdiffs

DESCRIPTION="--usearch_global --maxdiffs is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxdiffs 0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --maxdiffs rejects matches with more than N substitutions,
## insertions, or deletions
DESCRIPTION="--usearch_global --maxdiffs 0 rejects a match with one mismatch"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACCTAACTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --maxdiffs 0 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ maxgaps

DESCRIPTION="--usearch_global --maxgaps is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxgaps 0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --maxgaps 0 rejects matches with internal gaps
DESCRIPTION="--usearch_global --maxgaps 0 rejects a match with an internal gap"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --maxgaps 0 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ maxhits

DESCRIPTION="--usearch_global --maxhits caps the number of reported hits"
DB=$(mktemp)
printf ">d1\n%s\n>d2\n%s\n" "${SEQ}" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxaccepts 10 \
        --maxhits 1 \
        --blast6out - \
        --quiet | \
    wc -l | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- maxid

DESCRIPTION="--usearch_global --maxid 1.0 accepts a full-identity match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxid 1.0 \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --maxid rejects matches above the upper identity limit
DESCRIPTION="--usearch_global --maxid 0.95 rejects a perfect match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --maxid 0.95 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- maxqsize

DESCRIPTION="--usearch_global --maxqsize is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --sizein \
        --maxqsize 10 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --maxqsize rejects queries with abundance greater than the limit
DESCRIPTION="--usearch_global --maxqsize rejects queries above the abundance limit"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=5\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --sizein \
        --maxqsize 2 \
        --blast6out - \
        --quiet | \
    grep -q "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- maxqt

DESCRIPTION="--usearch_global --maxqt is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxqt 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- maxseqlength

DESCRIPTION="--usearch_global --maxseqlength discards longer query sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxseqlength 10 \
        --blast6out - \
        --quiet 2> /dev/null | \
    grep -q "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- maxsizeratio

DESCRIPTION="--usearch_global --maxsizeratio is accepted"
DB=$(mktemp)
printf ">d;size=1\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --sizein \
        --maxsizeratio 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- maxsl

DESCRIPTION="--usearch_global --maxsl is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxsl 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ maxsubs

DESCRIPTION="--usearch_global --maxsubs is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxsubs 0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --maxsubs 0 rejects matches with any mismatches
DESCRIPTION="--usearch_global --maxsubs 0 rejects a match with one mismatch"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACCTAACTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --maxsubs 0 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- mid

DESCRIPTION="--usearch_global --mid is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --mid 0.9 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ mincols

DESCRIPTION="--usearch_global --mincols is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --mincols 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- minqt

DESCRIPTION="--usearch_global --minqt is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --minqt 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- minseqlength

DESCRIPTION="--usearch_global --minseqlength is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --minseqlength 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --minseqlength discards shorter query sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --minseqlength 100 \
        --blast6out - \
        --quiet 2> /dev/null | \
    grep -q "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- minsizeratio

DESCRIPTION="--usearch_global --minsizeratio is accepted"
DB=$(mktemp)
printf ">d;size=1\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --sizein \
        --minsizeratio 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- minsl

DESCRIPTION="--usearch_global --minsl is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --minsl 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- mintsize

DESCRIPTION="--usearch_global --mintsize is accepted"
DB=$(mktemp)
printf ">d;size=5\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --sizein \
        --mintsize 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --mintsize rejects target sequences with abundance below the limit
DESCRIPTION="--usearch_global --mintsize rejects low-abundance targets"
DB=$(mktemp)
printf ">d;size=2\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --sizein \
        --mintsize 10 \
        --blast6out - \
        --quiet | \
    grep -q "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- minwordmatches

DESCRIPTION="--usearch_global --minwordmatches is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --minwordmatches 0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------- mothur_shared_out

DESCRIPTION="--usearch_global --mothur_shared_out writes a header line"
DB=$(mktemp)
printf ">otu1\n%s\n" "${SEQ}" > "${DB}"
printf ">q1;sample=s1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --mothur_shared_out - \
        --quiet | \
    grep -q "^label" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ n_mismatch

DESCRIPTION="--usearch_global --n_mismatch is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --n_mismatch \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --n_mismatch counts alignments of nucleotides against Ns as
## mismatches; without it, Ns are counted neutrally (default behaviour
## for the default --iddef 2)
DESCRIPTION="--usearch_global --n_mismatch counts N as mismatch"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTNCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --n_mismatch \
        --userfields mism \
        --userout - \
        --quiet | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- no_progress

DESCRIPTION="--usearch_global --no_progress is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --no_progress \
        --blast6out /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- notmatched

DESCRIPTION="--usearch_global --notmatched writes non-matching queries"
DB=$(mktemp)
printf ">d\nCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCG\n" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.97 \
        --blast6out /dev/null \
        --notmatched - \
        --quiet | \
    grep -qw ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- notrunclabels

DESCRIPTION="--usearch_global --notrunclabels retains full query headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q extra words\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --notrunclabels \
        --matched - \
        --quiet | \
    grep -qx ">q extra words" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- otutabout

DESCRIPTION="--usearch_global --otutabout writes a tab-separated OTU table"
DB=$(mktemp)
printf ">otu1\n%s\n" "${SEQ}" > "${DB}"
printf ">q1;sample=s1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --otutabout - \
        --quiet | \
    head -n 1 | \
    grep -q "^#OTU ID" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------ output_no_hits

DESCRIPTION="--usearch_global --output_no_hits writes non-matching queries"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q\nCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCGCG\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --output_no_hits \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q" && $2 == "*") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- qsegout

DESCRIPTION="--usearch_global --qsegout writes the aligned query segment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out /dev/null \
        --qsegout - \
        --quiet | \
    grep -qw ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- query_cov

DESCRIPTION="--usearch_global --query_cov is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --query_cov 0.9 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- quiet

DESCRIPTION="--usearch_global --quiet suppresses messages on stderr"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ relabel

DESCRIPTION="--usearch_global --relabel renames matched sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --relabel "renamed" \
        --matched - \
        --quiet | \
    grep -qx ">renamed1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- relabel_keep

DESCRIPTION="--usearch_global --relabel_keep retains the old header after a space"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --relabel "renamed" \
        --relabel_keep \
        --matched - \
        --quiet | \
    grep -qx ">renamed1 q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- relabel_md5

DESCRIPTION="--usearch_global --relabel_md5 renames sequences with md5 digests"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --relabel_md5 \
        --matched - \
        --quiet | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- relabel_self

DESCRIPTION="--usearch_global --relabel_self is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --relabel_self \
        --matched /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- relabel_sha1

DESCRIPTION="--usearch_global --relabel_sha1 renames sequences with sha1 digests"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --relabel_sha1 \
        --matched - \
        --quiet | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --relabel and --relabel_md5 are mutually exclusive"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --relabel "renamed" \
        --relabel_md5 \
        --matched /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- rightjust

DESCRIPTION="--usearch_global --rightjust accepts a flush-right alignment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --rightjust \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --rightjust rejects alignments that end with gaps (query shorter
## than target at the 3' end)
DESCRIPTION="--usearch_global --rightjust rejects alignments ending with gaps"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGTACGTAC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --rightjust \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- rowlen

DESCRIPTION="--usearch_global --rowlen is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --alnout /dev/null \
        --rowlen 64 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- samheader

DESCRIPTION="--usearch_global --samheader adds @HD lines to --samout"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --samheader \
        --quiet | \
    grep -q "^@HD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- samout

## See vsearch-sam(5) for the SAM format produced by vsearch. A record
## has 11 mandatory tab-separated fields (QNAME, FLAG, RNAME, POS,
## MAPQ, CIGAR, RNEXT, PNEXT, TLEN, SEQ, QUAL) followed, for mapped
## queries, by 8 optional tags in order: AS, XN, XM, XO, XG, NM, MD,
## YT. Unmapped queries carry no optional tags.

DESCRIPTION="--usearch_global --samout writes a SAM record for a hit"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q" && $3 == "d") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## by default, a query with no hit produces no SAM record
DESCRIPTION="--usearch_global --samout produces no record for a query with no hit"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## no header is written unless --samheader is given
DESCRIPTION="--usearch_global --samout emits no header by default"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -q "^@" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## records are terminated by a single line feed, with no carriage return
DESCRIPTION="--usearch_global --samout lines do not end with a carriage return"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -q $'\r' && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## no trailing tabs are emitted after the last field of each record
DESCRIPTION="--usearch_global --samout does not emit trailing tabs"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -qE $'\t$' && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## a mapped record has 11 mandatory fields plus 8 optional tags (AS,
## XN, XM, XO, XG, NM, MD, YT): 19 tab-separated fields total
DESCRIPTION="--usearch_global --samout mapped record has 19 tab-separated fields"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit (NF == 19) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------ mandatory fields (perfect 40-nt forward-strand hit) ------

## field 1 (QNAME) is the query label as given in the input fasta
DESCRIPTION="--usearch_global --samout QNAME is the query label"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 2 (FLAG) is 0 for a forward-strand primary hit
DESCRIPTION="--usearch_global --samout FLAG is 0 for a forward-strand primary hit"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($2 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 3 (RNAME) is the reference label
DESCRIPTION="--usearch_global --samout RNAME is the reference label"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($3 == "d") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 4 (POS) is always 1 for a mapped query (global alignment)
DESCRIPTION="--usearch_global --samout POS is 1 for a mapped query"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($4 == "1") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 5 (MAPQ) is always 255 (mapping quality not available)
DESCRIPTION="--usearch_global --samout MAPQ is 255 (mapping quality not available)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($5 == "255") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 6 (CIGAR) uses only M for a 40-nt gapless perfect match
DESCRIPTION="--usearch_global --samout CIGAR is 40M for a 40-nt gapless perfect hit"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($6 == "40M") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 7 (RNEXT) is always * (vsearch does not output paired-end info)
DESCRIPTION="--usearch_global --samout RNEXT is * (paired-end not supported)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($7 == "*") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 8 (PNEXT) is always 0
DESCRIPTION="--usearch_global --samout PNEXT is 0 (paired-end not supported)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($8 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 9 (TLEN) is always 0
DESCRIPTION="--usearch_global --samout TLEN is 0 (paired-end not supported)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($9 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 10 (SEQ) holds the original query for a forward-strand hit
## (compared case-insensitively: dust masking can lowercase residues)
DESCRIPTION="--usearch_global --samout SEQ is the original query for a forward-strand hit"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' -v s="${SEQ}" '{exit (toupper($10) == toupper(s)) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## field 11 (QUAL) is always *
DESCRIPTION="--usearch_global --samout QUAL is * (not available)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($11 == "*") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------ CIGAR operations ------

## CIGAR uses I when the query has a base not present in the reference
DESCRIPTION="--usearch_global --samout CIGAR uses I for an insertion in the query"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTAACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($6 ~ /I/) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## CIGAR uses D when the query is missing a base present in the reference
DESCRIPTION="--usearch_global --samout CIGAR uses D for a deletion in the query"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($6 ~ /D/) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------ optional tags (perfect hit: AS, XN, XM, XO, XG, NM, MD, YT) ------

DESCRIPTION="--usearch_global --samout appends AS:i:100 for a perfect match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -qE $'\tAS:i:100(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## AS stores percent identity rounded to the nearest integer (not an
## aligner-specific score); 39 matches in 40 positions give AS:i:98
DESCRIPTION="--usearch_global --samout AS is the percent identity rounded (98 for 39/40)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTCCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout - \
        --quiet | \
    grep -qE $'\tAS:i:98(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --samout appends XN:i:0 (not computed by vsearch)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -qE $'\tXN:i:0(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --samout XM is 0 for a gapless perfect match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -qE $'\tXM:i:0(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --samout XM counts mismatches (1 for a single substitution)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTCCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout - \
        --quiet | \
    grep -qE $'\tXM:i:1(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --samout XO is 0 for a gapless match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -qE $'\tXO:i:0(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --samout XO counts gap opens (1 for a single insertion)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTAACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout - \
        --quiet | \
    grep -qE $'\tXO:i:1(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --samout XG is 0 for a gapless match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -qE $'\tXG:i:0(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --samout XG counts total internal gap length (1 for a single inserted base)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTAACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout - \
        --quiet | \
    grep -qE $'\tXG:i:1(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --samout NM is 0 for a perfect match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -qE $'\tNM:i:0(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## NM is the edit distance (sum of XM and XG); a single mismatch gives
## NM:i:1 (XM:i:1 + XG:i:0)
DESCRIPTION="--usearch_global --samout NM equals XM + XG (single mismatch gives NM:i:1)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTCCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout - \
        --quiet | \
    grep -qE $'\tNM:i:1(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --samout MD is Z:40 for a 40-nt gapless perfect match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -qE $'\tMD:Z:40(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## MD encodes a mismatch as <count><ref-base><count>; vsearch emits the
## reference base in lowercase when dust-masked (SAM manpage documents
## uppercase), so match case-insensitively
DESCRIPTION="--usearch_global --samout MD encodes a mismatch with the reference base"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTCCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout - \
        --quiet | \
    grep -iqE $'\tMD:Z:20A19(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## MD prefixes reference bases deleted from the query with a caret
DESCRIPTION="--usearch_global --samout MD prefixes deletions with a caret"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout - \
        --quiet | \
    grep -iqE $'\tMD:Z:20\\^A19(\t|$)' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## YT:Z:UU (bowtie2 alignment type) is the last tag of a mapped record
DESCRIPTION="--usearch_global --samout ends each mapped record with YT:Z:UU"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    grep -qE "YT:Z:UU$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## optional tags appear in the documented order: AS XN XM XO XG NM MD YT
DESCRIPTION="--usearch_global --samout optional tags appear in the documented order"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($12 ~ /^AS:/ && $13 ~ /^XN:/ && $14 ~ /^XM:/ && $15 ~ /^XO:/ && $16 ~ /^XG:/ && $17 ~ /^NM:/ && $18 ~ /^MD:/ && $19 ~ /^YT:/) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------ FLAG bits (0x010 for reverse strand, 0x100 for secondary) ------

## --strand both with a forward-strand hit keeps FLAG 0
DESCRIPTION="--usearch_global --samout --strand both forward-strand hit has FLAG 0"
DB=$(mktemp)
printf ">d\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" > "${DB}"
printf ">q\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --strand both \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($2 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --strand both with a reverse-complement hit sets flag bit 0x010
## (decimal 16)
DESCRIPTION="--usearch_global --samout --strand both reverse-strand hit has FLAG 16"
DB=$(mktemp)
printf ">d\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" > "${DB}"
printf ">q\nAAATTTTAAAAACCCCCGGGGGTTTTTGATCGATCGATCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.97 \
        --strand both \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit ($2 == "16") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## on a reverse-strand hit, SEQ holds the reverse complement of the
## original query (compared case-insensitively)
DESCRIPTION="--usearch_global --samout --strand both reverse-strand SEQ is the reverse complement of the original query"
DB=$(mktemp)
printf ">d\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" > "${DB}"
printf ">q\nAAATTTTAAAAACCCCCGGGGGTTTTTGATCGATCGATCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.97 \
        --strand both \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit (toupper($10) == "GGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## the first hit of a query is the primary alignment (flag bit 0x100
## cleared): FLAG is 0 with two equally-good forward-strand matches
DESCRIPTION="--usearch_global --samout primary alignment has flag bit 0x100 cleared"
DB=$(mktemp)
printf ">d1\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n>d2\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" > "${DB}"
printf ">q\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxaccepts 2 \
        --samout - \
        --quiet | \
    awk -F'\t' 'NR==1 {exit ($2 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## subsequent hits are secondary alignments (flag bit 0x100 set): FLAG
## is 256 when the secondary is on the forward strand
DESCRIPTION="--usearch_global --samout secondary alignment has flag bit 0x100 set"
DB=$(mktemp)
printf ">d1\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n>d2\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" > "${DB}"
printf ">q\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxaccepts 2 \
        --samout - \
        --quiet | \
    awk -F'\t' 'NR==2 {exit ($2 == "256") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------ unmapped queries (--output_no_hits) ------

## --output_no_hits emits a single record for a query with no hit
DESCRIPTION="--usearch_global --samout --output_no_hits emits a record for an unmapped query"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --output_no_hits \
        --samout - \
        --quiet 2> /dev/null | \
    awk -F'\t' '{exit ($1 == "q") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --output_no_hits unmapped record: FLAG is 4 (0x004 unmapped bit)
DESCRIPTION="--usearch_global --samout --output_no_hits sets FLAG to 4 for an unmapped query"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --output_no_hits \
        --samout - \
        --quiet 2> /dev/null | \
    awk -F'\t' '{exit ($2 == "4") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --output_no_hits unmapped record: RNAME is *
DESCRIPTION="--usearch_global --samout --output_no_hits sets RNAME to * for an unmapped query"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --output_no_hits \
        --samout - \
        --quiet 2> /dev/null | \
    awk -F'\t' '{exit ($3 == "*") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --output_no_hits unmapped record: POS is 0
DESCRIPTION="--usearch_global --samout --output_no_hits sets POS to 0 for an unmapped query"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --output_no_hits \
        --samout - \
        --quiet 2> /dev/null | \
    awk -F'\t' '{exit ($4 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --output_no_hits unmapped record: CIGAR is *
DESCRIPTION="--usearch_global --samout --output_no_hits sets CIGAR to * for an unmapped query"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --output_no_hits \
        --samout - \
        --quiet 2> /dev/null | \
    awk -F'\t' '{exit ($6 == "*") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --output_no_hits unmapped record: no optional tags (exactly 11 fields)
DESCRIPTION="--usearch_global --samout --output_no_hits emits no optional tags for an unmapped query"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --output_no_hits \
        --samout - \
        --quiet 2> /dev/null | \
    awk -F'\t' '{exit (NF == 11) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --output_no_hits unmapped record: SEQ holds the original query
DESCRIPTION="--usearch_global --samout --output_no_hits preserves the original query in SEQ"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --output_no_hits \
        --samout - \
        --quiet 2> /dev/null | \
    awk -F'\t' '{exit (toupper($10) == "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- sample

DESCRIPTION="--usearch_global --sample adds ;sample=string to headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --sample "ABC" \
        --matched - \
        --quiet | \
    grep -qx ">q;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- self

DESCRIPTION="--usearch_global --self rejects matches with identical labels"
DB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" > "${DB}"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --self \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- selfid

DESCRIPTION="--usearch_global --selfid rejects matches with identical sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --selfid \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- sizein

DESCRIPTION="--usearch_global --sizein is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=5\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --sizein \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ sizeout

DESCRIPTION="--usearch_global --sizeout adds ;size=1 to unannotated headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --sizeout \
        --matched - \
        --quiet | \
    grep -qx ">q;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- target_cov

DESCRIPTION="--usearch_global --target_cov is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --target_cov 0.9 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- top_hits_only

DESCRIPTION="--usearch_global --top_hits_only reports only the best-identity hits"
DB=$(mktemp)
printf ">d1\n%s\n>d2\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGC\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --maxaccepts 10 \
        --top_hits_only \
        --blast6out - \
        --quiet | \
    wc -l | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ tsegout

DESCRIPTION="--usearch_global --tsegout writes the aligned target segment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --blast6out /dev/null \
        --tsegout - \
        --quiet | \
    grep -qw ">d" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- uc_allhits

DESCRIPTION="--usearch_global --uc_allhits reports all hits per query"
DB=$(mktemp)
printf ">d1\n%s\n>d2\n%s\n" "${SEQ}" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --maxaccepts 10 \
        --uc - \
        --uc_allhits \
        --quiet | \
    awk -F'\t' '$1 == "H"' | \
    wc -l | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- weak_id

DESCRIPTION="--usearch_global --weak_id is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.99 \
        --weak_id 0.5 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --weak_id reports hits below --id that still clear --weak_id
DESCRIPTION="--usearch_global --weak_id reports a weak hit"
DB=$(mktemp)
printf ">d\nACGTACGTACGTACGTACCTAACTACGTACGTACGTACGT\n" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --weak_id 0.5 \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- wordlength

## wordlength 15 requires too much memory
for LEN in 3 8 ; do
    DESCRIPTION="--usearch_global --wordlength ${LEN} is accepted"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --usearch_global - \
            --db "${DB}" \
            --id 1.0 \
            --wordlength "${LEN}" \
            --blast6out /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset LEN

DESCRIPTION="--usearch_global --wordlength 2 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --wordlength 2 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--usearch_global --wordlength 16 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --wordlength 16 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- xee

DESCRIPTION="--usearch_global --xee strips ;ee=float from headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;ee=0.5\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --xee \
        --matched - \
        --quiet | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- xlength

DESCRIPTION="--usearch_global --xlength strips ;length=integer from headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;length=40\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --xlength \
        --matched - \
        --quiet | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- xsize

DESCRIPTION="--usearch_global --xsize strips ;size=integer from headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=3\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --xsize \
        --matched - \
        --quiet | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                                 userfields                                  #
#                                                                             #
#*****************************************************************************#

## --userfields selects the fields written to --userout; here, the
## three-column output matches the expected values for an exact full-
## length match of a 40-nt sequence
DESCRIPTION="--usearch_global --userfields restricts --userout fields"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields "query+target+id" \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q" && $2 == "d" && $3 == "100.0" && NF == 3) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## alignment representation ----------------------------------------------- aln

## for a 40-nt exact match, aln is 40 M characters
DESCRIPTION="--usearch_global --userfields aln reports matches as M"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields aln \
        --quiet | \
    grep -qx "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- caln

DESCRIPTION="--usearch_global --userfields caln reports CIGAR string"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields caln \
        --quiet | \
    grep -qx "40M\|=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- qrow

DESCRIPTION="--usearch_global --userfields qrow reports the aligned query"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields qrow \
        --quiet | \
    grep -qix "${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- trow

DESCRIPTION="--usearch_global --userfields trow reports the aligned target"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields trow \
        --quiet | \
    grep -qix "${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## query and target identifiers ------------------------------------------ query

DESCRIPTION="--usearch_global --userfields query reports the query label"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields query \
        --quiet | \
    grep -qx "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- target

DESCRIPTION="--usearch_global --userfields target reports the target label"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields target \
        --quiet | \
    grep -qx "d" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## sequence lengths -------------------------------------------------------- ql

DESCRIPTION="--usearch_global --userfields ql reports the query length"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields ql \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------------- tl

DESCRIPTION="--usearch_global --userfields tl reports the target length"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields tl \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------------- qs

DESCRIPTION="--usearch_global --userfields qs reports the query segment length"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields qs \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------------- ts

DESCRIPTION="--usearch_global --userfields ts reports the target segment length"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields ts \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## alignment span --------------------------------------------------------- qlo

DESCRIPTION="--usearch_global --userfields qlo reports the first aligned query position"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields qlo \
        --quiet | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------------- qhi

DESCRIPTION="--usearch_global --userfields qhi reports the last aligned query position"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields qhi \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- qilo

DESCRIPTION="--usearch_global --userfields qilo reports the first aligned query position (no terminal gaps)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields qilo \
        --quiet | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- qihi

DESCRIPTION="--usearch_global --userfields qihi reports the last aligned query position (no terminal gaps)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields qihi \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------------- tlo

DESCRIPTION="--usearch_global --userfields tlo reports the first aligned target position"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields tlo \
        --quiet | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------------- thi

DESCRIPTION="--usearch_global --userfields thi reports the last aligned target position"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields thi \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- tilo

DESCRIPTION="--usearch_global --userfields tilo reports the first aligned target position (no terminal gaps)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields tilo \
        --quiet | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- tihi

DESCRIPTION="--usearch_global --userfields tihi reports the last aligned target position (no terminal gaps)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields tihi \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## alignment statistics ------------------------------------------------- alnlen

DESCRIPTION="--usearch_global --userfields alnlen reports the alignment length"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields alnlen \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------------- ids

DESCRIPTION="--usearch_global --userfields ids reports the number of matching columns"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields ids \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- mism

DESCRIPTION="--usearch_global --userfields mism reports the number of mismatches"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields mism \
        --quiet | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- gaps

DESCRIPTION="--usearch_global --userfields gaps reports zero for a gapless alignment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields gaps \
        --quiet | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- opens

DESCRIPTION="--usearch_global --userfields opens reports zero for a gapless alignment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields opens \
        --quiet | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- exts

DESCRIPTION="--usearch_global --userfields exts reports zero for a gapless alignment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields exts \
        --quiet | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- pairs

DESCRIPTION="--usearch_global --userfields pairs reports the number of non-gap columns"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields pairs \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------------- pv

DESCRIPTION="--usearch_global --userfields pv reports the number of positive columns"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields pv \
        --quiet | \
    grep -qx "40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ pctgaps

DESCRIPTION="--usearch_global --userfields pctgaps reports 0.0 for a gapless alignment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields pctgaps \
        --quiet | \
    grep -qx "0.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- pctpv

DESCRIPTION="--usearch_global --userfields pctpv reports 100.0 for a full match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields pctpv \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## identity percentages -------------------------------------------------- id

DESCRIPTION="--usearch_global --userfields id reports 100.0 for a full match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields id \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- id0

DESCRIPTION="--usearch_global --userfields id0 reports 100.0 for a full match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields id0 \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- id1

DESCRIPTION="--usearch_global --userfields id1 reports 100.0 for a full match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields id1 \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- id2

DESCRIPTION="--usearch_global --userfields id2 reports 100.0 for a full match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields id2 \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- id3

DESCRIPTION="--usearch_global --userfields id3 reports 100.0 for a full match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields id3 \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- id4

DESCRIPTION="--usearch_global --userfields id4 reports 100.0 for a full match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields id4 \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## coverage -------------------------------------------------------------- qcov

DESCRIPTION="--usearch_global --userfields qcov reports 100.0 for a full match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields qcov \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- tcov

DESCRIPTION="--usearch_global --userfields tcov reports 100.0 for a full match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields tcov \
        --quiet | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## score ---------------------------------------------------------------- raw

## with default --match 2 and an exact 40-nt match, the raw score is 80
DESCRIPTION="--usearch_global --userfields raw reports the raw alignment score"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields raw \
        --quiet | \
    grep -qx "80" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- bits

## --bits is not computed for nucleotide alignments (always 0)
DESCRIPTION="--usearch_global --userfields bits is always 0 for nucleotides"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields bits \
        --quiet | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- evalue

## --evalue is not computed for nucleotide alignments (always -1)
DESCRIPTION="--usearch_global --userfields evalue is always -1 for nucleotides"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields evalue \
        --quiet | \
    grep -qx "\-1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## strand -------------------------------------------------------------- qstrand

DESCRIPTION="--usearch_global --userfields qstrand is + for a plus-strand match"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields qstrand \
        --quiet | \
    grep -qx "+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ tstrand

DESCRIPTION="--usearch_global --userfields tstrand is always +"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields tstrand \
        --quiet | \
    grep -qx "+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --tstrand is + and qstrand is - for a reverse-complement match
DESCRIPTION="--usearch_global --userfields qstrand is - for a reverse-strand match"
DB=$(mktemp)
printf ">d\nGGATCGATCGATCAAAAACCCCCGGGGGTTTTTAAAATTT\n" > "${DB}"
printf ">q\nAAATTTTAAAAACCCCCGGGGGTTTTTGATCGATCGATCC\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.97 \
        --strand both \
        --userout - \
        --userfields "qstrand+tstrand" \
        --quiet | \
    awk -F'\t' '{exit ($1 == "-" && $2 == "+") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## unused fields ------------------------------------------------------- qframe

## --qframe is always +0 (not computed for nucleotide alignments)
DESCRIPTION="--usearch_global --userfields qframe is always +0"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields qframe \
        --quiet | \
    grep -qx "+0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- tframe

## --tframe is always +0 (not computed for nucleotide alignments)
DESCRIPTION="--usearch_global --userfields tframe is always +0"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout - \
        --userfields tframe \
        --quiet | \
    grep -qx "+0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --userfields rejects unknown field names
DESCRIPTION="--usearch_global --userfields rejects unknown field"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --userout /dev/null \
        --userfields "nosuchfield" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                       pairwise alignment options                            #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------------- match

DESCRIPTION="--usearch_global --match is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --match 2 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --match affects the raw alignment score
DESCRIPTION="--usearch_global --match changes the raw score"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --match 3 \
        --userout - \
        --userfields raw \
        --quiet | \
    grep -qx "120" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- mismatch

DESCRIPTION="--usearch_global --mismatch is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --mismatch -4 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- gapopen

DESCRIPTION="--usearch_global --gapopen is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --gapopen 20 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- gapext

DESCRIPTION="--usearch_global --gapext is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 1.0 \
        --gapext 2 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## options accepted for compatibility with usearch, but with no effect.
## vsearch should accept them (exit 0) and emit a warning to stderr.
for OPT_PAIR in "--band 16" "--fulldp" "--hspw 5" "--minhsp 3" \
                "--pattern xxx" "--slots 1024" "--xdrop_nw 32" ; do
    OPT_NAME="${OPT_PAIR%% *}"
    DESCRIPTION="--usearch_global accepts ${OPT_NAME} (ignored)"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    # shellcheck disable=SC2086
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --usearch_global - \
            --db "${DB}" \
            --id 1.0 \
            ${OPT_PAIR} \
            --blast6out /dev/null \
            --quiet 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB

    DESCRIPTION="--usearch_global ${OPT_NAME} emits an ignored warning"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    # shellcheck disable=SC2086
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --usearch_global - \
            --db "${DB}" \
            --id 1.0 \
            ${OPT_PAIR} \
            --blast6out /dev/null 2>&1 >/dev/null | \
        grep -qi "ignored" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset OPT_PAIR OPT_NAME


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## options that users might expect to work with --usearch_global but
## that do not apply to it
for OPT_PAIR in "--cluster_fast /dev/null" "--cluster_size /dev/null" \
                "--eeout" "--fastq_qmax 41" "--fastq_qmin 0" \
                "--fastq_ascii 33" "--fastqout /dev/null" ; do
    OPT_NAME="${OPT_PAIR%% *}"
    DESCRIPTION="--usearch_global rejects ${OPT_NAME}"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    # shellcheck disable=SC2086
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --usearch_global - \
            --db "${DB}" \
            --id 1.0 \
            ${OPT_PAIR} \
            --blast6out /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset OPT_PAIR OPT_NAME


## clean up common variables before the memory leaks section
unset SEQ


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    ## memory leak in userfields: fixed in d83bfee9
    LOG=$(mktemp)
    FASTA=$(mktemp)
    DB=$(mktemp)
    printf ">s\nA\n" > "${FASTA}"
    printf ">s\nA\n" > "${DB}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        "${VSEARCH}" \
        --usearch_global "${FASTA}" \
        --db "${DB}" \
        --minseqlength 1 \
        --id 0.5 \
        --alnout /dev/null \
        --biomout /dev/null \
        --blast6out /dev/null \
        --dbmatched /dev/null \
        --dbnotmatched /dev/null \
        --fastapairs /dev/null \
        --lcaout /dev/null \
        --log /dev/null \
        --matched /dev/null \
        --mothur_shared_out /dev/null \
        --notmatched /dev/null \
        --otutabout /dev/null \
        --samout /dev/null \
        --strand both \
        --uc /dev/null \
        --userout /dev/null \
        --userfields query+target+evalue+id+pctpv+pctgaps+pairs+gaps+qlo+qhi+tlo+thi+pv+ql+tl+qs+ts+alnlen+opens+exts+raw+bits+aln+caln+qstrand+tstrand+qrow+trow+qframe+tframe+mism+ids+qcov+tcov+id0+id1+id2+id3+id4+qilo+qihi+tilo+tihi 2> /dev/null
    DESCRIPTION="--usearch_global valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--usearch_global valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTA}" "${DB}"
fi


exit 0
