#!/bin/bash -

## Print a header
SCRIPT_NAME="Fasta parsing"
line=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${line:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    # exit -1
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}

## Is vsearch installed?
VSEARCH=$(which vsearch)
DESCRIPTION="check if vsearch is in the PATH"
[[ "${VSEARCH}" ]] && success "${DESCRIPTION}" || failure "${DESCRIPTION}"

## Is usearch installed?
for USEARCH in usearch{5..9} ; do
    DESCRIPTION="check if ${USEARCH} is in the PATH"
    which "${USEARCH}" > /dev/null && \
        success "${DESCRIPTION}" || failure "${DESCRIPTION}"
done


#*****************************************************************************#
#                                                                             #
#               Fastq valid and invalid examples (Cocks, 2010)                #
#                                                                             #
#*****************************************************************************#

# --------------------------------------------------------------------- vsearch

## Return status should be zero (success)
find . -name "*.fastq" ! -name "error*" -print | \
    while read f ; do
        DESCRIPTION="vsearch: $(basename ${f}) is a valid file"
        "${VSEARCH}" --fastq_chars "${f}" &> /dev/null && \
            success  "${DESCRIPTION}" || \
                failure "${DESCRIPTION}"
    done

## Return status should be !zero (failure)
find . -name "error*.fastq" -print | \
    while read f ; do
        DESCRIPTION="vsearch: $(basename ${f}) is an invalid file"
        "${VSEARCH}" --fastq_chars "${f}" &> /dev/null && \
            failure "${DESCRIPTION}" || \
                success  "${DESCRIPTION}"
    done

# --------------------------------------------------------------- usearch (all)

for USEARCH in usearch{6..9} ; do
    ## Return status should be zero (success)
    find . -name "*.fastq" ! -name "error*" -print | \
        while read f ; do
            DESCRIPTION="${USEARCH}: $(basename ${f}) is a valid file"
            "${USEARCH}" -fastq_chars "${f}" &> /dev/null && \
                success  "${DESCRIPTION}" || \
                    failure "${DESCRIPTION}"
        done

    ## Return status should be !zero (failure)
    find . -name "error*.fastq" -print | \
        while read f ; do
            DESCRIPTION="${USEARCH}: $(basename ${f}) is an invalid file"
            "${USEARCH}" -fastq_chars "${f}" &> /dev/null && \
                failure "${DESCRIPTION}" || \
                    success  "${DESCRIPTION}"
        done
done
    
# # -------------------------------------------------------------------- usearch7

# ## Return status should be zero (success)
# find . -name "*.fastq" ! -name "error*" -print | \
#     while read f ; do
#         DESCRIPTION="usearch7: $(basename ${f}) is a valid file"
#         "${USEARCH7}" -fastq_chars "${f}" &> /dev/null && \
#             success  "${DESCRIPTION}" || \
#                 failure "${DESCRIPTION}"
#     done

# ## Return status should be !zero (failure)
# find . -name "error*.fastq" -print | \
#     while read f ; do
#         DESCRIPTION="usearch7: $(basename ${f}) is an invalid file"
#         "${USEARCH7}" -fastq_chars "${f}" &> /dev/null && \
#             failure "${DESCRIPTION}" || \
#                 success  "${DESCRIPTION}"
#     done

# # -------------------------------------------------------------------- usearch8

# ## Return status should be zero (success)
# find . -name "*.fastq" ! -name "error*" -print | \
#     while read f ; do
#         DESCRIPTION="usearch8: $(basename ${f}) is a valid file"
#         "${USEARCH8}" -fastq_chars "${f}" &> /dev/null && \
#             success  "${DESCRIPTION}" || \
#                 failure "${DESCRIPTION}"
#     done

# ## Return status should be !zero (failure)
# find . -name "error*.fastq" -print | \
#     while read f ; do
#         DESCRIPTION="usearch8: $(basename ${f}) is an invalid file"
#         "${USEARCH8}" -fastq_chars "${f}" &> /dev/null && \
#             failure "${DESCRIPTION}" || \
#                 success  "${DESCRIPTION}"
#     done

exit 0
