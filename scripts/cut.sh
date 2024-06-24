#!/bin/bash -

## Print a header
SCRIPT_NAME="cut"
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

# --cut_pattern
# and at least one output file:
#    --fastaout
#    --fastaout_rev
#    --fastaout_discarded
#    --fastaout_discarded_rev

## ---------------------------------------------------------------- cut_pattern
DESCRIPTION="--cut requires --cut_pattern"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern requires a pattern"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can be inside quotes"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern requires a circumflex"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "GAATT_C" \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern requires a underscore"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATTC" \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# note: pattern can contain ^_ and IUPAC but nothing else 

DESCRIPTION="--cut --cut_pattern can be in lowercase"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern g^aatt_c \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can be in uppercase"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can mix lower- and uppercase"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AatT_C \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern accepts all IUPAC symbols"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern ac^gturykmbdhvswACGTURYKMBDHV_SW \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern rejects non-IUPAC symbols"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern x^y_z \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern circumflex can be before underscore"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern circumflex can be after underscore"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G_AATT^C \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern circumflex and underscore can be at the same position"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern GAA^_TTC \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# ## missing check!
# DESCRIPTION="--cut --cut_pattern accepts only one cutting site per strand (normal strand)"
# printf ">s\nA\n" | \
#     "${VSEARCH}" \
#         --cut - \
#         --cut_pattern G^AA^TT_C \
#         --fastaout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

# ## missing check!
# DESCRIPTION="--cut --cut_pattern accepts only one cutting site per strand (reverse strand)"
# printf ">s\nA\n" | \
#     "${VSEARCH}" \
#         --cut - \
#         --cut_pattern G^AA_TT_C \
#         --fastaout /dev/null 2> /dev/null && \
#     failure "${DESCRIPTION}" || \
# 	success "${DESCRIPTION}"

## --------------------------------------------------------------- output files

DESCRIPTION="--cut requires an output file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cut fails if unable to open fastaout for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--cut fails if unable to open fastaout_rev for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout_rev ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--cut fails if unable to open fastaout_discarded for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--cut fails if unable to open fastaout_discarded_rev for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout_rev ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

## ----------------------------------------------------------------- input file

DESCRIPTION="--cut requires an input file"
"${VSEARCH}" \
    --cut \
    --cut_pattern G^AATT_C \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cut fails if unable to open input file for reading"
TMP=$(mktemp) && chmod u-r ${TMP}  # remove write permission
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --cut ${TMP} \
    --cut_pattern G^AATT_C \
    --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r ${TMP} && rm -f ${TMP}
unset TMP


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--cut minimal working example (empty input)"
printf "" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^A_C \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut minimal working example (single fasta sequence)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut reads and returns fasta (not cut)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout_discarded - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut rejects fastq input"
printf "@\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--cut accepts identical input sequences (not dereplicated)"
printf ">s\nA\n>s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout_discarded - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut returns the same number of sequences (lossless)"
printf ">s1\nA\n>s2\nA\n>s3\nA\n>s4\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout_discarded - 2> /dev/null | \
    awk '/^>/ {s++} END {exit s == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut does not return duplicates"
printf ">s1\nA\n>s2\nA\n>s3\nA\n>s4\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout_discarded - 2> /dev/null | \
    grep "^>" | \
    sort | \
    uniq --repeated | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--cut accepts duplicated identifiers"
printf ">s\nA\n>s\nG\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut in 5' does not produce a empty fragment"
printf ">s\nCCWGG\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "^CCWGG_" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# pattern occurrences can overlap: GG^_GG -> GG|G|G|GG
DESCRIPTION="--cut --cut_pattern pattern occurrences can overlap (GG|G|G|GG)"
printf ">s\nGGGGGG\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "GG^_GG" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (R -> A)"
printf ">s\nACATGA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_R" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (R -> G)"
printf ">s\nACATGG\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_R" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (R -> R)"
printf ">s\nACATGR\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_R" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (Y -> C)"
printf ">s\nACATGC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_Y" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (Y -> T)"
printf ">s\nACATGT\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_Y" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (Y -> Y)"
printf ">s\nACATGY\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_Y" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (N -> A)"
printf ">s\nACATGA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_N" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (N -> C)"
printf ">s\nACATGC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_N" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (N -> G)"
printf ">s\nACATGG\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_N" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (N -> T)"
printf ">s\nACATGT\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_N" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (N -> N)"
printf ">s\nACATGN\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_N" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (U -> T)"
printf ">s\nACATGT\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_U" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (U -> U)"
printf ">s\nACATGU\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_U" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (T -> U)"
printf ">s\nACATGU\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_T" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (M -> A)"
printf ">s\nACATGA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_M" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (M -> C)"
printf ">s\nACATGC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_M" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (M -> M)"
printf ">s\nACATGM\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_M" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (K -> G)"
printf ">s\nACATGG\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_K" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (K -> T)"
printf ">s\nACATGT\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_K" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern can match equivalent nucleotides (K -> K)"
printf ">s\nACATGK\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "ACATG^_K" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## assume matches for these other IUPAC symbols too:
# 
# Symbol   Description                     Bases represented   Complement
# ────────────────────────────────────────────────────────────────────────
# B        not A (B comes after A)         C or G or T         V
# D        not C (D comes after C)         A or G or T         H
# H        not H (H comes after G)         A or C or T         D
# S        strong                          C or G              S
# V        not T (V comes after T and U)   A or C or G         B
# W        weak                            A or T              W

## ---------------------------------------------------------------------- EcoRI

# 5'-G|AATT-C-3'
# 3'-C-TTAA|G-5'

DESCRIPTION="--cut --cut_pattern EcoRI (input contains one pattern)"
printf ">s\nGAATTC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern EcoRI (fastaout)"
printf ">s\nGAATTC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sG>sAATTC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern EcoRI (fastaout_rev)"
printf ">s\nGAATTC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout_rev - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sAATTC>sG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern EcoRI (empty fastaout_discarded)"
printf ">s\nGAATTC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout_discarded - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern EcoRI (fastaout_rev)"
printf ">s\nGAATTC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout_discarded_rev - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern (pattern not found, empty fastaout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern (pattern not found, empty fastaout_rev)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout_rev - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern (pattern not found, sequence goes to fastaout_discarded)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout_discarded - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern (pattern not found, sequence goes to fastaout_discarded_rev)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout_discarded_rev - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## two cuts: G^AATTCG^AATTC, three fragments
DESCRIPTION="--cut --cut_pattern (two pattern occurrences, three fragments)"
printf ">s\nGAATTCGAATTC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## two cuts: G^AATTCG^AATTCG^AATTC, four fragments
DESCRIPTION="--cut --cut_pattern (three pattern occurrences, four fragments)"
printf ">s\nGAATTCGAATTCGAATTC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "G^AATT_C" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- EcoRII

# 5'-|CCWGG -3'
# 3'- GGWCC|-5'

DESCRIPTION="--cut --cut_pattern EcoRII produces one fragment"
printf ">s\nCCWGG\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "^CCWGG_" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern EcoRII produces the expected fragment"
printf ">s\nCCWGG\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "^CCWGG_" \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sCCWGG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern EcoRII produces the expected fragments (reverse)"
printf ">s\nCCWGG\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "^CCWGG_" \
        --fastaout_rev - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sCCWGG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- EcoRV

# 5'-GAT|ATC-3'
# 3'-CTA|TAG-5'

DESCRIPTION="--cut --cut_pattern EcoRV produces two fragments"
printf ">s\nGATATC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "GAT^_ATC" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern EcoRV produces the expected fragments"
printf ">s\nGATATC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "GAT^_ATC" \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sGAT>sATC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern EcoRV produces the expected fragments (reverse)"
printf ">s\nGATATC\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "GAT^_ATC" \
        --fastaout_rev - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sATC>sGAT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------------- Fok1

# The DNA is cut 9 nucleotides downstream of the motif on the forward
# strand, and 13 nucleotides downstream of the motif on the reverse
# strand

# 5'-N_NNNNNNNNNNNNGGATGNNNNNNNN^N-3'

DESCRIPTION="--cut --cut_pattern Fok1 produces two fragments"
printf ">s\nNNNNNNNNNNNNNGGATGNNNNNNNNN\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "N_NNNNNNNNNNNNGGATGNNNNNNNN^N" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern Fok1 produces the expected fragments"
printf ">s\nNNNNNNNNNNNNNGGATGNNNNNNNNN\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "N_NNNNNNNNNNNNGGATGNNNNNNNN^N" \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sNNNNNNNNNNNNNGGATGNNNNNNNN>sN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern Fok1 produces the expected fragments (reverse)"
printf ">s\nNNNNNNNNNNNNNGGATGNNNNNNNNN\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "N_NNNNNNNNNNNNGGATGNNNNNNNN^N" \
        --fastaout_rev - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sN>sNNNNNNNNNCATCCNNNNNNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- HindIII

# 5'-A|AGCTT-3'
# 3'-TTCGA|A-5' 

DESCRIPTION="--cut --cut_pattern HindIII produces two fragments"
printf ">s\nAAGCTT\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "A^AGCT_T" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern HindIII produces the expected fragments"
printf ">s\nAAGCTT\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "A^AGCT_T" \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sA>sAGCTT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern HindIII produces the expected fragments (reverse)"
printf ">s\nAAGCTT\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "A^AGCT_T" \
        --fastaout_rev - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sAGCTT>sA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------------- NspI

# 5'-RCATG^Y-3'

# try different input values for R and Y: ACATGG

DESCRIPTION="--cut --cut_pattern NspI produces two fragments"
printf ">s\nRCATGY\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "RCATG^_Y" \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {s += 1} END {exit s == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern NspI produces the expected fragments"
printf ">s\nRCATGY\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "RCATG^_Y" \
        --fastaout - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sRCATG>sY" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --cut_pattern NspI produces the expected fragments (reverse)"
printf ">s\nRCATGY\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern "RCATG^_Y" \
        --fastaout_rev - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw ">sCATGY>sR" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

# none


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

# The valid options for the cut command are: --bzip2_decompress
# --cut_pattern --fasta_width --fastaout --fastaout_discarded
# --fastaout_discarded_rev --fastaout_rev --gzip_decompress
# --label_suffix --lengthout --log --no_progress --notrunclabels
# --quiet --relabel --relabel_keep --relabel_md5 --relabel_self
# --relabel_sha1 --sample --sizein --sizeout --xee --xlength --xsize

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--cut --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --bzip2_decompress \
        --quiet \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --bzip2_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --bzip2_decompress \
        --quiet \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fasta_width

DESCRIPTION="--cut --fasta_width is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --fasta_width 1 \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --fasta_width wraps fasta output"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --fasta_width 1 \
        --fastaout_discarded - | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--cut --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --gzip_decompress \
        --quiet \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --gzip_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --gzip_decompress \
        --quiet \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--cut --label_suffix is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --label_suffix "_suffix" \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --label_suffix adds the suffix 'string' to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --label_suffix "_suffix" \
        --fastaout_discarded - | \
    grep -wq ">s_suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --label_suffix adds the suffix 'string' (before annotations)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --label_suffix "_suffix" \
        --lengthout \
        --fastaout_discarded - | \
    grep -wq ">s_suffix;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--cut --lengthout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --lengthout \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --lengthout adds length annotations to output"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --lengthout \
        --fastaout_discarded - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--cut --log is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --log /dev/null \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --log writes to a file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --fastaout_discarded /dev/null \
        --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --log does not prevent messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --fastaout_discarded /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--cut --no_progress is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --no_progress \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--cut --no_progress removes progressive report on stderr (no visible effect)"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --no_progress \
        --fastaout_discarded /dev/null 2>&1 | \
    grep -iq "^cutting" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- notrunclabels

DESCRIPTION="--cut --notrunclabels is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --notrunclabels \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --notrunclabels preserves full headers"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --notrunclabels \
        --fastaout_discarded - | \
    grep -wq ">s extra" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--cut --quiet is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --quiet eliminates all (normal) messages to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --fastaout_discarded /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--cut --quiet allows error messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --quiet2 \
        --fastaout_discarded /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--cut --relabel is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel renames sequence (label + ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --fastaout_discarded - | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel renames sequence (empty label, only ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "" \
        --fastaout_discarded - | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel cannot combine with --relabel_md5"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --relabel_md5 \
        --fastaout_discarded /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--cut --relabel cannot combine with --relabel_sha1"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --relabel_sha1 \
        --fastaout_discarded /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--cut --relabel_keep is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_keep renames and keeps original sequence name"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --fastaout_discarded - | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--cut --relabel_md5 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_md5 \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_md5 relabels using MD5 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_md5 \
        --fastaout_discarded - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--cut --relabel_self is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_self \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_self relabels using sequence as label"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_self \
        --fastaout_discarded - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--cut --relabel_sha1 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_sha1 \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_sha1 relabels using SHA1 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_sha1 \
        --fastaout_discarded - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--cut --sample is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --sample "ABC" \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --sample adds sample name to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --sample "ABC" \
        --fastaout_discarded - | \
    grep -qw ">s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--cut --sizein is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --sizein \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --sizein is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --sizein \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --sizein (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --fastaout_discarded - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut size annotations are present in output (with --sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --sizein \
        --fastaout_discarded - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut size annotations are present in output (without --sizein)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --fastaout_discarded - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

# When using --relabel, --relabel_self, --relabel_md5 or --relabel_sha1,
# preserve and report abundance annotations to the output fasta file
# (using the pattern ';size=integer;').

DESCRIPTION="--cut --sizeout is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --sizeout \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --sizeout is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --sizeout \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --sizeout missing size annotations are not added (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --fastaout_discarded - | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut size annotations are present in output (with --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --sizeout \
        --fastaout_discarded - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut size annotations are present in output (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --fastaout_discarded - | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## add abundance annotations
DESCRIPTION="--cut --relabel no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --fastaout_discarded - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --sizeout \
        --fastaout_discarded - | \
    grep -qw ">label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_self no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_self \
        --fastaout_discarded - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_self --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_self \
        --sizeout \
        --fastaout_discarded - | \
    grep -qw ">A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_md5 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_md5 \
        --fastaout_discarded - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_md5 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --fastaout_discarded - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_sha1 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_sha1 \
        --fastaout_discarded - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_sha1 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --fastaout_discarded - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## preserve abundance annotations
DESCRIPTION="--cut --relabel no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --fastaout_discarded - | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel "label" \
        --sizeout \
        --fastaout_discarded - | \
    grep -qw ">label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_self no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_self \
        --fastaout_discarded - | \
    grep -qw ">A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_self --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_self \
        --sizeout \
        --fastaout_discarded - | \
    grep -qw ">A;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_md5 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_md5 \
        --fastaout_discarded - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_md5 --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --fastaout_discarded - | \
    grep -qw ">7fc56270e7a70fa81a5935b72eacbe29;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_sha1 no size annotations (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_sha1 \
        --fastaout_discarded - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --relabel_sha1 --sizeout preserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --fastaout_discarded - | \
    grep -qw ">6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--cut --xee is accepted"
printf ">s;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --xee \
        --quiet \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --xee removes expected error annotations from input"
printf ">s;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --xee \
        --quiet \
        --fastaout_discarded - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--cut --xlength is accepted"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --xlength \
        --quiet \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --xlength removes length annotations from input"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --xlength \
        --quiet \
        --fastaout_discarded - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--cut --xlength removes length annotations (input), lengthout adds them (output)"
printf ">s;length=2\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --xlength \
        --lengthout \
        --quiet \
        --fastaout_discarded - | \
    grep -wq ">s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

DESCRIPTION="--cut --xsize is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --xsize \
        --quiet \
        --fastaout_discarded /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--cut --xsize removes abundance annotations from input"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --xsize \
        --quiet \
        --fastaout_discarded - | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# does not work as expected!
# DESCRIPTION="--cut --xsize removes abundance annotations (input), sizeout adds them (output)"
        # printf ">s;size=2\nA\n" | \
#     "${VSEARCH}" \
#         --cut - \
#        --cut_pattern G^AATT_C \
#         --xsize \
#         --quiet \
#         --sizeout \
#         --fastaout_discarded - | \
#     grep -wq ">s;size=1" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--cut --threads is rejected"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --cut - \
        --cut_pattern G^AATT_C \
        --threads 1 \
        --quiet \
        --fastaout_discarded /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then
    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --cut <(printf ">s1\nGAATTC\n>s2\nA\n") \
        --cut_pattern G^AATT_C \
        --fastaout_discarded /dev/null \
        --fastaout_rev /dev/null \
        --fastaout_discarded /dev/null \
        --fastaout_discarded_rev /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--cut valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--cut valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#

# missing check! exactly one cutting site on each strand must be indicated


exit 0

# status: complete (v2.28.1, 2024-06-24)
