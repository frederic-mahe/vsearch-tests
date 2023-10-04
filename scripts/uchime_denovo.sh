#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="uchime_denovo"
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
#                               uchime_denovo                                 #
#                                                                             #
#*****************************************************************************#

# The valid options for the uchime_denovo command are: --abskew
# --alignwidth --borderline --chimeras --dn --fasta_score --fasta_width
# --gapext --gapopen --hardmask --log --match --mindiffs --mindiv --minh
# --mismatch --no_progress --nonchimeras --notrunclabels --qmask --quiet
# --relabel --relabel_keep --relabel_md5 --relabel_self --relabel_sha1
# --sizein --sizeout --threads --uchimealns --uchimeout --uchimeout5
# --xee --xn --xsize

# sizein is implicit
DESCRIPTION="--uchime_denovo is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

A_START="GATTGTAGGCTGG"
A_END="AGTCGAACGGTAACAGGAAG"
B_START="ACGCGAACGCTGG"
B_END="AGTCGTCGCATATCAGGAAG"
A="${A_START}${A_END}"
B="${B_START}${B_END}"
Q="${A_START}${B_END}"

printf ">sA;size=5;\n%s\n>sB;size=5;\n%s\n>sQ;size=1;\n%s\n" "${A}" "${B}" "${Q}" | \
    vsearch --uchime_denovo - --alignwidth 0 --dn 0.1 --uchimealns -

# try to reduce further by factorizing the common parts


## smallest example with default parameters
A_START="CCTTGGTAGGCCGTTGCCCTGCAACT"
A_END="GGGTCCATCTCACACCACCGGTGTACC"
B_START="TCTTGGTGGGCCGTTACCCCGCAACA"
B_END="ATCCCCATCCATCACCGATAATTTCAG"
MIDDLE="AGCTAATCAGACGC"
A="${A_START}${MIDDLE}${A_END}"
B="${B_START}${MIDDLE}${B_END}"
Q="${A_START}${MIDDLE}${B_END}"

printf ">sA;size=9\n%s\n>sB;size=9\n%s\n>sQ;size=1\n%s\n" "${A}" "${B}" "${Q}" | \
    vsearch --uchime_denovo - --alignwidth 0 --uchimealns -


printf ">sA;size=5;\n%s\n>sB;size=5;\n%s\n>sQ;size=1;\n%s\n" "${A}" "${B}" "${Q}" | \
    vsearch --uchime_denovo - --alignwidth 0 --dn 0.1 --uchimealns -  # last command tested (mid-march)
# vsearch v2.14.2_linux_x86_64, 62.8GB RAM, 8 cores
# https://github.com/torognes/vsearch

# Reading file - 100%
# 99 nt in 3 seqs, min 33, max 33, avg 33
# Masking 100%
# Sorting by abundance 100%
# Counting k-mers 100%
# Detecting chimeras 66%
# ------------------------------------------------------------------------
# Query   (   33 nt) sQ;size=1;
# ParentA (   33 nt) sA;size=5;
# ParentB (   33 nt) sB;size=5;

# A     1 GATTGTAGGCTGGAGTCGaacggTAaCAGGAAG 33
# Q     1 GATTGTAGGCTGGAGTCGTCGCATATCAGGAAG 33
# B     1 acgcGaAcGCTGGAGTCGTCGCATATCAGGAAG 33
# Diffs   AAAA A A          BBBBB  B
# Votes   ++++ + +          +++++  +
# Model   AAAAAAAAxxxxxxxxxxBBBBBBBBBBBBBBB

# Ids.  QA 81.8%, QB 81.8%, AB 63.6%, QModel 100.0%, Div. +22.2%
# Diffs Left 6: N 0, A 0, Y 6 (100.0%); Right 6: N 0, A 0, Y 6 (100.0%), Score 56.2500
# Detecting chimeras 100%
# Found 1 (33.3%) chimeras, 2 (66.7%) non-chimeras,
# and 0 (0.0%) borderline sequences in 3 unique sequences.
# Taking abundance information into account, this corresponds to
# 1 (9.1%) chimeras, 10 (90.9%) non-chimeras,
# and 0 (0.0%) borderline sequences in 11 total sequences.


# Chimera detection is based on a scoring function controlled by five
# options (−−dn, −−mindiffs, −−mindiv, −−minh, −−xn).

# --abskew (2) OK
# --dn OK
# --gapext OK
# --gapopen OK
# --match OK
# --mindiffs 3
# --mindiv 0.8
# --minh 0.28
# --mismatch
# --xn

# Formula:
# H_g = Y_g /(β(N_g +n)+A_g )

# printf '@seq1\nAGC\n+\nIII\n' | \
#     "${VSEARCH}" --uchime_denovo - --chimeras - &>/dev/null && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"

exit

# used sequences from Edgar et Al. Bioinformatics Vol.27 no. 16 2011 p.2194-2200

DESCRIPTION="--uchime_denovo is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --abskew is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --abskew 2.0 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --dn is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --dn 1.4 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --mindiffs is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --mindiffs 3 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --mindiv is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --mindiv 0.8 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --minh is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --minh 0.28 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --sizein is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --sizein --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --self is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --self --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --selfid is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --selfid --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --xn is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --uchime_denovo - --xn 8.0 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                               uchime_denovo                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--uchime_denovo --abskew gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --abskew 2 \
           --chimeras - 2>&1 | \
            awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --abskew gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --abskew 3 \
           --chimeras - 2>&1 | \
            awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --abskew gives the correct result #3"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=3\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --abskew 3 \
           --chimeras - 2>&1 | \
            awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

# the man page says value should be equal or greater than 1.0
DESCRIPTION="--uchime_denovo --abskew fails if value under 1"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=3\n%s\n' ${seq1} ${seq2} ${seq3})
"${VSEARCH}" \
    --uchime_denovo <(printf "${chimera}") \
    --abskew 0.9 \
    --quiet \
    --chimeras /dev/null && \
failure "${DESCRIPTION}" || \
    success "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --mindiffs gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --mindiffs 5  \
           --chimeras - 2>&1 | \
            awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --mindiffs gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --mindiffs 6  \
           --chimeras - 2>&1 | \
            awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --dn gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAG"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAAaCTCTTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --dn 2 \
           --xn 8 \
           --minh 0.28  \
           --chimeras - 2>&1 | \
            awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --dn gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAG"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAAaCTCTTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --dn 1.8 \
           --xn 8 \
           --minh 0.28  \
           --chimeras - 2>&1 | \
             awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --minh gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
"${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --minh 0.5  \
           --chimeras - 2>&1 | \
    grep -q "^Found 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --minh gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --minh 0.4  \
           --chimeras - 2>&1 | grep "Found" | \awk '{print $2}' -)
    [[ "${OUTPUT}" == "1" ]] && \
     success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"


#*****************************************************************************#
#                                                                             #
#                                   Output                                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--uchime_denovo --nonchimeras is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" \
           --uchime_denovo - \
           --nonchimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" \
           --uchime_denovo - \
           --uchimeout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the good score"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $1}')
[[ "${OUTPUT}" == "0.5123" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the good chimera"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $2}')
[[ "${OUTPUT}" == "seq3;size=5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the good parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $3}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the good parents #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $4}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the most similar parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $5}')
[[ "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the global similarity"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $6}')
[[ "${OUTPUT}" == "98.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the similarity with 1st parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $7}')
[[ "${OUTPUT}" == "75.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the similarity with 2nd parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $8}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the similarity between both parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $9}')
[[ "${OUTPUT}" == "68.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the similarity between query and most similar parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $10}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the correct LY"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $11}')
[[ "${OUTPUT}" == "5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the correct LN"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $12}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the correct LA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $13}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the correct RY"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $14}')
[[ "${OUTPUT}" == "14" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the correct RN"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $15}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the correct RA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $16}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the correct div"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $17}')
[[ "${OUTPUT}" == "8.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout finds the chimera"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - 2>&1 | grep "seq3;size=5" | \
             awk '{print $18}')
[[ "${OUTPUT}" == "Y" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the good score"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $1}')
[[ "${OUTPUT}" == "0.5123" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the good chimera"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $2}')
[[ "${OUTPUT}" == "seq3;size=5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the good parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $3}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the good parents #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $4}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the global similarity"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $5}')
[[ "${OUTPUT}" == "98.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the similarity with 1st parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $6}')
[[ "${OUTPUT}" == "75.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the similarity with 2nd parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $7}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the similarity between both parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $8}')
[[ "${OUTPUT}" == "68.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the similarity between query and most similar parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $9}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the correct LY"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $10}')
[[ "${OUTPUT}" == "5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the correct LN"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $11}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the correct LA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $12}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the correct RY"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $13}')
[[ "${OUTPUT}" == "14" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the correct RN"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $14}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the correct RA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $15}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the correct div"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $16}')
[[ "${OUTPUT}" == "8.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 gives the correct RA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 2>&1 | grep "seq3;size=5" | \
             awk '{print $17}')
[[ "${OUTPUT}" == "Y" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout --uchimeout5 is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
    "${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimeout - \
           --uchimeout5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --nonchimeras is showing the nonchimerics inputs"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq1_uc=$(echo $seq1 | tr [:lower:] [:upper:])
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
seq2_uc=$(echo $seq2 | tr [:lower:] [:upper:])
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
             --uchime_denovo <(printf "${chimera}") \
             --quiet \
             --nonchimeras -)
EXPECTED=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1_uc} ${seq2_uc})
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset EXPECTED OUTPUT

DESCRIPTION="--uchime_denovo --uchimealns is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
"${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns QA is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
    grep "Ids." | awk '{print $3}' 2>/dev/null)
[[ "${OUTPUT}" == "75.0%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns QB is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
    grep "Ids." | awk '{print $5}' 2>/dev/null)
[[ "${OUTPUT}" == "90.0%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns AB is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1| \
    grep "Ids." | awk '{print $7}' 2>/dev/null)
[[ "${OUTPUT}" == "68.3%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns QModel is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
    grep "Ids." | awk '{print $9}' 2>/dev/null)
[[ "${OUTPUT}" == "98.3%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Div is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
    grep "Ids." | awk '{print $11}' 2>/dev/null)
[[ "${OUTPUT}" == "+9.3%" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs left is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
             grep -n "Diffs" | grep 29:* | awk '{print $3}'  2>/dev/null)
[[ "${OUTPUT}" == "6:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs left no is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
             grep -n "Diffs" | grep 29:* | awk '{print $5}'  2>/dev/null)
[[ "${OUTPUT}" == "0," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs left abstain is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
             grep -n "Diffs" | grep 29:* | awk '{print $7}'  2>/dev/null)
[[ "${OUTPUT}" == "1," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs left yes is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
             grep -n "Diffs" | grep 29:* | awk '{print $9}'  2>/dev/null)
[[ "${OUTPUT}" == "5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs right is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
             grep -n "Diffs" | grep 29:* | awk '{print $12}'  2>/dev/null)
[[ "${OUTPUT}" == "14:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs right no is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
             grep -n "Diffs" | grep 29:* | awk '{print $14}'  2>/dev/null)
[[ "${OUTPUT}" == "0," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs right abstain is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
             grep -n "Diffs" | grep 29:* | awk '{print $16}'  2>/dev/null)
[[ "${OUTPUT}" == "0," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs right yes is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
             grep -n "Diffs" | grep 29:* | awk '{print $18}'  2>/dev/null)
[[ "${OUTPUT}" == "14" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns score is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" \
             \
           --uchime_denovo <(printf "${chimera}") \
           --uchimealns - \
           --alignwidth 95 2>&1 | \
             grep -n "Diffs" | grep 29:* | awk '{print $21}'  2>/dev/null)
[[ "${OUTPUT}" == "0.5123" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns sort by decreasing abundance"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>q3;size=1\n%s\n>q1;size=3\n%s\n>q2;size=2\n%s\n' ${seq3} ${seq1} ${seq2})
"${VSEARCH}" \
    --uchime_denovo \
    <(printf "${chimera}") \
    --quiet \
    --minseqlength 1 \
    --alignwidth 95 \
    --uchimealns - | \
    grep -q "^Query" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



exit 0
