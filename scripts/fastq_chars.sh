#!/bin/bash -

## Print a header
SCRIPT_NAME="fastq_chars"
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
#                                --fastq_chars                                #
#                                                                             #
#*****************************************************************************#

## --fastq_chars is accepted
DESCRIPTION="--fastq_chars is accepted"
printf '@a_1\nACGT\n+\n!!aa\n' | \
    "${VSEARCH}" --fastq_chars - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_chars detects +33 quality score
DESCRIPTION="--fastq_chars detects +33 quality scores"
OUTPUT=$(printf '@a_1\nACGT\n+\n!!aa\n' | "${VSEARCH}" --fastq_chars - 2>&1 | \
		     sed "8q;d" | \
		     awk -F "[ ]" '{print $5}')
[[ "${OUTPUT}" == "(phred+33)" ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars detects +64 quality score
DESCRIPTION="--fastq_chars detects +64 quality scores"
OUTPUT=$(printf '@a_1\nACGT\n+\n@JJh\n' | "${VSEARCH}" --fastq_chars - 2>&1 | \
		     sed "8q;d" | \
		     awk -F "[ ]" '{print $5}')
[[ "${OUTPUT}" == "(phred+64)" ]] && \
    success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
unset OUTPUT

## /!\ this test is not correct as the warning could be raised by something else
## but there is no defined behaviour when the quality range is too large
##
## /!\ --fastq_chars raise a warning when quality score's range is too large
DESCRIPTION="/!\ --fastq_chars warning when quality score range's is too large"
printf '@a_1\nACGT\n+\n!JJh\n' | \
    "${VSEARCH}" --fastq_chars - 2>&1 | \
	grep -q "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_chars display correct number of sequences #1
DESCRIPTION="--fastq_chars display correct number of sequences #1"
OUTPUT=$(printf '@a_1\nACGT\n+\n@JJh\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1| \
	         awk 'NR == 5 {print $2}')
(( "${OUTPUT}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars display correct number of sequences #2
DESCRIPTION="--fastq_chars display correct number of sequences #2"
OUTPUT=$(printf '@a_1\nACGT\n+\n@JJh\n@b_1\nACGT\n+\n@JJh\n@c_1\nACGT\n+\n@JJh\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk 'NR == 5 {print $2}')
(( "${OUTPUT}" == 3 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars Qmin is correct
DESCRIPTION="--fastq_chars Qmin is correct"
OUTPUT=$(printf '@a_1\nACGT\n+\nOJJg\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk 'NR == 6 {print $2}')
[[ "${OUTPUT}" == "74," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars Qmax is correct
DESCRIPTION="--fastq_chars Qmax is correct"
OUTPUT=$(printf '@a_1\nACGT\n+\nOJJg\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk 'NR == 6 {print $4}')
[[ "${OUTPUT}" == "103," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars range is correct
DESCRIPTION="--fastq_chars range is correct"
OUTPUT=$(printf '@a_1\nACGT\n+\nOJJg\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk 'NR == 6 {print $6}')
(( "${OUTPUT}" == 30 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars format guess is correct for Solexa
DESCRIPTION="--fastq_chars format guess is correct for Solexa"
OUTPUT=$(printf '@a_1\nACGT\n+\n;CXH\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk 'NR == 8 {print $2}')
[[ "${OUTPUT}" == "Solexa" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars format guess is correct for Illumina 1.3+
DESCRIPTION="--fastq_chars format guess is correct for Illumina 1.3+"

OUTPUT=$(printf '@a_1\nACGT\n+\n@Kah\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1)
FORMAT=$(echo "${OUTPUT}" | awk 'NR == 8 {print $2}')
VERSION=$(echo "${OUTPUT}" |awk 'NR == 8 {print $3}')
if [[ "${FORMAT}" == "Illumina" ]] && [[ "${VERSION}" == "1.3+" ]]; then
    success "${DESCRIPTION}"
else
    failure "${DESCRIPTION}"
fi
unset FORMAT VERSION OUTPUT

## --fastq_chars format guess is correct for Illumina 1.5+
DESCRIPTION="--fastq_chars format guess is correct for Illumina 1.5+"
OUTPUT=$(printf '@a_1\nACGT\n+\nCT]h\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1)
FORMAT=$(echo "${OUTPUT}" | awk 'NR == 8 {print $2}')
VERSION=$(echo "${OUTPUT}" | awk 'NR == 8 {print $3}')
if [[ "${FORMAT}" == "Illumina" ]] && [[ "${VERSION}" == "1.5+" ]]; then
    success "${DESCRIPTION}"
else
    failure "${DESCRIPTION}"
fi
unset FORMAT VERSION OUTPUT

## --fastq_chars format guess is correct for Illumina 1.8+
DESCRIPTION="--fastq_chars format guess is correct for Illumina 1.8+"
OUTPUT=$(printf '@a_1\nACGT\n+\n!+;i\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1)
FORMAT=$(echo "${OUTPUT}" | awk -F "[ ]" 'NR == 8 {print $2}')
VERSION=$(echo "${OUTPUT}" | awk -F "[ ]" 'NR == 8 {print $3}')
if [[ "${FORMAT}" == "Illumina" ]] && [[ "${VERSION}" == "1.8+" ]]; then
    success "${DESCRIPTION}"
else
    failure "${DESCRIPTION}"
fi
unset FORMAT VERSION OUTPUT

## --fastq_chars number of nucleotides is correct #1
DESCRIPTION="--fastq_chars number of nucleotides is correct #1"
OUTPUT=$(printf '@a_1\nACCC\n+\naacc\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 12 {print $16}')
(( "${OUTPUT}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars number of nucleotides is correct #2
DESCRIPTION="--fastq_chars number of nucleotides is correct #2"
OUTPUT=$(printf '@a_1\nACAA\n+\naacc\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 12 {print $16}')
(( "${OUTPUT}" == 3 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars percentage of nucleotides is correct
DESCRIPTION="--fastq_chars percentage of nucleotides is correct"
OUTPUT=$(printf '@a_1\nCTAT\n+\n;CXH\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 12 {print $18}')
[[ "${OUTPUT}" == '25.0%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars percentage of nucleotides is rounded to 1 digit of precison #1
DESCRIPTION="--fastq_chars percentage of nucleotides is rounded to 1 digit of precison #1"
OUTPUT=$(printf '@a_1\nCCACCT\n+\n;CCCXH\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 13 {print $18}')
[[ "${OUTPUT}" == '66.7%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars percentage of nucleotides is rounded to 1 digit of precison #2
DESCRIPTION="--fastq_chars percentage of nucleotides is rounded to 1 digit of precison #2"
OUTPUT=$(printf '@a_1\nCCACCTT\n+\n;CCCXXH\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 13 {print $18}'  )
[[ "${OUTPUT}" == '57.1%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars MaxRun is correct #1
DESCRIPTION="--fastq_chars MaxRun is correct #1"
OUTPUT=$(printf '@a_1\nAACT\n+\naacc\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 12 {print $24}')
(( "${OUTPUT}" ==  1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars MaxRun is correct #2
DESCRIPTION="--fastq_chars MaxRun is correct #2"
OUTPUT=$(printf '@a_1\nAAAACA\n+\naaaccc\n' - | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 12 {print $24}')
(( "${OUTPUT}" ==  3 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars percentage of score letters is correct
DESCRIPTION="--fastq_chars percentage of score letters is correct"
OUTPUT=$(printf '@a_1\nCTAT\n+\n;CXH\n' - | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 19 {print $10}')
[[ "${OUTPUT}" == '25.0%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars percentage of score letters is rounded to 1 digit of precison #1
DESCRIPTION="--fastq_chars percentage of score letters is rounded to 1 digit of precison #1"
OUTPUT=$(printf '@a_1\nCCACCT\n+\n;CCCXC\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 19 {print $10}')
[[ "${OUTPUT}" == '66.7%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars percentage of nucleotides is rounded to 1 digit of precison #2
DESCRIPTION="--fastq_chars percentage of nucleotides is rounded to 1 digit of precison #2"
OUTPUT=$(printf '@a_1\nCCACCTT\n+\n;CCCCXH\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 19 {print $10}')
[[ "${OUTPUT}" == '57.1%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars number of tails is correct with default settings #1
DESCRIPTION="--fastq_chars number of tails is correct with default settings #1"
OUTPUT=$(printf '@a_1\nAAAAA\n+\nHHHHH\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk 'NR == 16 {print $NF}')
(( "${OUTPUT}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars number of tails is correct with default settings #2
DESCRIPTION="--fastq_chars number of tails is correct with default settings #2"
OUTPUT=$(printf '@a_1\nAAAAA\n+\nHHHHH\n@b_1\nAAAAA\n+\nHHHGG\n@c_1\nAAAAA\n+\nHHHHH\n' | \
	            "${VSEARCH}" --fastq_chars - 2>&1 | \
	         awk -F "[ ]" 'NR == 17 {print $21}')
(( "${OUTPUT}" == 2 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

## --fastq_chars number of tails is correct with --fastq_tail 2
DESCRIPTION="--fastq_chars number of tails is correct with --fastq_tail 2"
OUTPUT=$(printf '@a_1\nAAAA\n+\nHHCC\n@b_1\nAAAA\n+\nHHCC\n@a_1\nAAAA\n+\nHHHC\n' | \
                "${VSEARCH}" --fastq_chars - --fastq_tail 2 2>&1 | \
	         awk -F "[ ]" 'NR == 16 {print $21}')
(( "${OUTPUT}" == 2 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT

exit 0
