#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="masking options"
LINE=$(printf "%076s\n" | tr " " "-")
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
#                               fastq_filters                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_filter is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastaout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter fails if argument given is not correct"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter toto --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter fails if no arguments"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                fastq_ASCII                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_filter --fastq_ascii is accepted with 64"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_ascii 64 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_ascii is accepted with 33"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_ascii 33 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_ascii is not accepted with other values"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_ascii 50 --fastaout - &>/dev/null && \
     failure "${DESCRIPTION}"|| \
            success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             fastq_max/minlen                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_filter --fastq_maxlen is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_maxlen 10 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minlen is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_minlen 10 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxlen fails if fastq_minlen greater than"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_minlen 10 --fastqmaxlen 5 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}"|| \
            success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minlen fails if below 0"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_minlen \-1 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}"|| \
            success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                  fastq_max                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_filter --fastq_maxee is accepted"
printf '@seq1\nAG\n+\n!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_maxee 1.9 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxee is giving the correct result"
OUTPUT=$(printf '@seq1\nAG\n+\n!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_maxee 2.0 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAG\n+\n!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxee is giving the correct result #2"
OUTPUT=$(printf '@seq1\nAG\n+\n!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_maxee 1.9 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAG\n+\n!!\n') ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxee_rate is giving the correct result"
OUTPUT=$(printf '@seq1\nAG\n+\n!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_maxee_rate 1 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAG\n+\n!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxee_rate is giving the correct result #2"
OUTPUT=$(printf '@seq1\nAG\n+\n!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_maxee_rate 0.9 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAG\n+\n!!\n') ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxee_rate is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_maxee_rate 110 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxlen is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_maxlen 2 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxlen is giving the correct result"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_maxlen 3 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAGA\n+\n!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxlen is giving the correct result #2"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_maxlen 2 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxlen fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_maxlen \-1 --fastqout - 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxns is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_maxns 0 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxns is giving the correct result"
OUTPUT=$(printf '@seq1\nANA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_maxns 1 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nANA\n+\n!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxns is giving the correct result #2"
OUTPUT=$(printf '@seq1\nANA\n+\n!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_maxns 0 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_maxns fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_maxns \-1 --fastqout - 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minlen is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_minlen 2 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minlen is giving the correct result"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_minlen 3 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAGA\n+\n!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minlen is giving the correct result #2"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_minlen 2 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_minlen fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_minlen \-1 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_qmin/max is accepted"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_qmin 0 --fastq_qmax 41 --fastqout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_qmax fails when quality above it"
printf '@seq1\nAGA\n+\n""!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_qmin 0 --fastq_qmax 0 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_qmin fails when quality under it"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_qmin 1 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_qmin --fastq_qmax fails when qmax<qmin"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_qmin 10 --fastq_qmax 5 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_qmin fails when negative"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_qmin \-1 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_qmin fails when negative"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_qmin \-1 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_stripleft is accepted"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_stripleft 0 --fastqout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_stripleft erase all when parameter greater than input length"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_stripleft 4 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                                 fastq_trunc                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_filter --fastq_truncee is accepted"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_truncee 0 --fastqout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_truncee fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_truncee \-2 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_truncee erase all when parameter greater than input length"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_minlen 4 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_trunclen is accepted"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_truncee 1 --fastqout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_trunclen erase all when parameter equals 0"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_trunclen 0 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_trunclen fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastq_filter - --fastq_trunclen \-2 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_trunclen discards the output if value greater than input length"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_trunclen 4 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastq_trunclen_keep keeps the output if value greater than input length"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_trunclen_keep 4 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAGA\n+\n!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --fastqout_discarded shows the discarded sequence"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastq_filter - --fastq_trunclen 4 --fastqout_discarded - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAGA\n+\n!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --relabel  gives the correct value"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n@seq2\nA\n+\n!\n' | \
		"${VSEARCH}" --fastq_filter - --fastqout - --relabel sequence 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@sequence1\nAGA\n+\n!!!\n@sequence2\nA\n+\n!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_filter --relabel --relabel_keep gives the correct value"
OUTPUT=$(printf '@seq\nAGA\n+\n!!!\n@seq\nA\n+\n!\n' | \
		"${VSEARCH}" --fastq_filter - --fastqout - --relabel_keep --relabel sequence 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq sequence1\nAGA\n+\n!!!\n@seq sequence2\nA\n+\n!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

exit 0
