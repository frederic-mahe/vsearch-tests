#!/bin/bash -

## Print a header
SCRIPT_NAME="fastq_join"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    exit 1
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}

## use the first binary in $PATH by default, unless user wants
## to test another binary
VSEARCH=$(which vsearch 2> /dev/null)
[[ "${1}" ]] && VSEARCH="${1}"

DESCRIPTION="check if vsearch is executable"
[[ -x "${VSEARCH}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                           mandatory options                                 #
#                                                                             #
#*****************************************************************************#

## -------------------------------------------------------------------- reverse

DESCRIPTION="--fastq_join requires --reverse"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## -------------------------------- mandatory output file: fastaout or fastqout

DESCRIPTION="--fastq_join requires an output file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_join requires an output file (fastq in, fastaout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join outputs to fasta file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join outputs fasta to fasta file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join fails if unable to open output file for writing (fastq in, fastaout)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--fastq_join requires an output file (fastq in, fastqout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join outputs to fastq file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join outputs fastq to fastq file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join fails if unable to open output file for writing (fastq in, fastqout)"
TMP=$(mktemp) && chmod u-w ${TMP}  # remove write permission
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout ${TMP} 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
chmod u+w ${TMP} && rm -f ${TMP}
unset TMP

DESCRIPTION="--fastq_join fastqout requires fastq input (both inputs)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf ">s\nA\n") \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_join fastqout requires fastq input (mix: fasta forward, fastq reverse)"
printf ">s\nA\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf ">@\nA\n+\nI\n") \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_join fastqout requires fastq input (mix: fastq forward, fasta reverse)"
printf ">@\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf ">s\nA\n") \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_join accepts empty input (both forward and reverse)"
printf "" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "") \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join keeps empty sequences"
printf "@s\n\n+\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\n\n+\n") \
        --fastaout - 2> /dev/null | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join rejects inputs with different number of entries (empty forward)"
printf "" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join rejects inputs with different number of entries (empty reverse)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "") \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# accept entries shorter than 32 nucleotides by default
DESCRIPTION="--fastq_join accepts short fastq entry"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join can output both fasta and fastq"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout /dev/null \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            core functionality                               #
#                                                                             #
#*****************************************************************************#

## ----------------------------------------------------- test general behaviour

# join paired-end sequence reads into one sequence
DESCRIPTION="--fastq_join joins two fastq reads into a single entry"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    awk '/^>/ {c += 1} END {exit c == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join joins two fastq reads (join sequences)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    grep -qw "A.*T" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join joins two fastq reads (join quality)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "I.*I" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# the resulting sequences consist of the forward read, the padding
# sequence and the reverse complement of the reverse read
DESCRIPTION="--fastq_join outputs sequences starting with the forward sequence"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -q "^A" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join outputs sequences ending with the reverse-complement of the reverse sequence"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -q "A$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# add a gap between them using a padding sequence
DESCRIPTION="--fastq_join adds a padding sequence (8 Ns by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    grep -qw "ANNNNNNNNT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join adds a padding quality string (8 Is by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "IIIIIIIIII" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join adds a padding sequence to empty entries"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\n\n+\n\n") \
        --fastaout - 2> /dev/null | \
    grep -qw "NNNNNNNN" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join adds a padding quality string to empty entries"
printf "@s\n\n+\n\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\n\n+\n\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "IIIIIIII" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# the sequences are not merged as with the fastq_mergepairs command
DESCRIPTION="--fastq_join joins paired-end reads (no merging)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "ANNNNNNNNA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join counts the number of joined reads"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --fastqout /dev/null 2>&1 | \
    grep -qEw "1 pairs? joined" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join counts the number of joined reads (empty input)"
printf "" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "") \
        --fastqout /dev/null 2>&1 | \
    grep -qEw "0 pairs? joined" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join preserves sequence case (lowercase input -> lowercase output)"
printf "@s\na\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nt\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "aNNNNNNNNa" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

(
    printf "A\tT\n"
    printf "C\tG\n"
    printf "G\tC\n"
    printf "T\tA\n"
    printf "U\tA\n"
    printf "B\tV\n"
    printf "D\tH\n"
    printf "H\tD\n"
    printf "K\tM\n"
    printf "M\tK\n"
    printf "N\tN\n"
    printf "R\tY\n"
    printf "S\tS\n"
    printf "V\tB\n"
    printf "W\tW\n"
    printf "Y\tR\n"
) | \
    while read A B; do
        DESCRIPTION="--fastq_join reverse-complements ${A} into ${B}"
        printf "@s\nA\n+\nI\n" | \
            "${VSEARCH}" \
                --fastq_join - \
                --reverse <(printf "@s\n%s\n+\nI\n" ${A}) \
                --fastqout - 2> /dev/null | \
            grep -qw "ANNNNNNNN${B}" && \
            success "${DESCRIPTION}" || \
                failure "${DESCRIPTION}"
    done

DESCRIPTION="--fastq_join preserves U in forward sequence"
printf "@s\nU\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "UNNNNNNNNA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join preserves quality values (Q39)"
printf "@s\nU\n+\nH\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nH\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "HIIIIIIIIH" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join preserves quality values (Q0)"
printf "@s\nU\n+\n!\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\n!\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "!IIIIIIII!" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join discards entries with unexpected quality values (negative value: SPACE)"
printf "@s\nU\n+\n \n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\n \n") \
        --fastqout - 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join preserves quality values (Q41)"
printf "@s\nU\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nJ\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "JIIIIIIIIJ" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join preserves quality values (Q42)"
printf "@s\nU\n+\nK\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nK\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "KIIIIIIIIK" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join preserves quality values (Q93)"
printf "@s\nU\n+\n~\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\n~\n") \
        --fastqout - 2> /dev/null | \
    grep -qw "~IIIIIIII~" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join does not fold fastq sequences longer than 80 nucleotides"
(
    printf "@s\n"
    printf "%080s\n" | tr " " "A"
    printf "+\n"
    printf "%080s\n" | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -Ewq "I{81,}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join folds fasta sequences longer than 80 nucleotides"
(
    printf "@s\n"
    printf "%080s\n" | tr " " "A"
    printf "+\n"
    printf "%080s\n" | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    awk 'END {exit NR == 3 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# if F and R have different names, which one is retained?
DESCRIPTION="--fastq_join joins reads independently of their names"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s2\nT\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    awk '/^@/ {c += 1} END {exit c == 1 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join preserves the name of the forward read"
printf "@s1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s2\nT\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    grep -wq "@s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## coverage tests: trigger memory reverse sequence reallocation (fastq
## entries with more than 1,024 nucleotides)
DESCRIPTION="--fastq_join long reverse entry (> 1,024 nucleotides)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\n%01025s\n" | tr " " "A"
                    printf "+\n%01025s\n" | tr " " "I") \
        --fastqout - 2> /dev/null | \
    awk 'NR == 2 {exit length($1) > 1025 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join long reverse entry (> 1,024 quality symbols)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\n%01025s\n" | tr " " "A"
                    printf "+\n%01025s\n" | tr " " "I") \
        --fastqout - 2> /dev/null | \
    awk 'NR == 4 {exit length($1) > 1025 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## default pre-allocated length is 1,024 + 8 + 1,024 = 2,056
DESCRIPTION="--fastq_join long reverse entry (> 2,056 nucleotides)"
(
    printf "@s\n%02056s\n" | tr " " "A"
    printf "+\n%02056s\n" | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    awk 'NR == 2 {exit length($1) > 2056 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              core options                                   #
#                                                                             #
#*****************************************************************************#

#   --join_padgap STRING        sequence string used for padding (NNNNNNNN)
#   --join_padgapq STRING       quality string used for padding (IIIIIIII)

## ---------------------------------------------------------------- join_padgap

# sequence string used for padding
DESCRIPTION="--fastq_join --join_padgap is accepted"
printf "@s\nT\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgap "NNNNNNNN" \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

for S in A C G T U B D H K M N R S V W Y a c g t u b d h k m n r s v w y ; do
    DESCRIPTION="--fastq_join --join_padgap accepts all IUPAC symbols (${S})"
    printf "@s\nA\n+\nI\n" | \
        "${VSEARCH}" \
            --fastq_join - \
            --reverse <(printf "@s\nT\n+\nI\n") \
            --join_padgap "${S}${S}${S}${S}${S}${S}${S}${S}" \
            --fastqout - 2> /dev/null | \
        grep -Eqw "A${S}{8,}A" && \
        success "${DESCRIPTION}" || \
	    failure "${DESCRIPTION}"
done

DESCRIPTION="--fastq_join --join_padgap accepts non IUPAC symbols (X)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgap "XXXXXXXX" \
        --fastqout - 2> /dev/null | \
    grep -qw "AXXXXXXXXA" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --join_padgap accepts non IUPAC symbols (SPACE)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgap "        " \
        --fastqout - 2> /dev/null | \
    grep -qw "A        A" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --join_padgap accepts non IUPAC symbols (digits)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgap "01234567" \
        --fastqout - 2> /dev/null | \
    grep -qw "A01234567A" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------- join_padgapq

DESCRIPTION="--fastq_join --join_padgapq is accepted"
printf "@s\nT\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgapq "IIIIIIII" \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --join_padgapq accepts J (Q41)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgapq "JJJJJJJJ" \
        --fastqout - 2> /dev/null | \
    grep -qw "IJJJJJJJJI" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --join_padgapq accepts ! (Q0)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgapq "!!!!!!!!" \
        --fastqout - 2> /dev/null | \
    grep -qw "I!!!!!!!!I" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --join_padgapq accepts ~ (Q93)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgapq "~~~~~~~~" \
        --fastqout - 2> /dev/null | \
    grep -qw "I~~~~~~~~I" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --join_padgapq accepts SPACE (< Q0)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgapq "        " \
        --fastqout - 2> /dev/null | \
    grep -qw "I        I" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join padding can be empty"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgap "" \
        --join_padgapq "" \
        --fastqout - 2> /dev/null | \
    grep -qw "II" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join sequence and quality padding must have the same length"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgap "NN" \
        --join_padgapq "I" \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

# test very long padding
DESCRIPTION="--fastq_join sequence and quality padding can be long (256 chars)"
SEQ=$(printf "%0256s" | tr " " "N")
QUAL=$(printf "%0256s" | tr " " "I")
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgap "${SEQ}" \
        --join_padgapq "${QUAL}" \
        --fastqout - 2> /dev/null | \
    awk 'NR == 2 {exit length($1) == 258 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
unset SEQ QUAL

DESCRIPTION="--fastq_join sequence and quality padding can be long (1,024 chars)"
SEQ=$(printf "%01024s" | tr " " "N")
QUAL=$(printf "%01024s" | tr " " "I")
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nT\n+\nI\n") \
        --join_padgap "${SEQ}" \
        --join_padgapq "${QUAL}" \
        --fastqout - 2> /dev/null | \
    awk 'NR == 2 {exit length($1) == 1026 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"
unset SEQ QUAL


#*****************************************************************************#
#                                                                             #
#                            secondary options                                #
#                                                                             #
#*****************************************************************************#

# The valid options for the fastq_join command are: --bzip2_decompress
# --fasta_width --fastq_ascii --fastq_qmax --fastq_qmin
# --gzip_decompress --label_suffix --lengthout --log --no_progress
# --quiet --relabel --relabel_keep --relabel_md5 --relabel_self
# --relabel_sha1 --sizein --sizeout --threads --xee --xlength --xsize

## ----------------------------------------------------------- bzip2_decompress

DESCRIPTION="--fastq_join --bzip2_decompress is accepted (normal input)"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n" | bzip2) \
        --bzip2_decompress \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join rejects compressed stdin (default, bzip2)"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --bzip2_decompress is accepted (empty inputs)"
printf "" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "" | bzip2) \
        --bzip2_decompress \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# both inputs need to be compressed
DESCRIPTION="--fastq_join --bzip2_decompress accepts compressed stdin"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n" | bzip2) \
        --bzip2_decompress \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --bzip2_decompress rejects uncompressed stdin (forward)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n" | bzip2) \
        --bzip2_decompress \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --bzip2_decompress rejects uncompressed stdin (reverse)"
printf "@s\nA\n+\nI\n" | \
    bzip2 | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --bzip2_decompress \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ---------------------------------------------------------------- fasta_width

# Fasta files produced by vsearch are wrapped (sequences are written on
# lines of integer nucleotides, 80 by default). Set the value to zero to
# eliminate the wrapping.

DESCRIPTION="--fastq_join --fasta_width is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fasta_width 1 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

# 80+ nucleotides, expect wrapping
DESCRIPTION="--fastq_join fastq output is not wrapped"
(
    printf "@s\n%080s\n" | tr " " "A"
    printf "+\n%080s\n" | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout - 2> /dev/null | \
    awk 'NR == 2 {exit length($1) > 80 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join fasta output is wrapped by default (80 chars)"
(
    printf "@s\n%080s\n" | tr " " "A"
    printf "+\n%080s\n" | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    awk 'NR == 2 {exit length($1) == 80 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fasta_width controls fasta wrapping"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fasta_width 1 \
        --fastaout - 2> /dev/null | \
    awk 'END {exit NR == 11 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fasta_width is accepted (empty input)"
printf "" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "") \
        --fasta_width 80 \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fasta_width 2^32 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fasta_width $(( 2 ** 32 )) \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# expect 89 nucleotides on the second line
DESCRIPTION="--fastq_join --fasta_width 0 (no wrapping)"
(
    printf "@s\n%080s\n" | tr " " "A"
    printf "+\n%080s\n" | tr " " "I"
) | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fasta_width 0 \
        --fastaout - 2> /dev/null | \
    awk 'NR == 2 {exit length($1) == 89 ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- fastq_ascii

DESCRIPTION="--fastq_join --fastq_ascii is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 33 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_ascii 33 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 33 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_ascii 64 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 64 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_ascii values other than 33 and 64 are rejected"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 63 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_ascii 64 default quality padding is Q40 (h)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 64 \
        --fastqout - 2> /dev/null | \
    grep -qw "IhhhhhhhhI" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# still possible for users to request a string of eight 'I'
DESCRIPTION="--fastq_join --fastq_ascii 64 accepts low quality (same as default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --join_padgapq "IIIIIIII" \
        --fastq_ascii 64 \
        --fastqout - 2> /dev/null | \
    grep -qw "IIIIIIIIII" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmax

# fastq_qmax is accepted but has no effect!

DESCRIPTION="--fastq_join --fastq_qmax is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmax 41 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmax accepts lower quality values (H = 39)"
printf "@s\nA\n+\nH\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmax 40 \
        --fastqout - 2> /dev/null |\
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmax accepts equal quality values (I = 40)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmax 40 \
        --quiet \
        --fastqout - 2> /dev/null |\
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_qmax does not reject higher quality values (J = 41)
DESCRIPTION="--fastq_join --fastq_qmax is ignored and has no effect"
printf "@s\nA\n+\nJ\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmax 40 \
        --fastqout - 2> /dev/null |\
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmax must be a positive integer"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmax -1 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmax can be set to zero"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmax 0 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmax can be set to 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 33 \
        --fastq_qmax 93 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmax cannot be greater than 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 33 \
        --fastq_qmax 94 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmax can be set to 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 64 \
        --fastq_qmax 62 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmax cannot be greater than 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 64 \
        --fastq_qmax 63 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## ----------------------------------------------------------------- fastq_qmin

# fastq_qmin is accepted but has no effect!

DESCRIPTION="--fastq_join --fastq_qmin is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 0 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmin accepts higher quality values (0 = 15)"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 14 \
        --fastqout - 2> /dev/null |\
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmin accepts equal quality values (0 = 15)"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 15 \
        --fastqout - 2> /dev/null |\
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_qmin does not reject lower quality values (0 = 15)
DESCRIPTION="--fastq_join --fastq_qmin is ignored and has no effect"
printf "@s\nA\n+\n0\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 16 \
        --fastqout - 2> /dev/null |\
    grep -qw "@s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmin must be a positive integer"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin -1 \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmin can be set to zero (default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 0 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmin can be lower than fastq_qmax (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 40 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## allows to select only reads with a specific Q value
DESCRIPTION="--fastq_join --fastq_qmin can be equal to fastq_qmax (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 41 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --fastq_qmin cannot be higher than fastq_qmax (41 by default)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_qmin 42 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# but not higher, as it cannot be greater than qmax
DESCRIPTION="--fastq_join --fastq_qmin can be set to 93 (offset 33)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 33 \
        --fastq_qmin 93 \
        --fastq_qmax 93 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# but not higher, as it cannot be greater than qmax
DESCRIPTION="--fastq_join --fastq_qmin can be set to 62 (offset 64)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastq_ascii 64 \
        --fastq_qmin 62 \
        --fastq_qmax 62 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------ gzip_decompress

DESCRIPTION="--fastq_join --gzip_decompress is accepted (compressed inputs)"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n" | gzip) \
        --gzip_decompress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join rejects compressed stdin (gzip)"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --gzip_decompress is accepted (empty input)"
printf "" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "" | gzip) \
        --gzip_decompress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --gzip_decompress accepts compressed stdin"
printf "@s\nA\n+\nI\n" | \
    gzip | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n" | gzip) \
        --gzip_decompress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# more flexible than bzip2
DESCRIPTION="--fastq_join --gzip_decompress accepts uncompressed stdin"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --gzip_decompress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join rejects --bzip2_decompress + --gzip_decompress"
printf "" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --bzip2_decompress \
        --gzip_decompress \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## --------------------------------------------------------------- label_suffix

DESCRIPTION="--fastq_join --label_suffix is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --label_suffix "suffix" \
        --fastaout /dev/null 2> /dev/null  && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --label_suffix adds suffix (fastq in, fasta out)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --label_suffix ";suffix" \
        --fastaout - 2> /dev/null | \
    grep -qw ">s;suffix" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --label_suffix adds suffix (fastq in, fastq out)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --label_suffix ";suffix" \
        --fastqout - 2> /dev/null | \
    grep -qw "@s;suffix" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --label_suffix adds suffix (empty suffix string)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --label_suffix "" \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ------------------------------------------------------------------ lengthout

DESCRIPTION="--fastq_join --lengthout is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --lengthout \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --lengthout adds length annotations to output"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --lengthout \
        --fastaout - 2> /dev/null | \
    grep -wq ">s;length=10" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ log

DESCRIPTION="--fastq_join --log is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --log /dev/null \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --log writes to a file"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout /dev/null \
        --log - 2> /dev/null | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --log + --quiet prevents messages to be sent to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --quiet \
        --fastaout /dev/null \
        --log /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --log reports time and memory"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout /dev/null \
        --log - 2> /dev/null | \
    grep -q "memory" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --log reports number of joined pairs"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout /dev/null \
        --log - 2> /dev/null | \
    grep -q "joined" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------- no_progress

DESCRIPTION="--fastq_join --no_progress is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --no_progress \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## note: progress is not written to the log file
DESCRIPTION="--fastq_join --no_progress removes progressive report on stderr (no visible effect)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --no_progress \
        --fastaout /dev/null 2>&1 | \
    grep -iq "^joining" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- quiet

DESCRIPTION="--fastq_join --quiet is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --quiet \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## fixed bug: number of joined sequences is written to stderr, or not if quiet is set
DESCRIPTION="--fastq_join --quiet eliminates all (normal) messages to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --quiet \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --quiet allows error messages to be sent to stderr"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --quiet \
        --quiet2 \
        --fastaout /dev/null 2>&1 | \
    grep -q "." && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- relabel

DESCRIPTION="--fastq_join --relabel is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel renames sequence (label + ticker)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --fastaout - 2> /dev/null | \
    grep -wq ">label1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel renames sequence (empty label, only ticker)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --quiet \
        --relabel "" \
        --fastaout - 2> /dev/null | \
    grep -wq ">1" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel cannot combine with --relabel_md5"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --relabel_md5 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel cannot combine with --relabel_sha1"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --relabel_sha1 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_keep

DESCRIPTION="--fastq_join --relabel_keep is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --relabel_keep \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_keep renames and keeps original sequence name"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --relabel_keep \
        --fastaout - 2> /dev/null | \
    grep -wq ">label1 s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## ---------------------------------------------------------------- relabel_md5

DESCRIPTION="--fastq_join --relabel_md5 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_md5 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_md5 relabels using MD5 hash of sequence"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_md5 \
        --fastaout - 2> /dev/null | \
    grep -qw ">c70eb64a711ee0d143b42e6594139dfe" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_self

DESCRIPTION="--fastq_join --relabel_self is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_self \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_self relabels using sequence as label"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_self \
        --fastaout - 2> /dev/null | \
    grep -qw ">ANNNNNNNNT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------- relabel_sha1

DESCRIPTION="--fastq_join --relabel_sha1 is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_sha1 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_sha1 relabels using SHA1 hash of sequence"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --quiet \
        --relabel_sha1 \
        --fastaout - 2> /dev/null | \
    grep -qw ">dc327932820a3b0750c30bd768d9c2e95ce6f794" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --------------------------------------------------------------------- sizein

DESCRIPTION="--fastq_join --sizein is accepted (no size annotation)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --sizein is accepted (size annotation)"
printf "@s;size=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s;size=1\nA\n+\nI\n") \
        --sizein \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --sizein (no size in, no size out)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## bug? size annotations are not implied?
DESCRIPTION="--fastq_join --sizein --sizeout does not assume size=1 (no size annotation)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --sizein propagates size annotations (sizeout is implied)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --fastaout - 2> /dev/null | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

## -------------------------------------------------------------------- sizeout

# When using --relabel, --relabel_self, --relabel_md5 or --relabel_sha1,
# preserve and report abundance annotations to the output fasta file
# (using the pattern ';size=integer;').

DESCRIPTION="--fastq_join --sizeout is accepted (no size)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizeout \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --sizeout is accepted (with size)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizeout \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --sizeout missing size annotations are not added (no size)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# without sizein, annotations are discarded
DESCRIPTION="--fastq_join size annotations are discarded (without sizein, with sizeout)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join size annotations are discarded (with sizein and sizeout)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join size annotations are left untouched (without sizein and sizeout)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastaout - 2> /dev/null | \
    grep -qw ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## add abundance annotations
DESCRIPTION="--fastq_join --relabel no size annotations (without --sizeout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --fastaout - 2> /dev/null | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel --sizeout does no add size annotations"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_self no size annotations (without --sizeout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_self \
        --fastaout - 2> /dev/null | \
    grep -qw ">ANNNNNNNNT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_self --sizeout adds size annotations"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_self \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">ANNNNNNNNT;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_md5 no size annotations (without --sizeout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_md5 \
        --fastaout - 2> /dev/null | \
    grep -qw ">c70eb64a711ee0d143b42e6594139dfe" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_md5 --sizeout adds size annotations"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_md5 \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">c70eb64a711ee0d143b42e6594139dfe;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_sha1 no size annotations (without --sizeout)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_sha1 \
        --fastaout - 2> /dev/null | \
    grep -qw ">dc327932820a3b0750c30bd768d9c2e95ce6f794" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_sha1 --sizeout adds size annotations"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_sha1 \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">dc327932820a3b0750c30bd768d9c2e95ce6f794;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## preserve abundance annotations
DESCRIPTION="--fastq_join --relabel no size annotations (size annotation in, without --sizeout)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --fastaout - 2> /dev/null | \
    grep -qw ">label1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel --sizeout preserves size annotations (without sizein)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel "label" \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel --sizeout preserves size annotations (with sizein)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --relabel "label" \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">label1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_self no size annotations (size annotation in, without --sizeout)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_self \
        --fastaout - 2> /dev/null | \
    grep -qw ">ANNNNNNNNT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_self --sizeout preserves size annotations (without sizein)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_self \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">ANNNNNNNNT;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_self --sizeout preserves size annotations (with sizein)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --relabel_self \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">ANNNNNNNNT;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_md5 no size annotations (size annotation in, without --sizeout)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_md5 \
        --fastaout - 2> /dev/null | \
    grep -qw ">c70eb64a711ee0d143b42e6594139dfe" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_md5 --sizeout preserves size annotations"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_md5 \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">c70eb64a711ee0d143b42e6594139dfe;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_md5 --sizeout preserves size annotations (with sizein)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --relabel_md5 \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">c70eb64a711ee0d143b42e6594139dfe;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_sha1 no size annotations (size annotation in, without --sizeout)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_sha1 \
        --fastaout - 2> /dev/null | \
    grep -qw ">dc327932820a3b0750c30bd768d9c2e95ce6f794" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_sha1 --sizeout preserves size annotations"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_sha1 \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">dc327932820a3b0750c30bd768d9c2e95ce6f794;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --relabel_sha1 --sizeout preserves size annotations (with sizein)"
printf "@s;size=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --relabel_sha1 \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -qw ">dc327932820a3b0750c30bd768d9c2e95ce6f794;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- threads

DESCRIPTION="--fastq_join --threads is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --threads 1 \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --threads > 1 triggers a warning (not multithreaded)"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --threads 2 \
        --fastaout /dev/null 2>&1 | \
    grep -iq "warning" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ------------------------------------------------------------------------ xee

DESCRIPTION="--fastq_join --xee is accepted"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --xee \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --xee removes expected error annotations from input"
printf "@s;ee=1.00\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --xee \
        --fastaout - 2> /dev/null | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## -------------------------------------------------------------------- xlength

DESCRIPTION="--fastq_join --xlength is accepted"
printf "@s;length=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --xlength \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --xlength removes length annotations from input"
printf "@s;length=1\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --xlength \
        --fastaout - 2> /dev/null | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --xlength accepts input without length annotations"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --xlength \
        --fastaout - 2> /dev/null | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --xlength removes length annotations (input), lengthout adds them (output)"
printf "@s;length=2\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --xlength \
        --lengthout \
        --fastaout - 2> /dev/null | \
    grep -wq ">s;length=10" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## ---------------------------------------------------------------------- xsize

## --xsize is accepted
DESCRIPTION="--fastq_join --xsize is accepted"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --xsize \
        --fastaout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --xsize strips abundance values"
printf "@s;size=1;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizein \
        --xsize \
        --fastaout - 2> /dev/null | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --xsize strips abundance values (without --sizein)"
printf "@s;size=1;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --xsize \
        --fastaout - 2> /dev/null | \
    grep -q "^>s;size=1" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

# xsize + sizein + sizeout + relabel_keep: ?
DESCRIPTION="--fastq_join --xsize + sizeout (preserve size)"
printf "@s;size=2;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --xsize \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -wq ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --xsize + sizein (no size)"
printf "@s;size=2;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizeout \
        --xsize \
        --fastaout - 2> /dev/null | \
    grep -wq ">s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --xsize + sizein + sizeout (preserve size)"
printf "@s;size=2;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --sizeout \
        --xsize \
        --fastaout - 2> /dev/null | \
    grep -wq ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastq_join --xsize + sizein + sizeout + relabel_keep (keep old size)"
printf "@s;size=2;\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --relabel_keep \
        --sizein \
        --xsize \
        --sizeout \
        --fastaout - 2> /dev/null | \
    grep -wq ">s;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                              invalid options                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastq_join --output is rejected"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --output /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --maxseqlength is rejected"
printf ">s\n%081s\n" | tr " " "A" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --maxseqlength 81 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --minseqlength is rejected"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --minseqlength 1 \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"

DESCRIPTION="--fastq_join --notrunclabels is rejected"
printf "@s\nA\n+\nI\n" | \
    "${VSEARCH}" \
        --fastq_join - \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --notrunclabels \
        --fastaout /dev/null 2> /dev/null && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               memory leaks                                  #
#                                                                             #
#*****************************************************************************#

## valgrind: search for errors and memory leaks
if which valgrind > /dev/null 2>&1 ; then
    TMP=$(mktemp)
    valgrind \
        --log-file="${TMP}" \
        --leak-check=full \
        "${VSEARCH}" \
        --fastq_join <(printf "@s\nA\n+\nI\n") \
        --reverse <(printf "@s\nA\n+\nI\n") \
        --fastqout /dev/null \
        --log /dev/null \
        --fastaout /dev/null 2> /dev/null
    DESCRIPTION="--fastq_join valgrind (no leak memory)"
    grep -q "in use at exit: 0 bytes" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    DESCRIPTION="--fastq_join valgrind (no errors)"
    grep -q "ERROR SUMMARY: 0 errors" "${TMP}" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    rm -f "${TMP}"
    unset TMP
fi


#*****************************************************************************#
#                                                                             #
#                                    notes                                    #
#                                                                             #
#*****************************************************************************#

# - sizein is accepted but has no effect?
# - sizeout is accepted but has no effect?


exit 0
