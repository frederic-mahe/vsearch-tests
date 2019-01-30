#!/bin/bash -

## Print a header
SCRIPT_NAME="subsampling options"
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

## Constructing a test file
FASTQx1000=$(mktemp)
for ((i=1 ; i<=1000 ; i++)) ; do
    printf "@%s%d\nA\n+\nG\n" "seq" ${i}
done > "${FASTQx1000}"

## Constructing a test file
FASTAx1000=$(mktemp)
for ((i=1 ; i<=1000 ; i++)) ; do
    printf ">%s%d\nA\n" "seq" ${i}
done > "${FASTAx1000}"

## Is vsearch installed?
VSEARCH=$(which vsearch)
DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] && success "${DESCRIPTION}" || failure "${DESCRIPTION}"

if [[ ${OSTYPE} =~ darwin ]] ; then
    md5sum() { md5 -r ; }
    sha1sum() { shasum ; }
fi

#*****************************************************************************#
#                                                                             #
#                                  --fastaout                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastaout is accepted"
printf "@s1\nA\n+\nG" | \
"${VSEARCH}" --fastx_subsample - --fastaout - --sample_size 1 &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastaout fill a file"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout change fastq to fasta"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout change fastq to fasta"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout fasta to fasta is correct"
OUTPUT=$(mktemp)
printf ">s1\nA" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                             --fastaout_discarded                            #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastaout_discarded is accepted"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA" | \
    "${VSEARCH}" --fastx_subsample - --fastaout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastaout - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout_discarded fill a file"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA" | \
    "${VSEARCH}" --fastx_subsample - --fastaout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastaout - &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout_discarded discard sequences from the input (fasta)"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA" | \
    "${VSEARCH}" --fastx_subsample - --fastaout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastaout - &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] || \
    [[ $(cat "${OUTPUT}") == $(printf ">s2\nA") ]] && \
	success  "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastaout_discarded discard sequences from the input (fastq)"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastaout - &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA") ]] || \
    [[ $(cat "${OUTPUT}") == $(printf ">s2\nA") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                --fastq_ascii                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastq_ascii is accepted"
printf "@s1\nA\n+\n-\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --sizein &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastq_ascii should fail with fasta"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastq_ascii should fail with argument other than 33/64"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 72 &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## those 2 tests should fail because Qscores are outside 0-41 range specified by default
## see fastq_qmax
DESCRIPTION="--fastx_subsample --fastq_ascii fails when Qscore is outside specified range +64"
printf "@s1\nA\n+\nj\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 64 --sizein &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastq_ascii fails when Qscore is outside specified range +33"
printf "@s1\nA\n+\nK\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --sizein &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                --fastq_qmax                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastq_qmax is accepted"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --fastq_qmax 10 &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmax should fail if argument is negative"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --fastq_qmax -1 &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmax should fail if argument > 41"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --fastq_qmax 42 &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmax should fail with fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --fastq_qmax -1 &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmax rewrite Qscore capped (fastq_ascii 33)"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastqout "${OUTPUT}" \
		 --fastq_ascii 33 --fastq_qmax 0 &> /dev/null
[[ "${OUTPUT}" == "@s1\nA\n+\n!\n" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmax rewrite Qscore capped (fastq_ascii 64)"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\na\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastqout "${OUTPUT}" \
		 --fastq_ascii 64 --fastq_qmax 0 &> /dev/null
[[ "${OUTPUT}" == "@s1\nA\n+\n@\n" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                --fastq_qmin                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastq_qmin is accepted"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --fastq_qmin 10 &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmin should fail if argument is negative"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --fastq_qmin -1 &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmin should fail if argument > 41"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --fastq_qmin 42 &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmin should fail with fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastaout - \
		 --fastq_ascii 33 --fastq_qmin -1 &> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmin rewrite Qscore capped (fastq_ascii 33)"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\n-\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastqout "${OUTPUT}" \
		 --fastq_ascii 33 --fastq_qmin 0 &> /dev/null
[[ "${OUTPUT}" == "@s1\nA\n+\n!\n" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastq_qmin rewrite Qscore capped (fastq_ascii 64)"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\na\n" | \
    "${VSEARCH}" --fastx_subsample - --sample_size 1 --fastqout "${OUTPUT}" \
		 --fastq_ascii 64 --fastq_qmin 0 &> /dev/null
[[ "${OUTPUT}" == "@s1\nA\n+\n@\n" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                  --fastqout                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastqout is accepted"
printf "@s1\nA\n+\nG" | \
"${VSEARCH}" --fastx_subsample - --fastqout - --sample_size 1 &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout should fail with fasta"
printf ">s1\nA" | \
"${VSEARCH}" --fastx_subsample - --fastqout - --sample_size 1 &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout fill a file"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastqout output is correct"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" \
		 --sample_size 1 &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf "@s1\nA\n+\nG") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                             --fastqout_discarded                            #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --fastqout_discarded is accepted"
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastqout_discarded - \
		 --sample_size 1 --fastqout - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded should fail  with fasta"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout_discarded - \
		 --sample_size 1 --fastqout - &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --fastqout_discarded fill a file"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastqout - &> /dev/null
[[ -s "${OUTPUT}" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --fastqout_discarded display discarded sequences from the input"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout_discarded "${OUTPUT}" \
		 --sample_size 1 --fastqout - &> /dev/null
[[ $(cat "${OUTPUT}") == $(printf "@s1\nA\n+\nG\n") ]] || \
    [[ $(cat "${OUTPUT}") == $(printf "@s2\nA\n+\nG\n") ]] && \
	success  "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                              --fastx_subsample                              #
#                                                                             #
#*****************************************************************************#

## functionalities are tested through other options
DESCRIPTION="--fastx_subsample is accepted"
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sample_size 1 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                  --randseed                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --randseed is accepted"
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --randseed 0 --sample_size 1 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --randseed should fail whit negative arguments"
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --randseed -1 --sample_size 1 \
	&> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --randseed x produces constant output"
RANDSEED_OUTPUT=$("${VSEARCH}" --fastx_subsample "${FASTAx1000}" --randseed 666 \
			       --fastaout - --sample_size 1 2> /dev/null)
CLASSIC_OUTPUT=$("${VSEARCH}" --fastx_subsample "${FASTAx1000}" --randseed 666 \
			       --fastaout - --sample_size 1 2> /dev/null)
[[ "${RANDSEED_OUTPUT}" == "${CLASSIC_OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"s

DESCRIPTION="--fastx_subsample --randseed 0 produces different outputs (tiny chances of failure) (fasta)"
FIRST_OUTPUT=$("${VSEARCH}" --fastx_subsample "${FASTAx1000}" --randseed 0 \
			    --fastaout - --sample_size 5 2> /dev/null)
SECOND_OUTPUT=$("${VSEARCH}" --fastx_subsample "${FASTAx1000}" --randseed 0 \
			       --fastaout - --sample_size 5 2> /dev/null)
[[ "${FIRST_OUTPUT}" == "${SECOND_OUTPUT}" ]] && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"
rm "${FASTAx1000}"

DESCRIPTION="--fastx_subsample --randseed x produces constant output (fastq)"
RANDSEED_OUTPUT=$("${VSEARCH}" --fastx_subsample "${FASTQx1000}" --randseed 666 \
			       --fastaout - --sample_size 1 2> /dev/null)
CLASSIC_OUTPUT=$("${VSEARCH}" --fastx_subsample "${FASTQx1000}" --randseed 666 \
			       --fastaout - --sample_size 1 2> /dev/null)
[[ "${RANDSEED_OUTPUT}" == "${CLASSIC_OUTPUT}" ]] && \
    success "${DESCRIPTION}" || \
	failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --randseed 0 produces different outputs (tiny chances of failure) (fastq)"
FIRST_OUTPUT=$("${VSEARCH}" --fastx_subsample "${FASTQx1000}" --randseed 0 \
			    --fastaout - --sample_size 5 2> /dev/null)
SECOND_OUTPUT=$("${VSEARCH}" --fastx_subsample "${FASTQx1000}" --randseed 0 \
			       --fastaout - --sample_size 5 2> /dev/null)
[[ "${FIRST_OUTPUT}" == "${SECOND_OUTPUT}" ]] && \
    failure "${DESCRIPTION}" || \
	success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                 --relabel                                   #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --relabel is accepted"
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --randseed 0 --sample_size 1 \
	         --relabel 'lab' &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel produces correct outputs #1 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --relabel 'lab' \
		 --sample_size 1 &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == '>lab1' ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel produces correct outputs #2 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --relabel 'lab' \
		 --sample_size 2 &> /dev/null
[[ $(sed "3q;d" "${OUTPUT}") == '>lab2' ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel produces correct outputs #1 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --relabel 'lab' \
		 --sample_size 1 &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == '@lab1' ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel produces correct outputs #2 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --relabel 'lab' \
		 --sample_size 1 &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == '@lab1' ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

for OPTION in "--relabel_md5" "--relabel_sha1" ; do
    DESCRIPTION="--fastx_subsample --relabel should not be used with ${OPTION} fasta"
    "${VSEARCH}" --fastx_subsample <(printf ">a\nA\n") --relabel 'lab' ${OPTION} \
		 --fastaout - --sample_size 1&> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done

for OPTION in "--relabel_md5" "--relabel_sha1" ; do
    DESCRIPTION="--fastx_subsample --relabel should not be used with ${OPTION} fastq"
    "${VSEARCH}" --fastx_subsample <(printf "@a\nA\n+\n-") --relabel 'lab' ${OPTION} \
		 --fastaout - --sample_size 1 &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#                               --relabel_keep                                #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --relabel_keep is accepted"
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --randseed 0 --sample_size 1 \
		 --relabel 'lab' --relabel_keep &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_keep should fail if not used with anoter relabel option"
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --randseed 0 --sample_size 1 \
		 --relabel_keep &> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel produces correct outputs #1 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --relabel 'lab' \
		 --sample_size 1 --relabel_keep &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == '>lab1 s1' ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel produces correct outputs #2 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --relabel 'lab' \
		 --sample_size 2 --relabel_keep &> /dev/null
[[ $(sed "3q;d" "${OUTPUT}") == '>lab2 s2' ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel produces correct outputs #1 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --relabel 'lab' \
		 --sample_size 1 --relabel_keep &> /dev/null
[[ $(sed "1q;d" "${OUTPUT}") == '@lab1 s1' ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel produces correct outputs #2 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --relabel 'lab' \
		 --sample_size 2 --relabel_keep &> /dev/null
[[ $(sed "5q;d" "${OUTPUT}") == '@lab2 s2' ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       


#*****************************************************************************#
#                                                                             #
#                               --relabel_md5                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --relabel_md5 is accepted"
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --randseed 0 --sample_size 1 \
	         --relabel_md5 &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_md5 produces correct outputs #1 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --relabel_md5 \
		 --sample_size 1 &> /dev/null
[[ $(awk -F '>' 'NR==1 {print $2}' "${OUTPUT}") == \
   $(printf "A" | md5sum | awk '{printf $1}') ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel_md5 produces correct outputs #2 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --relabel_md5 \
		 --sample_size 2 &> /dev/null
[[ $(awk -F '>' 'NR==3 {print $2}' "${OUTPUT}") == \
   $(printf "C" | md5sum | awk '{printf $1}') ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel_md5 produces correct outputs #1 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --relabel_md5 \
		 --sample_size 1 &> /dev/null
[[ $(awk -F '@' 'NR==1 {print $2}' "${OUTPUT}") == \
   $(printf "A" | md5sum | awk '{printf $1}') ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --relabel_md5 produces correct outputs #2 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nC\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --relabel_md5 \
		 --sample_size 2 &> /dev/null
[[ $(awk -F '@' 'NR==5 {print $2}' "${OUTPUT}") == \
   $(printf "C" | md5sum | awk '{printf $1}') ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

for OPTION in "--relabel_sha1" "--relabel 'lab'"; do
    DESCRIPTION="--fastx_subsample --relabel_md5 should not be used with ${OPTION} fasta"
    "${VSEARCH}" --fastx_subsample <(printf ">a\nA\n")  "--relabel_md5" "${OPTION}" \
		 --fastaout - --sample_size 1&> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done

for OPTION in "--relabel_sha1" "--relabel 'lab'" ; do
    DESCRIPTION="--fastx_subsample --relabel_md5 should not be used with ${OPTION} fastq"
    "${VSEARCH}" --fastx_subsample <(printf "@a\nA\n+\n-") "--relabel_md5" ${OPTION} \
		 --fastaout - --sample_size 1 &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#                              --relabel_sha1                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --relabel_sha1 is accepted"
printf "@s1\nA\n+\nG" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --randseed 0 --sample_size 1 \
	         --relabel_sha1 &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --relabel_sha1 produces correct outputs #1 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --relabel_sha1 \
		 --sample_size 1 &> /dev/null
[[ $(awk -F '>' 'NR==1 {print $2}' "${OUTPUT}") == \
   $(printf "A" | sha1sum | awk '{printf $1}') ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel_sha1 produces correct outputs #2 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nC\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --relabel_sha1 \
		 --sample_size 2 &> /dev/null
[[ $(awk -F '>' 'NR==3 {print $2}' "${OUTPUT}") == \
   $(printf "C" | sha1sum | awk '{printf $1}') ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel_sha1 produces correct outputs #1 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --relabel_sha1 \
		 --sample_size 1 &> /dev/null
[[ $(awk -F '@' 'NR==1 {print $2}' "${OUTPUT}") == \
   $(printf "A" | sha1sum | awk '{printf $1}') ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

DESCRIPTION="--fastx_subsample --relabel_sha1 produces correct outputs #2 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nC\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --relabel_sha1 \
		 --sample_size 2 &> /dev/null
[[ $(awk -F '@' 'NR==5 {print $2}' "${OUTPUT}") == \
   $(printf "C" | sha1sum | awk '{printf $1}') ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"       

for OPTION in "--relabel_md5" "--relabel 'lab'"; do
    DESCRIPTION="--fastx_subsample --relabel_sha1 should not be used with ${OPTION} fasta"
    "${VSEARCH}" --fastx_subsample <(printf ">a\nA\n")  "--relabel_sha1" ${OPTION} \
		 --fastaout - --sample_size 1&> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done

for OPTION in "--relabel_md5" "--relabel 'lab'" ; do
    DESCRIPTION="--fastx_subsample --relabel_sha1 should not be used with ${OPTION} fastq"
    "${VSEARCH}" --fastx_subsample <(printf "@a\nA\n+\n-") "--relabel_sha1" ${OPTION} \
		 --fastaout - --sample_size 1 &> /dev/null && \
    failure "${DESCRIPTION}" || \
	    success "${DESCRIPTION}"
done

#*****************************************************************************#
#                                                                             #
#                               --sample_pct                                  #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --sample_pct is accepted with fasta"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sample_pct 50.00 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct produces correct results #1 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --sample_pct 100.00 \
	&> /dev/null
[[ $(cat "${OUTPUT}") == $(printf ">s1\nA\n>s2\nA\n") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --sample_pct produces correct results #2 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --sample_pct 50.00 \
       &> /dev/null
[[ $(echo $(wc -l < "${OUTPUT}")) == "2" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --sample_pct should fail with negative arguments"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sample_pct -2.0 \
	&> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct should fail with arguments > 100"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sample_pct 101.0 \
	&> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct is accepted with fastq"
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout - --sample_pct 50.00 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct produces correct results #1 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --sample_pct 100.00 \
	&> /dev/null
[[ $(cat "${OUTPUT}") == $(printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --sample_pct produces correct results #2 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --sample_pct 50.00 \
       &> /dev/null
[[ $(echo $(wc -l < "${OUTPUT}")) == "4" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --sample_pct should fail with negative arguments"
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout - --sample_pct -2.0 \
	&> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_pct should fail with arguments > 100"
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout - --sample_pct 101.0 \
	&> /dev/null && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                               --sample_size                                 #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --sample_size is accepted with fasta"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sample_size 1 \
&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size discard correct number of sequences #1 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --sample_size 1 \
	&> /dev/null
    [[ $(echo $(wc -l < "${OUTPUT}")) == "2" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --sample_size discard correct number of sequences #2 fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --sample_size 2 \
	&> /dev/null
    [[ $(echo $(wc -l < "${OUTPUT}")) == "4" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --sample_size should fail with negative arguments fasta"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sample_size -1 \
	&> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size should fail if argument is higher than the number of sequences fasta"
printf ">s1\nA\n>s2\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sample_size 3 \
	&> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size is accepted with fastq"
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sample_size 1 &> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size discard correct number of sequences #1 fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --sample_size 1 \
	&> /dev/null
    [[ $(echo $(wc -l < "${OUTPUT}")) == "4" ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --sample_size discard correct number of sequences #2 fastq"
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_size 2 \
        --fastqout - 2> /dev/null | \
    awk 'END {exit NR == 8 ? 0 : 1}' && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size should fail with negative arguments fastq"
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout - --sample_size -1 \
	&> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sample_size should fail if argument is higher than the number of sequences fastq"
printf "@s1\nA\n+\nG\n@s2\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout - --sample_size 3 \
	&> /dev/null && \
    failure  "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                            --sizein and sizeout                             #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --sizein is accepted with fasta"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sizein --sample_size 1 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sizeout is accepted with fasta"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --sizeout --sample_size 1 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sizein --sizeout write abundances fasta"
OUTPUT=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --sizein --sizeout \
                 --sample_size 1 &> /dev/null
    [[ $(cat "${OUTPUT}") == $(printf ">s1;size=1;\nA\n") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

DESCRIPTION="--fastx_subsample --sizein is accepted with fastq"
printf "@1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout - --sizein --sample_size 1 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sizeout is accepted with fastq"
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout - --sizeout --sample_size 1 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --sizein --sizeout write abundances fastq"
OUTPUT=$(mktemp)
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --sizein --sizeout \
                 --sample_size 1 &> /dev/null
    [[ $(cat "${OUTPUT}") == $(printf "@s1;size=1;\nA\n+\nG\n") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"


#*****************************************************************************#
#                                                                             #
#                                  --xsize                                    #
#                                                                             #
#*****************************************************************************#

DESCRIPTION="--fastx_subsample --xsize is accepted with fasta"
printf ">s1\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout - --xsize --sample_size 1 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --xsize strips abundance with fasta"
OUTPUT=$(mktemp)
printf ">s1;size=2;\nA\n" | \
    "${VSEARCH}" --fastx_subsample - --fastaout "${OUTPUT}" --xsize --sample_size 1 \
&> /dev/null
    [[ $(cat "${OUTPUT}") == $(printf ">s1\nA\n") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"
    
DESCRIPTION="--fastx_subsample --xsize is accepted with fastq"
printf "@s1\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout - --xsize --sample_size 1 \
	&> /dev/null && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="--fastx_subsample --xsize strips abundance with fasta"
OUTPUT=$(mktemp)
printf "@s1;size=1;\nA\n+\nG\n" | \
    "${VSEARCH}" --fastx_subsample - --fastqout "${OUTPUT}" --xsize --sample_size 1 \
&> /dev/null
    [[ $(cat "${OUTPUT}") == $(printf "@s1\nA\n+\nG\n") ]] && \
    success  "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${OUTPUT}"

rm "${FASTQx1000}"


#*****************************************************************************#
#                                                                             #
#                            behavioral tests                                 #
#                                                                             #
#*****************************************************************************#

## Percentage subsampling returns a predictable number of reads
##
## Here the number of reads in the input is 100 + 50 + 10 = 160, so
## there should always be 16 reads in the output
DESCRIPTION="--fastx_subsample returns a predictable total number of reads (--sample_pct)"
for i in {1..100} ; do
    printf ">s1;size=100;\nA\n>s2;size=50;\nC\n>s3;size=10;\nG\n" | \
        "${VSEARCH}" \
            --fastx_subsample - \
            --sizein \
            --sizeout \
            --sample_pct 10.0 \
            --fastaout - 2> /dev/null | \
        awk 'BEGIN {FS = "="} /^>/ {sum += $NF} END {exit sum == 16 ? 0 : 1}' || \
        failure "${DESCRIPTION}"
done && success "${DESCRIPTION}"


## read numbers per sequence converge towards an expected value
## (average other 100 repeats)
DESCRIPTION="--fastx_subsample returns predictable numbers of reads per sequence (--sample_pct)"
for i in {1..100} ; do
    printf ">s1;size=100;\nA\n>s2;size=50;\nC\n>s3;size=10;\nG\n" | \
        "${VSEARCH}" \
            --fastx_subsample - \
            --sizein \
            --sizeout \
            --sample_pct 10.0 \
            --fastaout - 2> /dev/null
done | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minseqlength 1 \
        --sizein \
        --sizeout \
        --output - 2> /dev/null | \
    awk 'BEGIN {FS = "="} /^>/ {printf "%.0f@", $NF / 100} END {printf "\n"}' | \
    grep -q "^10@5@1@$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


exit
