#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="search_oligodb"
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
## test (see search_global.sh): probe it once, so that the valgrind
## checks below are skipped, not passed, when it cannot.
VALGRIND_WORKS=false
if which valgrind > /dev/null 2>&1 ; then
    VALGRIND_PROBE=$(valgrind "${VSEARCH}" --version 2>&1)
    [[ "${VALGRIND_PROBE}" == *"ERROR SUMMARY"* && \
       "${VALGRIND_PROBE}" != *"Process terminating"* ]] && \
        VALGRIND_WORKS=true
    unset VALGRIND_PROBE
fi


## vsearch --search_oligodb fastxfile --db fastafile (--alnout |
## --blast6out | --userout) filename [options]

## every occurrence of every oligo of --db in the query sequences, within
## --maxdiffs differences (substitutions and gap columns), on both
## strands by default.

## A 19-nt oligo (the 515F primer without its ambiguous positions), and
## flanks that hold nothing resembling it: an exact copy between the two
## flanks spans the query positions 15 to 33 (1-based).
OLIGO="GTGCCAGCAGCCGCGGTAA"
RC_OLIGO="TTACCGCGGCTGCTGGCAC"
LEFT="GATTACAGATTACA"
RIGHT="CTCTCTGAGAGA"
FIELDS="query+target+qstrand+qlo+qhi+tlo+thi+diffs"

## write the one-oligo database used by most tests below
make_db () {
    printf ">o\n%s\n" "${OLIGO}"
}


#*****************************************************************************#
#                                                                             #
#                            mandatory options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_oligodb is accepted"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb requires --db"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--search_oligodb requires an output option"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb rejects an empty --db file"
DB=$(mktemp)
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb rejects an empty oligo"
DB=$(mktemp)
printf ">o\n\n" > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb accepts an oligo of 64 nucleotides"
DB=$(mktemp)
printf ">o\n%s\n" "$(printf 'ACGT%.0s' {1..16})" > "${DB}"
printf ">q\nA\n" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb rejects an oligo of 65 nucleotides"
DB=$(mktemp)
printf ">o\n%sA\n" "$(printf 'ACGT%.0s' {1..16})" > "${DB}"
printf ">q\nA\n" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb rejects a UDB database"
DB=$(mktemp)
UDB=$(mktemp)
printf ">t\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" > "${DB}"
"${VSEARCH}" \
    --makeudb_usearch "${DB}" \
    --minseqlength 1 \
    --quiet \
    --output "${UDB}" 2> /dev/null
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${UDB}" \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}" "${UDB}"
unset DB UDB

DESCRIPTION="--search_oligodb reads queries in fastq format"
DB=$(mktemp)
make_db > "${DB}"
printf "@q\n%s\n+\n%s\n" "${OLIGO}" "IIIIIIIIIIIIIIIIIII" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields query+qlo+qhi+diffs \
        --userout - | \
    grep -qx "q	1	19	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_oligodb reports an exact occurrence and its position"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields "${FIELDS}" \
        --userout - | \
    grep -qx "q	o	+	15	33	1	19	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb writes nothing for a query without occurrence"
DB=$(mktemp)
make_db > "${DB}"
{ printf ">q\n%s%s\n" "${LEFT}" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --quiet \
          --userfields "${FIELDS}" \
          --userout - ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reports every occurrence (two copies)"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" "${OLIGO}" "${LEFT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qlo \
        --userout - | \
    tr '\n' ' ' | \
    grep -qx "15 46 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reports adjacent copies separately"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s%s\n" "${LEFT}" "${OLIGO}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qlo \
        --userout - | \
    tr '\n' ' ' | \
    grep -qx "15 34 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb searches both strands by default (minus: qlo > qhi)"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${RC_OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields "${FIELDS}" \
        --userout - | \
    grep -qx "q	o	-	33	15	1	19	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb orders occurrences by position, whatever the strand"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s%s%s\n" "${LEFT}" "${RC_OLIGO}" "${RIGHT}" "${OLIGO}" "${LEFT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qstrand \
        --userout - | \
    tr '\n' ' ' | \
    grep -qx -e "- + " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb writes queries in input order"
DB=$(mktemp)
make_db > "${DB}"
printf ">q1\n%s%s%s\n>q2\n%s\n>q3\n%s%s\n" \
       "${LEFT}" "${OLIGO}" "${RIGHT}" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields query \
        --userout - | \
    tr '\n' ' ' | \
    grep -qx "q1 q3 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reports occurrences of different oligos that overlap"
DB=$(mktemp)
printf ">o\n%s\n>shifted\n%s\n" "${OLIGO}" "${OLIGO:5}${RIGHT:0:5}" > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields target+qlo \
        --userout - | \
    tr '\n\t' '  ' | \
    grep -qx "o 15 shifted 20 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## the end positions near an occurrence also fall within the default
## two differences (one or two bases more or less at the oligo's end):
## they collapse into one occurrence, the one with the fewest differences
DESCRIPTION="--search_oligodb collapses neighbouring end positions into one occurrence"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qlo \
        --userout - | \
    wc -l | \
    grep -qx " *1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb default --maxdiffs is 2 (2 substitutions found)"
DB=$(mktemp)
make_db > "${DB}"
## positions 3 and 12 of the oligo substituted
printf ">q\n%sGTACCAGCAGCAGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs+mism \
        --userout - | \
    grep -qx "2	2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb default --maxdiffs is 2 (3 substitutions not found)"
DB=$(mktemp)
make_db > "${DB}"
## positions 3, 12 and 17 of the oligo substituted
{ printf ">q\n%sGTACCAGCAGCAGCGGAAA%s\n" "${LEFT}" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --quiet \
          --userfields diffs \
          --userout - ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb finds an occurrence with a deleted nucleotide"
DB=$(mktemp)
make_db > "${DB}"
## the 10th oligo nucleotide (A) is missing from the query
printf ">q\n%sGTGCCAGCGCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs+gaps+opens+qlo+qhi \
        --userout - | \
    grep -qx "1	1	1	15	32" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb finds an occurrence with an inserted nucleotide"
DB=$(mktemp)
make_db > "${DB}"
## a T inserted after the 10th oligo nucleotide
printf ">q\n%sGTGCCAGCAGTCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs+gaps+qlo+qhi \
        --userout - | \
    grep -qx "1	1	15	34" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reports the alignment of the occurrence only (caln)"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTGCCAGCAGTCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields caln \
        --userout - | \
    grep -Eqx "[0-9]*M1D[0-9]*M" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reports raw as the number of differences"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTACCAGCAGCAGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields raw+bits+evalue \
        --userout - | \
    grep -qx "2	0	-1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb matches an ambiguous oligo position (Y against C)"
DB=$(mktemp)
printf ">o\nGTGYCAGCAGCCGCGGTAA\n" > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb matches an ambiguous oligo position (Y against T)"
DB=$(mktemp)
printf ">o\nGTGYCAGCAGCCGCGGTAA\n" > "${DB}"
printf ">q\n%sGTGTCAGCAGCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb counts an ambiguous oligo position against a base outside its set"
DB=$(mktemp)
printf ">o\nGTGYCAGCAGCCGCGGTAA\n" > "${DB}"
printf ">q\n%sGTGACAGCAGCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb matches an ambiguous query position (R against A)"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTGCCRGCAGCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb lets a query N match any oligo nucleotide"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTGCCNGCAGCNGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reports a run of Ns as long as the oligo, once per strand"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "$(printf 'N%.0s' {1..30})" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qstrand+diffs \
        --userout - | \
    tr '\n\t' '  ' | \
    grep -qx "+ 0 - 0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb ignores case"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "gtgccagcagccgcggtaa" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reads U as T"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "GUGCCAGCAGCCGCGGUAA" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reports an occurrence truncated by the query start (default --target_cov 0.75)"
DB=$(mktemp)
make_db > "${DB}"
## the first 4 oligo nucleotides are missing: 15 of 19 (78.9%) remain
printf ">q\n%s%s\n" "${OLIGO:4}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qlo+qhi+tlo+thi+diffs \
        --userout - | \
    grep -qx "1	15	5	19	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reports an occurrence truncated by the query end"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s\n" "${LEFT}" "${OLIGO:0:15}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qlo+qhi+tlo+thi+diffs \
        --userout - | \
    grep -qx "15	29	1	15	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb does not report a truncation below the default --target_cov 0.75"
DB=$(mktemp)
make_db > "${DB}"
## 14 of 19 oligo nucleotides (73.7%) remain. --maxdiffs 0, because with
## differences allowed the alignment can reach 15 oligo nucleotides by
## paying for a mismatch and a deletion at the edge, and then passes.
{ printf ">q\n%s%s\n" "${OLIGO:5}" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --maxdiffs 0 \
          --quiet \
          --userfields qlo \
          --userout - ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb does not count truncated nucleotides as differences"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s\n" "${OLIGO:3}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs+gaps \
        --userout - | \
    grep -qx "0	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb does not mask queries by default (low-complexity oligo found)"
DB=$(mktemp)
printf ">ac\nACACACACACACACACACAC\n" > "${DB}"
printf ">q\n%sACACACACACACACACACAC%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --strand plus \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb reports the number of occurrences on stderr"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" "${OLIGO}" "${LEFT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --userout /dev/null 2>&1 | \
    grep -qx "Occurrences found: 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------------ maxdiffs

DESCRIPTION="--search_oligodb --maxdiffs 0 finds an exact occurrence"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --maxdiffs 0 \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --maxdiffs 0 rejects one substitution"
DB=$(mktemp)
make_db > "${DB}"
{ printf ">q\n%sGTACCAGCAGCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --maxdiffs 0 \
          --quiet \
          --userfields diffs \
          --userout - ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --maxdiffs 3 finds 3 substitutions"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTACCAGCAGCAGCGGAAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --maxdiffs 3 \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --maxdiffs rejects a negative value"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --maxdiffs -1 \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- maxgaps

## two nucleotides deleted far apart: two differences, two gap openings
DESCRIPTION="--search_oligodb reports two gap openings by default"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTCCAGCAGCCGCGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields diffs+opens \
        --userout - | \
    grep -qx "2	2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --maxgaps 1 rejects two gap openings"
DB=$(mktemp)
make_db > "${DB}"
{ printf ">q\n%sGTCCAGCAGCCGCGTAA%s\n" "${LEFT}" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --maxgaps 1 \
          --quiet \
          --userfields diffs \
          --userout - ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --maxgaps 0 still finds substitutions"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTACCAGCAGCAGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --maxgaps 0 \
        --quiet \
        --userfields diffs+mism+gaps \
        --userout - | \
    grep -qx "2	2	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --maxgaps 0 aligns without gaps (deletion becomes substitutions)"
DB=$(mktemp)
make_db > "${DB}"
## the 10th oligo nucleotide (A) is missing from the query: with gaps it is
## one difference; without gaps, the best alignment has several mismatches
{ printf ">q\n%sGTGCCAGCGCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --maxgaps 0 \
          --maxdiffs 1 \
          --quiet \
          --userfields diffs \
          --userout - ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- strand

DESCRIPTION="--search_oligodb --strand plus ignores a minus-strand occurrence"
DB=$(mktemp)
make_db > "${DB}"
{ printf ">q\n%s%s%s\n" "${LEFT}" "${RC_OLIGO}" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --strand plus \
          --quiet \
          --userfields qstrand \
          --userout - ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --strand plus still finds a plus-strand occurrence"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --strand plus \
        --quiet \
        --userfields qstrand \
        --userout - | \
    grep -qx "+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --strand both is accepted"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${RC_OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --strand both \
        --quiet \
        --userfields qstrand \
        --userout - | \
    grep -qx -e "-" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --strand rejects an unknown value"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --strand minus \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- target_cov

## the first oligo nucleotide is missing from the query start. With
## --target_cov 1 it cannot hang off the query, so the whole oligo has to
## be aligned inside it: that costs 2 differences here (a mismatch and a
## deletion), more than --maxdiffs 1 allows
DESCRIPTION="--search_oligodb --target_cov 1 does not report truncated occurrences"
DB=$(mktemp)
make_db > "${DB}"
{ printf ">q\n%s%s\n" "${OLIGO:1}" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --target_cov 1 \
          --maxdiffs 1 \
          --quiet \
          --userfields qlo \
          --userout - ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --target_cov 1 aligns the whole oligo inside the query"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s\n" "${OLIGO:1}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --target_cov 1 \
        --quiet \
        --userfields qlo+tlo+thi+diffs \
        --userout - | \
    grep -qx "1	1	19	2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb default --target_cov lets the missing nucleotide hang off"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s\n" "${OLIGO:1}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qlo+tlo+thi+diffs \
        --userout - | \
    grep -qx "1	2	19	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --target_cov measures the span of the oligo inside the query: a deletion
## is a difference, not a truncation, although tcov drops below 100%
DESCRIPTION="--search_oligodb --target_cov 1 still reports an occurrence with a deletion"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTGCCAGCGCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --target_cov 1 \
        --quiet \
        --userfields tlo+thi+diffs+tcov \
        --userout - | \
    grep -qx "1	19	1	94.7" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --target_cov 0.5 reports a shorter truncation"
DB=$(mktemp)
make_db > "${DB}"
## 10 of 19 oligo nucleotides (52.6%) remain
printf ">q\n%s%s\n" "${OLIGO:9}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --target_cov 0.5 \
        --quiet \
        --userfields qlo+qhi+tlo+thi \
        --userout - | \
    grep -qx "1	10	10	19" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --target_cov rejects a value above 1"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --target_cov 1.5 \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- n_mismatch

DESCRIPTION="--search_oligodb --n_mismatch counts a query N as a mismatch"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTGCCNGCAGCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --n_mismatch \
        --quiet \
        --userfields diffs+mism \
        --userout - | \
    grep -qx "1	1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --n_mismatch finds nothing in a run of Ns"
DB=$(mktemp)
make_db > "${DB}"
{ printf ">q\n%s%s%s\n" "${LEFT}" "$(printf 'N%.0s' {1..30})" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --n_mismatch \
          --quiet \
          --userfields diffs \
          --userout - ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- threads

DESCRIPTION="--search_oligodb --threads gives the same output as one thread"
DB=$(mktemp)
QUERIES=$(mktemp)
OUT1=$(mktemp)
OUT4=$(mktemp)
make_db > "${DB}"
for i in {1..300} ; do
    printf ">q%d\n%s%s%s%s%s\n" "${i}" "${LEFT}" "${OLIGO}" "${RIGHT}" "${RC_OLIGO}" "${LEFT}"
done > "${QUERIES}"
"${VSEARCH}" \
    --search_oligodb "${QUERIES}" \
    --db "${DB}" \
    --threads 1 \
    --quiet \
    --userfields "${FIELDS}" \
    --userout "${OUT1}"
"${VSEARCH}" \
    --search_oligodb "${QUERIES}" \
    --db "${DB}" \
    --threads 4 \
    --quiet \
    --userfields "${FIELDS}" \
    --userout "${OUT4}"
[[ -s "${OUT1}" ]] && cmp -s "${OUT1}" "${OUT4}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERIES}" "${OUT1}" "${OUT4}"
unset DB QUERIES OUT1 OUT4 i


#*****************************************************************************#
#                                                                             #
#                             output options                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_oligodb --blast6out writes twelve fields"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --blast6out - | \
    awk -F '\t' '{exit NF == 12 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --blast6out reports the positions of the occurrence"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --blast6out - | \
    grep -qx "q	o	100.0	19	0	0	15	33	1	19	-1	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --blast6out swaps the query positions on the minus strand"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${RC_OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --blast6out - | \
    awk -F '\t' '{exit ($7 == 33 && $8 == 15 && $9 == 1 && $10 == 19) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --alnout shows the positions of the occurrence"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --alnout - | \
    grep -Eq "^Qry +15 \+ ${OLIGO} 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --rowlen wraps --alnout lines"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --rowlen 10 \
        --quiet \
        --alnout - | \
    grep -Eq "^Qry +15 \+ ${OLIGO:0:10} 24$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --userout and --userfields are accepted"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields query+target \
        --userout - | \
    grep -qx "q	o" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb userfields qlor and qhir count from zero"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qlor+qhir+tlor+thir \
        --userout - | \
    grep -qx "14	32	0	18" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb userfields qilo and qihi keep their meaning"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qilo+qihi+ql+tl \
        --userout - | \
    grep -qx "15	33	45	19" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb userfields qrow and trow cover the occurrence only"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%sGTGCCAGCGCCGCGGTAA%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields qrow+trow \
        --userout - | \
    grep -Eqx "GTGCCAGC-?G-?CCGCGGTAA	${OLIGO}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_oligodb --gzip_decompress reads a compressed query pipe"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    gzip | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --gzip_decompress \
        --quiet \
        --userfields qlo \
        --userout - | \
    grep -qx "15" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --bzip2_decompress reads a compressed query pipe"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    bzip2 | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --bzip2_decompress \
        --quiet \
        --userfields qlo \
        --userout - | \
    grep -qx "15" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --qmask dust (soft) does not hide an occurrence"
DB=$(mktemp)
printf ">ac\nACACACACACACACACACAC\n" > "${DB}"
printf ">q\n%sACACACACACACACACACAC%s\n" "${LEFT}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --strand plus \
        --qmask dust \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## hard masking turns the masked nucleotides into Ns, which match any
## oligo nucleotide: a G-only oligo then occurs in a masked AC repeat
DESCRIPTION="--search_oligodb --qmask dust --hardmask creates occurrences in masked regions"
DB=$(mktemp)
printf ">g\nGGGGGGGGGGGGGGGGGGGG\n" > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "$(printf 'AC%.0s' {1..30})" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --strand plus \
        --qmask dust \
        --hardmask \
        --quiet \
        --userfields diffs \
        --userout - | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --qmask none is accepted"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --qmask none \
        --quiet \
        --userfields qlo \
        --userout - | \
    grep -qx "15" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --log writes the number of occurrences"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --log - \
        --userout /dev/null | \
    grep -qx "Occurrences found: 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --quiet silences stderr"
DB=$(mktemp)
make_db > "${DB}"
{ printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
      "${VSEARCH}" \
          --search_oligodb - \
          --db "${DB}" \
          --quiet \
          --userout /dev/null 2>&1 ; echo "exit:$?" ; } | \
    tr '\n' ' ' | \
    grep -qx "exit:0 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --no_progress is accepted"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --no_progress \
        --quiet \
        --userout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb truncates query labels at the first blank by default"
DB=$(mktemp)
make_db > "${DB}"
printf ">q extra\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --quiet \
        --userfields query \
        --userout - | \
    grep -qx "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --notrunclabels keeps whole query labels"
DB=$(mktemp)
make_db > "${DB}"
printf ">q extra\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --notrunclabels \
        --quiet \
        --userfields query \
        --userout - | \
    grep -qx "q extra" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_oligodb --sizein is accepted"
DB=$(mktemp)
make_db > "${DB}"
printf ">q;size=3\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --sizein \
        --quiet \
        --userout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                             invalid options                                 #
#                                                                             #
#*****************************************************************************#

## options of the other search commands that select or rank hits: this
## command reports every occurrence
for OPTION in "--id 0.9" "--maxaccepts 1" "--maxhits 1" "--dbmask none" ; do
    DESCRIPTION="--search_oligodb rejects ${OPTION}"
    DB=$(mktemp)
    make_db > "${DB}"
    # shellcheck disable=SC2086
    printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
        "${VSEARCH}" \
            --search_oligodb - \
            --db "${DB}" \
            ${OPTION} \
            --quiet \
            --userout /dev/null 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset OPTION

DESCRIPTION="--search_oligodb rejects --top_hits_only"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" | \
    "${VSEARCH}" \
        --search_oligodb - \
        --db "${DB}" \
        --top_hits_only \
        --quiet \
        --userout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                                  memory                                     #
#                                                                             #
#*****************************************************************************#

if [[ "${VALGRIND_WORKS}" == "true" ]] ; then
    DESCRIPTION="--search_oligodb valgrind (no leak, no error)"
    DB=$(mktemp)
    QUERY=$(mktemp)
    make_db > "${DB}"
    printf ">q\n%s%s%s%s%s\n" "${LEFT}" "${OLIGO}" "${RIGHT}" "${RC_OLIGO}" "${LEFT}" > "${QUERY}"
    valgrind \
        --log-file=/dev/stdout \
        --leak-check=full \
        "${VSEARCH}" \
        --search_oligodb "${QUERY}" \
        --db "${DB}" \
        --threads 1 \
        --quiet \
        --alnout /dev/null \
        --blast6out /dev/null \
        --userfields "${FIELDS}+caln+qrow+trow" \
        --userout /dev/null 2> /dev/null | \
        grep -q "ERROR SUMMARY: 0 errors" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}" "${QUERY}"
    unset DB QUERY
fi


unset OLIGO RC_OLIGO LEFT RIGHT FIELDS
unset -f make_db

exit 0
