#!/bin/bash -

## Print a header
SCRIPT_NAME="SFF conversion"
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
    printf "1"

    # ... plus padding to fill-in 8 bytes (7 null bytes)
    printf "%b" "\x00\x00\x00\x00\x00\x00\x00"

    # flow strength is 100 (64 in hex, value * 1.0 / 100.0, uint16)
    printf "%b" "\x00\x64"

    # flow index per base is 1 (uint8)
    printf "%b" "\x01"

    # sequence is a T (lower case bases are before and after the clipping point, uint8)
    printf "T"

    ## quality score is 23 (17 in hex, uint8)...
    printf "%b" "\x17"

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
#                                --sff_convert                                #
#                                                                             #
#*****************************************************************************#

## sff_convert requires an input file
DESCRIPTION="sff_convert requires an input file"
"${VSEARCH}" --sff_convert &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## sff_convert requires an input file and an output file
DESCRIPTION="sff_convert requires an input file and an output file"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
DESCRIPTION="sff_convert fails if the output file is not specified"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## sff_convert supports the option list delimiter "--" and creates file "-test"
DESCRIPTION="sff_convert supports the option list delimiter \"--\""
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout -- -test &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## sff_convert messages are not witten to stdout
DESCRIPTION="sff_convert messages are not witten to stdout"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## sff_convert messages are witten to stderr
DESCRIPTION="sff_convert messages are witten to stderr"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## quiet eliminates messages to stderr
DESCRIPTION="quiet eliminates messages to stderr"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --quiet 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## input can be a redirection
DESCRIPTION="input can be a redirection"
"${VSEARCH}" \
    --sff_convert - \
    --quiet \
    --fastqout /dev/null < "${SFF}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## input can be a pipe
DESCRIPTION="input can be a pipe"
cat "${SFF}" | \
    "${VSEARCH}" \
        --sff_convert - \
        --quiet \
        --fastqout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## input can be a process substitution
DESCRIPTION="input can be a process substitution"
"${VSEARCH}" \
    --sff_convert <(cat "${SFF}") \
    --quiet \
    --fastqout /dev/null \
    && success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## input can be a named pipe
DESCRIPTION="input can be a named pipe"
mkfifo my_pipe
"${VSEARCH}" \
    --sff_convert - \
    --fastqout - &> /dev/null < my_pipe && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}" &
cat "${SFF}" > my_pipe
rm my_pipe

## log writes messages to a file
DESCRIPTION="log writes messages to a file (or stdout)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --log - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## log prevents messages from being written to stderr (?)
DESCRIPTION="log prevents messages from being written to stderr (?)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout /dev/null \
    --log /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## sff_convert produces a proper fastq file
DESCRIPTION="sff_convert produces a proper fastq file"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout - | \
    "${VSEARCH}" \
        --fastq_stats - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## sff_convert produces a fastq file with a quality encoding of 33
DESCRIPTION="sff_convert produces a fastq file with a quality encoding of 33"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastqout - | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "^Guess.*33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_asciiout controls the quality encoding (33)
DESCRIPTION="fastq_asciiout controls the quality encoding (33)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_asciiout 33 \
    --fastqout - | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "^Guess.*33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_asciiout controls the quality encoding (64)
DESCRIPTION="fastq_asciiout controls the quality encoding (64)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_asciiout 64 \
    --fastqout - | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "^Guess.*64$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_asciiout requires an argument
DESCRIPTION="fastq_asciiout requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_asciiout &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## fastq_asciiout accepts the value 33
DESCRIPTION="fastq_asciiout accepts the value 33"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastq_asciiout 33 \
    --fastqout - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_asciiout accepts the value 64
DESCRIPTION="fastq_asciiout accepts the value 64"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastq_asciiout 64 \
    --fastqout - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_asciiout rejects other values
DESCRIPTION="fastq_asciiout rejects other values"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastq_asciiout 42 \
    --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## fastq_qminout requires an argument
DESCRIPTION="fastq_qminout requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qminout &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## fastq_qminout accepts values ranging from 0 to 41 (test with 0)
DESCRIPTION="fastq_qminout accepts values ranging from 0 to 41 (test with 0)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qminout 0 &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_qminout accepts values ranging from 0 to 41 (test with 41)
DESCRIPTION="fastq_qminout accepts values ranging from 0 to 41 (test with 41)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qminout 41 &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## sum of arguments to --fastq_asciiout 33 and --fastq_qminout must be no less than 33
DESCRIPTION="sum of arguments to --fastq_asciiout 33 and --fastq_qminout must be no less than 33"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastq_asciiout 33 \
    --fastqout - \
    --fastq_qminout \-1 &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## sum of arguments to --fastq_asciiout 64 and --fastq_qminout must be no less than 64
DESCRIPTION="sum of arguments to --fastq_asciiout 64 and --fastq_qminout must be no less than 64"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastq_asciiout 64 \
    --fastqout - \
    --fastq_qminout \-1 &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}" # negative Q values does not make any
                                 # sense, so there should be no Q
                                 # values inferior to the offset

## fastq_qmaxout requires an argument
DESCRIPTION="fastq_qmaxout requires an argument"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qmaxout &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## fastq_qmaxout accepts values ranging from 0 to 41 (test with 0)
DESCRIPTION="fastq_qmaxout accepts values ranging from 0 to 41 (test with 0)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qmaxout 0 &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_qmaxout accepts values ranging from 0 to 41 (test with 41)
DESCRIPTION="fastq_qmaxout accepts values ranging from 0 to 41 (test with 41)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qmaxout 41 &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## sum of arguments to --fastq_asciiout (33) and --fastq_qmaxout must be no more than 126
DESCRIPTION="sum of fastq_asciiout (33) and fastq_qmaxout must be < 127"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_asciiout 33 \
    --fastq_qmaxout 93 &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
DESCRIPTION="sum of fastq_asciiout (33) and fastq_qmaxout must be < 127 (else error)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_asciiout 33 \
    --fastq_qmaxout 94 &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"  # 0 <= qminout <= 93
                                  # 0 <= qmaxout <= 93

## fastq_qminout and fastq_qmaxout can be set to 93 at most
DESCRIPTION="fastq_qminout and fastq_qmaxout can be set to 93 at most"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qminout 93 \
    --fastq_qmaxout 93 &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
DESCRIPTION="fastq_qminout and fastq_qmaxout can be set to 93 at most (else error)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qminout 94 \
    --fastq_qmaxout 94 &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## sum of arguments to --fastq_asciiout (64) and --fastq_qmaxout must be no more than 126
DESCRIPTION="sum of fastq_asciiout (64) and fastq_qmaxout must be < 127"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_asciiout 64 \
    --fastq_qmaxout 62 &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
DESCRIPTION="sum of fastq_asciiout (64) and fastq_qmaxout must be < 127 (else error)"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_asciiout 64 \
    --fastq_qmaxout 63 &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## fastq_qminout can be equal to fastq_qmaxout
DESCRIPTION="fastq_qminout can be equal to fastq_qmaxout"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qminout 10 \
    --fastq_qmaxout 10 &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_qminout cannot be greater than fastq_qmaxout
DESCRIPTION="fastq_qminout cannot be greater than fastq_qmaxout"
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --fastqout - \
    --fastq_qminout 11 \
    --fastq_qmaxout 10 &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## fastq_qminout controls the minimal quality value
DESCRIPTION="fastq_qminout controls the minimal quality value"
MIN=$("${VSEARCH}" \
          --sff_convert "${SFF}" \
          --quiet \
          --fastqout - | \
          "${VSEARCH}" \
              --fastq_chars - 2>&1 | \
          grep -Eo "fastq_qmin [0-9]+" | \
          cut -d " " -f 2)
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qminout $(( MIN + 1 )) \
    --fastqout - | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "fastq_qmin 24" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset MIN

## fastq_qmaxout controls the maximal quality value
DESCRIPTION="fastq_qmaxout controls the maximal quality value"
MAX=$("${VSEARCH}" \
          --sff_convert "${SFF}" \
          --quiet \
          --fastqout - | \
          "${VSEARCH}" \
              --fastq_chars - 2>&1 | \
          grep -Eo "fastq_qmax [0-9]+" | \
          cut -d " " -f 2)
"${VSEARCH}" \
    --sff_convert "${SFF}" \
    --quiet \
    --fastq_qmaxout $(( MAX - 10 )) \
    --fastqout - | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "fastq_qmax 13" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset MAX

## valgrind detects no errors
if which valgrind > /dev/null ; then
    DESCRIPTION="valgrind detects no errors"
    valgrind \
        "${VSEARCH}" \
        --sff_convert "${SFF}" \
        --fastqout /dev/null 2>&1 | \
        grep -q "ERROR SUMMARY: 0 errors" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
fi

## fuzzing: stopped after 15 times 0.5 Billion executions of afl-fuzz 2.52b

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

rm "${SFF}"

# TODO: create a minimal file with a lowercase nucleotide

exit 0
