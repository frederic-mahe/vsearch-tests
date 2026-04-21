#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="allpairs_global"
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


## vsearch --allpairs_global fastafile (--acceptall | --id real)
## (--alnout | --blast6out | --fastapairs | --matched | --notmatched |
## --qsegout | --samout | --tsegout | --uc | --userout) filename
## [options]

## a short sequence used in most tests; three sequences are enough to
## form n*(n-1)/2 = 3 pairs
SEQ="ACGTACGTACGTACGTACGT"


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global reads input from stdin (-)"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --blast6out - | \
    grep -qw "s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global reads input from a regular file"
INPUT=$(mktemp)
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" > "${INPUT}"
"${VSEARCH}" \
    --allpairs_global "${INPUT}" \
    --acceptall \
    --quiet \
    --blast6out - | \
    grep -qw "s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${INPUT}"
unset INPUT

DESCRIPTION="--allpairs_global fails if input file does not exist"
"${VSEARCH}" \
    --allpairs_global /no/such/file \
    --acceptall \
    --quiet \
    --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global fails if input file is not readable"
INPUT=$(mktemp)
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" > "${INPUT}"
chmod u-r "${INPUT}"
"${VSEARCH}" \
    --allpairs_global "${INPUT}" \
    --acceptall \
    --quiet \
    --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${INPUT}" && rm -f "${INPUT}"
unset INPUT

DESCRIPTION="--allpairs_global accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global accepts a single-sequence input (no pairs to compare)"
printf ">s1\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global accepts fasta input"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global accepts fastq input"
printf "@s1\n%s\n+\nIIIIIIIIIIIIIIIIIIII\n@s2\n%s\n+\nIIIIIIIIIIIIIIIIIIII\n" \
    "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --blast6out /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global rejects input that is not fasta or fastq"
printf "not a fasta file\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --blast6out /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global fails without any output option"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global fails without --acceptall or --id"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## each output option listed in the synopsis can be used as the sole
## output option, with the exception of --qsegout and --tsegout (see
## below)
for OPT in --alnout --blast6out --fastapairs --matched --notmatched \
           --samout --uc --userout ; do
    DESCRIPTION="--allpairs_global accepts ${OPT} as sole output option"
    printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
        "${VSEARCH}" \
            --allpairs_global - \
            --acceptall \
            "${OPT}" /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

## manpage claims --qsegout and --tsegout can be used as sole output
## options, but vsearch rejects them with "No output files
## specified". They can still be used alongside another output option
## (see secondary options section). To be reviewed.
for OPT in --qsegout --tsegout ; do
    DESCRIPTION="--allpairs_global rejects ${OPT} as sole output option"
    printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
        "${VSEARCH}" \
            --allpairs_global - \
            --acceptall \
            "${OPT}" /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OPT

## ---------------------------------------------------------------- acceptall

DESCRIPTION="--allpairs_global --acceptall is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --acceptall writes alignments regardless of identity
DESCRIPTION="--allpairs_global --acceptall writes all pairs regardless of identity"
printf ">s1\nAAAA\n>s2\nCCCC\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "s1" && $2 == "s2") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --acceptall overrides --id (low identity pair still reported)
DESCRIPTION="--allpairs_global --acceptall overrides --id"
printf ">s1\nAAAA\n>s2\nCCCC\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 1.0 \
        --acceptall \
        --blast6out - \
        --quiet | \
    grep -qw "s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- id

DESCRIPTION="--allpairs_global --id is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --id without a value is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --id with a non-numeric value is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id fail \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --id below 0.0 is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id -0.5 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --id above 1.0 is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 2.0 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --id 0.0 is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --id 1.0 is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## pair with 75% identity is rejected by --id 0.9
DESCRIPTION="--allpairs_global --id filters pairs below the identity threshold"
printf ">s1\nAAAA\n>s2\nAAAT\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.9 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## pair with 75% identity is accepted by --id 0.5
DESCRIPTION="--allpairs_global --id accepts pairs above the identity threshold"
printf ">s1\nAAAA\n>s2\nAAAT\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --blast6out - \
        --quiet | \
    grep -qw "s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## --allpairs_global compares all n*(n-1)/2 pairs (here 3 pairs for 3
## sequences)
DESCRIPTION="--allpairs_global compares all n*(n-1)/2 pairs"
printf ">s1\n%s\n>s2\n%s\n>s3\n%s\n" "${SEQ}" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out - \
        --quiet | \
    wc -l | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## each sequence is compared only to those that follow it in the file;
## with two identical sequences, exactly one line is written
DESCRIPTION="--allpairs_global compares each sequence only to following sequences"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out - \
        --quiet | \
    wc -l | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --allpairs_global compares on the plus strand only: s2 is the
## reverse-complement of s1 (AC-repeat vs GT-repeat) and the pair has
## 0 % identity on the plus strand, hence no hit with --id 0.5
DESCRIPTION="--allpairs_global compares on the plus strand only"
printf ">s1\nACACACACACACACACACAC\n>s2\nGTGTGTGTGTGTGTGTGTGT\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --blast6out reports 12 tab-separated fields per alignment
DESCRIPTION="--allpairs_global --blast6out reports 12 tab-separated fields"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit NF == 12 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc reports 10 tab-separated fields per record
DESCRIPTION="--allpairs_global --uc reports 10 tab-separated fields"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --uc - \
        --quiet | \
    awk -F'\t' '{exit NF == 10 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc reports one H record per alignment; sequences with no hit get
## an N record
DESCRIPTION="--allpairs_global --uc reports one H record per alignment"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --uc - \
        --quiet | \
    awk -F'\t' '$1 == "H"' | \
    wc -l | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## identical sequences report 100.0 % identity in --blast6out
DESCRIPTION="--allpairs_global reports 100.0 identity for identical sequences"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit $3 == "100.0" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------------- iddef

for D in 0 1 2 3 4 ; do
    DESCRIPTION="--allpairs_global --iddef ${D} is accepted"
    printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
        "${VSEARCH}" \
            --allpairs_global - \
            --acceptall \
            --iddef "${D}" \
            --blast6out /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset D

DESCRIPTION="--allpairs_global --iddef above 4 is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --iddef 5 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --iddef 2 excludes terminal gaps; here 2 matches over 2
## non-terminal columns = 100.0 %
DESCRIPTION="--allpairs_global --iddef 2 excludes terminal gaps"
printf ">s1\nAAAA\n>s2\nAATT\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --iddef 2 \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit $3 == "100.0" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --iddef 0 uses CD-HIT definition: (matches)/(shortest seq length);
## here 2 matches / 4 = 50.0 %
DESCRIPTION="--allpairs_global --iddef 0 uses the CD-HIT definition"
printf ">s1\nAAAA\n>s2\nAATT\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --iddef 0 \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit $3 == "50.0" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- maxaccepts

DESCRIPTION="--allpairs_global --maxaccepts is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxaccepts 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- maxrejects

DESCRIPTION="--allpairs_global --maxrejects is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxrejects 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- qmask

for METHOD in none dust soft ; do
    DESCRIPTION="--allpairs_global --qmask ${METHOD} is accepted"
    printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
        "${VSEARCH}" \
            --allpairs_global - \
            --acceptall \
            --qmask "${METHOD}" \
            --blast6out /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset METHOD

DESCRIPTION="--allpairs_global --qmask with an invalid value is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --qmask xxx \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- threads

DESCRIPTION="--allpairs_global --threads 1 is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --threads 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --allpairs_global is multi-threaded: --threads > 1 should not warn
DESCRIPTION="--allpairs_global --threads > 1 does not warn about non-multithreaded command"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --threads 2 \
        --blast6out /dev/null 2>&1 | \
    grep -iq "not multi-threaded\|only one thread will be used" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --threads above 1024 is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --threads 1025 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global negative --threads is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --threads -1 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                           secondary options                                 #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------------- alnout

DESCRIPTION="--allpairs_global --alnout writes a human-readable alignment"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --alnout - \
        --quiet | \
    grep -q "^Query >" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- blast6out

DESCRIPTION="--allpairs_global --blast6out writes a tab-separated record"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out - \
        --quiet | \
    awk -F'\t' '{exit ($1 == "s1" && $2 == "s2" && $3 == "100.0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- bzip2_decompress

DESCRIPTION="--allpairs_global --bzip2_decompress reads bzip2-compressed stdin"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    bzip2 | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --bzip2_decompress \
        --blast6out - \
        --quiet | \
    grep -qw "s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --bzip2_decompress rejects uncompressed stdin"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --bzip2_decompress \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- fasta_width

DESCRIPTION="--allpairs_global --fasta_width is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --fasta_width 5 \
        --matched /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --fasta_width folds matched sequences"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --fasta_width 5 \
        --matched - \
        --quiet | \
    awk '/^>/ {next} {exit length($0) <= 5 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastapairs

DESCRIPTION="--allpairs_global --fastapairs writes aligned pairs in fasta format"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --fastapairs - \
        --quiet | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--allpairs_global --gzip_decompress reads gzip-compressed stdin"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    gzip | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --gzip_decompress \
        --blast6out - \
        --quiet | \
    grep -qw "s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## NOTE: unlike --bzip2_decompress, --gzip_decompress does not fail
## when the input pipe is uncompressed; the fasta data is processed
## as-is (same behaviour as other commands, to be reviewed).

## ------------------------------------------------------------------ hardmask

DESCRIPTION="--allpairs_global --hardmask is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --hardmask \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ idprefix

DESCRIPTION="--allpairs_global --idprefix is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --idprefix 4 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --idprefix rejects pairs whose prefixes differ
DESCRIPTION="--allpairs_global --idprefix rejects pairs with different prefixes"
printf ">s1\nAAAAGGGG\n>s2\nTTTTGGGG\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --idprefix 4 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------ idsuffix

DESCRIPTION="--allpairs_global --idsuffix is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --idsuffix 4 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --idsuffix rejects pairs whose suffixes differ
DESCRIPTION="--allpairs_global --idsuffix rejects pairs with different suffixes"
printf ">s1\nAAAAGGGG\n>s2\nAAAATTTT\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --idsuffix 4 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--allpairs_global --label_suffix appends a suffix to matched headers"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --label_suffix ";x=1" \
        --matched - \
        --quiet | \
    grep -qx ">s1;x=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- leftjust

DESCRIPTION="--allpairs_global --leftjust is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --leftjust \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- lengthout

DESCRIPTION="--allpairs_global --lengthout adds ;length=integer to headers"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --lengthout \
        --matched - \
        --quiet | \
    grep -qx ">s1;length=20" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- log

DESCRIPTION="--allpairs_global --log is accepted"
LOG=$(mktemp)
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --log "${LOG}" \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${LOG}"
unset LOG

DESCRIPTION="--allpairs_global --log writes the version line"
LOG=$(mktemp)
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --log "${LOG}" \
        --blast6out /dev/null \
        --quiet
grep -q "vsearch" "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${LOG}"
unset LOG

## ------------------------------------------------------------------- matched

DESCRIPTION="--allpairs_global --matched writes matched query sequences"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --matched - \
        --quiet | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- maxdiffs

DESCRIPTION="--allpairs_global --maxdiffs is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxdiffs 10 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- maxgaps

DESCRIPTION="--allpairs_global --maxgaps is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxgaps 10 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- maxhits

DESCRIPTION="--allpairs_global --maxhits is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxhits 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --maxhits 1 caps the number of reported hits per query
DESCRIPTION="--allpairs_global --maxhits caps reported hits per query"
printf ">s1\n%s\n>s2\n%s\n>s3\n%s\n" "${SEQ}" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxhits 1 \
        --blast6out - \
        --quiet | \
    awk '$1 == "s1"' | \
    wc -l | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- maxid

DESCRIPTION="--allpairs_global --maxid is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxid 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --maxid rejects pairs whose identity exceeds the given value
DESCRIPTION="--allpairs_global --maxid rejects pairs above the upper identity bound"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxid 0.8 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------ maxqsize

DESCRIPTION="--allpairs_global --maxqsize is accepted"
printf ">s1;size=1\n%s\n>s2;size=1\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --sizein \
        --maxqsize 10 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- maxqt

DESCRIPTION="--allpairs_global --maxqt is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxqt 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- maxseqlength

DESCRIPTION="--allpairs_global --maxseqlength is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --maxseqlength 100 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --maxseqlength discards sequences longer than the threshold
DESCRIPTION="--allpairs_global --maxseqlength discards longer sequences"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --maxseqlength 10 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------- maxsizeratio

DESCRIPTION="--allpairs_global --maxsizeratio is accepted"
printf ">s1;size=1\n%s\n>s2;size=1\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --sizein \
        --maxsizeratio 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- maxsl

DESCRIPTION="--allpairs_global --maxsl is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxsl 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- maxsubs

DESCRIPTION="--allpairs_global --maxsubs is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --maxsubs 10 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- mid

DESCRIPTION="--allpairs_global --mid is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --mid 0.5 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- mincols

DESCRIPTION="--allpairs_global --mincols is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --mincols 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --mincols rejects pairs with an alignment shorter than the threshold
DESCRIPTION="--allpairs_global --mincols rejects alignments shorter than the threshold"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --mincols 100 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------------- minqt

DESCRIPTION="--allpairs_global --minqt is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --minqt 0.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- minseqlength

DESCRIPTION="--allpairs_global --minseqlength is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --minseqlength 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --minseqlength discards shorter sequences"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --minseqlength 100 \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------- minsizeratio

DESCRIPTION="--allpairs_global --minsizeratio is accepted"
printf ">s1;size=1\n%s\n>s2;size=1\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --sizein \
        --minsizeratio 1.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- minsl

DESCRIPTION="--allpairs_global --minsl is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --minsl 0.0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- mintsize

DESCRIPTION="--allpairs_global --mintsize is accepted"
printf ">s1;size=5\n%s\n>s2;size=5\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --sizein \
        --mintsize 1 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- minwordmatches

DESCRIPTION="--allpairs_global --minwordmatches is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --minwordmatches 0 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- n_mismatch

DESCRIPTION="--allpairs_global --n_mismatch is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --n_mismatch \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--allpairs_global --no_progress is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --no_progress \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- notmatched

DESCRIPTION="--allpairs_global --notmatched writes unmatched sequences"
printf ">s1\nAAAA\n>s2\nCCCC\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.9 \
        --notmatched - \
        --quiet | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--allpairs_global --notrunclabels retains full headers"
printf ">s1 extra words\n%s\n>s2 more\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --notrunclabels \
        --matched - \
        --quiet | \
    grep -qx ">s1 extra words" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ output_no_hits

DESCRIPTION="--allpairs_global --output_no_hits is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --output_no_hits \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --output_no_hits writes queries with no hit as an asterisk target
DESCRIPTION="--allpairs_global --output_no_hits writes non-matching queries"
printf ">s1\nAAAA\n>s2\nCCCC\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.9 \
        --output_no_hits \
        --blast6out - \
        --quiet | \
    awk -F'\t' '$2 == "*"' | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ qsegout

DESCRIPTION="--allpairs_global --qsegout writes the aligned query segment"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out /dev/null \
        --qsegout - \
        --quiet | \
    grep -qw ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- query_cov

DESCRIPTION="--allpairs_global --query_cov is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --query_cov 0.5 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- quiet

DESCRIPTION="--allpairs_global --quiet suppresses stderr"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out /dev/null \
        --quiet 2>&1 > /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- relabel

DESCRIPTION="--allpairs_global --relabel renames matched sequences"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --relabel "renamed" \
        --matched - \
        --quiet | \
    grep -qx ">renamed1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- relabel_keep

DESCRIPTION="--allpairs_global --relabel_keep retains the old header after a space"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --relabel "renamed" \
        --relabel_keep \
        --matched - \
        --quiet | \
    grep -qx ">renamed1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- relabel_md5

DESCRIPTION="--allpairs_global --relabel_md5 renames sequences with md5 digests"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --relabel_md5 \
        --matched - \
        --quiet | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- relabel_self

DESCRIPTION="--allpairs_global --relabel_self is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --relabel_self \
        --matched /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- relabel_sha1

DESCRIPTION="--allpairs_global --relabel_sha1 renames sequences with sha1 digests"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --relabel_sha1 \
        --matched - \
        --quiet | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --relabel and --relabel_md5 are mutually exclusive"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --relabel "renamed" \
        --relabel_md5 \
        --matched /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------------------------------------------------------------- rightjust

DESCRIPTION="--allpairs_global --rightjust is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --rightjust \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- rowlen

DESCRIPTION="--allpairs_global --rowlen is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --rowlen 64 \
        --alnout /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- samheader

DESCRIPTION="--allpairs_global --samheader adds @HD lines to --samout"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --samout - \
        --samheader \
        --quiet | \
    grep -q "^@HD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- samout

DESCRIPTION="--allpairs_global --samout writes a SAM record for each pair"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --samout - \
        --quiet | \
    awk -F'\t' '{exit $1 == "s1" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- sample

DESCRIPTION="--allpairs_global --sample adds ;sample=string to headers"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --sample "ABC" \
        --matched - \
        --quiet | \
    grep -qx ">s1;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- self

DESCRIPTION="--allpairs_global --self is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --self \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --self rejects pairs where query and target share the same label
DESCRIPTION="--allpairs_global --self rejects pairs with identical labels"
printf ">s\n%s\n>s\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --self \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------- selfid

DESCRIPTION="--allpairs_global --selfid is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --selfid \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --selfid rejects pairs with identical sequences
DESCRIPTION="--allpairs_global --selfid rejects pairs with identical sequences"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --selfid \
        --blast6out - \
        --quiet | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------ sizein

DESCRIPTION="--allpairs_global --sizein is accepted"
printf ">s1;size=5\n%s\n>s2;size=5\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --sizein \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- sizeout

DESCRIPTION="--allpairs_global --sizeout is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --sizeout \
        --matched /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizeout preserves the size annotation read with --sizein
DESCRIPTION="--allpairs_global --sizeout preserves size annotations"
printf ">s1;size=5\n%s\n>s2;size=3\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --sizein \
        --sizeout \
        --matched - \
        --quiet | \
    grep -qx ">s1;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- target_cov

DESCRIPTION="--allpairs_global --target_cov is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.5 \
        --target_cov 0.5 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ top_hits_only

DESCRIPTION="--allpairs_global --top_hits_only is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --top_hits_only \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- tsegout

DESCRIPTION="--allpairs_global --tsegout writes the aligned target segment"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --blast6out /dev/null \
        --tsegout - \
        --quiet | \
    grep -qw ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- uc

DESCRIPTION="--allpairs_global --uc writes records of type H for alignments"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --uc - \
        --quiet | \
    awk -F'\t' '$1 == "H" {found = 1} END {exit found ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- userfields

DESCRIPTION="--allpairs_global --userfields restricts --userout fields"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --userout - \
        --userfields "query+target+id" \
        --quiet | \
    awk -F'\t' '{exit ($1 == "s1" && $2 == "s2" && $3 == "100.0" && NF == 3) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ userout

DESCRIPTION="--allpairs_global --userout writes requested fields"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --userout - \
        --userfields "query+target" \
        --quiet | \
    awk -F'\t' '{exit ($1 == "s1" && $2 == "s2") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- weak_id

DESCRIPTION="--allpairs_global --weak_id is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.9 \
        --weak_id 0.5 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --weak_id reports pairs above the weak threshold that fall below --id
DESCRIPTION="--allpairs_global --weak_id reports pairs between weak_id and id"
printf ">s1\nAAAA\n>s2\nAATT\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --id 0.9 \
        --weak_id 0.4 \
        --blast6out - \
        --quiet | \
    grep -qw "s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- wordlength

DESCRIPTION="--allpairs_global --wordlength is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --wordlength 8 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --wordlength below 3 is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --wordlength 2 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --wordlength above 15 is rejected"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --wordlength 16 \
        --blast6out /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------------------------------------------------------------------- xee

DESCRIPTION="--allpairs_global --xee strips ;ee=float from headers"
printf ">s1;ee=0.5\n%s\n>s2;ee=0.5\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --xee \
        --matched - \
        --quiet | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- xlength

DESCRIPTION="--allpairs_global --xlength strips ;length=integer from headers"
printf ">s1;length=20\n%s\n>s2;length=20\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --xlength \
        --matched - \
        --quiet | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- xsize

DESCRIPTION="--allpairs_global --xsize strips ;size=integer from headers"
printf ">s1;size=3\n%s\n>s2;size=3\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --xsize \
        --matched - \
        --quiet | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                       pairwise alignment options                            #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --gapext is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --gapext 2I/1E \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --gapopen is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --gapopen 20I/2E \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --match is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --match 2 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --mismatch is accepted"
printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --mismatch -4 \
        --blast6out /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## the manpage lists these options as accepted for compatibility with
## usearch but with no effect on the results
for OPT_PAIR in "--band 16" "--fulldp" "--hspw 5" "--minhsp 16" \
                "--pattern xxx" "--slots 1024" "--xdrop_nw 16" ; do
    OPT_NAME="${OPT_PAIR%% *}"
    DESCRIPTION="--allpairs_global ${OPT_NAME} is accepted (ignored)"
    # shellcheck disable=SC2086
    printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
        "${VSEARCH}" \
            --allpairs_global - \
            --acceptall \
            ${OPT_PAIR} \
            --blast6out /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT_PAIR OPT_NAME


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## options not listed in the allpairs_global manpage or in the valid
## options list reported by vsearch; a user might reasonably try them
## by analogy with --usearch_global or --search_exact
for OPT in --db --strand --dbmask --dbmatched --dbnotmatched \
           --biomout --otutabout --mothur_shared_out \
           --lcaout --lca_cutoff --uc_allhits --fastqout ; do
    DESCRIPTION="--allpairs_global rejects ${OPT} as an invalid option"
    printf ">s1\n%s\n>s2\n%s\n" "${SEQ}" "${SEQ}" | \
        "${VSEARCH}" \
            --allpairs_global - \
            --acceptall \
            "${OPT}" /dev/null \
            --blast6out /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OPT


## clean up common variables before the fixed bugs and memory leaks
## sections
unset SEQ


#*****************************************************************************#
#                                                                             #
#                               fixed bugs                                    #
#                                                                             #
#*****************************************************************************#

## 2025-08-21: showalign.cc (alnout) refactoring
DESCRIPTION="--allpairs_global --alnout no extra empty final alignment block"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --rowlen 1 \
        --alnout - | \
    awk '{if (/^Qry/) {++block}} END {exit block == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    ## - memory leak in userfields: fixed in b109d62b
    ## - use of uninitialised value in samout: fixed in 8bab2444
    LOG=$(mktemp)
    FASTA=$(mktemp)
    printf ">s1\nA\n>s2\nA\n" > "${FASTA}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        "${VSEARCH}" \
        --allpairs_global "${FASTA}" \
        --acceptall \
        --alnout /dev/null \
        --blast6out /dev/null \
        --fastapairs /dev/null \
        --log /dev/null \
        --matched /dev/null \
        --notmatched /dev/null \
        --samout /dev/null \
        --uc /dev/null \
        --userout /dev/null \
        --userfields query+target+id 2> /dev/null
    DESCRIPTION="--allpairs_global valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--allpairs_global valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTA}"
fi


exit 0
