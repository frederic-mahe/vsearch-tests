#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="search_exact"
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
#                              Basic tests                                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_exact --userout is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1;size=5\n%s\n' ${seq1})
database=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") --db <(printf "${database}") --userout - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --alnout is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1;size=5\n%s\n' ${seq1})
database=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") --db <(printf "${database}") --alnout - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --biomout is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1;size=5\n%s\n' ${seq1})
database=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") --db <(printf "${database}") --biomout - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --blast6out is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1;size=5\n%s\n' ${seq1})
database=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") --db <(printf "${database}") --blast6out - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --mothur_shared_out is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1;size=5\n%s\n' ${seq1})
database=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") --db <(printf "${database}") --mothur_shared_out - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --otutabout is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1;size=5\n%s\n' ${seq1})
database=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") --db <(printf "${database}") --otutabout - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --samout is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1;size=5\n%s\n' ${seq1})
database=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") --db <(printf "${database}") --samout - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --uc is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1;size=5\n%s\n' ${seq1})
database=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") --db <(printf "${database}") --uc - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1;size=5\n%s\n' ${seq1})
database=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") --db <(printf "${database}") --userout - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --alnout finds the identical sequence"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
		      --db <(printf "${database}") --alnout - 2>&1 1>/dev/null | \
	     awk 'NR==6 {print $2}')
[[ "${OUTPUT}" == "100%" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

exit 0
#*****************************************************************************#
#                                                                             #
#                              Basic tests                                    #
#                                                                             #
#*****************************************************************************#

