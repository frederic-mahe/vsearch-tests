#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="masking options"
LINE=$(printf -- "-%.0s" {1..76})
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
#                                fastx_mask                                   #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask is accepted"
OUTPUT=$(mktemp)
printf '>seq1\nA\n' | \
    "${VSEARCH}" --fastx_mask - --fastaout "${OUTPUT}"  &> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_mask if argument given is not valid"
OUTPUT=$(mktemp)
"${VSEARCH}" --fastx_mask OUTEST --output "${OUTPUT}"  &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_mask if no argument"
OUTPUT=$(mktemp)
"${VSEARCH}" --output "${OUTPUT}" --fastx_mask  &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_mask --fastaout is accepted"
printf ">seq1\nACG" | \
    "${VSEARCH}" --fastx_mask - fastaout - &> /dev/null 
success "${DESCRIPTION}" || \
    failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --fastqout is accepted"
printf "@seq1\nACG\n+\n!!!" | \
    "${VSEARCH}" --fastx_mask - fastqout - &> /dev/null 
success "${DESCRIPTION}" || \
    failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            fasta hardmask off                               #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask --qmask none output is correct for a fasta input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | "${VSEARCH}" --fastx_mask - --qmask none --fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
               "${EXPECTED}" ]] && \
success "${DESCRIPTION}" || \
failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"
			
DESCRIPTION="--fastx_mask --qmask dust output is correct for a fasta input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn"        
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | "${VSEARCH}" --fastx_mask - --qmask dust --fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
               "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"

DESCRIPTION="--fastx_mask --qmask soft output is correct for a fasta input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"        
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | "${VSEARCH}" --fastx_mask - --qmask soft --fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
               "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"


#*****************************************************************************#
#                                                                             #
#                            fastq hardmask off                               #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask --qmask none output is correct for a fastq input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
QUALITY=$(printf "!%.0s" {1..89})
EXPECTED=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY})
OUTPUT=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY}| "${VSEARCH}" --fastx_mask - --qmask none --fastqout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
              "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "EXPECTED" "OUTPUT"

DESCRIPTION="--fastx_mask --qmask soft output is correct for a fastq input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
QUALITY=$(printf "!%.0s" {1..89})
EXPECTED=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY})
OUTPUT=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY}| "${VSEARCH}" --fastx_mask - --qmask soft --fastqout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
              "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "EXPECTED" "OUTPUT"
DESCRIPTION="--fastx_mask --qmask dust output is correct for a fastq input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
MIDDLE_LC=$(echo $MIDDLE | tr [:upper:] [:lower:])
TAIL="TGCTACAGTATGACCCCACTCCTGG"
QUALITY=$(printf "!%.0s" {1..89})
EXPECTED=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE_LC} ${TAIL} ${QUALITY})
OUTPUT=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY}| "${VSEARCH}" --fastx_mask - --qmask dust --fastqout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
              "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "EXPECTED" "OUTPUT"

#*****************************************************************************#
#                                                                             #
#                            fasta hardmask on                                #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask --qmask none --hardmask output is correct for a fasta input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | "${VSEARCH}" --fastx_mask - --qmask none --hardmask --fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
               "${EXPECTED}" ]] && \
success "${DESCRIPTION}" || \
failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"
			
DESCRIPTION="--fastx_mask --qmask dust --hardmask output is correct for a fasta input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn"        
MIDDLE_UC=$(echo $MIDDLE | tr [:lower:] [:upper:])
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE_UC} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | "${VSEARCH}" --fastx_mask - --qmask dust --hardmask --fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
               "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"

DESCRIPTION="--fastx_mask --qmask soft --hardmask output is correct for a fasta input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"        
TAIL="TGCTACAGTATGACCCCACTCCTGG"
EXPECTED=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL})
OUTPUT=$(printf ">seq1\n%s%s%s\n" ${HEAD} ${MIDDLE} ${TAIL} | "${VSEARCH}" --fastx_mask - --qmask soft --hardmask --fastaout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
               "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"


#*****************************************************************************#
#                                                                             #
#                            fastq hardmask on                                #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask --qmask none --hardmask output is correct for a fastq input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
QUALITY=$(printf "!%.0s" {1..89})
EXPECTED=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY})
OUTPUT=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY}| "${VSEARCH}" --fastx_mask - --qmask none --hardmask --fastqout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
              "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "EXPECTED" "OUTPUT"

DESCRIPTION="--fastx_mask --qmask soft --hardmask output is correct for a fastq input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="TAAAACTTAAAGTATAATAATAATAAAATTAAAAAAAAA"
TAIL="TGCTACAGTATGACCCCACTCCTGG"
QUALITY=$(printf "!%.0s" {1..89})
EXPECTED=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY})
OUTPUT=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY}| "${VSEARCH}" --fastx_mask - --qmask soft --hardmask --fastqout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
              "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "EXPECTED" "OUTPUT"

DESCRIPTION="--fastx_mask --qmask dust --hardmask output is correct for a fastq input"
HEAD="ACCTGCACATTGTGCACATGTACCC"
MIDDLE="NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN"        
TAIL="TGCTACAGTATGACCCCACTCCTGG"
QUALITY=$(printf "!%.0s" {1..89})
EXPECTED=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY})
OUTPUT=$(printf "@seq1\n%s%s%s\n+\n%s" ${HEAD} ${MIDDLE} ${TAIL} ${QUALITY}| "${VSEARCH}" --fastx_mask - --qmask dust --hardmask --fastqout - --fasta_width 0 2> /dev/null)
[[ "${OUTPUT}" == \
              "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "EXPECTED" "OUTPUT"


#*****************************************************************************#
#                                                                             #
#                            max/min_unmasked_pct                             #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_mask --max_unmasked_pct is accepted"
"${VSEARCH}" --fastx_mask <(printf '>seq1\natGC') --qmask soft \
             --hardmask --max_unmasked_pct 0 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct is accepted"
printf '>seq1\natGC' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --min_unmasked_pct 0 --fastaout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct fails if no argument given"
printf '>seq1\natGC' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --max_unmasked_pct --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct fails if no argument given"
printf '>seq1\natGC' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --min_unmasked_pct --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct fails if value given is not valid"
printf '>seq1\natGC' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --max_unmasked_pct toto --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct fails if value given is not valid"
printf '>seq1\natGC' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --min_unmasked_pct toto --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct gives the correct result"
OUTPUT=$(printf '>seq1\natGC\n>seq2\na' | \
		"${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
			     --max_unmasked_pct 49 --fastaout - 2>/dev/null)
[[ "${OUTPUT}" == \
               $(printf '>seq2\nN') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct gives the correct result"
OUTPUT=$(printf '>seq1\natGC\n>seq2\na' | \
		"${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
			     --min_unmasked_pct 50 --fastaout - 2>/dev/null)
[[ "${OUTPUT}" == \
               $(printf '>seq1\nNNGC') ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct fails if value is more than 100"
printf '>seq1\natGC\n>seq2\na' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --max_unmasked_pct 110 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct fails if value is greater than 100"
printf '>seq1\natGC\n>seq2\na' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --min_unmasked_pct 110 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct fails if value is less than 100"
printf '>seq1\natGC\n>seq2\na' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --fastaout - --max_unmasked_pct \-10 --min_unmasked_pct \-40 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct --min_unmasked_pct fails if min between 100 and max with max greater than 100"
printf '>seq1\natGC\n>seq2\na' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --max_unmasked_pct 140 --min_unmasked_pct 110 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct fails if value greater than 100"
printf '>seq1\natGC\n>seq2\na' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --fastaout - --max_unmasked_pct \-1 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --max_unmasked_pct --min_unmasked_pct fails if min less than 0"
printf '>seq1\natGC\n>seq2\na' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --min_unmasked_pct \-1 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct fails if value less than 0"
printf '>seq1\natGC\n>seq2\na' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --min_unmasked_pct -10 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_mask --min_unmasked_pct --max_unmasked_pct fails if min greater than max"
printf '>seq1\natGC\n>seq2\na' | \
    "${VSEARCH}" --fastx_mask - --qmask soft --hardmask \
		 --min_unmasked_pct 60 --max_unmasked_pct 40 --fastaout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

exit 0
