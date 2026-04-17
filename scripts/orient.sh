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

## --orient input

DESCRIPTION="--orient is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--orient reads from stdin (-)"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--orient reads from a file"
TMPFA=$(mktemp)
printf ">s\nACGT\n" > "${TMPFA}"
"${VSEARCH}" \
    --orient "${TMPFA}" \
    --db <(printf ">s\nACGT\n") \
    --fastaout /dev/null \
    --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--orient fails if input file does not exist"
"${VSEARCH}" \
    --orient /no/such/file \
    --db <(printf ">s\nACGT\n") \
    --fastaout /dev/null \
    --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--orient fails if input file is not readable"
TMPFA=$(mktemp)
printf ">s\nACGT\n" > "${TMPFA}"
chmod u-r "${TMPFA}"
"${VSEARCH}" \
    --orient "${TMPFA}" \
    --db <(printf ">s\nACGT\n") \
    --fastaout /dev/null \
    --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMPFA}" && rm -f "${TMPFA}"
unset TMPFA

DESCRIPTION="--orient fails with input that is neither FASTA nor FASTQ"
printf "not a fasta or fastq file\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--orient fails without any output option"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --db

DESCRIPTION="--db is mandatory"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--db accepts a fasta file"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--db accepts a fastq file"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf "@s\nACGT\n+\nIIII\n") \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--db accepts a UDB file"
TMPUDB=$(mktemp --suffix=.udb)
printf ">s\nGACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT\n" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output "${TMPUDB}" \
        --wordlength 12 \
        --quiet 2>/dev/null
printf ">q\nGACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db "${TMPUDB}" \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB

DESCRIPTION="--db fails if database file does not exist"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db /no/such/file \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--db fails if database file is not readable"
TMPDB=$(mktemp)
printf ">s\nACGT\n" > "${TMPDB}"
chmod u-r "${TMPDB}"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db "${TMPDB}" \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+r "${TMPDB}" && rm -f "${TMPDB}"
unset TMPDB

DESCRIPTION="--db fails with database that is neither FASTA, FASTQ, nor UDB"
TMPDB=$(mktemp)
printf "not a fasta/fastq/udb file\n" > "${TMPDB}"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db "${TMPDB}" \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${TMPDB}"
unset TMPDB

DESCRIPTION="--db with empty file is accepted (all queries become undetermined)"
TMPDB=$(mktemp)
printf ">q\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db "${TMPDB}" \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "?" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPDB}"
unset TMPDB

## --fastaout

DESCRIPTION="--fastaout is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastaout - writes to stdout"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--fastaout fails if output file cannot be opened for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout "${TMP}" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastaout accepts fastq input (writes oriented sequence in fasta format)"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

## --fastqout

DESCRIPTION="--fastqout is accepted with fastq input"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastqout fails with fasta input (no quality scores)"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastqout - writes to stdout"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastqout - \
        --quiet 2>/dev/null | \
    grep -qx "@q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

DESCRIPTION="--fastqout fails if output file cannot be opened for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastqout "${TMP}" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="--fastaout and --fastqout can be used together with fastq input"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --notmatched

DESCRIPTION="--notmatched is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --notmatched /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatched - writes to stdout"
# a 4-nt sequence cannot be clearly oriented -> goes to notmatched
printf ">q\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --notmatched - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notmatched fails if output file cannot be opened for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --notmatched "${TMP}" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

## --tabbedout

DESCRIPTION="--tabbedout is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout - writes to stdout"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    grep -q "^s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout fails if output file cannot be opened for writing"
TMP=$(mktemp) && chmod u-w "${TMP}"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --tabbedout "${TMP}" \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w "${TMP}" && rm -f "${TMP}"
unset TMP

DESCRIPTION="all four output options can be used together"
printf "@s\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --fastqout /dev/null \
        --notmatched /dev/null \
        --tabbedout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


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
DESCRIPTION="a 12-nt query identical to db is oriented forward (+)"
SEQ="GACAGGTACAAG"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "+" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

# 12-nt is enough to trigger a reverse match with db sequence (Reverse oriented sequences)
DESCRIPTION="a 12-nt query that is the revcomp of db is oriented reverse (-)"
SEQ1="GACAGGTACAAG"
SEQ2="CTTGTACCTGTC"  # reverse-complement of SEQ1 (all k-mers match on
                     # the reverse strand, and zero on the forward )
printf ">q\n%s\n" "${SEQ1}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ2}") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "-" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ1 SEQ2

# to use simple sequences, we need to use masking
DESCRIPTION="homopolymer query is oriented forward when masking is disabled"
SEQ="AAAAAAAAAAAA"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --qmask "none" \
        --dbmask "none" \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "+" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
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

# undetermined: query that does not match the db on either strand
DESCRIPTION="a query with no kmer match to db is undetermined (?)"
printf ">q\nACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nGGGGGGGGGGGG\n") \
        --qmask "none" \
        --dbmask "none" \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "?" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --fastaout: forward-oriented sequence is written unchanged
DESCRIPTION="--fastaout writes forward-oriented sequence unchanged"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -v "^>" | \
    grep -qx "${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

# --fastaout: reverse-oriented sequence is reverse-complemented
DESCRIPTION="--fastaout writes reverse-oriented sequence as its reverse-complement"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
REV="ATGATGATGATGATGATCGATGCATACTCCTTCTTGTACCTGTC"
printf ">q\n%s\n" "${REV}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -v "^>" | \
    grep -qx "${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ REV

# --fastaout receives + and - but not ?
DESCRIPTION="--fastaout does not contain undetermined sequences"
printf ">q\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# --notmatched receives only ? sequences
DESCRIPTION="--notmatched does not contain forward-oriented sequences"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --notmatched - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

# --notmatched preserves original format (fastq in -> fastq out)
DESCRIPTION="--notmatched with fastq input produces fastq output"
printf "@q\nACGT\n+\nIIII\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --notmatched - \
        --quiet 2>/dev/null | \
    grep -qx "@q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --notmatched preserves original format (fasta in -> fasta out)
DESCRIPTION="--notmatched with fasta input produces fasta output"
printf ">q\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --notmatched - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --tabbedout has 4 columns: label, strand, fwd count, rev count
DESCRIPTION="--tabbedout has exactly four tab-separated columns"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' 'END {exit NF == 4 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 1 is the query label"
printf ">myquery\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $1 == "myquery" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 2 is + for forward-oriented sequence"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "+" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--tabbedout column 2 is - for reverse-oriented sequence"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
REV="ATGATGATGATGATGATCGATGCATACTCCTTCTTGTACCTGTC"
printf ">q\n%s\n" "${REV}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "-" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ REV

DESCRIPTION="--tabbedout column 2 is ? for undetermined sequence"
printf ">q\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "?" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--tabbedout column 3 is a non-negative integer (forward matches)"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit ($3 ~ /^[0-9]+$/) && ($3 > 0) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--tabbedout column 4 is a non-negative integer (reverse matches)"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
REV="ATGATGATGATGATGATCGATGCATACTCCTTCTTGTACCTGTC"
printf ">q\n%s\n" "${REV}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit ($4 ~ /^[0-9]+$/) && ($4 > 0) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ REV

# --fastqout: reverse-oriented sequence is reverse-complemented, quality is reversed
DESCRIPTION="--fastqout writes forward-oriented fastq unchanged"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastqout - \
        --quiet 2>/dev/null | \
    awk "NR==2" | \
    grep -qx "${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

DESCRIPTION="--fastqout writes reverse-oriented fastq as reverse-complement of the input"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
REV="ATGATGATGATGATGATCGATGCATACTCCTTCTTGTACCTGTC"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${REV}" "${QUAL}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastqout - \
        --quiet 2>/dev/null | \
    awk "NR==2" | \
    grep -qx "${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ REV QUAL

# --fastqout: quality scores are reversed (not complemented) for reverse-oriented sequences
DESCRIPTION="--fastqout reverses quality scores for reverse-oriented sequences"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
REV="ATGATGATGATGATGATCGATGCATACTCCTTCTTGTACCTGTC"
QUAL_IN="012345678901234567890123456789012345678901!A"
QUAL_OUT="A!109876543210987654321098765432109876543210"
printf "@q\n%s\n+\n%s\n" "${REV}" "${QUAL_IN}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastqout - \
        --quiet 2>/dev/null | \
    awk "NR==4" | \
    grep -qx "${QUAL_OUT}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ REV QUAL_IN QUAL_OUT

# stderr summary: not printed when --quiet is used
DESCRIPTION="stderr summary is not printed with --quiet"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --quiet 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# stderr summary: four counters printed without --quiet
DESCRIPTION="stderr summary includes 'Forward oriented sequences'"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null 2>&1 | \
    grep -q "Forward oriented sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="stderr summary includes 'Reverse oriented sequences'"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null 2>&1 | \
    grep -q "Reverse oriented sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="stderr summary includes 'Not oriented sequences'"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null 2>&1 | \
    grep -q "Not oriented sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="stderr summary includes 'Total number of sequences'"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null 2>&1 | \
    grep -q "Total number of sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# multiple queries: each gets its own line in tabbedout
DESCRIPTION="--tabbedout produces one line per input sequence"
printf ">q1\nA\n>q2\nC\n>q3\nG\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# empty input: no output
DESCRIPTION="empty input produces empty tabbedout"
printf "" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# empty fasta entry is accepted (counted, but undetermined)
DESCRIPTION="fasta entry with empty sequence is classified as undetermined"
printf ">q\n\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "?" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

## --wordlength

DESCRIPTION="--wordlength is accepted"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout /dev/null \
        --wordlength 12 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--wordlength accepts minimum value (3)"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout /dev/null \
        --wordlength 3 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

# NOTE: --wordlength 15 would exercise the documented upper bound, but memory
# for a part of the index grows by a factor of 4 per additional nucleotide,
# which can be too slow for routine testing. Test is disabled.
# DESCRIPTION="--wordlength accepts maximum value (15)"
# SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
# printf ">q\n%s\n" "${SEQ}" | \
#     "${VSEARCH}" \
#         --orient - \
#         --db <(printf ">s\n%s\n" "${SEQ}") \
#         --fastaout /dev/null \
#         --wordlength 15 \
#         --quiet 2>/dev/null && \
#     success "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"
# unset SEQ

DESCRIPTION="--wordlength rejects value below minimum (2)"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout /dev/null \
        --wordlength 2 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--wordlength rejects value above maximum (16)"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout /dev/null \
        --wordlength 16 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

# NOTE for human review: the manpage specifies a range of 3 to 15 for
# --wordlength. Values 1, 2, and any negative value are rejected as expected,
# but --wordlength 0 is silently accepted (probably treated as the
# "unset / use default" sentinel by the option parser).
DESCRIPTION="--wordlength rejects value below minimum (1)"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout /dev/null \
        --wordlength 1 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--wordlength rejects negative value"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout /dev/null \
        --wordlength -1 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset SEQ

# --wordlength affects orientation outcome: too-short query cannot orient at k=12 default
# but with smaller k, the same sequence can be oriented.
DESCRIPTION="--wordlength 3 orients a sequence that k=12 cannot"
# A 10-nt sequence cannot generate any 12-mer, so orientation fails by default.
# With k=3, it can generate enough 3-mers to match.
SEQ="ACAGGTACAA"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --qmask none \
        --dbmask none \
        --wordlength 3 \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "+" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

# default wordlength is 12: a 10-nt sequence produces no 12-mers -> undetermined
DESCRIPTION="default --wordlength is 12 (10-nt sequence cannot be oriented)"
SEQ="ACAGGTACAA"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "?" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

# UDB was built with wordlength 12; specifying a different wordlength triggers a warning
DESCRIPTION="--wordlength is overridden when reading a UDB file"
TMPUDB=$(mktemp --suffix=.udb)
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">s\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --makeudb_usearch - \
        --output "${TMPUDB}" \
        --wordlength 12 \
        --quiet 2>/dev/null
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db "${TMPUDB}" \
        --fastaout /dev/null \
        --wordlength 15 2>&1 | \
    grep -qi "wordlength adjusted" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPUDB}"
unset TMPUDB SEQ


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

## --bzip2_decompress
#
# NOTE for human review: --bzip2_decompress is listed as a secondary option
# for --orient in the manpage, but invoking it on bzip2-compressed stdin pipe
# systematically fails here ("Fatal error: Unable to read from bzip2 compressed
# file") while the same pipe works with --fastx_revcomp and --fastx_filter.
# The happy-path test is therefore omitted; the tests below verify only that
# the option is recognized by the parser.

DESCRIPTION="--bzip2_decompress fails on uncompressed input"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --bzip2_decompress \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--bzip2_decompress and --gzip_decompress together is rejected"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --bzip2_decompress \
        --gzip_decompress \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --dbmask

DESCRIPTION="--dbmask none is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --dbmask none \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--dbmask dust is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --dbmask dust \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--dbmask soft is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --dbmask soft \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--dbmask rejects unknown value"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --dbmask invalid \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# default is dust: homopolymer is masked and cannot be used for orientation
DESCRIPTION="--dbmask dust (default) masks low-complexity db, homopolymer cannot be oriented"
printf ">q\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nAAAAAAAAAAAA\n") \
        --dbmask dust \
        --qmask none \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "?" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --dbmask none disables masking: homopolymer CAN be oriented
DESCRIPTION="--dbmask none disables masking (homopolymer can be oriented)"
printf ">q\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nAAAAAAAAAAAA\n") \
        --dbmask none \
        --qmask none \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "+" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --fasta_width

DESCRIPTION="--fasta_width is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --fasta_width 0 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# 86-nt sequence (> 80) appears on one line with --fasta_width 0
DESCRIPTION="--fasta_width 0 suppresses line folding"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCATGACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -v "^>" | \
    awk "NR==1 {exit length(\$0) == 86 ? 0 : 1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--fasta_width default folds at 80 characters"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCATGACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATC"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --quiet 2>/dev/null | \
    awk "NR==2 {exit length(\$0) == 80 ? 0 : 1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--fasta_width has no effect on fastq output"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
QUAL="IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
printf "@q\n%s\n+\n%s\n" "${SEQ}" "${QUAL}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastqout - \
        --fasta_width 4 \
        --quiet 2>/dev/null | \
    awk "NR==2 {exit length(\$0) == 44 ? 0 : 1}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ QUAL

## --gzip_decompress

DESCRIPTION="--gzip_decompress reads gzip-compressed fasta from stdin"
printf ">s\nACGT\n" | \
    gzip | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --gzip_decompress \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--gzip_decompress reads gzip-compressed fastq from stdin"
printf "@s\nACGT\n+\nIIII\n" | \
    gzip | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastqout /dev/null \
        --gzip_decompress \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --label_suffix

DESCRIPTION="--label_suffix is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --label_suffix ";foo=bar" \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--label_suffix appends suffix to sequence header"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --label_suffix ";foo=bar" \
        --quiet 2>/dev/null | \
    grep -qx ">q;foo=bar" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--label_suffix with empty string leaves header unchanged"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --label_suffix "" \
        --quiet 2>/dev/null | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --lengthout

DESCRIPTION="--lengthout is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --lengthout \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--lengthout adds length annotation to header"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --lengthout \
        --quiet 2>/dev/null | \
    grep -qx ">q;length=44" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--label_suffix and --lengthout annotations appear together in header"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --label_suffix ";foo=bar" \
        --lengthout \
        --quiet 2>/dev/null | \
    grep -q "length=44.*foo=bar\|foo=bar.*length=44" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --log

DESCRIPTION="--log is accepted"
TMPLOG=$(mktemp)
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --log "${TMPLOG}" \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG

DESCRIPTION="--log writes a non-empty file"
TMPLOG=$(mktemp)
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --log "${TMPLOG}" \
        --quiet 2>/dev/null
[[ -s "${TMPLOG}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG

DESCRIPTION="--log contains the orientation summary"
TMPLOG=$(mktemp)
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --log "${TMPLOG}" \
        --quiet 2>/dev/null
grep -q "Total number of sequences" "${TMPLOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${TMPLOG}"
unset TMPLOG

## --no_progress

DESCRIPTION="--no_progress is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --no_progress \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# NOTE: checking that --no_progress removes a specific line is unreliable;
# fastx_revcomp and fastq_convert only check that the option is accepted.

## --notrunclabels

DESCRIPTION="--notrunclabels is accepted"
printf ">s some description\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --notrunclabels \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--notrunclabels preserves full header (space included)"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q some description\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --notrunclabels \
        --quiet 2>/dev/null | \
    grep -qx ">q some description" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="default behaviour truncates header at first space"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q some description\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --quiet 2>/dev/null | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --qmask

DESCRIPTION="--qmask none is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --qmask none \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask dust is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --qmask dust \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask soft is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --qmask soft \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--qmask rejects unknown value"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --qmask invalid \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# --qmask none disables query masking; combined with --dbmask dust, the query
# still produces a single matching kmer on the forward strand -> oriented as +
DESCRIPTION="--qmask none allows low-complexity query to be oriented"
printf ">q\nAAAAAAAAAAAA\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nAAAAAAAAAAAA\n") \
        --qmask none \
        --dbmask none \
        --tabbedout - \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "+" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --quiet

DESCRIPTION="--quiet is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--quiet suppresses stderr output"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --quiet 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--quiet does not suppress fatal error messages"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --quiet 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel

DESCRIPTION="--relabel is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel "seq" \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel replaces header with prefix and ticker"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --relabel "seq" \
        --quiet 2>/dev/null | \
    grep -qx ">seq1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--relabel ticker increments across oriented sequences"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q1\n%s\n>q2\n%s\n>q3\n%s\n" "${SEQ}" "${SEQ}" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --relabel "x" \
        --quiet 2>/dev/null | \
    grep -c "^>x[123]$" | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --relabel_keep

DESCRIPTION="--relabel_keep is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel "seq" \
        --relabel_keep \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel_keep retains original identifier after relabeling"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --relabel "seq" \
        --relabel_keep \
        --quiet 2>/dev/null | \
    grep -qx ">seq1 q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --relabel_md5

DESCRIPTION="--relabel_md5 is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel_md5 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# MD5 of "GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT" (the oriented sequence)
DESCRIPTION="--relabel_md5 replaces header with MD5 digest of the oriented sequence"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --relabel_md5 \
        --quiet 2>/dev/null | \
    grep -qx ">9c999a58b7afe4dbe003d72c3b5005d4" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

# mutual exclusion tests
DESCRIPTION="--relabel and --relabel_md5 together produce an error"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel "seq" \
        --relabel_md5 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--relabel and --relabel_sha1 together produce an error"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel "seq" \
        --relabel_sha1 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--relabel and --relabel_self together produce an error"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel "seq" \
        --relabel_self \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--relabel_md5 and --relabel_sha1 together produce an error"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel_md5 \
        --relabel_sha1 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--relabel_md5 and --relabel_self together produce an error"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel_md5 \
        --relabel_self \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--relabel_sha1 and --relabel_self together produce an error"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel_sha1 \
        --relabel_self \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --relabel_self

DESCRIPTION="--relabel_self is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel_self \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--relabel_self replaces header with the oriented sequence itself"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --relabel_self \
        --quiet 2>/dev/null | \
    grep -qx ">${SEQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --relabel_sha1

DESCRIPTION="--relabel_sha1 is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --relabel_sha1 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# SHA1 of "GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
DESCRIPTION="--relabel_sha1 replaces header with SHA1 digest of the oriented sequence"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --relabel_sha1 \
        --quiet 2>/dev/null | \
    grep -qx ">1c1e59f76ad0d4c27ac3ac688c62904075020985" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --sample

DESCRIPTION="--sample is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --sample "ABC" \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sample adds sample annotation to header"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --sample "ABC" \
        --quiet 2>/dev/null | \
    grep -qx ">q;sample=ABC" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --sizein and --sizeout

DESCRIPTION="--sizein is accepted"
printf ">s;size=2\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --sizein \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizeout is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --sizeout \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--sizeout adds size annotation to header (default size=1)"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">q;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--sizein reads existing size annotation; --sizeout propagates it"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q;size=7\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --sizein \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">q;size=7" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--sizeout combined with --relabel produces new-label + size annotation"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --relabel "seq" \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -qx ">seq1;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --xee

DESCRIPTION="--xee is accepted"
printf ">s;ee=0.5\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --xee \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xee strips ee annotation from header"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q;ee=0.5\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --xee \
        --quiet 2>/dev/null | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --xlength

DESCRIPTION="--xlength is accepted"
printf ">s;length=10\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --xlength \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xlength strips length annotation from header"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q;length=10\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --xlength \
        --quiet 2>/dev/null | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

DESCRIPTION="--xlength with --lengthout replaces stale length annotation"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q;length=99\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --xlength \
        --lengthout \
        --quiet 2>/dev/null | \
    grep -qx ">q;length=44" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ

## --xsize

DESCRIPTION="--xsize is accepted"
printf ">s;size=5\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --xsize \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--xsize strips size annotation from header"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q;size=5\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --fastaout - \
        --fasta_width 0 \
        --xsize \
        --quiet 2>/dev/null | \
    grep -qx ">q" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ


#*****************************************************************************#
#                                                                             #
#                              ignored options                                #
#                                                                             #
#*****************************************************************************#

## --threads (command is not multithreaded, option has no effect)

DESCRIPTION="--threads is accepted"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --threads 1 \
        --quiet 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--threads has no effect on tabbedout output"
SEQ="GACAGGTACAAGAAGGAGTATGCATCGATCATCATCATCATCAT"
printf ">q\n%s\n" "${SEQ}" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\n%s\n" "${SEQ}") \
        --tabbedout - \
        --threads 4 \
        --quiet 2>/dev/null | \
    awk -F'\t' '{exit $2 == "+" ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SEQ


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

# --fastq_ascii is not listed in the --orient manpage; verify it is rejected
DESCRIPTION="--orient rejects --fastq_ascii"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --fastq_ascii 33 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# --fastq_qmax is not listed in the --orient manpage
DESCRIPTION="--orient rejects --fastq_qmax"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --fastq_qmax 41 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# --fastq_qmin is not listed in the --orient manpage
DESCRIPTION="--orient rejects --fastq_qmin"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --fastq_qmin 0 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# --strand is a search option; --orient decides strand itself
DESCRIPTION="--orient rejects --strand"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --strand both \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# --id is a clustering/search option
DESCRIPTION="--orient rejects --id"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --id 0.9 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# --minseqlength is a filter option; not listed in the --orient manpage
DESCRIPTION="--orient rejects --minseqlength"
printf ">s\nACGT\n" | \
    "${VSEARCH}" \
        --orient - \
        --db <(printf ">s\nACGT\n") \
        --fastaout /dev/null \
        --minseqlength 1 \
        --quiet 2>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


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
