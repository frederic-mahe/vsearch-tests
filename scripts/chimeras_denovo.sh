#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="chimeras_denovo"
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
# and either, or some or all:
#    --chimeras
#    --nonchimeras
#    --alnout
#    --tabbedout

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
        grep --quiet --line-regexp ">s;size=1@A@" && \
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


## --------------------------------------------------------------------- alnout

# output chimera alignments to file

DESCRIPTION="chimeras_denovo: alnout is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --alnout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout is accepted (with other output)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null \
        --alnout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout can output to stdout (/dev/stout)"
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
        --quiet \
        --alnout /dev/stdout |
    grep -q "." && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: alnout can output to stdout (-)"
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
        --quiet \
        --alnout /dev/stdout |
    grep -q "." && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: alnout is empty when there is no chimera"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout is not empty when there is a chimera"
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
        --alnout - | \
    grep --quiet "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: alnout produces an alignment model"
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
        --alnout - | \
    grep --quiet " AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: alnout separates results with an empty line and a ruler (empty line)"
(
    #                          1...5...10...15...20
    printf ">sA;size=9\n%s\n" "AAAAAAAAAAAAAAAAAAAA"
    printf ">sB;size=9\n%s\n" "CCCCCCCCCCCCCCCCCCCC"
    printf ">sQ;size=1\n%s\n" "AAAAAAAAAACCCCCCCCCC"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --alnout - | \
    head -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout separates results with an empty line and a ruler (ruler)"
(
    #                          1...5...10...15...20
    printf ">sA;size=9\n%s\n" "AAAAAAAAAAAAAAAAAAAA"
    printf ">sB;size=9\n%s\n" "CCCCCCCCCCCCCCCCCCCC"
    printf ">sQ;size=1\n%s\n" "AAAAAAAAAACCCCCCCCCC"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --alnout - | \
    head -n 2 | \
    grep -Eqx "[-]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports Query first"
(
    #                          1...5...10...15...20
    printf ">sA;size=9\n%s\n" "AAAAAAAAAAAAAAAAAAAA"
    printf ">sB;size=9\n%s\n" "CCCCCCCCCCCCCCCCCCCC"
    printf ">sQ;size=1\n%s\n" "AAAAAAAAAACCCCCCCCCC"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --alnout - | \
    head -n 3 | \
    grep -qx "Query.*sQ;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports Query length"
(
    #                          1...5...10...15...20
    printf ">sA;size=9\n%s\n" "AAAAAAAAAAAAAAAAAAAA"
    printf ">sB;size=9\n%s\n" "CCCCCCCCCCCCCCCCCCCC"
    printf ">sQ;size=1\n%s\n" "AAAAAAAAAACCCCCCCCCC"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --alnout - | \
    grep "^Query" | \
    grep -q "20 nt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports Query header"
(
    #                          1...5...10...15...20
    printf ">sA;size=9\n%s\n" "AAAAAAAAAAAAAAAAAAAA"
    printf ">sB;size=9\n%s\n" "CCCCCCCCCCCCCCCCCCCC"
    printf ">sQ;size=1\n%s\n" "AAAAAAAAAACCCCCCCCCC"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --alnout - | \
    grep "^Query" | \
    grep -q "sQ;size=1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports Parent C (three parents)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -q "^ParentC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports Parent C length"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep "^ParentC" | \
    grep -q "58 nt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports Parent C header"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep "^ParentC" | \
    grep -q "pC;size=9$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports multi-way alignment starting with parent name (query Q)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -Eq "^Q +1 [ACGTacgt-]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports uppercased sequences (query Q)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -Eq " [ACGT]+ " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports multi-way alignment starting with parent name (parent C)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -Eq "^C +1 [ACGTacgt-]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports lowercase letters when parent mismatches with query (parent C)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -Eq "^C +1 AaA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports dashes to represent alignment indels"
(
    #                          1...5...10...15...20
    printf ">sA;size=9\n%s\n" "AAAAAAAAAAAAAAAAAAAA"
    printf ">sB;size=9\n%s\n" "CCCCCCCCCCCCCCCCCCCC"
    printf ">sQ;size=1\n%s\n" "AAAAAAAAAACCCCCCCCCC"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --alnout - | \
    grep -Eq "^Q +1 -+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports positions that favor a particular parent (Diffs)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -q "^Diffs" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# hypothesis: parents are named A-U in spatial order (different parts of Query)
DESCRIPTION="chimeras_denovo: alnout reports positions that favor a particular parent (parent names)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -Eq "^Diffs +A +A +B +B +C +C" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports a model of the chimera (Model)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -q "^Model" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports a model of the chimera (parent names)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -Eq "^Model +A+B+C+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports global similarity percentages (Ids)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -q "^Ids." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports global similarity with parent A"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep "^Ids." | \
    grep -q "QA 93.10%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports global similarity with parent B"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep "^Ids." | \
    grep -q "QB 93.10%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports global similarity with parent C (three parents)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep "^Ids." | \
    grep -q "QC 93.10%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports global similarity with parent C (only two parents)"
(
    #                          1...5...10...15...20
    printf ">sA;size=9\n%s\n" "AAAAAAAAAAAAAAAAAAAA"
    printf ">sB;size=9\n%s\n" "CCCCCCCCCCCCCCCCCCCC"
    printf ">sQ;size=1\n%s\n" "AAAAAAAAAACCCCCCCCCC"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --alnout - | \
    grep "^Ids." | \
    grep -q "QC 0.00%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports global similarity of the parent closest to the query (QT)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep "^Ids." | \
    grep -q "QA 93.10%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: alnout reports global similarity with the model (always 100.00)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep "^Ids." | \
    grep -q "QModel 100.00%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# Div: divfrac = 100.00 * (QM - QT) / QT;
DESCRIPTION="chimeras_denovo: alnout reports the divergence of the model with the closest parent (Div)"
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep "^Ids." | \
    grep -q "Div. +7.41%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------------ tabbedout

DESCRIPTION="chimeras_denovo: option tabbedout is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --tabbedout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option tabbedout is accepted (with other output)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras /dev/null \
        --tabbedout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout can output to stdout (/dev/stout)"
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
        --quiet \
        --tabbedout /dev/stdout |
    grep -q "." && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: tabbedout can output to stdout (-)"
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
        --quiet \
        --tabbedout /dev/stdout |
    grep -q "." && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: tabbedout is empty when there are no chimeras"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout outputs 18 tab-separated columns"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"
# 99.9999	sQ;size=1	sA;size=9	sB;size=9	*	100.00	80.00	80.00	0.00	80.00	0	0	0	0	0	0	0.00	Y
(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - |
    awk 'BEGIN {FS = "\t"} END {exit (NF == 18) ? 0 : 1}' && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: tabbedout column 1 is the score value (always 99.9999)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($1 == "99.9999") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 2 is the query header"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($2 == "Q;size=1") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 3 is the parent A header"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($3 == "pA;size=9") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 4 is the parent B header"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($4 == "pB;size=9") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 5 is the parent C header"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($5 == "pC;size=9") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 5 is the parent C header (* if no parent C)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	*	100.00	94.59	94.59	0.00	94.59	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($5 == "*") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 6 is the max similarity percentage of the QModel (always 100.00)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($6 == "100.00") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 7 is the global similarity percentage with parent A (QA)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($7 == "93.10") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 8 is the global similarity percentage with parent B (QB)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($8 == "93.10") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 9 is the global similarity percentage with parent C (QC)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($9 == "93.10") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 9 is the global similarity percentage with parent C (QC) (0.00 if no parent C)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	*	100.00	94.59	94.59	0.00	94.59	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($9 == "0.00") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 10 is the highest global similarity percentage with a parent"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($10 == "93.10") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 10 is the highest global similarity percentage with a parent (more dissimilar parents)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	91.38	89.66	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAACAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($10 == "93.10") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 11 is the left yes count (always 0)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($11 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 12 is the left no count (always 0)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($12 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 13 is the left abstain count (always 0)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($13 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 14 is the right yes count (always 0)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($14 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 15 is the right no count (always 0)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($15 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 16 is the right abstain count (always 0)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($16 == "0") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 17 is a dummy value (always 0.00)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($17 == "0.00") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout column 18 is the chimeric status (always Y)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	93.10	93.10	93.10	93.10	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --tabbedout - | \
    awk '{exit ($18 == "Y") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: tabbedout only outputs the first three parents (4 parents)"
# 99.9999	Q;size=1	pA;size=9	pB;size=9	pC;size=9	100.00	91.89	91.89	91.89	91.89	0	0	0	0	0	0	0.00	Y
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pD;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAACAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAACAAAAAAAAAACAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras_parents_max 4 \
        --tabbedout - | \
    awk '{exit (! /^$/) && (! /pD/) ? 0 : 1}' && \
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
        --line-regexp \
        --quiet ">sQ;size=1@${A_START}${B_END}@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


## Q is not a chimera, Q is the same as A
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


DESCRIPTION="chimeras_denovo: converts lowercase sequences into uppercase"
printf ">s\na\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras - | \
    grep -qx "A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: accepts fastq input"
printf "@s\nA\n+\nI\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: converts fastq input to fasta output"
printf "@s\nA\n+\nI\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: simplest positive example (fastq)"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"
QUAL="IIIIIIIIIIIIIIIIIIII"
(
    printf "@sA\n%s\n+\n%s\n" "${A_START}${A_END}" "${QUAL}"
    printf "@sB\n%s\n+\n%s\n" "${B_START}${B_END}" "${QUAL}"
    printf "@sQ\n%s\n+\n%s\n" "${A_START}${B_END}" "${QUAL}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END QUAL


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


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

#  Parameters
#   --abskew REAL               minimum abundance ratio (1.0)
#   --chimeras_diff_pct         mismatch % allowed in each chimeric region (0.0)
#   --chimeras_length_min       minimum length of each chimeric region (10)
#   --chimeras_parents_max      maximum number of parent sequences (3)
#   --chimeras_parts            number of parts to divide sequences (length/100)
#   --sizein                    propagate abundance annotation from input


## --------------------------------------------------------------------- abskew

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


## 200000000000000000000 / 100000000000000000001 -> 2E-20
# DESCRIPTION="chimeras_denovo: can distinguish very close abundance ratio and abskew values (below LDBL_EPSILON = 1.0842e-19)"
# #        1...5...10...15.
# A_START="AAAAAAAAAAAAAAA"
# A_END="${A_START}"
# B_START="CCCCCCCCCCCCCCC"
# B_END="${B_START}"

# (
#     printf ">sA;size=200000000000000000000\n%s\n" "${A_START}${A_END}"
#     printf ">sB;size=200000000000000000000\n%s\n" "${B_START}${B_END}"
#     printf ">sQ;size=100000000000000000001\n%s\n" "${A_START}${B_END}"
# ) | \
#     ${VSEARCH} \
#         --chimeras_denovo - \
#         --qmask none \
#         --quiet \
#         --abskew 2 \
#         --chimeras - | \
#     grep --quiet "^>sQ;" && \
#     failure "${DESCRIPTION}" || \
#         success "${DESCRIPTION}"

# unset A_START A_END B_START B_END

# Fatal error: Invalid (range error) abundance annotation in FASTA
#
# File header abundance annotations are parsed with std::strtoll(),
# which can return at most LLONG_MAX:
#
# LONG_MAX  9223372036854775807
# LLONG_MAX 9223372036854775807
#         200000000000000000000  <- our input value is more than 20 times too large
# large abundance values already tested in fastq_mergepairs.sh


## ---------------------------------------------------------- chimeras_diff_pct

DESCRIPTION="chimeras_denovo: option chimeras_diff_pct is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 10 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct accepts floats"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 10.0 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct accepts values in range (0.0)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 0.0 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct accepts values in range (1.0)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 1.0 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct accepts values in range (50.0)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 50.0 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ints are silently interpreted as floats
DESCRIPTION="chimeras_denovo: option chimeras_diff_pct accepts integers (0)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 0 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct accepts integers (50)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 50 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct rejects negative values (-1.0)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct -1.0 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct rejects values greater than 50.0 (epsilon)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 50.00001 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct rejects values greater than 50.0 (51)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct 51 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct rejects non-numeric values ('A')"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct A \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_diff_pct rejects empty values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_diff_pct   \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## -------------------------------------------------------- chimeras_length_min

DESCRIPTION="chimeras_denovo: chimeras_length_min is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_length_min 10 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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


# test with chimeric regions of length 9
DESCRIPTION="chimeras_denovo: chimeras_length_min default is 10"
#        1...5...9
A_START="TAGGCCGTG"
A_END="${A_START}"
B_START="TGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=2\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=2\n%s\n" "${B_START}${B_END}"
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
    printf ">sA;size=2\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=2\n%s\n" "${B_START}${B_END}"
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


## ------------------------------------------------------- chimeras_parents_max

# maximum number of parent sequences (3 by default)

DESCRIPTION="chimeras_denovo: option chimeras_parents_max is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max 3 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max accepts integers"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max 3 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max accepts values ranging from 2 to 20 (2)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max 2 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max accepts values ranging from 2 to 20 (20)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max 20 \
        --chimeras - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max rejects floats"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max 3.1 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max rejects non-numeric values ('A')"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max A \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max rejects values < 2"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max 1 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max rejects values > 20"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max 21 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max rejects null values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max 0 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max rejects negative values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max -2 \
        --chimeras - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# with natural sequences
DESCRIPTION="chimeras_denovo: option chimeras_parents_max accepts three parents (default)"
# Query   (   58 nt) Q;size=1
# ParentA (   58 nt) pA;size=9
# ParentB (   58 nt) pB;size=9
# ParentC (   58 nt) pC;size=9
#
# Q     1 GAAAGCTTTTGATTTTAAAAGTTTTACACCAGTCTTTTACAGATCGGTGCTTGAAATG 58
# A     1 GAAAGCTTTTGATTTTgAAAGcTTTACACCtaTCTTTTtCAGATCGGTGCTTGAAATG 58
# B     1 cAAAGCTTTTGAaTTTAAAAGTTTTACACCAGTCTTTTcCAGATCGGTGCTTGAAATG 58
# C     1 cAAAGCTTTTGAcTTTAAAAGgTTTACACCgGTCTTTTACAGATCGGTGCTTGAAATG 58
# Diffs   A           A        B        B       C
# Model   AAAAAAAAAAAAABBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCC
#
# Ids.  QA 91.38%, QB 94.83%, QC 93.10%, QT 94.83%, QModel 100.00%, Div. +5.45%
(
    printf ">pA;size=9"
    printf "\n"
    printf "GAAAGCTTTTGATTTTGAAAGCTTTACACCTATCTTTTTCAGATCGGTGCTTGAAATG"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "CAAAGCTTTTGAATTTAAAAGTTTTACACCAGTCTTTTCCAGATCGGTGCTTGAAATG"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "CAAAGCTTTTGACTTTAAAAGGTTTACACCGGTCTTTTACAGATCGGTGCTTGAAATG"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "GAAAGCTTTTGATTTTAAAAGTTTTACACCAGTCTTTTACAGATCGGTGCTTGAAATG"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --alnout - | \
    grep -iq "^ParentC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max accepts three parents (option on)"
# Query   (   58 nt) Q;size=1
# ParentA (   58 nt) pA;size=9
# ParentB (   58 nt) pB;size=9
# ParentC (   58 nt) pC;size=9
#
# Q     1 GAAAGCTTTTGATTTTAAAAGTTTTACACCAGTCTTTTACAGATCGGTGCTTGAAATG 58
# A     1 GAAAGCTTTTGATTTTgAAAGcTTTACACCtaTCTTTTtCAGATCGGTGCTTGAAATG 58
# B     1 cAAAGCTTTTGAaTTTAAAAGTTTTACACCAGTCTTTTcCAGATCGGTGCTTGAAATG 58
# C     1 cAAAGCTTTTGAcTTTAAAAGgTTTACACCgGTCTTTTACAGATCGGTGCTTGAAATG 58
# Diffs   A           A        B        B       C
# Model   AAAAAAAAAAAAABBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCC
#
# Ids.  QA 91.38%, QB 94.83%, QC 93.10%, QT 94.83%, QModel 100.00%, Div. +5.45%
(
    printf ">pA;size=9"
    printf "\n"
    printf "GAAAGCTTTTGATTTTGAAAGCTTTACACCTATCTTTTTCAGATCGGTGCTTGAAATG"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "CAAAGCTTTTGAATTTAAAAGTTTTACACCAGTCTTTTCCAGATCGGTGCTTGAAATG"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "CAAAGCTTTTGACTTTAAAAGGTTTACACCGGTCTTTTACAGATCGGTGCTTGAAATG"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "GAAAGCTTTTGATTTTAAAAGTTTTACACCAGTCTTTTACAGATCGGTGCTTGAAATG"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras_parents_max 3 \
        --alnout - | \
    grep -iq "^ParentC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max 2 accepts chimeras with 2 parents"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=2\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=2\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parents_max 2 \
        --chimeras - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


# with artificial sequences
DESCRIPTION="chimeras_denovo: option chimeras_parents_max 2 rejects chimeras with 3 parents"
# Query   (   58 nt) Q;size=1
# ParentA (   58 nt) pA;size=9
# ParentB (   58 nt) pB;size=9
# ParentC (   58 nt) pC;size=9
#
# Q     1 ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA 58
# A     1 ACAAAAAAAAAAACAAAAaAAAAAAAAAAAaAAAAAAAAAAAaAAAAAAAAAAaAAAA 58
# B     1 AaAAAAAAAAAAAaAAAAGAAAAAAAAAAAGAAAAAAAAAAAaAAAAAAAAAAaAAAA 58
# C     1 AaAAAAAAAAAAAaAAAAaAAAAAAAAAAAaAAAAAAAAAAATAAAAAAAAAATAAAA 58
# Diffs    A           A    B           B           C          C
# Model   AAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCC
#
# Ids.  QA 93.10%, QB 93.10%, QC 93.10%, QT 93.10%, QModel 100.00%, Div. +7.41%
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras_parents_max 2 \
        --alnout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max 4 allows four parents"
# Query   (   74 nt) Q;size=1
# ParentA (   74 nt) pA;size=9
# ParentB (   74 nt) pB;size=9
# ParentC (   74 nt) pC;size=9
# ParentD (   74 nt) pD;size=9
#
# Q     1 ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAACA 60
# A     1 ACAAAAAAAAAAACAAAAaAAAAAAAAAAAaAAAAAAAAAAAaAAAAAAAAAAaAAAAaA 60
# B     1 AaAAAAAAAAAAAaAAAAGAAAAAAAAAAAGAAAAAAAAAAAaAAAAAAAAAAaAAAAaA 60
# C     1 AaAAAAAAAAAAAaAAAAaAAAAAAAAAAAaAAAAAAAAAAATAAAAAAAAAATAAAAaA 60
# D     1 AaAAAAAAAAAAAaAAAAaAAAAAAAAAAAaAAAAAAAAAAAaAAAAAAAAAAaAAAACA 60
# Diffs    A           A    B           B           C          C    D
# Model   AAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCDDDDDD
#
# Q    61 AAAAAAAAACAAAA 74
# A    61 AAAAAAAAAaAAAA 74
# B    61 AAAAAAAAAaAAAA 74
# C    61 AAAAAAAAAaAAAA 74
# D    61 AAAAAAAAACAAAA 74
# Diffs            D
# Model   DDDDDDDDDDDDDD
#
# Ids.  QA 91.89%, QB 91.89%, QC 91.89%, QT 91.89%, QModel 100.00%, Div. +8.82%
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pD;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAACAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAACAAAAAAAAAACAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras_parents_max 4 \
        --alnout - | \
    grep -iq "^ParentD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parents_max 3 rejects chimera with 4 parents"
# Query   (   74 nt) Q;size=1
# ParentA (   74 nt) pA;size=9
# ParentB (   74 nt) pB;size=9
# ParentC (   74 nt) pC;size=9
# ParentD (   74 nt) pD;size=9
#
# Q     1 ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAACA 60
# A     1 ACAAAAAAAAAAACAAAAaAAAAAAAAAAAaAAAAAAAAAAAaAAAAAAAAAAaAAAAaA 60
# B     1 AaAAAAAAAAAAAaAAAAGAAAAAAAAAAAGAAAAAAAAAAAaAAAAAAAAAAaAAAAaA 60
# C     1 AaAAAAAAAAAAAaAAAAaAAAAAAAAAAAaAAAAAAAAAAATAAAAAAAAAATAAAAaA 60
# D     1 AaAAAAAAAAAAAaAAAAaAAAAAAAAAAAaAAAAAAAAAAAaAAAAAAAAAAaAAAACA 60
# Diffs    A           A    B           B           C          C    D
# Model   AAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCDDDDDD
#
# Q    61 AAAAAAAAACAAAA 74
# A    61 AAAAAAAAAaAAAA 74
# B    61 AAAAAAAAAaAAAA 74
# C    61 AAAAAAAAAaAAAA 74
# D    61 AAAAAAAAACAAAA 74
# Diffs            D
# Model   DDDDDDDDDDDDDD
#
# Ids.  QA 91.89%, QB 91.89%, QC 91.89%, QT 91.89%, QModel 100.00%, Div. +8.82%
(
    printf ">pA;size=9"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAGAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATAAAAAAAAAATAAAAAAAAAAAAAAAAAAAA"
    printf "\n"
    printf ">pD;size=9"
    printf "\n"
    printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAACAAAA"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "ACAAAAAAAAAAACAAAAGAAAAAAAAAAAGAAAAAAAAAAATAAAAAAAAAATAAAACAAAAAAAAAACAAAA"
    printf "\n"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --chimeras_parents_max 3 \
        --alnout - | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ------------------------------------------------------------- chimeras_parts

# number of parts to divide sequences (default: length/100)

DESCRIPTION="chimeras_denovo: option chimeras_parts is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts 2 \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parts accepts integers"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts 3 \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# expected range is 2 to 100 (lower bound)
DESCRIPTION="chimeras_denovo: option chimeras_parts accepts lower bound value (2)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts 2 \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# expected range is 2 to 100 (upper bound)
DESCRIPTION="chimeras_denovo: option chimeras_parts accepts upper bound value (100)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts 100 \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parts rejects values below 2 (1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts 1 \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parts rejects a null value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts 0 \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parts rejects negative values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts -1 \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parts rejects values above 100 (101)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts 101 \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parts rejects floats"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts 2.5 \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parts rejects non-numeric values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts A \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option chimeras_parts rejects empty value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --chimeras_parts  \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## --------------------------------------------------------------------- sizein

# propagate abundance annotation from input
# sizein is always implied for the chimeras_denovo command

DESCRIPTION="chimeras_denovo: option sizein is accepted"
printf ">s;size=9\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --sizein \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# sizein is implied: abundance from the input header is preserved in output
DESCRIPTION="chimeras_denovo: sizein is always implied (abundance propagated to nonchimeras)"
printf ">s;size=42\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras - | \
    grep -q "^>s;size=42$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# sizein is implied: abundance is used for chimera detection (parents with
# matching size get detected as chimera when abskew = 1.0)
DESCRIPTION="chimeras_denovo: sizein is always implied (used for chimera detection)"
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
        --quiet \
        --chimeras - | \
    grep -q "^>sQ;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


# sequences without abundance are assumed to have size=1
DESCRIPTION="chimeras_denovo: entries without abundance are assumed size=1 (nonchimeras)"
printf ">s\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --sizeout \
        --nonchimeras - | \
    grep -q "^>s;size=1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------------------- xn

# weight of 'no' votes (beta), default 8.0. Manpage: "strictly positive real
# number", but actual behaviour rejects any value <= 1.0.

DESCRIPTION="chimeras_denovo: option xn is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xn 8.0 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option xn accepts integers"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xn 8 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option xn accepts values greater than 1.0"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xn 1.001 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option xn rejects 1.0 (must be > 1)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xn 1.0 \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option xn rejects a null value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xn 0.0 \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option xn rejects negative values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xn -1 \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option xn rejects non-numeric values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xn A \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option xn accepts large values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xn 1000.0 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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


DESCRIPTION="chimeras_denovo: option alignwidth folds each position (alignwidth = 1)"
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
        --alignwidth 61 \
        --alnout - | \
    awk '{if ($1 ~ /^Model/) matches += 1}
         END {exit matches == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


## ---------------------------------------------------------------- fasta_width

# width of sequences in fasta output (default 80); 0 suppresses folding

DESCRIPTION="chimeras_denovo: option fasta_width is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --fasta_width 80 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option fasta_width accepts a null value (no folding)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --fasta_width 0 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option fasta_width rejects non-numeric values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --fasta_width A \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# default width is 80 nucleotides: an 81-nt sequence is folded to 2 lines
DESCRIPTION="chimeras_denovo: default fasta_width is 80 (81-nt sequence is folded)"
printf ">s;size=1\n%s%s\n" \
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
    "A" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --quiet \
        --nonchimeras - | \
    grep -c "^A" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# with fasta_width = 0, the 81-nt sequence is not folded (single line)
DESCRIPTION="chimeras_denovo: fasta_width 0 suppresses folding (81-nt sequence on one line)"
printf ">s;size=1\n%s%s\n" \
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
    "A" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --fasta_width 0 \
        --quiet \
        --nonchimeras - | \
    grep -c "^A" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# fasta_width does not affect alnout (uses --alignwidth)
DESCRIPTION="chimeras_denovo: fasta_width does not affect alnout"
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
        --fasta_width 2 \
        --alnout - | \
    awk '{if ($1 ~ /^Model/) matches += 1}
         END {exit matches == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


## --------------------------------------------------------------------- gapext

# gap extension penalties, default "2I/1E" (2 internal, 1 terminal)

DESCRIPTION="chimeras_denovo: option gapext is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --gapext "2I/1E" \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option gapext accepts a single numeric value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --gapext "2" \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option gapext rejects invalid strings"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --gapext "invalid" \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## -------------------------------------------------------------------- gapopen

# gap opening penalties, default "20I/2E"

DESCRIPTION="chimeras_denovo: option gapopen is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --gapopen "20I/2E" \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option gapopen accepts a single numeric value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --gapopen "20" \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option gapopen rejects invalid strings"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --gapopen "invalid" \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ------------------------------------------------------------------- hardmask

# replace masked nucleotides with Ns

DESCRIPTION="chimeras_denovo: option hardmask is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --hardmask \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# default qmask is dust: a homopolymer is masked (lowercased); with
# --hardmask it is replaced by N
DESCRIPTION="chimeras_denovo: hardmask replaces masked nucleotides with Ns (nonchimeras)"
printf ">s;size=1\n%s\n" "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --hardmask \
        --quiet \
        --nonchimeras - | \
    grep -qx "NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# when qmask is none, nothing is masked, hardmask has no effect
DESCRIPTION="chimeras_denovo: hardmask has no effect when qmask is none"
printf ">s;size=1\n%s\n" "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --hardmask \
        --quiet \
        --nonchimeras - | \
    grep -qx "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## --------------------------------------------------------------- label_suffix

# add a user-specified suffix to sequence headers in output

DESCRIPTION="chimeras_denovo: option label_suffix is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --label_suffix ";foo=bar" \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: label_suffix adds the suffix to nonchimeras headers"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --label_suffix ";foo=bar" \
        --quiet \
        --nonchimeras - | \
    grep -qx ">s;size=1;foo=bar" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: label_suffix adds the suffix to chimeras headers"
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
        --label_suffix ";foo=bar" \
        --quiet \
        --chimeras - | \
    grep -qx ">sQ;size=1;foo=bar" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


# label_suffix is applied to fasta outputs, not to alnout (which does not
# write a fasta header) or tabbedout
DESCRIPTION="chimeras_denovo: label_suffix does not appear in alnout"
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
        --label_suffix ";foo=bar" \
        --quiet \
        --alnout - | \
    grep -q "foo=bar" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


# combines with --sizeout: label_suffix is appended first, then size=
DESCRIPTION="chimeras_denovo: label_suffix combines with sizeout (suffix before size)"
printf ">s\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --sizeout \
        --label_suffix ";foo=bar" \
        --quiet \
        --nonchimeras - | \
    grep -qx ">s;foo=bar;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------------ lengthout

DESCRIPTION="chimeras_denovo: lengthout is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --lengthout \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: lengthout adds sequence lengths to fasta output (non-chimeras)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --lengthout \
        --nonchimeras - | \
    grep -q "length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: lengthout adds sequence lengths to fasta output (chimeras)"
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
        --quiet \
        --lengthout \
        --chimeras - | \
    grep -q "length=20" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


# alnout already outputs sequence lengths
DESCRIPTION="chimeras_denovo: lengthout does not add sequence lengths to original headers (alnout)"
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
        --quiet \
        --lengthout \
        --alnout - | \
    grep -q "length=20" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: lengthout does not add sequence lengths to original headers (tabbedout)"
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
        --quiet \
        --lengthout \
        --tabbedout - | \
    grep -q "length=20" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: lengthout adds sequence lengths to fasta output (fastq input)"
printf "@s;size=1\nA\n+\nI\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --lengthout \
        --nonchimeras - | \
    grep -q "length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------------------ log

# write messages to a named file

DESCRIPTION="chimeras_denovo: option log is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --log /dev/null \
        --nonchimeras /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: log writes messages to the given file"
TMP=$(mktemp)
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --log "${TMP}" \
        --nonchimeras /dev/null 2> /dev/null
[[ -s "${TMP}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP


DESCRIPTION="chimeras_denovo: log records the vsearch version"
TMP=$(mktemp)
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --log "${TMP}" \
        --nonchimeras /dev/null 2> /dev/null
grep --quiet --ignore-case "vsearch" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP


DESCRIPTION="chimeras_denovo: log records the command line"
TMP=$(mktemp)
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --log "${TMP}" \
        --nonchimeras /dev/null 2> /dev/null
grep --quiet -- "--chimeras_denovo" "${TMP}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP


# log can be written to stdout
DESCRIPTION="chimeras_denovo: log can output to stdout (-)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --log - \
        --nonchimeras /dev/null 2> /dev/null | \
    grep --quiet --ignore-case "vsearch" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ---------------------------------------------------------------------- match

# score for a nucleotide match (default 2)

DESCRIPTION="chimeras_denovo: option match is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --match 2 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option match accepts arbitrary positive integers"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --match 10 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option match rejects floats"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --match 2.5 \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option match rejects non-numeric values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --match A \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## --------------------------------------------------------------- maxseqlength

# discard sequences longer than N (default 50,000)

DESCRIPTION="chimeras_denovo: option maxseqlength is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --maxseqlength 50000 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option maxseqlength discards longer sequences"
printf ">s;size=1\nAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --maxseqlength 5 \
        --quiet \
        --nonchimeras - 2> /dev/null | \
    grep --quiet "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option maxseqlength keeps sequences at the boundary"
printf ">s;size=1\nAAAAA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --maxseqlength 5 \
        --quiet \
        --nonchimeras - | \
    grep --quiet "^>s;size=1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option maxseqlength rejects non-numeric values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --maxseqlength A \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## --------------------------------------------------------------- minseqlength

# discard sequences shorter than N (default 32)

DESCRIPTION="chimeras_denovo: option minseqlength is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --minseqlength 1 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option minseqlength accepts a null value"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --minseqlength 0 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option minseqlength rejects negative values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --minseqlength -1 \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option minseqlength rejects non-numeric values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --minseqlength A \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option minseqlength discards shorter sequences"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --minseqlength 5 \
        --quiet \
        --nonchimeras - 2> /dev/null | \
    grep --quiet "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option minseqlength keeps sequences at the boundary"
printf ">s;size=1\nAAAAA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --minseqlength 5 \
        --quiet \
        --nonchimeras - | \
    grep --quiet "^>s;size=1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------------- mismatch

# score for a nucleotide mismatch (default -4)

DESCRIPTION="chimeras_denovo: option mismatch is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --mismatch 4 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option mismatch rejects floats"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --mismatch 4.5 \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option mismatch rejects non-numeric values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --mismatch A \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ---------------------------------------------------------------- no_progress

# suppress the progress indicator written to stderr

DESCRIPTION="chimeras_denovo: option no_progress is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --no_progress \
        --nonchimeras /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# no_progress still allows other stderr messages (version, stats)
DESCRIPTION="chimeras_denovo: no_progress does not silence informational messages"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --no_progress \
        --nonchimeras /dev/null 2>&1 | \
    grep --quiet --ignore-case "vsearch" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## -------------------------------------------------------------- notrunclabels

# do not truncate sequence headers at the first space or tab

DESCRIPTION="chimeras_denovo: option notrunclabels is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --notrunclabels \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# by default, headers are truncated at the first space
DESCRIPTION="chimeras_denovo: default truncates headers at first space"
printf ">s foo\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: notrunclabels retains text after first space"
printf ">s foo\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --notrunclabels \
        --quiet \
        --nonchimeras - | \
    grep -qx ">s foo" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: notrunclabels retains text after first tab"
printf ">s\tfoo\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --notrunclabels \
        --quiet \
        --nonchimeras - | \
    grep -qP "^>s\tfoo$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# notrunclabels applies to chimeras output too
DESCRIPTION="chimeras_denovo: notrunclabels retains full header in chimeras output"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"
(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1 foo bar\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --notrunclabels \
        --quiet \
        --chimeras - | \
    grep -qx ">sQ;size=1 foo bar" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

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
        --line-regexp \
        --quiet ">sQ;size=1@${A_START}${B_END}@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: option qmask accepts 'dust' (default)"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask dust \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option qmask accepts 'soft'"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask soft \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: option qmask rejects unknown values"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask bogus \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# with --qmask soft, lowercase letters are preserved (soft masking)
DESCRIPTION="chimeras_denovo: qmask soft preserves lowercase in output"
printf ">s;size=1\n%s\n" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask soft \
        --quiet \
        --nonchimeras - | \
    grep -qx "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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


# use fake option --quiet2 to trigger an error
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

# replace sequence headers with prefix + ticker

DESCRIPTION="chimeras_denovo: option relabel is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel "new_" \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel replaces nonchimeras headers with prefix + ticker"
printf ">s1;size=1\nA\n>s2;size=1\nC\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel "new_" \
        --quiet \
        --nonchimeras - | \
    grep -qx ">new_1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel uses an incrementing ticker"
printf ">s1;size=1\nA\n>s2;size=1\nC\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel "new_" \
        --quiet \
        --nonchimeras - | \
    grep -qx ">new_2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel applies to chimeras output too"
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
        --relabel "chimera_" \
        --quiet \
        --chimeras - | \
    grep -qx ">chimera_1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: relabel accepts an empty prefix"
printf ">s1;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel "" \
        --quiet \
        --nonchimeras - | \
    grep -qx ">1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## --------------------------------------------------------------- relabel_keep

# retain the original header after the new one, separated by a space

DESCRIPTION="chimeras_denovo: option relabel_keep is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel "new_" \
        --relabel_keep \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel_keep retains the original header after the new one"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel "new_" \
        --relabel_keep \
        --quiet \
        --nonchimeras - | \
    grep -qx ">new_1 s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# without any relabel option, relabel_keep has no visible effect (still works)
DESCRIPTION="chimeras_denovo: relabel_keep alone is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_keep \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ---------------------------------------------------------------- relabel_md5

# replace header with MD5 hex digest of sequence (uppercase, U->T)

DESCRIPTION="chimeras_denovo: option relabel_md5 is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_md5 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# md5 of "A" is 7fc56270e7a70fa81a5935b72eacbe29
DESCRIPTION="chimeras_denovo: relabel_md5 replaces header with MD5 digest"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_md5 \
        --quiet \
        --nonchimeras - | \
    grep -qx ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# md5 of "AAA" is e1faffb3e614e6c2fba74296962386b7; lowercase is normalized
DESCRIPTION="chimeras_denovo: relabel_md5 normalizes lowercase to uppercase for the digest"
printf ">s;size=1\naaa\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --relabel_md5 \
        --quiet \
        --nonchimeras - | \
    grep -qx ">e1faffb3e614e6c2fba74296962386b7" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# md5 of "TTT" is da189c1824c1b701010054237bcc143e; U is normalized to T
DESCRIPTION="chimeras_denovo: relabel_md5 normalizes U to T for the digest"
printf ">s;size=1\nUUU\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --qmask none \
        --relabel_md5 \
        --quiet \
        --nonchimeras - | \
    grep -qx ">da189c1824c1b701010054237bcc143e" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## --------------------------------------------------------------- relabel_self

# replace header with the sequence itself

DESCRIPTION="chimeras_denovo: option relabel_self is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_self \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel_self replaces header with the sequence itself"
printf ">s;size=1\nACGT\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_self \
        --quiet \
        --nonchimeras - | \
    grep -qx ">ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## --------------------------------------------------------------- relabel_sha1

# replace header with SHA1 hex digest of sequence (uppercase, U->T)

DESCRIPTION="chimeras_denovo: option relabel_sha1 is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_sha1 \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# sha1 of "A" is 6dcd4ce23d88e2ee9568ba546c007c63d9131c1b
DESCRIPTION="chimeras_denovo: relabel_sha1 replaces header with SHA1 digest"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_sha1 \
        --quiet \
        --nonchimeras - | \
    grep -qx ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ---------------------------------------------- relabel options are mutually exclusive

# only one of relabel, relabel_self, relabel_md5, relabel_sha1 may be used

DESCRIPTION="chimeras_denovo: relabel and relabel_md5 are mutually exclusive"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel "new_" \
        --relabel_md5 \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel and relabel_sha1 are mutually exclusive"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel "new_" \
        --relabel_sha1 \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel and relabel_self are mutually exclusive"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel "new_" \
        --relabel_self \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel_md5 and relabel_sha1 are mutually exclusive"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_md5 \
        --relabel_sha1 \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel_md5 and relabel_self are mutually exclusive"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_md5 \
        --relabel_self \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: relabel_sha1 and relabel_self are mutually exclusive"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_sha1 \
        --relabel_self \
        --nonchimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## --------------------------------------------------------------------- sample

# add a ;sample=<string> annotation to sequence headers

DESCRIPTION="chimeras_denovo: option sample is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --sample "ABC" \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: sample adds ';sample=<string>' to nonchimeras headers"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --sample "ABC" \
        --quiet \
        --nonchimeras - | \
    grep -qx ">s;size=1;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: sample adds ';sample=<string>' to chimeras headers"
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
        --sample "ABC" \
        --quiet \
        --chimeras - | \
    grep -qx ">sQ;size=1;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


# sample is not added to tabbedout output
DESCRIPTION="chimeras_denovo: sample does not modify tabbedout query label"
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
        --sample "ABC" \
        --quiet \
        --tabbedout - | \
    awk '{exit ($2 == "sQ;size=1") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


## -------------------------------------------------------------------- sizeout

# add ;size=N annotations to sequence headers

DESCRIPTION="chimeras_denovo: option sizeout is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --sizeout \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# abundance is already preserved by default (sizein is implied); sizeout
# makes sure the ;size= annotation is written to output
DESCRIPTION="chimeras_denovo: sizeout adds ;size=N to output headers"
printf ">s\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --sizeout \
        --quiet \
        --nonchimeras - | \
    grep -qx ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# sizeout applies to chimeras output
DESCRIPTION="chimeras_denovo: sizeout adds ;size=N to chimeras output headers"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"
(
    printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
    printf ">sQ\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --sizeout \
        --quiet \
        --chimeras - | \
    grep -qx ">sQ;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


# sizeout combined with relabel_md5: size appears at the end of the digest header
DESCRIPTION="chimeras_denovo: sizeout combines with relabel_md5"
printf ">s;size=42\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --relabel_md5 \
        --sizeout \
        --quiet \
        --nonchimeras - | \
    grep -qx ">7fc56270e7a70fa81a5935b72eacbe29;size=42" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## -------------------------------------------------------------------- threads

DESCRIPTION="chimeras_denovo: --threads is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --chimeras_denovo /dev/stdin \
        --chimeras /dev/null \
        --threads 1 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="chimeras_denovo: --threads > 1 triggers a warning (not multithreaded)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --chimeras_denovo /dev/stdin \
        --chimeras /dev/null \
        --threads 2 \
        --quiet 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------------------ xee

# strip ;ee= expected error annotations from output headers

DESCRIPTION="chimeras_denovo: option xee is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xee \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: xee removes ee= annotations (nonchimeras)"
printf ">s;size=1;ee=0.5\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xee \
        --quiet \
        --nonchimeras - | \
    grep -q "ee=0.5" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# without xee, the ee annotation is preserved
DESCRIPTION="chimeras_denovo: ee= annotations are preserved by default"
printf ">s;size=1;ee=0.5\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --nonchimeras - | \
    grep -q "ee=0.5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# xee applies to chimeras output too
DESCRIPTION="chimeras_denovo: xee removes ee= annotations (chimeras)"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"
(
    printf ">sA;size=9;ee=0.5\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9;ee=0.5\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1;ee=0.5\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xee \
        --quiet \
        --chimeras - | \
    grep -q "ee=0.5" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


## -------------------------------------------------------------------- xlength

DESCRIPTION="chimeras_denovo: xlength is accepted"
printf ">s;length=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --xlength \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: xlength removes sequence lengths from fasta input (non-chimeras)"
printf ">s;length=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --xlength \
        --nonchimeras - | \
    grep -q "length=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="chimeras_denovo: xlength removes sequence lengths from fastq input (non-chimeras)"
printf "@s;length=1\nA\n+\nI\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --xlength \
        --nonchimeras - | \
    grep -q "length=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: xlength removes sequence lengths from fasta input (chimeras)"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=9;length=20\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9;length=20\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1;length=20\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --xlength \
        --chimeras - | \
    grep -q "length=20" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: xlength removes sequence lengths from fasta input (alnout)"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=9;length=20\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9;length=20\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1;length=20\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --xlength \
        --alnout - | \
    grep -q "length=20" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


DESCRIPTION="chimeras_denovo: xlength removes sequence lengths from fasta input (tabbedout)"
#        1...5...10
A_START="GTAGGCCGTG"
A_END="${A_START}"
B_START="CTGAGCCGTA"
B_END="${B_START}"

(
    printf ">sA;size=9;length=20\n%s\n" "${A_START}${A_END}"
    printf ">sB;size=9;length=20\n%s\n" "${B_START}${B_END}"
    printf ">sQ;size=1;length=20\n%s\n" "${A_START}${B_END}"
) | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --xlength \
        --tabbedout - | \
    grep -q "length=20" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

unset A_START A_END B_START B_END


# lengthout adds to output
DESCRIPTION="chimeras_denovo: xlength removes sequence lengths from fasta input (lengthout)"
printf ">s;length=2\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --quiet \
        --xlength \
        --lengthout \
        --nonchimeras - | \
    grep -q "length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------------------- xn
## ---------------------------------------------------------------------- xsize

# strip ;size= abundance annotations from output headers

DESCRIPTION="chimeras_denovo: option xsize is accepted"
printf ">s;size=1\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xsize \
        --quiet \
        --nonchimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: xsize removes size= annotations (nonchimeras)"
printf ">s;size=9\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xsize \
        --quiet \
        --nonchimeras - | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


# xsize applies to chimeras output too
DESCRIPTION="chimeras_denovo: xsize removes size= annotations (chimeras)"
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
        --xsize \
        --quiet \
        --chimeras - | \
    grep -qx ">sQ" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

unset A_START A_END B_START B_END


# xsize + sizeout: the new size annotation is still added (xsize strips the
# original, sizeout appends the current abundance)
DESCRIPTION="chimeras_denovo: xsize combined with sizeout still writes ;size="
printf ">s;size=42\nA\n" | \
    ${VSEARCH} \
        --chimeras_denovo - \
        --xsize \
        --sizeout \
        --quiet \
        --nonchimeras - | \
    grep -qx ">s;size=42" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then
    #        1...5...10
    A_START="GTAGGCCGTG"
    A_END="${A_START}"
    B_START="CTGAGCCGTA"
    B_END="${B_START}"
    TMP=$(mktemp)
    FASTA=$(printf ">sA;size=9\n%s\n" "${A_START}${A_END}"
            printf ">sB;size=9\n%s\n" "${B_START}${B_END}"
            printf ">sQ;size=1\n%s\n" "${A_START}${B_END}")
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --chimeras_denovo <(echo "${FASTA}") \
        --chimeras /dev/null \
        --nonchimeras /dev/null \
        --alnout /dev/null \
        --tabbedout /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--chimeras_denovo valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--chimeras_denovo valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP A_START A_END B_START B_END FASTA
fi


#*****************************************************************************#
#                                                                             #
#                              memory issues                                  #
#                                                                             #
#*****************************************************************************#

# Notes:
#  - refactoring to use std::vector rather than raw memory makes the
#    bug more obvious (when compiled in debug mode). There is a
#    precise error message that shows that we are trying to fit a
#    100-char string into a 68-char vector,
#  - issue is that the query should be cut into three parts, but the
#    variable 'parts' went to 3 (when working of parent C), then to 2
#    (when we reached the actual Query sequence). So now we are trying
#    to cut the query into two parts, which overflows
#  - parts sould be std::max(formula, parts), but it changes the
#    results on larger datasets
#    (run_20190318_16S_341F_785R_113_samples.OTU.filtered.cleaved.mumu.uchime.fas)
#  - I need to write more tests before I actually try to fix that bug

DESCRIPTION="chimeras_denovo: no segfault"
(
    printf ">pA;size=9"
    printf "\n"
    printf "TGATACATAGTATCGTCACATGAAAGGATTGGGTCGGATGTCTCAAACGAATTCGAATTCTTTTCATGGTATTTATTCAACGCAATGGCAGTTTGTGTTAATACGTCGATGGCTACGTATAATCAATTTGGGGGAATTTTACCATCGTCAGACATGCCCCAGGACAATAATATTCAGACTGGTAATAGTGGCTTAGCATTG"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "TGGGAATTGACATGACTTACCCCGTTGGACTTTACATTCCATAATGTTACCTAATTATCTCATATCTAAGGGTTTAAGCTGTTGCGCTGGATGTCGTGTCTACGACGGTGTACCATTATTCGTTATCCTAAAAACATCTCACGTTGATAATGGTAGAAGGACCTGGAGATACACAAGGAAAAACAATTCGAGCAAAAAAA"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "ACTTTTCTGGTCGTAATGTATGATTAGTTACTTTTAGCAGAGTATCGTTCTCGCGTAATAGAAGTCAATCCATACCAAGTATGTCCAAGCAGTTAACCACTATTAGACGTGTTAATCATTTGACGTTATGACGATGACATGAATCGCTAGGGCTGACGAGATTCTTTACCGCGCGTTCTAACACGTCGTTTAGACCATGG"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "TCAAGATGTTTAACCTTCCGTGCACCTTTTGGTCCATTACCGACAGGGTACATACTGTTATGCCGTCCACATTAAAGGACGCAAATGTTCTCTTATTCTGACGAAGTTACAAGGAGGGCCAATCGGAGTTTCTTTTACTACACCGGACCCAGGAATGTGAACAGATTATGTTTTTATTCAGGACTGGGCTTAACATGAGGA"
    printf "\n"
) | \
    "${VSEARCH}" \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: no double free or corruption"
(
    printf ">pA;size=9"
    printf "\n"
    printf "AGCGACCTTTCAGGCCGAATGCAACAGAGTAGAAGCCCCAATTACCTATGAAAAGAATTTCGCTTTTATAGCTTTAAGTGGTAGGACTATCGATATTATGTATCAACCTCAGACAGACGATCCAAGATAATATTACATTTTGTGGATGTTGCTTGCCTGTCTCTGTTTTGGAATCGGAGTCACCCTGGGTGCTCAGTTGTT"
    printf "\n"
    printf ">pB;size=9"
    printf "\n"
    printf "GTTAGAGGATCTCCGTAGAGTTTTTCACATATATGGGTTTGAATAGCGAGCACACTTGCAACTCTCAAGTGCAGCCATGTTGGAAGGTTGTATTTACCAAAATGTGTGGTGTTCTCACCGTGTTTACATCAGGCATTTGGAAACTATTCTAATAGAATACTACTAAATCGAATACAGCTGTGAAGACTCTAGGTCTTATT"
    printf "\n"
    printf ">pC;size=9"
    printf "\n"
    printf "ATACGCGGATTTCCCCGTCGTCAACGTGTCCACTTCTGCTTAGGTATTAACCCAAATAATCCGCGAGGTGTTATCTCGCGGGCTGACTTAGGTACAAGTTCAGCTTTCCTGGTAGACATATGGGGAGCGCCAAATTTCGGTTTATATGTTTCTAGACATCGTATTAAATCTCTGGAGGGGCATTTAATCATAGTTAGAAG"
    printf "\n"
    printf ">Q;size=1"
    printf "\n"
    printf "AGCTAAGCGAATGTCTCGTACTGGGCACATATTTCCTAAATACTTCCAGAATCCTTAATGCCATTAAGATCGTAACCTCAACGATGTCGTTCGCGCATAAGTTTTCAGAATTAGTATTTTGTTCGGTTGATACCATGTGACCTAGTAGGTATACTCCATAAGTCAAGCTGTCATAATTATTCTAATTCTGCGTAGGGGAGC"
    printf "\n"
) | \
    "${VSEARCH}" \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="chimeras_denovo: no invalid pointer (munmap_chunk)"
(
    printf ">pA;size=9;length=201"
    printf "\n"
    printf "GGGTTTAAGTATCGTAGAAATTTAGTACATTTTCTGTACCCGTATCCTTATTCGTCAATAACCGTCTGCAACTATATTCGACATACGGCATCTAAAGATATTATGTACGATTTTTTCCCATCCTGTCTAGCATATGCTTACCATCTATAAACTTTTGATACTATGATATCCTTAGCACCGTAAGGATTCAAGAGGAGCAGG"
    printf "\n"
    printf ">pB;size=9;length=200"
    printf "\n"
    printf "AGACCTAAAACTTTTAACGATTTACCTTCGCCCATTCTGAAATTGTGAAATACCTCGTCTTTTAAGTTAGAAATGTAGGCGTTTACCTAGTAGCTAGGCGTGAATATACGAGAGTGTCTCTCCCCCCGTATCCGCGCTGATTGGTTTCTTCTCAATTGCTATTTGCACCGGTCGTTTAACCTGAAAACTGATTTATGTAG"
    printf "\n"
    printf ">pC;size=9;length=200"
    printf "\n"
    printf "TGACCGGGATTTCCGAGCGAACTTCCCGAGAGCATCTAGCGAATACCCAGCTTGAGGATCTAATTCGAGCATGGTCGCAGCAGGACTGCGTTATTTACTGCCGGCACCACAAGAGACGATGCTATCTAATTATCGCTTATTGAGTCGCGATTGCTAAAGTTGATTTTTTCCATTTTAGTCTATAAATTTAGGAAGGATCG"
    printf "\n"
    printf ">Q;size=1;length=201"
    printf "\n"
    printf "ATTAACTGTATGCGTGCTGGTGGGGTCATCCTAGAATGTTTTGGATGTTTCTAAGGTCTAATAATTACATAAAAACGGCGTCGCTGTCGTCGCCAACGAGATCGCTTTTCCTACCGATTTCAGGGTCTCTGAGCCCTGACTAAAAATAGAGACTGTTAATTGACGACCTACATTCCTCCTGATAACGACTACTAATTGTAA"
    printf "\n"
) | \
    "${VSEARCH}" \
        --chimeras_denovo - \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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

# --threads is ignored *DONE*
# - test chimeras with more than two parents, *DONE*
# - test chimeras with more than two parents for a given chunk,
# - check coverage, *90%*
# - test tabbedout output, *DONE*
# - tabbedout does not report more than 3 parents! *DONE*
# - test tabbedout highest similarity is reported,
# - fasta and fastq IUPAC are accepted,
# - test remaining command-specific parameters
# - test if relabel applies to both chimeras and non-chimeras
# - lengthout: add length to chimeras *DONE*
# - lengthout: works with fastq input? *DONE*
# - lengthout: not added to alnout and tabbedout? *DONE*


## potential mistakes?

# - fix: --chimeras_diff_pct is undocumented *DONE*
# - --chimeras_diff_pct is largely untested (no expected behavior)
# - no capacity to read bzip2 or gzip?
# - accept replicated sequences (same names)?
# --tabbedout "Fatal error: No output files specified" *DONE*
