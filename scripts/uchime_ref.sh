#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="uchime_ref"
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

## valgrind is only useful here if it can actually run the binary under
## test. When it dies before reaching main -- a uprobe on the dynamic
## loader does that, and so does a sanitizer-instrumented binary -- it
## still reports "ERROR SUMMARY: 0 errors" and "in use at exit: 0
## bytes", which would silently turn every valgrind check below into a
## pass. Probe it once here, so those checks are skipped, not passed.
VALGRIND_WORKS=false
if which valgrind > /dev/null 2>&1 ; then
    VALGRIND_PROBE=$(valgrind "${VSEARCH}" --version 2>&1)
    [[ "${VALGRIND_PROBE}" == *"ERROR SUMMARY"* && \
       "${VALGRIND_PROBE}" != *"Process terminating"* ]] && \
        VALGRIND_WORKS=true
    unset VALGRIND_PROBE
fi


## vsearch --uchime_ref fastafile (--chimeras | --nonchimeras |
## --uchimealns | --uchimeout) outputfile --db fastafile [options]

## Test sequences used across the script: two parent amplicons are
## placed in the reference database, and a chimera made of the
## beginning of parentA and the end of parentB is used as the query.
##        1...5...10...15...20...25...30...35
A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"
B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
A_END=$(rev <<< "${A_START}")
B_END=$(rev <<< "${B_START}")
PARENT_A="${A_START}${A_END}"
PARENT_B="${B_START}${B_END}"
CHIMERA_AB="${A_START}${B_END}"


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--uchime_ref is accepted"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref reads query from stdin (-)"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref reads query from a regular file"
DB=$(mktemp)
QUERY=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" > "${QUERY}"
"${VSEARCH}" \
    --uchime_ref "${QUERY}" \
    --db "${DB}" \
    --quiet \
    --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERY}"
unset DB QUERY

DESCRIPTION="--uchime_ref errors if query file does not exist"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
"${VSEARCH}" \
    --uchime_ref /no/such/file \
    --db "${DB}" \
    --quiet \
    --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref errors if query file is not readable"
DB=$(mktemp)
QUERY=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" > "${QUERY}"
chmod u-r "${QUERY}"
"${VSEARCH}" \
    --uchime_ref "${QUERY}" \
    --db "${DB}" \
    --quiet \
    --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${QUERY}" && rm -f "${QUERY}" "${DB}"
unset DB QUERY

DESCRIPTION="--uchime_ref accepts empty query input"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf "" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref accepts fasta query input"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref rejects fastq query input"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf "@s\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --quiet \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref rejects query that is not fasta"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf "not a fasta file\n" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --quiet \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref errors without --db"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_ref errors if --db file does not exist"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db /no/such/file \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_ref accepts empty --db file"
DB=$(mktemp)
printf "" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref errors without any output option"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## each listed output option accepted as sole output option
for OPT in --borderline --chimeras --nonchimeras --uchimealns --uchimeout ; do
    DESCRIPTION="--uchime_ref accepts ${OPT} as sole output option"
    DB=$(mktemp)
    printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
    printf ">s\n%s\n" "${PARENT_A}" | \
        "${VSEARCH}" \
            --uchime_ref - \
            --db "${DB}" \
            "${OPT}" /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset OPT

DESCRIPTION="--uchime_ref --borderline is accepted together with another output option"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --chimeras /dev/null \
        --borderline /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## chimera is detected against the reference database
DESCRIPTION="--uchime_ref detects a chimera against the reference database"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --chimeras - \
        --quiet | \
    grep -qw ">chimeraAB" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## Aligning the query against a reference normally uses the 16-bit SIMD
## aligner, which falls back to the linear memory aligner when a pair is
## too large for it (length product above 25,000,000). With references
## and a query of 5040 nt the product (5040 * 5040 = 25,401,600) exceeds
## that limit, exercising that fallback inside chimera detection. The
## sequences must be long and dissimilar, so they are built from a
## deterministic pseudo-random generator (a MINSTD linear congruential
## generator, whose products stay within awk's exact-integer range):
## parentA = blocks(1,2), parentB = blocks(3,4), query = blocks(1,4),
## i.e. a recombinant of the two references.
DESCRIPTION="--uchime_ref detects a chimera in sequences too large for the SIMD aligner"
GEN='BEGIN {b = "ACGT"; x = seed; for (i = 0; i < n; i++) {x = (x * 16807) % 2147483647; printf "%s", substr(b, (int(x / 256) % 4) + 1, 1)}}'
A1=$(awk -v n=2520 -v seed=1 "${GEN}")
A2=$(awk -v n=2520 -v seed=2 "${GEN}")
B1=$(awk -v n=2520 -v seed=3 "${GEN}")
B2=$(awk -v n=2520 -v seed=4 "${GEN}")
DB=$(mktemp)
printf ">parentA\n%s%s\n>parentB\n%s%s\n" "${A1}" "${A2}" "${B1}" "${B2}" > "${DB}"
printf ">chim\n%s%s\n" "${A1}" "${B2}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --chimeras /dev/stdout \
        --quiet 2> /dev/null | \
    awk 'BEGIN {n = 0} /^>chim$/ {n++} END {if (n == 1) exit 0 ; exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset GEN A1 A2 B1 B2 DB

DESCRIPTION="--uchime_ref writes non-chimeric query sequences to --nonchimeras"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">parentA\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --nonchimeras - \
        --quiet | \
    grep -qw ">parentA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --uchime_ref does not require abundance annotations on the query
DESCRIPTION="--uchime_ref does not require abundance annotations on the query"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -qw "chimeraAB" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## plus strand only (default) - a reverse complemented chimera is not
## detected
DESCRIPTION="--uchime_ref default compares sequences on plus strand only"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
REVCOMP=$(rev <<< "${CHIMERA_AB}" | tr 'ACGTacgt' 'TGCAtgca')
printf ">revcomp\n%s\n" "${REVCOMP}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB REVCOMP

## default --uchimeout has 18 tab-separated fields
DESCRIPTION="--uchime_ref default --uchimeout has 18 tab-separated fields"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '{print NF}' | \
    sort -u | \
    grep -qx "18" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------------- abskew

DESCRIPTION="--uchime_ref --abskew is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --abskew 2.0 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --abskew 1.0 is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --abskew 1.0 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --abskew < 1.0 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --abskew 0.9 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- dbmask

for METHOD in none dust soft ; do
    DESCRIPTION="--uchime_ref --dbmask ${METHOD} is accepted"
    DB=$(mktemp)
    printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
    printf ">s\n%s\n" "${PARENT_A}" | \
        "${VSEARCH}" \
            --uchime_ref - \
            --db "${DB}" \
            --dbmask "${METHOD}" \
            --chimeras /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset METHOD

## --dbmask soft combined with --hardmask hard-masks the soft (lowercase)
## regions of the reference database to N (chimera.cc dbmask == soft &&
## hardmask branch); the run is accepted
DESCRIPTION="--uchime_ref --dbmask soft --hardmask is accepted"
DB=$(mktemp)
printf ">d\nACGTacgtACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --dbmask soft \
        --hardmask \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --uchime_ref accepts a UDB-format reference database (chimera.cc
## udb_read path), built here with --makeudb_usearch
DESCRIPTION="--uchime_ref accepts a UDB reference database"
REF=$(mktemp)
UDB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${REF}"
"${VSEARCH}" \
    --makeudb_usearch "${REF}" \
    --output "${UDB}" \
    --quiet 2> /dev/null
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${UDB}" \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${REF}" "${UDB}"
unset REF UDB

DESCRIPTION="--uchime_ref --dbmask invalid is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --dbmask xxx \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------------ dn

DESCRIPTION="--uchime_ref --dn is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --dn 1.4 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref large --dn suppresses chimera detection"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --dn 1000000 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --dn 0 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --dn 0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ mindiffs

DESCRIPTION="--uchime_ref --mindiffs is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --mindiffs 3 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref large --mindiffs suppresses chimera detection"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --mindiffs 1000 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --mindiffs 0 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --mindiffs 0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- mindiv

DESCRIPTION="--uchime_ref --mindiv is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --mindiv 0.8 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref large --mindiv suppresses chimera detection"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --mindiv 99.0 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --mindiv 0 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --mindiv 0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- minh

DESCRIPTION="--uchime_ref --minh is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --minh 0.28 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref high --minh suppresses chimera detection"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --minh 100 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --minh 0 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --minh 0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- self

DESCRIPTION="--uchime_ref --self is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --self \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --self ignores reference entries when the label matches the query
## label; without --self, the query's self-match would dominate; with
## --self, parentA and parentB are used instead and the chimera is
## detected
DESCRIPTION="--uchime_ref --self ignores reference entries sharing the query label"
DB=$(mktemp)
(
    printf ">parentA\n%s\n" "${PARENT_A}"
    printf ">parentB\n%s\n" "${PARENT_B}"
    printf ">chimeraAB\n%s\n" "${CHIMERA_AB}"
) > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --self \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -qw "chimeraAB" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- selfid

DESCRIPTION="--uchime_ref --selfid is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --selfid \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --selfid ignores reference entries whose nucleotide sequence is
## strictly identical to the query. With both parents and a reference
## identical to the query in the database, the identical reference
## wins every smoothing window and suppresses detection, unless
## --selfid excludes it. vsearch 2.31.0 and older compared the
## reference against a query *part* (always shorter), so --selfid
## never excluded anything and this test - strengthened from an
## earlier single-entry-database version that passed vacuously - fails
## against released binaries
DESCRIPTION="--uchime_ref --selfid excludes the identical reference match"
DB=$(mktemp)
printf ">pa\n%s\n>pb\n%s\n>other\n%s\n" \
       "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" > "${DB}"
printf ">query\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --selfid \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '{exit $NF == "Y" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

# without --selfid, the identical reference is a perfect full-length
# match and the query is classified non-chimeric (passes against
# released binaries too)
DESCRIPTION="--uchime_ref: an identical reference suppresses detection without --selfid"
DB=$(mktemp)
printf ">pa\n%s\n>pb\n%s\n>other\n%s\n" \
       "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" > "${DB}"
printf ">query\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '{exit $NF == "N" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- strand

DESCRIPTION="--uchime_ref --strand plus is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --strand plus \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## manpage claims "--strand both" is supported, but vsearch rejects
## it: "Only --strand plus is allowed with uchime_ref."
DESCRIPTION="--uchime_ref --strand both is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --strand both \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --strand invalid is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --strand xxx \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- threads

DESCRIPTION="--uchime_ref --threads 1 is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --threads 1 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --uchime_ref is multithreaded: --threads > 1 should not produce a
## warning about the command not being multithreaded
DESCRIPTION="--uchime_ref --threads > 1 does not warn about non-multithreaded command"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --threads 4 \
        --chimeras /dev/null 2>&1 | \
    grep -iq "not multithreaded" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## The manpage says the output order may vary when using multiple
## threads. The order is all that varies: each query is compared against
## the reference database alone, so the set of rows must be the same at
## any thread count. Comparing the two runs sorted is what makes this
## test independent of the order (comparing them raw would fail on a
## perfectly correct binary).
DESCRIPTION="--uchime_ref output content does not depend on --threads"
DB=$(mktemp)
QUERIES=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">c1\n%s\n>p1\n%s\n>c2\n%s\n>p2\n%s\n>c3\n%s\n>p3\n%s\n>c4\n%s\n>p4\n%s\n" \
       "${CHIMERA_AB}" "${PARENT_A}" "${CHIMERA_AB}" "${PARENT_B}" \
       "${CHIMERA_AB}" "${PARENT_A}" "${CHIMERA_AB}" "${PARENT_B}" > "${QUERIES}"
SERIAL=$("${VSEARCH}" \
        --uchime_ref "${QUERIES}" \
        --db "${DB}" \
        --threads 1 \
        --uchimeout - \
        --quiet | sort)
PARALLEL=$("${VSEARCH}" \
        --uchime_ref "${QUERIES}" \
        --db "${DB}" \
        --threads 4 \
        --uchimeout - \
        --quiet | sort)
[[ -n "${SERIAL}" ]] && \
[[ "${SERIAL}" == "${PARALLEL}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERIES}"
unset DB QUERIES SERIAL PARALLEL

## the other half of the statement above: with a single thread there is
## nothing to interleave, so the rows come out in input order
DESCRIPTION="--uchime_ref --threads 1 reports queries in input order"
DB=$(mktemp)
QUERIES=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">c1\n%s\n>p1\n%s\n>c2\n%s\n>p2\n%s\n" \
       "${CHIMERA_AB}" "${PARENT_A}" "${CHIMERA_AB}" "${PARENT_B}" > "${QUERIES}"
"${VSEARCH}" \
    --uchime_ref "${QUERIES}" \
    --db "${DB}" \
    --threads 1 \
    --uchimeout - \
    --quiet | \
    awk -F'\t' '{printf "%s ", $2}' | \
    grep -qx "c1 p1 c2 p2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERIES}"
unset DB QUERIES

DESCRIPTION="--uchime_ref --threads above 1024 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --threads 1025 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref negative --threads is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --threads -1 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- uchimeout5

DESCRIPTION="--uchime_ref --uchimeout5 is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --uchimeout /dev/null \
        --uchimeout5 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --uchimeout5 produces 17 tab-separated fields"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --uchimeout - \
        --uchimeout5 \
        --quiet | \
    awk -F'\t' '{print NF}' | \
    sort -u | \
    grep -qx "17" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------------- xn

DESCRIPTION="--uchime_ref --xn is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --xn 8.0 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref large --xn suppresses chimera detection"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --xn 1000000 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --xn 1.0 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --xn 1.0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------- alignwidth

DESCRIPTION="--uchime_ref --alignwidth is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --alignwidth 80 \
        --uchimealns /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --alignwidth 0 suppresses folding"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --alignwidth 0 \
        --uchimealns - \
        --quiet | \
    awk '/^Q[[:space:]]+1[[:space:]]/ {print $NF}' | \
    grep -qw "66" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- fasta_score

DESCRIPTION="--uchime_ref --fasta_score is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --fasta_score \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --fasta_score adds uchime_ref=float to chimera headers"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" > "${DB}"
printf ">chimeraAB\n%s\n" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --fasta_score \
        --chimeras - \
        --quiet | \
    grep -qE "^>chimeraAB;uchime_ref=[0-9.]+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --fasta_score also annotates the --nonchimeras output (chimera.cc
## nonchimeras score-label branch); a query matching the reference is
## non-chimeric and gets a uchime_ref=0.0000 score
DESCRIPTION="--uchime_ref --fasta_score adds uchime_ref=float to nonchimera headers"
DB=$(mktemp)
printf ">parentA\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --fasta_score \
        --nonchimeras - \
        --quiet 2> /dev/null | \
    grep -qE "^>s;uchime_ref=[0-9.]+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- fasta_width

DESCRIPTION="--uchime_ref --fasta_width is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --fasta_width 80 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --fasta_width folds output sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --fasta_width 10 \
        --nonchimeras - \
        --quiet | \
    awk '/^>/ {next} {if (length($0) > 10) exit 1} END {exit 0}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- hardmask

DESCRIPTION="--uchime_ref --hardmask is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --hardmask \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- label_suffix

DESCRIPTION="--uchime_ref --label_suffix is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --label_suffix ";suffix" \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --label_suffix appends the suffix to headers"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --label_suffix ";suffix" \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- lengthout

DESCRIPTION="--uchime_ref --lengthout is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --lengthout \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --lengthout adds ;length=integer to headers"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --lengthout \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;length=66" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- log

DESCRIPTION="--uchime_ref --log is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --log /dev/null \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --log writes the version line"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --log - \
        --chimeras /dev/null \
        --quiet | \
    grep -qi "vsearch" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- maxseqlength

DESCRIPTION="--uchime_ref --maxseqlength is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --maxseqlength 50000 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --maxseqlength discards longer reference sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --maxseqlength 50 \
        --chimeras /dev/null 2>&1 | \
    grep -iq "maxseqlength.*discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- minseqlength

DESCRIPTION="--uchime_ref --minseqlength is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --minseqlength 1 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --minseqlength discards shorter sequences"
DB=$(mktemp)
printf ">d\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --minseqlength 33 \
        --chimeras /dev/null 2>&1 | \
    grep -iq "minseqlength.*discarded" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- no_progress

DESCRIPTION="--uchime_ref --no_progress is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --no_progress \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------ notrunclabels

DESCRIPTION="--uchime_ref --notrunclabels is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s extra\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --notrunclabels \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --notrunclabels retains full query headers"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s extra stuff\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --notrunclabels \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s extra stuff" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- qmask

for METHOD in none dust soft ; do
    DESCRIPTION="--uchime_ref --qmask ${METHOD} is accepted"
    DB=$(mktemp)
    printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
    printf ">s\n%s\n" "${PARENT_A}" | \
        "${VSEARCH}" \
            --uchime_ref - \
            --db "${DB}" \
            --qmask "${METHOD}" \
            --chimeras /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset METHOD

DESCRIPTION="--uchime_ref --qmask invalid is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --qmask xxx \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- quiet

DESCRIPTION="--uchime_ref --quiet suppresses messages on stdout"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --chimeras /dev/null \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- relabel

DESCRIPTION="--uchime_ref --relabel is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --relabel "seq_" \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --relabel renames output sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --relabel "seq_" \
        --nonchimeras - \
        --quiet | \
    grep -qx ">seq_1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- relabel_keep

DESCRIPTION="--uchime_ref --relabel_keep retains the old header after a space"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --relabel "seq_" \
        --relabel_keep \
        --nonchimeras - \
        --quiet | \
    grep -qx ">seq_1 s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- relabel_md5

DESCRIPTION="--uchime_ref --relabel_md5 renames sequences with md5 digests"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --relabel_md5 \
        --nonchimeras - \
        --quiet | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- relabel_self

DESCRIPTION="--uchime_ref --relabel_self is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --relabel_self \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- relabel_sha1

DESCRIPTION="--uchime_ref --relabel_sha1 renames sequences with sha1 digests"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --relabel_sha1 \
        --nonchimeras - \
        --quiet | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --relabel and --relabel_md5 are mutually exclusive"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --relabel "seq_" \
        --relabel_md5 \
        --nonchimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ sample

DESCRIPTION="--uchime_ref --sample adds ;sample=string to headers"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --sample "ABC" \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- sizeout

DESCRIPTION="--uchime_ref --sizeout adds ;size=1 to unannotated headers"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --sizeout \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- xee

DESCRIPTION="--uchime_ref --xee strips ;ee=float from headers"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s;ee=0.5\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --xee \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- xlength

DESCRIPTION="--uchime_ref --xlength strips ;length=integer from headers"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s;length=66\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --xlength \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ xsize

DESCRIPTION="--uchime_ref --xsize strips ;size=integer from headers"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s;size=5\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --xsize \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                        pairwise alignment options                           #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--uchime_ref --gapext is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --gapext 2I/1E \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --gapopen is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --gapopen 20I/2E \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --match is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --match 2 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--uchime_ref --mismatch is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --mismatch -4 \
        --chimeras /dev/null \
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

## --sizein is listed in the manpage as ignored by --uchime_ref:
## accepted silently and has no effect on results
DESCRIPTION="--uchime_ref --sizein is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
printf ">s;size=5\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db "${DB}" \
        --sizein \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## options not listed in the uchime_ref manpage or in the valid
## options list reported by vsearch. Flags (no argument) are tested
## bare; the command exits non-zero because the option is invalid.
for OPT in --gzip_decompress --bzip2_decompress ; do
    DESCRIPTION="--uchime_ref rejects ${OPT} as an invalid option"
    DB=$(mktemp)
    printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
    printf ">s\n%s\n" "${PARENT_A}" | \
        "${VSEARCH}" \
            --uchime_ref - \
            --db "${DB}" \
            "${OPT}" \
            --chimeras /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset OPT

## same, for options that take an argument: pass a syntactically valid
## argument and check for the "Invalid option" diagnostic, so the test
## cannot pass vacuously. A bare arg-taking option instead fails with
## "Illegal option argument" when the following token is consumed as its
## value. --id and --weak_id are search-identity options; uchime_ref uses a
## fixed internal identity with no weak band, so both are rejected.
while read -r OPT ARG ; do
    DESCRIPTION="--uchime_ref rejects ${OPT} as an invalid option"
    DB=$(mktemp)
    printf ">d\n%s\n" "${PARENT_A}" > "${DB}"
    printf ">s\n%s\n" "${PARENT_A}" | \
        "${VSEARCH}" \
            --uchime_ref - \
            --db "${DB}" \
            "${OPT}" "${ARG}" \
            --chimeras /dev/null 2>&1 | \
        grep -qi "Invalid option" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done <<'INVALID_ARG_OPTIONS'
--id 0.3
--weak_id 0.3
INVALID_ARG_OPTIONS
unset OPT ARG


## clean up common variables before the memory leaks section redefines
## them
unset A_START A_END B_START B_END PARENT_A PARENT_B CHIMERA_AB


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if [[ "${VALGRIND_WORKS}" == "true" ]] ; then

    LOG=$(mktemp)
    QUERY=$(mktemp)
    DB=$(mktemp)
    #        1...5...10...15...20...25...30...35
    A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"
    B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
    A_END=$(rev <<< ${A_START})
    B_END=$(rev <<< ${B_START})
    (
        printf ">parentA;size=50\n%s\n" "${A_START}${A_END}"
        printf ">parentB;size=49\n%s\n" "${B_START}${B_END}"
    ) > "${DB}"
    printf ">chimeraAB;size=1\n%s\n" "${A_START}${B_END}" > "${QUERY}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --uchime_ref "${QUERY}" \
        --db "${DB}" \
        --chimeras /dev/null \
        --nonchimeras /dev/null \
        --borderline /dev/null \
        --uchimealns /dev/null \
        --uchimeout /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--uchime_ref valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--uchime_ref valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${QUERY}" "${DB}"
    unset A_START B_START A_END B_END LOG QUERY DB DESCRIPTION
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
