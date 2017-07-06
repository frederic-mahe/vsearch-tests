#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="search_exact"
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
#                              Basic tests                                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--search_exact --userout is accepted"
"${VSEARCH}" \
    --search_exact <(printf '>seq1;size=5\n%s\n' "AAAA") \
    --db <(printf '>seq2;size=5\n%s\n' "AAAA") \
    --userout - &>/dev/null && \
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



#*****************************************************************************#
#                                                                             #
#                              Basic tests                                    #
#                                                                             #
#*****************************************************************************#


DESCRIPTION="--search_exact --alnout finds the identical sequence"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
         --db <(printf "${database}") --alnout - 2>&1 1>/dev/null | \
    awk 'NR==9 {print $7}')
[[ "${OUTPUT}" == "(100.00%)" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --alnout finds the identical sequence #2"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
         --db <(printf "${database}") --alnout - 2>&1 1>/dev/null | \
    awk 'NR==9 {print $7}')
[[ "${OUTPUT}" == "(0.00%)" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --alnout fails if wrong input"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --alnout - 2>&1 | \
      awk 'NR==10 {print $1 " " $2}')
[[ "${OUTPUT}" == "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --alnout fails if empty database"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '')
search_query=$(printf '>seq2%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --alnout - 2>&1 | \
         awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" == "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --alnout fails if no database"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '')
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --alnout fails if no input"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact  \
         --db <(printf "${database}") --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --biomout finds the identical sequence"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --biomout - 2>/dev/null | \
        awk -F "\"" 'NR==12 {print $4}')
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --biomout finds the identical sequence #2"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --biomout - 2>/dev/null | \
        awk -F "\"" 'NR==15 {print $4}')
[[ "${OUTPUT}" == "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --biomout finds the identical sequence #3"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --biomout - 2>/dev/null | \
        awk -F "," 'NR==15 {print $4} ')
[[ "${OUTPUT}" != "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --biomout finds the identical sequence #3"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --biomout - 2>/dev/null | \
        awk -F "," 'NR==15 {print $4} ')
[[ "${OUTPUT}" != "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --biomout fails if empty database"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '')
search_query=$(printf '>seq2%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --biomout - 2>&1 | \
         awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" == "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --biomout fails if no database"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '')
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --biomout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --biomout fails if no input"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact  \
         --db <(printf "${database}") --biomout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --biomout fails if wrong input"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --biomout - 2>&1 1>/dev/null | \
          awk 'NR==10 {print $1 " " $2}')
[[ "${OUTPUT}" == "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out fails if empty database"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '')
search_query=$(printf '>seq2%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>&1 | \
         awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" == "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out fails if no database"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '')
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --blast6out - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--search_exact --blast6out fails if no input"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2;size=5\n%s\n' ${seq1})
"${VSEARCH}" --search_exact  \
         --db <(printf "${database}") --blast6out - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--search_exact --blast6out fails if wrong input"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>&1 1>/dev/null | \
          awk 'NR==10 {print $1 " " $2}')
[[ "${OUTPUT}" == "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct query"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
      awk '{print $1}')
[[ "${OUTPUT}" == "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct target"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $2}')
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct similarity percentage"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $3}')
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct alnlen"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $4}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct mism"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $5}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct opens"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $6}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct qlo"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $7}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct qhi"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $8}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct tlo"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $9}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct thi"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $10}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct evalue"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $11}')
[[ "${OUTPUT}" == "-1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --blast6out finds the correct bits"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --blast6out - 2>/dev/null | \
        awk '{print $12}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --dbmatched is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --dbmatched - &>/dev/null | \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --dbmatched displays the matched sequence"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --dbmatched - 2>/dev/null)
EXPECTED=$(printf '>seq1\n%s\n' ${seq1})
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"
unset "EXPECTED"

DESCRIPTION="--search_exact --dbmatched displays the matched sequence #2"
seq1="AAAG"
seq2="AAAA"
database=$(printf '>seq1\n%s\n' ${seq1})
search_query=$(printf '>seq2\n%s\n' ${seq2})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --dbmatched - 2>/dev/null)
EXPECTED=$(printf '>seq1\n%s\n' ${seq1})
[[ "${OUTPUT}" != "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"
unset "EXPECTED"

DESCRIPTION="--search_exact --dbnotmatched displays the matched sequence"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --dbnotmatched - 2>/dev/null)
EXPECTED=$(printf '>seq1\n%s\n' ${seq1})
[[ "${OUTPUT}" != "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"
unset "EXPECTED"

DESCRIPTION="--search_exact --dbnotmatched displays the matched sequence #2"
seq1="AAAG"
seq2="AAAA"
database=$(printf '>seq1\n%s\n' ${seq1})
search_query=$(printf '>seq2\n%s\n' ${seq2})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --dbnotmatched - 2>/dev/null)
EXPECTED=$(printf '>seq1\n%s\n' ${seq1})
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"
unset "EXPECTED"

DESCRIPTION="--search_exact --fastapairs is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --fastapairs - 2>&1| \
        awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" != "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --matched is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --matched - 2>&1| \
        awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" != "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --matched displays the correct sequences"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq4\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --matched - 2>/dev/null | \
        awk 'NR==1')
[[ "${OUTPUT}" == ">seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --matched displays the correct sequences #2"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq4\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq4} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --matched - 2>/dev/null | \
        awk 'NR==1')
[[ "${OUTPUT}" != ">seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --notmatched is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --notmatched - 2>&1| \
        awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" != "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --notmatched displays the correct sequences"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq4\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --notmatched - 2>/dev/null | \
        awk 'NR==1')
[[ "${OUTPUT}" != ">seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --notmatched displays the correct sequences #2"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq4\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq4} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --notmatched - 2>/dev/null | \
        awk 'NR==1')
[[ "${OUTPUT}" == ">seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --mothur_shared_out is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --mothur_shared_out - 2>&1| \
        awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" != "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --mothur_shared_out displays the correct sequences"
seq1="AAAG"
seq2="AAAA"
seq3="AATG"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
         --db <(printf "${database}") --mothur_shared_out - 2>/dev/null | \
        awk  'NR==2 {print $4} NR==3 {print $5} NR==4 {print $6} NR==5 {print $7}' | \
        tr '\n' ' ')
[[ "${OUTPUT}" == "1 1 1 1 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --otutabout is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --otutabout - 2>&1| \
        awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" != "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --otutabout displays the correct sequences"
seq1="AAAG"
seq2="AAAA"
seq3="AATG"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --otutabout - 2>/dev/null | \
        awk  'NR==2 {print $2} NR==3 {print $3} NR==4 {print $4} NR==5 {print $5}' | \
        tr '\n' ' ')
[[ "${OUTPUT}" == "1 1 1 1 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --alnout --rowlen is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --rowlen 64 - 2>&1| \
        awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" != "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --alnout --rowlen gives the correct result"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
         --db <(printf "${database}") --alnout - --rowlen 1 2>&1 2>/dev/null | \
    awk 'NR==11 {print $2} NR==15 {print $2} NR==19 {print $2} NR==23 {print $2}' | \
    tr '\n' ' ')
[[ "${OUTPUT}" == "1 2 3 4 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

# According to the man page, rowlen is only used with alnout. Using
# rowlen for anything else than an alignment or a fasta output file
# does not make sense. vsearch should stop with a fatal error, if
# rowlen is used with else anything than a fasta or alignment
# output. In the test below, vsearch accepts the --biomout and the
# rowlen options. It should not.
DESCRIPTION="--search_exact --!alnout --rowlen is not accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
         --db <(printf "${database}") --rowlen 64 --biomout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
    success "${DESCRIPTION}"

DESCRIPTION="--search_exact --samout is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --samout - 2>&1| \
        awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" != "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--search_exact --samout is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --samout - 2>&1| \
        awk 'NR==6 {print $1 " " $2}')
[[ "${OUTPUT}" != "Fatal error:" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"
#--uc already tested in dereplication_replication.sh

## --uc is accepted
DESCRIPTION="--uc is accepted"
printf ">a\nAAAA\n>b\nAAAC\n>c\nGGGG" | \
    "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc fails if no filename given
DESCRIPTION="--uc fails if no filename given"
printf ">a\nAAAA\n>b\nAAAC\n>c\nGGGG" | \
    "${VSEARCH}" --derep_fulllength - --minseqlength 1 --uc &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --uc creates and fills file given in argument
DESCRIPTION="--uc creates and fills file given in argument"
OUTPUT=$(printf '>a_1\nAAAA\n>b_1\nAAAC\n>c_1\nGGGG\n' | \
        "${VSEARCH}" --derep_fulllength - --minseqlength 1 --uc - 2>/dev/null)
[[ -n "${OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc number of hits is correct in 1st column #1
DESCRIPTION="--uc number of hits is correct in st column #1"
OUTPUT=$(printf ">a\nAA\n>b\nCC\n" | \
    "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>/dev/null)
NUMBER_OF_HITS=$(grep -c "^H" <<< "${OUTPUT}")
(( "${NUMBER_OF_HITS}" == 0 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

## --uc number of hits is correct in 1st column #2
DESCRIPTION="--uc number of hits is correct in st column #2"
OUTPUT=$(printf ">s1\nGG\n>s2\nAA\n>s3\nAA\n" | \
    "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>/dev/null)
NUMBER_OF_HITS=$(grep -c "^H" <<< "${OUTPUT}")
(( "${NUMBER_OF_HITS}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

## --uc number of centroids is correct in 1st column
DESCRIPTION="--uc number of centroids is correct in 1st column"

OUTPUT=$(printf ">s1\nAA\n>s2\nAA\n>s3\nGG\n" | \
    "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>&1)
NUMBER_OF_CENTROIDS=$(grep -c "^S" <<< "${OUTPUT}")
(( "${NUMBER_OF_CENTROIDS}" == 2 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

## --uc number of cluster records is correct in 1st column
DESCRIPTION="--uc number of cluster records is correct in 1st column"

OUTPUT=$(printf ">s1\nAA\n>s2\nAA\n>s3\nGG\n" | \
    "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>&1)
NUMBER_OF_CLUSTERS=$(grep -c "^C" <<< "${OUTPUT}")
(( "${NUMBER_OF_CLUSTERS}" == 2 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

## --uc cluster number is correct in 2nd column #1
DESCRIPTION="--uc cluster number is correct in 2nd column #1"


OUTPUT=$(printf ">s1\nGGGG\n" | \
    "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>&1)
CLUSTER_NUMBER=$(awk '/^C/ {v = $2} END {print v}' <<< "${OUTPUT}")
(( "${CLUSTER_NUMBER}" == 0 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

## --uc cluster number is correct in 2nd column #2
DESCRIPTION="--uc cluster number is correct in 2nd column #2"

OUTPUT=$(printf ">s1\nGG\n>s2\nAA\n>s3\nAA\n" | \
    "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>&1)
CLUSTER_NUMBER=$(awk '/^C/ {v = $2} END {print v}' <<< "${OUTPUT}")
(( "${CLUSTER_NUMBER}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

## --uc cluster size is correct in 3rd column
DESCRIPTION="--uc cluster number is correct in 3rd column"

OUTPUT=$(printf ">s1\nAA\n>s2\nAA\n" | \
    "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>&1)
CLUSTER_SIZE=$(awk '/^C/ {v = $3} END {print v}' <<< "${OUTPUT}")
[[ "${CLUSTER_SIZE}" == "2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

## --uc centroid length is correct in 3rd column #1
DESCRIPTION="--uc centroid length is correct in 3rd column #1"
OUTPUT=$(printf ">s1\nG\n" | \
        "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>/dev/null)
CENTROID_LENGTH=$(awk '/^S/ {v = $3} END {print v}' <<< "${OUTPUT}")
(( "${CENTROID_LENGTH}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

## --uc centroid length is correct in 3rd column #2
DESCRIPTION="--uc centroid length is correct in 3rd column #2"

OUTPUT=$(printf ">s1\nGG" | \
    "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>/dev/null)
CENTROID_LENGTH=$(awk '/^S/ {v = $3} END {print v}' <<< "${OUTPUT}")
(( "${CENTROID_LENGTH}" == 2 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

## --uc hit length is correct in 3rd column #1
DESCRIPTION="--uc hit length is correct in 3rd column #1"
HIT_LENGTH=$(printf ">s1\nAA\n>s2\nAA" | \
              "${VSEARCH}" --derep_fulllength - --uc - \
                   --minseqlength 1 2> /dev/null | \
              awk '/^H/ {v = $3} END {print v}' -)
[[ "${HIT_LENGTH}" == "2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc hit length is correct in 3rd column #2
DESCRIPTION="--uc hit length is correct in 3rd column #2"
HIT_LENGTH=$(printf ">s1\nA\n>s2\nA" | "${VSEARCH}" --derep_fulllength - --uc - \
            --minseqlength 1 2> /dev/null | \
            awk '/^H/ {v = $3} END {print v}' -)
(( "${HIT_LENGTH}" == 1 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc similarity percentage is correct in 4th column
DESCRIPTION="--uc similarity percentage is correct in 4th column"
SIMILARITY_PERCENTAGE=$(printf ">s2\nAA\n>s3\nAA\n" | \
                   "${VSEARCH}" --derep_fulllength - --uc - \
                        --minseqlength 1 2> /dev/null | \
                   awk '/^H/ {v = $4} END {print v}' -)
[[ "${SIMILARITY_PERCENTAGE}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc match orientation is correct in 5th column with H (+)
DESCRIPTION="--uc match orientation is correct in 5th column with H (+)"
MATCH_ORIENTATION=$(printf ">s1;size=1;\nAA\n>s2;size=1;\nAA\n" | \
               "${VSEARCH}" --derep_fulllength - --uc - \
                    --minseqlength 1 2> /dev/null | \
               awk '/^H/ {v = $5} END {print v}' -)
[[ "${MATCH_ORIENTATION}" == "+" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc match orientation is correct in 5th column with H (-)
DESCRIPTION="--uc match orientation is correct in 5th column with H (-)"
MATCH_ORIENTATION=$(printf ">s1;size=1;\nGACT\n>s2;size=1;\nAGTC\n" | \
               "${VSEARCH}" --derep_fulllength - --uc - --strand both \
                    --minseqlength 1 2> /dev/null | \
               awk '/^H/ {v = $5} END {print v}' -)

[[ "${MATCH_ORIENTATION}" == "-" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc match orientation is * in 5th column with S
DESCRIPTION="--uc match orientation is correct in 5th column with S"
MATCH_ORIENTATION=$(printf ">s1;size=1;\nGA" | \
               "${VSEARCH}" --derep_fulllength - --uc - \
               --minseqlength 1 2> /dev/null | \
                           awk '/^S/ {v = $5} END {print v}' -)
[[ "${MATCH_ORIENTATION}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc match orientation is * in 5th column with C
DESCRIPTION="--uc match orientation is correct in 5th column with C"
MATCH_ORIENTATION=$(printf ">s1\nAA\n" | \
               "${VSEARCH}" --derep_fulllength - --uc - \
                    --minseqlength 1 2> /dev/null | \
               awk '/^C/ {v = $5} END {print v}' -)
[[ "${MATCH_ORIENTATION}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 6th column is * with C
DESCRIPTION="--uc 6th column is * with C"
COLUMN_6=$(printf ">s1\nAA\n" | \
          "${VSEARCH}" --derep_fulllength - --uc - \
                   --minseqlength 1 2> /dev/null | \
          awk '/^C/ {v = $6} END {print v}' -)
[[ "${COLUMN_6}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 6th column is * with S
DESCRIPTION="--uc 6th column is * with S"
COLUMN_6=$(printf ">s1\nAA\n" | \
          "${VSEARCH}" --derep_fulllength - --uc - --minseqlength 1 2>/dev/null | \
           awk '/^S/ {v = $6} END {print v}')
[[ "${COLUMN_6}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 6th column is 0 with H
DESCRIPTION="--uc 6th column is 0 with H"
COLUMN_6=$(printf ">s1\nAA\n>s2\nAA\n" | \
          "${VSEARCH}" --derep_fulllength - --uc - \
                   --minseqlength 1 2> /dev/null | \
          awk '/^H/ {v = $6} END {print v}' -)
(( "${COLUMN_6}" == 0 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 7th column is * with C
DESCRIPTION="--uc 7th column is * with C"
COLUMN_7=$(printf ">s1\nAA\n" | \
          "${VSEARCH}" --derep_fulllength - --uc - \
                   --minseqlength 1 2> /dev/null | \
          awk '/^C/ {v = $7} END {print v}' -)
[[ "${COLUMN_7}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 7th column is * with S
DESCRIPTION="--uc 7th column is * with S"
COLUMN_7=$(printf ">s1\nAA\n" | \
          "${VSEARCH}" --derep_fulllength - --uc - \
                   --minseqlength 1 2> /dev/null | \
          grep "^S" - | \
                  awk -F "\t" '{if (NR == 1) {print $7}}')
[[ "${COLUMN_7}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 7th column is 0 with H
DESCRIPTION="--uc 7th column is 0 with H"
COLUMN_7=$(printf ">s1\nAA\n>s2\nAA\n" | \
          "${VSEARCH}" --derep_fulllength - --uc - \
                   --minseqlength 1 2> /dev/null | \
          awk '/^H/ {v = $7} END {print v}' -)
[[ "${COLUMN_7}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 8th collumn is * with S
DESCRIPTION="--uc 8th collumn is * with S"
COLUMN_8=$(printf ">s1\nAA\n" | \
          "${VSEARCH}" --derep_fulllength - --uc - \
                   --minseqlength 1 2> /dev/null | \
          awk '/^S/ {v = $8} END {print v}' -)
[[ "${COLUMN_8}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 8th collumn is * with C
DESCRIPTION="--uc 8th collumn is * with C"
COLUMN_8=$(printf ">s1\nAA\n" | \
          "${VSEARCH}" --derep_fulllength - --uc - \
                   --minseqlength 1 2> /dev/null | \
          awk '/^C/ {v = $8} END {print v}' -)
[[ "${COLUMN_8}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 8th collumn is * with H
DESCRIPTION="--uc 8th collumn is * with H"
COLUMN_8=$(printf ">s1\nAA\n>s2\nAA\n" | \
          "${VSEARCH}" --derep_fulllength - --uc - \
                   --minseqlength 1 2> /dev/null | \
          awk '/^H/ {v = $8} END {print v}' -)
[[ "${COLUMN_8}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc query sequence's label is correct in 9th column with H
DESCRIPTION="--uc query sequence's label is correct in 9th column with H"
QUERY_LABEL=$(printf ">s1\nAA\n>s2\nAA\n" | \
             "${VSEARCH}" --derep_fulllength - --uc - \
                  --minseqlength 1 2> /dev/null | \
             awk '/^H/ {v = $9} END {print v}' -)
[[ "${QUERY_LABEL}" == "s2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid sequence's label is correct in 9th column with S
DESCRIPTION="--uc centroid sequence's label is correct in 9th column with S"
CENTROID_LABEL=$(printf ">s1\nAA\n" | \
            "${VSEARCH}" --derep_fulllength - --uc - \
                     --minseqlength 1 2> /dev/null | \
            awk '/^S/ {v = $9} END {print v}' -)
[[ "${CENTROID_LABEL}" == "s1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid sequence's label is correct in 9th column with C
DESCRIPTION="--uc centroid sequence's label is correct in 9th column with C"
CENTROID_LABEL=$(printf ">s1\nAA\n" | \
            "${VSEARCH}" --derep_fulllength - --uc - \
                     --minseqlength 1 2> /dev/null | \
            awk '/^C/ {v = $9} END {print v}' -)
[[ "${CENTROID_LABEL}" == "s1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc centroid sequence's label is correct in 10th column with H
DESCRIPTION="--uc centroid sequence's label is correct in 10th column with H"
CENTROID_LABEL=$(printf ">s1\nAA\n>s2\nAA\n" | \
            "${VSEARCH}" --derep_fulllength - --uc - \
                     --minseqlength 1 2> /dev/null | \
            awk '/^H/ {v = $10} END {print v}' -)
[[ "${CENTROID_LABEL}" == "s1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 10th column is * with C
DESCRIPTION="--uc 10th column is * with C"
CENTROID_LABEL=$(printf ">s1\nAA\n" | \
            "${VSEARCH}" --derep_fulllength - --uc - \
                     --minseqlength 1 2> /dev/null | \
            awk '/^C/ {v = $10} END {print v}' -)
[[ "${CENTROID_LABEL}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --uc 10th column is * with S
DESCRIPTION="--uc 10th column is * with S"
CENTROID_LABEL=$(printf ">a_3\nAAAA\n>b_3\nAAAC\n>c_3\nAACC\n>d_3\nAGCC\n" | \
            "${VSEARCH}" --derep_fulllength - --uc - \
                     --minseqlength 1 2> /dev/null | \
            awk '/^S/ {v = $10} END {print v}' -)
[[ "${CENTROID_LABEL}" == "*" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - &>/dev/null | \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout is empty when no --userfields"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - 2>/dev/null)
[[ "${OUTPUT}" == "" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields accepts all fields #1"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields \
              aln+alnlen+bits+caln+evalue+exts+gaps+id+id0+id1 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields accepts all fields #2"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields \
              ids+mism+opens+pairs+pctgaps+pctpv+pv+qcov+qframe+qhi+qihi &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields accepts all fields #3"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields \
              qilo+ql+qlo+qrow+qs+qstrand+query+raw+target+tcov+tframe &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields accepts all fields #4"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields \
              tilo+tl+tlo+trow+ts+tstrand+id3+id4+id2+tihi+thi  &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields aln is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields aln 2>/dev/null)
[[ "${OUTPUT}" == "MMMM" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields alnlen is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields alnlen 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields bits is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields bits 2>/dev/null)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields caln is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields caln 2>/dev/null)
[[ "${OUTPUT}" == "4M" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields evalue is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields evalue 2>/dev/null)
[[ "${OUTPUT}" == "-1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields exts is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields exts 2>/dev/null)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields gaps is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields gaps 2>/dev/null)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields id is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields id 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields id0 is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields id0 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields id1 is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields id1 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields id2 is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields id2 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields id3 is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields id3 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields id4 is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields id4 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields ids is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields ids 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields mism is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields mism 2>/dev/null)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields opens is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields opens 2>/dev/null)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields pairs is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields pairs 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields pctgaps is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields pctgaps 2>/dev/null)
[[ "${OUTPUT}" == "0.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields pctpv is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields pctpv 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields pv is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields pv 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields qcov is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields qcov 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields qframe is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields qframe 2>/dev/null)
[[ "${OUTPUT}" == "+0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields qhi is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields qhi 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields qihi is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields qihi 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields qilo is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields qilo 2>/dev/null)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields ql is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields ql 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields qlo is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields qlo 2>/dev/null)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields qrow is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields qrow 2>/dev/null)
[[ "${OUTPUT}" == "AAAG" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields qs is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields qs 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields qstrand is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields qstrand 2>/dev/null)
[[ "${OUTPUT}" == "+" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields query is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields query 2>/dev/null)
[[ "${OUTPUT}" == "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields raw is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields raw 2>/dev/null)
[[ "${OUTPUT}" == "8" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields target is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields target 2>/dev/null)
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields tcov is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields tcov 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields tframe is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields tframe 2>/dev/null)
[[ "${OUTPUT}" == "+0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields thi is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields thi 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields tihi is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields tihi 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields tilo is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields tilo 2>/dev/null)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields tl is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields tl 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields tlo is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields tlo 2>/dev/null)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields trow is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields trow 2>/dev/null)
[[ "${OUTPUT}" == "AAAG" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields ts is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields ts 2>/dev/null)
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --userfields tstrand is correct"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --userout - --userfields tstrand 2>/dev/null)
[[ "${OUTPUT}" == "+" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--search_exact --userout --wordlength is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --search_exact <(printf "${search_query}") \
              --db <(printf "${database}") --biomout - --wordlength 10 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"









 # database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' ${seq1} ${seq2} ${seq3} ${seq4})
 # search_query=$(printf '>seq1\n%s\n' ${seq1})

# "${VSEARCH}" --search_exact <(printf "${search_query}") \
#             --db <(printf "${database}") --aln - --wordlength \
#             3
