#!/bin/bash

## Launch all tests
for s in derep_fulllength.sh \
             fastq_parsing.sh \
             fixed_bugs.sh \
             rereplicate.sh \
             shuffle.sh \
             sortbylength.sh \
             sortbysize.sh \
             test_accepted_chars.sh ; do
    bash "./scripts/${s}" "${1}" || exit 1
    echo
done

exit 0
