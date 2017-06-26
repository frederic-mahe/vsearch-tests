#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="uchime_denovo"
LINE=$(printf -- "-%.0s" {1..76})f
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
#                               uchime_denovo                                 #
#                                                                             #
#*****************************************************************************#
#used sequences from Edgar et Al. Bioinformatics Vol.27 no. 16 2011 p.2194-2200
seq11='>seq1;size=10\nCCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACG\n'
seq12='CgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc'
seq31='>seq3;size=5 \nCCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGC\n'
seq32='ATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc'
seq21='>seq2;size=10\nTCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACG\n'
seq22='CATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG'
chimera=$seq11$seq12$seq21$seq22$seq31$seq32

DESCRIPTION="--uchime_denovo is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --abskew is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --abskew 2.0 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --dn is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --dn 1.4 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --mindiffs is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --mindiffs 3 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --mindiv is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --mindiv 0.8 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --minh is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --minh 0.28 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --sizein is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --sizein --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --self is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --self --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --selfid is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --selfid --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --xn is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --xn 8.0 --chimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                               uchime_denovo                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--uchime_denovo --abskew gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --abskew 2 --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --abskew gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --abskew 3 --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --abskew gives the correct result #3"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=3\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --abskew 3 --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --abskew fails if value under 1"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=3\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --abskew 0.9 --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --mindiffs gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --mindiffs 5  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --mindiffs gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --mindiffs 6  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"   
unset "OUTPUT"


DESCRIPTION="--uchime_denovo --dn gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAG"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAAaCTCTTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --dn 2 --xn 8 --minh 0.28  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --dn gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAG"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAAaCTCTTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --dn 1.8 --xn 8 --minh 0.28  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --minh gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --minh 0.5  --chimeras - 2>&1 | grep "Found" | awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --minh gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --minh 0.4  --chimeras - 2>&1 | grep "Found" | awk '{print $}' )
    [[ "${OUTPUT}" == "1" ]] && \
     success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

# DESCRIPTION="--uchime_denovo --minh gives the correct result #2"
# seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
# seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
# seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
# chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
# vsearch --uchime_denovo <(printf "${chimera}") --minh 0.28 --sizein  --chimeras - 2>&1

#*****************************************************************************#
#                                                                             #
#                                   Output                                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--uchime_denovo --nonchimeras is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --nonchimeras - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout is accepted"
printf '@seq1\nAGC\n+\nIII\n' | \
    vsearch --uchime_denovo - --uchimeout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the good score"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $1}')
[[ "${OUTPUT}" == "0.5123" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the good chimera"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $2}')
[[ "${OUTPUT}" == "seq3;size=5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the good parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $3}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the good parents #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $4}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
 # vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - --uchimeout5 >> /home/dylan/temp3 

DESCRIPTION="--uchime_denovo --uchimeout gives the most similar parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $5}')
[[ "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the global similarity"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $6}')
[[ "${OUTPUT}" == "98.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the similarity with 1st parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $7}')
[[ "${OUTPUT}" == "75.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the similarity with 2nd parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $8}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the similarity between both parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $9}')
[[ "${OUTPUT}" == "68.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the similarity between query and most similar parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $10}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimeout gives the correct LY"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - 2>&1 | grep "seq3;size=5" | awk '{print $11}')
[[ "${OUTPUT}" == "5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# exit 0
DESCRIPTION="--uchime_denovo --uchimeout is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
    vsearch --uchime_denovo <(printf "${chimera}") --uchimeout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --nonchimeras is showing the nonchimerics inputs"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --nonchimeras - 2>/dev/null)
EXPECTED=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns QA is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
    grep "Ids." | awk '{print $3}' 2>/dev/null)
[[ "${OUTPUT}" == "75.0%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns QB is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
    grep "Ids." | awk '{print $5}' 2>/dev/null)
[[ "${OUTPUT}" == "90.0%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns AB is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1| \
    grep "Ids." | awk '{print $7}' 2>/dev/null)
[[ "${OUTPUT}" == "68.3%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns QModel is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
    grep "Ids." | awk '{print $9}' 2>/dev/null)
[[ "${OUTPUT}" == "98.3%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Div is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
    grep "Ids." | awk '{print $11}' 2>/dev/null)
[[ "${OUTPUT}" == "+9.3%" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs left is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $3}'  2>/dev/null)
[[ "${OUTPUT}" == "6:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs left no is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $5}'  2>/dev/null)
[[ "${OUTPUT}" == "0," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs left abstain is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $7}'  2>/dev/null)
[[ "${OUTPUT}" == "1," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs left yes is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $9}'  2>/dev/null)
[[ "${OUTPUT}" == "5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs right is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $12}'  2>/dev/null)
[[ "${OUTPUT}" == "14:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs right no is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $14}'  2>/dev/null)
[[ "${OUTPUT}" == "0," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
# vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 1
exit 0
DESCRIPTION="--uchime_denovo --uchimealns Diffs right abstain is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $16}'  2>/dev/null)
[[ "${OUTPUT}" == "0," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns Diffs right yes is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $18}'  2>/dev/null)
[[ "${OUTPUT}" == "14" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns score is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimera}") --uchimealns - --alignwidth 95 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $21}'  2>/dev/null)
[[ "${OUTPUT}" == "0.5123" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



exit 0
