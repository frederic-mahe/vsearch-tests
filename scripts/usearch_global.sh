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

DESCRIPTION="--usearch_global --alnout is accepted"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nAAAA\n') \
    --db <(printf '>seq2\nAAAA\n') \
    --id 1.0 \
    --alnout - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --alnout is accepted (warning for short sequences)"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nAAAA\n') \
    --db <(printf '>seq2\nAAAA\n') \
    --id 1.0 \
    --alnout /dev/null 2>&1 | \
    grep -q "^WARNING" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --alnout --minseqlength is accepted (no warning)"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nAAAA\n') \
    --db <(printf '>seq2\nAAAA\n') \
    --id 1.0 \
    --minseqlength 1 \
    --alnout /dev/null 2>&1 | \
    grep -q "^WARNING" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --biomout is accepted"
seq1="AAAA"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' ${seq1}) \
    --db <(printf '>seq1\n%s\n' ${seq1}) \
    --id 1.0 \
    --biomout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --blast6out is accepted"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nAAAA\n') \
    --db <(printf '>seq2\nAAAA\n') \
    --id 1.0 \
    --blast6out - &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --samout is accepted"
seq1="AAAG"
seq2="AAAA"
seq3="AATT"
seq4="ATTT"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' ${seq1}) \
    --db <(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4}) \
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
    --usearch_global <(printf '>seq1\nAAAA\n') \
    --db <(printf '>seq1\nAAAA\n') \
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
    --usearch_global <(printf '>seq1\nAAAA\n') \
    --db <(printf "${database}") \
    --otutabout - \
    --id 1.0 &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout is accepted"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nAAAA\n') \
    --db <(printf '>seq2\nAAAA\n') \
    --userout - --id 1.0 &>/dev/null && \
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
    --usearch_global <(printf '>seq1\nAAAA\n') \
    --db <(printf "${database}") \
    --samout - \
    --id 1.0 &>/dev/null &&  \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --uc is accepted"
seq1="AAAA"
"${VSEARCH}" \
    --usearch_global <(printf '>query\n%s\n' ${seq1}) \
    --db <(printf '>target\n%s\n' ${seq1}) \
    --id 1.0 \
    --uc - &>/dev/null &&  \
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

DESCRIPTION="--usearch_global --alnout finds the matching sequence"
r1="AAAA"
r2="AAAT"
r3="AATT"
r4="ATTT"
database=$(printf '>r1\n%s\n>r2\n%s\n>r3\n%s\n>r4\n%s\n' \
		  ${r1} ${r2} ${r3} ${r4})
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAA\n') \
    --db <(printf "${database}") \
    --quiet \
    --minseqlength 1 \
    --id 1.0 \
    --alnout - | \
    grep -q "^100%.*r1$" && \
    success "${DESCRIPTION}" ||
    	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --alnout finds the non-matching sequence "
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nGCCC\n') \
    --db <(printf '>r1\nAAAA\n>r2\nTTTT\n') \
    --quiet \
    --minseqlength 1 \
    --id 0.0 \
    --output_no_hits \
    --alnout - | \
    grep -q "^Query >q1$" && \
    success "${DESCRIPTION}" ||
    	failure "${DESCRIPTION}"

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
"${VSEARCH}" \
    --usearch_global <(printf 'LSDLSDL\n') \
    --db <(printf '>r1\nA\n') \
    --id 1.0 \
    --quiet \
    --minseqlength 1 \
    --alnout - 2>&1 | \
    grep -q "^Fatal error:.*$" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --alnout fails if empty database"
"${VSEARCH}" --usearch_global <(printf '>q1\nAAAA\n') \
	     --db <(printf '') \
	     --quiet \
	     --minseqlength 1 \
	     --id 1.0 \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --alnout fails if no database"
"${VSEARCH}" --usearch_global <(printf '>seq2\nAAAA\n') \
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
# rowlen is used with anything else than a fasta or alignment
# output. In the test below, vsearch accepts the --biomout and the
# rowlen options. It should not.
DESCRIPTION="--usearch_global --!alnout --rowlen is not accepted"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nA\n') \
    --db <(printf '>q1\nA\n') \
    --quiet \
    --minseqlength 1 \
    --rowlen 64 \
    --id 1.0 \
    --biomout /dev/null && \
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
	     --usearch_global <(printf '>seq2\nAAAA\n') \
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
	     --usearch_global <(printf '>seq2\nAAAA\n') \
             --db <(printf "${database}") \
	     --biomout - \
	     --id 1.0 2>/dev/null | \
		awk -F "," 'NR==15 {print $4} ')
[[ "${OUTPUT}" != "seq2" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --biomout fails if empty database"
"${VSEARCH}" --usearch_global <(printf '>seq1\nAAAA\n') \
             --db <(printf '') \
	     --biomout - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --biomout fails if no database"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\nAAAA\n') \
    --biomout - \
    --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --biomout fails if no input"
"${VSEARCH}" \
    --usearch_global  \
    --db <(printf '>seq1\nAAAA\n') \
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
"${VSEARCH}" --usearch_global <(printf '>seq1\nAAAA\n') \
             --db <(printf '') \
	     --blast6out - \
	     --id 1.0 &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
unset "OUTPUT"

DESCRIPTION="--usearch_global --blast6out fails if no database"
"${VSEARCH}" --usearch_global <(printf '>seq1\nAAAA\n') \
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
             --db <(printf '>seq1\nAAAA\n') \
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
(( "${OUTPUT}" == 1 )) && \
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
(( "${OUTPUT}" == 4 )) && \
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
	     --usearch_global <(printf '>seq2\nAAAA\n') \
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
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAA\n') \
    --db <(printf '>r1\nAAA\n') \
    --minseqlength 1 \
    --quiet \
    --id 1.0 \
    --userfields alnlen \
    --userout - | \
    grep -q "^3$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

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
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAGGGGGGGGGCCC\n') \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --minseqlength 1 \
    --quiet \
    --id 0.1 \
    --userfields caln \
    --userout - | \
    grep -q "^6M3I7MD$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

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
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAGGGGGGGGGCCC\n') \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --minseqlength 1 \
    --quiet \
    --id 0.1 \
    --userfields exts \
    --userout - | \
    grep -q "^2$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields gaps is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAGGGGGGGGGCCC\n') \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --minseqlength 1 \
    --quiet \
    --id 0.1 \
    --userfields gaps \
    --userout - | \
    grep -q "^3$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

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
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAGGGGGGGGGCCC\n') \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --userfields id0 \
    --id 0.7 \
    --quiet \
    --minseqlength 1 \
    --userout - | \
    grep -q "^85.7$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields id1 is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAGGGGGGGGGCCC\n') \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --userfields id1 \
    --id 0.7 \
    --quiet \
    --minseqlength 1 \
    --userout - | \
    grep -q "70.6" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields id2 is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAGGGGGGGGGCCC\n') \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --userfields id2 \
    --id 0.7 \
    --quiet \
    --minseqlength 1 \
    --userout - | \
    grep -q "^75.0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields id3 is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAGGGGGGGGGCCC\n') \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --userfields id3 \
    --id 0.7 \
    --quiet \
    --minseqlength 1 \
    --userout - | \
    grep -q "^81.2$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --userout --userfields id4 is correct"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAGGGGGGGGGCCC\n') \
    --db <(printf '>r1\nAAGGGGAAAAGGGGCC\n') \
    --userfields id4 \
    --id 0.7 \
    --quiet \
    --minseqlength 1 \
    --alnout - \
    --userout - | \
    grep -q "^75.0$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

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
seq1="AAAA"
seq2="TAAA"
"${VSEARCH}" \
    --usearch_global <(printf '>seq1\n%s\n' ${seq1}) \
    --db <(printf '>seq2\n%s\n' ${seq2}) \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --userfields mism \
    --userout - | \
    grep -q "^1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset seq1 seq2 DESCRIPTION

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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields ql \
    --id 1.0 2>/dev/null | \
    grep -q "^32$" && \
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields qlo \
    --id 1.0 2>/dev/null | \
    grep -q "^1$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database"

DESCRIPTION="--usearch_global --userout --userfields qrow is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields qrow \
    --id 1.0 2>/dev/null | \
    grep -q "^aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database"

DESCRIPTION="--usearch_global --userout --userfields qs is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields qs \
    --id 1.0 2>/dev/null | \
    grep -q "^32$" && \
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields qstrand \
    --id 1.0 2>/dev/null | \
    grep -q "^+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq2" "seq3" "seq4" \
      "search_query" "database" "OUTPUT"


DESCRIPTION="--usearch_global --userout --userfields qstrand is correct #2"
seq1="ATCGATCGATCGATCGATCGATCGATCGATCG"
seq4="$(rev <<< ${seq1} | tr 'ACGT' 'TGCA')"
database=$(printf '>target\n%s\n' \
		  ${seq4})
search_query=$(printf '>query\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --strand both \
    --db <(printf "${database}") \
    --userfields qstrand \
    --quiet \
    --id 0.1 \
    --userout - | \
    grep -q "^-$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "seq1" "seq4" \
      "search_query" "database"

DESCRIPTION="--usearch_global --userout --userfields query is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>query\n%s\n' ${seq1})
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields raw \
    --id 1.0 2>/dev/null | \
    grep -q "^64$" && \
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields target \
    --id 1.0 2>/dev/null | \
    grep -q "^seq1$" && \
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields tframe \
    --id 1.0 2>/dev/null | \
    grep -q "^+0$" && \
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields thi \
    --id 1.0 2>/dev/null | \
    grep -q "^32$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


DESCRIPTION="--usearch_global --userout --userfields tihi is correct"
seq1="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
seq2="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
seq3="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
seq4="GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
database=$(printf '>seq1\n%s\n>seq2\n%s\n>seq3\n%s\n>seq4\n%s\n' \
		  ${seq1} ${seq2} ${seq3} ${seq4})
search_query=$(printf '>seq2\n%s\n' ${seq1})
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields tihi \
    --id 1.0 2>/dev/null | \
    grep -q "^32$" && \
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields tihi \
    --id 0.4 2>/dev/null | \
    grep -q "^28$" && \
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields tilo \
    --id 1.0 2>/dev/null | \
    grep -q "^1$"
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields tl \
    --id 1.0 2>/dev/null | \
    grep -q "^32$" && \
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields ts \
    --id 1.0 2>/dev/null | \
    grep -q "^32$" && \
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
"${VSEARCH}" \
    --usearch_global <(printf "${search_query}") \
    --db <(printf "${database}") \
    --userout - \
    --userfields tstrand \
    --id 1.0 2>/dev/null | \
    grep -q "^+$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"



#*****************************************************************************#
#                                                                             #
#                                 Parameters                                  #
#                                                                             #
#*****************************************************************************#

# --slots written in the vsearch --help but not the man
DESCRIPTION="--usearch_global accept all man parameters"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --dbmask dust \
	     --fulldp \
	     --gapext 2I/1E \
	     --gapopen 20I/1E \
	     --hardmask \
	     --id 1.0 \
	     --iddef 2 \
	     --idprefix 0 \
	     --idsuffix 0 \
	     --leftjust \
	     --match 2 \
	     --maxaccepts 1 \
	     --maxdiffs 1 \
	     --maxgaps 1 \
	     --maxhits 1200 \
	     --maxid 1.0 \
	     --maxqsize 100 \
	     --maxqt 2.0 \
	     --maxrejects 32 \
	     --maxsizeratio 20.0 \
	     --maxsl 20.0 \
	     --maxsubs 20 \
	     --mid 0.1 \
	     --mincols 1 \
	     --minqt 1.0 \
	     --minsizeratio 1.0 \
	     --minsl 1.0 \
	     --mintsize 1 \
	     --minseqlength 1 \
	     --minwordmatches 12 \
	     --mismatch -4 \
	     --pattern "test" \
	     --qmask dust \
	     --query_cov 1.0 \
	     --rightjust \
	     --sizein \
	     --self \
	     --selfid \
	     --slots 1 \
	     --strand plus \
	     --target_cov 2.0 \
	     --weak_id 1.0 \
	     --wordlength 8 \
	     --quiet \
	     --alnout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# masking option tested in fastx_mask

#*****************************************************************************#
#                                                                             #
#                                 gapopen/ext                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --gapopen parameters fails if not slash separated"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "10I2E" \
	     --minseqlength 1 \
	     --quiet \
	     --id 0.1 \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# associations
DESCRIPTION="--usearch_global --gapopen accept all the context letter given"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "1QL/1QI/1QR/1TL/1TI/1TR/1TE/1QE" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# alone
DESCRIPTION="--usearch_global --gapopen accept all the context characters given"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "1L/1I/1R/1T/1Q/1E" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapopen fails if other characters"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "1X" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapopen fails if character first"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "L1" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapopen fails if starting with a slash"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "/1L" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapopen fails if ending with a slash"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "1L/" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapopen accepts number only"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "1" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapopen accept * symbol"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "*" \
	     --id 0.1 \
	     --minseqlength 1 \
	     --quiet \
	     --alnout - &>/dev/null && \
success "${DESCRIPTION}" || \
    failure "${DESCRIPTION}"

# man page says zero or positive integer
DESCRIPTION="--usearch_global --gapopen fails if negative number"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "-1" \
	     --minseqlength 1 \
	     --quiet \
	     --id 0.1 \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapopen fails if REAL number instead of INT"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "1.5" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapopen * --gapext * forbids gaps"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --minseqlength 1 \
    --gapopen "*" \
    --gapext "*" \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -q "^Query >q1$" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapext parameters fails if not slash separated"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "10I2E" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# associations
DESCRIPTION="--usearch_global --gapext accept all the context characters given"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "1QL/2QI/3QR/4TL/5TI/6TR/7TE/8QE/9E/*E" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# alone
DESCRIPTION="--usearch_global --gapext accept all the context characters given #2"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "1L/1I/1R/1T/1Q/1E" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapext fails if other characters"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "1X" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapext fails if character first"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "L1" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapext fails if starting with a slash"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "/1L" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapext fails if ending with a slash"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "1L/" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapext accept number only"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "1" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapext accept * symbol"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "*" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# man page says zero or positive integer
DESCRIPTION="--usearch_global --gapext fails if negative number"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "-1" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --gapext fails if REAL number instead of INT"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapext "1.5" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                          id(def)(prefix(suffix)                             #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --iddef accepts parameter 0"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --iddef 0 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --alnout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --iddef accepts parameter 1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --iddef 1 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --alnout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --iddef accepts parameter 2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --iddef 2 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --alnout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --iddef accepts parameter 3"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --iddef 3 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --alnout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --iddef accepts parameter 4"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --iddef 4 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --alnout /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --iddef is 2 when not specified"
SPECIFIED=$("${VSEARCH}" \
		--usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
		--db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
		--id 0.1 \
		--iddef 2 \
		--minseqlength 1 \
		--id 0.1 \
		--quiet \
		--alnout - | \
		   awk 'NR==6 {print $1}')
DEFAULT=$("${VSEARCH}" \
	      --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
	      --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
	      --id 0.1 \
	      --iddef 2 \
	      --minseqlength 1 \
	      --id 0.1 \
	      --quiet \
	      --alnout - | \
		 awk 'NR==6 {print $1}')
[[ "${SPECIFIED}" == "${DEFAULT}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "SPECIFIED" "DEFAULT"

DESCRIPTION="--usearch_global --iddef fails if other parameter than 0-4"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --iddef 5 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --iddef fails if no parameter"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --iddef \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# sequence used gives almost a different for each 
DESCRIPTION="--usearch_global --iddef 0 correct"
SPECIFIED=$("${VSEARCH}" \
		--usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
		--db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
		--id 0.1 \
		--iddef 0 \
		--minseqlength 1 \
		--id 0.1 \
		--quiet \
		--alnout - | \
		   awk 'NR==6 {print $1}')
USERFIELD=$("${VSEARCH}" \
	      --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
	      --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
	      --id 0.1 \
	      --minseqlength 1 \
	      --id 0.1 \
	      --quiet \
	      --userfield id0 \
	      --userout -)
USERFIELD=$(echo "($USERFIELD+0.5)/1" | bc) 
[[ "${SPECIFIED}" == "${USERFIELD}%" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "SPECIFIED" "USERFIELD"
    
DESCRIPTION="--usearch_global --iddef 1 correct"
SPECIFIED=$("${VSEARCH}" \
		--usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
		--db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
		--id 0.1 \
		--iddef 1 \
		--minseqlength 1 \
		--id 0.1 \
		--quiet \
		--alnout - | \
		   awk 'NR==6 {print $1}')
USERFIELD=$("${VSEARCH}" \
	      --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
	      --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
	      --id 0.1 \
	      --minseqlength 1 \
	      --id 0.1 \
	      --quiet \
	      --userfield id1 \
	      --userout -)
USERFIELD=$(echo "($USERFIELD+0.5)/1" | bc) 
[[ "${SPECIFIED}" == "${USERFIELD}%" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "SPECIFIED" "USERFIELD"    


DESCRIPTION="--usearch_global --iddef 2 correct"
SPECIFIED=$("${VSEARCH}" \
		--usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
		--db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
		--id 0.1 \
		--iddef 2 \
		--minseqlength 1 \
		--id 0.1 \
		--quiet \
		--alnout - | \
		   awk 'NR==6 {print $1}')
USERFIELD=$("${VSEARCH}" \
	      --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
	      --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
	      --id 0.1 \
	      --minseqlength 1 \
	      --id 0.1 \
	      --quiet \
	      --userfield id2 \
	      --userout -)
USERFIELD=$(echo "($USERFIELD+0.5)/1" | bc) 
[[ "${SPECIFIED}" == "${USERFIELD}%" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "SPECIFIED" "USERFIELD"    

DESCRIPTION="--usearch_global --iddef 3 correct"
SPECIFIED=$("${VSEARCH}" \
		--usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
		--db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
		--iddef 3 \
		--minseqlength 1 \
		--id 0.1 \
		--quiet \
		--alnout - | \
		   awk 'NR==6 {print $1}')
USERFIELD=$("${VSEARCH}" \
	      --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
	      --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
	      --minseqlength 1 \
	      --id 0.1 \
	      --quiet \
	      --userfield id3 \
	      --userout -)
USERFIELD=$(echo "($USERFIELD+0.5)/1" | bc) 
[[ "${SPECIFIED}" == "${USERFIELD}%" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "SPECIFIED" "USERFIELD"    

DESCRIPTION="--usearch_global --iddef 4 correct"
SPECIFIED=$("${VSEARCH}" \
		--usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
		--db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
		--iddef 4 \
		--minseqlength 1 \
		--id 0.1 \
		--quiet \
		--alnout - | \
		   awk 'NR==6 {print $1}')
USERFIELD=$("${VSEARCH}" \
	      --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
	      --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
	      --minseqlength 1 \
	      --id 0.1 \
	      --quiet \
	      --userfield id4 \
	      --userout -)
USERFIELD=$(echo "($USERFIELD+0.5)/1" | bc) 
[[ "${SPECIFIED}" == "${USERFIELD}%" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset "SPECIFIED" "USERFIELD"    


DESCRIPTION="--usearch_global --idprefix fails if negative"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "/1L" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --idprefix -1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --idsuffix fails if negative"
"${VSEARCH}" --usearch_global <(printf '>q1\nA\n') \
	     --db <(printf '>r1\nA\n') \
	     --gapopen "/1L" \
	     --minseqlength 1 \
	     --id 0.1 \
	     --idsuffix -1 \
	     --quiet \
	     --alnout - &>/dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# query and target equals except for the 2nd nucleotide
DESCRIPTION="--usearch_global --idprefix is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --db <(printf '>r1\nACAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --minseqlength 1 \
    --idprefix 1 \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -q "Query >q1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --idprefix is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --db <(printf '>r1\nACAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --minseqlength 1 \
    --idprefix 2 \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -q "Query >q1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# query and target equals except for the last 2nd nucleotide
DESCRIPTION="--usearch_global --idsuffix is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --db <(printf '>r1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATCA\n') \
    --minseqlength 1 \
    --idsuffix 1 \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -q "Query >q1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --idsuffix is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --db <(printf '>r1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATCA\n') \
    --minseqlength 1 \
    --idsuffix 2 \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -q "Query >q1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 left/rightjust                              #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --leftjust is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --db <(printf '>r1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATCA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -q "Query >q1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --leftjust is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --db <(printf '>r1\nGAAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATCA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -q "Query >q1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --rightjust is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --db <(printf '>r1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATCA\n') \
    --minseqlength 1 \
    --rightjust \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -q "Query >q1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --rightjust is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
    --db <(printf '>r1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATCATA\n') \
    --minseqlength 1 \
    --rightjust \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -q "Query >q1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                (mis)match                                   #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --match is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAA\n') \
    --db <(printf '>r1\nAAAA\n') \
    --minseqlength 1 \
    --match 4 \
    --mismatch -4 \
    --id 0.1 \
    --userfield raw \
    --userout - \
    --quiet | \
    grep -q "^16$" && \
    success "${DESCRIPTION}" || \
    failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --mismatch is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAACAAAATGGTGTAGGTAGCTAC\n') \
                --db <(printf '>r1\nAAACAAAATGGTGTAGGTAGCTCC\n') \
    --minseqlength 1 \
    --match 2 \
    --mismatch -4 \
    --id 0.1 \
    --quiet \
    --alnout - | \
    grep -qv "ne sait pas encore comment tester" && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                    max/min                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--usearch_global --maxaccepts is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATCTAG\n') \
    --db <(printf '>r1\nATCTAG\n>r2\nATCTAG\n>r3\nATCTAG\n>r4\nATCTAG\n') \
    --minseqlength 1 \
    --id 0.1 \
    --maxaccepts 2 \
    --quiet \
    --alnout - | \
    grep -Ec "Target .* >r[12]$" | \
    grep -q "^2$" && \
    success "${DESCRIPTION}" || \
    	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxaccepts is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATCTAG\n') \
    --db <(printf '>r1\nATCTAG\n>r2\nATCTAG\n>r3\nATCTAG\n>r4\nATCTAG\n') \
    --minseqlength 1 \
    --id 0.1 \
    --maxaccepts 1 \
    --quiet \
    --alnout - | \
    grep -Ec "Target .* >r[12]$" | \
    grep -q "^1$" && \
    success "${DESCRIPTION}" || \
    	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxaccepts 0 search in all database"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATCTAG\n') \
    --db <(printf '>r1\nATCTAG\n>r2\nATCTAG\n>r3\nATCTAG\n>r4\nATCTAG\n') \
    --minseqlength 1 \
    --id 0.1 \
    --maxaccepts 0 \
    --quiet \
    --alnout - | \
    grep -Ec "Target .* >r[1234]$" | \
    grep -q "^4$" && \
    success "${DESCRIPTION}" || \
    	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxaccepts fails if negative value"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATCTAG\n') \
    --db <(printf '>r1\nATCTAG\n>r2\nATCTAG\n>r3\nATCTAG\n>r4\nATCTAG\n') \
    --minseqlength 1 \
    --id 0.1 \
    --maxaccepts -1 \
    --quiet \
    --alnout - &>/dev/null && \
	    failure "${DESCRIPTION}" || \
    	    	success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxdiffs is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATCTAG\n') \
    --db <(printf '>r1\nATCTAG\n') \
    --minseqlength 1 \
    --id 0.1 \
    --maxdiffs 1 \
    --quiet \
    --alnout - | \
	grep -cq "Target .* >r[12]$" && \
    success "${DESCRIPTION}" || \
    	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxdiffs fails if zero"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATCTAG\n') \
    --db <(printf '>r1\nATCTAG\n') \
    --minseqlength 1 \
    --id 0.1 \
    --maxdiffs 0 \
    --quiet \
    --alnout /dev/null && \
    failure "${DESCRIPTION}" || \
    	success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxgaps is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
                --db <(printf '>r1\nAGAGCTTCAAGCGGCGTGGCGATGGTGCCCCATCA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxgaps 1 \
    --alnout  - | \
    grep -q "Query >q1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxgaps is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAGAGCTTCAAGCGCGTGGCGATGGTGCCCCATGA\n') \
                --db <(printf '>r1\nAGAGCTTCAAGCGGCGTGGCGATGGTGCCCCATCA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxgaps 0 \
    --alnout  - | \
    grep -q "Query >q1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxhits is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAA\n') \
                --db <(printf '>r1\nAA\n>r2\nAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxaccepts 0 \
    --maxhits 2 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^2$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxhits is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAA\n') \
                --db <(printf '>r1\nAA\n>r2\nAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxaccepts 0 \
    --maxhits 1 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^1$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxhits is correct #3"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAA\n') \
                --db <(printf '>r1\nAA\n>r2\nAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxaccepts 0 \
    --maxhits 0 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^0$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAA\n') \
                --db <(printf '>r1\nAAAC\n>r2\nAAAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxid 0.75 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^1$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAA\n') \
                --db <(printf '>r1\nAAAC\n>r2\nAAAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxid 0.74 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^0$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid is correct #3"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAA\n') \
                --db <(printf '>r1\nAAAC\n>r2\nAAAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --maxaccepts 0 \
    --quiet \
    --maxid 1.0 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^2$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid uses the formula of choosen iddef #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --maxid 0.95 \
    --iddef 2 \
    --alnout - | \
    grep -q "^Query >q1$" && \
    success "${DESCRIPTION}" || \
    	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid uses the formula of choosen iddef #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --maxid 0.95 \
    --iddef 0 \
    --alnout - | \
    grep -q "^Query >q1$" && \
    failure"${DESCRIPTION}" || \
    	success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid fails if greater than one"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --maxid 1.5 \
    --alnout /dev/null && \
    failure "${DESCRIPTION}" || \
    	success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid gives a warning if greater than one"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --minseqlength 1 \
    --id 0.1 \
    --maxid 1.5 \
    --quiet \
    --alnout - | \
    grep -qEi "warning|Fatal Error" && \
     success "${DESCRIPTION}" || \
    	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid fails if negative"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --minseqlength 1 \
    --id 0.1 \
    --quiet \
    --maxid -0.1 \
    --alnout /dev/null && \
    failure "${DESCRIPTION}" || \
    	success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid gives a warning if negative"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --minseqlength 1 \
    --id 0.1 \
    --maxid -0.1 \
    --quiet \
    --alnout - | \
    grep -qEi "warning|Fatal Error" && \
     success "${DESCRIPTION}" || \
    	failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxid shows nothing if zero"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nATTTCCCCCCAACCCCCCCCCACTTGATCCGCTC\n') \
    --db <(printf '>r1\nTTTCCCCCCCCCCCCCCCACTTGATCCGCTCC\n') \
    --id 0.1 \
    --minseqlength 1 \
    --id 0.1 \
    --maxid 0 \
    --quiet \
    --alnout - | \
    grep -q "Query >q1" && \
     failure "${DESCRIPTION}" || \
    	success "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxqsize is correct #1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAA\n') \
                --db <(printf '>r1\nAAAC\n>r2;size=3\nAAAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxqsize 1 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^1$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxqsize is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAA\n') \
                --db <(printf '>r1\nAAAC\n>r2\nAAAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxqsize 0 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^0$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxqsize is correct #3"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAA\n') \
                --db <(printf '>r1\nAAAC\n>r2;size=3\nAAAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --maxaccepts 0 \
    --quiet \
    --maxqsize 4 \
    --alnout - | \
    grep -cE "Target .* (>r[12]|>r[12];size=3)$" | \
    grep -q "^2$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxqt is correct # 1"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAAAAAAAA\n') \
                --db <(printf '>r1\nAAAAAAAAAA\n>r2;size=3\nAAAAAAAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxqt 1.0 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^1$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxqt is correct #2"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAAAAAAAAAAA\n') \
                --db <(printf '>r1\nAAAAAAAAAAAAAA\n>r2\nAAAAAAAAAAAAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --quiet \
    --maxqt 0 \
    --alnout - | \
    grep -c "Target .* >r[12]$" | \
    grep -q "^0$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

DESCRIPTION="--usearch_global --maxqt is correct #3"
"${VSEARCH}" \
    --usearch_global <(printf '>q1\nAAAA\n') \
                --db <(printf '>r1\nAAAC\n>r2;size=3\nAAAA\n') \
    --minseqlength 1 \
    --leftjust \
    --id 0.1 \
    --maxaccepts 0 \
    --quiet \
    --maxqt 0.4 \
    --alnout - | \
    grep -cE "Target .* (>r[12]|>r[12];size=3)$" | \
    grep -q "^2$" && \
     success "${DESCRIPTION}" || \
    	 failure "${DESCRIPTION}"

exit 0
