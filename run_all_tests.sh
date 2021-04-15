#!/bin/bash

## Launch all tests
for s in ./scripts/*.sh ; do
    bash "${s}" "${1}" || exit 1
    echo
done

exit 0
