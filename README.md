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
