#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="search_exact"
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


## vsearch --search_exact fastxfile --db fastafile (--alnout | --biomout
## | --blast6out | --fastapairs | --matched | --mothur_shared_out |
## --notmatched | --otutabout | --qsegout | --samout | --tsegout | --uc
## | --userout) outputfile [options]

## A 20-nt sequence used in most tests; both query and target are
## identical by default, producing a single full-length exact match.
SEQ="ACGTACGTACGTACGTACGT"


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_exact is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact reads query from stdin (-)"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --quiet \
        --blast6out - | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact reads query from a regular file"
DB=$(mktemp)
QUERY=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" > "${QUERY}"
"${VSEARCH}" \
    --search_exact "${QUERY}" \
    --db "${DB}" \
    --quiet \
    --blast6out - | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${QUERY}"
unset DB QUERY

DESCRIPTION="--search_exact fails if query file does not exist"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
"${VSEARCH}" \
    --search_exact /no/such/file \
    --db "${DB}" \
    --quiet \
    --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact fails if query file is not readable"
DB=$(mktemp)
QUERY=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" > "${QUERY}"
chmod u-r "${QUERY}"
"${VSEARCH}" \
    --search_exact "${QUERY}" \
    --db "${DB}" \
    --quiet \
    --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${QUERY}" && rm -f "${QUERY}" "${DB}"
unset DB QUERY

DESCRIPTION="--search_exact accepts empty query input"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf "" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact accepts fasta query input"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact accepts fastq query input"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf "@q\n%s\n+\nIIIIIIIIIIIIIIIIIIII\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact rejects query that is not fasta or fastq"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf "not a fasta file\n" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact fails without --db"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--search_exact fails if --db file does not exist"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db /no/such/file \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## NOTE: an empty --db file triggers an assertion failure in vsearch
## (core dumped). The manpage does not specify the behaviour for an
## empty database, but other search commands (e.g., --uchime_ref)
## accept it silently. To be reviewed.

DESCRIPTION="--search_exact fails without any output option"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
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
    DESCRIPTION="--search_exact accepts ${OPT} as sole output option"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --search_exact - \
            --db "${DB}" \
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
    DESCRIPTION="--search_exact rejects ${OPT} as sole output option"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --search_exact - \
            --db "${DB}" \
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

## identical query and target produce a full-length exact match
DESCRIPTION="--search_exact reports a hit when query and target are identical"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q" && $2 == "d" && $3 == "100.0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## a single mismatch in a full-length alignment produces no hit
DESCRIPTION="--search_exact reports no hit when one nucleotide differs"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nTCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## matches must be full-length: a query that is a prefix of the target
## does not produce a hit
DESCRIPTION="--search_exact reports no hit when query is a prefix of target"
DB=$(mktemp)
printf ">d\n%sAAAAA\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## matches must be full-length: a query longer than the target does
## not produce a hit
DESCRIPTION="--search_exact reports no hit when query is longer than target"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%sAAAAA\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## default strand is plus only: a reverse-complemented query does not
## match (using a non-palindromic sequence)
DESCRIPTION="--search_exact default searches plus strand only"
DB=$(mktemp)
printf ">d\nAAAACCCCGGGGTTTTAAAA\n" > "${DB}"
printf ">q\nTTTTAAAACCCCGGGGTTTT\n" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## by default, non-matching queries are not written to --blast6out
DESCRIPTION="--search_exact does not report non-matching queries by default"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nTCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --blast6out reports 12 tab-separated fields per match
DESCRIPTION="--search_exact --blast6out reports 12 tab-separated fields"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit NF == 12 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --uc reports 10 tab-separated fields for each hit record
DESCRIPTION="--search_exact --uc reports 10 tab-separated fields"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --uc - \
        --quiet | \
    awk -F'\t' '{exit NF == 10 ? 0 : 1}' && \
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
    DESCRIPTION="--search_exact --dbmask ${METHOD} is accepted"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --search_exact - \
            --db "${DB}" \
            --dbmask "${METHOD}" \
            --blast6out /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset METHOD

DESCRIPTION="--search_exact --dbmask invalid is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --dbmask xxx \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- qmask

for METHOD in none dust soft ; do
    DESCRIPTION="--search_exact --qmask ${METHOD} is accepted"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --search_exact - \
            --db "${DB}" \
            --qmask "${METHOD}" \
            --blast6out /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset METHOD

DESCRIPTION="--search_exact --qmask invalid is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --qmask xxx \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ strand

DESCRIPTION="--search_exact --strand plus is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --strand plus \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --strand both is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --strand both \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --strand both finds a reverse-complemented match (using a
## non-palindromic sequence)
DESCRIPTION="--search_exact --strand both matches the reverse complement"
DB=$(mktemp)
printf ">d\nAAAACCCCGGGGTTTTAAAA\n" > "${DB}"
printf ">q\nTTTTAAAACCCCGGGGTTTT\n" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --strand both \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --strand invalid is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --strand xxx \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ threads

DESCRIPTION="--search_exact --threads 1 is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --threads 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --search_exact is multithreaded: --threads > 1 should not produce a
## warning about the command not being multithreaded
DESCRIPTION="--search_exact --threads > 1 does not warn about non-multithreaded command"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --threads 2 \
        --blast6out /dev/null 2>&1 | \
    grep -iq "not multi-threaded\|only one thread will be used" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --threads above 1024 is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --threads 1025 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact negative --threads is rejected"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
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

## ---------------------------------------------------------------- bzip2_decompress

DESCRIPTION="--search_exact --bzip2_decompress reads bzip2-compressed stdin"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    bzip2 | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --bzip2_decompress \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --bzip2_decompress rejects uncompressed stdin"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --bzip2_decompress \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ dbmatched

DESCRIPTION="--search_exact --dbmatched writes matched target sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out /dev/null \
        --dbmatched - \
        --quiet | \
    grep -qw ">d" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --dbmatched --sizeout reports the number of matching queries"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
(
    printf ">q1\n%s\n" "${SEQ}"
    printf ">q2\n%s\n" "${SEQ}"
) | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out /dev/null \
        --dbmatched - \
        --sizeout \
        --quiet | \
    grep -qx ">d;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- dbnotmatched

DESCRIPTION="--search_exact --dbnotmatched writes unmatched target sequences"
DB=$(mktemp)
printf ">d1\n%s\n>d2\nAAAAAAAAAAAAAAAAAAAA\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out /dev/null \
        --dbnotmatched - \
        --quiet | \
    grep -qw ">d2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- fasta_width

DESCRIPTION="--search_exact --fasta_width is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --fasta_width 5 \
        --matched /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --fasta_width folds sequences in the matched output file (here,
## onto four 5-nt lines)
DESCRIPTION="--search_exact --fasta_width folds matched sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --fasta_width 5 \
        --matched - \
        --quiet | \
    awk '/^>/ {next} {exit length($0) <= 5 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--search_exact --gzip_decompress reads gzip-compressed stdin"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    gzip | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --gzip_decompress \
        --blast6out - \
        --quiet | \
    grep -qw "q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## NOTE: unlike --bzip2_decompress, --gzip_decompress does not fail
## when the input pipe is uncompressed; the fasta data is processed
## as-is. To be reviewed.

## ------------------------------------------------------------------ hardmask

## with --hardmask and --qmask soft, the lowercase query is masked
## with Ns and no longer matches the unmasked target
DESCRIPTION="--search_exact --hardmask is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --hardmask \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--search_exact --label_suffix is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --label_suffix ";x=1" \
        --matched /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --label_suffix appends the suffix to matched headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --label_suffix ";x=1" \
        --matched - \
        --quiet | \
    grep -qx ">q;x=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- lca_cutoff

DESCRIPTION="--search_exact --lca_cutoff is accepted"
DB=$(mktemp)
printf ">d;tax=k:A\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --lca_cutoff 1.0 \
        --lcaout /dev/null \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- lcaout

DESCRIPTION="--search_exact --lcaout is accepted"
DB=$(mktemp)
printf ">d;tax=k:A\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --lcaout /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --lcaout writes the taxonomic lineage"
DB=$(mktemp)
printf ">d;tax=k:Archaea\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --lcaout - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q" && $2 ~ /Archaea/) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- lengthout

DESCRIPTION="--search_exact --lengthout adds ;length=integer to headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --lengthout \
        --matched - \
        --quiet | \
    grep -qx ">q;length=20" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- log

DESCRIPTION="--search_exact --log is accepted"
DB=$(mktemp)
LOG=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --log "${LOG}" \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${LOG}"
unset DB LOG

DESCRIPTION="--search_exact --log writes the version line"
DB=$(mktemp)
LOG=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --log "${LOG}" \
        --blast6out /dev/null \
        --quiet
grep -q "vsearch" "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}" "${LOG}"
unset DB LOG

## ------------------------------------------------------------------- maxhits

DESCRIPTION="--search_exact --maxhits is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --maxhits 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --maxhits caps the number of reported hits per query
DESCRIPTION="--search_exact --maxhits caps the number of reported hits"
DB=$(mktemp)
printf ">d1\n%s\n>d2\n%s\n" "${SEQ}" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --maxhits 1 \
        --blast6out - \
        --quiet | \
    wc -l | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ maxqsize

DESCRIPTION="--search_exact --maxqsize is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --sizein \
        --maxqsize 10 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --maxqsize rejects queries with abundance greater than the limit
DESCRIPTION="--search_exact --maxqsize rejects queries above the abundance limit"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=5\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --sizein \
        --maxqsize 2 \
        --blast6out - \
        --quiet | \
    grep -q "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ maxqt

DESCRIPTION="--search_exact --maxqt is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --maxqt 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- maxseqlength

DESCRIPTION="--search_exact --maxseqlength is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --maxseqlength 100 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --maxseqlength discards longer query sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --maxseqlength 10 \
        --blast6out - \
        --quiet | \
    grep -q "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- maxsizeratio

DESCRIPTION="--search_exact --maxsizeratio is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --maxsizeratio 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- maxsl

DESCRIPTION="--search_exact --maxsl is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --maxsl 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- mincols

DESCRIPTION="--search_exact --mincols is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --mincols 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- minqt

DESCRIPTION="--search_exact --minqt is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --minqt 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- minseqlength

DESCRIPTION="--search_exact --minseqlength is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --minseqlength 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --minseqlength discards shorter query sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --minseqlength 100 \
        --blast6out - \
        --quiet | \
    grep -q "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- minsizeratio

DESCRIPTION="--search_exact --minsizeratio is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --minsizeratio 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------------- minsl

DESCRIPTION="--search_exact --minsl is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --minsl 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- mintsize

DESCRIPTION="--search_exact --mintsize is accepted"
DB=$(mktemp)
printf ">d;size=5\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --sizein \
        --mintsize 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --mintsize rejects target sequences with abundance below the limit
DESCRIPTION="--search_exact --mintsize rejects low-abundance targets"
DB=$(mktemp)
printf ">d;size=2\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --sizein \
        --mintsize 10 \
        --blast6out - \
        --quiet | \
    grep -q "q" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- no_progress

DESCRIPTION="--search_exact --no_progress is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --no_progress \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- notrunclabels

DESCRIPTION="--search_exact --notrunclabels retains full query headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q extra words\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --notrunclabels \
        --matched - \
        --quiet | \
    grep -qx ">q extra words" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- output_no_hits

DESCRIPTION="--search_exact --output_no_hits is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --output_no_hits \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --output_no_hits writes non-matching queries to --blast6out
DESCRIPTION="--search_exact --output_no_hits writes non-matching queries"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\nTCGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --output_no_hits \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q" && $2 == "*") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ qsegout

DESCRIPTION="--search_exact --qsegout writes the aligned query segment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out /dev/null \
        --qsegout - \
        --quiet | \
    grep -qw ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- quiet

DESCRIPTION="--search_exact --quiet suppresses messages on stderr"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- relabel

DESCRIPTION="--search_exact --relabel renames matched sequences"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --relabel "renamed" \
        --matched - \
        --quiet | \
    grep -qx ">renamed1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- relabel_keep

DESCRIPTION="--search_exact --relabel_keep retains the old header after a space"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --relabel "renamed" \
        --relabel_keep \
        --matched - \
        --quiet | \
    grep -qx ">renamed1 q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## -------------------------------------------------------------- relabel_md5

DESCRIPTION="--search_exact --relabel_md5 renames sequences with md5 digests"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --relabel_md5 \
        --matched - \
        --quiet | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- relabel_self

DESCRIPTION="--search_exact --relabel_self is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --relabel_self \
        --matched /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------- relabel_sha1

DESCRIPTION="--search_exact --relabel_sha1 renames sequences with sha1 digests"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --relabel_sha1 \
        --matched - \
        --quiet | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

DESCRIPTION="--search_exact --relabel and --relabel_md5 are mutually exclusive"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --relabel "renamed" \
        --relabel_md5 \
        --matched /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- rowlen

DESCRIPTION="--search_exact --rowlen is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --alnout /dev/null \
        --rowlen 64 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------- samheader

DESCRIPTION="--search_exact --samheader adds @HD lines to --samout"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --samout - \
        --samheader \
        --quiet | \
    grep -q "^@HD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- sample

DESCRIPTION="--search_exact --sample adds ;sample=string to headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --sample "ABC" \
        --matched - \
        --quiet | \
    grep -qx ">q;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- self

DESCRIPTION="--search_exact --self is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --self \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --self rejects matches where query and target share the same label
DESCRIPTION="--search_exact --self rejects matches with identical labels"
DB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" > "${DB}"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --self \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------ sizein

DESCRIPTION="--search_exact --sizein is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=5\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --sizein \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- sizeout

DESCRIPTION="--search_exact --sizeout adds ;size=1 to unannotated headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --sizeout \
        --matched - \
        --quiet | \
    grep -qx ">q;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- top_hits_only

DESCRIPTION="--search_exact --top_hits_only is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --top_hits_only \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- tsegout

DESCRIPTION="--search_exact --tsegout writes the aligned target segment"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --blast6out /dev/null \
        --tsegout - \
        --quiet | \
    grep -qw ">d" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------- uc_allhits

DESCRIPTION="--search_exact --uc_allhits reports all hits per query"
DB=$(mktemp)
printf ">d1\n%s\n>d2\n%s\n" "${SEQ}" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
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

## ---------------------------------------------------------------- userfields

DESCRIPTION="--search_exact --userfields restricts --userout fields"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --userout - \
        --userfields "query+target+id" \
        --quiet | \
    awk -F'\t' '{exit ($1 == "q" && $2 == "d" && $3 == "100.0" && NF == 3) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ---------------------------------------------------------------------- xee

DESCRIPTION="--search_exact --xee strips ;ee=float from headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;ee=0.5\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --xee \
        --matched - \
        --quiet | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ------------------------------------------------------------------- xlength

DESCRIPTION="--search_exact --xlength strips ;length=integer from headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;length=20\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --xlength \
        --matched - \
        --quiet | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## --------------------------------------------------------------------- xsize

DESCRIPTION="--search_exact --xsize strips ;size=integer from headers"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q;size=3\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
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
#                       pairwise alignment options                            #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------------- match

DESCRIPTION="--search_exact --match is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --match 2 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB

## ----------------------------------------------------------------- mismatch

DESCRIPTION="--search_exact --mismatch is accepted"
DB=$(mktemp)
printf ">d\n%s\n" "${SEQ}" > "${DB}"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --search_exact - \
        --db "${DB}" \
        --mismatch -4 \
        --blast6out /dev/null \
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

## the manpage states that --id, --maxaccepts and --maxrejects do not
## apply and are not accepted
for OPT_PAIR in "--id 1.0" "--maxaccepts 1" "--maxrejects 1" ; do
    OPT_NAME="${OPT_PAIR%% *}"
    DESCRIPTION="--search_exact rejects ${OPT_NAME}"
    DB=$(mktemp)
    printf ">d\n%s\n" "${SEQ}" > "${DB}"
    # shellcheck disable=SC2086
    printf ">q\n%s\n" "${SEQ}" | \
        "${VSEARCH}" \
            --search_exact - \
            --db "${DB}" \
            ${OPT_PAIR} \
            --blast6out /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
    rm -f "${DB}"
    unset DB
done
unset OPT_PAIR OPT_NAME


## clean up common variables before the fixed bugs and memory leaks sections
unset SEQ


#*****************************************************************************#
#                                                                             #
#                               fixed bugs                                    #
#                                                                             #
#*****************************************************************************#

# CIGAR string is wrong for sequences of length 2 to 9
# then it is empty for sequences of length 10 and more
DESCRIPTION="search_exact: --samout reports CIGAR string (1M)"
SEQ="A"
"${VSEARCH}" \
    --search_exact <(printf ">s\n%s\n" "${SEQ}") \
    --db <(printf ">s\n%s\n" "${SEQ}") \
    --quiet \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {exit $6 == "1M" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="search_exact: --samout reports CIGAR string (10M)"
#    1...5...10
SEQ="AAAAAAAAAA"
"${VSEARCH}" \
    --search_exact <(printf ">s\n%s\n" "${SEQ}") \
    --db <(printf ">s\n%s\n" "${SEQ}") \
    --quiet \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {exit $6 == "10M" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    ## memory leak in userfields: fixed in 45cd56d6
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
        --search_exact "${FASTA}" \
        --db "${DB}" \
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
        --userfields query+target+id 2> /dev/null
    DESCRIPTION="--search_exact valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--search_exact valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTA}" "${DB}"
fi


exit 0
