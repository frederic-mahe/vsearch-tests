#!/bin/bash -

## Print a header
SCRIPT_NAME="rereplicate"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    exit 1
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
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

## --------------------------------------------------------------------- output
DESCRIPTION="--rereplicate requires --output"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--rereplicate fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--rereplicate outputs in fasta format"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq ">s1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate empty input -> empty output"
printf "" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

# The output file does not contain abundance information (unless
# --sizeout is used)
DESCRIPTION="--rereplicate removes size annotations (default)"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -q "size=" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--rereplicate output is n times abundance (implicit abundance)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate output is n times abundance (size=1)"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate output is n times abundance (size=9)"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 9 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# sequence labels are identical for the same sequence,
DESCRIPTION="--rereplicate outputs n times identical labels (size=9)"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output - 2> /dev/null | \
    awk '/^>s1$/ {s += 1} END {exit s == 9 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# can input be fastq format? no
DESCRIPTION="--rereplicate rejects fastq format"
printf "@s1;size=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# warning if abundance annotations are missing
DESCRIPTION="--rereplicate warns if abundance annotations are missing"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output /dev/null 2>&1 | \
    grep -iq "^warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate replaces missing abundance annotations with size=1"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output - 2> /dev/null | \
    awk '/^>s1$/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------------- sizein

DESCRIPTION="--rereplicate accepts --sizein"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --sizein \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# accepts both size=1 and size=1;
DESCRIPTION="--rereplicate --sizein accepts size=n"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --sizein \
        --output - 2> /dev/null | \
    awk '/^>s1$/ {s += 1} END {exit s == 9 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --sizein accepts size=n;"
printf ">s1;size=9;\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --sizein \
        --output - 2> /dev/null | \
    awk '/^>s1$/ {s += 1} END {exit s == 9 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# no need to specify --sizein
DESCRIPTION="--rereplicate --sizein is implied"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output - 2> /dev/null | \
    awk '/^>s1$/ {s += 1} END {exit s == 9 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

DESCRIPTION="--rereplicate accepts --sizeout"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --sizeout \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# when --sizeout is specified, an abundance of 1 is used
DESCRIPTION="--rereplicate --sizeout outputs size annotations (;size=1)"
printf ">s1;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --sizeout \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">s1;size=1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --sizeout outputs size annotations (missing annotation)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --sizeout \
        --output - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">s1;size=1A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expect 'size=1' 9 times 
DESCRIPTION="--rereplicate --sizeout outputs size annotations (;size=9)"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --sizeout \
        --output - 2> /dev/null | \
    grep -qw ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# same results with --sizein 
DESCRIPTION="--rereplicate --sizeout outputs size annotations (explicit --sizein)"
printf ">s1;size=9\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --sizein \
        --sizeout \
        --output - 2> /dev/null | \
    grep -qw ">s1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--rereplicate --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --rereplicate - \
        --bzip2_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --bzip2_decompress accepts compressed stdin"
printf ">s;size=1\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --rereplicate - \
        --bzip2_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fasta_width

DESCRIPTION="--rereplicate --fasta_width is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --fasta_width 1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --fasta_width wraps fasta output"
printf ">s;size=1\nAA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --fasta_width 1 \
        --output - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--rereplicate --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --rereplicate - \
        --gzip_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --gzip_decompress accepts compressed stdin"
printf ">s;size=1\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --rereplicate - \
        --gzip_decompress \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--rereplicate --label_suffix is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --label_suffix "_suffix" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --label_suffix adds the suffix 'string' to sequence headers"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --label_suffix "_suffix" \
        --output - | \
    grep -wq ">s_suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --label_suffix adds the suffix 'string' (before annotations)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --label_suffix "_suffix" \
        --lengthout \
        --output - | \
    grep -wq ">s_suffix;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--rereplicate --lengthout is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --lengthout \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --lengthout adds length annotations to output"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --lengthout \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--rereplicate --log is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --log /dev/null \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --log writes to a file"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --output /dev/null \
        --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --log does not prevent messages to be sent to stderr"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# log: stderr output when there are missing abundance annotations
DESCRIPTION="--rereplicate --log does not prevent messages to be sent to stderr (missing abundance)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --output /dev/null \
        --log /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--rereplicate --no_progress is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --no_progress \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--rereplicate --no_progress removes progressive report on stderr (no visible effect)"
printf ">s;size=1 extra\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --no_progress \
        --output /dev/null 2>&1 | \
    grep -iq "^rereplicating" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--rereplicate --notrunclabels is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --notrunclabels \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --notrunclabels preserves full headers"
printf ">s;size=1 extra\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --notrunclabels \
        --output - | \
    grep -wq ">s;size=1 extra" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--rereplicate --quiet is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --quiet eliminates all (normal) messages to stderr"
printf ">s;size=1 extra\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--rereplicate --quiet allows error messages to be sent to stderr"
printf ">s;size=1 extra\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --quiet2 \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--rereplicate --relabel is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel renames sequence (label + ticker)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel renames sequence (empty label, only ticker)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "" \
        --output - | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel cannot combine with --relabel_md5"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --relabel_md5 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel cannot combine with --relabel_sha1"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --relabel_sha1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --sizeout adds abundance annotations
DESCRIPTION="--rereplicate --relabel no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## replace abundance annotations with size=1
DESCRIPTION="--rereplicate --relabel no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --output - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel --sizeout replaces size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --output - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--rereplicate --relabel_keep is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_keep renames and keeps original sequence name"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --output - | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--rereplicate --relabel_md5 is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_md5 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_md5 relabels using MD5 hash of sequence"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_md5 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_md5 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_md5 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_md5 \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_md5 --sizeout replaces size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --output - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--rereplicate --relabel_sha1 is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_sha1 \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_sha1 relabels using SHA1 hash of sequence"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_sha1 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_sha1 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_sha1 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_sha1 \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_sha1 --sizeout replaces size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --output - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--rereplicate --relabel_self is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_self \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_self relabels using sequence as label"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_self no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_self --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_self no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_self \
        --output - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --relabel_self --sizeout replaces size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --relabel_self \
        --sizeout \
        --output - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--rereplicate --sample is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --sample "ABC" \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --sample adds sample name to sequence headers"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --quiet \
        --sample "ABC" \
        --output - | \
    grep -qw ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--rereplicate --threads is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --threads 1 \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --threads > 1 triggers a warning (not multithreaded)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --threads 2 \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--rereplicate --xee is accepted"
printf ">s;size=1;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --xee \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --xee removes expected error annotations from input"
printf ">s;size=1;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --xee \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--rereplicate --xlength is accepted"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --xlength \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --xlength removes length annotations from input"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --xlength \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --xlength removes length annotations (input), lengthout adds them (output)"
printf ">s;length=2\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --xlength \
        --lengthout \
        --quiet \
        --output - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

DESCRIPTION="--rereplicate --xsize is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --xsize \
        --quiet \
        --output /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--rereplicate --xsize removes abundance annotations from input"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --xsize \
        --quiet \
        --output - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does not work as expected!
# DESCRIPTION="--rereplicate --xsize removes abundance annotations (input), sizeout adds them (output)"
# printf ">s;size=2\nA\n" | \
#     "${VSEARCH}" \
#         --rereplicate - \
#         --xsize \
#         --quiet \
#         --sizeout \
#         --output - | \
#     grep -wq ">s;size=1" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--rereplicate rejects --fastq_ascii"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --fastq_ascii 33 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--rereplicate rejects --fastq_qmax"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --fastq_qmax 41 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--rereplicate rejects --fastq_qmin"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --fastq_qmin 10 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- maxseqlength

DESCRIPTION="--rereplicate rejects --maxseqlength"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --maxseqlength 1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------------- maxsize
DESCRIPTION="--sortbylength rejects --maxsize"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=1\nAA\n") \
    --quiet \
    --maxsize 2 \
    --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- minseqlength

DESCRIPTION="--rereplicate rejects --minseqlength"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --minseqlength 1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------------- minsize
DESCRIPTION="--sortbylength rejects --minsize"
"${VSEARCH}" \
    --sortbylength <(printf ">s1;size=3\nAA\n") \
    --quiet \
    --minsize 2 \
    --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------------- strand

DESCRIPTION="--rereplicate rejects --strand"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --rereplicate - \
        --strand both \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

exit 0

# status: complete (v2.28.1, 2024-05-22)
