#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="chimeras_denovo"
LINE=$(printf -- "-%.0s" {1..76})
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    # exit 1
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
#                              chimeras_denovo                                #
#                                                                             #
#*****************************************************************************#

# Chimera detection with new algorithm
#   --chimeras_denovo FILENAME  detect chimeras de novo in long exact sequences
#  Parameters
#   --abskew REAL               minimum abundance ratio (1.0)
#   --chimeras_length_min       minimum length of each chimeric region (10)
#   --chimeras_parents_max      maximum number of parent sequences (3)
#   --chimeras_parts            number of parts to divide sequences (length/100)
#   --sizein                    propagate abundance annotation from input
#  Output
#   --alignwidth INT            width of alignments in alignment output file (60)
#   --alnout FILENAME           output chimera alignments to file
#   --chimeras FILENAME         output chimeric sequences to file
#   --nonchimeras FILENAME      output non-chimeric sequences to file
#   --relabel STRING            relabel nonchimeras with this prefix string
#   --relabel_keep              keep the old label after the new when relabelling
#   --relabel_md5               relabel with md5 digest of normalized sequence
#   --relabel_self              relabel with the sequence itself as label
#   --relabel_sha1              relabel with sha1 digest of normalized sequence
#   --sizeout                   include abundance information when relabelling
#   --tabbedout FILENAME        output chimera info to tab-separated file
#   --xsize                     strip abundance information in output

DESCRIPTION="chimeras_denovo: command is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo /dev/stdin \
        --chimeras /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: output file is required"
# "Fatal error: No output files specified"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo /dev/stdin 2>&1 1> /dev/null | \
    grep --quiet --ignore-case "error" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: accepts empty file"
printf "" | \
    ${VSEARCH} \
        --chimeras_denovo /dev/stdin \
        --chimeras /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# reading from stdin or dash should yield the same results
DESCRIPTION="chimeras_denovo: dash represents stdin"
TMP_STDIN=$(
    printf ">s;size=1\nA\n" | \
        ${VSEARCH} \
            --chimeras_denovo /dev/stdin \
            --chimeras /dev/null 2>&1 | \
        sed 's/\/dev\/stdin/-/' | \
        md5sum)

TMP_DASH=$(
    printf ">s;size=1\nA\n" | \
        ${VSEARCH} \
            --chimeras_denovo - \
            --chimeras /dev/null 2>&1 | \
        md5sum)

[[ "${TMP_STDIN}" == "${TMP_DASH}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset TMP_STDIN TMP_DASH


DESCRIPTION="chimeras_denovo: default is to message on stderr"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null 2>&1 |
    grep --quiet "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: accepts replicated sequences (different names)"
printf ">s1;size=1\nA\n>s2;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: accepts replicated sequences (same names)"
printf ">s1;size=1\nA\n>s2;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ---------------------------------------------------------------- nonchimeras

DESCRIPTION="chimeras_denovo: output option nonchimeras is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --nonchimeras /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: output option nonchimeras writes an output"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --nonchimeras /dev/stdout 2> /dev/null |
    grep --quiet "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: output option nonchimeras writes fasta sequences"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --nonchimeras /dev/stdout 2> /dev/null |
    tr "\n" "@" | \
        grep --quiet --word-regexp ">s;size=1@A@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: output option nonchimeras discards empty fasta sequences"
printf ">s;size=1\n\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --nonchimeras /dev/stdout 2> /dev/null |
        grep --quiet "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# setting output to stdout or dash should yield the same results
DESCRIPTION="chimeras_denovo: dash represents stdout"
TMP_STDOUT=$(
    printf ">s;size=1\nA\n" | \
        ${VSEARCH} \
            --chimeras_denovo - \
            --nonchimeras /dev/stdout 2> /dev/null | \
        md5sum)

TMP_DASH=$(
    printf ">s;size=1\nA\n" | \
        ${VSEARCH} \
            --chimeras_denovo - \
            --nonchimeras - 2> /dev/null | \
        md5sum)

[[ "${TMP_STDOUT}" == "${TMP_DASH}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset TMP_STDOUT TMP_DASH


## ---------------------------------------------------------------------- quiet

DESCRIPTION="chimeras_denovo: option quiet is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option quiet eliminates stderr messages"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null \
        --quiet 2>&1 |
    grep --quiet "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ------------------------------------------------------------------- chimeras

DESCRIPTION="chimeras_denovo: option chimeras is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras does no write if there are no chimeras"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras - 2> /dev/null | \
    grep --quiet "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## simplest positive example (using default parameters)
DESCRIPTION="chimeras_denovo: simplest positive example"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: option chimeras write the expected fasta output"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras - 2> /dev/null | \
    tr "\n" "@" | \
    grep \
        --word-regexp \
        --quiet ">sQ;size=1@${A_START}${B_END}@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: simplest negative example"

#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${A_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras - 2> /dev/null | \
    grep --quiet "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


## ---------------------------------------------------------------------- qmask

DESCRIPTION="chimeras_denovo: homopolymers are masked"
#        1...5...10
A_START="AAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras - 2> /dev/null | \
    grep --quiet "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: qmask 'none' allows homopolymers"
#        1...5...10
A_START="AAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --chimeras - 2> /dev/null | \
    grep --quiet "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: option qmask write the expected fasta output"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras - 2> /dev/null | \
    tr "\n" "@" | \
    grep \
        --word-regexp \
        --quiet ">sQ;size=1@${A_START}${B_END}@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END



## -------------------------------------------------------- chimeras_length_min

DESCRIPTION="chimeras_denovo: chimeras_length_min is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 10 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# test with chimeric regions of length 9
DESCRIPTION="chimeras_denovo: chimeras_length_min default is 10"
#        1...5...9
A_START="TAGGCCGTG"
A_END="${A_START}"
B_START="TGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


# test with chimeric regions of length 10 and threshold set to 11
DESCRIPTION="chimeras_denovo: chimeras_length_min rejects chimeric regions shorter than length"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 11 \
        --chimeras - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: chimeras_length_min accepts values starting from 1"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 1 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: chimeras_length_min rejects a null value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 0 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: chimeras_length_min rejects a negative value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min -1 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: chimeras_length_min rejects a decimal value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 1.1 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: chimeras_length_min rejects non-numerical values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min A \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: chimeras_length_min accepts large values (2^8 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 255 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: chimeras_length_min accepts large values (2^16 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 65535 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: chimeras_length_min accepts large values (2^31 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 2147483647 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: chimeras_length_min rejects large values (2^32 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 4294967295 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: chimeras_length_min rejects large values (2^64 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 1267650600228229401496703205375 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## --------------------------------------------------------------------- alnout

# bug with --alnout "Fatal error: No output files specified"
# alnout should be enough
DESCRIPTION="chimeras_denovo: option alnout is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --alnout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alnout is accepted (with other output)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alnout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alnout is empty when there is no chimera"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alnout - | \
    grep --quiet "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alnout is not empty when there is a chimera"
#        1...5...10
A_START="AAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alnout - | \
    grep --quiet "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: option alnout produces an alignment model"
#        1...5...10
A_START="AAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alnout - | \
    grep --quiet " AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


## ----------------------------------------------------------------- alignwidth

DESCRIPTION="chimeras_denovo: option alignwidth is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth 60 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alignwidth rejects a negative value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth -1 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alignwidth rejects a non-numeric value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth A 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alignwidth accepts a null value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth 0 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alignwidth a null value means no folding"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAAA"
A_END="${A_START:0:15}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alignwidth 0 \
        --alnout - | \
    awk '{if ($1 ~ /^Model/) matches += 1}
         END {exit matches == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: option alignwidth accepts a value of 1"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth 1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alignwidth folds each position"
#        1...5...10...15
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alignwidth 1 \
        --alnout - | \
    awk '{if ($1 ~ /^Model/) matches += 1}
         END {exit matches == 60 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: option alignwidth accepts large values (2^8 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth 255 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alignwidth accepts large values (2^16 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth 65535 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alignwidth accepts large values (2^31 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth 2147483647 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alignwidth accepts large values (2^32 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth 4294967295 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option alignwidth accepts large values (2^64 - 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --alignwidth 1267650600228229401496703205375 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# assume that the 'Model' line is repeated each time the alignment is
# folded
DESCRIPTION="chimeras_denovo: alignment width is 60 by default (60 nt)"
#        1...5...10...15
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alnout - | \
    awk '{if ($1 ~ /^Model/) matches += 1}
         END {exit matches == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: alignment width is 60 by default (61 nt)"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAAA"
A_END="${A_START:0:15}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alnout - | \
    awk '{if ($1 ~ /^Model/) matches += 1}
         END {exit matches == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: alignwidth folds alignments longer than n"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAAA"
A_END="${A_START:0:15}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alignwidth 61 \
        --alnout - | \
    awk '{if ($1 ~ /^Model/) matches += 1}
         END {exit matches == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


## --------------------------------------------------------------------- abskew

# --abskew real
#          When  using --uchime_denovo, the abundance skew is used
#          to distinguish in a three-way alignment which  sequence
#          is  the  chimera and which are the parents. The assump‐
#          tion is that chimeras appear later in the PCR  amplifi‐
#          cation  process  and  are  therefore less abundant than
#          their parents. For --uchime3_denovo the  default  value
#          is  16.0.  For the other commands, the default value is
#          2.0, which means that the parents should be at least  2
#          times  more  abundant  than their chimera. Any positive
#          value equal or greater than 1.0 can be used.

DESCRIPTION="chimeras_denovo: option abskew is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --abskew 1.0 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option abskew rejects values smaller than 1.0"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --abskew 0.99 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option abskew rejects a null value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --abskew 0.0 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option abskew rejects a negative value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --abskew -1.0 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option abskew rejects a non-numeric value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --abskew A 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option abskew accepts large values (2.0)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --abskew 2.0 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option abskew accepts large values (16.0)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --abskew 16.0 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option abskew accepts large values (140961597.0)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --abskew 140961597.0 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## appr. upper limit of a 32-bit float
DESCRIPTION="chimeras_denovo: option abskew accepts large values (3.4028235 * 10^38)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --abskew 3402823500000000000000000000000000.0 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: default minimal abundance ratio is 1.0"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=2\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=2\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=2\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alnout - | \
    grep --quiet "^Model" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


# A's abundance is too low to be a parent for Q, no chimera
DESCRIPTION="chimeras_denovo: abundance ratio below 1.0, no chimera (A)"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=1\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=2\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=2\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alnout - | \
    grep --quiet "^Model" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


# B's abundance is too low to be a parent for Q, no chimera
DESCRIPTION="chimeras_denovo: abundance ratio below 1.0, no chimera (B)"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=2\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=1\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=2\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --chimeras /dev/null \
        --alnout - | \
    grep --quiet "^Model" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


# division by zero
DESCRIPTION="chimeras_denovo: null Q abundance, abundance ratio is undefined"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=2\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=2\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=0\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


# abundance ratio is 9.0, so reject
DESCRIPTION="chimeras_denovo: abskew rejects parents if abundance ratio is smaller than n"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --abskew 9.1 \
        --chimeras /dev/null \
        --alnout - | \
    grep --quiet "^Model" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END

## next:
# - make a test with abundance ratio very close to epsilon, so it will fail 

# FLT_EPSILON      = 1.19209e-07
# DBL_EPSILON      = 2.22045e-16
# LDBL_EPSILON     = 1.0842e-19

# 900000000000000009/900000000000000000 = 1.000000000000001

# abskew 9

exit 0

# Valid options for the uchime_denovo command are:
# --abskew,
# --alignwidth,  *DONE*
# --alnout,      *DONE*
# --chimeras,    *DONE*
# --chimeras_length_min,
# --chimeras_parents_max,
# --chimeras_parts,
# --fasta_width,
# --gapext,
# --gapopen,
# --hardmask,
# --label_suffix,
# --log,
# --match,
# --mismatch,
# --no_progress,
# --nonchimeras,
# --notrunclabels,
# --qmask,
# --quiet,
# --relabel,
# --relabel_keep,
# --relabel_md5,
# --relabel_self,
# --relabel_sha1,
# --sample,
# --sizein,
# --sizeout,
# --tabbedout,
# --threads,
# --xee,
# --xn,
# --xsize


## Notes

# - test chimeras with more than two parents,
# - test chimeras with more than two parents for a given chunk,
# - test tab output,
# - test remaining command-specific parameters
# - test if relabel applies to both chimeras and non-chimeras
