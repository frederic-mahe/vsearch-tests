#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="search_global"
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


## vsearch --search_global fastxfile --db filename --id real (--alnout |
## --biomout | --blast6out | --dbmatched | --dbnotmatched | --fastapairs
## | --lcaout | --matched | --mothur_shared_out | --notmatched |
## --otutabout | --qsegout | --samout | --tsegout | --uc | --userout)
## filename [options]

## --search_global is the exhaustive counterpart of --usearch_global:
## every database sequence is aligned against every query, with no
## k-mer pre-filter and no early stop.

## A 60-nt query and four targets chosen so that the pre-filter and the
## identity ranking disagree. Candidates are selected by shared word
## count but accepted by identity, so:
##   NEAR       1 substitution          98.3% -- found by both commands
##   SCATTERED  6 substitutions, 10 nt apart, each killing a full window
##              of 8 words: 90.0% identity but too few shared words to
##              pass the default --minwordmatches 12, so --usearch_global
##              never aligns it. This is the pair the command exists for.
##   BLOCK      8 contiguous substitutions kill only block + k - 1 words,
##              so the pre-filter keeps it at a *lower* 86.7% identity
##   UNRELATED  a different sequence entirely, below the thresholds used
##              here
QUERY_SEQ="TTGACCGATGCAGTTAACCGTAGCCTGAATGGCATACGTTCCAGATTGCAACGTTGACCA"
NEAR="TTGACCGATGCAGTTAACCGTAGCCTGAATTGCATACGTTCCAGATTGCAACGTTGACCA"
BLOCK="TTGACCGATGCAGTTAACCGGCTAAGTCATGGCATACGTTCCAGATTGCAACGTTGACCA"
SCATTERED="TTGAACGATGCAGTGAACCGTAGCATGAATGGCAGACGTTCCAGCTTGCAACGTGGACCA"
UNRELATED="GCTAGCTAGCGCTAGCTAGCGCTAGCTAGCGCTAGCTAGCGCTAGCTAGCGCTAGCTAGC"

## write the four-target database used by most tests below
make_db () {
    printf ">near\n%s\n>block\n%s\n>scattered\n%s\n>unrelated\n%s\n" \
           "${NEAR}" "${BLOCK}" "${SCATTERED}" "${UNRELATED}"
}


#*****************************************************************************#
#                                                                             #
#                            mandatory options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_global is accepted"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global requires --db"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --id 0.5 \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--search_global requires --id"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global rejects an --id above 1.0"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 1.5 \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global requires an output option"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global errors if the query file does not exist"
DB=$(mktemp)
make_db > "${DB}"
"${VSEARCH}" \
    --search_global /no/such/file \
    --db "${DB}" \
    --id 0.5 \
    --quiet \
    --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#                       exhaustiveness (the point)                            #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_global reports all three targets above the threshold"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    awk 'BEGIN {FS = "\t"} {printf "%s:%s ", $2, $3}' | \
    grep -qx "near:98.3 scattered:90.0 block:86.7 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global finds a high-identity target the pre-filter hides"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -qw "scattered" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## the same query and database through --usearch_global: the pre-filter
## drops "scattered" although it is the second-best target. Pinned so
## that a change to either command shows up as a diverging pair.
DESCRIPTION="--usearch_global hides that target (pre-filter, not early stop)"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -qw "scattered" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global reports an unrelated target at a low --id"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.1 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -qw "unrelated" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## the database-side warning counts sequences absent from the k-mer
## index. --search_global builds none, so the warning is meaningless and
## must not appear; --usearch_global on the same input still emits it.
DESCRIPTION="--search_global issues no k-mer index warning"
DB=$(mktemp)
printf ">masked\nacgtacgtacgtacgtacgtacgtacgtacgt\n" > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.1 \
        --minseqlength 1 \
        --threads 1 \
        --blast6out /dev/null 2>&1 | \
    grep -q "yielded no k-mer" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB


#*****************************************************************************#
#                                                                             #
#              equivalence with the exhaustive --usearch_global               #
#                                                                             #
#*****************************************************************************#

## --search_global must equal the incantation that switches the
## heuristics off. --minseqlength 1 on BOTH sides: --usearch_global
## defaults it to 32 and --search_global to 1, so without it the two
## sides would filter different inputs. --threads 1 and a sorted
## comparison: output line order varies between runs above one thread.
for FORMAT in blast6out userout uc ; do
    DESCRIPTION="--search_global matches the exhaustive --usearch_global (--${FORMAT})"
    DB=$(mktemp)
    QUERY=$(mktemp)
    LEFT=$(mktemp)
    RIGHT=$(mktemp)
    make_db > "${DB}"
    printf ">q\n%s\n" "${QUERY_SEQ}" > "${QUERY}"
    "${VSEARCH}" \
        --search_global "${QUERY}" \
        --db "${DB}" \
        --id 0.3 \
        --minseqlength 1 \
        --threads 1 \
        --userfields query+target+id+alnlen+mism+gaps+qlo+qhi+tlo+thi \
        --quiet \
        "--${FORMAT}" - 2> /dev/null | \
        LC_ALL=C sort > "${LEFT}"
    "${VSEARCH}" \
        --usearch_global "${QUERY}" \
        --db "${DB}" \
        --id 0.3 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --minwordmatches 0 \
        --minseqlength 1 \
        --threads 1 \
        --userfields query+target+id+alnlen+mism+gaps+qlo+qhi+tlo+thi \
        --quiet \
        "--${FORMAT}" - 2> /dev/null | \
        LC_ALL=C sort > "${RIGHT}"
    ## a comparison of two empty files would pass for the wrong reason
    [[ -s "${LEFT}" ]] && \
        cmp -s "${LEFT}" "${RIGHT}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}" "${QUERY}" "${LEFT}" "${RIGHT}"
    unset DB QUERY LEFT RIGHT
done
unset FORMAT


#*****************************************************************************#
#                                                                             #
#                             ignored options                                 #
#                                                                             #
#*****************************************************************************#

## the options that steer the index --search_global does not build are
## accepted, so a command line moved over from --usearch_global keeps
## working, and they change nothing
DESCRIPTION="--search_global ignores --maxaccepts, --maxrejects and --minwordmatches"
DB=$(mktemp)
QUERY=$(mktemp)
LEFT=$(mktemp)
RIGHT=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" > "${QUERY}"
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${DB}" \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --blast6out "${LEFT}"
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${DB}" \
    --id 0.5 \
    --maxaccepts 1 \
    --maxrejects 1 \
    --minwordmatches 12 \
    --threads 1 \
    --quiet \
    --blast6out "${RIGHT}"
[[ -s "${LEFT}" ]] && \
    cmp -s "${LEFT}" "${RIGHT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERY}" "${LEFT}" "${RIGHT}"
unset DB QUERY LEFT RIGHT

DESCRIPTION="--search_global ignores --wordlength"
DB=$(mktemp)
QUERY=$(mktemp)
LEFT=$(mktemp)
RIGHT=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" > "${QUERY}"
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${DB}" \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --blast6out "${LEFT}"
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${DB}" \
    --id 0.5 \
    --wordlength 15 \
    --threads 1 \
    --quiet \
    --blast6out "${RIGHT}"
[[ -s "${LEFT}" ]] && \
    cmp -s "${LEFT}" "${RIGHT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERY}" "${LEFT}" "${RIGHT}"
unset DB QUERY LEFT RIGHT


#*****************************************************************************#
#                                                                             #
#                        strand, masking, and limits                          #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_global searches the plus strand only by default"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" --fastx_revcomp - --fastaout - --quiet | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.8 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global --strand both finds a reverse-complemented query"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" --fastx_revcomp - --fastaout - --quiet | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.8 \
        --strand both \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -qw "near" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global --maxhits limits the number of reported hits"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --maxhits 2 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    wc -l | \
    grep -qw "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global --top_hits_only reports only the best identity"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --top_hits_only \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    wc -l | \
    grep -qw "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global --iddef 5 is accepted"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --iddef 5 \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --iddef 5 (score-based identity): against a copy of the query missing
## one internal nucleotide (30MD29M, raw 98), the 1-nt gap weighs its
## penalty, 20 / (2 + 4) = 3.3 mismatches: 100 * (1 - 20 / (6 * 59)) =
## 94.4%, where --iddef 2 reports 59 / 60 = 98.3%
DESCRIPTION="--search_global --iddef 5 reports the score-based identity"
DB=$(mktemp)
printf ">d\nTTGACCGATGCAGTTAACCGTAGCCTGAATGCATACGTTCCAGATTGCAACGTTGACCA\n" > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --iddef 5 \
        --qmask none \
        --dbmask none \
        --quiet \
        --userout - \
        --userfields id+id2 | \
    grep -qx "94.4	98.3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global --self excludes a target with the query's label"
DB=$(mktemp)
printf ">q\n%s\n" "${NEAR}" > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --self \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global --selfid excludes an identical target"
DB=$(mktemp)
printf ">d\n%s\n" "${QUERY_SEQ}" > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --selfid \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## soft masking only ever steered the k-mer index, so with no index it
## cannot change an alignment: dust and none must agree
DESCRIPTION="--search_global soft masking does not change the alignment"
DB=$(mktemp)
QUERY=$(mktemp)
LEFT=$(mktemp)
RIGHT=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" > "${QUERY}"
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${DB}" \
    --id 0.5 \
    --qmask dust \
    --dbmask dust \
    --threads 1 \
    --quiet \
    --blast6out "${LEFT}"
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${DB}" \
    --id 0.5 \
    --qmask none \
    --dbmask none \
    --threads 1 \
    --quiet \
    --blast6out "${RIGHT}"
[[ -s "${LEFT}" ]] && \
    cmp -s "${LEFT}" "${RIGHT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERY}" "${LEFT}" "${RIGHT}"
unset DB QUERY LEFT RIGHT


#*****************************************************************************#
#                                                                             #
#                            database formats                                 #
#                                                                             #
#*****************************************************************************#

## a UDB is accepted, and only its sequences are read: the results must
## be those of the fasta database it was built from
DESCRIPTION="--search_global accepts a UDB database"
DB=$(mktemp)
UDB=$(mktemp)
QUERY=$(mktemp)
LEFT=$(mktemp)
RIGHT=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" > "${QUERY}"
"${VSEARCH}" \
    --makeudb_usearch "${DB}" \
    --output "${UDB}" \
    --minseqlength 1 \
    --quiet 2> /dev/null
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${DB}" \
    --id 0.5 \
    --minseqlength 1 \
    --threads 1 \
    --quiet \
    --blast6out "${LEFT}"
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${UDB}" \
    --id 0.5 \
    --minseqlength 1 \
    --threads 1 \
    --quiet \
    --blast6out "${RIGHT}"
[[ -s "${LEFT}" ]] && \
    cmp -s "${LEFT}" "${RIGHT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${UDB}" "${QUERY}" "${LEFT}" "${RIGHT}"
unset DB UDB QUERY LEFT RIGHT


#*****************************************************************************#
#                                                                             #
#                               edge cases                                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_global accepts an empty query file"
DB=$(mktemp)
make_db > "${DB}"
printf "" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global accepts a single-sequence database"
DB=$(mktemp)
printf ">d\n%s\n" "${NEAR}" > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -qw "d" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --search_global defaults --minseqlength to 1, not to the 32 of
## --usearch_global: nothing here requires a sequence to hold a whole
## word, so a sequence shorter than the word length is still searched
DESCRIPTION="--search_global searches sequences shorter than the word length"
DB=$(mktemp)
printf ">short\nACGTACG\n" > "${DB}"
printf ">q\nACGTACG\n" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -qw "short" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global --output_no_hits reports a query with no match"
DB=$(mktemp)
printf ">d\n%s\n" "${UNRELATED}" > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.9 \
        --output_no_hits \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --blast6out - | \
    grep -q "^q.*\*" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global --notmatched collects a query with no match"
DB=$(mktemp)
printf ">d\n%s\n" "${UNRELATED}" > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.9 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --notmatched - | \
    grep -qw ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global --dbnotmatched collects an unmatched target"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.9 \
        --threads 1 \
        --qmask none \
        --dbmask none \
        --quiet \
        --dbnotmatched - | \
    grep -qw ">unrelated" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global gives the same results at --threads 2"
DB=$(mktemp)
QUERY=$(mktemp)
LEFT=$(mktemp)
RIGHT=$(mktemp)
make_db > "${DB}"
printf ">q1\n%s\n>q2\n%s\n" "${QUERY_SEQ}" "${NEAR}" > "${QUERY}"
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${DB}" \
    --id 0.5 \
    --threads 1 \
    --qmask none \
    --dbmask none \
    --quiet \
    --blast6out - | \
    LC_ALL=C sort > "${LEFT}"
"${VSEARCH}" \
    --search_global "${QUERY}" \
    --db "${DB}" \
    --id 0.5 \
    --threads 2 \
    --qmask none \
    --dbmask none \
    --quiet \
    --blast6out - | \
    LC_ALL=C sort > "${RIGHT}"
[[ -s "${LEFT}" ]] && \
    cmp -s "${LEFT}" "${RIGHT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERY}" "${LEFT}" "${RIGHT}"
unset DB QUERY LEFT RIGHT


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## options a user might reasonably reach for, but which --search_global
## does not accept. --acceptall in particular is accepted by
## --allpairs_global, the other command that aligns everything, so the
## asymmetry is worth pinning: --search_global always requires --id.
DESCRIPTION="--search_global rejects --acceptall"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --acceptall \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global rejects --sizeorder"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --sizeorder \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_global rejects --centroids"
DB=$(mktemp)
OUTPUT=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --centroids "${OUTPUT}" \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}" "${OUTPUT}"
unset DB OUTPUT

DESCRIPTION="--search_global rejects --fastq_qmax"
DB=$(mktemp)
make_db > "${DB}"
printf ">q\n%s\n" "${QUERY_SEQ}" | \
    "${VSEARCH}" \
        --search_global - \
        --db "${DB}" \
        --id 0.5 \
        --fastq_qmax 41 \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
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
    DESCRIPTION="--search_global valgrind (no leak, no error)"
    DB=$(mktemp)
    QUERY=$(mktemp)
    make_db > "${DB}"
    printf ">q\n%s\n" "${QUERY_SEQ}" > "${QUERY}"
    valgrind \
        --log-file=/dev/stdout \
        --leak-check=full \
        "${VSEARCH}" \
        --search_global "${QUERY}" \
        --db "${DB}" \
        --id 0.5 \
        --threads 1 \
        --quiet \
        --blast6out /dev/null 2> /dev/null | \
        grep -q "ERROR SUMMARY: 0 errors" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}" "${QUERY}"
    unset DB QUERY
fi


unset QUERY_SEQ NEAR BLOCK SCATTERED UNRELATED
unset -f make_db

exit 0
