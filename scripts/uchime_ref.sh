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
#                                uchime_ref                                   #
#                                                                             #
#*****************************************************************************#

#used sequences from Edgar et Al. Bioinformatics Vol.27 no. 16 2011 p.2194-2200

DESCRIPTION="--uchime_ref is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --abskew is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --abskew 2.0 --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --dn is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --dn 1.4 --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --mindiffs is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --mindiffs 3 --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --mindiv is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --mindiv 0.8 --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --minh is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --minh 0.28 --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --sizein is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --sizein --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --self is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --self --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --selfid is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --selfid --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --xn is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --xn 8.0 --chimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

#*****************************************************************************#
#                                                                             #
#                                uchime_ref                                   #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--uchime_ref --abskew gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --abskew 2 --chimeras - --db <(printf "${database}") 2>&1 | \
	    awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_ref --abskew gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --abskew 3 --chimeras - --db <(printf "${database}") 2>&1 | \
	    awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_ref --abskew gives the correct result #3"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --abskew 3 --chimeras - --db <(printf "${database}") 2>&1 | \
	    awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_ref --abskew fails if value under 1"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --abskew 0.9 --chimeras - --db <(printf "${database}") 2>&1 | \
	    awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_ref --mindiffs gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --mindiffs 5  --chimeras - --db <(printf "${database}") 2>&1 | \
	    awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_ref --mindiffs gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --mindiffs 6  --chimeras - --db <(printf "${database}") 2>&1 | \
	    awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_ref --dn gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAG"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAAaCTCTTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --dn 2 --xn 8 --minh 0.28  --chimeras - --db <(printf "${database}") 2>&1 | \
	    awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_ref --dn gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAG"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAAaCTCTTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --dn 1.8 --xn 8 --minh 0.28  --chimeras - --db <(printf "${database}") 2>&1 | \
	     awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_ref --minh gives the correct result"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3}) 
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --minh 0.5  --chimeras - --db <(printf "${database}") 2>&1 | \
	     awk '/Found/ {print $2}' -)
[[ "${OUTPUT}" == "0" ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"   
unset "OUTPUT"

DESCRIPTION="--uchime_ref --minh gives the correct result #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --minh 0.4  --chimeras - --db <(printf "${database}") 2>&1 | grep "Found" | \awk '{print $2}' -)
    [[ "${OUTPUT}" == "1" ]] && \
     success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"   
unset "OUTPUT"


#*****************************************************************************#
#                                                                             #
#                                   Output                                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--uchime_ref --nonchimeras is accepted"
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --nonchimeras - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout is accepted"
printf '>seq1\nAGC\n' | \
    vsearch --uchime_ref - --uchimeout - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the good score"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $1}')
[[ "${OUTPUT}" == "0.5123" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the good chimera"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $2}')
[[ "${OUTPUT}" == "seq3;size=5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the good parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $3}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the good parents #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $4}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the most similar parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq3;size=5\n%s\n'${seq3})
database=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $5}')
[[ "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the global similarity"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $6}')
[[ "${OUTPUT}" == "98.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the similarity with 1st parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $7}')
[[ "${OUTPUT}" == "75.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the similarity with 2nd parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $8}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the similarity between both parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $9}')
[[ "${OUTPUT}" == "68.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the similarity between query and most similar parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $10}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the correct LY"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $11}')
[[ "${OUTPUT}" == "5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the correct LN"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $12}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the correct LA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $13}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the correct RY"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $14}')
[[ "${OUTPUT}" == "14" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the correct RN"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $15}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the correct RA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $16}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout gives the correct div"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $17}')
[[ "${OUTPUT}" == "8.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout finds the chimera"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $18}')
[[ "${OUTPUT}" == "Y" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the good score"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $1}')
[[ "${OUTPUT}" == "0.5123" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the good chimera"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $2}')
[[ "${OUTPUT}" == "seq3;size=5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the good parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $3}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the good parents #2"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $4}')
[[ "${OUTPUT}" == "seq1;size=10" || "${OUTPUT}" == "seq2;size=10" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the global similarity"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $5}')
[[ "${OUTPUT}" == "98.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the similarity with 1st parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $6}')
[[ "${OUTPUT}" == "75.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the similarity with 2nd parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $7}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the similarity between both parents"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $8}')
[[ "${OUTPUT}" == "68.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the similarity between query and most similar parent"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $9}')
[[ "${OUTPUT}" == "90.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the correct LY"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $10}')
[[ "${OUTPUT}" == "5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the correct LN"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $11}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the correct LA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $12}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the correct RY"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $13}')
[[ "${OUTPUT}" == "14" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the correct RN"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $14}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the correct RA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $15}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the correct div"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $16}')
[[ "${OUTPUT}" == "8.3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 gives the correct RA"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") 2>&1 | grep "seq3;size=5" | \
	     awk '{print $17}')
[[ "${OUTPUT}" == "Y" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimeout --uchimeout5 is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
    vsearch --uchime_ref <(printf "${chimera}") --uchimeout - --uchimeout5 --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --nonchimeras is showing the nonchimerics inputs"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --nonchimeras - --db <(printf "${database}") 2>/dev/null)
EXPECTED=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n' ${seq1} ${seq2})
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
       failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns is accepted"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --db <(printf "${database}") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns QA is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
    grep "Ids." | awk '{print $3}' 2>/dev/null)
[[ "${OUTPUT}" == "75.0%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns QB is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
    grep "Ids." | awk '{print $5}' 2>/dev/null)
[[ "${OUTPUT}" == "90.0%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns AB is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1| \
    grep "Ids." | awk '{print $7}' 2>/dev/null)
[[ "${OUTPUT}" == "68.3%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns QModel is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
    grep "Ids." | awk '{print $9}' 2>/dev/null)
[[ "${OUTPUT}" == "98.3%," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns Div is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
    grep "Ids." | awk '{print $11}' 2>/dev/null)
[[ "${OUTPUT}" == "+9.3%" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns Diffs left is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $3}'  2>/dev/null)
[[ "${OUTPUT}" == "6:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns Diffs left no is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $5}'  2>/dev/null)
[[ "${OUTPUT}" == "0," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns Diffs left abstain is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $7}'  2>/dev/null)
[[ "${OUTPUT}" == "1," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns Diffs left yes is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $9}'  2>/dev/null)
[[ "${OUTPUT}" == "5" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns Diffs right is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $12}'  2>/dev/null)
[[ "${OUTPUT}" == "14:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns Diffs right no is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $14}'  2>/dev/null)
[[ "${OUTPUT}" == "0," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns Diffs right abstain is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $16}'  2>/dev/null)
[[ "${OUTPUT}" == "0," ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns Diffs right yes is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $18}'  2>/dev/null)
[[ "${OUTPUT}" == "14" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uchime_ref --uchimealns score is correct"
seq1="CCTTGGTAGGCCGtTGCCCTGCCAACTAGCTAATCAGACGCgggtCCATCtcaCACCaccggAgtTTTtcTCaCTgTacc"
seq3="CCTTGGTAGGCCGCTGCCCTGCAACTAGCTAATCAGACGCATCCCCATCCATCACCGATAAATCTTTAATCTCTTTCAGc"
seq2="TCTTGGTgGGCCGtTaCCCcGCCAACaAGCTAATCAGACGCATAATCAGACGCATCCCCATCCATCACCGATAATTTCAG"
chimera=$(printf '>seq1;size=10\n%s\n>seq2;size=10\n%s\n>seq3;size=5\n%s\n' ${seq1} ${seq2} ${seq3})
OUTPUT=$(vsearch --uchime_ref <(printf "${chimera}") --uchimealns - --alignwidth 95 --db <(printf "${database}") 2>&1 | \
	     grep -n "Diffs" | grep 29:* | awk '{print $21}'  2>/dev/null)
[[ "${OUTPUT}" == "0.5123" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
exit 0
