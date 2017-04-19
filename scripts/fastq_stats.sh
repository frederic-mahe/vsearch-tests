#!/bin/bash -

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
    exit -1
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
#                    Database can contain empty sequences                     #
#                                                                             #
#*****************************************************************************#

FASTQ=$(mktemp)
printf "@illumina33\nGTGAATCATCGAATCTTT\n+\nCCCCCGGGGGGGGGGGGG\n" > "${FASTQ}"

DESCRIPTION="fastq stats deals with Illumina +33"

"${VSEARCH}" \
    --fastq_stats "${QUERY}" \
    --db "${DATABASE}" \
    --alnout "${ALNOUT}" \
    --quiet 2> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## Clean
rm "${FASTQ}"

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
