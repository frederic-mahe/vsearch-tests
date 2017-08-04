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

# The @HD line should be present, with either the SO tag or the GO tag
# (but not both) specified.
DESCRIPTION="--usearch_global --samout --samheader @HD GO and SO are not both displayed (not recommended)"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(printf '>seq1\nA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --samheader \
    --quiet \
    --samout - | \
    grep -Eq "^@HD.*(GO:.*SO:|SO:.*GO:)" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}" 

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
MD5=$(printf "AAA" | md5sum | awk '{print $1}')
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
unset "MD5"

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
unset "VERSION"

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

# If @SQ header lines are present,
# RNAME (if not ‘*’) must be present in one of the SQ-SN tag
DESCRIPTION="--usearch_global --samout --samheader @HQ SN is equal to RNAME "
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAA\n') \
    --db <(printf '>r1\nAAA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samheader \
    --samout - | \
    awk	'/^@SQ/ {VAR = $2}
         !/^@/ {VAR2 = "SN:"$3}
         END {exit VAR == VAR2 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                      alignment section: mandatory fields                    #
#                                                                             #
#*****************************************************************************#

# example from official sam specs
# no match with vsearch, yet it should !
ref="AGCATGTTAGATAAGATAGCTGTGCTAGTAGGCAGTCAGCGCCAT"
r001="TTAGATAAAGGATACTG"
"${VSEARCH}" \
    --usearch_global <(printf ">r001\n%s\n" "$r001") \
    --db <(printf ">ref\n%s\n" "$ref") \
    --id 0.0 \
    --acceptall \
    --minseqlength 1 \
    --quiet \
    --samout - | \
    awk '{exit $6 == "8M2I4M1D3M" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "ref" "r001"

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

DESCRIPTION="--usearch_global --samout Adjacent CIGAR operations should be different (not recommended)(field #6)"
SEQ="AAGGGGGGGGGCCC"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\n%s\n' ${SEQ}) \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk 'BEGIN {FS = "\t"} {print $6}' | \
    tr '[0-9]' '\n' | \
    uniq -d | \
    awk '{exit NR == 0 ? 0 :1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "SEQ"

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
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n>s2\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
     grep -Pq \
    "^[!-?A-~]{1,254}\t[0-9]{0,5}\t(\*|[!-()+-<>-~][!-~]*)\t[0-9]{0,10}\t[0-9]{0,3}\t(\*|([0-9]+[MIDNSHPX=])+)\t(\*|=|[!-()-+-<>-~][!-~]*)\t[0-9]{0,10}\t-?[0-9]{0,10}\t(\*|[A-Za-z=.]+)\t[!-~]+"
    
DESCRIPTION="--usearch_global --samout Qname is correct (field #1)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    grep -q "^q1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout FLAG is correct (field #2 default)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.1 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
   awk -F "\t" '{exit $2 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout FLAG is correct (field #2 rev-comp)"
"${VSEARCH}" \
    --usearch_global <(printf '>S1\nCCCC\n') \
    --db <(printf '>R1\nGGGG\n') \
    --id 0.1 \
    --minseqlength 1 \
    --strand both \
    --quiet \
    --samout - | \
    awk -F "\t" '{exit $2 == 16 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout FLAG is correct (field #2 unmapped)"
"${VSEARCH}" \
    --usearch_global <(printf '>S1\nCCCC\n') \
    --db <(printf '>R1\nGGGG\n') \
    --output_no_hits \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samout - | \
    awk -F "\t" '{exit $2 == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout FLAG is correct (field #2 secondary align)"
"${VSEARCH}" \
    --usearch_global <(printf '>S1\nGGGG\n') \
    --db <(printf '>R1\nGGGG\n>R2\nCGGG\n') \
    --id 0.5 \
    --maxaccepts 2 \
    --minseqlength 1 \
    --quiet \
    --samout - | \
    awk -F "\t" 'NR == 2 {exit $2 == 256 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# secondary align is the less-matching sequence"
DESCRIPTION="--usearch_global --samout RNAME is correct for secondary align"
"${VSEARCH}" \
    --usearch_global <(printf '>S1\nGGGG\n') \
    --db <(printf '>R1\nGGGG\n>R2\nCGGG\n') \
    --id 0.5 \
    --maxaccepts 2 \
    --minseqlength 1 \
    --quiet \
    --samout - | \
    awk -F "\t" 'NR == 2 {exit $3 == "R2" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout QNAME is correct (field #3)"
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

# An unmapped segment without coordinate has a ‘*’ at this field
DESCRIPTION="--usearch_global --samout QNAME is correct when no_hits (field #3)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nTTTT\n') \
    --id 0.5 \
    --output_no_hits \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{exit $3 == "*" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# result should be 4: 1-based leftmost mapping POSition of the first
# CIGAR operation that 'consumes' a reference base. The first base in
# a reference sequence has coordinate 1.
DESCRIPTION="--usearch_global --samout POS is correct (field #4)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCCCGGGG\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{exit $4 == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# POS is set as 0 for an unmapped read without coordinate
DESCRIPTION="--usearch_global --samout POS is correct when no match (field #4)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCCCC\n') \
    --id 0.1 \
    --output_no_hits \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{exit $4 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# A value 255 indicates that the mapping quality is not available.
DESCRIPTION="--usearch_global --samout is correct (field #5)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{exit $5 == 255 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout CIGAR is correct (field #6)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGGG\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{exit $6 == "1D4M" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# set ‘*’ if unavailable
DESCRIPTION="--usearch_global --samout CIGAR is correct when no hits (field #6)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nAAAA\n') \
    --id 0.5 \
    --output_no_hits \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{exit $6 == "*" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout RNEXT is correct (field #7)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk -F "\t" '{print $7}' | \
    grep -q "^*$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Sum of lengths of the M/I/S/=/X operations shall equal the length of SEQ
DESCRIPTION="--usearch_global --samout CIGAR is correct (field #6 #2)"
SEQ="AAGGGGGGGGGCCC"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\n%s\n' ${SEQ}) \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk -F "\t" '{print $6}' | \
    grep -Po "([0-9]+[MIS])+" | \
    grep -Po "[0-9]+" | \
    awk -v LENSEQ="${#SEQ}" '{SUM += $1} END {exit SUM == LENSEQ ? 0 : 1} ' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
 UNSET "SEQ"

DESCRIPTION="--usearch_global --samout PNEXT is correct (field #8)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{exit $8 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# It is set as 0 for single-segment template or when the information
# is unavailable.
DESCRIPTION="--usearch_global --samout TLEN is correct (field #9)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk -F "\t" '{exit $9 == 0 ? 0: 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# field #10 (SEQ) contains the query sequence
DESCRIPTION="--usearch_global --samout SEQ is correct (field #10)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk -F "\t" '{exit $10 == "GGGG" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# This field can be a ‘*’ when the sequence is not stored
DESCRIPTION="--usearch_global --samout SEQ is correct when empty(field #10)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\n\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --output_no_hits \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk -F "\t" '{exit $10 == "*" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# An '=' denotes the base is identical to the reference base
DESCRIPTION="--usearch_global --samout SEQ is correct when equal (field #10)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nT\n') \
    --db <(printf '>r1\nT\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk -F "\t" '{exit $10 == "=" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is correct (field #11)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk -F "\t" '{exit $11 == "*" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout optional fields is present"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk -F "\t" '{exit $12 != "" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout optional fields are tab-separated"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk -F "\t" '{exit NF >= 12 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# All optional fields follow the TAG:TYPE:VALUE
DESCRIPTION="--usearch_global --samout optional fields are well-formated"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n'  | \
    awk -F ":" '{if (NF != 3) {exit 1}}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# TAG is a two-character string that matches /[A-Za-z][A-Za-z0-9]/
DESCRIPTION="--usearch_global --samout optional fields TAG is well-formated"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n'  | \
    awk -F ":" '{if ($1 == /[A-Za-z][A-Za-z0-9]/) {exit 1}}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Each TAG can only appear once in one alignment line.
DESCRIPTION="--usearch_global --samout optional fields TAG is unique"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n'  | \
    cut -d ":" -f 1 | \
    sort | \
    uniq -d | \
    grep -q "*" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# The NM tag should be present
DESCRIPTION="--usearch_global --samout optional fields have a NM field (recommended)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    grep -qP "\tNM:i:" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout optional fields TYPE can only be A,i,f,Z,H,B"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n' | \
    grep -qv "^.*:[AifZHB]:.*$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# no optional field with A for now
DESCRIPTION="--usearch_global --samout optional fields type A is well formated"
OUTPUT=$("${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n' | \
    grep "^[A-Za-z][A-Za-z0-9]:A:")
if [[ -n "${OUTPUT}" ]] ; then
    grep -vEq ":[!-~]$" <<< "${OUTPUT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
fi
UNSET "OUTPUT"

# when TYPE is i, value should be a signed integer
DESCRIPTION="--usearch_global --samout optional fields TYPE i is well formated"
OUTPUT=$("${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n'  | \
    grep "^[A-Za-z][A-Za-z0-9]:i:")
if [[ -n "${OUTPUT}" ]] ; then
    grep -vEq ":[-+]?[0-9]+$" <<< "${OUTPUT}" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}" 
fi
unset "OUTPUT"

# no optional field with f for now
DESCRIPTION="--usearch_global --samout optional fields TYPE f is well formated"
OUTPUT=$("${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n'  | \
    grep "^[A-Za-z][A-Za-z0-9]:f:")
if [[ -n "${OUTPUT}" ]] ; then
    grep -vEq ":[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$" <<< "${OUTPUT}" && \
	success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
fi
unset "OUTPUT"

# when TYPE is Z, VALUE should be a string
DESCRIPTION="--usearch_global --samout optional fields TYPE Z is well formated"
OUTPUT=$("${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n'  | \
    grep "^[A-Za-z][A-Za-z0-9]:Z:")
if [[ -n "${OUTPUT}" ]] ; then
    grep -vEq ":[ !-~]*$" <<< "${OUTPUT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
fi
UNSET "OUTPUT"

# no optional field with H for now
DESCRIPTION="--usearch_global --samout optional fields TYPE H is well formated"
OUTPUT=$("${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n'  | \
    grep "^[A-Za-z][A-Za-z0-9]:H:")
if [[ -n "${OUTPUT}" ]] ; then
    grep -vEq ":([0-9A-F][0-9A-F])*$" <<< "${OUTPUT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
fi
 UNSET "OUTPUT"

# no optional field with B for now
DESCRIPTION="--usearch_global --samout optional fields TYPE B is well formated"
OUTPUT=$("${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n'  | \
    grep "^[A-Za-z][A-Za-z0-9]:B:")
if [[ -n "${OUTPUT}" ]] ; then
    grep -vEq ":[cCsSiIf](,[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+$" <<< "${OUTPUT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
fi
UNSET "OUTPUT"

# AS is the percentage similarity
DESCRIPTION="--usearch_global --samout AS is correct (field #12-1)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n' | \
    awk -F ":" '/^AS/ {exit $3 == 75 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# XN is the next best alignement score (always set to 0 in vsearch)
DESCRIPTION="--usearch_global --samout XN is correct (field #12-2)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout -  | \
     cut -f 12-  | \
     tr '\t' '\n' | \
     awk -F ":" '/^XN/ {exit $3 == 0 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# XM is the number of mismatch
DESCRIPTION="--usearch_global --samout XM is correct (field #12-3)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout -  | \
     cut -f 12-  | \
     tr '\t' '\n' | \
     awk -F ":" '/^XM/ {exit $3 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# X0 is the number of gap opens
DESCRIPTION="--usearch_global --samout X0 is correct (field #12-4)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGGGGGGGGGG\n') \
    --db <(printf '>r1\nGGGGGCCCCGGGGGGG\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
     cut -f 12-  | \
     tr '\t' '\n' | \
     awk -F ":" '/^X0/ {exit $3 == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# XG is the number of gap opens
DESCRIPTION="--usearch_global --samout XG is correct (field #12-5)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGGGGGGGGGG\n') \
    --db <(printf '>r1\nGGGGGCCCCGGGGGGG\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
     cut -f 12-  | \
     tr '\t' '\n' | \
     awk -F ":" '/^X0/ {exit $3 == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# NM is the edit distance (sum of XM and XG)
DESCRIPTION="--usearch_global --samout NM is correct (field #12-6)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGGGGGGGGGG\n') \
    --db <(printf '>r1\nGGGGGCCCCGGGGGGG\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
     cut -f 12-  | \
     tr '\t' '\n' | \
     awk -F ":" '/^NM/ {exit $3 == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# MD is a variant string (CIGAR complement)
DESCRIPTION="--usearch_global --samout MD is correct (field #12-7)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGGGGGGGGGG\n') \
    --db <(printf '>r1\nGGGGGCCCCGGGGGGG\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
     cut -f 12-  | \
     tr '\t' '\n' | \
     awk -F ":" '/^MD/ {exit $3 == "5^CCCC7" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# YT is the alignment type
DESCRIPTION="--usearch_global --samout YT is correct (field #12-8)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGGGGGGGGGG\n') \
    --db <(printf '>r1\nGGGGGCCCCGGGGGGG\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
     cut -f 12-  | \
     tr '\t' '\n' | \
     awk -F ":" '/^YT/ {exit $3 == "UU" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# If you wish to store free text in a CT tag, use the key value Note
# (uppercase N) to match GFF3.
DESCRIPTION="--usearch_global --samout optional fields CT is well formated"
OUTPUT=$("${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n') \
    --id 0.5 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    cut -f 12- | \
    tr '\t' '\n' | \
    grep "^CT:Z:.*$")
if [[ -n "${OUTPUT}" ]] ; then
    grep -q "Note=" <<< "${OUTPUT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
fi

exit 0
