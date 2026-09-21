#!/bin/bash

## Launch all tests

## Declare a color code for the final verdict
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

## The run stops at the first failing test script (failure() exits, and
## so does this runner). Without a final verdict, a complete run and a
## run that died early -- wrong binary path, interrupted, killed --
## both end without printing a FAIL line, and cannot be told apart by
## the caller. Report the outcome in one greppable line, always.
CURRENT_SCRIPT=""
SCRIPT_NUMBER=0

# shellcheck disable=SC2329  # invoked indirectly, by the EXIT trap below
report_verdict () {
    local STATUS=$?
    if [[ "${STATUS}" -eq 0 ]] ; then
        printf "%bSUMMARY: OK - all %d test scripts completed%b\n" \
               "${GREEN}" "${SCRIPT_NUMBER}" "${NO_COLOR}"
    elif [[ -z "${CURRENT_SCRIPT}" ]] ; then
        printf "%bSUMMARY: ABORTED - no test script was started%b\n" \
               "${RED}" "${NO_COLOR}"
    else
        printf "%bSUMMARY: ABORTED - stopped in scripts/%s (test script number %d)%b\n" \
               "${RED}" "${CURRENT_SCRIPT}" "${SCRIPT_NUMBER}" "${NO_COLOR}"
    fi
    exit "${STATUS}"
}

trap report_verdict EXIT

run_test_script () {
    CURRENT_SCRIPT="${1}"
    SCRIPT_NUMBER=$(( SCRIPT_NUMBER + 1 ))
    bash "./scripts/${1}" "${2}" || exit 1
    echo
}

## command-specific tests
for test_script in vsearch.sh \
                       allpairs_global.sh \
                       chimeras_denovo.sh \
                       cluster_fast.sh \
                       cluster_size.sh \
                       cluster_smallmem.sh \
                       cluster_unoise.sh \
                       cut.sh \
                       derep_fulllength.sh \
                       derep_id.sh \
                       derep_prefix.sh \
                       derep_smallmem.sh \
                       fasta2fastq.sh \
                       fastq_chars.sh \
                       fastq_convert.sh \
                       fastq_eestats.sh \
                       fastq_eestats2.sh \
                       fastq_filter.sh \
                       fastq_join.sh \
                       fastx_filter.sh \
                       fastx_getseq.sh \
                       fastx_getseqs.sh \
                       fastx_getsubseq.sh \
                       fastq_mergepairs.sh \
                       fastq_stats.sh \
                       fastx_mask.sh \
                       fastx_revcomp.sh \
                       fastx_subsample.sh \
                       fastx_syncpairs.sh \
                       fastx_uniques.sh \
                       help.sh \
                       makeudb_usearch.sh \
                       maskfasta.sh \
                       orient.sh \
                       rereplicate.sh \
                       scramble.sh \
                       search_exact.sh \
                       search_global.sh \
                       sff_convert.sh \
                       shuffle.sh \
                       sintax.sh \
                       sortbylength.sh \
                       sortbysize.sh \
                       uchime_denovo.sh \
                       uchime2_denovo.sh \
                       uchime3_denovo.sh \
                       uchime_ref.sh \
                       udb2fasta.sh \
                       udbinfo.sh \
                       udbstats.sh \
                       usearch_global.sh \
                       version.sh ; do
    run_test_script "${test_script}" "${1}"
done

## non-specific tests
for test_script in fastq_parsing.sh \
                       fixed_bugs.sh \
                       google_forum_issues.sh \
                       test_accepted_chars.sh ; do
    run_test_script "${test_script}" "${1}"
done

exit 0
