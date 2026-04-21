#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="uchime_denovo"
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


## vsearch --uchime_denovo fastafile (--chimeras | --nonchimeras |
## --uchimealns | --uchimeout) outputfile [options]

## Test sequences used across the script (from Edgar et al. 2011
## Bioinformatics 27:2194-2200): two parent amplicons and a chimera
## made of the beginning of parentA and the end of parentB.
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

DESCRIPTION="--uchime_denovo is accepted"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo reads from stdin (-)"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo reads from a regular file"
TMP=$(mktemp)
printf ">s;size=1\n%s\n" "${PARENT_A}" > "${TMP}"
"${VSEARCH}" \
    --uchime_denovo "${TMP}" \
    --quiet \
    --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--uchime_denovo fails if input file does not exist"
"${VSEARCH}" \
    --uchime_denovo /no/such/file \
    --quiet \
    --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo fails if input file is not readable"
TMP=$(mktemp)
printf ">s;size=1\n%s\n" "${PARENT_A}" > "${TMP}"
chmod u-r "${TMP}"
"${VSEARCH}" \
    --uchime_denovo "${TMP}" \
    --quiet \
    --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--uchime_denovo accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo accepts fasta input"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo rejects input that is not fasta or fastq"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --quiet \
        --chimeras /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo fails without any output option"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## each listed output option accepted as sole output option
for OPT in --chimeras --nonchimeras --uchimealns --uchimeout ; do
    DESCRIPTION="--uchime_denovo accepts ${OPT} as sole output option"
    printf ">s;size=1\n%s\n" "${PARENT_A}" | \
        "${VSEARCH}" \
            --uchime_denovo - \
            "${OPT}" /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OPT

## --borderline is listed in the manpage as an output option, but it
## cannot be used alone: vsearch reports "No output files specified"
DESCRIPTION="--uchime_denovo --borderline is not accepted as sole output option"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --borderline /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --borderline is accepted together with another output option"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --chimeras /dev/null \
        --borderline /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## chimera is detected with default parameters
DESCRIPTION="--uchime_denovo detects a chimera with default parameters"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --chimeras - \
        --quiet | \
    grep -qw ">chimeraAB;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo writes non-chimeric parents to --nonchimeras"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --nonchimeras - \
        --quiet | \
    grep -c "^>parent" | \
    grep -qw "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --sizein is always implied: abundance annotations are parsed even
## when --sizein is not specified
DESCRIPTION="--uchime_denovo --sizein is implied (abundance used without --sizein)"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --uchimeout - \
        --quiet | \
    awk '$NF == "Y"' | \
    grep -qw "chimeraAB;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## without abundance skew (all sizes equal), no chimera is detected
DESCRIPTION="--uchime_denovo does not detect a chimera without abundance skew"
printf ">parentA;size=10\n%s\n>parentB;size=10\n%s\n>chimeraAB;size=10\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## plus strand only (manpage): a reverse-complemented chimera is not
## detected as a chimera of the same parents
DESCRIPTION="--uchime_denovo compares sequences on plus strand only"
REVCOMP=$(rev <<< "${CHIMERA_AB}" | tr 'ACGTacgt' 'TGCAtgca')
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>revcomp;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${REVCOMP}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset REVCOMP

## default masking is dust (output is lowercased for low-complexity regions)
DESCRIPTION="--uchime_denovo default masking is dust (low complexity regions lowercased)"
printf ">s;size=1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --nonchimeras - \
        --quiet | \
    awk '/^>/ {next} /[a-z]/ {found = 1} END {exit !found}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## default --uchimeout has 18 tab-separated fields
DESCRIPTION="--uchime_denovo default --uchimeout has 18 tab-separated fields"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '{print NF}' | \
    sort -u | \
    grep -qx "18" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------------- abskew

DESCRIPTION="--uchime_denovo --abskew is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --abskew 2.0 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --abskew 2 (default) detects the chimera"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --abskew 2 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -qw "chimeraAB;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --abskew 100 is too strict (no chimera detected)"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --abskew 100 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --abskew 1.0 is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --abskew 1.0 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --abskew < 1.0 is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --abskew 0.9 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------------ dn

DESCRIPTION="--uchime_denovo --dn is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --dn 1.4 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## larger --dn reduces the likelihood of tagging a sequence as a
## chimera (fewer false positives)
DESCRIPTION="--uchime_denovo large --dn suppresses chimera detection"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --dn 1000000 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --dn 0 is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --dn 0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo negative --dn is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --dn -1 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------ mindiffs

DESCRIPTION="--uchime_denovo --mindiffs is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --mindiffs 3 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## large --mindiffs suppresses chimera detection
DESCRIPTION="--uchime_denovo large --mindiffs suppresses chimera detection"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --mindiffs 1000 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --mindiffs 0 is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --mindiffs 0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo negative --mindiffs is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --mindiffs -1 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------- mindiv

DESCRIPTION="--uchime_denovo --mindiv is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --mindiv 0.8 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo large --mindiv suppresses chimera detection"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --mindiv 99.0 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --mindiv 0 is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --mindiv 0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo negative --mindiv is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --mindiv -1 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------------- minh

DESCRIPTION="--uchime_denovo --minh is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --minh 0.28 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo high --minh suppresses chimera detection"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --minh 100 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## manpage says "Accepted values range from 0.0 to 1.0 included", but
## vsearch rejects --minh 0.0 ("Argument to --minh must be > 0")
DESCRIPTION="--uchime_denovo --minh 0 is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --minh 0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo negative --minh is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --minh -0.1 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------- sizein

DESCRIPTION="--uchime_denovo --sizein is accepted (implied but can be given)"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --sizein \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- uchimeout5

DESCRIPTION="--uchime_denovo --uchimeout5 is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --uchimeout /dev/null \
        --uchimeout5 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uchimeout5 drops the 5th field (top parent T), so the line has
## 17 tab-separated fields instead of 18
DESCRIPTION="--uchime_denovo --uchimeout5 produces 17 tab-separated fields"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --uchimeout - \
        --uchimeout5 \
        --quiet | \
    awk -F'\t' '{print NF}' | \
    sort -u | \
    grep -qx "17" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------------- xn

DESCRIPTION="--uchime_denovo --xn is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xn 8.0 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## larger --xn reduces the likelihood of tagging a sequence as a
## chimera
DESCRIPTION="--uchime_denovo large --xn suppresses chimera detection"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xn 1000000 \
        --uchimeout - \
        --quiet | \
    awk -F'\t' '$NF == "Y"' | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## manpage says "strictly positive real number", but vsearch rejects
## values <= 1.0 ("Argument to --xn must be > 1")
DESCRIPTION="--uchime_denovo --xn 1.0 is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xn 1.0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --xn 0 is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xn 0 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo negative --xn is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xn -1 \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------- alignwidth

DESCRIPTION="--uchime_denovo --alignwidth is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --alignwidth 80 \
        --uchimealns /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --alignwidth 0 suppresses folding"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --alignwidth 0 \
        --uchimealns - \
        --quiet | \
    awk '/^Q[[:space:]]+1[[:space:]]/ {print $NF}' | \
    grep -qw "66" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- fasta_score

DESCRIPTION="--uchime_denovo --fasta_score is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --fasta_score \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --fasta_score adds uchime_denovo=float to headers"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=1\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --fasta_score \
        --chimeras - \
        --quiet | \
    grep -qE "^>chimeraAB;size=1;uchime_denovo=[0-9.]+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- fasta_width

DESCRIPTION="--uchime_denovo --fasta_width is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --fasta_width 80 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --fasta_width folds output sequences"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --fasta_width 10 \
        --nonchimeras - \
        --quiet | \
    awk '/^>/ {next} {if (length($0) > 10) exit 1} END {exit 0}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- hardmask

DESCRIPTION="--uchime_denovo --hardmask is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --hardmask \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --hardmask replaces masked nucleotides with Ns"
printf ">s;size=1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --hardmask \
        --nonchimeras - \
        --quiet | \
    grep -qx "NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- label_suffix

DESCRIPTION="--uchime_denovo --label_suffix is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --label_suffix ";suffix" \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --label_suffix appends the suffix to headers"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --label_suffix ";suffix" \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;size=1;suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- lengthout

DESCRIPTION="--uchime_denovo --lengthout is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --lengthout \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --lengthout adds ;length=integer to headers"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --lengthout \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;size=1;length=66" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- log

DESCRIPTION="--uchime_denovo --log is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --log /dev/null \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --log writes the version line"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --log - \
        --chimeras /dev/null \
        --quiet | \
    grep -qi "vsearch" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- maxseqlength

DESCRIPTION="--uchime_denovo --maxseqlength is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --maxseqlength 50000 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --maxseqlength discards longer sequences"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --maxseqlength 50 \
        --nonchimeras - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------- minseqlength

DESCRIPTION="--uchime_denovo --minseqlength is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --minseqlength 1 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --minseqlength discards shorter sequences"
printf ">s;size=1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --minseqlength 33 \
        --nonchimeras - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------- no_progress

DESCRIPTION="--uchime_denovo --no_progress is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --no_progress \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ notrunclabels

DESCRIPTION="--uchime_denovo --notrunclabels is accepted"
printf ">s;size=1 extra\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --notrunclabels \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --notrunclabels retains full headers"
printf ">s;size=1 extra stuff\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --notrunclabels \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;size=1 extra stuff" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- qmask

for METHOD in none dust soft ; do
    DESCRIPTION="--uchime_denovo --qmask ${METHOD} is accepted"
    printf ">s;size=1\n%s\n" "${PARENT_A}" | \
        "${VSEARCH}" \
            --uchime_denovo - \
            --qmask "${METHOD}" \
            --chimeras /dev/null \
            --quiet && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset METHOD

DESCRIPTION="--uchime_denovo --qmask none disables masking (output is upper case)"
printf ">s;size=1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --qmask none \
        --nonchimeras - \
        --quiet | \
    awk '/^>/ {next} /[a-z]/ {found = 1} END {exit found}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --qmask invalid is rejected"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --qmask xxx \
        --chimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------- quiet

DESCRIPTION="--uchime_denovo --quiet suppresses messages on stdout"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --chimeras /dev/null \
        --quiet 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- relabel

DESCRIPTION="--uchime_denovo --relabel is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel "seq_" \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --relabel renames output sequences"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel "seq_" \
        --nonchimeras - \
        --quiet | \
    grep -qx ">seq_1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- relabel_keep

DESCRIPTION="--uchime_denovo --relabel_keep is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel "seq_" \
        --relabel_keep \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --relabel_keep retains the old header after a space"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel "seq_" \
        --relabel_keep \
        --nonchimeras - \
        --quiet | \
    grep -qx ">seq_1 s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- relabel_md5

DESCRIPTION="--uchime_denovo --relabel_md5 is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel_md5 \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --relabel_md5 renames sequences with md5 digests"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel_md5 \
        --nonchimeras - \
        --quiet | \
    grep -qE "^>[0-9a-f]{32}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- relabel_self

DESCRIPTION="--uchime_denovo --relabel_self is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel_self \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- relabel_sha1

DESCRIPTION="--uchime_denovo --relabel_sha1 is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel_sha1 \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --relabel_sha1 renames sequences with sha1 digests"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel_sha1 \
        --nonchimeras - \
        --quiet | \
    grep -qE "^>[0-9a-f]{40}$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel variants are mutually exclusive
DESCRIPTION="--uchime_denovo --relabel and --relabel_md5 are mutually exclusive"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --relabel "seq_" \
        --relabel_md5 \
        --nonchimeras /dev/null \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------ sample

DESCRIPTION="--uchime_denovo --sample is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --sample "ABC" \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --sample adds ;sample=string to headers"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --sample "ABC" \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;size=1;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- sizeout

DESCRIPTION="--uchime_denovo --sizeout is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --sizeout \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --sizeout adds ;size=1 to unannotated headers"
printf ">s\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --sizeout \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xee

DESCRIPTION="--uchime_denovo --xee is accepted"
printf ">s;size=1;ee=0.5\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xee \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --xee strips ;ee=float from headers"
printf ">s;size=1;ee=0.5\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xee \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- xlength

DESCRIPTION="--uchime_denovo --xlength is accepted"
printf ">s;size=1;length=66\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xlength \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --xlength strips ;length=integer from headers"
printf ">s;size=1;length=66\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xlength \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ xsize

DESCRIPTION="--uchime_denovo --xsize is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xsize \
        --nonchimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --xsize strips ;size=integer from headers"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --xsize \
        --nonchimeras - \
        --quiet | \
    grep -qx ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                        pairwise alignment options                           #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--uchime_denovo --gapext is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --gapext 2I/1E \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --gapopen is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --gapopen 20I/2E \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --match is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --match 2 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --mismatch is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --mismatch -4 \
        --chimeras /dev/null \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------------- threads

DESCRIPTION="--uchime_denovo --threads is accepted"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --threads 1 \
        --quiet \
        --chimeras /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --threads > 1 triggers a warning (not multithreaded)"
printf ">s;size=1\n%s\n" "${PARENT_A}" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --threads 2 \
        --quiet \
        --chimeras /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## options not listed in the uchime_denovo manpage or in the valid
## options list reported by vsearch; reasonable guesses that users
## might try but which vsearch rejects
for OPT in --id --strand --db --self --selfid --dbmask --gzip_decompress --bzip2_decompress ; do
    DESCRIPTION="--uchime_denovo rejects ${OPT} as an invalid option"
    printf ">s;size=1\n%s\n" "${PARENT_A}" | \
        "${VSEARCH}" \
            --uchime_denovo - \
            "${OPT}" \
            --chimeras /dev/null \
            --quiet 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OPT


## clean up common variables before the memory leaks section redefines
## them
unset A_START A_END B_START B_END PARENT_A PARENT_B CHIMERA_AB


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    LOG=$(mktemp)
    QUERY=$(mktemp)
    #        1...5...10...15...20...25...30...35
    A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"
    B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
    A_END=$(rev <<< ${A_START})
    B_END=$(rev <<< ${B_START})
    (
        printf ">parentA;size=50\n%s\n" "${A_START}${A_END}"
        printf ">parentB;size=49\n%s\n" "${B_START}${B_END}"
        printf ">chimeraAB;size=1\n%s\n" "${A_START}${B_END}"
    ) > "${QUERY}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --uchime_denovo "${QUERY}" \
        --chimeras /dev/null \
        --nonchimeras /dev/null \
        --borderline /dev/null \
        --uchimealns /dev/null \
        --uchimeout /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--uchime_denovo valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--uchime_denovo valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${QUERY}"
    unset A_START B_START A_END B_END LOG QUERY DESCRIPTION
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
