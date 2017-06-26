
#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="masking options"
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

seq11='>seq1;size=10\nCCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACG\n'
seq12='CgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc'
seq31='>seq3;size=5 \nCCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGC\n'
seq32='ATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc'
seq21='>seq2;size=10\nTCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACG\n'
seq22='CATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG'
chimere=$seq11$seq12$seq21$seq22$seq31$seq32

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
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --abskew 2 --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -) && \
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --abskew gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --abskew 3 --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -) && \
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --mindiffs gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --mindiffs 5  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -) && \
    [[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --mindiffs gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --mindiffs 6  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -) && \
    [[ "${OUTPUT}" == "0" ]] && \
     failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"   
unset "OUTPUT"


DESCRIPTION="--uchime_denovo --dn gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAG"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAAaCTCTTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --dn 2 --xn 8 --minh 0.28  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -) && \
    [[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --dn gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAG"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAAaCTCTTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --dn 1.8 --xn 8 --minh 0.28  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -) && \
    [[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --minh gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --minh 0.5  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -) && \
    [[ "${OUTPUT}" == "0" ]] && \
     failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_denovo --minh gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --minh 0.4  --chimeras - 2>&1 | grep "Found" | awk '{print $2}' -) && \
    [[ "${OUTPUT}" == "1" ]] && \
     success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

# DESCRIPTION="--uchime_denovo --minh gives the correct result #2"
# seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
# seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
# seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
# chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
# vsearch --uchime_denovo <(printf "${chimere}") --minh 0.28 --sizein  --chimeras - 2>&1

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

DESCRIPTION="--uchime_denovo --nonchimeras is showing the nonchimerics inputs"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --nonchimeras - 2>/dev/null)
EXPECTED=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
vsearch --uchime_denovo <(printf "${chimere}") --uchimealns - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_denovo --uchimealns gives the correct length"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimere=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_denovo <(printf "${chimere}") --uchimealns - --alignwidth 93 2>/dev/null | \
		awk 'NR==3 {print $3}')
[[ "${OUTPUT}" == "80" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
vsearch --uchime_denovo <(printf "${chimere}") --uchimealns - --alignwidth 95 2>&1
vsearch --uchime_denovo <(printf "${chimere}") --uchimealns - --alignwidth 95 2>&1 | \
    grep "Ids." | awk '{print $3}'

exit 0
