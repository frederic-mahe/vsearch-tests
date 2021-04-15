#!/bin/bash -

## Print a header
SCRIPT_NAME="Tests inputs FASTA"
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

## use the first binary in $PATH by default, unless user wants
## to test another binary
VSEARCH=$(which vsearch 2> /dev/null)
[[ "${1}" ]] && VSEARCH="${1}"

DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] && success "${DESCRIPTION}" || failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 Fasta input                                 #
#                                                                             #
#*****************************************************************************#

## vsearch accepts an empty file
DESCRIPTION="vsearch handles empty files"
printf "" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

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
# 13: "\r"
# 32: SPACE
for i in 0 13 32 ; do
    DESCRIPTION="ascii character ${i} is allowed in fasta header (outside identifier)"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">aa;size=1; ${OCTAL}padding\nACGT\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done 

## ASCII character 10 (\n) is not allowed in fasta headers (outside identifier)
# 10: "\n"
DESCRIPTION="ascii character 10 is not allowed in fasta headers (outside identifier)"
OCTAL=$(printf "\%04o" 10)
echo -e ">aa;size=1; ${OCTAL}padding\nACGT\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## non-ASCII characters accepted in fasta identifiers
DESCRIPTION="non-ASCII characters accepted in fasta identifiers"
echo -e ">ø;size=1;\nACGT\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout -  &> /dev/null && \
    success "${DESCRIPTION}" || failure "${DESCRIPTION}"

## Define ASCII characters accepted in fasta sequences
# 10: "\n"
# 13: "\r"
# and ACGTUacgtu
# SPACE is not allowed
for i in 0 10 13 65 67 71 84 85 97 99 103 116 117 ; do
    DESCRIPTION="ascii character ${i} is allowed in sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">aaaa;size=1;\nAC${OCTAL}GT\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done

## Define ASCII characters not accepted in fasta sequences
for i in {1..9} 11 12 {14..64} 66 {68..70} {72..83} {86..96} 98 {100..102} {104..115} {118..127} ; do
    DESCRIPTION="ascii character ${i} is not allowed in sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">s;size=1;\nAC${OCTAL}GT\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done

## Vsearch aborts if fasta identifiers are not unique
DESCRIPTION="vsearch aborts if fasta headers are not unique"
echo -e ">a;size=10;\nACGT\n>a;size=10;\nAAGT\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

# ## Fasta headers can contain more than one underscore symbol
# DESCRIPTION="fasta headers can contain more than one underscore symbol"
# STATS=$(mktemp)
# IDENTIFIER="a_2_2"
# echo -e ">${IDENTIFIER}_3\nACGTACGT" | \
#     "${VSEARCH}" --sample_size 1 --fastaout - -s "${STATS}" &> /dev/null
# grep -qE "[[:blank:]]${IDENTIFIER}[[:blank:]]" "${STATS}" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"
# rm -f "${STATS}"

## Fasta header must contain an abundance value after being truncated
DESCRIPTION="vsearch aborts if fasta headers lacks abundance value"
echo -e ">a a;size=1;\nACGT" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch aborts if abundance value is not a number
DESCRIPTION="vsearch aborts if abundance value is not a number"
echo -e ">a;size=n;\nACGT" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch aborts if abundance value is zero
DESCRIPTION="vsearch aborts if abundance value is zero"
echo -e ">a;size=0;\nACGT" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch aborts if abundance value is negative
DESCRIPTION="vsearch aborts if abundance value is negative"
echo -e ">a;size=-1;\nACGT" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch accepts large abundance values (2^32 - 1)
DESCRIPTION="vsearch accepts large abundance values (up to 2^32 - 1)"
for POWER in {2..32} ; do
    printf ">s1;size=%d;\nA\n" $(( (1 << POWER) - 1 )) | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null || \
        failure "${DESCRIPTION}"
done && success "${DESCRIPTION}"

## vsearch accepts abundance values equal to 2^32
DESCRIPTION="vsearch accepts abundance values equal to 2^32"
printf ">s1_;size=%d;\nA\n" $(( 1 << 32 )) | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## vsearch accepts abundance values equal to 2^32 + 1
DESCRIPTION="vsearch accepts abundance values equal to 2^32 + 1"
printf ">s1;size=%d;\nA\n" $(( (1 << 32) + 1 )) | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 Fastq input                                 #
#                                                                             #
#*****************************************************************************#

## Print a header
SCRIPT_NAME="Tests inputs FASTQ"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Test empty sequence
DESCRIPTION="vsearch handles empty sequences"
echo -e "@a;size=10;\n+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
    success "${DESCRIPTION}" || failure "${DESCRIPTION}"

## Test empty header
DESCRIPTION="vsearch aborts on empty fastq headers"
echo -e "@;size=10\nACGT\n+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## Define ASCII characters accepted in fastq identifiers
DESCRIPTION="ascii characters 1-9, 11-12, 14-31, 33-127 allowed in fastq identifiers"
for i in {1..9} 11 12 {14..31} {33..127} ; do
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@aa${OCTAL}aa;size=1;\nACGT\n+\nGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null || \
        failure "ascii character ${i} allowed in fastq identifiers"
done && success "${DESCRIPTION}"

## Define ASCII characters not accepted in fastq identifiers
#  0: NULL
# 10: "\n"
# 13: "\r"
# 32: SPACE
for i in 0 10 13 32 ; do
    DESCRIPTION="ascii character ${i} is not allowed in fastq identifiers"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@aa${OCTAL}aa;size=1;\nACGT\n+\nGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done 

## Define ASCII characters accepted in fastq headers
#  0: NULL
# 13: "\r"
# 32: SPACE
for i in 0 13 32 ; do
    DESCRIPTION="ascii character ${i} is allowed in fastq header (outside identifier)"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@aa;size=1; ${OCTAL}padding\nACGT\n+\nGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done 

## ASCII character 10 (\n) is not allowed in fastq headers (outside identifier)
# 10: "\n"
DESCRIPTION="ascii character 10 is not allowed in fastq headers (outside identifier)"
OCTAL=$(printf "\%04o" 10)
echo -e "@aa;size=1; ${OCTAL}padding\nACGT\n+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## non-ASCII characters accepted in fastq identifiers
DESCRIPTION="non-ASCII characters accepted in fastq identifiers"
echo -e "@ø;size=1;\nACGT\n+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout -  &> /dev/null && \
    success "${DESCRIPTION}" || failure "${DESCRIPTION}"

## Define ASCII characters accepted in fastq sequences
# 10: "\n"
# 13: "\r"
# and ACGTUacgtu
# SPACE is not allowed
for i in 0 10 13 65 67 71 84 85 97 99 103 116 117 ; do
    DESCRIPTION="ascii character ${i} is allowed in fastq sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@aaaa;size=1;\nAC${OCTAL}GT\n+\nGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done

## Define ASCII characters not accepted in fastq sequences
for i in {1..9} 11 12 {14..64} 66 {68..70} {72..83} {86..96} 98 {100..102} {104..115} {118..127} ; do
    DESCRIPTION="ascii character ${i} is not allowed in fastq sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@s;size=1;\nAC${OCTAL}GT\n+\nGGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done

## Vsearch aborts if fastq identifiers are not unique
DESCRIPTION="vsearch aborts if fasta headers are not unique"
echo -e "@a;size=10;\nACGT\n+\nGGGG\n@a;size=10;\nAAGT\n+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## Fastq header must contain an abundance value after being truncated
DESCRIPTION="vsearch aborts if fastq headers lacks abundance value"
echo -e "@a a;size=1;\nACGT+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch aborts if abundance value is not a number
DESCRIPTION="vsearch aborts if abundance value is not a number"
echo -e "@a;size=n;\nACGT+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch aborts if abundance value is zero
DESCRIPTION="vsearch aborts if abundance value is zero"
echo -e "@a;size=0;\nACGT+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch aborts if abundance value is negative
DESCRIPTION="vsearch aborts if abundance value is negative"
echo -e "@a;size=-1;\nACGT\n+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch accepts large abundance values (2^32 - 1)
DESCRIPTION="vsearch accepts large abundance values (up to 2^32 - 1)"
for POWER in {2..32} ; do
    printf "@s1;size=%d;\nA\n+\nG\n" $(( (1 << POWER) - 1 )) | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null || \
        failure "${DESCRIPTION}"
done && success "${DESCRIPTION}"

## vsearch accepts abundance values equal to 2^32
DESCRIPTION="vsearch accepts abundance values equal to 2^32"
printf "@s1_;size=%d;\nA\n+\nG\n" $(( 1 << 32 )) | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## vsearch accepts abundance values equal to 2^32 + 1
DESCRIPTION="vsearch accepts abundance values equal to 2^32 + 1"
printf "@s1;size=%d;\nA\n+\nG\n" $(( (1 << 32) + 1 )) | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

exit 0
