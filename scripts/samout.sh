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
ref=$(printf "AGCATGTTAGATAAGATAGCTGTGCTAGTAGGCAGTCAGCGCCAT")
r001=$(printf "TTAGATAAAGGATACTG")
r002=$(printf "aaaAGATAAGGATA")
r003=$(printf "gcctaAGCTAA")
r004=$(printf "ATAGCTTCAGC")
database=$(printf ">ref\n%s\n" $ref)
query=$(printf ">ref\n%s\n>r001\n%s\n>r002\n%s\n>r003\n%s\n>r004\n%s\n" $ref $r001 $r002 $r003 $r004)
"${VSEARCH}" \
    --usearch_global <(printf "%s" "$query") \
    --db <(printf "$database") \
    --id 0.1 \
    --minseqlength 1 \
    --quiet \
    --output_no_hits \
    --strand both \
    --samheader \
    --samout - &>/dev/null

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
"${VSEARCH}" \
    --usearch_global <(printf '>s1\nA\n') \
    --db <(printf '>s1\nA\n>s2\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
     grep -Pq --color=auto \
    "^[!-?A-~]{1,254}\t[0-9]{0,5}\t(\*|[!-()+-<>-~][!-~]*)\t[0-9]{0,10}\t[0-9]{0,3}\t(\*|([0-9]+[MIDNSHPX=])+)\t(\*|=|[!-()-+-<>-~][!-~]*)\t[0-9]{0,10}\t-?[0-9]{0,10}\t(\*|[A-Za-z=.]+)\t[!-~]+"
    
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

DESCRIPTION="--usearch_global --samout is correct (field #6)"
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
DESCRIPTION="--usearch_global --samout is correct when no hits (field #6)"
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
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nAAGGGGGGGGGCCC\n') \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --id 0.1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    grep -Po "([0-9]+[MIS])+" | \
    grep -Po "[0-9]+" | \
    awk '{SUM += $1} END {exit SUM == 14 ? 0 : 1} '  && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

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

DESCRIPTION="--usearch_global --samout TLEN is correct (field #9)"
"${VSEARCH}" \
    --usearch_global  <(printf '>q1\nGGGG\n') \
    --db <(printf '>r1\nCGGG\n>r2\nTTTT\n') \
    --id 0.5 \
    --threads 1 \
    --quiet \
    --minseqlength 1 \
    --samout - | \
    awk '{exit $9 == 0 ? 0: 1}' && \
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


