#!/bin/bash -

## Print a header
SCRIPT_NAME="Test options"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    # exit -1
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
#                                --fastq_chars                                #
#                                                                             #
#*****************************************************************************#

## --fastq_chars is accepted
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\n!!aa\n' > "${INPUT}"
DESCRIPTION="--fastq_chars is accepted"
"${VSEARCH}" --fastq_chars "${INPUT}" &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fastq_chars detects +33 quality score
OFF33=$(mktemp)
printf '@a_1\nACGT\n+\n!!aa\n' > "${OFF33}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars detects +33 quality scores"
"${VSEARCH}" --fastq_chars "${OFF33}" 2> "${OUTPUT}"
OFFSET=$(sed "8q;d" "${OUTPUT}" | \
		awk -F "[ ]" '{print $5}')
[[ "${OFFSET}" == "(phred+33)" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${OFF33}"



## --fastq_chars detects +64 quality score
OFF64=$(mktemp)
printf '@a_1\nACGT\n+\n@JJh\n' > "${OFF64}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars detects +64 quality scores"
"${VSEARCH}" --fastq_chars "${OFF64}" 2> "${OUTPUT}"
OFFSET=$(sed "8q;d" "${OUTPUT}" | \
		awk -F "[ ]" '{print $5}')
[[ "${OFFSET}" == "(phred+64)" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${OFF64}"

## /!\ this test is not correct as the warning could be raised by something else
## but there is no defined behaviour when the quality range is too large
##
## /!\ --fastq_chars raise a warning when quality score's range is too large
OUTPUT=$(mktemp)
OFF_TOO_LARGE=$(mktemp)
printf '@a_1\nACGT\n+\n!JJh\n' > "${OFF_TOO_LARGE}"
DESCRIPTION="/!\ --fastq_chars raise a warning when quality score range's is too large"
"${VSEARCH}" --fastq_chars "${OFF_TOO_LARGE}" 2> "${OUTPUT}"
IS_WARNING=$(grep -q "warning" "${OUTPUT}")
[[ "${IS_WARNING}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

## --fastq_chars diplay correct number of sequences #1
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\n@JJh\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars diplay correct number of sequences #1"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
NB_SEQUENCES=$(sed "5q;d" "${OUTPUT}" | \
		awk -F "[ ]" '{print $2}')
[[ "${NB_SEQUENCES}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars diplay correct number of sequences #2
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\n@JJh\n@b_1\nACGT\n+\n@JJh\n@c_1\nACGT\n+\n@JJh\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars diplay correct number of sequences #2"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
NB_SEQUENCES=$(sed "5q;d" "${OUTPUT}" | \
		awk -F "[ ]" '{print $2}')
[[ "${NB_SEQUENCES}" == "3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars diplay correct number of sequences #2
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\n@JJh\n@b_1\nACGT\n+\n@JJh\n@c_1\nACGT\n+\n@JJh\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars diplay correct number of sequences #2"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
NB_SEQUENCES=$(sed "5q;d" "${OUTPUT}" | \
		awk -F "[ ]" '{print $2}')
[[ "${NB_SEQUENCES}" == "3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars Qmin is correct
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\nOJJg\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars Qmin is correct"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
QMIN=$(sed "6q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $2}')
[[ "${QMIN}" == "74," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars Qmax is correct
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\nOJJg\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars Qmax is correct"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
QMAX=$(sed "6q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $4}')
[[ "${QMAX}" == "103," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars range is correct
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\nOJJg\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars range is correct"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
RANGE=$(sed "6q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $6}')
[[ "${RANGE}" == "30" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars range is correct
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\nOJJg\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars range is correct"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
RANGE=$(sed "6q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $6}')
[[ "${RANGE}" == "30" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars format guess is correct for Solexa
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\n;CXH\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars format guess is correct for Solexa"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
FORMAT=$(sed "8q;d" "${OUTPUT}" | \
		awk -F "[ ]" '{print $2}')
[[ "${FORMAT}" == "Solexa" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars format guess is correct for Illumina 1.3+
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\n@Kah\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars format guess is correct for Illumina 1.3+"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
FORMAT=$(sed "8q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $2}')
VERSION=$(sed "8q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $3}')
if [[ "${FORMAT}" == "Illumina" ]] && [[ "${VERSION}" == "1.3+" ]]; then
    success "${DESCRIPTION}"
else
    failure "${DESCRIPTION}"
fi
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars format guess is correct for Illumina 1.5+
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\nCT]h\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars format guess is correct for Illumina 1.5+"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
FORMAT=$(sed "8q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $2}')
VERSION=$(sed "8q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $3}')
if [[ "${FORMAT}" == "Illumina" ]] && [[ "${VERSION}" == "1.5+" ]]; then
    success "${DESCRIPTION}"
else
    failure "${DESCRIPTION}"
fi
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars format guess is correct for Illumina 1.8+
INPUT=$(mktemp)
printf '@a_1\nACGT\n+\n!+;i\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars format guess is correct for Illumina 1.8+"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
FORMAT=$(sed "8q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $2}')
VERSION=$(sed "8q;d" "${OUTPUT}" | \
	      awk -F "[ ]" '{print $3}')
if [[ "${FORMAT}" == "Illumina" ]] && [[ "${VERSION}" == "1.8+" ]]; then
    success "${DESCRIPTION}"
else
    failure "${DESCRIPTION}"
fi
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars percentage of nucleotides is correct
INPUT=$(mktemp)
printf '@a_1\nCTAT\n+\n;CXH\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars percentage of nucleotides is correct"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
PERCENTAGE=$(sed "12q;d" "${OUTPUT}" | \
		    awk -F "[ ]" '{print $18}')
[[ "${PERCENTAGE}" == '25.0%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars percentage of nucleotides is rounded to 1 digit of precison #1
INPUT=$(mktemp)
printf '@a_1\nCCACCT\n+\n;CCCXH\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars percentage of nucleotides is rounded to 1 digit of precison #1"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
PERCENTAGE=$(sed "13q;d" "${OUTPUT}" | \
		    awk -F "[ ]" '{print $18}')
[[ "${PERCENTAGE}" == '66.7%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars percentage of nucleotides is rounded to 1 digit of precison #2
INPUT=$(mktemp)
printf '@a_1\nCCACCTT\n+\n;CCCXXH\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars percentage of nucleotides is rounded to 1 digit of precison #2"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
PERCENTAGE=$(sed "13q;d" "${OUTPUT}" | \
		    awk -F "[ ]" '{print $18}')
[[ "${PERCENTAGE}" == '57.1%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars percentage of score letters is correct
INPUT=$(mktemp)
printf '@a_1\nCTAT\n+\n;CXH\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars percentage of score letters is correct"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
PERCENTAGE=$(sed "19q;d" "${OUTPUT}" | \
		    awk -F "[ ]" '{print $10}')
[[ "${PERCENTAGE}" == '25.0%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars percentage of score letters is rounded to 1 digit of precison #1
INPUT=$(mktemp)
printf '@a_1\nCCACCT\n+\n;CCCXC\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars percentage of score letters is rounded to 1 digit of precison #1"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
PERCENTAGE=$(sed "19q;d" "${OUTPUT}" | \
		    awk -F "[ ]" '{print $10}')
[[ "${PERCENTAGE}" == '66.7%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

## --fastq_chars percentage of nucleotides is rounded to 1 digit of precison #2
INPUT=$(mktemp)
printf '@a_1\nCCACCTT\n+\n;CCCCXH\n' > "${INPUT}"
OUTPUT=$(mktemp)
DESCRIPTION="--fastq_chars percentage of nucleotides is rounded to 1 digit of precison #2"
"${VSEARCH}" --fastq_chars "${INPUT}" 2> "${OUTPUT}"
cat "${OUTPUT}"
PERCENTAGE=$(sed "19q;d" "${OUTPUT}" | \
		    awk -F "[ ]" '{print $10}')
[[ "${PERCENTAGE}" == '57.1%' ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
rm "${INPUT}"

