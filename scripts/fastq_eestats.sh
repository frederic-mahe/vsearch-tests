#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fastq_eestats all tests"
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
#                           Positions and quartiles                           #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_eestats Pos is correct #1"
POS=$(printf '@s1\nA\n+\nH\n' | \
		     "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
             wc -l -)
[[ $(echo "${POS}") == "2 -" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Pos is correct #2"
POS=$(printf '@s1\nAA\n+\nHH\n' | \
		     "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
             wc -l -)
[[ $(echo "${POS}") == "3 -" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Recs is correct #1"
RECS=$(printf '@s1\nAA\n+\nHH\n@s2\nA\n+\nH\n' | \
		     "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
             awk 'NR==2 {print $2}' -)
[[ $(echo "${RECS}") == "2" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Recs is correct #2"
RECS=$(printf '@s1\nAA\n+\nHH\n@s2\nA\n+\nH\n' | \
		     "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
             awk 'NR==3 {print $2}' -)
[[ $(echo "${RECS}") == "1" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats PctRecs is correct"
PCTRECS=$(printf '@s1\nAA\n+\nHH\n@s2\nA\n+\nH\n@s3\nA\n+\nH\n@s4\nA\n+\nH\n@s5\nA\n+\nH\n@s6\nA\n+\nH\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $3}' -)
[[ $(echo "${PCTRECS}") == "16.7" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Min_Q is correct #1"
MINQ=$(printf '@s1\nA\n+\n"\n@s2\nA\n+\n!\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $4}' -)
[[ $(echo "${MINQ}") == "0.0" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Min_Q is correct #2"
MINQ=$(printf '@s1\nA\n+\n"\n@s2\nA\n+\n#\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $4}' -)
[[ $(echo "${MINQ}") == "1.0" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Low_Q is correct #1"
LOWQ=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $5}' -)
[[ $(echo "${LOWQ}") == "0.0" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Low_Q is correct #2"
LOWQ=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n#\n@s5\nA\n+\n#\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $5}' -)
[[ $(echo "${LOWQ}") == "1.0" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Med_Q is correct #1"
MEDQ=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n!\n@s3\nA\n+\n"\n@s4\nA\n+\n"\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $6}' -)
[[ $(echo "${MEDQ}") == "0.5" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Med_Q is correct #2"
MEDQ=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n$\n@s5\nA\n+\n$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $6}' -)
[[ $(echo "${MEDQ}") == "2.0" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Mean_Q is correct"
MEANQ=$(printf '@s1\nA\n+\n"\n@s2\nA\n+\n#\n@s3\nA\n+\n$\n@s4\nA\n+\n&\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $7}' -)
[[ $(echo "${MEANQ}") == "2.8" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Hi_Q is correct #1"
HIQ=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $8}' -)
[[ $(echo "${HIQ}") == "2.0" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Hi_Q is correct #2"
HIQ=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n$\n@s5\nA\n+\n%%\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $8}' -)
[[ $(echo "${HIQ}") == "3.0" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Max_Q is correct #2"
MAXQ=$(printf '@s1\nA\n+\n"\n@s2\nA\n+\n!\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $9}' -)
[[ $(echo "${MAXQ}") == "1.0" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              Error probability                              #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_eestats Min_PE is correct #1"
MINPE=$(printf '@s1\nA\n+\n"\n@s2\nA\n+\n!\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $10}' -)
[[ $(echo "${MINPE}") == "0.79" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Min_PE is correct #2"
MINPE=$(printf '@s1\nAA\n+\n"&\n@s2\nAA\n+\n#$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $10}' -)
[[ $(echo "${MINPE}") == "0.32" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Low_PE is correct #1"
LOWPE=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $11}' -)
[[ $(echo "${LOWPE}") == "0.63" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Low_PE is correct #2"
LOWPE=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n#\n@s5\nA\n+\n#\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $11}' -)
[[ $(echo "${LOWPE}") == "0.63" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Med_PE is correct #1"
MEDPE=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $12}' -)
[[ $(echo "${MEDPE}") == "0.71" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Med_PE is correct #2"
MEDPE=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n$\n@s5\nA\n+\n$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $12}' -)
[[ $(echo "${MEDPE}") == "0.63" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Mean_PE is correct"
MEANPE=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $13}' -)
[[ $(echo "${MEANPE}") == "0.73" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Hi_PE is correct #1"
HIPE=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n"\n@s3\nA\n+\n#\n@s4\nA\n+\n$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $14}' -)
[[ $(echo "${HIPE}") == "0.79" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Hi_PE is correct #2"
HIPE=$(printf '@s1\nA\n+\n!\n@s2\nA\n+\n!\n@s3\nA\n+\n"\n@s4\nA\n+\n#\n@s5\nA\n+\n$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $14}' -)
[[ $(echo "${HIPE}") == "0.79" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Max_PE is correct #1"
MAXPE=$(printf '@s1\nA\n+\n"\n@s2\nA\n+\n!\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $15}' -)
[[ $(echo "${HIPE}") == "1" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Max_PE is correct #2"
MAXPE=$(printf '@s1\nAA\n+\n"&\n@s2\nAA\n+\n#$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $15}' -)
[[ $(echo "${MAXPE}") == "0.5" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                                Expected error                               #    
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_eestats Min_EE is correct #1"
MINEE=$(printf '@s1\nA\n+\n"\n@s2\nA\n+\n!\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $16}' -)
[[ $(echo "${MINEE}") == "0.79" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Min_EE is correct #2"
MINEE=$(printf '@s1\nAA\n+\n"&\n@s2\nAA\n+\n#$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $16}' -)
[[ $(echo "${MINEE}") == "1.11" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Low_EE is correct #1"
LOWEE=$(printf '@s1\nAA\n+\n!"\n@s2\nAA\n+\n"#\n@s3\nAA\n+\n#$\n@s4\nAA\n+\n$%%\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $17}' -)
[[ $(echo "${LOWEE}") == "0.90" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Low_EE is correct #2"
LOWEE=$(printf '@s1\nAA\n+\n!"\n@s2\nAA\n+\n"#\n@s3\nAA\n+\n#$\n@s4\nAA\n+\n$%%\n@s5\nAA\n+\n%%&\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $17}' -)
[[ $(echo "${LOWEE}") == "0.90" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Med_EE is correct #1"
MEDEE=$(printf '@s1\nAA\n+\n!"\n@s2\nAA\n+\n"#\n@s3\nAA\n+\n#$\n@s4\nAA\n+\n$%%\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $18}' -)
[[ $(echo "${MEDEE}") == "1.28" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Med_EE is correct #2"
MEDEE=$(printf '@s1\nAA\n+\n!"\n@s2\nAA\n+\n"#\n@s3\nAA\n+\n#$\n@s4\nAA\n+\n$%%\n@s5\nAA\n+\n%%&\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $18}' -)
[[ $(echo "${MEDEE}") == "1.13" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Mean_EE is correct"
MEANEE=$(printf '@s1\nAA\n+\n!"\n@s2\nAA\n+\n"#\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $19}' -)
[[ $(echo "${MEANEE}") == "1.61" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Hi_EE is correct #1"
LOWEE=$(printf '@s1\nAA\n+\n!"\n@s2\nAA\n+\n"#\n@s3\nAA\n+\n#$\n@s4\nAA\n+\n$%%\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $20}' -)
[[ $(echo "${LOWEE}") == "1.43" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Hi_EE is correct #2"
HIEE=$(printf '@s1\nAA\n+\n!"\n@s2\nAA\n+\n"#\n@s3\nAA\n+\n#$\n@s4\nAA\n+\n$%%\n@s5\nAA\n+\n%%&\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $20}' -)
[[ $(echo "${HIEE}") == "1.43" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Max_EE is correct #1"
MAXEE=$(printf '@s1\nA\n+\n"\n@s2\nA\n+\n!\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==2 {print $21}' -)
[[ $(echo "${HIEE}") == "1.00" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_eestats Max_EE is correct #2"
MAXEE=$(printf '@s1\nAA\n+\n"&\n@s2\nAA\n+\n#$\n' | \
		      "${VSEARCH}" --fastq_eestats - --output - 2> /dev/null | \
              awk 'NR==3 {print $21}' -)
[[ $(echo "${MAXEE}") == "1.13" ]] &&
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
