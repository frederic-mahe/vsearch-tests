#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastq_convert"
LINE=$(printf "%76s\n" " " | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "%bFAIL%b: %s\n" "${RED}" "${NO_COLOR}" "${1}"
    exit 1
}

success () {
    printf "%bPASS%b: %s\n" "${GREEN}" "${NO_COLOR}" "${1}"
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

## vsearch --fastq_convert fastqfile --fastqout outputfile [options]

## ------------------------------------------------------------------ fastqout

DESCRIPTION="--fastq_convert is accepted with --fastqout"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_convert fails without --fastqout"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_convert fails if output file is not writable"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastqout "${TMP}" 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastq_convert --fastqout - writes to stdout"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_convert fails if input file does not exist"
"${VSEARCH}" \
    --fastq_convert /no/such/file \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_convert fails if input file is not readable"
TMP=$(mktemp) && printf "@s\nA\n+\nI\n" > "${TMP}" && chmod u-r "${TMP}"
"${VSEARCH}" \
    --fastq_convert "${TMP}" \
    --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastq_convert fails with FASTA input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_convert accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_convert produces no output for empty input"
printf "" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

# Default encoding is phred+33 for both input and output

DESCRIPTION="--fastq_convert output is in FASTQ format (4 lines per entry)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'END {exit NR == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_convert header line starts with @"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==1 {exit /^@/ ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_convert separator line is +"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==3 {exit /^\+/ ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_convert preserves sequence header"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_convert preserves sequence"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# quality unchanged in 33->33 (identity)
DESCRIPTION="--fastq_convert preserves quality scores (33->33 identity)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "I" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_convert processes all entries in multi-entry input"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nI\n@s3\nG\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'END {exit NR == 12 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------------- fastq_ascii

DESCRIPTION="--fastq_ascii 33 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 33 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_ascii 64 is accepted"
printf "@s\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 64 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_ascii value other than 33 or 64 is rejected (32)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 32 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_ascii value other than 33 or 64 is rejected (34)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 34 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------- fastq_asciiout

DESCRIPTION="--fastq_asciiout 33 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_asciiout 33 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_asciiout 64 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_asciiout 64 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_asciiout value other than 33 or 64 is rejected (32)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_asciiout 32 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_asciiout value other than 33 or 64 is rejected (65)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_asciiout 65 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# phred+33 to phred+64: quality char shifts by +31 (64 - 33)
# 'I' = ASCII 73 = Phred 40; output 'h' = ASCII 104 = 64 + 40
DESCRIPTION="--fastq_ascii 33 --fastq_asciiout 64 converts quality correctly (I -> h)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 33 \
        --fastq_asciiout 64 \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "h" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# phred+64 to phred+33: quality char shifts by -31 (33 - 64)
# 'h' = ASCII 104 = Phred 40 in phred+64; output 'I' = ASCII 73 = 33 + 40
DESCRIPTION="--fastq_ascii 64 --fastq_asciiout 33 converts quality correctly (h -> I)"
printf "@s\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 64 \
        --fastq_asciiout 33 \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "I" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# phred+33 to phred+33: identity (quality unchanged)
DESCRIPTION="--fastq_ascii 33 --fastq_asciiout 33 is the identity (no quality change)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 33 \
        --fastq_asciiout 33 \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "I" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# phred+64 to phred+64: identity (quality unchanged)
DESCRIPTION="--fastq_ascii 64 --fastq_asciiout 64 is the identity (no quality change)"
printf "@s\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 64 \
        --fastq_asciiout 64 \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "h" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Lowest quality: '!' (Phred 0, offset 33) -> '@' (ASCII 64 = 64 + 0)
DESCRIPTION="--fastq_ascii 33 --fastq_asciiout 64 converts Phred 0 correctly (! -> @)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 33 \
        --fastq_asciiout 64 \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "@" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- fastq_qmaxout

DESCRIPTION="--fastq_qmaxout is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_qmaxout 40 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Phred 41 ('J') with qmaxout 40 is clamped to Phred 40 ('I') in phred+33 output
DESCRIPTION="--fastq_qmaxout clamps quality above max to max (J -> I with qmaxout 40)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 33 \
        --fastq_asciiout 33 \
        --fastq_qmaxout 40 \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "I" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Phred 40 ('I') with qmaxout 40 is not further clamped
DESCRIPTION="--fastq_qmaxout does not clamp quality at max (I preserved with qmaxout 40)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 33 \
        --fastq_asciiout 33 \
        --fastq_qmaxout 40 \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "I" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- fastq_qminout

DESCRIPTION="--fastq_qminout is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_qminout 5 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Phred 0 ('!') with qminout 5 is raised to Phred 5 ('&' = ASCII 38 = 33 + 5)
DESCRIPTION="--fastq_qminout clamps quality below min to min (! -> & with qminout 5)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 33 \
        --fastq_asciiout 33 \
        --fastq_qminout 5 \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "&" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Phred 5 ('&') with qminout 5 is not further raised
DESCRIPTION="--fastq_qminout does not clamp quality at min (& preserved with qminout 5)"
printf "@s\nA\n+\n&\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 33 \
        --fastq_asciiout 33 \
        --fastq_qminout 5 \
        --quiet \
        --fastqout - 2> /dev/null | \
    awk 'NR==4 {exit $0 == "&" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------ bzip2_decompress

DESCRIPTION="--bzip2_decompress is accepted"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_convert - \
        --bzip2_decompress \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--bzip2_decompress decompresses a bzip2-compressed FASTQ stream"
printf "@s\nACGT\n+\nIIII\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_convert - \
        --bzip2_decompress \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--fastq_qmax is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_qmax 41 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Default qmax is 41: 'J' (Phred 41) passes
DESCRIPTION="--fastq_convert accepts quality at default qmax (Phred 41 = J)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Default qmax is 41: 'K' (Phred 42) fails
DESCRIPTION="--fastq_convert rejects quality above default qmax (Phred 42 = K)"
printf "@s\nA\n+\nK\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# With --fastq_qmax 50: 'S' (ASCII 83 = Phred 50 with offset 33) passes
DESCRIPTION="--fastq_qmax 50 accepts quality at 50 (S)"
printf "@s\nA\n+\nS\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_qmax 50 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# With --fastq_qmax 50: 'T' (ASCII 84 = Phred 51 with offset 33) fails
DESCRIPTION="--fastq_qmax 50 rejects quality above 50 (T = Phred 51)"
printf "@s\nA\n+\nT\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_qmax 50 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_qmin 0 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Default qmin is 0: '!' (Phred 0, ASCII 33) passes
DESCRIPTION="--fastq_convert accepts quality at default qmin (Phred 0 = !)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# With offset 64, '?' (ASCII 63) is Phred -1, below default qmin 0
DESCRIPTION="--fastq_convert rejects quality below default qmin (Phred -1 with offset 64)"
printf "@s\nA\n+\n?\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_ascii 64 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# With --fastq_qmin 5: '&' (ASCII 38 = Phred 5 with offset 33) passes
DESCRIPTION="--fastq_qmin 5 accepts quality at 5 (&)"
printf "@s\nA\n+\n&\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_qmin 5 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# With --fastq_qmin 5: '%' (ASCII 37 = Phred 4 with offset 33) fails
# Use octal \045 to avoid printf interpreting % as a format specifier
DESCRIPTION="--fastq_qmin 5 rejects quality below 5 (% = Phred 4)"
printf "@s\nA\n+\n\045\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --fastq_qmin 5 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--gzip_decompress is accepted"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_convert - \
        --gzip_decompress \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--gzip_decompress decompresses a gzip-compressed FASTQ stream"
printf "@s\nACGT\n+\nIIII\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_convert - \
        --gzip_decompress \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--label_suffix is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --label_suffix ";tag=1" \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_suffix appends suffix to sequence headers"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --label_suffix ";tag=1" \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s;tag=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--lengthout is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --lengthout \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--lengthout adds length annotation to header"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --lengthout \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------------- log

DESCRIPTION="--log is accepted"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --log "${TMP}" \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--log creates a non-empty log file"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --log "${TMP}" \
        --fastqout /dev/null 2> /dev/null
[[ -s "${TMP}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

## ------------------------------------------------------------- no_progress

DESCRIPTION="--no_progress is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --no_progress \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- quiet

DESCRIPTION="--quiet is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--quiet suppresses output to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --quiet \
        --fastqout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--relabel is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel "seq" \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel replaces header with prefix and counter"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel "seq" \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@seq1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel increments counter for each entry"
printf "@s1\nA\n+\nI\n@s2\nC\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel "seq" \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@seq2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--relabel_keep is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel "new" \
        --relabel_keep \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel_keep retains the original sequence identifier"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel "new" \
        --relabel_keep \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@new1 s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_md5

DESCRIPTION="--relabel_md5 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel_md5 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel_md5 replaces header with 32-character MD5 hex digest"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel_md5 \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qEx "@[0-9a-f]{32}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- relabel_sha1

DESCRIPTION="--relabel_sha1 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel_sha1 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel_sha1 replaces header with 40-character SHA1 hex digest"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel_sha1 \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qEx "@[0-9a-f]{40}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------- relabel_self

DESCRIPTION="--relabel_self is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel_self \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel_self replaces header with the sequence itself"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel_self \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------ mutually exclusive relabels

DESCRIPTION="--relabel and --relabel_md5 are mutually exclusive"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel "x" \
        --relabel_md5 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--relabel and --relabel_sha1 are mutually exclusive"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel "x" \
        --relabel_sha1 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--relabel and --relabel_self are mutually exclusive"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel "x" \
        --relabel_self \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--relabel_md5 and --relabel_sha1 are mutually exclusive"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel_md5 \
        --relabel_sha1 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------------- sample

DESCRIPTION="--sample is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --sample "ABC" \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sample adds sample annotation to header"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --sample "ABC" \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--sizein is accepted"
printf "@s;size=5\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --sizein \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

DESCRIPTION="--sizeout is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --sizeout \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizeout adds size=1 when no abundance annotation is present"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --sizeout \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizein --sizeout propagates existing abundance annotation"
printf "@s;size=5\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --sizein \
        --sizeout \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------------- xee

DESCRIPTION="--xee is accepted"
printf "@s;ee=1.2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --xee \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xee strips expected error annotation from header"
printf "@s;ee=1.2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --xee \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------ xlength

DESCRIPTION="--xlength is accepted"
printf "@s;length=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --xlength \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xlength strips length annotation from header"
printf "@s;length=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --xlength \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------- xsize

DESCRIPTION="--xsize is accepted"
printf "@s;size=3\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --xsize \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize strips abundance annotation from header"
printf "@s;size=3\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --xsize \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------- option combinations

DESCRIPTION="--label_suffix and --lengthout can be combined"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --label_suffix ";tag=1" \
        --lengthout \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s;tag=1;length=4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizeout and --relabel can be combined"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --relabel "seq" \
        --sizeout \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@seq1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## ------------------------------------------------------------------- threads

DESCRIPTION="--threads is accepted (ignored)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --threads 4 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--threads does not affect output"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_convert - \
        --threads 4 \
        --quiet \
        --fastqout - 2> /dev/null | \
    grep -qx "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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
    FASTQ=$(mktemp)
    printf "@s\nA\n+\nI\n" > "${FASTQ}"
    valgrind \
        --log-file="${LOG}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastq_convert "${FASTQ}" \
        --fastqout /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastq_convert valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastq_convert valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${LOG}" "${FASTQ}"
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#


exit 0
