#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fastq_mergepairs"
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
#                                Test options                                 #
#                                                                             #
#*****************************************************************************#

## As of 2023-07-06

# note: both input files need to be compressed
DESCRIPTION="fastq_mergepairs option bzip2_decompress is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n" | bzip2) \
    --reverse <(printf '@s\nT\n+\nI\n' | bzip2) \
    --bzip2_decompress \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option eeout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --eeout \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option eetabbedout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --eetabbedout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fasta_width is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fasta_width 0 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastaout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastaout_notmerged_fwd is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastaout_notmerged_fwd /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastaout_notmerged_rev is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastaout_notmerged_rev /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_allowmergestagger is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_allowmergestagger \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_ascii is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_ascii 33 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_eeout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_eeout \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_maxdiffpct is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_maxdiffpct 100.0 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_maxdiffs is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_maxdiffs 10 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_maxee is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_maxee 1.0 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_maxlen is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_maxlen 10 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_maxmergelen is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_maxmergelen 10 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_maxns is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_maxns 1 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minlen is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_minlen 10 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minmergelen is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_minmergelen 10 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_minovlen 10 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_nostagger is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_nostagger \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmax is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmax 41 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmaxout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmaxout 41 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmin is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmin 1 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qminout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qminout 1 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_truncqual is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_truncqual 10 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastqout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastqout_notmerged_fwd is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastqout_notmerged_fwd /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastqout_notmerged_rev is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastqout_notmerged_rev /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option gzip_decompress is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n" | gzip) \
    --reverse <(printf '@s\nT\n+\nI\n' | gzip) \
    --gzip_decompress \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option label_suffix is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --label_suffix A \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option lengthout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --lengthout \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option log is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --log /dev/null \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option no_progress is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --no_progress \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option quiet is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --quiet \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option relabel is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --relabel S \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option relabel_keep is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --relabel S \
    --relabel_keep \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option relabel_md5 is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --relabel_md5 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option relabel_self is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --relabel_self \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option relabel_sha1 is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --relabel_sha1 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option reverse is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option sample is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --sample=ABC \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option sizein is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s;size=5\nA\n+\nI\n") \
    --reverse <(printf '@s;size=5\nT\n+\nI\n') \
    --sizein \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option sizeout is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --sizeout \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option threads is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --threads 2 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option xee is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s;ee=1.0\nA\n+\nI\n") \
    --reverse <(printf '@s;ee=1.0\nT\n+\nI\n') \
    --xee \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option xlength is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s;length=1\nA\n+\nI\n") \
    --reverse <(printf '@s;length=1\nT\n+\nI\n') \
    --xlength \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option xsize is accepted"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s;size=1\nA\n+\nI\n") \
    --reverse <(printf '@s;size=1\nT\n+\nI\n') \
    --xsize \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             handle empty input                              #
#                                                                             #
#*****************************************************************************#

## (see issue 366)

DESCRIPTION="fastq_mergepairs R1 and R2 empty input"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "") \
    --reverse <(printf "") \
    --fastqout - > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Fatal error: More forward reads than reverse reads
DESCRIPTION="fastq_mergepairs R2 empty input"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s1\nA\n+\nI\n") \
    --reverse <(printf "") \
    --fastqout - > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# Fatal error: More reverse reads than forward reads
DESCRIPTION="fastq_mergepairs R1 empty input"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "") \
    --reverse <(printf "@s1\nA\n+\nI\n") \
    --fastqout - > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs empty input yields empty output"
TMP=$(mktemp -u)
"${VSEARCH}" \
    --fastq_mergepairs <(printf "") \
    --reverse <(printf "") \
    --fastqout ${TMP} > /dev/null 2>&1
[[ -e ${TMP} ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}

DESCRIPTION="fastq_mergepairs no warning if empty input"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "") \
    --reverse <(printf "") \
    --fastqout /dev/null 2>&1 | \
    grep -qi "^Warning" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs error if missing file"
"${VSEARCH}" \
    --fastq_mergepairs missing_R1 \
    --reverse missing_R2 \
    --fastqout - > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               --fastq_minovlen                              #    
#                                                                             #
#*****************************************************************************#

# positive integer: default is 10, must be at least 5.

DESCRIPTION="fastq_mergepairs option fastq_minovlen accepts values >= 5 (5)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 5 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen accepts values >= 5 (10)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 10 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen accepts values >= 5 (2^8)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 256 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen accepts values >= 5 (2^16)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 65536 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen accepts values >= 5 (2^32)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 4294967296 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen accepts values >= 5 (2^63 - 1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 9223372036854775807 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# option value is stored in a signed int64_t
DESCRIPTION="fastq_mergepairs option fastq_minovlen rejects values > 2^63 - 1 (2^63)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 9223372036854775808 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="fastq_mergepairs option fastq_minovlen rejects values > 2^63 - 1 (2^64 - 1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 18446744073709551615 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen rejects values > 2^63 - 1 (2^64)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 18446744073709551616 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen rejects values below 5 (4)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 4 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen rejects values below 5 (0)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen 0 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen must be a positive integer (-1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen -1 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minovlen must be an integer (A)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minovlen A \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                --fastq_minlen                               #    
#                                                                             #
#*****************************************************************************#

# discard sequences with less than the specified number of bases (default 1)

DESCRIPTION="fastq_mergepairs option fastq_minlen accepts values >= 1 (1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen 1 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minlen accepts values >= 1 (2^8)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen 256 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minlen accepts values >= 5 (2^16)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen 65536 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minlen accepts values >= 5 (2^32)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen 4294967296 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minlen accepts values >= 5 (2^63 - 1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen 9223372036854775807 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# option value is stored in a signed int64_t
DESCRIPTION="fastq_mergepairs option fastq_minlen rejects values > 2^63 - 1 (2^63)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen 9223372036854775808 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="fastq_mergepairs option fastq_minlen rejects values > 2^63 - 1 (2^64 - 1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen 18446744073709551615 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minlen rejects values > 2^63 - 1 (2^64)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen 18446744073709551616 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# should minlen = 0 be rejected? should users be allowed to reject all input sequences?
DESCRIPTION="fastq_mergepairs option fastq_minlen rejects value 0"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen 0 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minlen must be a positive integer"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen -1 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minlen must be an integer"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minlen A \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                             --fastq_minmergelen                             #    
#                                                                             #
#*****************************************************************************#

# specify the minimum length of the merged sequence. The default is 1.

DESCRIPTION="fastq_mergepairs option fastq_minmergelen accepts values >= 1 (1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen 1 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minmergelen accepts values >= 1 (2^8)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen 256 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minmergelen accepts values >= 5 (2^16)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen 65536 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minmergelen accepts values >= 5 (2^32)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen 4294967296 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minmergelen accepts values >= 5 (2^63 - 1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen 9223372036854775807 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# option value is stored in a signed int64_t
DESCRIPTION="fastq_mergepairs option fastq_minmergelen rejects values > 2^63 - 1 (2^63)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen 9223372036854775808 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


DESCRIPTION="fastq_mergepairs option fastq_minmergelen rejects values > 2^63 - 1 (2^64 - 1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen 18446744073709551615 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minmergelen rejects values > 2^63 - 1 (2^64)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen 18446744073709551616 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# should minmergelen = 0 be rejected? should users be allowed to reject all input sequences?
DESCRIPTION="fastq_mergepairs option fastq_minmergelen rejects value 0"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen 0 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minmergelen must be a positive integer"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen -1 \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_minmergelen must be an integer"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf '@s\nT\n+\nI\n') \
    --fastq_minmergelen A \
    --fastqout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                --fastq_qmax                                 #
#                                                                             #
#*****************************************************************************#

# Specify the maximum quality score accepted when reading FASTQ
# files. The default is 41, which is usual for recent Sanger/Illumina
# 1.8+ files.

# int64_t again, values accepted should range from 1 to 93

DESCRIPTION="fastq_mergepairs option fastq_qmax rejects negative values"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmax -1 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# lowest possible qmin is zero, and qmax = qmin + 1
DESCRIPTION="fastq_mergepairs option fastq_qmax rejects a null value"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\n!\n") \
    --reverse <(printf "@s\nT\n+\n!\n") \
    --fastq_qmax 0 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmax accepts positive integers (1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\n!\n") \
    --reverse <(printf "@s\nT\n+\n!\n") \
    --fastq_qmax 1 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="fastq_mergepairs option fastq_qmax accepts positive integers (41)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmax 41 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmax accepts positive integers (93)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmax 93 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Sum of arguments to --fastq_ascii and --fastq_qmax must be no more than 126
DESCRIPTION="fastq_mergepairs option fastq_qmax rejects values greater than 126 - 33 = 93 (94)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmax 94 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmax 40 accepts entry with Q=40"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmax 40 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmax 40 rejects entry with Q=41"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nJ\n") \
    --reverse <(printf "@s\nT\n+\nJ\n") \
    --fastq_qmax 40 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmax 40 rejects entry with Q=41 (log file)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nJ\n") \
    --reverse <(printf "@s\nT\n+\nJ\n") \
    --fastq_qmax 40 \
    --log /dev/null \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmax must be greater than fastq_qmin"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nJ\n") \
    --reverse <(printf "@s\nT\n+\nJ\n") \
    --fastq_qmin 42 \
    --fastq_qmax 41 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                --fastq_qmin                                 #
#                                                                             #
#*****************************************************************************#

# Specify the minimum quality score accepted for FASTQ files. The
# default is 0, which is usual for recent Sanger/Illumina 1.8+
# files. Older formats may use scores between -5 and 2.

# int64_t again, values accepted should range from 0 to 92

# Older formats may use scores between -5 and 2. To do what?

# Sum of arguments to --fastq_ascii and --fastq_qmin must be no less than 33
DESCRIPTION="fastq_mergepairs option fastq_qmin rejects negative values (-1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmin -1 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmin accepts a null value (default)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmin 0 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmin accepts positive integers (1)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmin 1 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmin accepts positive integers (40)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmin 40 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# The argument to --fastq_qmin cannot be equal to or greater than --fastq_qmax
DESCRIPTION="fastq_mergepairs fails if fastq_qmin is equal to fastq_qmax default (41)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmin 41 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs succeeds if fastq_qmin is smaller than fastq_qmax (41)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nJ\n") \
    --reverse <(printf "@s\nT\n+\nJ\n") \
    --fastq_qmin 41 \
    --fastq_qmax 42 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs succeeds if fastq_qmax is greater than fastq_qmin (42)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nK\n") \
    --reverse <(printf "@s\nT\n+\nK\n") \
    --fastq_qmin 42 \
    --fastq_qmax 93 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs succeeds if fastq_qmax is greater than fastq_qmin (92)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\n}\n") \
    --reverse <(printf "@s\nT\n+\n}\n") \
    --fastq_qmin 92 \
    --fastq_qmax 93 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# The argument to --fastq_qmin cannot be larger than --fastq_qmax
DESCRIPTION="fastq_mergepairs option fastq_qmin rejects values greater than 126 - 33 = 93 (94)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nI\n") \
    --reverse <(printf "@s\nT\n+\nI\n") \
    --fastq_qmin 94 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmin 15 accepts entry with Q=15"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\n0\n") \
    --reverse <(printf "@s\nT\n+\n0\n") \
    --fastq_qmin 15 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmin 16 rejects entry with Q=15"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\n0\n") \
    --reverse <(printf "@s\nT\n+\n0\n") \
    --fastq_qmin 16 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmin 16 rejects entry with Q=15 (log file)"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\n0\n") \
    --reverse <(printf "@s\nT\n+\n0\n") \
    --fastq_qmin 16 \
    --log /dev/null \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="fastq_mergepairs option fastq_qmin must be smaller than fastq_qmax"
"${VSEARCH}" \
    --fastq_mergepairs <(printf "@s\nA\n+\nJ\n") \
    --reverse <(printf "@s\nT\n+\nJ\n") \
    --fastq_qmin 42 \
    --fastq_qmax 41 \
    --fastaout /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

exit 0
