#!/bin/bash -

## Print a header
SCRIPT_NAME="test fasta input"
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

DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## vsearch accepts an empty file
DESCRIPTION="vsearch handles empty files"
printf "" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 Fasta input                                 #
#                                                                             #
#*****************************************************************************#

## Test empty sequence
DESCRIPTION="vsearch handles empty sequences"
printf ">s\n\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Test empty header
DESCRIPTION="vsearch accepts empty fasta headers"
printf ">\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Define ASCII characters not accepted in fasta identifiers
# Oct   Dec   Hex   Char
# ────────────────────────────────────────
# 001   1     01    SOH (start of heading)
# 002   2     02    STX (start of text)
# 003   3     03    ETX (end of text)
# 004   4     04    EOT (end of transmission)
# 005   5     05    ENQ (enquiry)
# 006   6     06    ACK (acknowledge)
# 007   7     07    BEL '\a' (bell)
# 010   8     08    BS  '\b' (backspace)
# 013   11    0B    VT  '\v' (vertical tab)
# 014   12    0C    FF  '\f' (form feed)
# 016   14    0E    SO  (shift out)
# 017   15    0F    SI  (shift in)
# 020   16    10    DLE (data link escape)
# 021   17    11    DC1 (device control 1)
# 022   18    12    DC2 (device control 2)
# 023   19    13    DC3 (device control 3)
# 024   20    14    DC4 (device control 4)
# 025   21    15    NAK (negative ack.)
# 026   22    16    SYN (synchronous idle)
# 027   23    17    ETB (end of trans. blk)
# 030   24    18    CAN (cancel)
# 031   25    19    EM  (end of medium)
# 032   26    1A    SUB (substitute)
# 033   27    1B    ESC (escape)
# 034   28    1C    FS  (file separator)
# 035   29    1D    GS  (group separator)
# 036   30    1E    RS  (record separator)
# 037   31    1F    US  (unit separator)
# 177   127   7F    DEL
for i in {1..8} 11 12 {14..31} 127 ; do
    DESCRIPTION="ascii character ${i} is not allowed in fasta identifiers"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">s${OCTAL}s\nA\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done 
unset OCTAL

## Define ASCII characters accepted in fasta identifiers
#  0: NULL
#  9: '\t'
# 10: '\n'
# 13: '\r'
# 32: space
# 33-126: all visible characters
for i in 0 9 10 13 32 {33..126} ; do
    DESCRIPTION="ascii character ${i} allowed in fasta identifiers"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">s${OCTAL}s\nA\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OCTAL

## Define ASCII characters accepted in fasta headers
#  0: NULL
# 10: "\n"
# 13: "\r"
# 32: SPACE
for i in 0 9 10 13 {32..126} ; do
    DESCRIPTION="ascii character ${i} is allowed in fasta header (outside identifier)"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">s ${OCTAL}s\nA\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done 
unset OCTAL

## Define ASCII characters not accepted in fasta headers
# 10: "\n"
# 13: "\r"
# 32: SPACE
for i in {1..8} 11 12 {14..31} 127 ; do
    DESCRIPTION="ascii character ${i} is not allowed in fasta header (outside identifier)"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">s ${OCTAL}s\nA\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done 
unset OCTAL

## non-ASCII characters accepted in fasta identifiers
DESCRIPTION="non-ASCII characters accepted in fasta identifiers"
echo -e ">ø\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Define ASCII characters accepted in fasta sequences
# 10: "\n"
# 13: "\r"
# and ACGTUacgtu
for i in 0 {9..13} {32..44} {47..127} ; do
    DESCRIPTION="ascii character ${i} is allowed in fasta sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">s\nA${OCTAL}A\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
            success "${DESCRIPTION}" || \
                failure "${DESCRIPTION}"
done
unset OCTAL

## Define ASCII characters not accepted in fasta sequences
# most invisible chars
# 45: '-'
# 46: '.'
for i in {1..8} {14..31} 45 46 ; do
    DESCRIPTION="ascii character ${i} is not allowed in fasta sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">s\nA${OCTAL}A\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OCTAL

## vsearch accepts duplicated fasta identifiers
DESCRIPTION="vsearch accepts duplicated fasta identifiers"
printf ">s\nA\n>s\nT\n" | \
            "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 Fastq input                                 #
#                                                                             #
#*****************************************************************************#

## Print a header
SCRIPT_NAME="test fastq input"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Test empty sequence
DESCRIPTION="vsearch handles empty fastq entries"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Test empty header
DESCRIPTION="vsearch accepts empty fastq headers"
printf "@\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# always truncate headers at first "\0" or "\n" or "\r"
DESCRIPTION="vsearch rejects multi-line fastq headers (LF)"
printf "@s\nheader\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="vsearch truncates fastq headers after CR"
printf "@s\rheader\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastqout - | \
    grep -q "header" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="vsearch truncates fastq headers after NULL char"
printf "@s\0header\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastqout - | \
    grep -q "header" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## Define ASCII characters not accepted in fastq identifiers
# Oct   Dec   Hex   Char
# ────────────────────────────────────────
# 001   1     01    SOH (start of heading)
# 002   2     02    STX (start of text)
# 003   3     03    ETX (end of text)
# 004   4     04    EOT (end of transmission)
# 005   5     05    ENQ (enquiry)
# 006   6     06    ACK (acknowledge)
# 007   7     07    BEL '\a' (bell)
# 010   8     08    BS  '\b' (backspace)
# 012   10    0A    LF  '\n' (new line)
# 013   11    0B    VT  '\v' (vertical tab)
# 014   12    0C    FF  '\f' (form feed)
# 016   14    0E    SO  (shift out)
# 017   15    0F    SI  (shift in)
# 020   16    10    DLE (data link escape)
# 021   17    11    DC1 (device control 1)
# 022   18    12    DC2 (device control 2)
# 023   19    13    DC3 (device control 3)
# 024   20    14    DC4 (device control 4)
# 025   21    15    NAK (negative ack.)
# 026   22    16    SYN (synchronous idle)
# 027   23    17    ETB (end of trans. blk)
# 030   24    18    CAN (cancel)
# 031   25    19    EM  (end of medium)
# 032   26    1A    SUB (substitute)
# 033   27    1B    ESC (escape)
# 034   28    1C    FS  (file separator)
# 035   29    1D    GS  (group separator)
# 036   30    1E    RS  (record separator)
# 037   31    1F    US  (unit separator)
# 177   127   7F    DEL
for i in {1..8} 10 11 12 {14..31} 127 ; do
    DESCRIPTION="ascii character ${i} is not allowed in fastq identifiers"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@s${OCTAL}s\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done 
unset OCTAL

## Define ASCII characters accepted in fastq identifiers
#  0: NULL
#  9: '\t'
# 13: '\r'
# 32: space
# 33-126: all visible characters
for i in 0 9 13 32 {33..126} ; do
    DESCRIPTION="ascii character ${i} allowed in fastq identifiers"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@s${OCTAL}s\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset OCTAL

## Define ASCII characters accepted in fastq headers
#  0: NULL
#  9: "\t"
# 13: "\r"
# 32: SPACE
for i in 0 9 13 {32..126} ; do
    DESCRIPTION="ascii character ${i} is allowed in fastq header (outside identifier)"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@s ${OCTAL}s\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done 
unset OCTAL

## Define ASCII characters not accepted in fastq headers
# 10: "\n"
# 11: "\v"
# 12: "\f"
for i in {1..8} 10 11 12 {14..31} 127 ; do
    DESCRIPTION="ascii character ${i} is not allowed in fastq header (outside identifier)"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@s ${OCTAL}s\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done 
unset OCTAL

DESCRIPTION="report illegal ascii characters in fastq identifiers (fatal error)"
printf "@s\b\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -iq "fatal" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="report illegal ascii characters in fastq identifiers (character number)"
printf "@s\b\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -iq "character no 8" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="report illegal ascii characters in fastq identifiers (line number # 1)"
printf "@s\b\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -iq "line 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="report illegal ascii characters in fastq identifiers (line number # 7)"
printf "@s1\nA\nA\nA\n+\nIII\n@s2\b\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -iq "line 7" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## non-ASCII characters accepted in fastq identifiers
DESCRIPTION="non-ASCII characters accepted in fastq identifiers"
echo -e "@ø\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="keep non-ASCII characters in fastq identifiers"
printf "@søs\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -wq "@søs" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="warn about non-ASCII characters in fastq identifiers"
printf "@søs\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="warn about non-ASCII characters in fastq identifiers (character number)"
printf "@søs\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -iq "Character no 195" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="warn about non-ASCII characters in fastq identifiers (line number 1)"
printf "@søs\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -iq "line 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="warn about non-ASCII characters in fastq identifiers (line number 7)"
printf "@s1\nA\nA\nA\n+\nIII\n@søs\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastx_uniques - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -iq "line 7" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Define ASCII characters accepted in fastq sequences
# ACGTUacgtu
for i in {65..68} 71 72 75 77 78 82 83 84 85 86 87 89 97 98 99 100 103 104 107 109 110 114 115 116 117 118 119 121 ; do
    DESCRIPTION="ascii character ${i} is allowed in fastq sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@s\nA${OCTAL}A\n+\nIII\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
            success "${DESCRIPTION}" || \
                failure "${DESCRIPTION}"
done
unset OCTAL

## Define ASCII characters not accepted in fastq sequences
# most invisible chars
# 45: '-'
# 46: '.'
for i in {0..64} 127 ; do
    DESCRIPTION="ascii character ${i} is not allowed in fastq sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@s\nA${OCTAL}A\n+\nIII\n" | \
        "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OCTAL

## vsearch accepts duplicated fastq identifiers
DESCRIPTION="vsearch accepts duplicated fastq identifiers"
printf "@s\nA\n+\nI\n@s\nT\n+\nI\n" | \
            "${VSEARCH}" \
            --fastx_filter - \
            --quiet \
            --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

exit 0
