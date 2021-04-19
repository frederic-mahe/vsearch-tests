#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fastq_eestats all tests"
LINE=$(printf "%076s\n" | tr " " "-")
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
#                                  basic tests                                #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --alnout --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --acceptall accepts only one sequence"
printf '>seq1\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout is not accepted without id or acceptall"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                                    id tests                                 #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --alnout --id is not accepted without parameter"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is not accepted with wrong parameter"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id 'fail' &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is not accepted with value less than 0"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id \-5.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is not accepted with value more than 1"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --alnout - --id 2.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --alnout --id is not considered if used with acceptall"
OUTPUT=$(printf '>seq1\nAAAAA\n>seq2\nTTTTT\n' | \
                "${VSEARCH}" --allpairs_global - \
                             --alnout - --id 1.0 --acceptall 2>/dev/null | \
                awk '/cols,/ {print $5}')
[[ "${OUTPUT}" == "(0.0%)," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

#*****************************************************************************#
#                                                                             #
#                              accepted output                                #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --blast6out --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --blast6out - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --blast6out --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --blast6out - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# if fastapairs is not accepted, the man page should be updated
DESCRIPTION="--allpairs_global --fastapairs --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --fastapairs - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --fastapairs --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --fastapairs - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --matched --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --matched - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --matched --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --matched - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --notmatched --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --notmatched - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --notmatched --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --notmatched - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --samout --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --samout - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --samout --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --samout - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --uc --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --uc - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --uc --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --uc - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --userout --acceptall is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --userout - --acceptall &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--allpairs_global --userout --id is accepted"
printf '>seq1\nAAAAA\n>seq2\nAAAAA\n' | \
    "${VSEARCH}" --allpairs_global - \
                 --userout - --id 0.5 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                          expected output tests                              #    
#                                                                             #
#*****************************************************************************#
#alnout, blast6out, matched, notmatched, samout, uc, userout
# printf '>seq1\nAAATTA\n>seq2\nAAAAAA\n' | "${VSEARCH}" --allpairs_global - \
#                  --alnout - --id 0.6


DESCRIPTION="--allpairs_global --alnout --id gives the correct result #1"
OUTPUT=$(printf '>seq1\nAAATTA\n>seq2\nAAAAAA\n' | \
		"${VSEARCH}" --allpairs_global - \
			     --alnout - --id 0.6 2>/dev/null | \
		awk '/cols,/ {print $5}')
[[ "${OUTPUT}" == "(66.7%)," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--allpairs_global --alnout --id gives the correct result #2"
OUTPUT=$(printf '>seq1\nAAATTA\n>seq2\nAAAAAA\n' | \
		"${VSEARCH}" --allpairs_global - \
			     --alnout - --id 0.7 2>/dev/null | \
		awk '/cols,/ {print $5}')
[[ "${OUTPUT}" == "" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--allpairs_global --alnout --acceptall gives the correct result"
OUTPUT=$(printf '>seq1\nAAACCA\n>seq2\nTTTGGT\n' | \
		"${VSEARCH}" --allpairs_global - \
			     --alnout - --acceptall 2>/dev/null | \
		awk '/cols,/ {print $5}')
[[ "${OUTPUT}" == "(0.0%)," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"


#*****************************************************************************#
#                                                                             #
#                         blast6out: expected output                          #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct query"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
                      --blast6out - 2>/dev/null | \
                awk '{print $1}')
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct target"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
                      --blast6out - 2>/dev/null | \
                awk '{print $2}')
[[ "${OUTPUT}" == "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct similarity percentage"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $3}')
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct alnlen"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $4}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct mism"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $5}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct opens"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $6}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct qlo"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $7}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct qhi"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $8}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct tlo"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $9}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct thi"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $10}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct evalue"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $11}')
[[ "${OUTPUT}" == "-1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --blast6out finds the correct bits"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall \
		      --blast6out - 2>/dev/null | \
		awk '{print $12}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct query"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
                      --blast6out - 2>/dev/null | \
                awk '{print $1}')
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct target"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
                      --blast6out - 2>/dev/null | \
                awk '{print $2}')
[[ "${OUTPUT}" == "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct similarity percentage"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $3}')
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct alnlen"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $4}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct mism"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $5}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct opens"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $6}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct qlo"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $7}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct qhi"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $8}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct tlo"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $9}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct thi"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $10}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct evalue"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $11}')
[[ "${OUTPUT}" == "-1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --id 0.5 --blast6out finds the correct bits"
seq1="AAAA"
seq2="AAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --id 0.5 \
		      --blast6out - 2>/dev/null | \
		awk '{print $12}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0--blast6out finds the correct query"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
                      --blast6out - 2>/dev/null | \
                awk '{print $1}')
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct target"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
                      --blast6out - 2>/dev/null | \
                awk '{print $2}')
[[ "${OUTPUT}" == "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct similarity percentage"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $3}')
[[ "${OUTPUT}" == "75.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct alnlen"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $4}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct mism"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $5}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct opens"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $6}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct qlo"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $7}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct qhi"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $8}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct tlo"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $9}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct thi"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $10}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct evalue"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $11}')
[[ "${OUTPUT}" == "-1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2"

DESCRIPTION="--allpairs_global --acceptall --id 1.0 --blast6out finds the correct bits"
seq1="AAAA"
seq2="AAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n' \
		  ${seq1} ${seq2})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --id 1.0 \
		      --blast6out - 2>/dev/null | \
		awk '{print $12}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "database" "seq1" "seq2"


#*****************************************************************************#
#                                                                             #
#                       (not)matched: expected output                         #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --acceptall --matched shows every sequences"
seq1="AAAA"
seq2="AAAA"
seq3="AAAA"
seq4="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n>s4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 --qmask none \
		      --matched - 2>/dev/null | \
		awk '/>s/' | tr '\n' ' ')
[[ "${OUTPUT}" == ">s1 >s2 >s3 >s4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "database" "seq1" "seq2" "seq3" "seq4"

DESCRIPTION="--allpairs_global --acceptall --notmatched shows no sequence"
seq1="AAAA"
seq2="TTTT"
seq3="GGGG"
seq4="CCCC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n>s4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --notmatched - 2>/dev/null | \
		awk '/>s/' | tr '\n' ' ')
[[ "${OUTPUT}" == " " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "database" "seq1" "seq2" "seq3" "seq4"


#*****************************************************************************#
#                                                                             #
#                           samout: expected output                           #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --acceptall --samout is correct #1 "
seq1="TTTT"
seq2="AAAA"
seq3="AAAA"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --acceptall --threads 1 \
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
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
		      --samout - 2>/dev/null | \
		awk '{print $2}' | tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

#*****************************************************************************#
#                                                                             #
#                             uc: expected output                             #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--allpairs_global --uc --acceptall #1 is always H"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
"${VSEARCH}" \
    --allpairs_global <(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
			       ${seq1} ${seq2} ${seq3}) \
    --threads 1 \
    --acceptall \
    --quiet \
    --uc - | \
    grep -q "^[^H]" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
		awk '{print $1}' | egrep -v "^H" | tr '\n' ' ')
[[ -z "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --acceptall #2 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
		awk '{print $2}' | egrep -v "^\*" | \
		egrep -v "2|1" | tr '\n' ' ')
[[ "${OUTPUT}" == "" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --acceptall #3 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
		awk '{print $3}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "4 4 4 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --acceptall #4 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
		awk '{print $4}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "100.0 75.0 50.0 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --acceptall #5 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
	        awk '{print $5}' | egrep -v "^\." | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "+ + + " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --acceptall #6 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
	        awk '{print $6}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "0 0 0 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --acceptall #7 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
	        awk '{print $7}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "0 0 0 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --acceptall #8 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
	        awk '{print $8}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "2D2M2I 4M 4M " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --acceptall #9 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
	        awk '{print $9}' | egrep -v "s3" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --acceptall #10 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --acceptall 2>/dev/null | \
	        awk '{print $10}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "s3 s2 s3 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #1 is always H"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
		awk '{print $1}' | egrep -v "^H" | tr '\n' ' ')
[[ -z "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #2 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
		awk '{print $2}' | egrep -v "^\*" | \
		egrep -v "2|1" | tr '\n' ' ')
[[ "${OUTPUT}" == "" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #3 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
		awk '{print $3}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "4 4 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #4 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
		awk '{print $4}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "100.0 75.0 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #5 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
	        awk '{print $5}' | egrep -v "^\." | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "+ + " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #6 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
	        awk '{print $6}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "0 0 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #7 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
	        awk '{print $7}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "0 0 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #8 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
	        awk '{print $8}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "2D2M2I 4M " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #9 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
	        awk '{print $9}' | egrep -v "s3" |\
		tr '\n' ' ')
[[ "${OUTPUT}" == "s1 s1 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"

DESCRIPTION="--allpairs_global --uc --id 0.7 #10 is correct"
seq1="AAAA"
seq2="AAAT"
seq3="AACC"
database=$(printf '>s1\n%s\n>s2\n%s\n>s3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
OUTPUT=$("${VSEARCH}" --allpairs_global  <(printf "${database}") --uc - --threads 1 \
		      --id 0.7 2>/dev/null | \
	        awk '{print $10}' | egrep -v "^\*" | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "s3 s2 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "seq1" "seq2" "seq3" "database"


#*****************************************************************************#
#                                                                             #
#         check pairwise alignment correctness (Flouri et al., 2015)          #
#                                                                             #
#*****************************************************************************#

# http://biorxiv.org/content/early/2015/11/12/031500

# In USEARCH and VSEARCH the gap opening penalty includes the gap
# extension penalty of the first residue, while in other programs it
# does not. So if the gap open penalty is 40 and the gap extension
# penalty is 1, then a single nucleotide gap will get a penalty of 40
# in USEARCH and VSEARCH, and 41 in other programs.

# In Flouri's tests, the gap opening penalty does not include the gap
# extension penalty, and the optimal alignments contain two
# independent gaps. Therefore, USEARCH and VSEARCH should return score
# values equal to the scores indicated by Flouri, minus twice the gap
# extension penalty (e.g., a score of -72 reported by Flouri
# corresponds to a score of -70 with USEARCH and VSEARCH). The
# expected score values in the tests below take that into account.

# test 1 requires the possibility to set independent match/mismatch
# scores for the different pairs of nucleotides. Not possible to
# replicate in vsearch: ">seq1\nGGTGTGA\n>seq2\nTCGCGT\n"

# test 2 uses a match score of zero, not possible with vsearch (Fatal
# error: The argument to --match must be positive)
# ">seq1\nAAAGGG\n>seq2\nTTAAAAGGGGTT\n"

# test 3 (score should be -70 in USEARCH/VSEARCH)
DESCRIPTION="Flouri 2015 pairwise alignment correctness tests (test 3)"
score=$("${VSEARCH}" \
            --allpairs_global <(printf ">seq1\nAAATTTGC\n>seq2\nCGCCTTAC\n") \
            --acceptall \
            --gapopen 40 \
            --gapext 1\
            --match 10 \
            --mismatch -30 \
            --qmask none \
            --quiet \
            --userfields raw \
            --userout -)

(( ${score} == -70 )) && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# test 4 (score should be -60 in USEARCH/VSEARCH
DESCRIPTION="Flouri 2015 pairwise alignment correctness tests (test 4)"
score=$("${VSEARCH}" \
            --allpairs_global <(printf ">seq1\nTAAATTTGC\n>seq2\nTCGCCTTAC\n") \
            --acceptall \
            --gapopen 40 \
            --gapext 1\
            --match 10 \
            --mismatch -30 \
            --qmask none \
            --quiet \
            --userfields raw \
            --userout -)

(( ${score} == -60 )) && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# test 5 (identical to test 3)

# test 6 (score should be -44 in USEARCH/VSEARCH
DESCRIPTION="Flouri 2015 pairwise alignment correctness tests (test 6)"
score=$("${VSEARCH}" \
            --allpairs_global <(printf ">seq1\nAGAT\n>seq2\nCTCT\n") \
            --acceptall \
            --gapopen 25 \
            --gapext 1\
            --match 10 \
            --mismatch -30 \
            --qmask none \
            --quiet \
            --userfields raw \
            --userout -)

(( ${score} == -44 )) && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

exit 0
