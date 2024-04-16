# vsearch-tests

unit tests for [vsearch](https://github.com/torognes/vsearch).

The objective is to gather, organize and factorize all the scripts
written to test the behaviour, results or bugs of the multi-purpose
tool vsearch.

Tests are grouped by command (e.g., `vsearch --derep_fulllength`;
`vsearch --fastqchars`; `vsearch --shuffle`), which creates a certain
level of redundancy but clarifies the organisation of the
tests. Additional sets of tests can focus on input formats (fasta or
fastq), or output formats common to several commands. When applicable,
the behaviour of usearch is also tested (usearch 6 to 9).

To test a new version of vsearch, simply launch:
```sh
bash run_all_tests.sh
```
(bash version 4 or higher required)

## approach to test writing

Black-box tests for a given application can be written with three
user-categories in mind. A lambda user using only the main features,
sometimes mistakenly. An expert user expecting all features to behave
precisely as specified. A malicious user trying to derail the
execution of the application.

To emulate a lambda user, tests should verify that the main
application features behave as expected. A lambda user might also use
unexpected input data (empty, ill-formatted), or unexpected
combinations of parameters.

To emulate an expert user, tests should verify that the application
behaves exactly as specified in the documentation. Expert users might
also work with very large datasets. When possible tests should check
that the application has no unexpected limits (i.e. int32
overflow). Tests should also challenge conditions not covered by the
documentation (i.e. dark-corners). For example, for the application to
be integrated in a pipeline, it needs to handle empty input
gracefully.

Emulating a malicous user can be a bit more involved. As most security
issues for applications such as vsearch are memory-related, I'd
recommend to compile with sanitizers and to to run all tests, to run
tests with valgrind, and to use a fuzzer to generate unexpected
input. The rest is in the hands of the application developper (static
analysis).
