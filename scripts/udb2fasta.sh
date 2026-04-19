#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="udb2fasta"
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


## helper: build a UDB file from a fasta string passed on stdin
## (--dbmask none to keep the sequence unmasked and predictable)
make_udb () {
    local udb="${1}"
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --output "${udb}" \
        --quiet 2> /dev/null
}


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## vsearch --udb2fasta udbfile --output outputfile [options]

SEQ="ACGTACGTACGTACGTACGTACGTACGTACGT"

DESCRIPTION="--udb2fasta is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--udb2fasta fails if UDB file does not exist"
"${VSEARCH}" \
    --udb2fasta /no/such/file \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--udb2fasta fails with a non-UDB input file"
TMPFA=$(mktemp)
printf ">s\n%s\n" "${SEQ}" > "${TMPFA}"
"${VSEARCH}" \
    --udb2fasta "${TMPFA}" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--udb2fasta fails if input file is not readable"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
chmod u-r "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMPUDB}" && rm -f "${TMPUDB}"
unset TMPUDB

## --output is mandatory
DESCRIPTION="--udb2fasta fails without --output"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--output writes to a regular file"
TMPUDB=$(mktemp)
TMPFA=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output "${TMPFA}" \
    --quiet 2> /dev/null
[[ -s "${TMPFA}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPFA}"
unset TMPUDB TMPFA


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## udb2fasta writes sequences in fasta format (header + sequence)
DESCRIPTION="--udb2fasta writes a fasta header"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--udb2fasta writes the stored sequence"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx "${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## a round-trip (fasta -> udb -> fasta) preserves sequences (with --dbmask none)
DESCRIPTION="round-trip fasta -> udb -> fasta preserves sequence content"
TMPUDB=$(mktemp)
TMPIN=$(mktemp)
TMPOUT=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" > "${TMPIN}"
"${VSEARCH}" \
    --makeudb_usearch "${TMPIN}" \
    --dbmask none \
    --output "${TMPUDB}" \
    --quiet 2> /dev/null
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output "${TMPOUT}" \
    --quiet 2> /dev/null
diff -q "${TMPIN}" "${TMPOUT}" > /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPIN}" "${TMPOUT}"
unset TMPUDB TMPIN TMPOUT


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --fasta_width: default 80, set to 0 to suppress folding

DESCRIPTION="--fasta_width is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --fasta_width 80 \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## a 90-nt sequence is folded on 2 lines with --fasta_width 80 (default)
DESCRIPTION="--udb2fasta folds long sequences at the default width (80)"
TMPUDB=$(mktemp)
SEQ90=$(printf 'ACGTACGTAC%.0s' {1..9})
printf ">s\n%s\n" "${SEQ90}" | make_udb "${TMPUDB}"
[[ $("${VSEARCH}" --udb2fasta "${TMPUDB}" --output /dev/stdout --quiet 2> /dev/null | wc -l) -eq 3 ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB SEQ90

## --fasta_width 0 suppresses folding
DESCRIPTION="--fasta_width 0 suppresses folding"
TMPUDB=$(mktemp)
SEQ90=$(printf 'ACGTACGTAC%.0s' {1..9})
printf ">s\n%s\n" "${SEQ90}" | make_udb "${TMPUDB}"
[[ $("${VSEARCH}" --udb2fasta "${TMPUDB}" --output /dev/stdout --quiet --fasta_width 0 2> /dev/null | wc -l) -eq 2 ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB SEQ90

## --label_suffix: append a string to each header

DESCRIPTION="--label_suffix is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --label_suffix ";x=1" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--label_suffix appends the given string"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --label_suffix ";x=1" \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx ">s1;x=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --lengthout: add ;length=integer to each header

DESCRIPTION="--lengthout is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --lengthout \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--lengthout adds the sequence length annotation"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --lengthout \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx ">s1;length=32" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --log: write messages to a file

DESCRIPTION="--log is accepted"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/null \
    --log "${TMPLOG}" 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

DESCRIPTION="--log writes to the specified file"
TMPUDB=$(mktemp)
TMPLOG=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/null \
    --log "${TMPLOG}" 2> /dev/null
[[ -s "${TMPLOG}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPLOG}"
unset TMPUDB TMPLOG

## --no_progress

DESCRIPTION="--no_progress is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --no_progress \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --quiet

DESCRIPTION="--quiet is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--quiet suppresses stderr output"
TMPUDB=$(mktemp)
TMPERR=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --output /dev/null \
    --quiet 2> "${TMPERR}"
[[ ! -s "${TMPERR}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}" "${TMPERR}"
unset TMPUDB TMPERR

## --relabel: replace each header with a prefix + a ticker

DESCRIPTION="--relabel is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel "x" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--relabel replaces headers with a prefix + ticker"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel "x" \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx ">x1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --relabel_keep: retain old identifier after the new one

DESCRIPTION="--relabel_keep is accepted (with --relabel)"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel "x" \
    --relabel_keep \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--relabel_keep retains old identifier after the new one"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel "x" \
    --relabel_keep \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx ">x1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --relabel_md5

DESCRIPTION="--relabel_md5 is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel_md5 \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--relabel_md5 replaces headers with an MD5 digest"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel_md5 \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --relabel_self

DESCRIPTION="--relabel_self is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel_self \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--relabel_self uses the sequence itself as the new header"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel_self \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx ">${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --relabel_sha1

DESCRIPTION="--relabel_sha1 is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel_sha1 \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--relabel_sha1 replaces headers with a SHA1 digest"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel_sha1 \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## relabel options are mutually exclusive
DESCRIPTION="--relabel and --relabel_md5 cannot be combined"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel "x" \
    --relabel_md5 \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--relabel and --relabel_sha1 cannot be combined"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel "x" \
    --relabel_sha1 \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--relabel_md5 and --relabel_sha1 cannot be combined"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --relabel_md5 \
    --relabel_sha1 \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --sample

DESCRIPTION="--sample is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --sample "ABC" \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--sample adds ;sample=<string> to the header"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --sample "ABC" \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -q ";sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --sizein: abundance is not stored in the UDB file, so --sizein
## has no observable effect on the output (all entries become size=1
## when combined with --sizeout)
DESCRIPTION="--sizein is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --sizein \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --sizeout: add ;size=<integer> to headers (defaults to 1)

DESCRIPTION="--sizeout is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --sizeout \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--sizeout adds ;size=1 (abundance is not stored in UDB)"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --sizeout \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --xee, --xlength, --xsize: strip annotations from stored headers

DESCRIPTION="--xee is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --xee \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --notrunclabels during makeudb_usearch keeps the whole header;
## --xee then strips ;ee=... from it
DESCRIPTION="--xee strips expected-error annotations"
TMPUDB=$(mktemp)
printf ">s1;ee=0.5;\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --notrunclabels \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --xee \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qE "^>s1" && \
    "${VSEARCH}" \
        --udb2fasta "${TMPUDB}" \
        --xee \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
        grep -qv "ee=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--xlength is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --xlength \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--xlength strips length annotations"
TMPUDB=$(mktemp)
printf ">s1;length=32;\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --notrunclabels \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --xlength \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qv "length=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--xsize is accepted"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --xsize \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--xsize strips abundance annotations"
TMPUDB=$(mktemp)
printf ">s1;size=5;\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --dbmask none \
        --notrunclabels \
        --output "${TMPUDB}" \
        --quiet 2> /dev/null
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --xsize \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qv "size=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## combination: --label_suffix after --lengthout
DESCRIPTION="--lengthout combined with --label_suffix"
TMPUDB=$(mktemp)
printf ">s1\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --lengthout \
    --label_suffix ";x=1" \
    --output /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx ">s1;x=1;length=32" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## --threads: accepted but command is not multithreaded

DESCRIPTION="--threads is accepted (ignored, no observable effect)"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --threads 2 \
    --output /dev/null \
    --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## --minseqlength is not accepted by udb2fasta
DESCRIPTION="--minseqlength is rejected"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --minseqlength 1 \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --dbmask is not accepted by udb2fasta (masking is fixed at UDB creation)
DESCRIPTION="--dbmask is rejected"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --dbmask none \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

## --wordlength is fixed at UDB creation
DESCRIPTION="--wordlength is rejected"
TMPUDB=$(mktemp)
printf ">s\n%s\n" "${SEQ}" | make_udb "${TMPUDB}"
"${VSEARCH}" \
    --udb2fasta "${TMPUDB}" \
    --wordlength 8 \
    --output /dev/null \
    --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    LOG=$(mktemp)
    UDB=$(mktemp)
    printf "@s\nACGTACGT\n+\nIIIIIIII\n" | \
        "${VSEARCH}" \
            --makeudb_usearch - \
            --minseqlength 1 \
            --quiet \
            --output "${UDB}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --udb2fasta "${UDB}" \
        --output /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--udb2fasta valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--udb2fasta valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${UDB}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


unset SEQ
exit 0
