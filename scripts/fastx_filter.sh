
#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fastx_filter"
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

## vsearch --fastx_filter inputfile [--reverse inputfile] (--fastaout
## | --fastaout_discarded | --fastqout | --fastqout_discarded
## --fastaout_rev | --fastaout_discarded_rev | --fastqout_rev |
## --fastqout_discarded_rev) outputfile [options]


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

# none

#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then

    LOG=$(mktemp)
    FORWARD=$(mktemp)
    REVERSE=$(mktemp)
    printf "@s\nA\n+\nI\n" > "${FORWARD}"
    printf "@s\nT\n+\nI\n" > "${REVERSE}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastx_filter "${FORWARD}" \
        --reverse "${REVERSE}" \
        --fastaout /dev/null \
        --fastaout_discarded /dev/null \
        --fastqout /dev/null \
        --fastqout_discarded /dev/null \
        --fastaout_rev /dev/null \
        --fastaout_discarded_rev /dev/null \
        --fastqout_rev /dev/null \
        --fastqout_discarded_rev /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastx_filter valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastx_filter valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FORWARD}" "${REVERSE}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0


#*****************************************************************************#
#                                                                             #
#                               fastx_filters                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_filter is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastaout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter fails if argument given is not correct"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter toto --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter fails if no arguments"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                fastq_ASCII                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_filter --fastq_ascii is accepted with 64"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_ascii 64 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_ascii is accepted with 33"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_ascii 33 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_ascii is not accepted with other values"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_ascii 50 --fastaout - &>/dev/null && \
     failure "${DESCRIPTION}"|| \
            success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_ascii does not impact fasta input"
printf '>seq1\nAGC\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_ascii 50 --fastaout - &>/dev/null && \
     failure "${DESCRIPTION}"|| \
            success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             fastq_max/minlen                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_filter --fastq_maxlen is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_maxlen 10 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_minlen is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_minlen 10 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxlen fails if fastq_minlen greater than"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_minlen 10 --fastqmaxlen 5 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}"|| \
            success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_minlen fails if below 0"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_minlen \-1 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}"|| \
            success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxlen gives the correct result"
OUTPUT=$(printf '>seq1\nAGA\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_maxlen 2 --fastaout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_minlen gives the correct result"
OUTPUT=$(printf '>seq1\nAGA\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_minlen 4 --fastaout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxlen fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_maxlen \-1 --fastqout - 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_minlen is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_minlen 2 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_minlen is giving the correct result"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_minlen 3 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAGA\n+\n!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_minlen is giving the correct result #2"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_minlen 2 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_minlen fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_minlen \-1 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                fastq_max                                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_filter --fastx_maxee is accepted"
printf '@seq1\nAG\n+\n!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_maxee 1.9 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastx_maxee does not impact when fasta input"
OUTPUT=$(printf '>seq1\nAGA\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_maxee 0 --fastaout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>seq1\nAGA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxee is giving the correct result"
OUTPUT=$(printf '@seq1\nAG\n+\n!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_maxee 2.0 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAG\n+\n!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxee is giving the correct result #2"
OUTPUT=$(printf '@seq1\nAG\n+\n!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_maxee 1.9 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAG\n+\n!!\n') ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxee_rate is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_maxee_rate 110 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxee_rate does not impact a fasta input"
OUTPUT=$(printf '>seq1\nAG\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_maxee_rate 0.9 --fastaout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAG\n+\n!!\n') ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxee_rate is giving the correct result"
OUTPUT=$(printf '@seq1\nAG\n+\n!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_maxee_rate 1 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAG\n+\n!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxee_rate is giving the correct result #2"
OUTPUT=$(printf '@seq1\nAG\n+\n!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_maxee_rate 0.9 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAG\n+\n!!\n') ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxns is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_maxns 0 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}"|| \
            failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxns is giving the correct result"
OUTPUT=$(printf '@seq1\nANA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_maxns 1 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nANA\n+\n!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxns is giving the correct result #2"
OUTPUT=$(printf '@seq1\nANA\n+\n!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_maxns 0 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_maxns fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_maxns \-1 --fastqout - 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_qmin/max is accepted"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_qmin 0 --fastq_qmax 41 --fastqout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_qmax fails when quality above it"
printf '@seq1\nAGA\n+\n""!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_qmin 0 --fastq_qmax 0 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_qmin fails when quality under it"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_qmin 1 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_qmin --fastq_qmax fails when qmax<qmin"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_qmin 10 --fastq_qmax 5 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_qmin fails when negative"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_qmin \-1 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_qmax fails when negative"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_qmax \-1 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             fastq_stripleft                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_filter --fastq_stripleft is accepted"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_stripleft 0 --fastqout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_stripleft erase all when parameter greater than input length"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_stripleft 4 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_stripleft gives the correct result"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_stripleft 1 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nGA\n+\n!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               fastq_trunc                                   #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_filter --fastq_truncee is accepted"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_truncee 0 --fastqout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_truncee fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_truncee \-2 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_truncee erase all when parameter greater than input length"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_minlen 4 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_trunclen is accepted"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_truncee 1 --fastqout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_trunclen erase all when parameter equals 0"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_trunclen 0 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_trunclen fails if negative value"
printf '@seq1\nAGA\n+\n!!!\n' | \
    "${VSEARCH}" --fastx_filter - --fastq_trunclen \-2 --fastqout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_trunclen discards the output if value greater than input length"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_trunclen 4 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastq_trunclen_keep keeps the output if value greater than input length"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_trunclen_keep 4 --fastqout - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1\nAGA\n+\n!!!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 relabel                                     #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_filter --relabel  gives the correct value"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n@seq2\nA\n+\n!\n' | \
		"${VSEARCH}" --fastx_filter - --fastqout - --relabel sequence 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@sequence1\nAGA\n+\n!!!\n@sequence2\nA\n+\n!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --relabel_keep gives the correct value"
OUTPUT=$(printf '>seq\nAGA\n>seq\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel_keep --relabel sequence 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>sequence1 seq\nAGA\n>sequence2 seq\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
DESCRIPTION="--fastx_filter --relabel --sizeout gives the correct value"
OUTPUT=$(printf '>seq1;size=3\nAGA\n>seq2;size=2\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel sequence --sizeout 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>sequence1;size=3;\nAGA\n>sequence2;size=2;\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --sizeout gives the correct value #2"
OUTPUT=$(printf '>seq1\nAGA\n>seq2\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel sequence --sizeout 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>sequence1;size=1;\nAGA\n>sequence2;size=1;\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --xsize gives the correct value"
OUTPUT=$(printf '>seq1;size=3\nAGA\n>seq2;size=2\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --xsize 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>seq1\nAGA\n>seq2\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --xsize gives the correct value #2"
OUTPUT=$(printf '>seq1\nAGA\n>seq2\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --xsize 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>seq1\nAGA\n>seq2\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --relabel_md5 gives the correct value"
OUTPUT=$(printf '>seq\nAGA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel_md5 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>b13b6429c6c3ddc1531b364fdfd82457\nAGA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --relabel_sha1 gives the correct value"
OUTPUT=$(printf '>seq\nAGA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel_sha1 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>c9cd9df36dcce8254c5ccf410709b5213524ad76\nAGA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                    out                                      #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_filter --fastqout_discarded shows the name of the discarded sequence"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n' | \
		"${VSEARCH}" --fastx_filter - --fastq_trunclen 4 --fastqout_discarded - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@seq1') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastqout_discarded fails if fasta input"
printf '>seq1\nAGA\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_trunclen 4 --fastqout_discarded - 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastaout_discarded shows the name of the discarded sequence"
OUTPUT=$(printf '>seq1\nAGA\n' | \
		"${VSEARCH}" --fastx_filter - --fastq_trunclen 4 --fastaout_discarded - 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>seq1') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --fastaout_discarded fails if fastq input"
printf '@seq1\nAGA\n+\n!!!\n' | \
		 "${VSEARCH}" --fastx_filter - --fastq_trunclen 4 --fastaout_discarded - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 relabel                                     #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_filter --relabel  gives the correct value"
OUTPUT=$(printf '@seq1\nAGA\n+\n!!!\n@seq2\nA\n+\n!\n' | \
		"${VSEARCH}" --fastx_filter - --fastqout - --relabel sequence 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '@sequence1\nAGA\n+\n!!!\n@sequence2\nA\n+\n!\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --relabel_keep gives the correct value"
OUTPUT=$(printf '>seq\nAGA\n>seq\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel_keep --relabel sequence 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>sequence1 seq\nAGA\n>sequence2 seq\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
DESCRIPTION="--fastx_filter --relabel --sizeout gives the correct value"
OUTPUT=$(printf '>seq1;size=3\nAGA\n>seq2;size=2\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel sequence --sizeout 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>sequence1;size=3;\nAGA\n>sequence2;size=2;\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --sizeout gives the correct value #2"
OUTPUT=$(printf '>seq1\nAGA\n>seq2\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel sequence --sizeout 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>sequence1;size=1;\nAGA\n>sequence2;size=1;\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --xsize gives the correct value"
OUTPUT=$(printf '>seq1;size=3\nAGA\n>seq2;size=2\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --xsize 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>seq1\nAGA\n>seq2\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --xsize gives the correct value #2"
OUTPUT=$(printf '>seq1\nAGA\n>seq2\nA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --xsize 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>seq1\nAGA\n>seq2\nA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --relabel_md5 gives the correct value"
OUTPUT=$(printf '>seq\nAGA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel_md5 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>b13b6429c6c3ddc1531b364fdfd82457\nAGA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --relabel --relabel_sha1 gives the correct value"
OUTPUT=$(printf '>seq\nAGA\n' | \
		"${VSEARCH}" --fastx_filter - --fastaout - --relabel_sha1 2>/dev/null)
[[ "${OUTPUT}" == \
   $(printf '>c9cd9df36dcce8254c5ccf410709b5213524ad76\nAGA\n') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                    xee                                      #
#                                                                             #
#*****************************************************************************#

# Strip information about expected errors (ee) from the output file
# headers. This information is added by the --fastq_eeout and --eeout
# options. Option introduced in vsearch v2.11.0 (Feb. 2019).

DESCRIPTION="--fastx_filter --xee strips the ee header (@s;ee=float)"
printf "@s;ee=1.23\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --xee strips the ee header (@s;ee=float;)"
printf "@s;ee=1.23;\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --xee strips the ee header (@s;size=1;ee=float)"
printf "@s;size=1;ee=1.23\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --xee strips the ee header (@s;size=1;ee=float;)"
printf "@s;size=1;ee=1.23;\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_filter --xee strips the ee header (@s;ee=float;size=1)"
printf "@s;ee=1.23;size=1\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# assuming vsearch never outputs entry headers ending with ";"
DESCRIPTION="--fastx_filter --xee strips the ee header (@s;ee=float;size=1;)"
printf "@s;ee=1.23;size=1;\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# assuming xee can only match ";ee=[0-9]*.?[0-9]*;?"
DESCRIPTION="--fastx_filter --xee does not strip non-float ee values (@s;ee=not-a-float;)"
printf "@s;ee=a;\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s;ee=a;" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# verify what xee can match: ";ee=[0-9]*.?[0-9]*;?"
DESCRIPTION="--fastx_filter --xee strips partial ee floats values (@s;ee=.23)"
printf "@s;ee=.23\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# verify what xee can match: ";ee=[0-9]*.?[0-9]*;?"
DESCRIPTION="--fastx_filter --xee strips partial ee floats values (@s;ee=0)"
printf "@s;ee=0\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# ee cannot contain a negative value
DESCRIPTION="--fastx_filter --xee does not strip negative ee values (@s;ee=-1)"
printf "@s;ee=-1\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# ee is placed before the header!
DESCRIPTION="--fastx_filter --xee strips when ee is placed before the sequence header (@;ee=float;s)"
printf "@;ee=1.23;s\nA\n+\nI\n" | \
	"${VSEARCH}" --fastx_filter - --fastqout - --xee 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


exit 0

# TODO:
# --fastx_filter: does not truncate fastq labels by default?!
