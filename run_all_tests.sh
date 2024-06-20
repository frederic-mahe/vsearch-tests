#!/bin/bash

## Launch all tests
for s in vsearch.sh \
             derep_fulllength.sh \
             derep_id.sh \
             derep_prefix.sh \
             fastq_parsing.sh \
             fastx_subsample.sh \
             fastx_uniques.sh \
             fixed_bugs.sh \
             help.sh \
             rereplicate.sh \
             shuffle.sh \
             sortbylength.sh \
             sortbysize.sh \
             test_accepted_chars.sh \
             version.sh ; do
    bash "./scripts/${s}" "${1}" || exit 1
    echo
done

exit 0
