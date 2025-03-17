#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fastq_stats"
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

## none per-se, but --log is important


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------- test general behaviour

DESCRIPTION="--fastq_stats is a valid command"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fastq_stats - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats accepts empty read"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_stats - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats rejects fasta input"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastq_stats - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats does not write stats to stdout"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats accepts --log"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats writes stats to log"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats writes banner to stderr (without --log)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats writes banner to stderr (with --log)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats writes banner to log (with --log)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -q "${VSEARCH}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats writes the number of reads to stderr (one read)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - 2>&1 | \
    grep -qw "Read 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats writes the number of reads to stderr (two reads)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - 2>&1 | \
    grep -qw "Read 2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats writes the number of reads to stderr (no read)"
printf "" | \
    "${VSEARCH}" \
        --fastq_stats - 2>&1 | \
    grep -qw "Read 0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats writes the number of reads to stderr (with --log)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log /dev/null 2>&1 | \
    grep -qw "Read 1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats accepts ASCII values inside of the 0-41 range (! = 0)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats accepts ASCII values inside of the 0-41 range (J = 41)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats rejects ASCII values outside of the 0-41 range (SPACE = -1)"
printf "@s\nA\n+\n \n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats rejects ASCII values outside of the 0-41 range (K = 42)"
printf "@s\nA\n+\nK\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## --------------------------------------------------- Read length distribution

# first section of the log file

# Read length distribution
#       L           N      Pct   AccPct
# -------  ----------  -------  -------
# >=    3           1    33.3%    33.3%
#       2           1    33.3%    66.7%
#       1           1    33.3%   100.0%

#        1.  L: read length.
#        2.  N: number of reads.
#        3.  Pct: fraction of reads with this length.
#        4:  AccPct: fraction of reads with this length or longer.

DESCRIPTION="--fastq_stats logs a section titled Read length distribution"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -qw "Read length distribution" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs a first section with 4 columns"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 1 "Read length distribution" | \
    grep -qwE "[[:blank:]]+L[[:blank:]]+N[[:blank:]]+Pct[[:blank:]]+AccPct" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats separates column headers and values with a horizontal rule (first section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 2 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "[-]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when input is empty (first section)"
printf "" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats longest length value is marked with >= (first section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qw ">=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats length value is correct (first section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE ">=[[:blank:]]+1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats number of reads is correct (first section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE ">=[[:blank:]]+1[[:blank:]]+1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fraction of reads with this length is correct (first section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE ">=[[:blank:]]+1[[:blank:]]+1[[:blank:]]+100.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fraction of reads with this length or longer is correct (first section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE ">=[[:blank:]]+1[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats length values are sorted by decreasing order (input longest first) (first section)"
printf "@s1\nAAA\n+\nIII\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE ">=[[:blank:]]+3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats length values are sorted by decreasing order (input shortest first) (first section)"
printf "@s1\nA\n+\nI\n@s2\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE ">=[[:blank:]]+3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats lesser length values do not start with >= (first section)"
printf "@s1\nA\n+\nI\n@s2\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 4 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="--fastq_stats number of reads N is correct (1 read of length 1) (first section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^>=[[:blank:]]+1[[:blank:]]+1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats number of reads N is correct (2 reads of length 1) (first section)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^>=[[:blank:]]+1[[:blank:]]+2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats Pct (fraction of reads of length 1) is correct (1/2) (first section)"
printf "@s1\nAAA\n+\nIII\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 4 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+50.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats Pct (fraction of reads of length 1) is correct (1/3rd) (first section)"
printf "@s1\nAAA\n+\nIII\n@s2\nAA\n+\nII\n@s3\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 5 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+33.3%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats Pct (fraction of reads of length 1) is correct (1/6rd) (first section)"
printf "@s1\nAA\n+\nII\n@s2\nAA\n+\nII\n@s3\nAA\n+\nII\n@s4\nAA\n+\nII\n@s5\nAA\n+\nII\n@s6\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 4 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+16.7%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats AccPct (fraction of reads with length 1 or longer) is correct (first section)"
printf "@s1\nA\n+\nI\n@s2\nAA\n+\nII\n@s3\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 5 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+33.3%[[:blank:]]+100.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats AccPct (fraction of reads with length 2 or longer) is correct (first section)"
printf "@s1\nA\n+\nI\n@s2\nAA\n+\nII\n@s3\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 4 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+2[[:blank:]]+1[[:blank:]]+33.3%[[:blank:]]+66.7%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats AccPct (fraction of reads with length 3 or longer) is correct (first section)"
printf "@s1\nA\n+\nI\n@s2\nAA\n+\nII\n@s3\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^>=[[:blank:]]+3[[:blank:]]+1[[:blank:]]+33.3%[[:blank:]]+33.3%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats AccPct (fraction of reads with shortest length or longer) is always 100.0 (first section)"
printf "@s1\nA\n+\nI\n@s2\nAA\n+\nII\n@s3\nAAA\n+\nIII\n@s4\nAAAA\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 6 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+25.0%[[:blank:]]+100.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats AccPct is correct for empty reads (length is zero) (first section)"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Read length distribution" | \
    tail -n 1 | \
    grep -qwE "^>=[[:blank:]]+0[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------- Quality score distribution

# second section of the log file

#        1.  ASCII: character encoding the quality score.
#        2.  Q: Phred quality score.
#        3.  Pe: probability of error associated with the quality score.
#        4.  N: number of bases with this quality score.
#        5.  Pct: fraction of bases with this quality score.
#        6:  AccPct: fraction of bases with this quality score or higher.

# Q score distribution
# ASCII    Q       Pe           N      Pct   AccPct
# -----  ---  -------  ----------  -------  -------
#     I   40  0.00010           6   100.0%   100.0%

DESCRIPTION="--fastq_stats logs a section titled Q score distribution"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -qw "Q score distribution" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs a second section with 6 columns"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 1 "Q score distribution" | \
    grep -qwE "ASCII[[:blank:]]+Q[[:blank:]]+Pe[[:blank:]]+N[[:blank:]]+Pct[[:blank:]]+AccPct" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats separates column headers and values with a horizontal rule (second section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 2 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "[-]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when input is empty (second section)"
printf "" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when read is empty (second section)"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs ASCII values (second section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs quality values Q (second section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I[[:blank:]]+40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs probability of error values Pe (second section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]+0.00010" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs number of bases with this quality score N (second section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]+0.00010[[:blank:]]+1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs fraction of bases with this quality score Pct (second section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]+0.00010[[:blank:]]+1[[:blank:]]+100.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs fraction of bases with this quality score or higher AccPct (second section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]+0.00010[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats sorts ASCII values (H after I) (second section)"
printf "@s1\nA\n+\nH\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 4 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+H" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats sorts ASCII values (I before H) (second section)"
printf "@s1\nA\n+\nH\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs high Pe values (Q = 0) (second section)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+![[:blank:]]+0[[:blank:]]+1.00000" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs high Pe values (Q = 1) (second section)"
printf "@s\nA\n+\n\"\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+\"[[:blank:]]+1[[:blank:]]+0.79433" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs high Pe values (Q = 2) (second section)"
printf "@s\nA\n+\n#\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+#[[:blank:]]+2[[:blank:]]+0.63096" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs high Pe values (Q = 3) (second section)"
printf "@s\nA\n+\n$\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+[$][[:blank:]]+3[[:blank:]]+0.50119" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs high Pe values (Q = 4) (second section)"
printf "@s\nA\n+\n%%\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+%[[:blank:]]+4[[:blank:]]+0.39811" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs common Pe values (Q = 10) (second section)"
printf "@s\nA\n+\n+\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+[+][[:blank:]]+10[[:blank:]]+0.10000" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs common Pe values (Q = 20) (second section)"
printf "@s\nA\n+\n5\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+5[[:blank:]]+20[[:blank:]]+0.01000" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs common Pe values (Q = 30) (second section)"
printf "@s\nA\n+\n?\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+[?][[:blank:]]+30[[:blank:]]+0.00100" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs number of bases with a given Q value (second section)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]+0.00010[[:blank:]]+2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs Pct of bases with a given Q value (first Q) (second section)"
printf "@s1\nA\n+\nH\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]+0.00010[[:blank:]]+1[[:blank:]]+50.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs Pct of bases with a given Q value (second Q) (second section)"
printf "@s1\nA\n+\nH\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 4 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+H[[:blank:]]+39[[:blank:]]+0.00013[[:blank:]]+1[[:blank:]]+50.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs AccPct of bases with a given Q value or more (first Q) (second section)"
printf "@s1\nA\n+\nH\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 3 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]+0.00010[[:blank:]]+1[[:blank:]]+50.0%[[:blank:]]+50.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs AccPct of bases with a given Q value or more (second Q) (second section)"
printf "@s1\nA\n+\nH\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -w -A 4 "Q score distribution" | \
    tail -n 1 | \
    grep -qwE "^[[:blank:]]+H[[:blank:]]+39[[:blank:]]+0.00013[[:blank:]]+1[[:blank:]]+50.0%[[:blank:]]+100.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## -------------------------------------------- Length vs. quality distribution

#        1.  L: position in reads (starting from position 2).
#        2.  PctRecs: fraction of reads with at least this length.
#        3.  AvgQ: average quality score over all reads up to this position.
#        4.  P(AvgQ): error probability corresponding to AvgQ.
#        5.  AvgP: average error probability.
#        6:  AvgEE: average expected error over all reads up to this position.
#        7:  Rate: growth rate of AvgEE between this position and position - 1.
#        8:  RatePct: Rate (as explained above) expressed as a percentage.

#     L  PctRecs  AvgQ  P(AvgQ)      AvgP  AvgEE       Rate   RatePct
# -----  -------  ----  -------  --------  -----  ---------  --------
#     2    66.7%  40.0  0.00010  0.000100   0.00   0.000100    0.010%
#     3    33.3%  40.0  0.00010  0.000100   0.00   0.000100    0.010%

# empty line between sections two and three
DESCRIPTION="--fastq_stats logs a untitled third section"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -B 1 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    head -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs a third section with 8 columns"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -qwE "^[[:blank:]]+L[[:blank:]]+PctRecs[[:blank:]]+AvgQ[[:blank:]]+P\(AvgQ\)[[:blank:]]+AvgP[[:blank:]]+AvgEE[[:blank:]]+Rate[[:blank:]]+RatePct$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats separates column headers and values with a horizontal rule (third section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 1 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -qwE "[-]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when input is empty (third section)"
printf "" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when read is empty (third section)"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when read has a length of 1 (third section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when reads have a length of 1 (third section)"
printf "@s1\nA\n+\nI\n@s2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs values when read has a length > 1 (third section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -q "^$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs length value (L) (third section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs first length value (L) is always 2 (third section)"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs fraction of reads with at least this length (PctRecs) (third section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs average quality score over all reads up to this position (AvgQ) (third section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+40.0[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Put low Q values ('5' = Q20) in first position to demonstrate that
## previous positions are not taken into account
DESCRIPTION="--fastq_stats AvgQ is the average for this position (third section)"
printf "@s1\nAA\n+\n5I\n@s2\nAA\n+\n5I\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+40.0[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs error probability corresponding to AvgQ (P(AvgQ)) (third section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+40.0[[:blank:]]+0.00010[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs average error probability (AvgP) (third section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+40.0[[:blank:]]+0.00010[[:blank:]]+0.000100[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Put big P values ('5': 0.01) in first position to demonstrate that
## previous positions are not taken into account
DESCRIPTION="--fastq_stats AvgP is the average for this position (third section)"  # not the cummulated average
printf "@s1\nAA\n+\n5I\n@s2\nAA\n+\n5I\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+40.0[[:blank:]]+0.00010[[:blank:]]+0.000100[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note: AvgEE can only increase from one position to the next
DESCRIPTION="--fastq_stats logs average expected error over all reads up to this position (AvgEE) (third section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+40.0[[:blank:]]+0.00010[[:blank:]]+0.000100[[:blank:]]+0.00[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Use different Q values to demonstrate that all previous positions
## are taken into account (this test might be a bit fragile; it might
## break if rounding method changes)
DESCRIPTION="--fastq_stats AvgEE is the average over all reads up to this position (third section)"
printf "@s1\nAA\n+\n+-\n@s2\nAA\n+\n25\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+16.0[[:blank:]]+0.02512[[:blank:]]+0.036548[[:blank:]]+0.10[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats AvgEE is not the sum of all probabilities up to that position (third section)"
# refactoring issue:
# when trying to deduce the AvgEE from the quality distribution,
# a partial sum of all probabilities for all sequences produces wrong
# values (way too large) when sequences differ in length
printf "@s1\nAAA\n+\nIII\n@s2\nAA\n+\n\"\"\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 3 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+3[[:blank:]]+50.0%[[:blank:]]+40.0[[:blank:]]+0.00010[[:blank:]]+0.000100[[:blank:]]+0.00[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs growth rate of AvgEE between this position and position - 1 (Rate) (third section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+40.0[[:blank:]]+0.00010[[:blank:]]+0.000100[[:blank:]]+0.00[[:blank:]]+0.000100[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs Rate expressed as a percentage (RatePct) (third section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+40.0[[:blank:]]+0.00010[[:blank:]]+0.000100[[:blank:]]+0.00[[:blank:]]+0.000100[[:blank:]]+0.010%$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# fastest possible AvgEE increase (for a dataset with a single read)
DESCRIPTION="--fastq_stats logs Rate expressed as a percentage (RatePct, Q = 0) (third section)"
printf "@s\nAA\n+\n!!\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+0.0[[:blank:]]+1.00000[[:blank:]]+1.000000[[:blank:]]+2.00[[:blank:]]+1.000000[[:blank:]]+100.000%$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats PctRecs is correct (third section)"
printf "@s1\nA\n+\nI\n@s2\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -qE "^[[:blank:]]+2[[:blank:]]+50.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# double read == double Rate? no, this is an average
DESCRIPTION="--fastq_stats Rate is correct for double reads (third section)"
printf "@s1\nAA\n+\nII\n@s2\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+PctRecs" | \
    tail -n 1 | \
    grep -qE "^[[:blank:]]+2[[:blank:]]+100.0%[[:blank:]]+40.0[[:blank:]]+0.00010[[:blank:]]+0.000100[[:blank:]]+0.00[[:blank:]]+0.000100[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------ Effect of expected error and length filtering

# First column: read lengths (L)

# The next four columns indicate the number of reads that would be
# retained by the --fastq_filter command if the reads were truncated
# at length L (option --fastq_trunclen L) and filtered to have a
# maximum expected error of 1.0, 0.5, 0.25 or 0.1 (with the option
# --fastq_maxee float).

# p = 1.0  -> Q =  0 (= 0)
# p = 0.5  -> Q =  3 (> 0.5)
# p = 0.25 -> Q =  6 (> 0.25)
# p = 0.1  -> Q = 10 (= 0.1)

# The last four columns indicate the fraction of reads that would be
# retained by the --fastq_filter command using the same length and
# maximum expected error parameters.

#     L   1.0000   0.5000   0.2500   0.1000   1.0000   0.5000   0.2500   0.1000
# -----  -------  -------  -------  -------  -------  -------  -------  -------
#     3        1        1        1        1   33.33%   33.33%   33.33%   33.33%
#     2        2        2        2        2   66.67%   66.67%   66.67%   66.67%
#     1        3        3        3        3  100.00%  100.00%  100.00%  100.00%

# empty line between sections three and four
DESCRIPTION="--fastq_stats logs a untitled fourth section"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -B 1 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    head -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs a fourth section with 9 columns"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -qwE "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]+0.5000[[:blank:]]+0.2500[[:blank:]]+0.1000[[:blank:]]++1.0000[[:blank:]]+0.5000[[:blank:]]+0.2500[[:blank:]]+0.1000$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats separates column headers and values with a horizontal rule (fourth section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 1 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -qwE "[-]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when input is empty (fourth section)"
printf "" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when read is empty (fourth section)"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs values when read has a length > 0 (fourth section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -q "^$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs length value (L) (fourth section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs length values (L) in decreasing order (first line) (fourth section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs length values (L) in decreasing order (second line) (fourth section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 3 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (EE > 1.0) (fourth section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note: Q=0 -> p = 1.0; maxEE cannot be greater than 1.0 for the first
# position, so first position cannot be filtered out
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (EE = 1.0) (fourth section)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats EE must be strictly greater than maxEE to be filtered out (fourth section)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note: p = 0.5  -> Q =  3 (> 0.5)
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (Q=4, EE < 0.5) (fourth section)"
printf "@s\nA\n+\n%%\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (Q=3, EE > 0.5) (fourth section)"
printf "@s\nA\n+\n$\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+0[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note: p = 0.25 -> Q = 6 (> 0.25)
# Q=7 (
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (Q=7, EE < 0.25) (fourth section)"
printf "@s\nA\n+\n(\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Q=6 '
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (Q=6, EE > 0.25) (fourth section)"
printf "@s\nA\n+\n'\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]+0[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# note: p = 0.1 -> Q = 10 (== 0.1)
# Q=9  '*'
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (Q=9, EE > 0.1) (fourth section)"
printf "@s\nA\n+\n*\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]+0[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Q=10  '+'
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (Q=10, EE = 0.1) (fourth section)"
printf "@s\nA\n+\n+\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Q=11  ','
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (Q=11, EE < 0.1) (fourth section)"
printf "@s\nA\n+\n,\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# using --fastq_filter with --fastq_trunclen 3 and --fastq_maxee 0.1 would trim the last position
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (length = 3) (fourth section)"
printf "@s\nAAA\n+\nII+\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+3[[:blank:]]+1[[:blank:]]+1[[:blank:]]+1[[:blank:]]+0[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# for a non-empty fastq input, section 4 contains at least one line
# because EE cannot be greater than 1.0 before the second position
DESCRIPTION="--fastq_stats section four is never empty if fastq is not empty (fourth section)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+1[[:blank:]]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## expect:
#     L   1.0000   0.5000   0.2500   0.1000   1.0000   0.5000   0.2500   0.1000
# -----  -------  -------  -------  -------  -------  -------  -------  -------
#     1        4        3        2        1  100.00%   75.00%   50.00%   25.00%
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (percentages: 100 to 25) (fourth section)"
printf "@s1\nA\n+\n!\n@s2\nA\n+\n'\n@s3\nA\n+\n*\n@s4\nA\n+\n+\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+4[[:blank:]]+3[[:blank:]]+2[[:blank:]]+1[[:blank:]]+100.00%[[:blank:]]+75.00%[[:blank:]]+50.00%[[:blank:]]+25.00%$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## expect:
#     L   1.0000   0.5000   0.2500   0.1000   1.0000   0.5000   0.2500   0.1000
# -----  -------  -------  -------  -------  -------  -------  -------  -------
#     1        2        1        1        0  100.00%   50.00%   50.00%    0.00%
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (percentages: 100, 50, and 0) (fourth section)"
printf "@s1\nA\n+\n!\n@s2\nA\n+\n*\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+2[[:blank:]]+1[[:blank:]]+1[[:blank:]]+0[[:blank:]]+100.00%[[:blank:]]+50.00%[[:blank:]]+50.00%[[:blank:]]+0.00%$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# Never report lengths (L) with only null values, start reporting from
# the first L with a cummulated EE <= 1.0 (here, L = 3 is filtered out
# as its EE is greater than 1.0, and report starts at L = 2)
# (does not apply to the fifth section)
DESCRIPTION="--fastq_stats logs the effect of truncating and maxEE filtering (pre-filter positions with EE > 1.0) (fourth section)"
printf "@s\nAAA\n+\nII!\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -m 1 -E -A 2 "^[[:blank:]]+L[[:blank:]]+1.0000[[:blank:]]" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+2[[:blank:]]+1[[:blank:]]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ----------------------------- Effect of minimum quality and length filtering

# The first column indicates read lengths (Len). The next four columns
# indicate the fraction of reads that would be retained by the
# --fastq_filter command if the reads were truncated at length Len
# (option --fastq_trunclen Len) or at the first position with a
# quality Q below 5, 10, 15 or 20 (option --fastq_truncqual Q).

# Truncate at first Q
#   Len     Q=5    Q=10    Q=15    Q=20
# -----  ------  ------  ------  ------
#     3   33.3%   33.3%   33.3%   33.3%
#     2   66.7%   66.7%   66.7%   66.7%
#     1  100.0%  100.0%  100.0%  100.0%

# Q=5 ('&'), Q=10 ('+'), Q=15 ('0'), Q=20 ('5') cuts at value or above?

# empty line between sections four and five
DESCRIPTION="--fastq_stats logs an empty line between sections four and five"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -B 1 "^Truncate at first Q$" | \
    head -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs a fifth section"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -q "^Truncate at first Q$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs a fifth section with 5 columns"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 1 "^Truncate at first Q$" | \
    grep -qwE "^[[:blank:]]+Len[[:blank:]]+Q=5[[:blank:]]+Q=10[[:blank:]]+Q=15[[:blank:]]+Q=20$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats separates column headers and values with a horizontal rule (fifth section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 2 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -qwE "[-]+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when input is empty (fifth section)"
printf "" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats empty section when read is empty (fifth section)"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -q "^$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs values when read has a length > 0 (fifth section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -q "^$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs one value when read length is 1 (fifth section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -qE "^[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs two values when read length is 2 (fifth section)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 4 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -qE "^[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs three values when read length is 3 (fifth section)"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 5 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -qE "^[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs three values when read length is 4 (fifth section)"
printf "@s\nAAAA\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 6 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -q "^[[:blank:]]+1[[:blank:]]" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs four values when read length is 6 (fifth section)"
printf "@s\nAAAAAA\n+\nIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 7 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -q "^[[:blank:]]+2[[:blank:]]" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# output floor(length / 2) + 1
DESCRIPTION="--fastq_stats logs five values when read length is 8 (fifth section)"
printf "@s\nAAAAAAAA\n+\nIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 8 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -q "^[[:blank:]]+3[[:blank:]]" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs length value (Len) (fifth section)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 4 ('%')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 5 at this position (Q < 5) (fifth section)"
printf "@s\nA\n+\n%%\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+0.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 5 ('&')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 5 at this position (Q = 5) (fifth section)"
printf "@s\nA\n+\n&\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+0.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 6 (''')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 5 at this position (Q > 5) (fifth section)"
printf "@s\nA\n+\n'\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 9 ('*')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 10 at this position (Q < 10) (fifth section)"
printf "@s\nA\n+\n*\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+0.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 10 ('+')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 10 at this position (Q = 10) (fifth section)"
printf "@s\nA\n+\n+\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+0.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 11 (',')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 10 at this position (Q > 10) (fifth section)"
printf "@s\nA\n+\n,\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 14 ('/')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 15 at this position (Q < 15) (fifth section)"
printf "@s\nA\n+\n/\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]+0.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 15 ('0')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 15 at this position (Q = 15) (fifth section)"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]+0.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 16 ('1')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 15 at this position (Q > 15) (fifth section)"
printf "@s\nA\n+\n1\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 19 ('4')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 20 at this position (Q < 20) (fifth section)"
printf "@s\nA\n+\n4\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]+0.0%$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 20 ('5')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 20 at this position (Q = 20) (fifth section)"
printf "@s\nA\n+\n5\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]+0.0%$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Q = 21 ('6')
DESCRIPTION="--fastq_stats logs fraction of reads with Q > 20 at this position (Q > 20) (fifth section)"
printf "@s\nA\n+\n6\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -A 3 "^Truncate at first Q$" | \
    tail -n 1 | \
    grep -Eq "^[[:blank:]]+1[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]+100.0%[[:blank:]]+100.0%$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ------------------------------------------------------------- coverage tests

# force memory re-allocation (current alloc-realloc implementation
# allocates for reads of length 512, then reallocates read > length + 1)
DESCRIPTION="--fastq_stats accepts and allocates for long reads (length = 512)"
LENGTH=512
(
    printf "@s\n"
    yes A | head -n ${LENGTH}
    printf "+\n"
    yes I | head -n ${LENGTH}
) | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset LENGTH

DESCRIPTION="--fastq_stats accepts and allocates for long reads (length = 512 + 1)"
LENGTH=513
(
    printf "@s\n"
    yes A | head -n ${LENGTH}
    printf "+\n"
    yes I | head -n ${LENGTH}
) | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset LENGTH

# trigger reallocation
DESCRIPTION="--fastq_stats accepts and allocates for long reads (length = 512 + 2)"
LENGTH=514
(
    printf "@s\n"
    yes A | head -n ${LENGTH}
    printf "+\n"
    yes I | head -n ${LENGTH}
) | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset LENGTH


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--fastq_stats --fastq_ascii is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet \
        --fastq_ascii 33 && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_ascii accepts 33"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet \
        --fastq_ascii 33 && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_ascii accepts 64"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet \
        --fastq_ascii 64 && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_ascii rejects other values (45)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet \
        --fastq_ascii 45 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats uses an offset of 33 by default (I = Q40)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_ascii 33 sets an offset of 33 (I = Q40)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 33 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_ascii 64 sets an offset of 64 (I = Q9)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 64 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+I[[:blank:]]+9[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ----------------------------------------------------------------- fastq_qmax

#   --fastq_qmax INT            maximum base quality value for FASTQ input (41)

DESCRIPTION="--fastq_stats --fastq_qmax is accepted"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax 41 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax accepts lower quality values (H = 39)"
printf "@s\nA\n+\nH\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax 40 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+H[[:blank:]]+39[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax accepts equal quality values (I = 40)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax 40 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+I[[:blank:]]+40[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax rejects higher quality values (J = 41)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax 40 \
        --quiet 2> /dev/null && \
     failure "${DESCRIPTION}" || \
         success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax must be a positive integer"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax -1 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax can be set to zero"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax 0 \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax can be set to 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 33 \
        --fastq_qmax 93 \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax cannot be greater than 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 33 \
        --fastq_qmax 94 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax can be set to 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 64 \
        --fastq_qmax 62 \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax cannot be greater than 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 64 \
        --fastq_qmax 63 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax 93 Pe is 0.00001 for Q50"
printf "@s\nA\n+\nS\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax 93 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+S[[:blank:]]+50[[:blank:]]+0.00001[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax 93 Pe is 0.00001 for Q53"
printf "@s\nA\n+\nV\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax 93 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+V[[:blank:]]+53[[:blank:]]+0.00001[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax 93 Pe is 0.00000 for Q54"
printf "@s\nA\n+\nW\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax 93 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+W[[:blank:]]+54[[:blank:]]+0.00000[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax 93 Pe is 0.00000 for Q60"
printf "@s\nA\n+\n]\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmax 93 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+][[:blank:]]+60[[:blank:]]+0.00000[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ----------------------------------------------------------------- fastq_qmin

#   --fastq_qmin INT            minimum base quality value for FASTQ input (0)

DESCRIPTION="--fastq_stats --fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmin 0 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmin accepts higher quality values (0 = 15)"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmin 14 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+0[[:blank:]]+15[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmin accepts equal quality values (0 = 15)"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmin 15 \
        --quiet \
        --log - | \
    grep -qE "^[[:blank:]]+0[[:blank:]]+15[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmin rejects lower quality values (0 = 15)"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmin 16 \
        --quiet 2> /dev/null && \
     failure "${DESCRIPTION}" || \
         success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmin must be a positive integer"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmin -1 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmin can be set to zero (default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmin 0 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmin can be lower than fastq_qmax (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmin 40 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## allows to select only reads with a specific Q value
DESCRIPTION="--fastq_stats --fastq_qmin can be equal to fastq_qmax (41 by default)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmin 41 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmin cannot be higher than fastq_qmax (41 by default)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_qmin 42 \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


# but not higher, as it cannot be greater than qmax
DESCRIPTION="--fastq_stats --fastq_qmin can be set to 93 (offset 33)"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 33 \
        --fastq_qmin 93 \
        --fastq_qmax 93 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# but not higher, as it cannot be greater than qmax
DESCRIPTION="--fastq_stats --fastq_qmin can be set to 62 (offset 64)"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --fastq_ascii 64 \
        --fastq_qmin 62 \
        --fastq_qmax 62 \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

# The valid options for the fastq_stats command are:
# --bzip2_decompress --fastq_ascii --fastq_qmax --fastq_qmin
# --gzip_decompress --log --no_progress --output --quiet --threads

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--fastq_stats --bzip2_decompress is accepted (empty input)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_stats - \
        --bzip2_decompress \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats rejects compressed stdin (bzip2)"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --bzip2_decompress accepts compressed stdin"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_stats - \
        --bzip2_decompress \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --bzip2_decompress rejects uncompressed stdin"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --bzip2_decompress \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--fastq_stats --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_stats - \
        --gzip_decompress \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats rejects compressed stdin (gzip)"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --gzip_decompress accepts compressed stdin"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_stats - \
        --gzip_decompress \
        --quiet && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# more flexible than bzip2
DESCRIPTION="--fastq_stats --gzip_decompress accepts uncompressed stdin"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --gzip_decompress \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats rejects --bzip2_decompress + --gzip_decompress"
printf "" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --bzip2_decompress \
        --gzip_decompress \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ------------------------------------------------------------------------ log

# already partially tested in the general behaviour section

DESCRIPTION="--fastq_stats logs the starting timestamp"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -qw "Started" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs the finishing timestamp"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -qw "Finished" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs the elapsed time"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -qw "Elapsed time" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats logs the maximal allocated memory"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --log - 2> /dev/null | \
    grep -qw "Max memory" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


## ---------------------------------------------------------------- no_progress

DESCRIPTION="--fastq_stats --no_progress is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet \
        --no_progress && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --no_progress removes progressive report on stderr (no visible effect)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --no_progress 2>&1 | \
    grep -iq "^reading" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


## ---------------------------------------------------------------------- quiet

DESCRIPTION="--fastq_stats --quiet is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --quiet eliminates all (normal) messages to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --quiet allows error messages to be sent to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet \
        --quiet2 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"


## -------------------------------------------------------------------- threads

DESCRIPTION="--fastq_stats --threads is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --threads 1 \
        --quiet && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --threads > 1 triggers a warning (not multithreaded)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --threads 2 \
        --quiet 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## --------------------------------------------------------------------- output

DESCRIPTION="--fastq_stats --output is rejected"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
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
    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastq_stats <(printf "@s\nAA\n+\nII\n") \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastq_stats valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastq_stats valgrind (no errors)"
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

## TODO: add a warning stating that option --log is recommended? (man
## states 'requires', but it is not enforced yet)


exit 0
