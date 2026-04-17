#!/bin/bash -
# shellcheck disable=SC2015

## Print a header
SCRIPT_NAME="orient"
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

# (see the manpage vsearch-orient.1 for more details)
# vsearch --orient fastxfile --db fastxfile (--fastaout | --fastqout | --notmatched | --tabbedout) outputfile [options]


#*****************************************************************************#
#                                                                             #
#                            default behaviour                                #
#                                                                             #
#*****************************************************************************#

# typical usage of vsearch --orient

# for some tests, the input sequences need to be long enough. The
# orientation algorithm works on 12-mers, and requires that one strand
# shares 4× more words than the other to avoid an undetermined
# result. With very short sequences, you'll frequently get ?
# (undetermined) results rather than + or -.

# This is the biggest practical trap. The # todo: note at the bottom
# hints at this but doesn't give Claude enough guidance to avoid
# it. You should explicitly tell Claude that test sequences need to be
# at least ~30–50 nt long and crafted so that k-mer ratios are
# unambiguous, or provide a known-good example pair.


# 12-nt is enough to trigger a forward match with db sequence (Forward oriented sequences)
SEQ="GACAGGTACAAG"
vsearch \
    --orient <(printf ">s\n%s\n" "${SEQ}") \
    --db <(printf ">s\n%s\n" "${SEQ}") \
    --fastaout -
unset SEQ

# 12-nt is enough to trigger a reverse match with db sequence (Reverse oriented sequences)
SEQ1="GACAGGTACAAG"
SEQ2="CTTGTACCTGTC"  # reverse-complement of SEQ1 (all k-mers match on
                     # the reverse strand, and zero on the forward )
vsearch \
    --orient <(printf ">s\n%s\n" "${SEQ1}") \
    --db <(printf ">s\n%s\n" "${SEQ2}") \
    --fastaout -
unset SEQ1 SEQ2

# to use simple sequences, we need to use masking
SEQ="AAAAAAAAAAAA"
vsearch \
    --orient <(printf ">s\n%s\n" "${SEQ}") \
    --qmask "none" \
    --dbmask "none" \
    --db <(printf ">s\n%s\n" "${SEQ}") \
    --fastaout -
unset SEQ

# use this python code to generate sequences with a precise number of 12-mers:

# for example: SEQ="GACAGGTACAAGAAGGAGTATGCAT"

# python3 -c "
# import random, sys
# random.seed(42)
# bases = 'ACGT'
# while True:
#     seq = ''.join(random.choices(bases, k=25))
#     kmers = [seq[i:i+12] for i in range(len(seq)-11)]
#     if len(kmers) == len(set(kmers)):
#         print(seq)
#         break
# "

#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

# option --threads goes here

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

## very slow, deactivate for now
## valgrind: search for errors and memory leaks
# if which valgrind > /dev/null 2>&1 ; then

#     LOG=$(mktemp)
#     FASTQ=$(mktemp)
#     DB=$(mktemp)
#     printf "@s\nACC\n+\nIII\n" > "${FASTQ}"
#     printf "@s\nGGT\n+\nIII\n" > "${DB}"
#     valgrind \
#         --log-file="${LOG}" \
#         --leak-check=full \
#         "${VSEARCH}" \
#         --orient "${FASTQ}" \
#         --db "${DB}" \
#         --fastaout /dev/null \
#         --fastqout /dev/null \
#         --notmatched /dev/null \
#         --tabbedout /dev/null \
#         --log /dev/null 2> /dev/null
#     DESCRIPTION="--orient valgrind (no leak memory)"
#     grep -q "in use at exit: 0 bytes" "${LOG}" && \
#         success "${DESCRIPTION}" || \
#             failure "${DESCRIPTION}"
#     DESCRIPTION="--orient valgrind (no errors)"
#     grep -q "ERROR SUMMARY: 0 errors" "${LOG}" && \
#         success "${DESCRIPTION}" || \
#             failure "${DESCRIPTION}"
#     rm -f "${LOG}" "${FASTQ}" "${DB}"
# fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#

# todo:
# - create a small minimal example,
# - test exact sequences (normal),
# - test exact sequences (anti-sens),
# - test sequences with a few errors,

exit 0
