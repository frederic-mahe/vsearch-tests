#!/bin/bash

## Launch all tests
for s in fastq_parsing.sh \
             test_accepted_chars.sh \
             fixed_bugs.sh ; do
    bash "./scripts/${s}" "${1}" || exit 1
    echo
done

exit 0
