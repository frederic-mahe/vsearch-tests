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

#hardly testable because of the memory
DESCRIPTION="--usearch_global --samout --samheader @SQ LN shouldn't be more than 2^31"
TMP=$(mktemp)
(printf ">s\n"
 for ((i=1 ; i<=((2**4)-1) ; i++)) ; do
     printf "A"
 done ) | bzip2 -c > $TMP
bzcat "${TMP}"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nA\n') \
    --db <(zcat "${TMP}") \
    --id 1.0 \
    --minseqlength 1 \
    --quiet \
    --samheader \
    --samout - | \
    awk '/^@SQ/ {exit $3 == "LN:0" ? 0 : 1}' && \
    failure "${DESCRIPTION}" || \
       success "${DESCRIPTION}"

exit
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


exit
DESCRIPTION="--allpairs_global --acceptall --samout is correct #1 "
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $1}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #2"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $2}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #3 "
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $3}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s2 s3 s3 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #4"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $4}' | tr '\n' ' ')
[[ "${OUTPUT}" == "1 1 1 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #5 "
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $5}' | tr '\n' ' ')
[[ "${OUTPUT}" == "255 255 255 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #6"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $6}' | tr '\n' ' ')
[[ "${OUTPUT}" == "4D4I 4D4I 4M " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #7 "
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $1}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #8"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $8}' | tr '\n' ' ')
[[ "${OUTPUT}" == "0 0 0 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #9 "
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $9}' | tr '\n' ' ')
[[ "${OUTPUT}" == "4 4 4 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #10"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $10}' | tr '\n' ' ')
[[ "${OUTPUT}" == "TTTT TTTT AAAA " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #11"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $11}' | tr '\n' ' ')
[[ "${OUTPUT}" == "* * * " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #12"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $12}' | tr '\n' ' ')
[[ "${OUTPUT}" == "AS:i:0 AS:i:100 AS:i:100 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #13 "
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $1}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #14"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $2}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #15 "
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $1}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #16"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $2}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #17 "
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $1}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #18"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $2}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --acceptall --samout is correct #19"
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --quiet \
		      --samout - | \
		awk '{print $2}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"


exit 0
