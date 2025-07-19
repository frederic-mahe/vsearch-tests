#!/bin/bash

## Launch all tests

## command-specific tests
for test_script in vsearch.sh \
                       cut.sh \
                       derep_fulllength.sh \
                       derep_id.sh \
                       derep_prefix.sh \
                       derep_smallmem.sh \
                       fasta2fastq.sh \
                       fastq_chars.sh \
                       fastq_join.sh \
                       fastq_stats.sh \
                       fastx_subsample.sh \
                       fastx_uniques.sh \
                       help.sh \
                       rereplicate.sh \
                       sff_convert.sh \
                       shuffle.sh \
                       sortbylength.sh \
                       sortbysize.sh \
                       version.sh ; do
    bash "./scripts/${test_script}" "${1}" || exit 1
    echo
done

## non-specific tests: fastq tests, fixed bugs
for test_script in fastq_parsing.sh \
                       fixed_bugs.sh \
                       test_accepted_chars.sh ; do
    bash "./scripts/${test_script}" "${1}" || exit 1
    echo
done

## (preliminary) command-specific tests (valgrind)
for test_script in allpairs_global.sh \
                       cluster_fast.sh \
                       cluster_size.sh \
                       cluster_smallmem.sh \
                       cluster_unoise.sh \
                       fastx_getseq.sh \
                       fastx_getseqs.sh \
                       search_exact.sh \
                       usearch_global.sh ; do
    bash "./scripts/${test_script}" "${1}" || exit 1
    echo
done


exit 0
