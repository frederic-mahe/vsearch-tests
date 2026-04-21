#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastq_eestats"
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

## vsearch --fastq_eestats fastqfile --output outputfile [options]

DESCRIPTION="--fastq_eestats is a valid command"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats requires --output"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --output accepts a regular file"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output "${TMP}" 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastq_eestats --output accepts /dev/null"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --output accepts - (stdout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --output requires an argument"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats reads from stdin with -"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats reads from a file argument"
TMP=$(mktemp)
printf "@s\nA\n+\nI\n" > "${TMP}"
"${VSEARCH}" \
    --fastq_eestats "${TMP}" \
    --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMP}"
unset TMP


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------- output stream behaviour

DESCRIPTION="--fastq_eestats does not write table to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -q "^Pos" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats writes a banner to stderr (without --quiet)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null 2>&1 > /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats empty input produces header-only output"
printf "" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    wc -l | \
    grep -qxE "[[:space:]]*1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats rejects fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats accepts empty read"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------- table format and header

DESCRIPTION="--fastq_eestats output is tab-separated"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    head -n 1 | \
    grep -q "	" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats outputs a 21-column header"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    head -n 1 | \
    awk -F "\t" '{print NF}' | \
    grep -qx "21" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats outputs 21-column data rows"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==2 {print NF}' | \
    grep -qx "21" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## expected columns (in order):
## Pos Recs PctRecs
## Min_Q Low_Q Med_Q Mean_Q Hi_Q Max_Q
## Min_Pe Low_Pe Med_Pe Mean_Pe Hi_Pe Max_Pe
## Min_EE Low_EE Med_EE Mean_EE Hi_EE Max_EE
for COL_N_NAME in \
    "1:Pos" "2:Recs" "3:PctRecs" \
    "4:Min_Q" "5:Low_Q" "6:Med_Q" "7:Mean_Q" "8:Hi_Q" "9:Max_Q" \
    "10:Min_Pe" "11:Low_Pe" "12:Med_Pe" "13:Mean_Pe" "14:Hi_Pe" "15:Max_Pe" \
    "16:Min_EE" "17:Low_EE" "18:Med_EE" "19:Mean_EE" "20:Hi_EE" "21:Max_EE" ; do
    COL_N=${COL_N_NAME%:*}
    COL_NAME=${COL_N_NAME#*:}
    DESCRIPTION="--fastq_eestats column ${COL_N} header is ${COL_NAME}"
    printf "@s\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastq_eestats - \
            --output - \
            --quiet 2> /dev/null | \
        awk -F "\t" -v c="${COL_N}" 'NR==1 {print $c}' | \
        grep -qxF "${COL_NAME}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done
unset COL_N_NAME COL_N COL_NAME

## ----------------------------------------------------- table content per row

DESCRIPTION="--fastq_eestats one read of length 1 produces one data row"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk 'NR>1' | \
    wc -l | \
    grep -qxE "[[:space:]]*1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats one read of length 2 produces two data rows"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk 'NR>1' | \
    wc -l | \
    grep -qxE "[[:space:]]*2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Pos starts at 1"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==2 {print $1}' | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Pos is 1-based and increments"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==3 {print $1}' | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Recs counts reads reaching this position (length 1)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==2 {print $2}' | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Recs decreases at longer positions"
printf "@s1\nAA\n+\nII\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==3 {print $2}' | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats PctRecs is 100.0 at position 1"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==2 {print $3}' | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats PctRecs reflects partial coverage (50.0%)"
printf "@s1\nAA\n+\nII\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==3 {print $3}' | \
    grep -qx "50.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## with a single Q value, all Q stats should equal that value
DESCRIPTION="--fastq_eestats Q stats match the single observed quality score (I = Q40)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==2 {for (i=4; i<=9; i++) if ($i != "40.0") exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## cumulative EE at position 1 equals per-base error probability at position 1
DESCRIPTION="--fastq_eestats EE at position 1 equals Pe at position 1 (Q40 -> 0.00)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==2 {print $16}' | \
    grep -qx "0.00" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q=0 (! = 33) corresponds to error probability of 1.0
DESCRIPTION="--fastq_eestats Q=0 yields Pe=1.0"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==2 {print $10}' | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--fastq_eestats --fastq_ascii is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_ascii 33 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --fastq_ascii accepts 33"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_ascii 33 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --fastq_ascii accepts 64"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_ascii 64 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --fastq_ascii rejects values other than 33 or 64"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_ascii 50 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## with --fastq_ascii 33, 'I' = ASCII 73 = Q40
DESCRIPTION="--fastq_eestats --fastq_ascii 33 interprets 'I' as Q40"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_ascii 33 \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==2 {print $4}' | \
    grep -qx "40.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## with --fastq_ascii 64, 'I' = ASCII 73 = Q9
DESCRIPTION="--fastq_eestats --fastq_ascii 64 interprets 'I' as Q9"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_ascii 64 \
        --output - \
        --quiet 2> /dev/null | \
    awk -F "\t" 'NR==2 {print $4}' | \
    grep -qx "9.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

DESCRIPTION="--fastq_eestats --fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_qmin 0 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## default fastq_qmin is 0, default fastq_qmax is 41; H = Q39, allowed
DESCRIPTION="--fastq_eestats --fastq_qmin accepts a quality equal to fastq_qmin"
printf "@s\nA\n+\nH\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_qmin 39 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --fastq_qmin rejects qualities below fastq_qmin"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_qmin 1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## fastq_ascii + fastq_qmin must be >= 33
DESCRIPTION="--fastq_eestats --fastq_qmin + --fastq_ascii < 33 is rejected"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_ascii 33 \
        --fastq_qmin -1 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

DESCRIPTION="--fastq_eestats --fastq_qmax is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_qmax 41 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --fastq_qmax rejects qualities above fastq_qmax"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_qmax 40 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## fastq_ascii + fastq_qmax must be <= 126
DESCRIPTION="--fastq_eestats --fastq_qmax + --fastq_ascii > 126 is rejected"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_ascii 33 \
        --fastq_qmax 100 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats rejects --fastq_qmin > --fastq_qmax"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_qmin 40 \
        --fastq_qmax 20 \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--fastq_eestats --bzip2_decompress accepts bzip2 compressed input"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --bzip2_decompress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats rejects bzip2-compressed stdin without --bzip2_decompress"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --bzip2_decompress accepts empty compressed input"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --bzip2_decompress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--fastq_eestats --gzip_decompress accepts gzip compressed input"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --gzip_decompress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats rejects gzip-compressed stdin without --gzip_decompress"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --gzip_decompress accepts empty compressed input"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --gzip_decompress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats rejects --bzip2_decompress combined with --gzip_decompress"
printf "" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --bzip2_decompress \
        --gzip_decompress \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--fastq_eestats --log is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null \
        --log /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --log writes to the log file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null \
        --log - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --log + --quiet silences stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --output /dev/null \
        --quiet \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--fastq_eestats --no_progress is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --no_progress \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--fastq_eestats --no_progress removes progressive report on stderr (no visible effect)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --no_progress \
        --output /dev/null 2>&1 | \
    grep -iq "^reading" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--fastq_eestats --quiet is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --quiet \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --quiet eliminates all (normal) messages to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --quiet \
        --output /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --quiet does not alter the --output table"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --quiet \
        --output - 2> /dev/null | \
    head -n 1 | \
    grep -q "^Pos" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------------- threads

## --threads is accepted but not supported (not multithreaded)
DESCRIPTION="--fastq_eestats --threads 1 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --threads 1 \
        --output /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats --threads > 1 triggers a warning (not multithreaded)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --threads 2 \
        --output /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## options that belong to other commands
for OPT in --id --minseqlength --sizein --sizeout --relabel --fastq_maxee ; do
    DESCRIPTION="--fastq_eestats rejects ${OPT}"
    printf "@s\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastq_eestats - \
            "${OPT}" 1 \
            --output /dev/null 2> /dev/null && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done
unset OPT

## eestats2-specific options are not valid for --fastq_eestats
DESCRIPTION="--fastq_eestats rejects --ee_cutoffs"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --ee_cutoffs "0.5,1.0" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats rejects --length_cutoffs"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --length_cutoffs "1,1,1" \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats cannot be combined with --fastq_eestats2"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_eestats - \
        --fastq_eestats2 - \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


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
        --fastq_eestats "${FASTQ}" \
        --output /dev/null \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastq_eestats valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${LOG}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastq_eestats valgrind (no errors)"
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
