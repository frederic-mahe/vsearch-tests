#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fastq_stats all tests"
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
#                                  Arguments                                  #
#                                                                             #
#*****************************************************************************#

# FASTQ=$(mktemp)
# printf "@illumina33\nGTGAATCATCGAATCTTT\n+\nCCCCCGGGGGGGGGGGGG\n" > "${FASTQ}"
# DESCRIPTION="fastq stats deals with Illumina +33"
# "${VSEARCH}" \
#     --fastq_stats "${QUERY}" \
#     --db "${DATABASE}" \
#     --alnout "${ALNOUT}" \
#     --quiet 2> /dev/null && \
#     success  "${DESCRIPTION}" || \
#         failure "${DESCRIPTION}"
# rm "${FASTQ}"

DESCRIPTION="--fastq_stats is accepted"
printf "@s1\nACGT\n+\nGGGG" |
"${VSEARCH}" --fastq_stats - --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_ascii is accepted"
printf "@s1\nACGT\n+\nGGGG" |
"${VSEARCH}" --fastq_stats - --fastq_ascii 33 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmin is accepted"
printf "@s1\nACGT\n+\nGGGG" |
"${VSEARCH}" --fastq_stats - --fastq_qmin 32 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax is accepted"
printf "@s1\nACGT\n+\nGGGG" |
"${VSEARCH}" --fastq_stats - --fastq_qmin 32 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fails without --log"
printf "@s1\nACGT\n+\nGGGG" |
"${VSEARCH}" --fastq_stats - &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                          Read length distribution                           #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_stats read length is correct #1"
READ_LENGTH=$(printf "@s1\nAC\n+\nGG" | \
		     "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==8 {print $2}' -)
[[ $(printf "${READ_LENGTH}") == "2" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats read length is correct #2"
READ_LENGTH=$(printf "@s1\n\n+\n" | \
		     "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==8 {print $2}' -)
[[ $(printf "${READ_LENGTH}") == "0" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats number of reads is correct #1"
READ_NB=$(printf "@s1\nA\n+\nG" | \
		     "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==8 {print $3}' -)
[[ $(printf "${READ_NB}") == "1" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats number of reads is correct #2"
READ_NB=$(printf "@s1\nA\n+\nG\n@s2\nA\n+\nG" | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==8 {print $3}' -)
[[ $(printf "${READ_NB}") == "2" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats percentage of reads with this length is correct"
READ_PERCENT=$(printf "@s1\nA\n+\nG\n@s2\nAA\n+\nGG\n@s3\nAA\n+\nGG" | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==8 {print $4}' -)
[[ $(echo "${READ_PERCENT}") == "66.7%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fraction of reads with this length or more is correct"
READ_NB=$(printf "@s1\nA\n+\nG\n@s2\nAA\n+\nGG\n@s3\nAAA\n+\nGGG\n" | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==9 {print $5}' -)
[[ $(echo "${READ_PERCENT}") == "66.7%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fraction of reads with this length or more is correct"
READ_NB=$(printf "@s1\nA\n+\nG\n@s2\nAA\n+\nGG\n@s3\nAAA\n+\nGGG\n" | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==9 {print $5}' -)
[[ $(echo "${READ_PERCENT}") == "66.7%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fraction of reads with this length or more is correct"
READ_NB=$(printf "@s1\nA\n+\nG\n@s2\nAA\n+\nGG\n@s3\nAAA\n+\nGGG\n" | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==9 {print $5}' -)
[[ $(echo "${READ_PERCENT}") == "66.7%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                         Quality score distribution                          #
#                                                                             #
#*****************************************************************************#

# DESCRIPTION="--fastq_stats number of reads is correct #2"
# for i in {33..104}
# 	 {
# 	     LETTER=$([ ${i} -lt 256 ] || return i             ## convertit la valeur décimale en lettre
# 		      printf \\$(($i/64*100+$i%64/8*10+$i%8)))
# 	     if [ "${i}" -lt 73 ] ; then     
# 		 READ_NB=$(printf "@s1\nA\n+\n${LETTER}" | \
# 				  "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
# 				  awk 'NR==13{print $1}' -)
# 	     else
# 		 READ_NB=$(printf "@s1\nA\n+\n${LETTER}" | \
# 				  "${VSEARCHg}" --fastq_stats - --log - --fastq_ascii 64 2> /dev/null | \
# 				  awk 'NR==13{print $1}' -)
# 	     fi 
# 	     [[ $(printf "${READ_NB}") == "${LETTER}" ]] && \
# 		 success  "${DESCRIPTION}" || \
# 		     failure "${DESCRIPTION}"
# }

DESCRIPTION="--fastq_stats Phred quality score is correct #1"
E_PROBA=$(printf '@s1\nA\n+\nH\n' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==13 {print $3}' -)
[[ $(printf "${E_PROBA}") == "0.00013" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats Phred quality score is correct #2"
E_PROBA=$(printf '@s1\nA\n+\n"' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==13 {print $3}' -)
[[ $(printf "${E_PROBA}") == "0.79433" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats number of bases with this quality score is correct #1"
BASES_NB=$(printf '@s1\nA\n+\nH\n@s2\nA\n+\nG' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==13 {print $4}' -)
[[ $(echo "${BASES_NB}") == "1" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats number of bases with this quality score is correct #2"
BASES_NB=$(printf '@s1\nA\n+\nG\n@s2\nA\n+\nG' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==13 {print $4}' -)
[[ $(echo "${BASES_NB}") == "2" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats percentage of bases with this quality score is correct"
BASES_PRCT=$(printf '@s1\nA\n+\nG\n@s2\nA\n+\nH\n@s3\nA\n+\nH' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==13 {print $5}' -)
[[ $(echo "${BASES_PRCT}") == "66.7%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats percentage of bases with this quality score is correct"
BASES_PRCT=$(printf '@s1\nA\n+\nG\n@s2\nA\n+\nH\n@s3\nA\n+\nH' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==13 {print $5}' -)
[[ $(echo "${BASES_PRCT}") == "66.7%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats percentage of bases with this quality score or higher is correct"
BASES_PRCT=$(printf '@s1\nA\n+\nG\n@s2\nA\n+\nH\n@s3\nA\n+\nI' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==14 {print $6}' -)
[[ $(echo "${BASES_PRCT}") == "66.7%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                       Length vs quality distribution                        #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_stats PctRecs is correct"
BASES_PRCT=$(printf '@s1\nA\n+\nH\n@s2\nAA\n+\nHH\n@s3\nAAA\n+\nHHH' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==19 {print $2}' -)
[[ $(echo "${BASES_PRCT}") == "66.7%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## following tests are checking that nucleotides after position 2 are not taken in
## account by using 4 nucletotide sequence, and that result is truncated by
## testing result having at least 2 significant numbers with the second above 4 before
## truncating
DESCRIPTION="--fastq_stats AvgQ is correct"
AVGQ=$(printf '@s1\nAAAA\n+\nHDII\n@s2\nAA\n+\nHG\n@s3\nAA\n+\nHI' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==21 {print $3}' -)
[[ $(echo "${AVGQ}") == "37.7" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats P(AvgQ) is correct"
PAVGQ=$(printf '@s1\nAAAA\n+\nHDII\n@s2\nAA\n+\nHG\n@s3\nAA\n+\nHI' | \
		 "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		     awk 'NR==21 {print $4}' -)
[[ $(echo "${PAVGQ}") == "0.00017" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats avgP is correct"
AVGP=$(printf '@s1\nAAAA\n+\nIDII\n@s2\nAA\n+\nHH\n' | \
		    "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
		    awk 'NR==20 {print $5}' -)
[[ $(echo "${AVGP}") == "0.000221" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats avgEE is correct"
AVGEE=$(printf '@s1\nAAA\n+\n++5\n@s2\nAAA\n+\n""5' | \
		           "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
     awk 'NR==20 {print $6}' -)
[[ $(echo "${AVGEE}") == "0.90" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats Rate is correct"
RATE=$(printf '@s1\nAAA\n+\n++0\n@s2\nAAA\n+\n++0' | \
		           "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
                   awk 'NR==19 {print $7}' -)
[[ $(echo "${RATE}") == "0.077208" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats RatePct is correct"
RATEPCT=$(printf '@s1\nAAA\n+\n++0\n@s2\nAAA\n+\n++0' | \
		           "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
                   awk 'NR==19 {print $8}' -)
[[ $(echo "${RATEPCT}") == "7.721%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                Effect of excpected error end length filtering              #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_stats RatePct is correct"
RATEPCT=$(printf '@s1\nAAA\n+\n++0\n@s2\nAAA\n+\n++0' | \
		           "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
                   awk 'NR==23 {print $2}' -)
[[ $(echo "${RATEPCT}") == "7.721%" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                Effect of minimum quality and length filtering               #
#                                                                             #
#*****************************************************************************#

#DESCRIPTION="--fastq_stats RatePct is correct"
#RATEPCT=$(printf "@s1\nAAA\n+\n('&\n" | \
#		           "${VSEARCH}" --fastq_stats - --log - 2> /dev/null) #| \
#                   awk 'NR==32 {print $2}' -)
#echo "${RATEPCT}"
#[[ $(echo "${RATEPCT}") == "7.721%" ]] && \
#    success  "${DESCRIPTION}" || \
#        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                    Next                                     #
#                                                                             #
#*****************************************************************************#

## Discrepency in reported lengths?
# In the log, explain why some stats are reported for sequences of
# length up to 490 nucleotides, and sometimes for lengths of up to only
# 483 nucleotides.
# /scratch/mahe/projects/Quercus_suber/data/ITS2_20160805$ cat tmp 
# /scratch/mahe/bin/vsearch/bin/vsearch --fastq_stats TARA-P2_TGACCT_L001_assembled.fastq --log tmp

exit 0
