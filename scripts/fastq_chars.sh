#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="fastq_chars"
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

## valgrind is only useful here if it can actually run the binary under
## test. When it dies before reaching main -- a uprobe on the dynamic
## loader does that, and so does a sanitizer-instrumented binary -- it
## still reports "ERROR SUMMARY: 0 errors" and "in use at exit: 0
## bytes", which would silently turn every valgrind check below into a
## pass. Probe it once here, so those checks are skipped, not passed.
VALGRIND_WORKS=false
if which valgrind > /dev/null 2>&1 ; then
    VALGRIND_PROBE=$(valgrind "${VSEARCH}" --version 2>&1)
    [[ "${VALGRIND_PROBE}" == *"ERROR SUMMARY"* && \
       "${VALGRIND_PROBE}" != *"Process terminating"* ]] && \
        VALGRIND_WORKS=true
    unset VALGRIND_PROBE
fi


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## none


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------- test general behaviour

DESCRIPTION="--fastq_chars reads fastq data"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars accepts empty input"
printf "" | \
    "${VSEARCH}" \
        --fastq_chars - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars does not write to stdout"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars writes a summary to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ sequence string

DESCRIPTION="--fastq_chars summarizes input fastq file (number of sequences #1)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -Eiqx "Read 1 sequences?\.?" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars summarizes input fastq file (number of sequences #2)"
printf "@s\nA\n+\nI\n@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -Eiqx "Read 2 sequences?\.?" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars summarizes input fastq file (number of sequences #3)"
printf "@s\nA\n+\nI\n@s\nA\n+\nI\n@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -Eiqx "Read 3 sequences?\.?" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

for S in A C G T U B D H K M N R S V W Y ; do
    DESCRIPTION="--fastq_chars accepts any IUPAC nucleotide (${S})"
    printf "@s\n%s\n+\nI\n" "${S}" | \
        "${VSEARCH}" \
            --fastq_chars - 2>&1 | \
        grep -qE "[[:blank:]]${S}[[:blank:]]+1[[:blank:]]" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done

for S in a c g t u b d h k m n r s v w y ; do
    s_uppercase="$(tr "[:lower:]" "[:upper:]" <<< "${S}")"
    DESCRIPTION="--fastq_chars converts lowercase IUPAC to uppercase (${S})"
    printf "@s\n%s\n+\nI\n" "${S}" | \
        "${VSEARCH}" \
            --fastq_chars - 2>&1 | \
        grep -qE "[[:blank:]]${s_uppercase}[[:blank:]]+1[[:blank:]]" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    unset s_uppercase
done

DESCRIPTION="--fastq_chars accepts non-IUPAC sequence symbols"
printf "@s\nD\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars outputs sequence symbols in ASCII order"
printf "@s\nCBA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -oE "^[[:blank:]]+[ABC]" | \
    tr -d " " | \
    tr -d "\n" | \
    grep -qx "ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# MaxRun is the number of consecutive repetitions after the first
# occurrence (the longest run length minus one): AAAA scores 3. Same
# semantics as usearch, except that vsearch also counts a run ending
# with the read (usearch 11 reports 0 for AAAA). Passes against
# released binaries
DESCRIPTION="--fastq_chars MaxRun counts repetitions after the first (AAAA is 3)"
printf "@s\nAAAA\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+4[[:blank:]]+100\.0%[[:blank:]]+3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# a symbol that never appears twice in a row scores 0
DESCRIPTION="--fastq_chars MaxRun is 0 without consecutive repetitions"
printf "@s\nATATA\n+\nIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+3[[:blank:]]+60\.0%[[:blank:]]+0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars counts each sequence symbol (one A)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## nucleotides are counted 
DESCRIPTION="--fastq_chars counts each sequence symbol (two As)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+2[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (100.0 percent A)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+100\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (50.0 percent A)"
printf "@s\nAC\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+50\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (33.3 percent A)"
printf "@s\nACC\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+33\.3%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (25.0 percent A)"
printf "@s\nACCC\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+25\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (20.0 percent A)"
printf "@s\nACCCC\n+\nIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+20\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (16.7 percent A)"
printf "@s\nACCCCC\n+\nIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+16\.7%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (14.3 percent A)"
printf "@s\nACCCCCC\n+\nIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+14\.3%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (12.5 percent A)"
printf "@s\nACCCCCCC\n+\nIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+12\.5%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (11.1 percent A)"
printf "@s\nACCCCCCCC\n+\nIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+11\.1%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (10.0 percent A)"
printf "@s\nACCCCCCCCC\n+\nIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+10\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (9.1 percent A)"
printf "@s\nACCCCCCCCCC\n+\nIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+9\.1%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## report is limited to 1/1000
DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (0.1 percent A)"
(
    printf "@s\nA%999s\n" " " | tr " " "C"
    printf "+\nI%999s\n" " " | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+0\.1%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## values ranging between 1/1000 and 0.5/1000 are reported as 0.1% 
DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (below 0.1 percent A)"
(
    printf "@s\nA%1999s\n" " " | tr " " "C"
    printf "+\nI%1999s\n" " " | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+0\.1%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## below 5/10000, values are reported as 0.0%
DESCRIPTION="--fastq_chars gives the frequency of each sequence symbol (0.0 percent A)"
(
    printf "@s\nA%2000s\n" " " | tr " " "C"
    printf "+\nI%2000s\n" " " | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]]+1[[:blank:]]+0\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the longest run of each sequence symbol (no run)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]].*[[:blank:]]0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## two in a row: run length = 1 (off-by-one error?)
DESCRIPTION="--fastq_chars gives the longest run of each sequence symbol (run length = 1)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]].*[[:blank:]]1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the longest run of each sequence symbol (run length = 2)"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]].*[[:blank:]]2$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the longest run of each sequence symbol (run length = 3)"
printf "@s\nAAAA\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]A[[:blank:]].*[[:blank:]]3$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------- special case for 'N'

DESCRIPTION="--fastq_chars outputs an additional quality range for Ns (Q=I..J)"
printf "@s\nNN\n+\nIJ\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]N[[:blank:]].*[[:blank:]]Q=I..J$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars outputs an additional quality range for Ns (no range, single value)"
printf "@s\nN\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]N[[:blank:]].*[[:blank:]]Q=I$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars outputs an additional quality range for 'n' (Q=I..J)"
printf "@s\nnn\n+\nIJ\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]N[[:blank:]].*[[:blank:]]Q=I..J$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars outputs an additional quality range for 'n' (no range, single value)"
printf "@s\nn\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]N[[:blank:]].*[[:blank:]]Q=I$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------- quality string

# For each character present in the quality strings, --fastq_chars
# gives the ASCII value of the character, its relative frequency, and
# the number of times a k-mer of that character appears at the end of
# quality strings.

DESCRIPTION="--fastq_chars gives the ASCII value of quality symbols (I)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]]+73[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the ASCII value of quality symbols (J)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## lowest
DESCRIPTION="--fastq_chars gives the ASCII value of quality symbols (!)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'!'[[:blank:]]+33[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## highest
DESCRIPTION="--fastq_chars gives the ASCII value of quality symbols (~)"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'~'[[:blank:]]+126[[:blank:]]" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars rejects ASCII values outside of the range 33-126"
printf "@s\nA\n+\n \n" | \
    "${VSEARCH}" \
        --fastq_chars - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars outputs quality symbols in ASCII order"
printf "@s\nNNN\n+\nCBA\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -oE "^[[:blank:]]+'[ABC]'" | \
    tr -d " " | \
    tr -d "'" | \
    tr -d "\n" | \
    grep -qx "ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (100.0 percent J)"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+100\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (50.0 percent J)"
printf "@s\nAC\n+\nJI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+50\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (33.3 percent J)"
printf "@s\nACC\n+\nJII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+33\.3%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (25.0 percent J)"
printf "@s\nACCC\n+\nJIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+25\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (20.0 percent J)"
printf "@s\nACCCC\n+\nJIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+20\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (16.7 percent J)"
printf "@s\nACCCCC\n+\nJIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+16\.7%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (14.3 percent J)"
printf "@s\nACCCCCC\n+\nJIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+14\.3%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (12.5 percent J)"
printf "@s\nACCCCCCC\n+\nJIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+12\.5%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (11.1 percent J)"
printf "@s\nACCCCCCCC\n+\nJIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+11\.1%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (10.0 percent J)"
printf "@s\nACCCCCCCCC\n+\nJIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+10\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (9.1 percent J)"
printf "@s\nACCCCCCCCCC\n+\nJIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+9\.1%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## report is limited to 1/1000
DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (0.1 percent J)"
(
    printf "@s\nA%999s\n" " " | tr " " "C"
    printf "+\nJ%999s\n" " " | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+0\.1%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## values ranging between 1/1000 and 0.5/1000 are reported as 0.1% 
DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (below 0.1 percent J)"
(
    printf "@s\nA%1999s\n" " " | tr " " "C"
    printf "+\nJ%1999s\n" " " | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+0\.1%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## below 5/10000, values are reported as 0.0%
DESCRIPTION="--fastq_chars gives the frequency of each quality symbol (0.0 percent J)"
(
    printf "@s\nA%2000s\n" " " | tr " " "A"
    printf "+\nJ%2000s\n" " " | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'J'[[:blank:]]+74[[:blank:]]+0\.0%" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## 4-mers by default
DESCRIPTION="--fastq_chars counts tail-occurrences of kmers of each symbols (1 char -> 0 tail)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars counts tail-occurrences of kmers of each symbols (2 chars -> 0 tail)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars counts tail-occurrences of kmers of each symbols (3 chars -> 0 tail)"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars counts tail-occurrences of kmers of each symbols (4 chars -> 1 tail)"
printf "@s\nAAAA\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars counts tail-occurrences of kmers of each symbols (5 chars -> 1 tail)"
printf "@s\nAAAAA\n+\nIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars counts tail-occurrences of kmers of each symbols (2 reads -> 2 tails)"
(
    printf "@s1\nAAAA\n+\nIIII\n"
    printf "@s2\nAAAA\n+\nIIII\n"
) | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]2$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------- range of observed quality score values

## min, max, range size

DESCRIPTION="--fastq_chars reports the smallest observed quality symbol (I = 73)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "^Qmin 73," && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the smallest observed quality symbol (! = 33)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "^Qmin 33," && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the smallest observed quality symbol (~ = 126)"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "^Qmin 126," && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the largest observed quality symbol (I = 73)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Qmax 73," && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the largest observed quality symbol (! = 33)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Qmax 33," && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the largest observed quality symbol (~ = 126)"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Qmax 126," && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# min range = 1
# max range = 93

DESCRIPTION="--fastq_chars reports the observed quality symbol range (minimal range = 1)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Range 1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the observed quality symbol range (maximal range = 94)"
printf "@s\nAA\n+\n!~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Range 94$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------- quality values reported

DESCRIPTION="--fastq_chars reports the smallest observed quality value (I = 40)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_qmin 40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the smallest observed quality value (! = 0)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_qmin 0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## guess offset 64, so quality value is 62
DESCRIPTION="--fastq_chars reports the smallest observed quality value (~ = 93)"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_qmin 62" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the largest observed quality value (I = 40)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_qmax 40" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the largest observed quality value (! = 0)"
printf "@s\nA\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_qmax 0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## guess offset 64, so quality value is 62
DESCRIPTION="--fastq_chars reports the largest observed quality value (~ = 93)"
printf "@s\nA\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_qmax 62" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------- fastq offset guess

#  !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
#  |                         |    |        |              |               |                     |
# 33                        59   64       73             88             104                   126
#  0........................26...31.......40.
#                           -5....0........9.............................40.

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 33 to 63 -> +33)"
printf "@s\nAA\n+\n!?\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 33 to 73 -> +33)"
printf "@s\nAA\n+\n!I\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 33 to 74 -> +33)"
printf "@s\nAA\n+\n!J\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 33 to 126 -> +33)"
printf "@s\nAA\n+\n!~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 63 to 74 -> +33)"
printf "@s\nAA\n+\n?J\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 58 to 126 -> +33)"
printf "@s\nAA\n+\n:~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 64 to 104 -> +64)"
printf "@s\nAA\n+\n@h\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 64$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 64 to 105 -> +64)"
printf "@s\nAA\n+\n@i\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 64$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 64 to 126 -> +64)"
printf "@s\nAA\n+\n@~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 64$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## offset +64 extends to -5
DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 59 to 104 -> +64)"
printf "@s\nAA\n+\n;h\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 64$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 59 to 126 -> +64)"
printf "@s\nAA\n+\n;~\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 64$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ambiguous range: 59-74, either low +64 quality values or high +33
## quality values ; favor +33
DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 59 to 74 -> +33)"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ambiguous range: 64-74, either low +64 quality values or high +33
## quality values ; favor +33
DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 64 to 74 -> +33)"
printf "@s\nAA\n+\n@J\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ambiguous range: 64-73, either low +64 quality values or high +33
## quality values ; favor +33
DESCRIPTION="--fastq_chars reports the most likely quality offset (ascii 64 to 73 -> +33)"
printf "@s\nAA\n+\n@I\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "\-fastq_ascii 33$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------- fastq version guess

DESCRIPTION="--fastq_chars reports the most likely version (ascii 59 to 104 -> Solexa +64)"
printf "@s\nAA\n+\n;h\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Solexa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## the Solexa encoding is solexa+64, not phred+64: it shares the offset
## with Illumina 1.3+ but defines its scores as -10 log10(p / (1 - p)),
## and vsearch has only the Phred formula
DESCRIPTION="--fastq_chars names the Solexa encoding solexa+64, not supported"
printf "@s\nAA\n+\n;h\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "^Guess: Solexa format (solexa+64, not supported)$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely version (ascii 64 to 104 -> Illumina 1.3 +64)"
printf "@s\nAA\n+\n@h\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Illumina 1\.3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely version (ascii 66 to 104 -> Illumina 1.5 +64)"
printf "@s\nAA\n+\nBh\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Illumina 1\.5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely version (ascii 33 to 73 -> Sanger +33)"
printf "@s\nAA\n+\n!I\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Sanger" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars reports the most likely version (ascii 33 to 74 -> Illumina 1.8 +33)"
printf "@s\nAA\n+\n!J\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "Illumina 1\.8" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------------------- fastq_tail

# --fastq_tail positive integer

# When using --fastq_chars, count the number of times a series of
# characters of length k appears at the end of quality strings. By
# default, k = 4.

DESCRIPTION="--fastq_chars --fastq_tail is accepted"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 4 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail accepts integers (1)"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 1 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## signed 2^8
DESCRIPTION="--fastq_chars --fastq_tail accepts integers (127)"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 127 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## 2^8
DESCRIPTION="--fastq_chars --fastq_tail accepts integers (256)"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 256 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## signed 2^16
DESCRIPTION="--fastq_chars --fastq_tail accepts integers (32767)"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 32767 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## 2^16
DESCRIPTION="--fastq_chars --fastq_tail accepts integers (65536)"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 65536 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## signed 2^32
DESCRIPTION="--fastq_chars --fastq_tail accepts integers (2147483647)"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 2147483647 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## 2^32
DESCRIPTION="--fastq_chars --fastq_tail accepts integers (4294967296)"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 4294967296 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail rejects a null value"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 0 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail rejects a negative value"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail -1 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail rejects a floating value"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 1.0 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail rejects a char"
printf "@s\nAA\n+\n;J\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail A 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail 1 counts a tail-occurrence for each symbol"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 1 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail 1 counts a tail-occurrence for each symbol (two Is)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 1 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail 2 count 0 tail-occurrence (one I)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 2 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail 2 counts a tail-occurrence (two Is)"
printf "@s\nAA\n+\nII\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 2 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --fastq_tail 2 counts a tail-occurrence (three Is)"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 2 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# below threshold, tail length > sequence length
DESCRIPTION="--fastq_chars --fastq_tail is set to 4 by default (three Is)"
printf "@s\nAAA\n+\nIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# equal to threshold
DESCRIPTION="--fastq_chars --fastq_tail is set to 4 by default (four Is)"
printf "@s\nAAAA\n+\nIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# above threshold
DESCRIPTION="--fastq_chars --fastq_tail is set to 4 by default (five Is)"
printf "@s\nAAAAA\n+\nIIIII\n" | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -qE "[[:blank:]]'I'[[:blank:]].*[[:blank:]]1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 'Char' section is empty when input sequence is empty
DESCRIPTION="--fastq_chars --fastq_tail 1 accepts empty sequence"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_tail 1 2>&1 | \
    grep -i -A 2 "Tails" | \
    tail -n 1 | \
    grep -qE "[-]{4}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#


# The valid options for the fastq_chars command are:
# --bzip2_decompress --gzip_decompress --log --no_progress --quiet
# --threads

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--fastq_chars --bzip2_decompress is accepted (normal input)"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_chars - \
        --bzip2_decompress 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars rejects compressed stdin (default, bzip2)"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_chars - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --bzip2_decompress is accepted (empty inputs)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_chars - \
        --bzip2_decompress 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --bzip2_decompress rejects uncompressed stdin"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --bzip2_decompress 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--fastq_chars --gzip_decompress is accepted (compressed inputs)"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_chars - \
        --gzip_decompress 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars rejects compressed stdin (gzip)"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_chars - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_chars - \
        --gzip_decompress 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --gzip_decompress accepts compressed stdin"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_chars - \
        --gzip_decompress 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# more flexible than bzip2
DESCRIPTION="--fastq_chars --gzip_decompress accepts uncompressed stdin"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --gzip_decompress 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars rejects --bzip2_decompress + --gzip_decompress"
printf "" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --bzip2_decompress \
        --gzip_decompress 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--fastq_chars --log is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --log /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --log writes to a file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --log - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --log + --quiet prevents messages to be sent to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --log reports time and memory"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --log - 2> /dev/null | \
    grep -q "memory" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --log reports guesses"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --log - 2> /dev/null | \
    grep -qi "guess" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --log also reports guesses on stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --log /dev/null 2>&1 | \
    grep -qi "guess" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--fastq_chars --no_progress is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --no_progress 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--fastq_chars --no_progress removes progressive report on stderr (no visible effect)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --no_progress 2>&1 | \
    grep -iq "^reading" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--fastq_chars --quiet is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --quiet eliminates all (normal) messages to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --quiet allows error messages to be sent to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --quiet \
        --quiet2 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--fastq_chars --threads is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --threads 1 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_chars --threads > 1 triggers a warning (not multithreaded)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --threads 2 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

## --fastq_chars is the command that names the Solexa encoding in its own
## output ("Guess: Solexa format"), so it is where a user meets the format
## and reaches for --fastq_solexa next. That option belongs to
## --fastq_convert alone, which is the only command that converts a Solexa
## score to a Phred one; every other command still refuses Solexa data.
DESCRIPTION="--fastq_chars rejects --fastq_solexa (--fastq_convert only)"
printf "@s\nA\n+\nh\n" | \
    "${VSEARCH}" \
        --fastq_chars - \
        --fastq_solexa \
        --quiet 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if [[ "${VALGRIND_WORKS}" == "true" ]] ; then
    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastq_chars <(printf "@s\nA\n+\nI\n") \
        --log /dev/null 2> /dev/null
    DESCRIPTION="--fastq_chars valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastq_chars valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP
fi


#*****************************************************************************#
#                                                                             #
#                    suspicious quality offset (warning)                      #
#                                                                             #
#*****************************************************************************#

## Since 3.0 --fastq_qmax accepts every score the encoding can represent, so a
## phred+64 file read at the default offset 33 is no longer stopped by the
## bound. The reader instead warns when the quality symbols it saw contradict
## --fastq_ascii, using the same heuristic --fastq_chars prints its guess from.

## a phred+64 file ('h' is Q40 at offset 64) read at the default offset 33
DESCRIPTION="a phred+64 file read at offset 33 triggers a warning"
awk 'BEGIN {for (i = 1; i <= 200; i++) printf "@r%d\nACGTACGTAC\n+\nhhhhhhhhhh\n", i}' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null 2>&1 | \
    grep -q "which looks like phred+64" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## the same file read with the right offset says nothing
DESCRIPTION="a phred+64 file read at offset 64 triggers no warning"
awk 'BEGIN {for (i = 1; i <= 200; i++) printf "@r%d\nACGTACGTAC\n+\nhhhhhhhhhh\n", i}' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastq_ascii 64 \
        --fastaout /dev/null 2>&1 | \
    grep -q "which looks like" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## an ordinary Sanger file says nothing
DESCRIPTION="a phred+33 file read at offset 33 triggers no warning"
awk 'BEGIN {for (i = 1; i <= 200; i++) printf "@r%d\nACGTACGTAC\n+\nIIII#IIIII\n", i}' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null 2>&1 | \
    grep -q "which looks like" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --quiet never suppresses a warning (see option_quiet.md)
DESCRIPTION="the suspicious-offset warning survives --quiet"
awk 'BEGIN {for (i = 1; i <= 200; i++) printf "@r%d\nACGTACGTAC\n+\nhhhhhhhhhh\n", i}' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -q "which looks like phred+64" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## the threshold is a record count, not an ordinal: exactly 100 records is
## enough evidence, 99 is not
DESCRIPTION="the suspicious-offset warning fires at exactly 100 records"
awk 'BEGIN {for (i = 1; i <= 100; i++) printf "@r%d\nACGTACGTAC\n+\nhhhhhhhhhh\n", i}' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null 2>&1 | \
    grep -q "which looks like phred+64" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="the suspicious-offset warning is silent at 99 records"
awk 'BEGIN {for (i = 1; i <= 99; i++) printf "@r%d\nACGTACGTAC\n+\nhhhhhhhhhh\n", i}' | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null 2>&1 | \
    grep -q "which looks like" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## too few records is not evidence: a heuristic needs a sample, and small
## hand-made files would otherwise warn constantly
DESCRIPTION="a file below the sampling threshold triggers no warning"
printf "@r1\nACGTACGTAC\n+\nhhhhhhhhhh\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --fastaout /dev/null 2>&1 | \
    grep -q "which looks like" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --fastq_chars is the diagnostic itself and prints its own guess, so it must
## not also emit the reader's warning
DESCRIPTION="--fastq_chars reports its guess without the reader warning"
awk 'BEGIN {for (i = 1; i <= 200; i++) printf "@r%d\nACGTACGTAC\n+\nhhhhhhhhhh\n", i}' | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "which looks like" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_chars still guesses phred+64 for the same input"
awk 'BEGIN {for (i = 1; i <= 200; i++) printf "@r%d\nACGTACGTAC\n+\nhhhhhhhhhh\n", i}' | \
    "${VSEARCH}" \
        --fastq_chars - 2>&1 | \
    grep -q "phred+64" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#

# input accepts any ASCII character in sequence (permissive? as should
# be a diagnostic tool?)


exit 0
