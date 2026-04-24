#!/bin/bash

## Launch all tests

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
                       fastx_uniques.sh \
                       help.sh \
                       makeudb_usearch.sh \
                       maskfasta.sh \
                       rereplicate.sh \
                       search_exact.sh \
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
    bash "./scripts/${test_script}" "${1}" || exit 1
    echo
done

## non-specific tests
for test_script in fastq_parsing.sh \
                       fixed_bugs.sh \
                       test_accepted_chars.sh ; do
    bash "./scripts/${test_script}" "${1}" || exit 1
    echo
done

## slow tests
# bash ./scripts/orient.sh "${1}" || exit 1

exit 0
