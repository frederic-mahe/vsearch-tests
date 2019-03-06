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
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}


## use the first vsearch binary in $PATH by default, unless user wants
## to test another binary
VSEARCH=$(which vsearch)
[[ "${1}" ]] && VSEARCH="${1}"

## Is vsearch installed?
DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                Test options                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_mergepairs --reverse --fastqout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s1\nA\n+\n!\n") \
    --reverse <(printf "@s1\nA\n+\n!\n") \
    --fastqout - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastaout is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --fastaout - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastaout_notmerged_fwd is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --fastaout_notmerged_fwd - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastaout_notmerged_rev is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --fastaout_notmerged_fwd - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastqout is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --fastqout - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastqout_notmerged_fwd is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --fastqout_notmerged_fwd - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastqout_notmerged_rev is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --fastqout_notmerged_fwd - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --eetabbedout is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_truncqual is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_truncqual 1 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minlen is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_minlen 1 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minlen is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_minlen 1 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_maxns is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_maxns 1 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_allowmergestagger is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_allowmergestagger > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minovlen is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_minovlen 16 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --maxdiffs is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --maxdiffs 5 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_minmergelen 5 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_maxmergelen is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_maxmergelen 5 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_ascii is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_ascii 33 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_maxee is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_maxee 1 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_nostagger is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_nostagger > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_qmax is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --fastq_qmax 1 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_qmin is accepted"
printf '@seq1\nA\n+\n"\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n"\n') \
                 --eetabbedout - --fastq_qmin 1 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --label_suffix is accepted"
printf '@seq1\nA\n+\n!\n' | \
    "${VSEARCH}" --fastq_mergepairs - --reverse <(printf '@seq1\nA\n+\n!\n') \
                 --eetabbedout - --label_suffix a > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               --fastq_minovlen                              #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_mergepairs --fastq_minovlen fails if given 0"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minovlen 0 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minovlen fails if given negative integer"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minovlen -- -1 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minovlen does not merge seqs if len >"
MERGSEQ_NB=$("${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nAAAA\n+\n!!!!\n') \
                      --reverse <(printf '@seq2\nTTTT\n+\n!!!!\n') \
                      --fastqout - --fastq_minovlen 5 2>&1 | \
         grep "Merged" | awk '{print $1}' -)
[[ "${MERGSEQ_NB}" == $(printf "0") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                --fastq_minlen                               #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_mergepairs --fastq_minlen fails if given 0"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minlen 0 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minlen fails if given negative integer"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minlen -- -1 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minlen does not merge seqs if len >"
MERGSEQ_NB=$("${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nAAAA\n+\n!!!!\n') \
                      --reverse <(printf '@seq2\nTTTT\n+\n!!!!\n') \
                      --fastqout - --fastq_minovlen 3 --fastq_minlen 5 2>&1 | \
         grep "Merged" | awk '{print $1}' -)
[[ "${MERGSEQ_NB}" == $(printf "0") ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             --fastq_minmergelen                             #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen fails if given 0"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minmergelen 0 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen fails if given negative integer"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minmergelen -- -1 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen merge seqs but then discard then if len >"
MERGSEQ_NB=$("${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nAAAA\n+\n!!!!\n') \
                      --reverse <(printf '@seq2\nTTTT\n+\n!!!!\n') \
                      --fastqout - --fastq_minovlen 3 --fastq_minmergelen 5 2>&1 | \
                 grep "Merged" | awk '{print $1}' -)
MERGSEQS=$("${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nAAAA\n+\n!!!!\n') \
                      --reverse <(printf '@seq2\nTTTT\n+\n!!!!\n') \
                      --fastqout - --fastq_minovlen 3 --fastq_minmergelen 5 2> /dev/null)
[[ ("${MERGSEQ_NB}" == $(printf "1")) && ("${MERGSEQS}" == $(printf "")) ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             --fastq_minmergelen                             #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen fails if given 0"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minmergelen 0 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen fails if given negative integer"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minmergelen -- -1 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen merge seqs but then discard then if len >"
MERGSEQ_NB=$("${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nAAAA\n+\n!!!!\n') \
                      --reverse <(printf '@seq2\nTTTT\n+\n!!!!\n') \
                      --fastqout - --fastq_minovlen 3 --fastq_minmergelen 5 2>&1 | \
                 grep "Merged" | awk '{print $1}' -)
MERGSEQS=$("${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nAAAA\n+\n!!!!\n') \
                      --reverse <(printf '@seq2\nTTTT\n+\n!!!!\n') \
                      --fastqout - --fastq_minovlen 3 --fastq_minmergelen 5 2> /dev/null)
[[ ("${MERGSEQ_NB}" == $(printf "1")) && ("${MERGSEQS}" == $(printf "")) ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             --fastq_minmergelen                             #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen fails if given 0"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minmergelen 0 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen fails if given negative integer"
"${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nA\n+\n$\n') \
                      --reverse <(printf '@seq2\nT\n+\n$\n') \
                      --fastqout - --fastq_minmergelen -- -1 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_mergepairs --fastq_minmergelen merge seqs but then discard then if len >"
MERGSEQ_NB=$("${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nAAAA\n+\n!!!!\n') \
                      --reverse <(printf '@seq2\nTTTT\n+\n!!!!\n') \
                      --fastqout - --fastq_minovlen 3 --fastq_minmergelen 5 2>&1 | \
                 grep "Merged" | awk '{print $1}' -)
MERGSEQS=$("${VSEARCH}" --fastq_mergepairs <(printf '@seq1\nAAAA\n+\n!!!!\n') \
                      --reverse <(printf '@seq2\nTTTT\n+\n!!!!\n') \
                      --fastqout - --fastq_minovlen 3 --fastq_minmergelen 5 2> /dev/null)
[[ ("${MERGSEQ_NB}" == $(printf "1")) && ("${MERGSEQS}" == $(printf "")) ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

exit 0
