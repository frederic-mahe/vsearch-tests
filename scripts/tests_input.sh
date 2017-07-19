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
#                                 Fasta input                                 #
#                                                                             #
#*****************************************************************************#

## Test empty sequence
DESCRIPTION="vsearch handles empty sequences"
echo -e ">a;size=10;\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    success "${DESCRIPTION}" || failure "${DESCRIPTION}"

## Test empty header
DESCRIPTION="vsearch aborts on empty fasta headers"
echo -e ">;size=10\nACGT\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"


# ## Clustering with only one sequence is accepted
# DESCRIPTION="clustering with only one sequence is accepted"
# echo -e ">a;size=10;\nACGNT\n" | \
#     "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
#     success "${DESCRIPTION}" || failure "${DESCRIPTION}"

# ## Clustering sequences of length 1 should work with d > 1 too (shorter than kmers)
# DESCRIPTION="clustering a sequence shorter than kmer length is accepted"
# echo -e ">a;size=10;\nA" | \
#     "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
#     success "${DESCRIPTION}" || failure "${DESCRIPTION}"

## Define ASCII characters accepted in fastq identifiers
DESCRIPTION="ascii characters 1-9, 11-12, 14-31, 33-127 allowed in fastq identifiers"
for i in {1..9} 11 12 {14..31} {33..127} ; do
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">aa${OCTAL}aa;size=1;\nACGT\n+\nGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null || \
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
    echo -e ">aa${OCTAL}aa;size=1;\nACGT\n" | \
        "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
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
    echo -e ">aa;size=1; ${OCTAL}padding\nACGT\n" | \
        "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done 

## ASCII character 10 (\n) is not allowed in fastq headers (outside identifier)
# 10: "\n"
DESCRIPTION="ascii character 10 is not allowed in fastq headers (outside identifier)"
OCTAL=$(printf "\%04o" 10)
echo -e ">aa;size=1; ${OCTAL}padding\nACGT\n" | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## non-ASCII characters accepted in fastq identifiers
DESCRIPTION="non-ASCII characters accepted in fastq identifiers"
echo -e ">ø;size=1;\nACGT\n" | \
    "${VSEARCH}" --sample_size 1 --fastqout -  &> /dev/null && \
    success "${DESCRIPTION}" || failure "${DESCRIPTION}"

## Define ASCII characters accepted in fastq sequences
# 10: "\n"
# 13: "\r"
# and ACGTUacgtu
# SPACE is not allowed
for i in 0 10 13 65 67 71 84 85 97 99 103 116 117 ; do
    DESCRIPTION="ascii character ${i} is allowed in sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">aaaa;size=1;\nAC${OCTAL}GT\n" | \
        "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done

## Define ASCII characters not accepted in fastq sequences
for i in {1..9} 11 12 {14..64} 66 {68..70} {72..83} {86..96} 98 {100..102} {104..115} {118..127} ; do
    DESCRIPTION="ascii character ${i} is not allowed in sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e ">s;size=1;\nAC${OCTAL}GT\n" | \
        "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done

## Vsearch aborts if fastq identifiers are not unique
DESCRIPTION="vsearch aborts if fastq headers are not unique"
echo -e ">a;size=10;\nACGT\n>a;size=10;\nAAGT\n" | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

# ## Fastq headers can contain more than one underscore symbol
# DESCRIPTION="fastq headers can contain more than one underscore symbol"
# STATS=$(mktemp)
# IDENTIFIER="a_2_2"
# echo -e ">${IDENTIFIER}_3\nACGTACGT" | \
#     "${VSEARCH}" --sample_size 1 --fastqout - -s "${STATS}" &> /dev/null
# grep -qE "[[:blank:]]${IDENTIFIER}[[:blank:]]" "${STATS}" && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"
# rm -f "${STATS}"

## Fastq header must contain an abundance value after being truncated
DESCRIPTION="vsearch aborts if fastq headers lacks abundance value"
echo -e ">a a;size=1;\nACGT" | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch aborts if abundance value is not a number
DESCRIPTION="vsearch aborts if abundance value is not a number"
echo -e ">a;size=n;\nACGT" | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch aborts if abundance value is zero
DESCRIPTION="vsearch aborts if abundance value is zero"
echo -e ">a;size=0;\nACGT" | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch aborts if abundance value is negative
DESCRIPTION="vsearch aborts if abundance value is negative"
echo -e ">a;size=-1;\nACGT" | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
    failure "${DESCRIPTION}" || success "${DESCRIPTION}"

## vsearch accepts large abundance values (2^32 - 1)
DESCRIPTION="vsearch accepts large abundance values (up to 2^32 - 1)"
for POWER in {2..32} ; do
    printf ">s1;size=%d;\nA\n" $(( (1 << POWER) - 1 )) | \
        "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null || \
        failure "${DESCRIPTION}"
done && success "${DESCRIPTION}"

## vsearch accepts abundance values equal to 2^32
DESCRIPTION="vsearch accepts abundance values equal to 2^32"
printf ">s1_;size=%d;\nA\n" $(( 1 << 32 )) | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## vsearch accepts abundance values equal to 2^32 + 1
DESCRIPTION="vsearch accepts abundance values equal to 2^32 + 1"
printf ">s1;size=%d;\nA\n" $(( (1 << 32) + 1 )) | \
    "${VSEARCH}" --sample_size 1 --fastqout - &> /dev/null && \
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

## Define ASCII characters accepted in fasta identifiers
DESCRIPTION="ascii characters 1-9, 11-12, 14-31, 33-127 allowed in fasta identifiers"
for i in {1..9} 11 12 {14..31} {33..127} ; do
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@aa${OCTAL}aa;size=1;\nACGT\n+\nGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null || \
        failure "ascii character ${i} allowed in fasta identifiers"
done && success "${DESCRIPTION}"

## Define ASCII characters not accepted in fasta identifiers
#  0: NULL
# 10: "\n"
# 13: "\r"
# 32: SPACE
for i in 0 10 13 32 ; do
    DESCRIPTION="ascii character ${i} is not allowed in fasta identifiers"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@aa${OCTAL}aa;size=1;\nACGT\n+\nGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done 

## Define ASCII characters accepted in fasta headers
#  0: NULL
# 13: "\r"
# 32: SPACE
for i in 0 13 32 ; do
    DESCRIPTION="ascii character ${i} is allowed in fasta header (outside identifier)"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@aa;size=1; ${OCTAL}padding\nACGT\n+\nGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done 

## ASCII character 10 (\n) is not allowed in fasta headers (outside identifier)
# 10: "\n"
DESCRIPTION="ascii character 10 is not allowed in fasta headers (outside identifier)"
OCTAL=$(printf "\%04o" 10)
echo -e "@aa;size=1; ${OCTAL}padding\nACGT\n+\nGGGG\n" | \
    "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## non-ASCII characters accepted in fasta identifiers
DESCRIPTION="non-ASCII characters accepted in fasta identifiers"
echo -e "@ø;size=1;\nACGT\n+\nGGGG\n" | \
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
    echo -e "@aaaa;size=1;\nAC${OCTAL}GT\n+\nGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done

## Define ASCII characters not accepted in fasta sequences
for i in {1..9} 11 12 {14..64} 66 {68..70} {72..83} {86..96} 98 {100..102} {104..115} {118..127} ; do
    DESCRIPTION="ascii character ${i} is not allowed in sequences"
    OCTAL=$(printf "\%04o" ${i})
    echo -e "@s;size=1;\nAC${OCTAL}GT\n+\nGGGGG\n" | \
        "${VSEARCH}" --sample_size 1 --fastaout - &> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done

## Vsearch aborts if fasta identifiers are not unique
DESCRIPTION="vsearch aborts if fasta headers are not unique"
echo -e "@a;size=10;\nACGT\n+\nGGGG\n@a;size=10;\nAAGT\n+\nGGGG\n" | \
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

exit
