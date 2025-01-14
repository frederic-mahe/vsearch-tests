#!/bin/bash -

## Print a header
SCRIPT_NAME="SFF_convert"
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

## create a tiny test file
SFF=$(mktemp)
# quality offset is +33 (no ambiguity),
# https://github.com/torognes/vsearch/issues/352
(## header ----------------------------------------------

    # magic number (string ".sff", uint32)
    printf ".sff"

    # version number (integer 1, 4 * uint8)
    printf "%b" "\x00\x00\x00\x01"

    # index offset (no index, so null uint64)
    printf "%b" "\x00\x00\x00\x00\x00\x00\x00\x00"

    # index length (no index, so null uint32)
    printf "%b" "\x00\x00\x00\x00"

    # number of reads (integer 1, uint32)
    printf "%b" "\x00\x00\x00\x01"

    # header length is 40 bytes (28 in hex, uint16)
    printf "%b" "\x00\x28"

    # key length is 4 (uint16)
    printf "%b" "\x00\x04"

    # number of flows per read is 1 (uint16)
    printf "%b" "\x00\x01"

    # flowgram format code (1, uint8)
    printf "%b" "\x01"

    # flows chars (usually "TACG" repeated number of flows / 4, here
    # only "T", uint8)
    printf "T"

    # key sequence (TCAG)...
    printf "TCAG"

    # ... plus padding to fill-in 8 bytes (4 null bytes)
    printf "%b" "\x00\x00\x00\x00"
    
    ## read ----------------------------------------------

    # read header length (usually 32 characters, here 24 characters,
    # so an hex value of 18, uint16)
    printf "%b" "\x00\x18"

    # length of read name is 1 character (uint8)
    printf "%b" "\x00\x01"

    # number of bases before clipping is 1 (uint32)
    printf "%b" "\x00\x00\x00\x01"

    # clip qual left is 1 (position of the first base to be included
    # after clipping, uint16)
    printf "%b" "\x00\x01"

    # clip qual right is 1 (position of the last base before clipping,
    # uint16)
    printf "%b" "\x00\x01"

    # clip adapter left is 0 (uint16)
    printf "%b" "\x00\x00"

    # clip adapter right is 0 (uint16)
    printf "%b" "\x00\x00"

    # read name is "1" (uint8)...
    printf "s"

    # ... plus padding to fill-in 8 bytes (7 null bytes)
    printf "%b" "\x00\x00\x00\x00\x00\x00\x00"

    # flow strength is 100 (64 in hex, value * 1.0 / 100.0, uint16)
    printf "%b" "\x00\x64"

    # flow index per base is 1 (uint8)
    printf "%b" "\x01"

    # sequence is a T (lower case bases are before and after the clipping point, uint8)
    printf "T"

    ## quality score is 40 (28 in hex, uint8)...
    printf "%b" "\x28"

    # ... plus padding to fill-in 8 bytes (3 null bytes)
    printf "%b" "\x00\x00\x00"
) > "${SFF}"

# The second week of January 2019, this minimal input file was used in
# combination with afl-fuzz v2.52b to try to trigger crashes when
# parsing SFF files. A master thread and 14 subordonate threads were
# launch in parallel, performing a total of 7.5 billion
# excecutions. No crash was found.


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------------- fastqout

DESCRIPTION="--sff_convert requires --fastqout"
"${VSEARCH}" \
    --sff_convert "${SFF}" 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert accepts --fastqout"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastqout writes to output file (file is not empty)"
TMP=$(mktemp)
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout ${TMP} 2> /dev/null
[[ -s ${TMP} ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--sff_convert --fastqout fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--sff_convert --fastqout can write to /dev/stdout (stream is not empty)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/stdout 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastqout can write to '-' (stream is not empty)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastqout can write to process substitution (stream is not empty)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout >(grep -q "." && \
                     success "${DESCRIPTION}" || \
                         failure "${DESCRIPTION}"
                ) 2> /dev/null

DESCRIPTION="--sff_convert --fastqout outputs in fastq format"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - 2> /dev/null | \
    tr -d "\n" | \
    grep -wq "@sT+I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--sff_convert requires an input file"
"${VSEARCH}" \
    --sff_convert 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert can read from /dev/stdin (pipe)"
cat "${SFF}" | \
    "${VSEARCH}" \
        --sff_convert /dev/stdin \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert dash is a placeholder for /dev/stdin"
cat "${SFF}" | \
    "${VSEARCH}" \
        --sff_convert - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert can read from /dev/stdin (redirection)"
"${VSEARCH}" \
    --sff_convert /dev/stdin \
    --fastqout /dev/null 2> /dev/null < "${SFF}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert can read from a process substitution"
"${VSEARCH}" \
    --sff_convert <(cat "${SFF}") \
    --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert can read from a named pipe (direct)"
mkfifo my_pipe
"${VSEARCH}" \
    --sff_convert my_pipe \
    --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}" &
cat "${SFF}" > my_pipe
rm -f my_pipe

DESCRIPTION="--sff_convert can read from a named pipe (redirection)"
mkfifo my_pipe
"${VSEARCH}" \
    --sff_convert - \
    --fastqout /dev/null 2> /dev/null < my_pipe && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}" &
cat "${SFF}" > my_pipe
rm -f my_pipe

DESCRIPTION="--sff_convert rejects empty input"
printf "" | \
    "${VSEARCH}" \
        --sff_convert - \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert does not write messages to stdout"
"${VSEARCH}" \
    --sff_convert - \
    --fastqout /dev/null 2> /dev/null < "${SFF}" | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert writes messages to stderr"
"${VSEARCH}" \
    --sff_convert - \
    --fastqout /dev/null 2>&1 > /dev/null < "${SFF}" | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------ stderr messages

## sff_convert reports:
# Number of reads: 1
# Flows per read:  1
# Key sequence:    CAG  <= wrong? should be 'T' with our minimal example?


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------------- sff_clip

# ## no clipping by default (lowercase nucleotides in the output)
# DESCRIPTION="no clipping by default (lowercase nucleotides in the output)"
# "${VSEARCH}" \
#     --sff_convert "${SFF}" \
#     --quiet \
#     --fastqout - | \
#     "${VSEARCH}" \
#         --fastx_filter - \
#         --quiet \
#         --fastaout - | \
#     grep -v "^>" | \
#     grep -qE "[[:lower:]]" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"

# ## sff_clip outputs uppercase nucleotides
# DESCRIPTION="sff_clip outputs uppercase nucleotides"
# "${VSEARCH}" \
#     --sff_convert "${SFF}" \
#     --quiet \
#     --sff_clip \
#     --fastqout - | \
#     "${VSEARCH}" \
#         --fastx_filter - \
#         --quiet \
#         --fastaout - | \
#     grep -v "^>" | \
#     grep -qE "[[:upper:]]" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"

# ## sff_clip eliminates all lowercase nucleotides (both ends are clipped)
# DESCRIPTION="sff_clip eliminates all lowercase nucleotides (both ends are clipped)"
# "${VSEARCH}" \
#     --sff_convert "${SFF}" \
#     --quiet \
#     --sff_clip \
#     --fastqout - | \
#     "${VSEARCH}" \
#         --fastx_filter - \
#         --quiet \
#         --fastaout - | \
#     grep -v "^>" | \
#     grep -qE "[[:lower:]]" && \
#     failure "${DESCRIPTION}" || \
#         success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## for each secondary option below, write two tests: 1) accepts
## option, 2) check basic option effect (if applicable)

## ------------------------------------------------------------- fastq_asciiout

## The ascii character 'I' has a value of 73, which encodes a quality
## of 40 when the offset is 33
DESCRIPTION="--sff_convert default quality offset is 33"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout - | \
    awk 'NR == 4 {exit ($1 == "I") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_asciiout is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_asciiout 33 \
    --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_asciiout controls the quality encoding (33)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_asciiout 33 \
    --fastqout - | \
    awk 'NR == 4 {exit ($1 == "I") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## The ascii character 'h' has a value of 104, which encodes a quality
## of 40 when the offset is 64
DESCRIPTION="--sff_convert --fastq_asciiout controls the quality encoding (64)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_asciiout 64 \
    --fastqout - | \
    awk 'NR == 4 {exit ($1 == "h") ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_asciiout rejects values other than 33 and 64"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastq_asciiout 42 \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_asciiout requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastq_asciiout \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------- fastq_qmaxout

DESCRIPTION="--sff_convert --fastq_qmaxout is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qmaxout 40 \
    --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qmaxout requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qmaxout 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## 93 + 33 = 126 (last printable character)
DESCRIPTION="--sff_convert --fastq_qmaxout accepts values ranging from 0 to 93 (0)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qmaxout 0 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qmaxout accepts values ranging from 0 to 93 (93)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qmaxout 93 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qmaxout rejects negative values"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qmaxout -1 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qmaxout rejects values > 93"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qmaxout 94 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## 62 + 64 = 126 (last printable character)
DESCRIPTION="--sff_convert --fastq_qmaxout accepts values ranging from 0 to 62 (0, +64)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_asciiout 64 \
    --fastq_qmaxout 0 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qmaxout accepts values ranging from 0 to 62 (62, +64)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_asciiout 64 \
    --fastq_qmaxout 62 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qmaxout rejects values > 62 (+64)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_asciiout 64 \
    --fastq_qmaxout 63 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## output Q = min(Q, qmaxout), so output Q <= qmaxout
DESCRIPTION="--sff_convert --fastq_qmaxout keeps lower Q values"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qmaxout 41 \
    --fastqout - | \
    grep -qw "I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qmaxout keeps equal Q values"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qmaxout 40 \
    --fastqout - | \
    grep -qw "I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qmaxout caps higher Q values"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qmaxout 39 \
    --fastqout - | \
    grep -qw "H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- fastq_qminout

DESCRIPTION="--sff_convert --fastq_qminout is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qminout 40 \
    --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qminout 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout accepts values ranging from 0 to qmaxout (0)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qminout 0 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout accepts values ranging from 0 to qmaxout (41)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qminout 41 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## 93 + 33 = 126 (last printable character)
DESCRIPTION="--sff_convert --fastq_qminout accepts values ranging from 0 to qmaxout (93)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qmaxout 93 \
    --fastq_qminout 93 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout cannot be greater than --fastq_qmaxout"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qmaxout 41 \
    --fastq_qminout 42 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout can be equal to --fastq_qmaxout"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qmaxout 10 \
    --fastq_qminout 10 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout can be smaller than --fastq_qmaxout"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qmaxout 1 \
    --fastq_qminout 0 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout rejects negative values"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_qminout -1 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## 62 + 64 = 126 (last printable character)
DESCRIPTION="--sff_convert --fastq_qminout accepts values ranging from 0 to 62 (0, +64)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_asciiout 64 \
    --fastq_qminout 0 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout accepts values ranging from 0 to 62 (62, +64)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --fastq_asciiout 64 \
    --fastq_qmaxout 62 \
    --fastq_qminout 62 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## output Q = max(Q, qminout), so output Q >= qminout
DESCRIPTION="--sff_convert --fastq_qminout caps lower Q values"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qminout 41 \
    --fastqout - | \
    grep -qw "J" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout keeps equal Q values"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qminout 40 \
    --fastqout - | \
    grep -qw "I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --fastq_qminout keeps higher Q values"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qminout 39 \
    --fastqout - | \
    grep -qw "I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--sff_convert --label_suffix is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --label_suffix "suffix" \
    --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --label_suffix requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --label_suffix 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --label_suffix adds a suffix"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --label_suffix "suffix" \
    --fastqout - | \
    grep -qw "@ssuffix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --label_suffix can be empty"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --label_suffix "" \
    --fastqout - | \
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--sff_convert --lengthout is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --lengthout \
    --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --lengthout adds length annotations to headers"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --lengthout \
    --fastqout - | \
    grep -wq "@s;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --lengthout --sizeout add annotations to output (size first)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --lengthout \
    --sizeout \
    --fastqout - | \
    grep -wq "@s;size=1;length=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--sff_convert --log is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --log /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --log requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --log 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --log writes messages to stdout"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --log - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --log writes messages to a file"
TMP=$(mktemp)
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --log ${TMP} 2> /dev/null
grep -q "." ${TMP} && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f ${TMP}
unset TMP

DESCRIPTION="--sff_convert --log fails if unable to open output file for writing"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --log ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

## only quiet prevents messages to stderr
DESCRIPTION="--sff_convert --log does not prevent messages from being written to stderr"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--sff_convert --no_progress is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --no_progress 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--sff_convert --no_progress removes progressive report on stderr (no visible effect)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --no_progress \
    --fastqout /dev/null 2>&1 | \
    grep -iq "^converting" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--sff_convert --quiet is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --quiet && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --quiet eliminates all (normal) messages to stderr"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --quiet 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --quiet allows error messages to be sent to stderr"
printf "" | \
    "${VSEARCH}" \
        --sff_convert - \
        --fastqout /dev/null \
        --quiet 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--sff_convert --relabel is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --relabel "label" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --relabel requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --relabel 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --relabel renames sequence (label + ticker)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --relabel "label" \
    --fastqout - 2> /dev/null | \
    grep -qw "@label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --relabel accepts empty label (only ticker)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --relabel "" \
    --fastqout - 2> /dev/null | \
    grep -qw "@1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --relabel cannot combine with --relabel_md5"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --relabel "label" \
    --relabel_md5 \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --relabel cannot combine with --relabel_sha1"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --relabel "label" \
    --relabel_sha1 \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--sff_convert --relabel_keep is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --relabel "label" \
    --relabel_keep && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --relabel_keep keeps original sequence name"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --relabel "label" \
    --relabel_keep \
    --fastqout - | \
    grep -qw "@label1 s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--sff_convert --relabel_md5 is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --relabel_md5 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --relabel_md5 relabels using MD5 hash of sequence"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --relabel_md5 \
    --fastqout - | \
    grep -qw "@b9ece18c950afbfa6b0fdbfa4ff731d3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--sff_convert --relabel_self is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --relabel_self && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --relabel_self relabels using sequence as label"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --relabel_self \
    --fastqout - | \
    grep -qw "@T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--sff_convert --relabel_sha1 is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --relabel_sha1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --relabel_sha1 relabels using MD5 hash of sequence"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --relabel_sha1 \
    --fastqout - | \
    grep -qw "@c2c53d66948214258a26ca9ca845d7ac0c17f8e7" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--sff_convert --sample is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --sample "ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --sample requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout /dev/null \
    --sample 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--sff_convert --sample adds sample name to sequence headers"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --sample "ABC" \
    --fastqout - 2> /dev/null | \
    grep -qw "@s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --sample accepts empty string"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --sample "" \
    --fastqout - 2> /dev/null | \
    grep -qw "@s;sample=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

# Normal case

# Complex cases:
# When using --relabel, --relabel_self, --relabel_md5 or
# --relabel_sha1, preserve and report abundance annotations to the
# output fastq file (using the pattern ';size=integer;').


## -------------------------------------------------------------------- threads

DESCRIPTION="--sff_convert --threads is accepted"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --threads 1 \
    --quiet \
    --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--sff_convert --threads > 1 triggers a warning (not multithreaded)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --threads 2 \
    --quiet \
    --fastqout /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#


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
        --sff_convert "${SFF}" \
        --log /dev/null \
        --fastqout /dev/null 2> /dev/null
    DESCRIPTION="--sff_convert valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--sff_convert valgrind (no errors)"
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

# - fuzzing: stopped after 15 times 0.5 Billion executions of afl-fuzz 2.52b, no issue.
# - real-life: test against all ENA avalaible SFF files (60,011 files, 2019-01-22), no issue.

# TODO: check coverage
# TODO: create a minimal file with a lowercase nucleotide
# TODO: vsearch should emit a warning when --sample "" (empty string)?


rm "${SFF}"

exit 0
