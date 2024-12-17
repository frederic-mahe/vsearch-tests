#!/bin/bash -

## Print a header
SCRIPT_NAME="fasta2fastq"
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

## ------------------------------------------------------------------- fastqout

DESCRIPTION="--fasta2fastq accepts --fastqout"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

# Cannot subsample more reads than in the original sample
DESCRIPTION="--fasta2fastq accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq keeps empty fasta sequences"
printf ">s\n\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -wq "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastqout outputs in fastq format (fasta input)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq "@sA+J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastqout rejects fastq input"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq fails if unable to open input file for reading"
TMP=$(mktemp) && chmod u-r ${TMP}  # remove read permission
printf ">s\nA\n" > ${TMP}
"${VSEARCH}" \
    --fasta2fastq ${TMP} \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r ${TMP} && rm -f ${TMP}
unset TMP


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

# Add a fake nucleotide quality score to the sequences in the given
# FASTA file and write them to the FASTQ file specified with the
# --fastqout option.

DESCRIPTION="--fasta2fastq adds a fake quality header line (+)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    grep -wq "+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq adds a fake quality value (J by default)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    grep -wq "J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq outputs fastq entries (4 lines)"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    awk 'END {exit NR == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq output size is equal to input size"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    awk '/^@/ {s += 1} END {exit s == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq input order is preserved"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n>s5\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    grep "^@" | \
    sort --check=quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq entries are not duplicated or lost"
printf ">s1\nA\n>s2\nC\n>s3\nG\n>s4\nT\n>s5\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    grep "^@" | \
    sort --unique | \
    awk -F "=" 'END {exit NR == 5 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fake quality is the same length as input fasta sequence
DESCRIPTION="--fasta2fastq length of quality line is correct (length = 1)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw "@sA+J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq length of quality line is correct (length = 2)"
printf ">s\nAA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    tr -d "\n" | \
    grep -qw "@sAA+JJ" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq length of quality line is correct (length = 80)"
printf ">s\n%080s\n" | \
    tr " " "A" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    awk 'NR == 4 {exit length($1) == 80 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq length of consecutive quality lines is correct (1025, then 80)"
(printf ">s1\n%01025s\n" | \
     tr " " "A"
 printf ">s2\n%080s\n" | \
     tr " " "A") | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    awk 'NR == 8 {exit length($1) == 80 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## no folding of long sequences, expect 4 lines
DESCRIPTION="--fasta2fastq output is not folded at 80 chars per line"
printf ">s\n%081s\n" | \
    tr " " "A" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    awk 'END {exit NR == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## input folding is not conserved, expect 4 lines of output
DESCRIPTION="--fasta2fastq folded input is unfolded"
printf ">s\nA\nA\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout - 2> /dev/null | \
    awk 'END {exit NR == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------- fastq_asciiout

DESCRIPTION="--fasta2fastq --fastq_asciiout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_asciiout 33 \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_asciiout 33 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastq_asciiout 33 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_asciiout 64 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastq_asciiout 64 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_asciiout values other than 33 and 64 are rejected"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastq_asciiout 63 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_asciiout (33 in, default symbol is J)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastq_asciiout 33 \
        --quiet \
        --fastqout - | \
    tr -d "\n" | \
    grep -qw "@sA+J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_asciiout (64 in, default symbol is i)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastq_asciiout 64 \
        --quiet \
        --fastqout - | \
    tr -d "\n" | \
    grep -qw "@sA+i" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- fastq_qmaxout

#   --fastq_qmaxout INT         fake quality score for FASTQ output (41)

DESCRIPTION="--fasta2fastq --fastq_qmaxout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 41 \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_qmaxout 41 adds quality value J (offset 33)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 41 \
        --fastqout - | \
    grep -wq "J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_qmaxout 40 adds quality value I (offset 33)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 40 \
        --fastqout - | \
    grep -wq "I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_qmaxout 0 adds quality value ! (offset 33)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 0 \
        --fastqout - | \
    grep -wq "!" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_qmaxout 93 adds quality value ~ (offset 33)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 93 \
        --fastqout - | \
    grep -wq "~" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq rejects --fastq_qmaxout 94 (offset 33)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 94 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_qmaxout 41 adds quality value i (offset 64)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 41 \
        --fastq_asciiout 64 \
        --fastqout - | \
    grep -wq "i" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_qmaxout 40 adds quality value h (offset 64)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 40 \
        --fastq_asciiout 64 \
        --fastqout - | \
    grep -wq "h" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_qmaxout 0 adds quality value @ (offset 64)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 0 \
        --fastq_asciiout 64 \
        --fastqout - | \
    grep -wq "@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --fastq_qmaxout 62 adds quality value ~ (offset 64)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 62 \
        --fastq_asciiout 64 \
        --fastqout - | \
    grep -wq "~" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq rejects --fastq_qmaxout 63 (offset 64)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastq_qmaxout 63 \
        --fastq_asciiout 64 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

# The valid options for the fasta2fastq command are:
# --bzip2_decompress --fastq_asciiout --fastq_qmaxout --fastqout
# --gzip_decompress --label_suffix --lengthout --log --no_progress
# --quiet --relabel --relabel_keep --relabel_md5 --relabel_self
# --relabel_sha1 --sample --sizein --sizeout --threads --xee
# --xlength --xsize

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--fasta2fastq --bzip2_decompress is accepted"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --bzip2_decompress \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --bzip2_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --bzip2_decompress \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--fasta2fastq --gzip_decompress is accepted"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --gzip_decompress \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --gzip_decompress accepts compressed stdin"
printf ">s\nA\n" | \
    gzip | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --gzip_decompress \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--fasta2fastq --label_suffix is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --label_suffix "_suffix" \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --label_suffix adds the suffix 'string' to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --label_suffix "_suffix" \
        --fastqout - | \
    grep -wq "@s_suffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --label_suffix adds the suffix 'string' (before annotations)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --label_suffix "_suffix" \
        --lengthout \
        --fastqout - | \
    grep -wq "@s_suffix;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--fasta2fastq --lengthout is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --lengthout \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --lengthout adds length annotations to output"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --lengthout \
        --fastqout - | \
    grep -wq "@s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--fasta2fastq --log is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --log /dev/null \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --log writes to a file"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastqout /dev/null \
        --log - | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --log does not prevent messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastqout /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--fasta2fastq --no_progress is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --no_progress \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--fasta2fastq --no_progress removes progressive report on stderr (no visible effect)"
printf ">s extra\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --no_progress \
        --fastqout /dev/null 2>&1 | \
    grep -iq "^converting" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--fasta2fastq --quiet is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --quiet eliminates all (normal) messages to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --quiet allows error messages to be sent to stderr"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --quiet2 \
        --fastqout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--fasta2fastq --relabel is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel renames sequence (label + ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --fastqout - | \
    grep -wq "@label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel renames sequence (empty label, only ticker)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "" \
        --fastqout - | \
    grep -wq "@1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel cannot combine with --relabel_md5"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --relabel_md5 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel cannot combine with --relabel_sha1"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --relabel_sha1 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--fasta2fastq --relabel_keep is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_keep renames and keeps original sequence name"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --relabel_keep \
        --fastqout - | \
    grep -wq "@label1 s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--fasta2fastq --relabel_md5 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_md5 \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_md5 relabels using MD5 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_md5 \
        --fastqout - | \
    grep -qw "@7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--fasta2fastq --relabel_self is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self relabels using sequence as label"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - | \
    grep -qw "@A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self preserves U symbols (no conversion)"
printf ">s\nU\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - | \
    grep -qw "@U" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self preserves case (no conversion)"
printf ">s\na\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - | \
    grep -qw "@a" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self eliminates wrapping"
printf ">s\nA\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - | \
    grep -qw "@AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self eliminates whitespace (with a warning)"
printf ">s\nA A\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - 2> /dev/null | \
    grep -qw "@AA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self empty sequence makes empty label"
printf ">s\n\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - | \
    grep -qw "@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self accepts IUPAC sequences"
printf ">s\nACGTURYSWKMDBHVNacgturyswkmdbhvn\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - | \
    grep -qw "@ACGTURYSWKMDBHVNacgturyswkmdbhvn" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# can output an empty label!
DESCRIPTION="--fasta2fastq --relabel_self rejects non-IUPAC"
printf ">s\nX\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - 2> /dev/null | \
    grep -qw "@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--fasta2fastq --relabel_sha1 is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_sha1 \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_sha1 relabels using SHA1 hash of sequence"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_sha1 \
        --fastqout - | \
    grep -qw "@6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--fasta2fastq --sample is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --sample "ABC" \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --sample adds sample name to sequence headers"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --sample "ABC" \
        --fastqout - | \
    grep -qw "@s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--fasta2fastq accepts --sizein"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --sizein \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --sizein (fasta input)"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --sizein \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# entries without annotations are silently assumed to be of size=1
DESCRIPTION="--fasta2fastq --sizein (missing annotations are set to size=1)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --sizein \
        --fastqout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq "@sA+J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --sizein takes into account annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --sizein \
        --fastqout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq "@s;size=2A+J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --sizein (output size is conserved)"
printf ">s;size=3\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --sizein \
        --fastqout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq "@s;size=3A+J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

DESCRIPTION="--fasta2fastq --sizeout is accepted (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --sizeout \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --sizeout is accepted (with size)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --sizeout \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --sizeout missing size annotations are not added (no size)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastqout - | \
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# no --sizein, so all entries are size=1, --sizeout writes that value to the output
DESCRIPTION="--fasta2fastq size annotations are present in output (with --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --sizeout \
        --fastqout - | \
    grep -qw "@s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq size annotations are present in output (without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --fastqout - | \
    grep -qw "@s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## add abundance annotations
DESCRIPTION="--fasta2fastq --relabel no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --fastqout - | \
    grep -qw "@label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --fastqout - | \
    grep -qw "@label1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - | \
    grep -qw "@A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --sizeout \
        --fastqout - | \
    grep -qw "@A;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_md5 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_md5 \
        --fastqout - | \
    grep -qw "@7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_md5 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --fastqout - | \
    grep -qw "@7fc56270e7a70fa81a5935b72eacbe29;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_sha1 no size annotations (without --sizeout)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_sha1 \
        --fastqout - | \
    grep -qw "@6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_sha1 --sizeout adds size annotations"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --fastqout - | \
    grep -qw "@6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## preserve abundance annotations
DESCRIPTION="--fasta2fastq --relabel no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --fastqout - | \
    grep -qw "@label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel --sizeout conserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel "label" \
        --sizeout \
        --fastqout - | \
    grep -qw "@label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --fastqout - | \
    grep -qw "@A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_self --sizeout conserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_self \
        --sizeout \
        --fastqout - | \
    grep -qw "@A;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_md5 no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_md5 \
        --fastqout - | \
    grep -qw "@7fc56270e7a70fa81a5935b72eacbe29" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_md5 --sizeout conserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_md5 \
        --sizeout \
        --fastqout - | \
    grep -qw "@7fc56270e7a70fa81a5935b72eacbe29;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_sha1 no size annotations (size annotation in, without --sizeout)"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_sha1 \
        --fastqout - | \
    grep -qw "@6dcd4ce23d88e2ee9568ba546c007c63d9131c1b" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --relabel_sha1 --sizeout conserves size annotations"
printf ">s;size=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --quiet \
        --relabel_sha1 \
        --sizeout \
        --fastqout - | \
    grep -qw "@6dcd4ce23d88e2ee9568ba546c007c63d9131c1b;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--fasta2fastq --threads is accepted"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --threads 1 \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --threads > 1 triggers a warning (not multithreaded)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --threads 2 \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--fasta2fastq --xee is accepted"
printf ">s;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --xee \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --xee removes expected error annotations from input"
printf ">s;ee=1.00\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --xee \
        --quiet \
        --fastqout - | \
    grep -wq "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--fasta2fastq --xlength is accepted"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --xlength \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --xlength removes length annotations from input"
printf ">s;length=1\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --xlength \
        --quiet \
        --fastqout - | \
    grep -wq "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --xlength removes length annotations (input), lengthout adds them (output)"
printf ">s;length=2\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --xlength \
        --lengthout \
        --quiet \
        --fastqout - | \
    grep -wq "@s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

DESCRIPTION="--fasta2fastq --xsize is accepted"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --xsize \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq --xsize removes abundance annotations from input"
printf ">s;size=1\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --xsize \
        --quiet \
        --fastqout - | \
    grep -wq "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fasta2fastq rejects --fastaout"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq rejects --fastq_ascii"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastq_ascii 33 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq rejects --fastq_qmax"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastq_qmax 40 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq rejects --fastq_qmin"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --fastq_qmin 0 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fasta2fastq rejects --notrunclabels"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fasta2fastq - \
        --notrunclabels \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then
    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fasta2fastq <(printf ">s;size=100\nA\n") \
        --sizein \
        --quiet \
        --sizeout \
        --fastqout /dev/null
    DESCRIPTION="--fasta2fastq valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fasta2fastq valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#



exit 0
