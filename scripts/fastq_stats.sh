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

#   --fastq_stats FILENAME      report statistics on FASTQ file
#  Parameters
#   --fastq_ascii INT           FASTQ input quality score ASCII base char (33)
#   --fastq_qmax INT            maximum base quality value for FASTQ input (41)
#   --fastq_qmin INT            minimum base quality value for FASTQ input (0)
#  Output
#   --log FILENAME              output file for fastq_stats statistics

DESCRIPTION="--fastq_stats + --log is accepted"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fails without --log"  # shouldn't that be true?
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_ascii is accepted"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_ascii 33 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmin is accepted"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_qmin 20 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_qmax is accepted"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_qmax 40 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              Input values                                   #
#                                                                             #
#*****************************************************************************#

# G is interpreted as a quality value of 38 when the offset is 33
DESCRIPTION="--fastq_stats --fastq_ascii is set to 33 by default"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --log - 2> /dev/null | \
    grep -qE "G[[:blank:]]+38" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_ascii can be set to 33"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_ascii 33 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats --fastq_ascii can be set to 64"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_ascii 64 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# G is interpreted as a quality value of 7 when the offset is 64
DESCRIPTION="--fastq_stats --fastq_ascii 64 is taken into account"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_ascii 64 --log - 2> /dev/null | \
    grep -qE "G[[:blank:]]+7" && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# or should we allow users to use other offset values?
DESCRIPTION="--fastq_stats --fastq_ascii rejects values other than 33 or 64"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_ascii 42 --log - &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# vsearch now checks that the argument to fastq_ascii + the argument
# to fastq_qmin or fastq_qmax is within the range 33 to 126 of
# printable ascii characters.
DESCRIPTION="--fastq_stats fastq_ascii + fastq_qmin is at least 33"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_qmin 0 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fastq_ascii + fastq_qmax is at most 126 (offset 33)"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_qmax 93 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fastq_ascii + fastq_qmax must be less than 127 (offset 33)"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_qmax 94 --log - &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fastq_ascii + fastq_qmax is at most 126 (offset 64)"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_ascii 64 --fastq_qmax 62 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fastq_ascii + fastq_qmax must be less than 127 (offset 64)"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_ascii 64 --fastq_qmax 63 --log - &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fastq_qmin can be equal to fastq_qmax"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_qmin 38 --fastq_qmax 38 --log - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_stats fastq_qmin cannot be greater than fastq_qmax"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_qmin 39 --fastq_qmax 38 --log - &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ascii characters accepted as fastq quality values (33 to 126)
for i in {33..126} ; do
    DESCRIPTION="ascii character ${i} can be used as fastq quality value (offset 33)"
    echo -e "@s\nA\n+\n$(printf "\%04o" ${i})\n" | \
        "${VSEARCH}" --fastq_stats - --fastq_ascii 33 --fastq_qmax 93 --log - &> /dev/null && \
        success  "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done

## ascii characters rejected as fastq quality values (1-32 and 127)
for i in {1..32} 127 ; do
    DESCRIPTION="ascii character ${i} cannot be used as fastq quality value (offset 33)"
    echo -e "@s\nA\n+\n$(printf "\%04o" ${i})\n" | \
        "${VSEARCH}" --fastq_stats - --fastq_ascii 33 --fastq_qmax 93 --log - &> /dev/null && \
        failure  "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done

## ascii characters accepted as fastq quality values (64 to 126)
for i in {64..126} ; do
    DESCRIPTION="ascii character ${i} can be used as a fastq quality value (offset 64)"
    echo -e "@s\nA\n+\n$(printf "\%04o" ${i})\n" | \
        "${VSEARCH}" --fastq_stats - --fastq_ascii 64 --fastq_qmax 62 --log - &> /dev/null && \
        success  "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done

## ascii characters rejected as fastq quality values (1-63 and 127)
for i in {1..63} 127 ; do
    DESCRIPTION="ascii character ${i} cannot be used as fastq quality value (offset 64)"
    echo -e "@s\nA\n+\n$(printf "\%04o" ${i})\n" | \
        "${VSEARCH}" --fastq_stats - --fastq_ascii 64 --fastq_qmax 62 --log - &> /dev/null && \
        failure  "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done

## when using the --fastq_stats command, the --fastq_qmin and
## --fastq_qmax options do not play any filtering role. At most, the
## values can be changed to accommodate a dataset with unusual quality
## values. That's it.

## fastq_qmin controls the range of accepted quality values
DESCRIPTION="--fastq_qmin controls the range of accepted quality values"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_qmin 39 --log - &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## fastq_qmax controls the range of accepted quality values
DESCRIPTION="--fastq_qmax controls the range of accepted quality values"
printf "@s\nA\n+\nG\n" | \
    "${VSEARCH}" --fastq_stats - --fastq_qmax 37 --log - &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## below this point the tests need to be revised -----------------------------


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
# 				  "${VSEARCH}" --fastq_stats - --log - --fastq_ascii 64 2> /dev/null | \
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

## following tests are checking that nucleotides after position 2 are
## not taken into account when using 4 nucleotide-sequences, and that
## the result is truncated. (by testing result having at least 2
## significant numbers with the second above 4 before truncating)? TO BE REVISED
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
