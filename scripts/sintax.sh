#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="sintax"
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

## vsearch --sintax fastafile --db fastafile --tabbedout outputfile
## [--sintax_cutoff real] [options]

## test sequences:
## SEQ is a 50-nt sequence producing 43 possible 8-mers (>= 32 = subset_size)
## -> should be classified when it matches the DB
## SHORT is a 37-nt sequence producing 30 possible 8-mers (< 32 = subset_size)
## -> unclassified (too few unique k-mers for bootstrap)
## RCSEQ is the reverse complement of SEQ
## -> used to test minus-strand classification with --strand both

## --sintax is accepted
DESCRIPTION="--sintax is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --sintax reads from stdin (-)
DESCRIPTION="--sintax reads from stdin (-)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --sintax reads from a file
DESCRIPTION="--sintax reads from a file"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
QUERY=$(mktemp)
printf ">q\n%s\n" "${SEQ}" > "${QUERY}"
"${VSEARCH}" \
    --sintax "${QUERY}" \
    --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
    --tabbedout /dev/null \
    --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${QUERY}"
unset SEQ QUERY

## --sintax fails if query file does not exist
DESCRIPTION="--sintax fails if query file does not exist"
"${VSEARCH}" \
    --sintax /no/such/file \
    --db /dev/null \
    --tabbedout /dev/null \
    --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --sintax fails if query file is not readable
DESCRIPTION="--sintax fails if query file is not readable"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
QUERY=$(mktemp)
printf ">q\n%s\n" "${SEQ}" > "${QUERY}"
chmod u-r "${QUERY}"
"${VSEARCH}" \
    --sintax "${QUERY}" \
    --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
    --tabbedout /dev/null \
    --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${QUERY}" && rm -f "${QUERY}"
unset SEQ QUERY

## --sintax fails without --db
DESCRIPTION="--sintax fails without --db"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

## --sintax fails without --tabbedout
DESCRIPTION="--sintax fails without --tabbedout"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

## --db is accepted
DESCRIPTION="--db is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
DB=$(mktemp)
printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db "${DB}" \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset SEQ DB

## --db fails if db file does not exist
DESCRIPTION="--db fails if db file does not exist"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db /no/such/file \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

## --db fails if db file is not readable
DESCRIPTION="--db fails if db file is not readable"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
DB=$(mktemp)
printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}" > "${DB}"
chmod u-r "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db "${DB}" \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${DB}" && rm -f "${DB}"
unset SEQ DB

## --db accepts a UDB format database
DESCRIPTION="--db accepts a UDB format database"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
DB_FASTA=$(mktemp)
DB_UDB=$(mktemp)
printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}" > "${DB_FASTA}"
"${VSEARCH}" \
    --makeudb_usearch "${DB_FASTA}" \
    --output "${DB_UDB}" \
    --quiet 2>/dev/null
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db "${DB_UDB}" \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB_FASTA}" "${DB_UDB}"
unset SEQ DB_FASTA DB_UDB

## --db with UDB format classifies correctly
DESCRIPTION="--db with UDB format classifies correctly"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
DB_FASTA=$(mktemp)
DB_UDB=$(mktemp)
printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}" > "${DB_FASTA}"
"${VSEARCH}" \
    --makeudb_usearch "${DB_FASTA}" \
    --output "${DB_UDB}" \
    --quiet 2>/dev/null
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db "${DB_UDB}" \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 !~ /d:Bacteria/)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB_FASTA}" "${DB_UDB}"
unset SEQ DB_FASTA DB_UDB

## --tabbedout is accepted
DESCRIPTION="--tabbedout is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --tabbedout fails if output file cannot be written
DESCRIPTION="--tabbedout fails if output file cannot be written"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
OUTPUT_DIR=$(mktemp -d)
chmod u-w "${OUTPUT_DIR}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout "${OUTPUT_DIR}/output.tsv" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${OUTPUT_DIR}" && rm -rf "${OUTPUT_DIR}"
unset SEQ OUTPUT_DIR


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## output has 3 tab-separated columns without --sintax_cutoff
DESCRIPTION="--sintax output has 3 tab-separated columns (no --sintax_cutoff)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit (NF != 3)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## column 1 is the query label
DESCRIPTION="--sintax output column 1 is the query label"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">query1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($1 != "query1")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## column 2 contains taxonomy with bootstrap confidence values
DESCRIPTION="--sintax output column 2 contains taxonomy with confidence values"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 !~ /^[a-z]:[^(]+\([0-9.]+\)/)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## column 3 is '+' for a plus-strand match (default)
DESCRIPTION="--sintax output column 3 is '+' (plus strand, default)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($3 != "+")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## one output line per query
DESCRIPTION="--sintax writes one output line per query"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk 'END {exit (NR != 1)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## two queries → two output lines
DESCRIPTION="--sintax writes one output line per query (two queries)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q1\n%s\n>q2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk 'END {exit (NR != 2)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## a query with fewer than 32 unique k-mers is unclassified (empty taxonomy column)
## (37-nt sequence -> 30 possible 8-mers < 32 = subset_size, so no bootstrap runs)
DESCRIPTION="--sintax short query with < 32 unique k-mers is unclassified"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
SHORT="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAG"
printf ">q\n%s\n" "${SHORT}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 != "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ SHORT

## classified/total count is reported to stderr
DESCRIPTION="--sintax reports classified count to stderr"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null 2>&1 | \
    grep -qi "classified" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## empty query file produces no output lines
DESCRIPTION="--sintax empty query produces no output"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf "" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk 'END {exit (NR != 0)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## empty query file: classified count reports "0 of 0"
DESCRIPTION="--sintax empty query reports 0 of 0 classified"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf "" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null 2>&1 | \
    grep -q "0 of 0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## fastq query input is classified correctly
DESCRIPTION="--sintax classifies fastq query correctly"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
QUAL=$(printf 'I%.0s' $(seq 1 50))
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 == "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

## all 9 taxonomy levels are reported
DESCRIPTION="--sintax reports all 9 taxonomy levels"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:D,k:K,p:P,c:C,o:O,f:F,g:G,s:S,t:T\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 !~ /d:D.*k:K.*p:P.*c:C.*o:O.*f:F.*g:G.*s:S.*t:T/)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## DB header without ;tax= field: query gets empty taxonomy
DESCRIPTION="--sintax DB without ;tax= produces empty taxonomy"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s_no_taxonomy\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 != "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --sintax_cutoff is accepted
DESCRIPTION="--sintax_cutoff is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --sintax_cutoff 0.8 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --sintax_cutoff adds a 4th column to the output
DESCRIPTION="--sintax_cutoff adds a 4th column (filtered taxonomy)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --sintax_cutoff 0.8 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit (NF != 4)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --sintax_cutoff 0.0 is treated as no cutoff (column 4 absent; opt_sintax_cutoff > 0.0)
DESCRIPTION="--sintax_cutoff 0.0 produces 3 columns (treated as no cutoff)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --sintax_cutoff 0.0 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit (NF != 3)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --sintax_cutoff 0.01 includes all ranks in column 4 (all pass threshold 0.01)
DESCRIPTION="--sintax_cutoff 0.01 includes all classified ranks in column 4"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --sintax_cutoff 0.01 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($4 == "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --sintax_cutoff 1.0 with 100% confidence includes ranks in column 4
DESCRIPTION="--sintax_cutoff 1.0 includes ranks with 100% bootstrap support in column 4"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --sintax_cutoff 1.0 \
        --randseed 1 \
        --threads 1 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($4 == "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## column 4 (filtered taxonomy) contains no confidence values (no parentheses)
DESCRIPTION="--sintax column 4 (filtered taxonomy) has no confidence values"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --sintax_cutoff 0.01 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($4 ~ /\(/)}'  && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## unclassified query + --sintax_cutoff: output has 4 fields (all empty after label)
DESCRIPTION="--sintax_cutoff unclassified query produces 4-column output"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
SHORT="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAG"
printf ">q\n%s\n" "${SHORT}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --sintax_cutoff 0.8 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit (NF != 4)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ SHORT

## --sintax_cutoff with a negative value is rejected
DESCRIPTION="--sintax_cutoff rejects negative value"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --sintax_cutoff -0.1 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

## --sintax_cutoff 0.99 filters ranks with less than 99% bootstrap support
## with multiple DB entries and different taxonomies, some ranks may have
## less than full support and be excluded from column 4
DESCRIPTION="--sintax_cutoff 0.99 can exclude low-confidence ranks from column 4"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
DB=$(mktemp)
printf ">s1;tax=d:Bacteria,p:Proteo,c:Gamma\n%s\n" "${SEQ}" > "${DB}"
printf ">s2;tax=d:Bacteria,p:Proteo,c:Alpha\n%s\n" "${SEQ}" >> "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db "${DB}" \
        --sintax_cutoff 0.99 \
        --sintax_random \
        --randseed 1 \
        --threads 1 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit (NF != 4)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset SEQ DB

## --sintax_random is accepted
DESCRIPTION="--sintax_random is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --sintax_random \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --sintax_random breaks ties between DB sequences with equal k-mer counts
DESCRIPTION="--sintax_random exercises random tie-breaking with equal k-mer DB seqs"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s1;tax=d:Archaea\n%s\n>s2;tax=d:Bacteria\n%s\n" "${SEQ}" "${SEQ}") \
        --sintax_random \
        --randseed 1 \
        --threads 1 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 == "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## default tie-breaking prefers the earlier DB sequence when same length
DESCRIPTION="--sintax default tie-breaking prefers earlier DB sequence (same length)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
DB=$(mktemp)
printf ">first;tax=d:Archaea\n%s\n>second;tax=d:Bacteria\n%s\n" "${SEQ}" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db "${DB}" \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 !~ /d:Archaea/)}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset SEQ DB

## --strand plus is accepted
DESCRIPTION="--strand plus is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --strand plus \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --strand both is accepted
DESCRIPTION="--strand both is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --strand both \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --strand both: plus strand match is reported as '+'
DESCRIPTION="--strand both reports '+' for plus-strand match"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --strand both \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($3 != "+")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --strand both: minus strand match is reported as '-'
## RCSEQ is the reverse complement of SEQ; it matches the DB only on the minus strand
DESCRIPTION="--strand both reports '-' for minus-strand match"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
RCSEQ="GTAATTCCGATTAACGCTTGCACCCTCCGTATTACCGCGGCTGCTGGCAC"
printf ">q\n%s\n" "${RCSEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --strand both \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($3 != "-")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ RCSEQ

## --strand both with palindromic query: equal score on both strands defaults to '+'
## PALSEQ is an 80-nt palindrome (equal to its own reverse complement, 71 unique 8-mers)
DESCRIPTION="--strand both with palindromic query defaults to plus strand"
PALSEQ="ATGCTAGCAACTTGGCCAATCGGTAACCTTGGAATCGCTATAGCGATTCCAAGGTTACCGATTGGCCAAGTTGCTAGCAT"
printf ">q\n%s\n" "${PALSEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${PALSEQ}") \
        --strand both \
        --randseed 1 \
        --threads 1 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($3 != "+")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset PALSEQ

## --strand minus is rejected (only plus and both are valid)
DESCRIPTION="--strand minus is rejected"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --strand minus \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

## --randseed is accepted
DESCRIPTION="--randseed is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --randseed 42 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --randseed 0 is accepted (use pseudo-random seed)
DESCRIPTION="--randseed 0 is accepted (pseudo-random seed)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --randseed 0 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --randseed combined with --threads 1 gives reproducible results
DESCRIPTION="--randseed + --threads 1 gives reproducible results"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
DB=$(mktemp)
TABBEDOUT1=$(mktemp)
TABBEDOUT2=$(mktemp)
printf ">s;tax=d:Bacteria,p:Proteobacteria,c:Gamma,o:Entero,f:Fam,g:Gen,s:Spe\n%s\n" \
    "${SEQ}" > "${DB}"
printf ">q1\n%s\n>q2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db "${DB}" \
        --randseed 42 \
        --threads 1 \
        --tabbedout "${TABBEDOUT1}" \
        --quiet 2>/dev/null
printf ">q1\n%s\n>q2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db "${DB}" \
        --randseed 42 \
        --threads 1 \
        --tabbedout "${TABBEDOUT2}" \
        --quiet 2>/dev/null
diff -q "${TABBEDOUT1}" "${TABBEDOUT2}" > /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${TABBEDOUT1}" "${TABBEDOUT2}"
unset SEQ DB TABBEDOUT1 TABBEDOUT2

## --threads is accepted
DESCRIPTION="--threads is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --threads 2 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --threads 1 is accepted
DESCRIPTION="--threads 1 is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --threads 1 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --dbmask none is accepted
DESCRIPTION="--dbmask none is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --dbmask none \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --dbmask dust is accepted
DESCRIPTION="--dbmask dust is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --dbmask dust \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --dbmask soft is accepted
DESCRIPTION="--dbmask soft is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --dbmask soft \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --wordlength is accepted (uses default value of 8)
DESCRIPTION="--wordlength is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --wordlength 8 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --wordlength 3 is accepted (minimum value)
DESCRIPTION="--wordlength 3 is accepted (minimum)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --wordlength 3 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## test requires too much RAM
# ## --wordlength 15 is accepted (maximum value)
# DESCRIPTION="--wordlength 15 is accepted (maximum)"
# SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
# printf ">q\n%s\n" "${SEQ}" | \
#     "${VSEARCH}" \
#         --sintax - \
#         --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
#         --wordlength 15 \
#         --tabbedout /dev/null \
#         --quiet 2>/dev/null && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"
# unset SEQ

## --wordlength 2 is rejected (below the minimum of 3)
DESCRIPTION="--wordlength 2 is rejected (below minimum of 3)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --wordlength 2 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

## --wordlength 16 is rejected (above the maximum of 15)
DESCRIPTION="--wordlength 16 is rejected (above maximum of 15)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --wordlength 16 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --bzip2_decompress: bzip2-compressed query file is auto-detected and classified
## Note: --bzip2_decompress with stdin pipe fails when --db is also present
## (Fatal error: Unable to read from bzip2 compressed file); testing file
## auto-detection instead
DESCRIPTION="--sintax accepts bzip2-compressed query file (auto-detection)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
QUERY=$(mktemp)
printf ">q\n%s\n" "${SEQ}" | bzip2 > "${QUERY}.bz2"
"${VSEARCH}" \
    --sintax "${QUERY}.bz2" \
    --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
    --tabbedout /dev/null \
    --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${QUERY}" "${QUERY}.bz2"
unset SEQ QUERY

## --gzip_decompress is accepted (with actual gzip-compressed input pipe)
DESCRIPTION="--gzip_decompress is accepted (gzip-compressed stdin)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | gzip | \
    "${VSEARCH}" \
        --sintax - \
        --gzip_decompress \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --gzip_decompress reads gzip-compressed input and classifies correctly
DESCRIPTION="--gzip_decompress classifies gzip-compressed query correctly"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | gzip | \
    "${VSEARCH}" \
        --sintax - \
        --gzip_decompress \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 == "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --fastq_ascii is accepted (with fastq query)
DESCRIPTION="--fastq_ascii is accepted (with fastq query)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --fastq_ascii 33 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

## --fastq_ascii 33 is accepted
DESCRIPTION="--fastq_ascii 33 is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --fastq_ascii 33 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

## --fastq_ascii 64 is accepted
DESCRIPTION="--fastq_ascii 64 is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
## quality scores for offset 64 (ASCII 64 + 0 = '@' = minimum quality)
QUAL="@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --fastq_ascii 64 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

## --fastq_ascii 50 is rejected (only 33 or 64 allowed)
DESCRIPTION="--fastq_ascii 50 is rejected"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --fastq_ascii 50 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ QUAL

## --fastq_qmax is accepted (with fastq query)
DESCRIPTION="--fastq_qmax is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --fastq_qmax 41 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

## --fastq_qmin is accepted (with fastq query)
DESCRIPTION="--fastq_qmin is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --fastq_qmin 0 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

## --label_suffix is accepted (does not affect --tabbedout output)
DESCRIPTION="--label_suffix is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --label_suffix ";modified" \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --label_suffix does not alter query label in tabbedout output
DESCRIPTION="--label_suffix does not alter query label in tabbedout"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">query1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --label_suffix ";modified" \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($1 != "query1")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --log is accepted
DESCRIPTION="--log is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
LOG=$(mktemp)
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --log "${LOG}" \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${LOG}"
unset SEQ LOG

## --log contains the classified/total count
DESCRIPTION="--log contains classified count"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
LOG=$(mktemp)
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --log "${LOG}" \
        --tabbedout /dev/null \
        --quiet 2>/dev/null
grep -qi "classified" "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${LOG}"
unset SEQ LOG

## --maxseqlength is accepted
DESCRIPTION="--maxseqlength is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --maxseqlength 50000 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --maxseqlength discards long DB sequences (query is unclassified when DB is empty)
DESCRIPTION="--maxseqlength discards DB sequences above the threshold"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
## maxseqlength=49 discards the 50-nt DB sequence, leaving an empty DB
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --maxseqlength 49 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 != "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --minseqlength is accepted
DESCRIPTION="--minseqlength is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --minseqlength 1 \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --minseqlength discards short DB sequences (query is unclassified when DB is empty)
DESCRIPTION="--minseqlength discards DB sequences below the threshold"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
## DB has a 20-nt sequence; default minseqlength=32 discards it
DB_SHORT="GTGCCAGCAGCCGCGGTAAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${DB_SHORT}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 != "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ DB_SHORT

## --minseqlength 1 allows short DB sequences that would otherwise be discarded
DESCRIPTION="--minseqlength 1 allows short DB sequences"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
## DB has a 20-nt sequence; with --minseqlength 1 it is kept and query is classified
DB_SHORT="GTGCCAGCAGCCGCGGTAAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${DB_SHORT}") \
        --minseqlength 1 \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($2 == "")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ DB_SHORT

## --no_progress is accepted
DESCRIPTION="--no_progress is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --no_progress \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --notrunclabels is on by default for --sintax (headers with spaces are preserved)
DESCRIPTION="--notrunclabels is on by default (header with space is preserved)"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">query with spaces\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/stdout \
        --quiet 2>/dev/null | \
    awk -F'\t' 'NR == 1 {exit ($1 != "query with spaces")}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --notrunclabels is accepted explicitly
DESCRIPTION="--notrunclabels is accepted"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">query with spaces\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --notrunclabels \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --quiet suppresses the classified count message on stderr
DESCRIPTION="--quiet suppresses the classified count on stderr"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null \
        --quiet 2>&1 | \
    grep -qi "classified" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## --uc is not a valid option for --sintax
DESCRIPTION="--uc is not a valid option for --sintax"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null \
        --uc /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

## --matched is not a valid option for --sintax
DESCRIPTION="--matched is not a valid option for --sintax"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null \
        --matched /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

## --notmatched is not a valid option for --sintax
DESCRIPTION="--notmatched is not a valid option for --sintax"
SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAATCGGAATTAC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --sintax - \
        --db <(printf ">s;tax=d:Bacteria,p:Proteobacteria\n%s\n" "${SEQ}") \
        --tabbedout /dev/null \
        --notmatched /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    SEQ="GTGCCAGCAGCCGCGGTAATACGGAGGGTGCAAGCGTTAA"  # 39 nt
    LOG=$(mktemp)
    QUERY=$(mktemp)
    DB=$(mktemp)
    printf ">q\n%s\n" "${SEQ}" > "${QUERY}"
    printf ">s;tax=d:d,p:p,c:c,o:o,f:f,g:g,s:s,t:t\n%s\n" "${SEQ}" > "${DB}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --sintax "${QUERY}" \
        --db "${DB}" \
        --minseqlength 1 \
        --tabbedout /dev/null \
        --strand both \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--sintax valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--sintax valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${QUERY}" "${DB}"
    unset SEQ LOG QUERY DB DESCRIPTION
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#

## Manpage discrepancies found during test development (need human review):
##
## 2. --bzip2_decompress with stdin pipe fails when --db is also present:
##    "Fatal error: Unable to read from bzip2 compressed file" (exit 1).
##    The same option works correctly for --fastx_revcomp and --fastx_mask.
##    The bzip2 auto-detection from files works fine. This may be a bug.
##

## To Do List:
##
## - make a script to transform silva (use silva slv tax), Unite,
##   GreenGenes and the barcode of life into a format usable by sintax,
## - test if results are subject-order dependent (users should be able
##   to use a fix seed).

exit 0
