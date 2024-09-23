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



#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

# --chimeras_denovo
# and either, or both:
#    --chimeras
#    --nonchimeras

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


DESCRIPTION="chimeras_denovo: accepts both output options chimeras and nonchimeras"
printf ">s;size=1\n\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null \
        --nonchimeras /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

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
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

#  Parameters
#   --abskew REAL               minimum abundance ratio (1.0)
#   --chimeras_length_min       minimum length of each chimeric region (10)
#   --chimeras_parents_max      maximum number of parent sequences (3)
#   --chimeras_parts            number of parts to divide sequences (length/100)
#   --sizein                    propagate abundance annotation from input

## also:
# --chimeras_diff_pct           ??????

## --------------------------------------------------------------------- abskew

# --abskew real

# When using --uchime_denovo, the abundance skew is used to
# distinguish in a three-way alignment which sequence is the chimera
# and which are the parents. The assumption is that chimeras appear
# later in the PCR amplification process and are therefore less
# abundant than their parents. The default value is 2.0, which means
# that the parents should be at least 2 times more abundant than their
# chimera. Any positive value equal or greater than 1.0 can be used.

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


DESCRIPTION="chimeras_denovo: accepts parents if abundance ratio is greater than abskew"
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
        --abskew 8 \
        --chimeras - | \
    grep --quiet "^>sQ;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: accepts parents if abundance ratio is equal to abskew"
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
        --abskew 9 \
        --chimeras - | \
    grep --quiet "^>sQ;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: rejects parents if abundance ratio is smaller than abskew"
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
        --chimeras - | \
    grep --quiet "^>sQ;" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


## get an epsilon so small that an inferior abundance ratio will be
## declared equal to abskew (for example: a ratio of 1.99999 will be
## declared equal to 2)
# 200000000 / 100000001 -> 2E-8
DESCRIPTION="chimeras_denovo: can distinguish very close abundance ratio and abskew values (below FLT_EPSILON = 1.19209e-07)"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=200000000\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=200000000\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=100000001\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --abskew 2 \
        --chimeras - | \
    grep --quiet "^>sQ;" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


# 20000000000000000 / 10000000000000001 -> 2E-16
DESCRIPTION="chimeras_denovo: can distinguish very close abundance ratio and abskew values (below DBL_EPSILON = 2.22045e-16)"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=20000000000000000\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=20000000000000000\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=10000000000000001\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --abskew 2 \
        --chimeras - | \
    grep --quiet "^>sQ;" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


# 200000000000000000000 / 100000000000000000001 -> 2E-20
DESCRIPTION="chimeras_denovo: can distinguish very close abundance ratio and abskew values (below LDBL_EPSILON = 1.0842e-19)"
#        1...5...10...15.
A_START="AAAAAAAAAAAAAAA"
A_END="${A_START}"
B_START="CCCCCCCCCCCCCCC"
B_END="${B_START}"

(
    printf ">sA;size=200000000000000000000\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=200000000000000000000\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=100000000000000000001\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --abskew 2 \
        --chimeras - | \
    grep --quiet "^>sQ;" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


## ---------------------------------------------------------- chimeras_diff_pct

# undocumented!

DESCRIPTION="chimeras_denovo: chimeras_diff_pct is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 10 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


exit


# if ((opt_chimeras_diff_pct < 0.0) or (opt_chimeras_diff_pct > 50.0))
#   {
#     fatal("The argument to chimeras_diff_pct must be in the range 0.0 to 50.0");
#   }


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


# if (opt_chimeras_length_min < 1)
#   {
#     fatal("The argument to chimeras_length_min must be at least 1");
#   }


exit
    




## ------------------------------------------------------- chimeras_parents_max

# maximum number of parent sequences (3)


## ------------------------------------------------------------- chimeras_parts

# number of parts to divide sequences (length/100)


## --------------------------------------------------------------------- sizein

# propagate abundance annotation from input


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

# The valid options for the chimeras_denovo command are: --alignwidth
# --alnout --fasta_width --gapext --gapopen --hardmask --label_suffix
# --log --match --maxseqlength --minseqlength --mismatch --no_progress
# --notrunclabels --qmask --quiet --relabel --relabel_keep
# --relabel_md5 --relabel_self --relabel_sha1 --sample --sizeout
# --tabbedout --threads --xee --xn --xsize

#  Output
#   --alignwidth INT            width of alignments in alignment output file (60)
#   --alnout FILENAME           output chimera alignments to file
#   --relabel STRING            relabel nonchimeras with this prefix string
#   --relabel_keep              keep the old label after the new when relabelling
#   --relabel_md5               relabel with md5 digest of normalized sequence
#   --relabel_self              relabel with the sequence itself as label
#   --relabel_sha1              relabel with sha1 digest of normalized sequence
#   --sizeout                   include abundance information when relabelling
#   --tabbedout FILENAME        output chimera info to tab-separated file
#   --xsize                     strip abundance information in output


## ----------------------------------------------------------------- alignwidth

# width of alignments in alignment output file (60)


## --------------------------------------------------------------------- alnout

# output chimera alignments to file


## ---------------------------------------------------------------- fasta_width
## --------------------------------------------------------------------- gapext
## -------------------------------------------------------------------- gapopen
## ------------------------------------------------------------------- hardmask
## --------------------------------------------------------------- label_suffix
## ------------------------------------------------------------------------ log
## ---------------------------------------------------------------------- match
## --------------------------------------------------------------- maxseqlength
## --------------------------------------------------------------- minseqlength
## ------------------------------------------------------------------- mismatch
## ---------------------------------------------------------------- no_progress
## -------------------------------------------------------------- notrunclabels
## ---------------------------------------------------------------------- qmask
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


# use fale option --quiet2 to trigger an error
DESCRIPTION="chimeras_denovo: option quiet does not eliminate error messages"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null \
        --quiet \
        --quiet2 2>&1 |
    grep --quiet "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## -------------------------------------------------------------------- relabel
## --------------------------------------------------------------- relabel_keep
## ---------------------------------------------------------------- relabel_md5
## --------------------------------------------------------------- relabel_self
## --------------------------------------------------------------- relabel_sha1
## --------------------------------------------------------------------- sample
## -------------------------------------------------------------------- sizeout
## ------------------------------------------------------------------ tabbedout

# --tabbedout "Fatal error: No output files specified", tabbedout
# should be enough?
DESCRIPTION="chimeras_denovo: output only to tabbedout"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --tabbedout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



## -------------------------------------------------------------------- threads
## ------------------------------------------------------------------------ xee
## ------------------------------------------------------------------------- xn
## ---------------------------------------------------------------------- xsize







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




## ---------------------------------------------------------------- fasta_width


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

# none


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

# TODO: write a test that activates all output files, with a chimeric
# and a non-chimeric case.

## valgrind: search for errors and memory leaks
# if which valgrind > /dev/null 2>&1 ; then
#     TMP=$(mktemp)
#     valgrind \
#         --log-file="${TMP}" \
#         --leak-check=full \
#         "${VSEARCH}" \
#         --cut <(printf ">s1\nGAATTC\n>s2\nA\n") \
#         --cut_pattern G^AATT_C \
#         --fastaout_discarded /dev/null \
#         --fastaout_rev /dev/null \
#         --fastaout_discarded /dev/null \
#         --fastaout_discarded_rev /dev/null \
#         --log /dev/null 2> /dev/null
#     DESCRIPTION="--cut valgrind (no leak memory)"
#     grep -q "in use at exit: 0 bytes" "${TMP}" && \
#         success "${DESCRIPTION}" || \
#             failure "${DESCRIPTION}"
#     DESCRIPTION="--cut valgrind (no errors)"
#     grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
#         success "${DESCRIPTION}" || \
#             failure "${DESCRIPTION}"
#     rm -f "${TMP}"
#     unset TMP
# fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0

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


## potential mistakes?

# - fix: --chimeras_diff_pct is undocumented
# - --chimeras_diff_pct is largely untested (no expected behavior)
# - no capacity to read bzip2 or gzip?
# - accept replicated sequences (same names)?
