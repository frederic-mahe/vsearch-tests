#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="samout"
LINE=$(printf -- "-%.0s" {1..76})
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}
## Is vsearch installed?
VSEARCH=$(which vsearch)
DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] && success "${DESCRIPTION}" || failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                        accepted output options                              #
#                                                                             #
#*****************************************************************************#



DESCRIPTION="--usearch_global --samout is accepted"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --samout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                basic tests                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --samout output is not empty"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - | \
    grep -qE ".?" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout fields are tab-separated"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - | \
    grep -q $'\t' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                        header section (samheader)                           #
#                                                                             #
#*****************************************************************************#


DESCRIPTION="--usearch_global --samout --samheader displays @HD"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -q "@HD" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="--usearch_global --samout --samheader @HD is the first header line"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samheader \
    --samout - | \
    awk "{exit NR == 1 && /^@HD/ ? 0 : 1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# use the regex definition of the header lines (avoid alignment lines
# by using very dissimilar sequences)
DESCRIPTION="--usearch_global --samout --samheader is well formated"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nC\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -vqP '^@[A-Z][A-Z](\t[A-Za-z][A-Za-z0-9]:[ -~]+)+|^@CO\t.*$' && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @HD VN is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samheader \
    --samout - | \
    grep -qP "^@HD.*VN:[0-9]+\.[0-9]+"  && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @HD SO is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -Eq "^@HD.*SO:(queryname|unsorted|unknown|coordinate)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @HD GO is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --samheader \
    --quiet \
    --samout - | \
    grep -qE "^@HD.*GO:(query|none|reference)"  && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader displays @SQ"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -q "^@SQ" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @SQ contains SN and LN"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -Eq "^@SQ.*(SN:.*LN:)|(LN:.*SN:)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @SQ SN is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -qP "^@SQ.*SN:[!-)+-<>-~][!-~]*" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# test with 2 references
DESCRIPTION="--usearch_global --samout --samheader @SQ displays as many lines as references"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n>seq2\nA\n') \
    --id 0.1 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader  | \
    awk '/^@SQ/ {i++} END {exit i == 2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @SQ LN is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nAAA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samheader \
    --samout - | \
    awk '/^@SQ/ {exit $3 == "LN:3" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @SQ LN is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nAAA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samheader \
    --samout - | \
    awk '/^@SQ/ {exit $3 == "LN:3" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

#sequences not matching to only get the header
DESCRIPTION="--usearch_global --samout --samheader fails if starting with *"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nCCC\n') \
    --db <(printf '>*seq1\nAAA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samheader \
    --samout - | \
    grep -vq "^*" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"    

DESCRIPTION="--usearch_global --samout --samheader fails if starting with ="
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nCCC\n') \
    --db <(printf '>=seq1\nAAA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samheader \
    --samout - | \
    grep -vq "^=" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"    

DESCRIPTION="--usearch_global --samout --samheader @SQ LN shouldn't be zero"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\n\n') \
    --id 1.0 \
    --minseqlength 0 \
    --quiet \
    --samheader \
    --samout - | \
    awk '/^@SQ/ {exit $3 == "LN:0" ? 0 : 1}' && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# substitution process always gives 'fd/62' as 2nd input file"
DESCRIPTION="--usearch_global --samout --samheader @SQ UR is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 0 \
    --quiet \
    --samheader \
    --samout - | \
    awk '/^@SQ/ {exit $4 == "UR:file:/dev/fd/62" ? 0 : 1}' && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## hardly testable because of the memory and processing time
# DESCRIPTION="--usearch_global --samout --samheader @SQ LN shouldn't be more than 2^31"
# TMP=$(mktemp)
# (printf ">s\n"
#  for ((i=1 ; i<=((2**31)) ; i++)) ; do
#      printf "A"
#  done
#  printf "\n") | bzip2 -c > $TMP
# "${VSEARCH}" \
#     --usearch_global <(printf '>seq1\nA\n') \
#     --db <(bzcat "${TMP}") \
#     --id 1.0 \
#     --minseqlength 1 \
#     --maxseqlength $((2**31)) \
#     --quiet \
#     --samheader \
#     --samout - | \
#     awk '/^@SQ/ {exit $3 == "LN:2147483648" ? 0 : 1}' && \
#     failure "${DESCRIPTION}" || \
#        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @SQ M5 is correct"
SEQ="AAA"
MD5=$(printf "%s" ${SEQ} | md5sum | awk '{print $1}')
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\n%s\n' ${SEQ}) \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samheader \
    --samout - | \
    awk -v M5="${MD5}" '/^@SQ/ {exit $4 == "M5:"M5 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader displays @PG"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -q "@PG" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @PG contains ID"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -q "^@PG.*ID:" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @PG ID is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -q "^@PG.*ID:" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout --samheader @PG VN is correct"
VERSION=$(vsearch -v 2>&1 | grep -Eo "[0-9]+.[0-9]+.[0-9]+")
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -Eq "^@PG.*[[:blank:]]VN:${VERSION}"  && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# No need to test CL (command line)

DESCRIPTION="--usearch_global --samout --samheader doesn't displays @RG"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --samheader | \
    grep -q "@RG" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"



#*****************************************************************************#
#                                                                             #
#                      alignment section: mandatory fields                    #
#                                                                             #
#*****************************************************************************#

"${VSEARCH}" \
    --usearch_global <(printf '>S1\nATGAGGCTCCTACCGTA\n') \
    --db <(printf '>R1\nTACGGTAGGAGCCTCAT\n') \
    --id 0.1 \
    --minseqlength 1 \
    --quiet \
    --samout - \
    --dbnotmatched -
    exit

DESCRIPTION="--usearch_global --samout alignments have at least 11 fields"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - | \
    awk -F '\t' '!/^@/ && (NF < 11) {exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="--usearch_global --samout Qname is well-shaped (field #1)" 
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {print $1}' | \
    grep -qP "^[!-?A-~]{1,254}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout Flag is well-shaped (field #2)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {exit $2>=0 && $2 < 2**16 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout Rname is well-shaped (field #3)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {print $3}' | \
    grep -qP "^\*|^[!-()+-<>-~][!-~]*" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout Pos is well-shaped (field #4)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {exit $4>=0 && $4 < 2**31 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout Mapq is well-shaped (field #5)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {exit $5>=0 && $5 < 2**8 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout CIGAR is well-shaped (field #6)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {print $6}' | \
    grep -qP "^\*|([0-9]+[MIDNSHPX=])+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout RNEXT is well-shaped (field #7)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n>s2\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {print $7}' | \
    grep -qP "^\*|=|[!-()-+-<>-r][!-~]*" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout PNEXT is well-shaped (field #8)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n>s2\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {exit $8>=0 && $8 < 2**31 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout TLEN is well-shaped (field #9)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n>s2\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {exit $9 > -(2**31) && $9 < 2**31 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout SEQ is well-shaped (field #10)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n>s2\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {print $10}' | \
    grep -qP "^\*|[A-Za-z=.]+" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout QUAL is well-shaped (field #11)"
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n>s2\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {print $10}' | \
    grep -qP "[!-~]+" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"




DESCRIPTION="--usearch_global --samout All"
# Sortie
^[!-?A-~]{1,254} [0-9]{1,5} ^\*|^[!-()+-<>-~][!-~]*
# /Sortie
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n>s2\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {print $10}' | \
    grep -qP "[!-~]+" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout Qname is correct (field #1)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.1 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    grep -q "^q1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #2)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.1 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $2}' | \
    grep -q "^0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #3)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $3}' | \
    grep -q "^r1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #4(non certain))"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $4}' | \
    grep -q "^2$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #5)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $5}' | \
    grep -q "^255$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #6(non certain))"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $6}' | \
    grep -q "^4m$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #7)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $7}' | \
    grep -q "^*$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #8)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $8}' | \
    grep -q "^0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #9)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $9}' | \
    grep -q "^0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #10)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $10}' | \
    grep -q "^GGGG$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #11)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{print $11}' | \
    grep -q "^*$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


