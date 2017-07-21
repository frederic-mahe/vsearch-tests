#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="usearch_global"
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
#                        accepted output options                              #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --userout is accepted"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
    --db <(printf '>seq2\n%s\n' "AAAA") \
    --userout - --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --alnout is accepted"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
    --db <(printf '>seq2\n%s\n' "AAAA") --alnout - --id 1.0 &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--uc is accepted"
printf ">a\nAAAA\n>b\nAAAC\n>c\nGGGG" | \
    "${VSEARCH}" \
	--derep_fulllength - \
	--uc - --minseqlength 1 --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --biomout is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1\n%s\n' ${seq1})
database=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
	     --db <(printf "${database}") --biomout - --id 1.0 &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --blast6out is accepted"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
    --db <(printf '>seq2\n%s\n' "AAAA") --blast6out - --id 1.0 &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
    --db <(printf "${database}") \
    --samout - \
	     --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --fastapairs is accepted"
"${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf '>seq1\n%s\n' "AAAG") \
	     --fastapairs - --id 1.0 &>/dev/null && \
		success "${DESCRIPTION}" || \
		    failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --matched is accepted"
"${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
             --db <(printf '>seq1\n%s\n' "AAAG") \
	     --matched - \
	     --id 1.0 &>/dev/null && \
		success "${DESCRIPTION}" || \
		    failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --mothur_shared_out is accepted"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
    --db <(printf '>seq1\n%s\n' "AAAA") \
    --mothur_shared_out - \
    --id 1.0 &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --notmatched is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
             --db <(printf "${database}") \
	     --notmatched - \
	     --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --dbmatched is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
             --db <(printf "${database}") \
	     --dbmatched - \
	     --id 1.0 &>/dev/null | \
    success "${DESCRIPTION}" || \
    failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --otutabout is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1\n%s\n' ${seq1})
database=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
    --db <(printf "${database}") \
    --otutabout - \
    --id 1.0 &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --wordlength is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
    --db <(printf "${database}") \
    --biomout - \
    --wordlength 10 \
    --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1\n%s\n' ${seq1})
database=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
    --db <(printf "${database}") \
    --samout - \
    --id 1.0 &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --uc is accepted"
seq1="AAAA"
seq2="TTTT"
seq3="CCCC"
seq3="GGGG"
search_query=$(printf '>seq1\n%s\n' ${seq1})
database=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAA") --db <(printf "${database}") --uc - --id 1.0 &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
    --db <(printf "${database}") \
    --userout - \
    --id 1.0 &>/dev/null | \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --alnout --rowlen is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
    --db <(printf "${database}") \
    --alnout - \
    --rowlen 64 \
    --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                      alnout: test expected outputs                          #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --alnout finds the identical sequence"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
             --db <(printf "${database}") \
	     --alnout - \
	     --id 1.0 2>&1 1>/dev/null | \
    awk 'NR==9 {print $7}')
[[ "${OUTPUT}" == "(100.00%)" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset OUTPUT database search_query seq{1..4}

DESCRIPTION="--usearch_global --alnout finds the identical sequence #2"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
             --db <(printf "${database}") \
	     --alnout - \
	     --id 1.0 2>&1 1>/dev/null | \
    awk 'NR==9 {print $7}')
[[ "${OUTPUT}" == "(0.00%)" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --alnout fails if wrong input"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2%s\n' ${seq1})  # bad fasta sequence
"${VSEARCH}" --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --alnout - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --alnout fails if wrong input with error message"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf 'lkqsj' ${seq1})  # bad fasta sequence
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
	     --db <(printf "${database}") \
	     --alnout - --id 1.0 2>&1 | \
      awk 'NR==10 {print $1 " " $2 " " $3 " " $4}')
[[ "${OUTPUT}" == "Fatal error: Invalid FASTA" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --alnout fails if empty database"
"${VSEARCH}" --usearch_global <(printf '>seq2%s\n' "AAAA") \
             --db <(printf '') \
	     --alnout - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --alnout fails if no database"
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --usearch_global <(printf '>seq2\n%s\n' "AAAA") \
             --alnout - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --alnout fails if no input"
seq1="AAAA"
seq2="AAAT"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq2} ${seq2} ${seq3} ${seq4})
"${VSEARCH}" \
    --usearch_global  \
    --db <(printf "${database}") --alnout - \
    --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"


DESCRIPTION="--usearch_global --alnout --rowlen gives the correct result"
seq1="AAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq3="AATTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq4="ATTTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
             --db <(printf "${database}") \
	     --alnout - \
	     --rowlen 1 \
	     --id 1.0 2>&1 2>/dev/null | \
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
DESCRIPTION="--usearch_global --!alnout --rowlen is not accepted"
seq1="AAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq3="AATTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq4="ATTTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
    --db <(printf "${database}") \
    --rowlen 64 \
    --biomout - \
    --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                     biomout: test expected outputs                          #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --biomout finds the identical sequence"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAATAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq3="AATTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq4="ATTTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
database=$(printf '>seq1\n%s\n>seq5\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq3\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --biomout - \
	     --dbmask none \
	     --id 1.0 2>/dev/null | \
		awk -F "\"" 'NR==12 {print $4}')
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --biomout finds the identical sequence #2"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq2\n%s\n' "AAAA") \
             --db <(printf "${database}") \
	     --biomout - \
	     --id 1.0 2>/dev/null | \
		awk -F "\"" 'NR==15 {print $4}')
[[ "${OUTPUT}" == "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --biomout finds the identical sequence #3"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq2\n%s\n' "AAAA") \
             --db <(printf "${database}") \
	     --biomout - \
	     --id 1.0 2>/dev/null | \
		awk -F "," 'NR==15 {print $4} ')
[[ "${OUTPUT}" != "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --biomout fails if empty database"
"${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
             --db <(printf '') \
	     --biomout - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --biomout fails if no database"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
    --biomout - \
    --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --biomout fails if no input"
"${VSEARCH}" \
    --usearch_global  \
    --db <(printf '>seq1\n%s\n' "AAAA") \
    --biomout - \
    --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --biomout fails if wrong input"
"${VSEARCH}" --usearch_global <(printf 'echec' ) \
             --db <(printf 'echec') \
	     --biomout - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

#*****************************************************************************#
#                                                                             #
#                    blast6out: test expected outputs                         #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --blast6out fails if empty database"
"${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
             --db <(printf '') \
	     --blast6out - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out fails if no database"
"${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAA") \
             --blast6out - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --blast6out fails if no input"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq2} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" --usearch_global  \
             --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --blast6out fails if wrong input"
"${VSEARCH}" --usearch_global <(printf "echec") \
             --db <(printf '>seq1\n%s\n' "AAAA") \
	     --blast6out - --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct query"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq1\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
		      --db <(printf "${database}") \
		      --blast6out - \
		      --id 1.0 2>/dev/null | \
      awk '{print $1}')
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct target"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
             --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
        awk '{print $2}')
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct similarity percentage"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
		awk '{print $3}')
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct alnlen"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq1\n%s\n' \
		  ${seq1})
OUTPUT=$("${VSEARCH}" --usearch_global <(printf "${search_query}") \
		      --db <(printf "${database}") \
		      --blast6out - \
		      --id 1.0 2>/dev/null | \
		awk '{print $4}')
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct mism"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
		awk '{print $5}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct opens"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
		awk '{print $6}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct qlo"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
		awk '{print $7}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct qhi"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
		awk '{print $8}')
[[ "${OUTPUT}" == "4" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct tlo"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
		awk '{print $9}')
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct thi"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
		awk '{print $10}')
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct evalue"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
		awk '{print $11}')
[[ "${OUTPUT}" == "-1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out finds the correct bits"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --blast6out - \
	     --id 1.0 2>/dev/null | \
		awk '{print $12}')
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"


#*****************************************************************************#
#                                                                             #
#                  (db)(not)matched: test expected outputs                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --dbmatched displays the matched sequence"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
		      --db <(printf "${database}") \
		      --dbmatched - \
		      --dbmask none \
		      --id 1.0 2>/dev/null)
EXPECTED=$(printf '>seq1\n%s\n' ${seq1})
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"
unset "EXPECTED"

DESCRIPTION="--usearch_global --dbmatched displays the matched sequence #2"
seq1="AAAG"
seq2="AAAA"
database=$(printf '>seq1\n%s\n' ${seq1})
search_query=$(printf '>seq2\n%s\n' ${seq2})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq2\n%s\n' "AAAA") \
             --db <(printf "${database}") \
	     --dbmatched - \
	     --id 1.0 2>/dev/null)
EXPECTED=$(printf '>seq1\n%s\n' ${seq1})
[[ "${OUTPUT}" != "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"
unset "EXPECTED" 

DESCRIPTION="--usearch_global --dbnotmatched displays the matched sequence"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
		      --db <(printf "${database}") \
		      --dbnotmatched - \
		      --id 1.0 2>/dev/null)
EXPECTED=$(printf '>seq1\n%s\n' ${seq1})
[[ "${OUTPUT}" != "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT" "EXPECTED"

DESCRIPTION="--usearch_global --dbnotmatched displays the matched sequence #2"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
database=$(printf '>seq1\n%s\n' ${seq1})
search_query=$(printf '>seq2\n%s\n' ${seq2})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --dbnotmatched - \
	     --dbmask none \
	     --id 1.0 2>/dev/null)
EXPECTED=$(printf '>seq1\n%s\n' ${seq1})
[[ "${OUTPUT}" == "${EXPECTED}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --matched displays the correct sequences"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
seq3="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAATTT"
database=$(printf '>seq1\n%s\n>seq4\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
		      --db <(printf "${database}") \
		      --matched - \
		      --dbmask none \
		      --id 1.0 2>/dev/null | \
		awk 'NR==1')
[[ "${OUTPUT}" == ">seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --matched displays the correct sequences #2"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq4\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq4} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --matched - \
	     --id 1.0 2>/dev/null | \
		awk 'NR==1')
[[ "${OUTPUT}" != ">seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --notmatched displays the correct sequences"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT" 
database=$(printf '>seq1\n%s\n>seq4\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
             --db <(printf "${database}") \
	     --notmatched - \
	     --id 1.0 2>/dev/null | \
        awk 'NR==1')
[[ "${OUTPUT}" != ">seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --notmatched displays the correct sequences #2"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq4\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq4} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --notmatched - \
	     --id 1.0 2>/dev/null | \
		awk 'NR==1')
[[ "${OUTPUT}" == ">seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"


#*****************************************************************************#
#                                                                             #
#                mothur_shared_out: test expected outputs                     #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --mothur_shared_out displays the correct sequences"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		      ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --mothur_shared_out - \
	     --id 1.0 2>/dev/null | \
		awk  \
		    'NR==2 {print $4} NR==3 {print $5} 
                     NR==4 {print $6} NR==5 {print $7}' | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "1 1 1 1 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"


#*****************************************************************************#
#                                                                             #
#                     otutabout: test expected outputs                        #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --otutabout displays the correct sequences"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		      ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --otutabout - \
	     --id 1.0 2>/dev/null | \
		awk  \
		    'NR==2 {print $2} NR==3 {print $3} NR==4 {print $4} NR==5 {print $5}' | \
		tr '\n' ' ')
[[ "${OUTPUT}" == "1 1 1 1 " ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"


#*****************************************************************************#
#                                                                             #
#                           uc: test expected outputs                         #
#                                                                             #
#*****************************************************************************#
#--uc already tested in dereplication_replication.sh

#*****************************************************************************#
#                                                                             #
#                         userout: test expected outputs                      #
#                                                                             #
#*****************************************************************************#
DESCRIPTION="--usearch_global --userout is empty when no --userfields"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
             --db <(printf "${database}") \
	     --userout - \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields accepts all fields #1"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
    --db <(printf "${database}") \
    --userout - \
    --userfields \
    aln+alnlen+bits+caln+evalue+exts+gaps+id+id0+id1 \
    --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields accepts all fields #2"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
    --db <(printf "${database}") \
    --userout - \
    --userfields \
    ids+mism+opens+pairs+pctgaps+pctpv+pv+qcov+qframe+qhi+qihi \
	      --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields accepts all fields #3"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
    --db <(printf "${database}") \
    --userout - \
    --userfields \
    qilo+ql+qlo+qrow+qs+qstrand+query+raw+target+tcov+tframe \
    --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "database" "OUTPUT"
DESCRIPTION="--usearch_global --userout --userfields accepts all fields #4"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
    --db <(printf "${database}") \
    --userout - \
    --userfields \
    tilo+tl+tlo+trow+ts+tstrand+id3+id4+id2+tihi+thi  \
    --id 1.0 &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields aln is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq4="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global \
	     <(printf '>seq1\n%s\n' "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields aln \
	     --id 0.4 2>/dev/null)
[[ "${OUTPUT}" == "DMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMI" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields alnlen is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq4="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global \
	     <(printf '>seq1\n%s\n' "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields alnlen \
	     --id 0.4 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields bits is correct"
seq1="AAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq3="AATTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq4="ATTTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf '>seq1\n%s\n' "AAAG") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields bits \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields caln is correct"
seq1="AAAAATTCCGAAAAAAAAAAAAAAAAAAAATGCG"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq4="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" --usearch_global \
		      <(printf '>seq1\n%s\n' "CAAAAATTCCGAAAAAAACCCCAAAAAAAAAAAAATGCGC") \
		      --db <(printf "${database}") --userout - \
		      --userfields caln \
		      --alnout - \
		      --dbmask none \
		      --qmask none \
		      --id 0.5 2>/dev/null)
[[ "${OUTPUT}" == "2I30M2D" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields evalue is correct"
seq1="AAAGAAAGAAAGAAAGAAAGAAAGAAAGAAAG"
seq2="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq3="AAAGAAAGAAAGAAAGAAAGAAAGAAAGAAAG"
seq4="AAAGAAAGAAAGAAAGAAAGAAAGAAAGAAAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global \
	     <(printf '>seq1\n%s\n' "AAAGAAAGAAAGAAAGAAAGAAAGAAAGAAAG") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields evalue \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "-1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields exts is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACCC"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq4="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global \
	     <(printf '>seq1\n%s\n' "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA") \
	     --db <(printf "${database}") --userout - \
	     --userfields exts \
	     --id 0.5 2>/dev/null)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields exts is correct #2"
seq1="AAAAAAAAAAAAAAACCCAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq4="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global \
	     <(printf '>seq1\n%s\n' "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA") \
	     --db <(printf "${database}") --userout - \
	     --userfields exts+aln \
	     --id 0.5 2>/dev/null)
[[ "${OUTPUT}" == "3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields gaps is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global \
	     <(printf '>seq1\n%s\n' "CCCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA") \
	     --db <(printf "${database}") \
	     --userout - \
	     --dbmask none \
	     --userfields gaps \
	     --id 0.5 2>/dev/null)
[[ "${OUTPUT}" == "3" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields id is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields id \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields id0 is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields id0 \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields id1 is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="AGAGAGAGAGAGAGAGAGAGAGAGAGAGAGAG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>query\n%s\n' ${seq4})
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields id1 \
    --id 0.4 2>/dev/null | \
    grep -q "50.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields id2 is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>query\n%s\n' ${seq4})
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields id2 \
    --id 1.0 2>/dev/null | \
grep -q "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields id3 is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="AAAAAAAAAAAAGGGGAAAAAAAAAAAAAAAAAAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>seq2\n%s\n' ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields id3 \
	     --id 0.7 2>/dev/null)
[[ "${OUTPUT}" == "96.9" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields id4 is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields id4 \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields ids is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields ids \
	     --id 1.0 2>/dev/null)
(( "${OUTPUT}" == 32 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"


DESCRIPTION="--usearch_global --userout --userfields id1 is not id2 when terminal gaps"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>query\n%s\n' ${seq4})
OUTPUT1=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields id1 \
	     --id 0.5 2>/dev/null)
OUTPUT2=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields id2 \
	     --id 0.5 2>/dev/null)
[[ "${OUTPUT1}" != "${OUTPUT2}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"


DESCRIPTION="--usearch_global --userout --userfields id1 is not id3 when extended gaps"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="AAAAAAAAAAAAAAAAAGGGGAAAAAAAAAAAAAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>query\n%s\n' ${seq4})
OUTPUT1=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields id1 \
	     --id 0.5 2>/dev/null)
OUTPUT2=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields id3 \
	     --id 0.5 2>/dev/null)
[[ "${OUTPUT1}" != "${OUTPUT2}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields mism is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields mism \
	     --id 1.0 2>/dev/null)
(( "${OUTPUT}" == 0 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields mism is correct #2"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="ATATATATATATATATATATATATATATATAT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>seq2\n%s\n' ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields mism \
	     --id 0.1 2>/dev/null)
(( "${OUTPUT}" == 16 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"


DESCRIPTION="--usearch_global --userout --userfields mism is correct #3"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="TAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>seq2\n%s\n' ${seq4})
"${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields mism \
	     --id 0.1 2>/dev/null | \
		grep -q "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"


DESCRIPTION="--usearch_global --userout --userfields mism is correct #4"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="TTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>seq2\n%s\n' ${seq4})
"${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields mism \
	     --id 0.1 2>/dev/null | \
		grep -q "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"


DESCRIPTION="--usearch_global --userout --userfields mism is correct #5"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>seq2\n%s\n' ${seq4})
"${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields mism \
	     --id 0.1 2>/dev/null | \
		grep -q "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"



DESCRIPTION="--usearch_global --userout --userfields mism is correct #6"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAATT"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>seq2\n%s\n' ${seq4})
"${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields mism \
	     --id 0.1 2>/dev/null | \
		grep -q "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"


DESCRIPTION="--usearch_global --userout --userfields opens is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields opens \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields pairs is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields pairs \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields pctgaps is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields pctgaps \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "0.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields pctpv is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields pctpv \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields pv is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields pv \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields qcov is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields qcov \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields qframe is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields qframe \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "+0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields qhi is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields qhi \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields qihi is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields qihi \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields qilo is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields qilo \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields ql is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields ql \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields qlo is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields qlo \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields qrow is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields qrow \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields qs is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields qs \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields qstrand is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields qstrand \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "+" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"

DESCRIPTION="--usearch_global --userout --userfields query is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>query\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields query \
	     --id 1.0 2>/dev/null)

"${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields query \
	     --id 1.0 2>/dev/null | \
    grep -q "^seq1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields raw is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields raw \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "64" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields target is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>query\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields target \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "seq1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields tcov is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields tcov \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "100.0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields tframe is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields tframe \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "+0" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields thi is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields thi \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

exit
DESCRIPTION="--usearch_global --userout --userfields tihi is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields tihi \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields tihi is correct #2"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAATCCA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="AAAAAAAAAAAAAAAAAAAAAAAAAAAACGAAGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n' \
		  ${seq1} ${seq2} ${seq3})
search_query=$(printf '>seq2\n%s\n' ${seq4})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields tihi \
	     --id 0.4 2>/dev/null)
(( "${OUTPUT}" == 28 )) && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields tilo is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields tilo \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields tl is correct"d
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields tl \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields tlo is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields tlo \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "1" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields trow is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
	     --db <(printf "${database}") \
	     --userout - \
	     --dbmask none \
	     --userfields trow \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "${seq1}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields ts is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
	     --db <(printf "${database}") \
	     --userout - \
	     --userfields ts \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "32" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields tstrand is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
OUTPUT=$("${VSEARCH}" \
	     --usearch_global <(printf "${search_query}") \
             --db <(printf "${database}") \
	     --userout - \
	     --userfields tstrand \
	     --id 1.0 2>/dev/null)
[[ "${OUTPUT}" == "+" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

exit 0
