#!/bin/bash -

## Print a header
SCRIPT_NAME="Unclassified tests"
LINE=$(printf "%76s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    # exit 1
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
#                    Clustering UC format CIGAR alignment                     #
#                                                                             #
#*****************************************************************************#

## usearch 6, 7 and 8 output a "=" when the sequences are strictly identical
DESCRIPTION="CIGAR string is \'=\' when the sequences are identical"
UC_OUT=$("${VSEARCH}" \
             --cluster_fast <(printf ">seq1\nACGT\n>seq2\nACGT\n") \
             --id 0.97 \
             --quiet \
             --minseqlength 1 \
             --uc - | grep "^H" | cut -f 8)

[[ "${UC_OUT}" == "=" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## clean
unset UC_OUT


## usearch 6 and 7 output a "=" when the sequences are identical
## (terminal gaps ignored), usearch 8 seems to behave differently
DESCRIPTION="CIGAR string is \'=\' when the sequences are identical (terminal gaps ignored)"
UC_OUT=$("${VSEARCH}" \
             --cluster_fast <(printf ">seq1\nACGT\n>seq2\nACG\n") \
             --id 0.97 \
             --quiet \
             --minseqlength 1 \
             --uc - | grep "^H" | cut -f 8)

[[ "${UC_OUT}" == "=" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## clean
unset UC_OUT


## is the 3rd column of H the query length or the alignment length?
DESCRIPTION="when clustering, 3rd column of H in --uc is the query length"
UC_OUT=$("${VSEARCH}" \
             --cluster_fast <(printf ">seq1\nACGT\n>seq2\nACAGT\n") \
             --id 0.5 \
             --quiet \
             --minseqlength 1 \
             --uc - | grep "^H")

awk 'BEGIN {FS = "\t"} {$3 == 4 && $9 == "seq1"}' <<< "${UC_OUT}" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## clean
unset UC_OUT


## when clustering, in --uc output, the highest number in the 2nd
## column of H entries is smaller or equal to the number of input
## sequences (number of S and H lines, minus one)
DESCRIPTION="when clustering (--uc output), the 2nd column of H is the centroid's ordinal number"
INPUT=">seq1\nAAAA\n>seq2\nAAAT\n>seq3\nGGGG\n>seq4\nGGGC\n"

UC_OUT=$("${VSEARCH}" \
    --cluster_fast <(printf ${INPUT}) \
    --id 0.75 \
    --quiet \
    --minseqlength 1 \
    --uc -)

awk 'BEGIN {FS = "\t" ; H = 0 ; seq = -1}
     {if (/^S/ || /^H/) {seq += 1}
      if (/^H/) {if (H < $2) {H = $2}}}
     END {if (H > seq - 1) {exit 1}}' <<< "${UC_OUT}" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## clean
unset UC_OUT


#*****************************************************************************#
#                                                                             #
#                        UC format when dereplicating                         #
#                                                                             #
#*****************************************************************************#

## sizein is taken into account
DESCRIPTION="when prefix dereplicating, --uc output accounts for --sizein"
s=$(printf ">seq1;size=3;\nACGT\n>seq2;size=1;\nACGT\n" | \
           "${VSEARCH}" \
               --derep_prefix - \
               --quiet \
               --sizein \
               --minseqlength 1 \
               --uc - | grep "^C" | cut -f 3)

(( ${s} == 4 )) && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# clean
unset s


## vsearch reports H record when sequences have the same length
DESCRIPTION="when prefix dereplicating same length sequences, --uc reports H record"
H=$(printf ">seq1\nACGT\n>seq2\nACGT\n" | \
           "${VSEARCH}" \
               --derep_prefix - \
               --quiet \
               --minseqlength 1 \
               --uc - | grep "^H")

[[ -n ${H} ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# clean
unset H

## vsearch reports H record when sequences have different lengths
DESCRIPTION="when prefix dereplicating a shorter sequence, --uc reports H record"
H=$(printf ">seq1\nACGTA\n>seq2\nACGT\n" | \
           "${VSEARCH}" \
               --derep_prefix - \
               --quiet \
               --minseqlength 1 \
               --uc - | grep "^H")

[[ -n ${H} ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## clean
unset H


## --derep_prefix does not support the option --strand
DESCRIPTION="--derep_prefix does not support the option --strand"
printf ">seq1\nAATT\n>seq2\nTTAA\n" | \
    "${VSEARCH}" \
        --derep_prefix - \
        --quiet \
        --strand both \
        --minseqlength 1 \
        --uc - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success  "${DESCRIPTION}"

# clean
unset H


## --derep_fulllength accepts the option --strand
DESCRIPTION="--derep_fulllength accepts the option --strand"
printf ">seq1\nAATT\n>seq2\nTTAA\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --quiet \
        --strand both \
        --minseqlength 1 \
        --uc /dev/null 2> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# clean
unset H


## --derep_fulllength searches both strands
DESCRIPTION="--derep_fulllength searches both strands"
C=$(printf ">seq1\nAACC\n>seq2\nGGTT\n" | \
           "${VSEARCH}" \
               --derep_fulllength - \
               --quiet \
               --strand both \
               --minseqlength 1 \
               --uc - | grep -c "^C")

# There should be only cluster
(( ${C} == 1 )) && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# clean
unset C


exit 0
