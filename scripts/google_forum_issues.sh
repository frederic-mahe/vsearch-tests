#!/bin/bash -
# shellcheck disable=SC2015

export LC_NUMERIC=C  # use US/EN decimal separator (.)

## Print a header
SCRIPT_NAME="Google forum issues"
LINE=$(printf "%76s\n" " " | tr " " "-")
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "%bFAIL%b: %s\n" "${RED}" "${NO_COLOR}" "${1}"
    exit 1
}

success () {
    printf "%bPASS%b: %s\n" "${GREEN}" "${NO_COLOR}" "${1}"
}

## use the first binary in $PATH by default, unless user wants
## to test another binary
VSEARCH=$(which vsearch 2> /dev/null)
[[ "${1}" ]] && VSEARCH="${1}"

DESCRIPTION="check if vsearch is executable"
[[ -x "${VSEARCH}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#                       vsearch Google forum issues                            #
#                                                                              #
#******************************************************************************#
##
## Tests derived from questions posted on the vsearch user forum:
## https://groups.google.com/g/vsearch-forum/
##
## Threads are listed in chronological order (oldest first). For each thread,
## a comment banner gives the title, author, date, and URL, followed by either
## a black-box test reproducing the reported behaviour, or a note explaining
## why the thread is not testable (external resource, third-party tool, pure
## usage advice, etc.).


#******************************************************************************#
#                                                                              #
#  VBLAST                                                                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/InekLKVdHVs
## Martin / Torbjørn Rognes 2015-02-19
## Q: Any plans for an open-source UBLAST alternative in vsearch?
## A: No plans at the time; feature-request discussion only.
## not testable: feature-request / roadmap discussion, no reproducible behaviour


#******************************************************************************#
#                                                                              #
#  vsearch --cluster_fast error                                                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/lIdALNJ_cFY
## Martin / Torbjørn Rognes 2015-04-02
## Q: cluster_fast on a .fastq fails ("Illegal header line in fasta file").
## A: In 2015 only FASTA was accepted; modern vsearch (2.31.0) now reads FASTQ.

# NOTE: behaviour changed since 2015 -- cluster_fast now accepts FASTQ input
# directly (sequence used 36 nt to clear the default minseqlength of 32)
DESCRIPTION="forum (2015-04-02): cluster_fast accepts fastq input"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --centroids /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Database size                                                               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/zOH4A0K8sQ8
## Michael Tangherlini / Torbjørn Rognes 2015-04-02
## Q: How much RAM/CPU does usearch_global need for a 70 GB database?
## A: Roughly the input file size plus overhead; a sizing rule, not a behaviour.
## not testable: hardware sizing advice, no reproducible small-input behaviour


#******************************************************************************#
#                                                                              #
#  extra otus in a mock community                                              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/TzLM3BQIL2c
## Alma / Frédéric Mahé 2015-04-08
## Q: Mock-community OTUs assigned to unexpected taxa / abundances.
## A: Assignment issue tied to uclust-like clustering limits; no command given.
## not testable: data-/method-interpretation discussion, no command or repro


#******************************************************************************#
#                                                                              #
#  Problem in reducing NCBI nt                                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/EvrnxwylE10
## user / Torbjørn Rognes 2015-04-10
## Q: NCBI nt fails with "illegal unprintable character 0x01" in headers/seq.
## A: Buffer enlarged in v1.0.12+; control characters in sequence are rejected.

# the 0x01 (Ctrl-A) byte that appears in NCBI nt is rejected when it occurs
# in a sequence line (message wording updated since 2015)
DESCRIPTION="forum (2015-04-10): unprintable ASCII character 0x01 in fasta is rejected"
printf ">s1\nAC\001GT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --centroids /dev/null 2>&1 | \
    grep -qi "Illegal sequence character (unprintable, no 1)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Illegal instruction error on Mac OS X 10.6.8                                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/CZx0y3X4s1o
## Valerie / Torbjørn Rognes 2015-04-11
## Q: "Illegal instruction" running binary; x86intrin.h missing on build.
## A: OS too old; upgrading to OS X 10.10 fixed it.
## not testable: build/install/hardware compatibility, no vsearch behaviour


#******************************************************************************#
#                                                                              #
#  cluster_fast speed                                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/FI_tl_UHMSY
## Jason Sahl / Rognes & Mahé 2015-04-16
## Q: Why is vsearch cluster_fast slower than usearch at id 0.90?
## A: Algorithmic/data-dependent performance difference; not a malfunction.
## not testable: performance expectation, no deterministic small-input assertion


#******************************************************************************#
#                                                                              #
#  Making OTU tables                                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/uM8cBTlDfXA
## David Clark / Torbjørn Rognes 2015-07-10
## Q: Does vsearch build OTU tables directly from search output?
## A: (2015) No; use external uc2otutab.py. (Modern vsearch has --otutabout.)
## not testable as worded: 2015 answer points to an external script; the modern
## --otutabout feature is covered by the usearch_global / per-command tests


#******************************************************************************#
#                                                                              #
#  Missing output in uchime_denovo mode                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/GjkTFtYaIvU
## user / Torbjørn Rognes 2015-07-28
## Q: chimeras + nonchimeras don't sum to the input count; some are missing.
## A: "suspicious" borderline seqs ('?'); --uchimeout last column is Y/N/?.

# the uchimeout report row has a fixed 18 columns and its final column is the
# classification flag, taking only Y (chimera), N (non-chimera) or ? (suspicious)
DESCRIPTION="forum (2015-07-28): uchimeout report has 18 columns ending in a Y/N/? flag"
printf ">pa;size=50\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>pb;size=50\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --uchimeout /dev/stdout \
        --quiet 2> /dev/null | \
    awk -F'\t' '{ if (NF == 18 && $NF ~ /^[YN?]$/) ok++; else bad++ } END { exit (bad > 0 || ok == 0) }' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  minor issue with -cluster_smallmem option                                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/VMLVxYoyTvs
## Kirk B / Torbjørn Rognes 2015-08-08
## Q: cluster_smallmem with --output gives "no output file specified".
## A: Clustering commands don't take --output; use --centroids/--uc/etc.

# --output is not a valid option for the clustering commands
DESCRIPTION="forum (2015-08-08): cluster_smallmem rejects --output"
printf ">s1\nACGT\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --id 0.97 \
        --output /dev/null 2>&1 | \
    grep -qx "Invalid option(s): --output" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  vsearch problem with searching step (convert .uc to .txt)                   #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/_q9lQGUlryI
## Maria G / Torbjørn Rognes 2015-08-18
## Q: Samples missing/mislabeled after converting .uc to .txt with a script.
## A: Likely the third-party uc2otutab_mod.py script; root cause undetermined.
## not testable: issue is in an external QIIME-community conversion script


#******************************************************************************#
#                                                                              #
#  Header info in SAM output                                                   #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/4iviPHoz0_U
## Laura / Torbjørn Rognes 2015-09-15
## Q: Can vsearch write SAM headers (SAMtools needs them)?
## A: --samheader option added (v1.3.3+); adds @HD/@SQ/@PG header lines.

# --samheader prepends SAM header lines (@HD ...) to --samout
DESCRIPTION="forum (2015-09-15): --samheader adds @HD line to SAM output"
DB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout /dev/stdout \
        --samheader \
        --quiet 2> /dev/null | \
    grep -q "^@HD	VN:" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"

# without --samheader no @-prefixed header lines are emitted
DESCRIPTION="forum (2015-09-15): without --samheader no @ header lines in SAM output"
DB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --samout /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qv "^@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"


#******************************************************************************#
#                                                                              #
#  Basic question about the usage of vsearch                                   #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/yf3lCMT16-Y
## Ahmed Abdelfattah / Frédéric Mahé 2015-09-23
## Q: usearch_global only gave one output; how to get chimeras/nonchimeras?
## A: Use --uchime_ref (not usearch_global) for reference-based chimera detection.

# usearch_global is not the chimera-detection command: --chimeras /
# --nonchimeras are not valid options for it
DESCRIPTION="forum (2015-09-23): usearch_global rejects --chimeras (use uchime_ref)"
DB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --chimeras /dev/null 2>&1 | \
    grep -qx "Invalid option(s): --chimeras" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"


#******************************************************************************#
#                                                                              #
#  mapping seqs back to OTUs in vsearch                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/G2nlF4cbOk4
## 2015-10-21
## Q: Does vsearch have a usearch_global equivalent for mapping reads to OTUs?
## A: Yes; same --usearch_global/--db/--id/--strand/--uc options as usearch.

## a query that matches nothing in the database is reported in the .uc
## file as an N (no hit) record, not silently dropped
DESCRIPTION="forum (2015-10-21): usearch_global writes an N record for a non-matching query"
DB=$(mktemp)
printf ">ref1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" > "${DB}"
printf ">q1\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db "${DB}" \
        --id 0.97 \
        --strand plus \
        --uc /dev/stdout \
        --quiet 2> /dev/null | \
    grep -q "^N	" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB DESCRIPTION


#******************************************************************************#
#                                                                              #
#  using vsearch-1.8.0 in qiime                                                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Q4Q2-pbqFpc
## 2015-11-13
## Q: vsearch (via QIIME) rejected --threads 0.5; also many short seqs lost.
## A: 1.8.1 accepts floating-point --threads; short seqs dropped by minseqlength 32.

## QIIME passed a fractional thread count; vsearch accepts a floating-point
## value for --threads (the fix released in 1.8.1)
DESCRIPTION="forum (2015-11-13): --threads accepts a floating-point value (0.5)"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --threads 0.5 \
        --output /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

## sequences shorter than the default minseqlength (32) are discarded,
## with a warning on stderr (the cause of the user's "missing" reads)
DESCRIPTION="forum (2015-11-13): sequences shorter than default minseqlength (32) are discarded with a warning"
printf ">short\nACGT\n>long\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --output /dev/null 2>&1 | \
    grep -q "minseqlength 32: 1 sequence discarded." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  vsearch-1.1.3-osx command not found after installation                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/mkkCsqPyijI
## 2016-01-03
## Q: "command not found" running the vsearch binary on macOS.
## A: chmod u+x the binary / add it to PATH — a shell/permissions issue.
## not testable: installation/permissions/PATH issue, not a vsearch behaviour


#******************************************************************************#
#                                                                              #
#  Default Action for Non-Matching Sequences                                   #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/nkR8Arx29cA
## 2016-01-13
## Q: Are non-matching sequences kept in the .uc file or discarded?
## A: They are kept; singletons get their own S (seed) record.

## two dissimilar sequences do not cluster together; each becomes its own
## singleton, written as a separate S record in the .uc file
DESCRIPTION="forum (2016-01-13): non-matching sequences appear as singleton S-records in the .uc file"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGTAAAA\n>b\nTGCATGCATGCATGCATGCATGCATGCATGCATCCC\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --uc /dev/stdout \
        --quiet 2> /dev/null | \
    grep -c "^S	" | grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  upper case results                                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/rQmAt2lo81c
## 2016-01-14
## Q: Why does vsearch uppercase sequences, losing case-encoded information?
## A: Bug fixed in 1.9.7; with masking off, the original case is preserved.

## with --qmask none, lowercase input is preserved verbatim in the
## --msaout aligned sequences (it is not forced to uppercase)
DESCRIPTION="forum (2016-01-14): --qmask none preserves lowercase input in the --msaout output"
printf ">s1\nacgtacgtacgtacgtacgtacgtacgtacgtacgt\n>s2\nacgtacgtacgtacgtacgtacgtacgtacgtacgt\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.97 \
        --qmask none \
        --msaout /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx "acgtacgtacgtacgtacgtacgtacgtacgtacgt" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Dereplication algorithm                                                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/nl6z67aBbZE
## 2016-02-09
## Q: Does derep_prefix allow mismatches in the prefix / set a %id?
## A: No; derep_prefix allows no mismatches at all. Use clustering for that.

## an exact prefix is merged into the longer sequence (size accumulates)
DESCRIPTION="forum (2016-02-09): derep_prefix merges an exact prefix (no mismatch allowed)"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGTAAAACCCC\n>b\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --derep_prefix - \
        --output /dev/stdout \
        --sizeout \
        --quiet 2> /dev/null | \
    grep -qx ">a;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

## a single mismatch in the prefix prevents merging (no mismatch tolerated):
## the longer sequence stays a singleton
DESCRIPTION="forum (2016-02-09): derep_prefix does not merge a prefix containing a mismatch"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGTAAAACCCC\n>b\nTCGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --derep_prefix - \
        --output /dev/stdout \
        --sizeout \
        --quiet 2> /dev/null | \
    grep -qx ">a;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  chimera detection on unusually long reads                                   #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/xMVk36TfuWk
## 2016-02-09
## Q: What parameters for chimera detection on 1100-1400 bp assembled reads?
## A: No tested recipe; try uchime_ref and inspect alignments — usage advice.
## not testable: open-ended parameter/usage advice, no defined behaviour to pin


#******************************************************************************#
#                                                                              #
#  suggestion for chimera reporting                                            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/2jnRkcXXzn0
## 2016-02-12
## Q: Report chimera counts weighted by abundance, not just unique sequences.
## A: Implemented in 1.10.0; the summary now adds an abundance-weighted line.

## the chimera summary now reports a second, abundance-weighted line in
## addition to the unique-sequence counts
DESCRIPTION="forum (2016-02-12): uchime_denovo reports total (abundance-weighted) chimera counts"
A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"
B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
A_END=$(rev <<< "${A_START}")
B_END=$(rev <<< "${B_START}")
PARENT_A="${A_START}${A_END}"
PARENT_B="${B_START}${B_END}"
CHIMERA_AB="${A_START}${B_END}"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=5\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --chimeras /dev/null 2>&1 > /dev/null | \
    grep -q "Taking abundance information into account" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

## the abundance-weighted total equals the sum of all size annotations
## (50 + 49 + 5 = 104)
DESCRIPTION="forum (2016-02-12): uchime_denovo total count equals the sum of all sizes (104)"
printf ">parentA;size=50\n%s\n>parentB;size=49\n%s\n>chimeraAB;size=5\n%s\n" \
    "${PARENT_A}" "${PARENT_B}" "${CHIMERA_AB}" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --chimeras /dev/null 2>&1 > /dev/null | \
    grep -q "in 104 total sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset A_START B_START A_END B_END PARENT_A PARENT_B CHIMERA_AB DESCRIPTION


#******************************************************************************#
#                                                                              #
#  which is the best cms tool for transaction purpose                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/A8XjAVJk-t8
## 2016-02-15
## Q: (spam)
## A: (spam)
## not testable: spam thread, unrelated to vsearch


#******************************************************************************#
#                                                                              #
#  PER_SAMPLE option for subsampling                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/roo9MIkN7Dw
## 2016-02-22
## Q: How to subsample the same number of reads per sample?
## A: No per-sample option; split per sample and run --fastx_subsample each.

## --fastx_subsample --sample_size keeps exactly the requested number of
## sequences (here 2 of 3), the per-file building block of the workaround
DESCRIPTION="forum (2016-02-22): --fastx_subsample --sample_size keeps exactly that many sequences"
printf ">a\nAAAA\n>b\nCCCC\n>c\nGGGG\n" | \
    ${VSEARCH} \
        --fastx_subsample - \
        --sample_size 2 \
        --fastaout /dev/stdout \
        --quiet 2> /dev/null | \
    grep -c "^>" | grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Is it able to compile a binary for Windows?                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/vsr5adSPCP0
## 2016-02-22
## Q: Can vsearch be compiled for Windows?
## A: Not a priority; compile under Cygwin — a build/platform question.
## not testable: build/platform question, no runtime behaviour to pin


#******************************************************************************#
#                                                                              #
#  fastq_mergepairs and barcode labels                                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/PTaSJ0aE1GY
## 2016-02-23
## Q: Can fastq_mergepairs keep barcode labels in the merged header?
## A: Fixed in 1.10.1; the full header (incl. barcode) is retained by default.

## the full read header, including the barcode field after the first space,
## is retained on the merged read (no --notrunclabels needed)
DESCRIPTION="forum (2016-02-23): fastq_mergepairs retains the full read header (barcode after the first space)"
FWD_FQ=$(mktemp)
REV_FQ=$(mktemp)
printf "@r1 barcode=ACGTACGT\nTCCAGCTCCAATAGCGTATACTAAAGTTGTTGCCGTTGTTGAAAT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${FWD_FQ}"
printf "@r1 barcode=ACGTACGT\nGAGGTTATCGCATATGATTTCAACAACGGCAACAACTTTAGTATA\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${REV_FQ}"
${VSEARCH} \
    --fastq_mergepairs "${FWD_FQ}" \
    --reverse "${REV_FQ}" \
    --fastqout /dev/stdout \
    --quiet 2> /dev/null | \
    grep -qx "@r1 barcode=ACGTACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FWD_FQ}" "${REV_FQ}"
unset FWD_FQ REV_FQ DESCRIPTION


#******************************************************************************#
#                                                                              #
#  no chimeras detected with --uchime_ref --uchime_denovo                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/dZsBbU1h_Pw
## 2016-02-24
## Q: 0 chimeras found (ref + de novo) where usearch found thousands.
## A: de novo needs prior dereplication (--sizeout); ref bug on lowercase DB fixed in 1.9.10.

## de novo chimera detection requires abundance information: dereplicate
## with --sizeout first, then uchime_denovo detects the chimera (c1)
DESCRIPTION="forum (2016-02-24): de novo chimera detection works after dereplication with --sizeout"
A_START="TCCAGCTCCAATAGCGTATACTAAAGTTGTTGC"
B_START="AGTTCATGGGCAGGGGCTCCCCGTCATTTACTG"
A_END=$(rev <<< "${A_START}")
B_END=$(rev <<< "${B_START}")
PARENT_A="${A_START}${A_END}"
PARENT_B="${B_START}${B_END}"
CHIMERA_AB="${A_START}${B_END}"
{
  printf ">a1\n%s\n>a2\n%s\n>a3\n%s\n>a4\n%s\n>a5\n%s\n" \
      "${PARENT_A}" "${PARENT_A}" "${PARENT_A}" "${PARENT_A}" "${PARENT_A}"
  printf ">b1\n%s\n>b2\n%s\n>b3\n%s\n>b4\n%s\n" \
      "${PARENT_B}" "${PARENT_B}" "${PARENT_B}" "${PARENT_B}"
  printf ">c1\n%s\n" "${CHIMERA_AB}"
} | \
    ${VSEARCH} \
        --derep_fulllength - \
        --sizeout \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
    ${VSEARCH} \
        --uchime_denovo - \
        --chimeras /dev/stdout \
        --quiet 2> /dev/null | \
    grep -q "^>c1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

## a lowercase reference database no longer prevents detection: the chimera
## is still found against an all-lowercase --db (the 1.9.10 fix)
DESCRIPTION="forum (2016-02-24): uchime_ref detects a chimera against a lowercase reference database"
DB=$(mktemp)
printf ">parentA\n%s\n>parentB\n%s\n" "${PARENT_A}" "${PARENT_B}" | \
    tr 'ACGT' 'acgt' > "${DB}"
printf ">chim\n%s\n" "${CHIMERA_AB}" | \
    ${VSEARCH} \
        --uchime_ref - \
        --db "${DB}" \
        --chimeras /dev/stdout \
        --quiet 2> /dev/null | \
    grep -q "^>chim" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"
unset DB A_START B_START A_END B_END PARENT_A PARENT_B CHIMERA_AB DESCRIPTION


#******************************************************************************#
#                                                                              #
#  VSEARCH general question                                                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/lcqtMECJybM
## 2016-03-09
## Q: Is vsearch suitable for cluster computing and how to set thread count?
## A: No MPI/inter-node support; use --threads N (defaults to detected cores).
## not testable: usage/hardware advice; no reproducible behaviour beyond the
##               generic --threads option (already covered by per-command tests).


#******************************************************************************#
#                                                                              #
#  Pipeline for 16s OTU analysis                                              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/fd8MWsAuuDA
## 2016-03-20
## Q: Is my derep/sortbysize/usearch_global 16S OTU pipeline correct?
## A: Pipeline is sound; trim reference with same primers; consider swarm/cutadapt.
## not testable: pure pipeline-design advice, points to external tools.


#******************************************************************************#
#                                                                              #
#  Incomplete dereplicaiton issue                                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/8BXQGhAL5VE
## 2016-03-28
## Q: After derep, allpairs_global --id 1 still reports 100% identical matches.
## A: Terminal gaps are ignored by default, so a prefix matching a longer
##    sequence is reported as 100% identity even though they are not identical.

# a short sequence that is a prefix of a longer one is reported as 100%
# identity because terminal gaps are ignored by default
DESCRIPTION="forum (2016-03-28): allpairs_global ignores terminal gaps, reports 100% id for prefix"
printf ">s1\nACGTACGT\n>s2\nACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --id 1.0 \
        --acceptall \
        --quiet \
        --userfields id \
        --userout - 2> /dev/null | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Making OTU table                                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/83tCXeQ1mEw
## 2016-04-02
## Q: Can vsearch emit an OTU table directly via --userout/--userfields?
## A: No direct OTU-table output; use uc2otutab.py or post-process the uc file.
## not testable: feature-request / external-script advice; no reproducible
##               vsearch behaviour to pin down.


#******************************************************************************#
#                                                                              #
#  heuristics cluster_smallmem and usearch_global                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/2H4re5LGAxs
## 2016-04-07
## Q: Is it OK to cluster then map back using maxaccepts/maxrejects heuristics?
## A: (unanswered) — methodological concern about heuristic suboptimal hits.
## not testable: unanswered methodology question; no defined behaviour to assert.


#******************************************************************************#
#                                                                              #
#  derep_fulllength strand annotation                                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/7N7r8odTT2I
## 2016-04-13
## Q: derep_fulllength --strand both writes '*' in uc column 5 (no strand).
## A: Fixed in v1.11.1: uc files now follow usearch v8; hits get '+' or '-'.

# with --strand both, a hit matching the seed on the same strand is annotated
# with '+' in column 5 of the uc file
DESCRIPTION="forum (2016-04-13): derep_fulllength --strand both reports plus strand in uc column 5"
printf ">s1\nAAGGCCTTACGTACGTAAGGCCTTACGTACGT\n>s2\nAAGGCCTTACGTACGTAAGGCCTTACGTACGT\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --strand both \
        --quiet \
        --uc - 2> /dev/null | \
    awk '$1 == "H" {print $5}' | \
    grep -qx "+" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# with --strand both, a hit that is the reverse-complement of the seed is
# annotated with '-' in column 5 of the uc file (s2 is revcomp of s1)
DESCRIPTION="forum (2016-04-13): derep_fulllength --strand both reports minus strand for reverse-complement match"
printf ">s1\nAAGGCCTTACGTACGTAAGGCCTTACGTACGT\n>s2\nACGTACGTAAGGCCTTACGTACGTAAGGCCTT\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --strand both \
        --quiet \
        --uc - 2> /dev/null | \
    awk '$1 == "H" && $5 == "-" { found = 1 } END { exit (found ? 0 : 1) }' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Error in trying to DL                                                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/T48f7T1jp10
## 2016-04-13
## Q: wget download gives 404 Not Found.
## A: Placeholder vx.y.z was not replaced with a real version number.
## not testable: download/install issue, unrelated to vsearch behaviour.


#******************************************************************************#
#                                                                              #
#  Re: Evalue of -1 ??                                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/-SSBDKFR35E
## 2016-04-27
## Q: Why does vsearch report an e-value of -1?
## A: E-values are not computed for nucleotide alignments; always set to -1.

# the evalue userfield is always -1 for nucleotide alignments because it is
# not computed (still true in current versions)
DESCRIPTION="forum (2016-04-27): evalue is -1 for nucleotide alignments (not computed)"
DB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --quiet \
        --userfields evalue \
        --userout - 2> /dev/null | \
    grep -qx -- "-1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"


#******************************************************************************#
#                                                                              #
#  Full header in usearch mode ?                                              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Vg87LYP8GZM
## 2016-05-01
## Q: How to keep the complete header (not the truncated id) in usearch_global?
## A: Use --notrunclabels to keep the full header (no truncation at space/tab).

# by default the target label is truncated at the first space
DESCRIPTION="forum (2016-05-01): usearch_global truncates target header at first space by default"
DB=$(mktemp)
printf ">t1 full target description\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --quiet \
        --userfields target \
        --userout - 2> /dev/null | \
    grep -qx "t1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"

# --notrunclabels keeps the full target header in the output
DESCRIPTION="forum (2016-05-01): usearch_global --notrunclabels keeps full target header in output"
DB=$(mktemp)
printf ">t1 full target description\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --notrunclabels \
        --quiet \
        --userfields target \
        --userout - 2> /dev/null | \
    grep -qx "t1 full target description" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"


#******************************************************************************#
#                                                                              #
#  cluster_fast for amino acids?                                              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/z81rxTxmNbY
## 2016-05-09
## Q: Can cluster_fast be used on amino-acid sequences?
## A: vsearch only handles nucleotides; amino-acid letters are stripped as
##    invalid characters (with a WARNING).

# amino-acid-only letters (E F I L P Q X) are not valid nucleotides and are
# stripped, triggering an 'invalid characters stripped' warning on stderr
DESCRIPTION="forum (2016-05-09): amino-acid letters trigger 'invalid characters stripped' warning"
printf ">s1\nEFILPQX\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --output /dev/null 2>&1 | \
    grep -q "invalid characters stripped" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  stampa input?                                                              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/dTg-P3XOa38
## 2016-05-20
## Q: Is there a worked example for the stampa taxonomic-assignment script?
## A: (unanswered) — concerns the external stampa.sh wrapper, not vsearch.
## not testable: external-tool documentation request; no vsearch behaviour.


#******************************************************************************#
#                                                                              #
#  -fastq_filter outputs                                                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/ENvTJEmmGWE
## 2016-05-26
## Q: Can fastq_filter produce both FASTQ and FASTA output at once?
## A: Yes — supply both --fastqout and --fastaout in the same run.

# fastq_filter can write a FASTA and a FASTQ output simultaneously in a single
# run; both files receive the (filtered) record
DESCRIPTION="forum (2016-05-26): fastq_filter writes both --fastaout and --fastqout in one run"
FASTA=$(mktemp)
FASTQ=$(mktemp)
printf "@s1\nACGTACGT\n+\nIIIIIIII\n" | \
    ${VSEARCH} \
        --fastq_filter - \
        --fastaout "${FASTA}" \
        --fastqout "${FASTQ}" \
        --quiet 2> /dev/null
grep -qx ">s1" "${FASTA}" && grep -qx "@s1" "${FASTQ}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FASTA}" "${FASTQ}"


#******************************************************************************#
#                                                                              #
#  fastq_stats                                                                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/eHHtaRy8pbs
## 2016-05-27
## Q: Can fastq_stats report quality-score quantiles (like FASTX)?
## A: Use fastq_eestats — it reports per-position min/lower-quartile/median/
##    mean/upper-quartile/max quality scores.

# fastq_eestats reports per-position quality quantiles: its header carries the
# lower-quartile (Low_Q), median (Med_Q) and upper-quartile (Hi_Q) columns
DESCRIPTION="forum (2016-05-27): fastq_eestats header includes lower-quartile, median, upper-quartile quality columns"
printf "@s1\nACGT\n+\nIIII\n@s2\nACGT\n+\nABCD\n@s3\nACGT\n+\n5678\n" | \
    ${VSEARCH} \
        --fastq_eestats - \
        --output - \
        --quiet 2> /dev/null | \
    awk 'NR == 1 { ok = (index($0, "Low_Q") > 0) && (index($0, "Med_Q") > 0) && (index($0, "Hi_Q") > 0) } END { exit (ok ? 0 : 1) }' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  vsearch --usearch_global question                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/gXE6aYohWGM
## 2016-05-30
## Q: How does --fastapairs format its output, and are unmatched queries excluded?
## A: --fastapairs emits each matching query followed by its db target, then a blank line.

# the --fastapairs output for a matched query is the query record
# immediately followed by the matching database record (then a blank line)
DESCRIPTION="forum (2016-05-30): fastapairs emits query then its matching db sequence"
DB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --quiet \
        --fastapairs /dev/stdout 2> /dev/null | \
    tr '\n' '@' | \
    grep -q "^>q1@.*@>t1@" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"


#******************************************************************************#
#                                                                              #
#  Different sequence length statistic?                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/uAF5zd9J-7M
## 2016-05-30
## Q: How to get a sequence length distribution (not per-base stats)?
## A: --fastq_stats reports a "Read length distribution" section in its log.

# fastq_stats writes a read length distribution table to the log file
DESCRIPTION="forum (2016-05-30): fastq_stats log reports a read length distribution"
STATS_LOG=$(mktemp)
printf "@s1\nACGTACGT\n+\nIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_stats - \
        --quiet \
        --log "${STATS_LOG}" 2> /dev/null
grep -qi "Read length distribution" "${STATS_LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${STATS_LOG}"
unset STATS_LOG


#******************************************************************************#
#                                                                              #
#  filter sequences after maximum length                                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/_UUzTU7M_co
## 2016-05-31
## Q: How to discard (not truncate) reads longer than a given length? --maxseqlength did nothing.
## A: --maxseqlength does not apply to fastq_filter; use --fastq_minlen N+1 with --fastqout_discarded.

# --maxseqlength is not a valid option for fastq_filter (rejected at parse time)
DESCRIPTION="forum (2016-05-31): fastq_filter rejects --maxseqlength as an invalid option"
printf "@s1\nACGTACGTAC\n+\nIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --maxseqlength 5 \
        --fastqout /dev/stdout \
        --quiet 2>&1 | \
    grep -qF "Invalid option(s): --maxseqlength" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# workaround: --fastq_minlen 401 sends reads shorter than 401 (i.e. <=400)
# to --fastqout_discarded, which is the set the user wants to keep
DESCRIPTION="forum (2016-05-31): fastq_minlen + fastqout_discarded keeps short, drops long reads"
LONG_FQ=$(mktemp)
printf "@short\nACGTACGTAC\n+\nIIIIIIIIII\n" > "${LONG_FQ}"
printf "@long\n%s\n+\n%s\n" \
    "$(printf 'A%.0s' $(seq 1 401))" \
    "$(printf 'I%.0s' $(seq 1 401))" >> "${LONG_FQ}"
"${VSEARCH}" \
    --fastq_filter "${LONG_FQ}" \
    --fastq_minlen 401 \
    --fastqout_discarded /dev/stdout \
    --quiet 2> /dev/null | \
    grep '^@' | \
    tr '\n' ' ' | \
    grep -qx "@short " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${LONG_FQ}"
unset LONG_FQ


#******************************************************************************#
#                                                                              #
#  Chimera checking and OTU picking speed                                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/3_o0UDRQKyg
## 2016-06-16
## Q: How to speed up --chimera_denovo and reduce memory during clustering?
## A: Usage/performance advice (cluster first, drop singletons, RAM sizing).
## not testable: performance/memory tuning advice, no specific reproducible behaviour.


#******************************************************************************#
#                                                                              #
#  using vsearch as library                                                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/ZfFHfINMe7A
## 2016-06-23
## Q: Can vsearch be used as a C/C++ library to call clustering functions?
## A: No; but pipes (/dev/stdin, /dev/stdout) are being added to avoid temp files.
## not testable: concerns library/embedding use, not a command behaviour.


#******************************************************************************#
#                                                                              #
#  Looking for paper to explain pipeline                                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/lyne-qlqJD8
## 2016-07-30
## Q: Recommendations for papers explaining a microbiome pipeline?
## A: (none / external literature request).
## not testable: request for reading material, no vsearch behaviour involved.


#******************************************************************************#
#                                                                              #
#  what's fsa file                                                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/tW_2VmfM4wE
## 2016-07-30
## Q: What is a .fsa file -- fasta or fastq?
## A: .fsa files are usually fasta files.
## not testable: file-extension naming convention, not a vsearch behaviour (vsearch ignores extensions).


#******************************************************************************#
#                                                                              #
#  Opening up the wordlength restriction                                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/CIL6itQ4xL4
## 2016-08-03
## Q: Can --wordlength accept values below 7 (e.g. 4 or 5) for very small sequences?
## A: Request accepted; current vsearch allows --wordlength in the range 3 to 15.

# the old 7-12 restriction was opened up: small values down to 3 are now accepted
DESCRIPTION="forum (2016-08-03): wordlength 3 is accepted (below the old minimum of 7)"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --wordlength 3 \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# the lower boundary is enforced: 2 is rejected
DESCRIPTION="forum (2016-08-03): wordlength 2 is rejected (range is 3 to 15)"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --wordlength 2 \
        --centroids /dev/null \
        --quiet 2>&1 | \
    grep -qF "must be in the range 3 to 15" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# the upper boundary is enforced: 16 is rejected
DESCRIPTION="forum (2016-08-03): wordlength 16 is rejected (range is 3 to 15)"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --wordlength 16 \
        --centroids /dev/null \
        --quiet 2>&1 | \
    grep -qF "must be in the range 3 to 15" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  v1.10.1_linux: no output: user says there should be                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Z58q7n6bKDQ
## 2016-08-04
## Q: usearch_global reports 0 matches though matches should exist.
## A: An over-restrictive --mincols suppressed all hits; removing it restored matches.

# a query/target that match normally (H record) become a no-hit (N record)
# when --mincols demands more aligned columns than the alignment provides
DESCRIPTION="forum (2016-08-04): an over-high --mincols turns a hit into a no-hit"
DB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
[ "$(printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --quiet \
        --uc /dev/stdout 2> /dev/null | cut -f1)" = "H" ] && \
[ "$(printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --mincols 99 \
        --quiet \
        --uc /dev/stdout 2> /dev/null | cut -f1)" = "N" ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"


#******************************************************************************#
#                                                                              #
#  biom from-uc                                                                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/09nb_YKL8e4
## 2016-08-22
## Q: How to convert a UC file to BIOM; what identifier format is required?
## A: biom (not vsearch) requires sample_id in the identifier (underscore-separated).
## not testable: the error and requirement come from the third-party biom tool, not vsearch.


#******************************************************************************#
#                                                                              #
#  Describe stat column                                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/_EQyGiTnhqQ
## 2016-08-26
## Q: What do the columns of --fastq_stats output mean?
## A: Documentation request; manual was later updated to describe fastq_stats output.
## not testable: documentation clarification request (the existence of the report section
## is already covered by the 2016-05-30 fastq_stats test above).


#******************************************************************************#
#                                                                              #
#  86% as chimeric reads: vsearch 1.9.1                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/G__T2eFURg4
## 2016-08-26
## Q: Why are ~86% of clustered reads flagged chimeric?
## A: Count by abundance, not cluster count; upgrade for better detection/reporting.
## not testable: interpretation/version-upgrade advice on a real dataset, no minimal repro.


#******************************************************************************#
#                                                                              #
#  Query for flag - double dashes vs single dash                               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/nlnrmI4jgMQ
## 2016-09-09
## Q: Does using a single dash (-strand) vs double dash (--strand) change results?
## A: No, vsearch accepts both single and double dashes identically; results are the same.

DESCRIPTION="forum (2016-09-09): options are accepted with a single dash"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        -derep_fulllength - \
        -output - \
        -quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2016-09-09): single-dash and double-dash options give identical results"
SINGLE=$(printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" -cluster_size - -id 0.97 -uc - -quiet 2> /dev/null)
DOUBLE=$(printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" --cluster_size - --id 0.97 --uc - --quiet 2> /dev/null)
[ "${SINGLE}" = "${DOUBLE}" ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SINGLE DOUBLE


#******************************************************************************#
#                                                                              #
#  subsample split                                                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/zxfLn0CJEAU
## 2016-09-19
## Q: How to write the sequences NOT chosen by a random subsample to a separate file?
## A: Use --fastaout_discarded (or --fastqout_discarded), added in v2.1.0.

DESCRIPTION="forum (2016-09-19): --fastaout_discarded receives the unselected sequences"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 50 \
        --randseed 1 \
        --fastaout /dev/null \
        --fastaout_discarded /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2016-09-19): --fastaout and --fastaout_discarded partition the input"
SELECTED=$(printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 50 \
        --randseed 1 \
        --fastaout /dev/stdout \
        --fastaout_discarded /dev/null \
        --quiet 2> /dev/null | \
    grep -c "^>")
DISCARDED=$(printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --fastx_subsample - \
        --sample_pct 50 \
        --randseed 1 \
        --fastaout /dev/null \
        --fastaout_discarded /dev/stdout \
        --quiet 2> /dev/null | \
    grep -c "^>")
[ "${SELECTED}" -eq 1 ] && [ "${DISCARDED}" -eq 1 ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset SELECTED DISCARDED


#******************************************************************************#
#                                                                              #
#  De novo VS reference                                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/-lJcLqulp5A
## 2016-10-06
## Q: Which chimera count (de novo vs reference) to trust in QIIME?
## A: Advice to trust/combine methods; no specific vsearch behaviour to pin down.
## not testable: usage/interpretation advice mediated by QIIME and external DB; no reproducible vsearch behaviour or option.


#******************************************************************************#
#                                                                              #
#  extracting all mapped sequences from uc file or biom table                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/5hQynxy_29E
## 2016-10-11
## Q: How to extract all sequences mapped to OTUs from a .uc file?
## A: Unanswered post; downstream parsing/biom task, not a vsearch behaviour.
## not testable: unanswered post about post-processing a uc file / biom table with external tools; no reproducible vsearch behaviour or option.


#******************************************************************************#
#                                                                              #
#  confused on how to merge different FASTQ file                               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/gt3JmqJtbh8
## 2016-10-12
## Q: How to merge several FASTQ pairs and pool them for a database?
## A: Process each pair individually then concatenate; cluster_otus/otutab not implemented.
## not testable: workflow/usage advice (per-file loops, cat, unsupported usearch v8 features); no single reproducible vsearch behaviour a minimal test can pin down.


#******************************************************************************#
#                                                                              #
#  Clustering method ??                                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/YoSsyQYKVmU
## 2016-10-13
## Q: Which clustering method does vsearch implement (usearch 5/6/uparse)?
## A: uclust-style (cluster_fast/cluster_smallmem); UPARSE/cluster_otus not implemented.
## not testable: informational answer about algorithm provenance; no command-level behaviour to assert beyond cluster_otus being unimplemented (covered elsewhere).


#******************************************************************************#
#                                                                              #
#  Getting all matches from a mapping                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/aB35IM4KF1Y
## 2016-10-17
## Q: --uc_allhits only returns the top hit; why?
## A: The option is --maxaccepts (not --max_accepts); with maxaccepts 0 + --uc_allhits all hits are reported.

DESCRIPTION="forum (2016-10-17): --max_accepts (with underscore) is an unrecognized option"
DB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --max_accepts 0 \
        --uc /dev/stdout 2>&1 | \
    grep -q "unrecognized option .--max_accepts'" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"

DESCRIPTION="forum (2016-10-17): --uc_allhits reports every equally-good target hit"
DB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>t2\nACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --uc_allhits \
        --uc /dev/stdout \
        --quiet 2> /dev/null | \
    awk 'BEGIN {n = 0} /^H/ {n++} END {if (n == 2) exit 0; exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"

DESCRIPTION="forum (2016-10-17): without --uc_allhits only the top hit is reported"
DB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>t2\nACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --uc /dev/stdout \
        --quiet 2> /dev/null | \
    awk 'BEGIN {n = 0} /^H/ {n++} END {if (n == 1) exit 0; exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"


#******************************************************************************#
#                                                                              #
#  vsearch for chimera checkin but not clustering?                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/qsXT59Gy4mo
## 2016-10-19
## Q: Can vsearch do chimera detection only, then feed output to swarm/sumaclust?
## A: Yes; --uchime_denovo with --nonchimeras/--chimeras works standalone.

DESCRIPTION="forum (2016-10-19): --uchime_denovo can be run standalone to filter chimeras"
printf ">a;size=20\nACGACGACGACGTTTTTTTTTTTTTTTTTTTTTTTTTTGGGGGGGGGG\n>b;size=15\nGGGGGGGGGGCCCCCCCCCCCCCCCCCCCCCCCCCCACGACGACGACG\n>c;size=1\nACGACGACGACGTTTTTTTTTTTTTTTTTTTTTTTTTTACGACGACGACG\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --sizein \
        --nonchimeras /dev/stdout \
        --quiet 2> /dev/null | \
    grep -q "^>" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Understanding counts from vsearch logs (chimera abundance)                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/niW4C0kT-Hg
## 2016-10-26
## Q: Why is the chimera-log sequence count lower than the dereplication input count?
## A: --minuniquesize 2 discarded singletons during dereplication (those are not passed on).

DESCRIPTION="forum (2016-10-26): --minuniquesize 2 keeps clusters with size >= 2"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s3\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minuniquesize 2 \
        --sizeout \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2016-10-26): --minuniquesize 2 discards singleton clusters"
N=$(printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s3\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minuniquesize 2 \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
    grep -c "^>")
[ "${N}" -eq 1 ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset N


#******************************************************************************#
#                                                                              #
#  WHY SEQUENCES LONGER THEN 7 ARE NOT CLUSTERING?                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/aCtLcke0Oek
## 2016-11-15
## Q: Very short (8-9 nt) sequences fail to cluster; can word length be changed?
## A: vsearch uses 8-mer heuristics; --wordlength can be set (range 3 to 15) to help short seqs.

# --wordlength 15 is also within range but builds a 4^15-entry k-mer
# index (~4 GB, tens of seconds), too heavy for CI; the lower bound (3)
# is tested here and the upper bound is covered by the rejection of 16
# below.
DESCRIPTION="forum (2016-11-15): --wordlength 3 is accepted by cluster_smallmem"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --usersort \
        --id 0.97 \
        --wordlength 3 \
        --uc /dev/stdout \
        --quiet 2> /dev/null | \
    grep -q "^C" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2016-11-15): --wordlength above 15 is rejected (range is 3 to 15)"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --usersort \
        --id 0.97 \
        --wordlength 16 \
        --uc /dev/stdout 2>&1 | \
    grep -q "Argument to --wordlength must be in the range 3 to 15" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  QIIME crashing with vsearch                                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/E3y0p5zJg00
## 2016-11-15
## Q: QIIME crashes (KeyError 'denovo51') with vsearch 2.3.0 but not 2.0.2.
## A: QIIME-side parsing problem / possible missing library in a binary build; not a vsearch behaviour.
## not testable: crash occurs in QIIME's parse_usearch61_clusters wrapper / binary-distribution issue; no reproducible vsearch behaviour or option to assert.


#******************************************************************************#
#                                                                              #
#  VSEARCH/QIIME chimera checking                                              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/m8jstyrgEyY
## 2016-11-15
## Q: How/when to run chimera checking and which reference DB in QIIME?
## A: Developer redirected the user to the QIIME forum; not a vsearch question.
## not testable: QIIME workflow and reference-database choice questions; no reproducible vsearch behaviour or option.


#******************************************************************************#
#                                                                              #
#  FORBIDDEN INTERNAL GAPS                                                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/OBIUgQ157ZM
## 2016-11-15
## Q: Internal gaps appear in the alignment despite forbidding them via *I gap penalties.
## A: Acknowledged as an unresolved bug at the time; here we pin down the stable, well-defined part:
##    the *I (interior) gap-penalty syntax is accepted by --gapopen/--gapext.

DESCRIPTION="forum (2016-11-15): *I (interior) gap-penalty syntax is accepted by cluster_smallmem"
printf ">s1\nACGTACGTACGT\n>s2\nACGTACGTAC\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --usersort \
        --id 0.5 \
        --minseqlength 3 \
        --gapopen "*I/0E" \
        --gapext "*I/12E" \
        --uc /dev/stdout \
        --quiet 2> /dev/null | \
    grep -q "^C" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  recalculated phred scores after merge pairs                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/yY8U9aGTT8g
## 2016-11-15
## Q: How to view recalculated Phred/expected-error values after merging reads?
## A: Use --eeout (with fastq_filter); the expected error is written into the read header.

DESCRIPTION="forum (2016-11-15): --eeout adds ee= to fastq header"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --eeout \
        --quiet \
        --fastqout - | \
    grep -q "^@s1;ee=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  No chimeras in the representative OTUs                                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/19uYH8T6hww
## 2016-11-18
## Q: Why does de novo chimera detection find no chimeras among representative OTUs?
## A: De novo detection requires abundance (size) information; without abundance differences nothing is flagged.

## A;size=50 + B;size=50 are parents; chim;size=1 is a left-A/right-B chimera.
DESCRIPTION="forum (2016-11-18): de novo chimera detection flags chimera when parents are more abundant"
printf ">A;size=50\nGCTAACGCGTTAAGTATCCCGCCTGGGGAGTACGGTCGCAAGATTAAAACTCAAATGAATTGACGGGGGCCCGCACAAGCGGTGGAGCATGTGGTTTAATTCGAAGCAACGCGAAGAACCTTACCAGGTCTTGACATCCTGCGAACCCTC\n>B;size=50\nTTGGGTTAAGTCCCGCAACGAGCGCAACCCTTGTCCTTAGTTGCCAGCATTCAGTTGGGCACTCTAAGGAGACTGCCGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAGTCATCATGGCCCTTACGACCAGGGCTACACACGTGCTA\n>chim;size=1\nGCTAACGCGTTAAGTATCCCGCCTGGGGAGTACGGTCGCAAGATTAAAACTCAAATGAGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAGTCATCATGGCCCTTACGACCAGGGCTACACACGTGCTA\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --quiet \
        --chimeras /dev/stdout 2> /dev/null | \
    grep -qx ">chim;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## same sequences but all size=1: no abundance skew, no chimera reported.
DESCRIPTION="forum (2016-11-18): de novo chimera detection finds nothing without abundance differences"
printf ">A;size=1\nGCTAACGCGTTAAGTATCCCGCCTGGGGAGTACGGTCGCAAGATTAAAACTCAAATGAATTGACGGGGGCCCGCACAAGCGGTGGAGCATGTGGTTTAATTCGAAGCAACGCGAAGAACCTTACCAGGTCTTGACATCCTGCGAACCCTC\n>B;size=1\nTTGGGTTAAGTCCCGCAACGAGCGCAACCCTTGTCCTTAGTTGCCAGCATTCAGTTGGGCACTCTAAGGAGACTGCCGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAGTCATCATGGCCCTTACGACCAGGGCTACACACGTGCTA\n>chim;size=1\nGCTAACGCGTTAAGTATCCCGCCTGGGGAGTACGGTCGCAAGATTAAAACTCAAATGAGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAGTCATCATGGCCCTTACGACCAGGGCTACACACGTGCTA\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --quiet \
        --chimeras /dev/stdout 2> /dev/null | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  VSEARCH Citation                                                            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/mFbspR4RUQA
## 2016-11-19
## Q: How should VSEARCH be cited?
## A: Cite the PeerJ paper (https://peerj.com/articles/2584/).
## not testable: citation request, no vsearch behaviour to pin down


#******************************************************************************#
#                                                                              #
#  Do I need to concatenate after fastq_filter                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/ozNuNkDpmI0
## 2016-11-28
## Q: Is an explicit concatenation step still needed before dereplication?
## A: No; vsearch reads concatenated entries straight from stdin (e.g. cat *.fa | vsearch --derep_fulllength -).

## two "files" concatenated into stdin; identical a/c collapse to size=2.
DESCRIPTION="forum (2016-11-28): derep_fulllength reads concatenated entries from stdin (no temp file)"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n>c\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --sizein \
        --sizeout \
        --quiet \
        --output /dev/stdout | \
    grep -qx ">a;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Clustering OTU on VSEARCH                                                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/pNjWOTTXSnE
## 2016-12-19
## Q: Why is --otus not accepted by --cluster_fast?
## A: --cluster_fast has no --otus option; use --centroids to output representative sequences.

DESCRIPTION="forum (2016-12-19): cluster_fast rejects --otus"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --otus /dev/stdout 2>&1 | \
    grep -q "unrecognized option .--otus'" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2016-12-19): cluster_fast outputs representatives with --centroids"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_fast - \
        --id 0.97 \
        --quiet \
        --centroids /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Agglomerative clustering with vsearch                                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/FAKsLsohmS4
## 2016-12-23
## Q: Does vsearch offer agglomerative clustering like usearch -cluster_agg?
## A: No; there is no such function (--cluster_agg is not a recognized option).

DESCRIPTION="forum (2016-12-23): no agglomerative clustering (--cluster_agg unrecognized)"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_agg - \
        --id 0.80 2>&1 | \
    grep -q "unrecognized option .--cluster_agg'" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  using vsearch instead of usearch in the GBS-SNP-CROPs pipeline              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/T2hNL6Nb9GA
## 2016-12-23
## Q: How to port usearch sortbylength/sortbysize commands (using --fastaout) to vsearch?
## A: vsearch uses --output, not --fastaout, for sortbylength/sortbysize.

DESCRIPTION="forum (2016-12-23): sortbylength rejects --fastaout"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --fastaout /dev/stdout 2>&1 | \
    grep -q "Invalid option(s): --fastaout" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2016-12-23): sortbylength writes results with --output"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --sortbylength - \
        --quiet \
        --output /dev/stdout | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2016-12-23): sortbysize rejects --fastaout"
printf ">s1;size=5\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --sortbysize - \
        --fastaout /dev/stdout 2>&1 | \
    grep -q "Invalid option(s): --fastaout" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Using multiple clustering QIIME pipeline for OTU picking                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/vfnj22Jkjmk
## 2016-12-29
## Q: Can vsearch produce an OTU map for chaining with QIIME's merge_otu_map.py?
## A: (no reply in thread)
## not testable: unanswered, QIIME-specific OTU-map workflow with no defined vsearch behaviour


#******************************************************************************#
#                                                                              #
#  search_exact doesn't find matches - syntax issue?                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/AvYdBCEc_cU
## 2017-01-04
## Q: Why does search_exact return 0 hits when matching short oligos against a longer reference?
## A: search_exact requires full-length matches (equal lengths); use usearch_global for shorter queries.

## query (25 nt) is a prefix of the longer reference (36 nt).
DESCRIPTION="forum (2017-01-04): search_exact requires full-length match (no hit for shorter query)"
printf ">q\nACGTACGTACGTACGTACGTACGTA\n" | \
    "${VSEARCH}" \
        --search_exact - \
        --db <(printf ">ref\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --quiet \
        --blast6out /dev/stdout 2> /dev/null | \
    grep -q "." && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="forum (2017-01-04): usearch_global id 1.0 matches shorter query within longer reference"
printf ">q\nACGTACGTACGTACGTACGTACGTA\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">ref\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 1.0 \
        --quiet \
        --blast6out /dev/stdout 2> /dev/null | \
    awk '$1 == "q" && $2 == "ref" && $3 == "100.0" { found = 1 } END { exit found ? 0 : 1 }' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Chimera detecting in vsearch OTU clustering                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/ffrrHqy4QM0
## 2017-01-06
## Q: Do vsearch clustering commands detect chimeras like usearch cluster_otus?
## A: No; vsearch clustering does clustering only, run uchime_denovo/uchime_ref separately.
## not testable: usage advice (no integrated chimera step); the "clustering only" claim has no
## single distinguishing observable beyond the chimera tests already covered above


#******************************************************************************#
#                                                                              #
#  Unusually high chimera percentage                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/XI8q75NNPYg
## 2017-01-09
## Q: Why ~41% chimeras with uchime_ref? Arguments were reversed.
## A: Put the query first (--uchime_ref) and the reference second (--db); swapping them is wrong.

## chim is a left-A/right-B chimera; A and B are the reference parents.
DESCRIPTION="forum (2017-01-09): uchime_ref flags query chimera against reference --db"
printf ">chim;size=1\nGCTAACGCGTTAAGTATCCCGCCTGGGGAGTACGGTCGCAAGATTAAAACTCAAATGAGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAGTCATCATGGCCCTTACGACCAGGGCTACACACGTGCTA\n" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db <(printf ">A;size=50\nGCTAACGCGTTAAGTATCCCGCCTGGGGAGTACGGTCGCAAGATTAAAACTCAAATGAATTGACGGGGGCCCGCACAAGCGGTGGAGCATGTGGTTTAATTCGAAGCAACGCGAAGAACCTTACCAGGTCTTGACATCCTGCGAACCCTC\n>B;size=50\nTTGGGTTAAGTCCCGCAACGAGCGCAACCCTTGTCCTTAGTTGCCAGCATTCAGTTGGGCACTCTAAGGAGACTGCCGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAGTCATCATGGCCCTTACGACCAGGGCTACACACGTGCTA\n") \
        --quiet \
        --chimeras /dev/stdout 2> /dev/null | \
    grep -qx ">chim;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## swapped: chimera used as the reference, parents queried -> nothing flagged.
DESCRIPTION="forum (2017-01-09): uchime_ref with swapped query/db arguments finds no chimera"
printf ">A;size=50\nGCTAACGCGTTAAGTATCCCGCCTGGGGAGTACGGTCGCAAGATTAAAACTCAAATGAATTGACGGGGGCCCGCACAAGCGGTGGAGCATGTGGTTTAATTCGAAGCAACGCGAAGAACCTTACCAGGTCTTGACATCCTGCGAACCCTC\n>B;size=50\nTTGGGTTAAGTCCCGCAACGAGCGCAACCCTTGTCCTTAGTTGCCAGCATTCAGTTGGGCACTCTAAGGAGACTGCCGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAGTCATCATGGCCCTTACGACCAGGGCTACACACGTGCTA\n" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --db <(printf ">chim;size=1\nGCTAACGCGTTAAGTATCCCGCCTGGGGAGTACGGTCGCAAGATTAAAACTCAAATGAGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAGTCATCATGGCCCTTACGACCAGGGCTACACACGTGCTA\n") \
        --quiet \
        --chimeras /dev/stdout 2> /dev/null | \
    grep -q "^>" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

DESCRIPTION="forum (2017-01-09): uchime_ref requires --db"
printf ">q;size=1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --uchime_ref - \
        --chimeras /dev/stdout 2>&1 | \
    grep -q "Fatal error: Database filename not specified with --db" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  fastq_mergepairs with named pipes                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/1UPEtGEA_fg
## 2017-01-10
## Q: Can fastq_mergepairs read from named pipes (FIFOs)?
## A: Yes (after the fix accepting S_ISFIFO inputs); vsearch reads forward/reverse from FIFOs.

DESCRIPTION="forum (2017-01-10): fastq_mergepairs accepts named pipes (FIFO) as input"
WORKDIR=$(mktemp -d)
FWD="${WORKDIR}/r1"
REV="${WORKDIR}/r2"
mkfifo "${FWD}" "${REV}"
printf "@s\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACGCGCGCG\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${FWD}" &
printf "@s\nCGCGCGCGTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${REV}" &
"${VSEARCH}" \
    --fastq_mergepairs "${FWD}" \
    --reverse "${REV}" \
    --quiet \
    --fastaout /dev/stdout 2> /dev/null | \
    grep -q "^>s" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
wait
rm -f "${FWD}" "${REV}"
rmdir "${WORKDIR}"
unset WORKDIR FWD REV


#******************************************************************************#
#                                                                              #
#  Chimera checking without clustering                                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/X7w2jiKNfrQ
## 2017-02-07
## Q: How to run chimera detection without clustering while keeping original ids?
## A: (no reply in thread)
## not testable: unanswered usage question, no specific vsearch behaviour/error to pin down


#******************************************************************************#
#                                                                              #
#  cluster_fast consensus differs from usearch                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/AibAvepI1Sw
## 2017-02-16
## Q: Why does cluster_fast yield far fewer clusters (453) than usearch (693) at id 0.995?
## A: Different undisclosed heuristics; vsearch is more sensitive. Not a bug.
## not testable: usearch is closed-source and unavailable; no deterministic black-box behaviour to pin down


#******************************************************************************#
#                                                                              #
#  Does the order of commands change final OTU clustering?                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/yfc3pGWeeZg
## 2017-02-23
## Q: Does the order of pipeline commands affect final OTU clustering?
## A: Pipeline (derep -> uchime_denovo -> cluster_fast -> usearch_global) is reasonable.
## not testable: general pipeline-design advice, no specific reproducible vsearch behaviour or option


#******************************************************************************#
#                                                                              #
#  vsearch pipeline for 16s analysis                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/3noDiYwIfz0
## 2017-03-05
## Q: Is this 16S pipeline OK and how to dereplicate without losing sample info?
## A: Add a derep step but keep sample info to build the biom file later.
## not testable: pipeline/usage advice and downstream biom/taxonomy tools; no isolated vsearch behaviour


#******************************************************************************#
#                                                                              #
#  Dereplication, chimera removal and Rereplication                            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/7j_Pv2e7ZUA
## 2017-03-08
## Q: Should chimeras + non-chimeras equal total input? Why does rereplicate duplicate labels?
## A: chimeras + non-chimeras + borderline = total; rereplicate lacks info to restore labels.
DESCRIPTION="forum (2017-03-08): uchime_denovo chimeras + non-chimeras + borderline equals total"
A="ACGTACGTACGTACGTACGTACGTAGCTAGCTAGCTAGCTAGCTAGCTGGCCGGCCGGCCGGCCTTAATTAATTAATTAA"
B="TTGGTTGGTTGGTTGGCCAACCAACCAACCAAGATCGATCGATCGATCAATTCCGGAATTCCGGAATTCCTTGGAATTCC"
CHIM="${A:0:40}${B:40:40}"
printf ">a;size=20\n%s\n>b;size=20\n%s\n>chim;size=1\n%s\n" "${A}" "${B}" "${CHIM}" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --chimeras /dev/null \
        --nonchimeras /dev/null \
        --borderline /dev/null 2>&1 | \
    grep -q "1 (33.3%) chimeras, 2 (66.7%) non-chimeras," && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION A B CHIM

DESCRIPTION="forum (2017-03-08): rereplicate repeats the same label and loses original identity"
printf ">s1;size=3\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --rereplicate - \
        --output - \
        --quiet 2>/dev/null | \
    grep -c "^>s1$" | \
    grep -qx "3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Remove singleton after clustering and create biom                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/J5a2yLvTeYw
## 2017-04-17
## Q: How to remove singletons after clustering and convert to a BIOM file?
## A: Use --sortbysize --minsize 2 to drop singletons; --search_exact ... --biomout for the table.
DESCRIPTION="forum (2017-04-17): sortbysize --minsize 2 removes singleton OTUs"
printf ">a;size=5\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=1\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    ${VSEARCH} \
        --sortbysize - \
        --minsize 2 \
        --output - \
        --quiet 2>/dev/null | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">a;size=5 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2017-04-17): search_exact --biomout writes a BIOM 1.0 JSON table"
printf ">q;size=2\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --search_exact - \
        --db <(printf ">otu1\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --biomout - \
        --quiet 2>/dev/null | \
    grep -q "Biological Observation Matrix" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Remove singletons and approach to closed reference in vsearch               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/ll7_jXyc-6Y
## 2017-04-24
## Q: Run usearch_global on singleton-filtered OTUs or on the original file?
## A: Use the original labelled file; derep+filtering loses sample info. minsize boundary is inclusive.
DESCRIPTION="forum (2017-04-24): sortbysize --minsize 2 keeps doubletons (boundary is inclusive)"
printf ">a;size=2\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=1\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    ${VSEARCH} \
        --sortbysize - \
        --minsize 2 \
        --output - \
        --quiet 2>/dev/null | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">a;size=2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Problem during installing                                                   #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/hDpuiEffScY
## 2017-04-27
## Q: Build fails with "autoreconf: not found".
## A: Install GNU autotools/gcc, or download a precompiled binary.
## not testable: build/install environment issue, not a vsearch runtime behaviour


#******************************************************************************#
#                                                                              #
#  VSEARCH-based pipeline                                                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/QEM5_fiZe70
## 2017-05-01
## Q: Can the pipeline be used for amoA, and where do sample names come from?
## A: Update DBs for the target gene; sample labels come from --relabel during derep.
## not testable: pipeline-adaptation and external-database advice; no isolated reproducible behaviour


#******************************************************************************#
#                                                                              #
#  Finding duplicate sequences                                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Le0wIs-CVo4
## 2017-05-17
## Q: Does derep_fulllength do substring/prefix dedup, and what does "19I1394M83I" mean?
## A: derep_fulllength only merges identical seqs (allows case + T/U); derep_prefix dedups prefixes.
DESCRIPTION="forum (2017-05-17): derep_fulllength merges sequences differing only by case and T/U"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nacguacguacguacguacguacguacguacgu\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --output - \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -q "^>s1;size=2$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2017-05-17): derep_fulllength does not merge a prefix (requires identical length)"
printf ">pfx\nACGTACGTACGTACGTACGTACGTACGTACGT\n>full\nACGTACGTACGTACGTACGTACGTACGTACGTGGGG\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --output - \
        --quiet 2>/dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2017-05-17): derep_prefix merges a prefix into the longest sequence"
printf ">pfx\nACGTACGTACGTACGTACGTACGTACGTACGT\n>full\nACGTACGTACGTACGTACGTACGTACGTACGTGGGG\n" | \
    ${VSEARCH} \
        --derep_prefix - \
        --output - \
        --sizeout \
        --quiet 2>/dev/null | \
    grep -q "^>full;size=2$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Confusion on algorithm in clustering: cluster_fast                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/dTPMmyibRaU
## 2017-05-18
## Q: Which algorithm does cluster_fast use and must derep output be length-sorted first?
## A: Length-based greedy centroid clustering; cluster_fast sorts by length internally, no pre-sort needed.
DESCRIPTION="forum (2017-05-18): cluster_fast sorts by decreasing length, so the longest input is the centroid"
printf ">short\nACGTACGTACGTACGTACGTACGTACGTACGT\n>long\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.80 \
        --centroids - \
        --quiet 2>/dev/null | \
    grep -q "^>long$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Fastq_truncee (fastq_trunclen typo)                                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/rYcFdVF8jcU
## 2017-06-10
## Q: How to preserve headers of reads discarded during quality filtering of paired reads?
## A: Use --fastqout_discarded to capture reads removed by fastq_filter.
DESCRIPTION="forum (2017-06-10): fastq_filter --fastqout_discarded keeps reads removed by quality filtering"
printf "@good\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n@bad\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\n################################\n" | \
    ${VSEARCH} \
        --fastq_filter - \
        --fastq_maxee 0.5 \
        --fastqout /dev/null \
        --fastqout_discarded - \
        --quiet 2>/dev/null | \
    grep -q "^@bad$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  --uchime_denovo no chimeras detected - alternative dereplication            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/roWz8_nw2Tk
## 2017-06-14
## Q: Why does uchime_denovo report 0 chimeras when sequences lack size annotations?
## A: De novo detection needs abundance; embed ;size=N (e.g. via --sizeout) before running it.
DESCRIPTION="forum (2017-06-14): uchime_denovo detects no chimeras when all sequences have abundance 1"
A="ACGTACGTACGTACGTACGTACGTAGCTAGCTAGCTAGCTAGCTAGCTGGCCGGCCGGCCGGCCTTAATTAATTAATTAA"
B="TTGGTTGGTTGGTTGGCCAACCAACCAACCAAGATCGATCGATCGATCAATTCCGGAATTCCGGAATTCCTTGGAATTCC"
CHIM="${A:0:40}${B:40:40}"
printf ">a\n%s\n>b\n%s\n>chim\n%s\n" "${A}" "${B}" "${CHIM}" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --chimeras - \
        --quiet 2>/dev/null | \
    grep -c "^>" | \
    grep -qx "0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION A B CHIM

DESCRIPTION="forum (2017-06-14): uchime_denovo detects the chimera once abundances are provided"
A="ACGTACGTACGTACGTACGTACGTAGCTAGCTAGCTAGCTAGCTAGCTGGCCGGCCGGCCGGCCTTAATTAATTAATTAA"
B="TTGGTTGGTTGGTTGGCCAACCAACCAACCAAGATCGATCGATCGATCAATTCCGGAATTCCGGAATTCCTTGGAATTCC"
CHIM="${A:0:40}${B:40:40}"
printf ">a;size=20\n%s\n>b;size=20\n%s\n>chim;size=1\n%s\n" "${A}" "${B}" "${CHIM}" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --chimeras - \
        --quiet 2>/dev/null | \
    grep -qi "^>chim" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION A B CHIM


#******************************************************************************#
#                                                                              #
#  Output IDs that are not clustered                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/LbBMT-yqkhg
## 2017-06-22
## Q: How to output sequences that are not members of a cluster (singletons)?
## A: Identify singletons with --sortbysize and --maxsize.
DESCRIPTION="forum (2017-06-22): sortbysize --maxsize 1 outputs only non-clustered singletons"
printf ">a;size=5\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=1\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    ${VSEARCH} \
        --sortbysize - \
        --maxsize 1 \
        --output - \
        --quiet 2>/dev/null | \
    grep "^>" | \
    tr "\n" " " | \
    grep -qx ">b;size=1 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Different clustering when using single thread                               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/tnSPNKkFAe8
## 2017-07-07
## Q: Does --threads count change cluster membership in --cluster_smallmem (not just output order)?
## A: Unanswered; only output order is acknowledged as thread-dependent, with no reproducible spec to pin down on tiny input.
## not testable: no resolution given; thread-count effect on membership is not a documented/deterministic behaviour reproducible from minimal input.


#******************************************************************************#
#                                                                              #
#  Retain reference id from reference                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/jVY76zySsyk
## 2017-07-13
## Q: How to keep the reference (database) IDs instead of de novo OTU labels?
## A: Map reads directly to the reference with usearch_global; the hit's target field is the reference id.
DESCRIPTION="forum (2017-07-13): usearch_global --uc reports the reference id as target"
printf ">q1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACG\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">ref1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACG\n") \
        --id 0.97 \
        --strand plus \
        --quiet \
        --uc /dev/stdout | \
    awk '$1 == "H" {print $10}' | \
    grep -qx "ref1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Clustering and OTU table generation                                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/o6WiRmvCL60
## 2017-07-13
## Q: How to preserve abundances reduced by dereplication when clustering into an OTU table?
## A: Use --sizein/--sizeout throughout so abundances propagate; cluster_size sums member sizes into the centroid.
DESCRIPTION="forum (2017-07-13): cluster_size with sizein/sizeout sums member abundances"
printf ">a;size=3\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=4\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --sizein \
        --sizeout \
        --quiet \
        --centroids /dev/stdout | \
    grep -qx ">b;size=7" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  How do I generate OTU map file (txt) using vsearch                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/RdsaX0C1_IM
## 2017-07-14
## Q: How to produce a centroid->members OTU map text file in a specific custom layout?
## A: vsearch cannot emit that exact format; use --uc / --biomout / --otutabout instead.
## not testable: request is for an unsupported custom text layout; no reproducible vsearch behaviour to pin down.


#******************************************************************************#
#                                                                              #
#  maxhits vs top_hits_only                                                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/0q9gllMGSpQ
## 2017-08-01
## Q: Are --maxhits 1 and --top_hits_only redundant?
## A: No; top_hits_only reports all co-best hits, while maxhits 1 caps output to a single hit.
DESCRIPTION="forum (2017-08-01): top_hits_only reports all co-best hits"
printf ">q1\nGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">d1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT\n>d2\nGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n") \
        --id 0.90 \
        --strand plus \
        --maxaccepts 10 \
        --maxrejects 0 \
        --top_hits_only \
        --userfields target \
        --quiet \
        --userout /dev/stdout | \
    awk 'END {exit (NR == 2) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2017-08-01): maxhits 1 caps output to one hit despite co-best ties"
printf ">q1\nGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">d1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT\n>d2\nGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n") \
        --id 0.90 \
        --strand plus \
        --maxaccepts 10 \
        --maxrejects 0 \
        --maxhits 1 \
        --userfields target \
        --quiet \
        --userout /dev/stdout | \
    awk 'END {exit (NR == 1) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  fasta input to usearch_global header issue                                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/i6feVrSHPxM
## 2017-08-02
## Q: Why does --otutabout make one column per read instead of per sample?
## A: vsearch aggregates by the "sample=" header annotation; add it so columns become samples.
DESCRIPTION="forum (2017-08-02): sample= header annotation sets otutabout columns"
printf ">q1;sample=A\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACG\n>q2;sample=B\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACG\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">ref1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACG\n") \
        --id 0.97 \
        --strand plus \
        --quiet \
        --otutabout /dev/stdout | \
    head -n 1 | \
    grep -qx "#OTU ID	A	B" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  generating a sample x otu table from multiple sample files                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Ifpiybc5kRU
## 2017-08-04
## Q: Why does relabel create read-level granularity instead of per-sample aggregation?
## A: --relabel always appends an incrementing numeric ticker, making each header unique.
DESCRIPTION="forum (2017-08-04): relabel appends an incrementing ticker to each header"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --relabel sample=X \
        --quiet \
        --output /dev/stdout | \
    grep "^>" | \
    tr '\n' ' ' | \
    grep -qx ">sample=X1 >sample=X2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Chimeras with more than two parents in very long amplicons                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/uwfYbFpOeJ4
## 2017-08-04
## Q: Why are multi-breakpoint (>2 parent) chimeras in ~4.5kb amplicons not detected?
## A: Algorithmic limitation: the model assumes a single breakpoint; multi-parent detection is out of scope.
## not testable: a fundamental single-breakpoint model limitation; reproducing it reliably needs real multi-kb multi-parent data, not minimal printf input.


#******************************************************************************#
#                                                                              #
#  Dereplication leading to loss of an entire technical replicate              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/ymYN5O3LfH4
## 2017-08-04
## Q: Why does a technical replicate disappear after derep -> uchime_denovo -> rereplicate?
## A: No conclusive resolution; final counts matched chimera removal, loss likely expected, not pinned down.
## not testable: no confirmed reproducible behaviour; outcome attributed to the user's full pipeline, not a single specifiable vsearch effect.


#******************************************************************************#
#                                                                              #
#  uchime_denovo usearch vs vsearch                                            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/z3FxNepVc5k
## 2017-09-29
## Q: What does --id do in uchime_denovo, and why does vsearch find more chimeras?
## A: Count differences are deliberate algorithmic choices (not a bug); --id is not a uchime_denovo option (it belongs to uchime_ref).
DESCRIPTION="forum (2017-09-29): uchime_denovo does not accept the --id option"
printf ">a;size=9\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --id 0.99 \
        --chimeras /dev/null 2>&1 | \
    grep -q "Invalid option(s): --id" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  cluster_fast VS cluster_size                                                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/_ZjBk3vk2bo
## 2017-10-06
## Q: What is the difference between --cluster_fast and --cluster_size?
## A: cluster_fast sorts by decreasing length (longest = centroid); cluster_size sorts by decreasing abundance (most abundant = centroid).
DESCRIPTION="forum (2017-10-06): cluster_size sorts by abundance, most abundant is centroid"
printf ">a;size=1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>b;size=5\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.90 \
        --sizein \
        --quiet \
        --centroids /dev/stdout | \
    grep -qx ">b;size=5" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2017-10-06): cluster_fast sorts by length, longest is centroid"
printf ">short\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>longer\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.80 \
        --quiet \
        --centroids /dev/stdout | \
    grep -qx ">longer" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Chimera ID after OTU picking with QIIME                                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/dkzjlN7Y8S4
## 2017-10-26
## Q: Why does uchime fail with "illegal character" on aligned/QIIME FASTA files?
## A: Aligned FASTA contains gaps ('-') and dots ('.'), which vsearch rejects; run chimera detection on ungapped sequences.
DESCRIPTION="forum (2017-10-26): alignment gap '-' is rejected as an illegal character"
printf ">s1\nACG-TACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --nonchimeras /dev/null 2>&1 | \
    grep -q "Illegal sequence character '-'" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2017-10-26): alignment dot '.' is rejected as an illegal character"
printf ">s1\nACG.TACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --nonchimeras /dev/null 2>&1 | \
    grep -q "Illegal sequence character '\.'" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  How to set --fastq_maxdiffs on variable length amplicon data                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/XneTn0tKdMw
## 2017-11-10
## Q: How to set --fastq_maxdiffs for variable-length (ITS) amplicons with differing overlaps?
## A: Set it very high (highest tolerable in the longest overlap); other rules guard merges. fastq_mergepairs accepts large values.
DESCRIPTION="forum (2017-11-10): fastq_mergepairs accepts a very large fastq_maxdiffs value"
REV=$(mktemp)
printf "@s1\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${REV}"
printf "@s1\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    ${VSEARCH} \
        --fastq_mergepairs - \
        --reverse "${REV}" \
        --fastq_maxdiffs 1000 \
        --quiet \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${REV}"
unset REV DESCRIPTION


#******************************************************************************#
#                                                                              #
#  identify chimeras via vsearch                                               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/uAWDvJONHHM
## 2017-11-15
## Q: How to identify chimeras with vsearch (via QIIME's identify_chimeric_seqs.py)?
## A: This is a QIIME wrapper question; directed to the QIIME forum.
## not testable: QIIME wrapper / third-party tool usage, no reproducible vsearch behaviour


#******************************************************************************#
#                                                                              #
#  otu table wrong order OTU numbers                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/d6z2Y08jxSM
## 2017-11-20
## Q: OTUs in otutabout sort alphabetically (OTU_1, OTU_10, OTU_100) not numerically.
## A: vsearch numbers --relabel labels sequentially in cluster order; numeric sort (sort -k1,1V) is a downstream step.

## --relabel OTU_ produces sequentially numbered OTU_1, OTU_2 in cluster order in the otutabout header column
DESCRIPTION="forum (2017-11-20): cluster_size --relabel OTU_ numbers OTUs sequentially in otutabout"
printf ">s1;size=3\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>s2;size=1\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --sizein \
        --quiet \
        --relabel OTU_ \
        --otutabout /dev/stdout 2> /dev/null | \
    awk 'NR>1 {printf "%s ", $1} END {print ""}' | \
    grep -qx "OTU_1 OTU_2 " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## the otutabout sample-column header is derived from the input sequence headers (s1, s2)
DESCRIPTION="forum (2017-11-20): otutabout header lists samples derived from input headers"
printf ">s1;size=3\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>s2;size=1\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --sizein \
        --quiet \
        --relabel OTU_ \
        --otutabout /dev/stdout 2> /dev/null | \
    head -n 1 | \
    grep -qx "#OTU ID	s1	s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Continue interrupted chimera detection                                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/H_ChvDH7Kc0
## 2017-11-20
## Q: Can an interrupted uchime_denovo run be resumed?
## A: No, resuming an interrupted chimera search is not possible; must restart.
## not testable: absence of a resume feature is not a reproducible black-box behaviour


#******************************************************************************#
#                                                                              #
#  VSEARCH: chimera and OTU picking                                            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Hh-AaYVTQpg
## 2018-01-07
## Q: Pipeline for chimera + OTU picking; is a separate sortbysize step needed after derep?
## A: derep_full --minuniquesize 2 drops singletons; derep already outputs sorted by abundance, so a separate sort is unnecessary.

## --derep_fulllength --minuniquesize 2 removes singletons, keeping only clusters of size >= 2
DESCRIPTION="forum (2018-01-07): derep_fulllength --minuniquesize 2 removes singletons"
printf ">a\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>b\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>c\nCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --minuniquesize 2 \
        --sizeout \
        --quiet \
        --output /dev/stdout 2> /dev/null | \
    grep -qx ">a;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## derep_fulllength output is sorted by decreasing abundance by default (no separate sortbysize needed)
DESCRIPTION="forum (2018-01-07): derep_fulllength output is sorted by decreasing abundance"
printf ">a\nGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n>b\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>c\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --sizeout \
        --quiet \
        --output /dev/stdout 2> /dev/null | \
    grep "^>" | \
    head -n 1 | \
    grep -qx ">b;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  closed reference approach in vsearch                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/fTjFTXJq3BU
## 2018-01-27
## Q: Steps for closed-reference OTU picking against Greengenes for PICRUSt.
## A: Use usearch_global against an unaligned reference DB; chimera checking unnecessary for closed-ref.
## not testable: pipeline/usage advice tied to external Greengenes DB and PICRUSt, no specific vsearch corner-case


#******************************************************************************#
#                                                                              #
#  Where to fit global trimming step; what does map.pl do                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/20zQScHmqG0
## 2018-02-27
## Q: Where to fit global trimming; what does map.pl do?
## A: Use fastx_filter --fastq_trunclen for fixed-length trimming; map.pl is an external script.

## --fastx_filter --fastq_trunclen truncates all reads to a fixed length
DESCRIPTION="forum (2018-02-27): fastx_filter --fastq_trunclen truncates reads to a fixed length"
printf "@s1\nACGTACGTAC\n+\nIIIIIIIIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --fastq_trunclen 4 \
        --quiet \
        --fastaout /dev/stdout 2> /dev/null | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## reads shorter than --fastq_trunclen are discarded (cannot be truncated to the requested length)
DESCRIPTION="forum (2018-02-27): fastx_filter --fastq_trunclen discards reads shorter than the length"
[ "$(printf "@s1\nACG\n+\nIII\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --fastq_trunclen 4 \
        --quiet \
        --fastaout /dev/stdout 2> /dev/null | \
    grep -c "^>")" -eq 0 ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Many sequences lost when mapping OTU list to original file                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/fzicsSy5DnI
## 2018-02-27
## Q: ~100k sequences lost when clustering at id 1.0; different-length seqs clustered together.
## A: Default identity ignores terminal gaps; --iddef 1 (alignment-length based) keeps different-length seqs separate at id 1.0.

## at id 1.0 with --iddef 1, sequences differing only by terminal length form SEPARATE clusters
DESCRIPTION="forum (2018-02-27): iddef 1 keeps different-length sequences in separate clusters at id 1.0"
printf ">s1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 1.0 \
        --iddef 1 \
        --quiet \
        --uc /dev/stdout 2> /dev/null | \
    grep -c "^C" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## at id 1.0 with --iddef 0 (terminal gaps ignored), the same sequences merge into ONE cluster
DESCRIPTION="forum (2018-02-27): iddef 0 merges different-length sequences into one cluster at id 1.0"
printf ">s1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 1.0 \
        --iddef 0 \
        --quiet \
        --uc /dev/stdout 2> /dev/null | \
    grep -c "^C" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Using vsearch to cluster 100 / 800 nt transposable elements                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/iYyWyf7N13M
## 2018-03-10
## Q: How to avoid clustering variable-length (100-800 nt) sequences of low real similarity together?
## A: Use --iddef 1 (edit distance over alignment length) for stricter matching of different-length sequences.

## --iddef 1 (edit-distance / alignment-length) keeps clearly different-length sequences apart at id 0.8
DESCRIPTION="forum (2018-03-10): iddef 1 keeps a short and a much longer sequence in separate clusters at id 0.8"
printf ">s1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>s2\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.8 \
        --iddef 1 \
        --quiet \
        --uc /dev/stdout 2> /dev/null | \
    grep -c "^C" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  16S rRNA pipeline for V4/V5                                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/NOkDmn-4e94
## 2018-03-14
## Q: Must the SILVA reference DB be trimmed to V4/V5 before chimera detection?
## A: No; vsearch only scores the overlap region and ignores terminal gaps, so trimmed vs full DB give the same result.

## terminal gaps are ignored: a query matches a longer reference at full identity in the overlap region (no DB trimming needed)
DESCRIPTION="forum (2018-03-14): usearch_global ignores terminal gaps, full-length ref matches a shorter query at id=1.0"
printf ">q\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGGGGGG\n") \
        --id 1.0 \
        --strand plus \
        --quiet \
        --uc /dev/stdout 2> /dev/null | \
    awk '/^H/ {print $4}' | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  processing more than one file in vsearch                                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/5dZ7cF38HCY
## 2018-03-16
## Q: How to loop vsearch over 20 files; loops produced empty/missing outputs.
## A: The problem was bash loop syntax (globbing, quoting); not a vsearch issue.
## not testable: bash scripting / shell-loop syntax problem, not a vsearch behaviour


#******************************************************************************#
#                                                                              #
#  chimera.vsearch command not reading fastafile                               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/UUQnIK05pxg
## 2018-03-16
## Q: mothur's chimera.vsearch fails ("Permission denied", "Blank name").
## A: The vsearch binary lacked execute permission (chmod +x); a mothur/file-permission issue.
## not testable: mothur wrapper + OS file-permission problem, no reproducible vsearch behaviour


#******************************************************************************#
#                                                                              #
#  trouble generating OTU table after clustering                               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/8Nxqmkm8rYU
## 2018-03-20
## Q: biom from-uc fails: identifiers in BIOM not present in rep-seq fasta.
## A: Unresolved; the failure is in the external biom tool, not vsearch.
## not testable: error originates in the external biom-format tool, not vsearch


#******************************************************************************#
#                                                                              #
#  error with fastx_filter                                                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/asAvtR_weJM
## 2018-03-20
## Q: fastx_filter on Ion Torrent fails: "FASTQ quality value (43) above qmax (41)".
## A: Quality scores exceed the default --fastq_qmax 41; raise it (e.g. --fastq_qmax 43).

## a quality above qmax 41 is a fatal error in fastx_filter. 41 was the
## default when the question was asked; since 3.0 it has to be requested,
## the default being 93 (see the next test)
DESCRIPTION="forum (2018-03-20): fastx_filter fatal error when quality value exceeds qmax 41"
printf "@s1\nACGT\n+\nLLLL\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --fastq_qmax 41 \
        --fastaout /dev/stdout 2>&1 | \
    grep -q "above qmax (41)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## since 3.0 the default --fastq_qmax is 93, so the Ion Torrent file that
## prompted the question is accepted without any option at all
DESCRIPTION="forum (2018-03-20): fastx_filter accepts the same input with the 3.0 default qmax"
printf "@s1\nACGT\n+\nLLLL\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --fastaout /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## raising --fastq_qmax to 43 makes the same high-quality input acceptable
DESCRIPTION="forum (2018-03-20): fastx_filter --fastq_qmax 43 accepts quality value 43"
printf "@s1\nACGT\n+\nLLLL\n" | \
    ${VSEARCH} \
        --fastx_filter - \
        --fastq_qmax 43 \
        --quiet \
        --fastaout /dev/stdout 2> /dev/null | \
    grep -qx "ACGT" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Suitability for arthropod metagenomics?                                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/vmL7a5xzgd4
## 2018-03-20
## Q: Is vsearch suitable for COI-based arthropod metagenomics?
## A: Yes for single-amplicon data, not for shotgun metagenomics (usage advice).
## not testable: usage/applicability advice, no command or behaviour to pin down


#******************************************************************************#
#                                                                              #
#  maxaccepts, maxrejects, and top hit                                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/IX4dtVahUvg
## 2018-03-21
## Q: Why did an exhaustive search return a 100% hit that is visibly different?
## A: Default --iddef is 2 (terminal gaps ignored), inflating identity; use --iddef 0/1.

# with the default identity definition (iddef 2) terminal gaps are ignored,
# so a query that is an internal substring of the target scores 100.0%; the
# same alignment scored with iddef 1 (terminal gaps count as differences)
# scores lower. userfields 'id' reflects the default (== id2), not id1.
DESCRIPTION="forum (2018-03-21): default iddef is 2 (terminal gaps ignored)"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nGGGGGACGTACGTACGTACGTACGTACGTACGTACGTGGGGG\n") \
        --id 0.5 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --quiet \
        --userfields id+id1+id2 \
        --userout - 2>/dev/null | \
    grep -qx "100.0	76.2	100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  negative control removal                                                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/hKErZyhMs1k
## 2018-03-23
## Q: Can vsearch remove sequences found in negative controls before clustering?
## A: No single option; build a usearch_global + --notmatched workflow (advice).
## not testable: multi-step workflow recommendation, no single behaviour to pin down


#******************************************************************************#
#                                                                              #
#  usearch_global not choosing best match                                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/vY4qUIaUbUY
## 2018-03-23
## Q: Why does usearch_global not return the highest-identity match?
## A: Developer points to GitHub issue 298 for the heuristic explanation.
## not testable: resolution defers to an external GitHub issue, no forum-stated reproducer


#******************************************************************************#
#                                                                              #
#  how can i get otutable file with taxonomy using vsearch                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/GPvQ6_jRkeM
## 2018-04-16
## Q: How to merge an OTU table with taxonomy using vsearch?
## A: Use an external tutorial / downstream tooling to combine the two outputs.
## not testable: points to an external tutorial, no vsearch behaviour to pin down


#******************************************************************************#
#                                                                              #
#  -usearch_global: specify output file with abundances of ASVs                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/CdnBZOMTlsY
## 2018-04-30
## Q: How to output ASV abundances (size = number of mapped reads) with usearch_global?
## A: Use --dbmatched with --sizeout; size = count of query sequences mapped to each db seq.

# --dbmatched together with --sizeout annotates each matched database sequence
# with the number of query sequences that mapped to it (here 3 identical queries
# all map to t1, giving size=3)
DESCRIPTION="forum (2018-04-30): dbmatched + sizeout counts mapped query sequences"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>q2\nACGTACGTACGTACGTACGTACGTACGTACGT\n>q3\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.97 \
        --sizeout \
        --quiet \
        --dbmatched - 2>/dev/null | \
    grep -qx ">t1;size=3" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  adding taxonomy to OTU table                                                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/erKSN2EAvjE
## 2018-04-30
## Q: Can usearch_global show the best reference match for taxonomy assignment?
## A: Use external tools (STAMPA, QIIME 2) on top of usearch_global results.
## not testable: resolution recommends external third-party tools


#******************************************************************************#
#                                                                              #
#  fastq-mergepairs, tandem repeat failure and indel in overlap                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/f8RZXN9GnAc
## 2018-05-23
## Q: Does vsearch merge pairs with indels in the overlap; what is "tandem repeat"?
## A: It does not merge indel-in-overlap pairs; the message reflects multiple alignment diagonals.
## not testable: no reliable minimal reproducer; whether a given indel-in-overlap is
## rejected (and which "multiple alignments" message fires) depends on alignment heuristics


#******************************************************************************#
#                                                                              #
#  Missing reads after Chimera calling                                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/4ePifJgLjVE
## 2018-05-25
## Q: After chimera detection, chimeric + non-chimeric counts do not add up; where are the rest?
## A: They are "borderline" sequences (a third class), captured with --borderline.

# uchime_denovo has a third output class beyond chimeras/nonchimeras: --borderline
# is a valid output option (accepted, exit 0)
DESCRIPTION="forum (2018-05-25): uchime_denovo accepts --borderline output"
printf ">a;size=10\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --quiet \
        --nonchimeras /dev/null \
        --borderline /dev/null 2>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# a clearly detected chimera (left half of pa + right half of pb) is reported in
# --chimeras, confirming it is a distinct class from --borderline
DESCRIPTION="forum (2018-05-25): detected chimera reported in chimeras, not borderline"
A="ACGATCGATCGATCGATCGATCGATCGATCGATCGTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCT"
B="TGCATGCATGCATGCATGCATGCATGCATGCATGCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCA"
printf ">pa;size=200\n%s\n>pb;size=200\n%s\n>ch;size=1\n%s%s\n" \
    "${A}" "${B}" "${A:0:36}" "${B:36:36}" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --quiet \
        --borderline /dev/null \
        --chimeras - 2>/dev/null | \
    grep -qx ">ch;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION A B


#******************************************************************************#
#                                                                              #
#  What is the default --id value for --cluster_fast                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/d3xN8I6GH0U
## 2018-06-05
## Q: What is the default --id for --cluster_fast?
## A: There is no default; --id is mandatory and must be specified.

# --cluster_fast (like the other clustering commands) has no default identity;
# omitting --id is a fatal error
DESCRIPTION="forum (2018-06-05): cluster_fast requires --id (no default value)"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --quiet \
        --centroids /dev/null 2>&1 | \
    grep -q "must be specified with --id" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  relabel unmerged forward sequences                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/l43f-xIen9c
## 2018-08-14
## Q: Can the unmerged forward reads (fastqout_notmerged_fwd) be relabeled like merged ones?
## A: In 2018 the usearch '@' relabel was unsupported; current vsearch DOES apply --relabel to notmerged_fwd.

# in v2.31.0 a --relabel prefix is applied to the --fastqout_notmerged_fwd
# records too (not only to merged reads); the original label is replaced by
# prefix + counter
DESCRIPTION="forum (2018-08-14): --relabel prefix is applied to fastqout_notmerged_fwd"
fwd="@s.r1
ACGTACGTACGTACGTACGT
+
IIIIIIIIIIIIIIIIIIII"
rev="@s.r1
GGGGGGGGGGTTTTTTTTTT
+
IIIIIIIIIIIIIIIIIIII"
${VSEARCH} \
    --fastq_mergepairs <(printf "%s\n" "${fwd}") \
    --reverse <(printf "%s\n" "${rev}") \
    --relabel sample. \
    --quiet \
    --fastqout_notmerged_fwd - 2>/dev/null | \
    grep -qx "@sample.1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset fwd rev


#******************************************************************************#
#                                                                              #
#  VSEARCH clustering fails for mutations in the beginning of the sequence     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/1DvtTJ3DX5I
## 2018-08-15
## Q: Why does clustering fail to merge short low-complexity seqs differing only at the start?
## A: dust masking leaves too few distinct k-mers; set --minwordmatches 0 to bypass the heuristic.

# two 51-nt sequences differ only at position 1 and are mostly low-complexity
# (poly-A); under dust masking the default k-mer heuristic keeps them apart
# (two clusters)
DESCRIPTION="forum (2018-08-15): dust masking + default minwordmatches leaves seqs unclustered"
[ "$(printf ">s1\nATTGATTGATTGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>s2\nCTTGATTGATTGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --cluster_smallmem - \
        --usersort \
        --id 0.9 \
        --iddef 1 \
        --qmask dust \
        --quiet \
        --uc - 2>/dev/null | grep -c '^C')" -eq 2 ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# setting --minwordmatches 0 disables the k-mer heuristic and the two sequences
# now cluster together (a single cluster)
DESCRIPTION="forum (2018-08-15): --minwordmatches 0 lets low-complexity short seqs cluster"
[ "$(printf ">s1\nATTGATTGATTGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n>s2\nCTTGATTGATTGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --cluster_smallmem - \
        --usersort \
        --id 0.9 \
        --iddef 1 \
        --qmask dust \
        --minwordmatches 0 \
        --quiet \
        --uc - 2>/dev/null | grep -c '^C')" -eq 1 ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  output all pairwise distances using Vsearch                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/92ShJw0RkIs
## 2018-08-15
## Q: How to output all pairwise distances compactly (without full alignments)?
## A: Use allpairs_global with --userout/--userfields (e.g. id) for a small tabular file.

# allpairs_global computes every pairwise comparison; --userout with
# --userfields id gives a compact identity table without alignments
DESCRIPTION="forum (2018-08-15): allpairs_global emits pairwise identity via userout/userfields"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nACGTACGTACGTACGTACGTACGTACGTACGA\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --quiet \
        --userfields query+target+id \
        --userout - 2>/dev/null | \
    grep -qx "s1	s2	96.9" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  In which circumstances Vsearch (--cluster_fast) throw away reads?           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/YqxkNj_gcd0
## 2018-08-16
## Q: Under what circumstances does --cluster_fast drop reads from its output?
## A: Non-centroid members of a cluster are not output; only the centroid (or a consensus) is written.
DESCRIPTION="forum (2018-08-16): cluster_fast keeps only one centroid per cluster of identical reads"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.95 \
        --quiet \
        --centroids - 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  clustering at 0.98 ending up with identical centroids                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/1J0WLJX2-gQ
## 2018-08-24
## Q: Why do clusters produce identical consensus sequences with --consout?
## A: --consout builds artificial consensus sequences (centroid= headers); use --centroids for real representative sequences.
DESCRIPTION="forum (2018-08-24): consout emits artificial centroid= consensus headers"
printf ">a;size=5\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --sizein \
        --quiet \
        --consout - 2> /dev/null | \
    grep -q "^>centroid=a;size=" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2018-08-24): centroids emits a real sequence label (no centroid= prefix)"
printf ">a;size=5\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --sizein \
        --quiet \
        --centroids - 2> /dev/null | \
    grep -q "^>a;size=5$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  Usearch otutab command analog in Vsearch                                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Gx6F2Ph10RM
## 2018-09-02
## Q: What is the usearch otutab equivalent in vsearch?
## A: usearch_global with --otutabout produces a classic tab-separated OTU table.
DESCRIPTION="forum (2018-09-02): usearch_global --otutabout builds a tab-separated OTU table"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.97 \
        --strand plus \
        --quiet \
        --otutabout - 2> /dev/null | \
    grep -qx "t1	1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  --uchime2_denovo options                                                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/GsvG84YChHo
## 2018-09-04
## Q: Is uchime2_denovo only for 454, or does it work on Illumina/any amplicon data?
## A: It works on denoised amplicons from any platform; de novo detection needs no reference database (uchime3_denovo preferred).
DESCRIPTION="forum (2018-09-04): uchime_denovo detects a chimera without a reference database"
A="ACGATCGATCGATCGATCGATCGATCGATCGATCGTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCT"
B="TGCATGCATGCATGCATGCATGCATGCATGCATGCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCA"
printf ">pa;size=200\n%s\n>pb;size=200\n%s\n>ch;size=1\n%s%s\n" \
    "${A}" "${B}" "${A:0:36}" "${B:36:36}" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --sizein \
        --quiet \
        --chimeras - 2> /dev/null | \
    grep -qx ">ch;size=1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION A B


#******************************************************************************#
#                                                                              #
#  Merge differences between vsearch and usearch                               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/AWPAQ7-Er5w
## 2018-09-05
## Q: Why does vsearch merge far fewer pairs than usearch with the same command?
## A: vsearch limits mismatches in the overlap via fastq_maxdiffs; raise it to merge more permissively.
DESCRIPTION="forum (2018-09-05): mergepairs default fastq_maxdiffs (10) merges a 3-mismatch overlap"
FRAG="ACGTTGCAACGGTTACCGGTACGTTGCAACGGTTACCAAGGTTCCAAGGTTCCAAGGTT"
FRAGMUT="ACGTTGCAACGGTTCCCGGTACGTTGCAAAGGTTACCAAGGTTCAAAGGTTCCAAGGTT"
RC=$(printf "%s" "${FRAG}" | rev | tr ACGT TGCA)
Q=$(printf 'I%.0s' $(seq 1 ${#FRAG}))
${VSEARCH} \
    --fastq_mergepairs <(printf "@m\n%s\n+\n%s\n" "${FRAGMUT}" "${Q}") \
    --reverse <(printf "@m\n%s\n+\n%s\n" "${RC}" "${Q}") \
    --quiet \
    --fastqout - 2> /dev/null | \
    grep -qx "${FRAG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2018-09-05): lowering fastq_maxdiffs to 2 rejects the same 3-mismatch overlap"
${VSEARCH} \
    --fastq_mergepairs <(printf "@m\n%s\n+\n%s\n" "${FRAGMUT}" "${Q}") \
    --reverse <(printf "@m\n%s\n+\n%s\n" "${RC}" "${Q}") \
    --fastq_maxdiffs 2 \
    --fastqout /dev/null 2>&1 | \
    grep -q "too many differences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION FRAG FRAGMUT RC Q


#******************************************************************************#
#                                                                              #
#  Staggered read pairs                                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Fa5V1Fdv_JU
## 2018-09-26
## Q: Why do staggered read pairs (overhangs past the opposite read) fail to merge?
## A: They are discarded by default; --fastq_allowmergestagger merges them and trims the overhangs.
DESCRIPTION="forum (2018-09-26): staggered pairs are not merged by default"
FRAG="ACGTTGCAACGTTGCAACGGTTACCGGTA"
RC=$(printf "%s" "${FRAG}" | rev | tr ACGT TGCA)
R1="${FRAG}TTTTTT"
R2="${RC}TTTTTT"
Q1=$(printf 'I%.0s' $(seq 1 ${#R1}))
Q2=$(printf 'I%.0s' $(seq 1 ${#R2}))
${VSEARCH} \
    --fastq_mergepairs <(printf "@m\n%s\n+\n%s\n" "${R1}" "${Q1}") \
    --reverse <(printf "@m\n%s\n+\n%s\n" "${R2}" "${Q2}") \
    --fastqout /dev/null 2>&1 | \
    grep -q "staggered read pairs" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2018-09-26): fastq_allowmergestagger merges staggered pairs and trims overhangs"
${VSEARCH} \
    --fastq_mergepairs <(printf "@m\n%s\n+\n%s\n" "${R1}" "${Q1}") \
    --reverse <(printf "@m\n%s\n+\n%s\n" "${R2}" "${Q2}") \
    --fastq_allowmergestagger \
    --quiet \
    --fastqout - 2> /dev/null | \
    grep -qx "${FRAG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION FRAG RC R1 R2 Q1 Q2


#******************************************************************************#
#                                                                              #
#  OTU ID                                                                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/umuLDv5BRtw
## 2018-10-01
## Q: Why does the OTU ID column show only accession (truncated at the first semicolon) despite --notrunclabels?
## A: Pure usage/data-formatting advice (edit the reference DB headers; merge taxonomy externally) - no isolatable vsearch behaviour.
## not testable: question is about SILVA header formatting and external taxonomy-merging workflow, not a reproducible vsearch behaviour


#******************************************************************************#
#                                                                              #
#  VSEARCH general pipeline to analyze Illumina Miseq raw data                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Gg8pKoMNqGc
## 2018-11-30
## Q: What is the proper order of steps for MiSeq paired-end data, and is de novo chimera detection possible without a reference?
## A: Conceptual workflow advice (merge, trim, filter, derep, cluster, chimera); no exact commands given.
## not testable: high-level pipeline-ordering advice with no specific command/behaviour to pin down (the de novo-without-reference point is already covered by the 2018-09-04 uchime_denovo test)


#******************************************************************************#
#                                                                              #
#  -usearch_global                                                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/7rO6WvaJYww
## 2018-12-14
## Q: Can vsearch assign taxonomy by searching nucleotide reads against a protein database?
## A: No - vsearch works on nucleotide sequences only; use usearch ublast or DIAMOND for protein databases.
## not testable: a fundamental scope limitation (no protein-search command exists), with no command/error to reproducibly exercise


#******************************************************************************#
#                                                                              #
#  About --uchime_ref and --uchime_denovo                                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Uv4zqvklsm0
## 2019-02-15
## Q: Does chimera-checking order matter, and is the Greengenes DB compatible with --uchime_ref?
## A: De novo detection relies on abundance (run derep --sizeout then uchime_denovo); any known-microbe DB works with --uchime_ref.
DESCRIPTION="forum (2019-02-15): uchime_denovo uses abundance, flagging the low-abundance sequence as the chimera"
A="ACGATCGATCGATCGATCGATCGATCGATCGATCGTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCT"
B="TGCATGCATGCATGCATGCATGCATGCATGCATGCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCA"
printf ">pa;size=200\n%s\n>pb;size=200\n%s\n>ch;size=1\n%s%s\n" \
    "${A}" "${B}" "${A:0:36}" "${B:36:36}" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --sizein \
        --quiet \
        --nonchimeras - 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION A B


#******************************************************************************#
#                                                                              #
#  unoise3                                                                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/ws7NEP68gO8
## 2019-02-28
## Q: Why do cluster_unoise results differ from usearch unoise3, and why does --id matter if unoise3 is identity-independent?
## A: unoise3 is identity-sensitive; vsearch's --cluster_unoise accepts and applies --id (chimera removal is a separate uchime3_denovo step).
DESCRIPTION="forum (2019-02-28): cluster_unoise accepts the identity-sensitive --id option"
printf ">a;size=100\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_unoise - \
        --sizein \
        --id 0.97 \
        --quiet \
        --centroids - 2> /dev/null | \
    grep -qx ">a;size=100" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  ReadStdioFile failed fatal error when run -udb2fasta                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/JbihPegYdvk
## 2019-03-20
## Q: udb2fasta fails with "ReadStdioFile failed ...errno=0" on a .udb file.
## A: That error is from usearch (wrong forum) on a likely-corrupted file; vsearch also provides udb2fasta and can be used instead.
DESCRIPTION="forum (2019-03-20): vsearch makeudb_usearch then udb2fasta round-trips the label"
UDB=$(mktemp)
printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --makeudb_usearch - \
        --output "${UDB}" \
        --quiet 2> /dev/null
${VSEARCH} \
    --udb2fasta "${UDB}" \
    --output - \
    --quiet 2> /dev/null | \
    grep -qx ">t1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${UDB}"
unset DESCRIPTION UDB


#******************************************************************************#
#                                                                              #
#  Fastq quality value above qmax 41                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/03lC9IpMPY0
## 2019-04-07
## Q: fastq_filter aborts with "FASTQ quality value (42) above qmax (41)".
## A: The default qmax was 41; pass --fastq_qmax 42 (or higher) to accept the higher quality scores.
## Since 3.0 the default is 93 and the question no longer arises, so the
## historical error is reproduced with an explicit --fastq_qmax 41
DESCRIPTION="forum (2019-04-07): a quality value of 42 is rejected with qmax 41"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n+\nKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK\n" | \
    ${VSEARCH} \
        --fastq_filter - \
        --fastq_maxee 1 \
        --fastq_qmax 41 \
        --fastqout /dev/null 2>&1 | \
    grep -qx "Fatal error: FASTQ quality value (42) above qmax (41)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2019-04-07): the same read passes with the 3.0 default qmax (93)"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n+\nKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK\n" | \
    ${VSEARCH} \
        --fastq_filter - \
        --fastq_maxee 1 \
        --fastqout /dev/null 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2019-04-07): raising fastq_qmax to 42 lets the read through"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGT\n+\nKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK\n" | \
    ${VSEARCH} \
        --fastq_filter - \
        --fastq_maxee 1 \
        --fastq_qmax 42 \
        --fastaout - \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION


#******************************************************************************#
#                                                                              #
#  cluster_fast and cluster_size issue                                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/biEHwceenuQ
## 2019-04-30
## Q: cluster_fast/cluster_size seem to ignore abundance; can --minsize be used?
## A: --minsize is not a valid option for clustering commands (rejected); use --sizein / sortbysize --minsize instead.
DESCRIPTION="forum (2019-04-30): --minsize is rejected by cluster_size"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --minsize 2 \
        --centroids /dev/null 2>&1 | \
    grep -q "^Invalid option(s): --minsize" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  RAM needed for --makeudb_usearch                                            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/3MyyNJ8KZY4
## 2019-05-29
## Q: How much RAM does --makeudb_usearch need for a 208 GB GenBank nt FASTA?
## A: Rule of thumb ~5x the FASTA size; vsearch is ill-suited to very long sequences.
## not testable: hardware/memory-sizing advice; no reproducible behaviour, option, or error to pin down at small scale.


#******************************************************************************#
#                                                                              #
#  long duration for denovo chimera detection                                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/vRWbAT56aZI
## 2019-06-20
## Q: Why is --uchime_denovo so slow on 10 GB, and can GNU parallel help?
## A: De novo detection is single-threaded by design; reorder the pipeline (derep -> cluster_size -> uchime_denovo) instead of parallelizing.
## not testable: performance/pipeline-ordering advice; no reproducible single-command behaviour or error at small scale.


#******************************************************************************#
#                                                                              #
#  --minsize while using --cluster_fast                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/EcJy4MmXzUg
## 2019-06-21
## Q: A published pipeline uses --minsize 2 with --cluster_fast, but it now errors.
## A: --minsize is not valid for cluster_fast; --mintsize is the accepted (abundance-based) option, or filter afterwards.
DESCRIPTION="forum (2019-06-21): --minsize is rejected by cluster_fast"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.97 \
        --minsize 2 \
        --centroids /dev/null 2>&1 | \
    grep -q "^Invalid option(s): --minsize" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2019-06-21): --mintsize is accepted by cluster_fast"
printf ">s1;size=2\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.97 \
        --sizein \
        --mintsize 2 \
        --centroids /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">s1;size=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  dereplicate sequences with same name                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/1b0PwnWzCvE
## 2019-08-27
## Q: Can vsearch dedupe identical sequences keeping only the first occurrence?
## A: --derep_fulllength keeps the first occurrence among identical sequences (name-based dedup is not built in).
DESCRIPTION="forum (2019-08-27): derep_fulllength keeps the first occurrence's header"
printf ">first\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n>second\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">first" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  dereplicate guppy_hac basecalled 16S ONT reads                              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/LV-t56eV-Gg
## 2019-09-13
## Q: Can vsearch dereplicate guppy_hac-basecalled 16S Oxford Nanopore reads?
## A: vsearch may not be ideal for very long (>5 kbp) sequences; no concrete protocol given.
## not testable: open-ended suitability advice for long-read data; no reproducible behaviour, option, or error.


#******************************************************************************#
#                                                                              #
#  Working with folded sequences (8-letter alphabet)                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/uziYUG-tjL4
## 2019-09-13
## Q: Can vsearch treat lowercase vs uppercase (8-letter folded alphabet) distinctly?
## A: Soft masking (--dbmask/--qmask soft) marks lowercase as masked; the effect is not reproducible at minimal scale.
## not testable: the soft-masking exclusion effect is not reproducible with a minimal single-sequence input (a fully lowercase 32 nt query still matched under --qmask soft in v2.31.0); cannot build a non-vacuous test.


#******************************************************************************#
#                                                                              #
#  OTU Assembly question                                                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/y7cI3dVoZMs
## 2019-10-17
## Q: How to see every sequence assigned to each OTU/cluster?
## A: Use --clusters PREFIX (one FASTA file per cluster) or --msaout (alignment + consensus per cluster).
DESCRIPTION="forum (2019-10-17): --clusters writes one file per cluster"
PREFIX=$(mktemp -u)
printf ">s1\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n>s2\nGGGGCCCCAAAAATGCTAGCTAGCATGCCGTA\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.97 \
        --clusters "${PREFIX}" \
        --centroids /dev/null \
        --quiet 2> /dev/null
COUNT=0
for f in "${PREFIX}"* ; do
    [ -e "${f}" ] && COUNT=$((COUNT + 1))
done
[ "${COUNT}" -eq 2 ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${PREFIX}"*
unset PREFIX COUNT f

DESCRIPTION="forum (2019-10-17): --msaout emits a consensus entry per cluster"
printf ">s1\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n>s2\nGGGGCCCCAAAAATGCTAGCTAGCATGCCGTA\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.97 \
        --msaout /dev/stdout \
        --quiet 2> /dev/null | \
    grep -q "^>consensus" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  OTU_fasta header                                                            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/StHwcoL9nGE
## 2019-10-26
## Q: What do "seqs" and "size" mean in a --consout centroid/consensus header?
## A: seqs = number of sequences in the cluster; with sizein/sizeout, size = summed cluster abundance.
DESCRIPTION="forum (2019-10-26): consout header reports cluster member count as seqs"
printf ">s1\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n>s2\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --consout /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">centroid=s1;seqs=2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2019-10-26): consout with sizein/sizeout reports summed cluster abundance"
printf ">s1;size=3\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n>s2;size=5\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --sizein \
        --sizeout \
        --consout /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">centroid=s2;seqs=2;size=8" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  advice on --maxrejects when --maxaccepts=1                                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/xwlzDbL91Cc
## 2019-11-04
## Q: What --maxrejects with --maxaccepts 1, and how to keep a single hit with --strand both?
## A: Tune maxrejects for speed; --maxhits 1 limits output to a single hit even when both strands match.
DESCRIPTION="forum (2019-11-04): --maxhits 1 returns a single hit even with --strand both"
printf ">q1\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n") \
        --id 0.9 \
        --strand both \
        --maxaccepts 100 \
        --maxrejects 100 \
        --maxhits 1 \
        --blast6out /dev/stdout \
        --quiet 2> /dev/null | \
    awk 'END {exit (NR == 1) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  split sequences in -allpairs_global to speed up vsearch                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/bvH5qZinLMs
## 2019-11-25
## Q: How to split all-vs-all allpairs_global and keep every comparison?
## A: --acceptall reports even dissimilar pairs, but it is an allpairs_global-only option (rejected by usearch_global).
DESCRIPTION="forum (2019-11-25): --acceptall reports even a dissimilar pair in allpairs_global"
printf ">s1\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n>s2\nGGGGCCCCAAAAATGCTAGCTAGCATGCCGTA\n" | \
    ${VSEARCH} \
        --allpairs_global - \
        --acceptall \
        --blast6out /dev/stdout \
        --quiet 2> /dev/null | \
    grep -q "^s1	s2" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2019-11-25): --acceptall is rejected by usearch_global"
DB=$(mktemp)
printf ">t\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n" > "${DB}"
printf ">q\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db "${DB}" \
        --id 0.9 \
        --acceptall \
        --blast6out /dev/null 2>&1 | \
    grep -q "^Invalid option(s): --acceptall" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"


#******************************************************************************#
#                                                                              #
#  --fastq_mergepairs                                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/SYUfrxMjWb4
## 2019-12-14
## Q: Can --fastq_mergepairs take wildcards/many files, and does --relabel work with it?
## A: Only one file pair at a time (extra files -> "Unrecognized string" fatal error); contrary to the thread, --relabel does work with --fastq_mergepairs.
DESCRIPTION="forum (2019-12-14): fastq_mergepairs rejects more than one forward input file"
${VSEARCH} \
    --fastq_mergepairs a.fastq b.fastq \
    --reverse c.fastq \
    --fastqout /dev/null 2>&1 | \
    grep -q "^Fatal error: Unrecognized string on command line (b.fastq)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2019-12-14): --relabel does rename merged reads in fastq_mergepairs"
FWD=$(mktemp)
REV=$(mktemp)
printf "@r1\nGTACTGATCGATTACGGCATGCTAGCTAGCAT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${FWD}"
printf "@r1\nGGGGCCCCAAAAATGCTAGCTAGCATGCCGTA\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${REV}"
${VSEARCH} \
    --fastq_mergepairs "${FWD}" \
    --reverse "${REV}" \
    --relabel X \
    --fastqout /dev/stdout \
    --quiet 2> /dev/null | \
    head -n 1 | \
    grep -qx "@X1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FWD}" "${REV}"
unset FWD REV


#******************************************************************************#
#                                                                              #
#  --derep_fulllength removing sequences below 30 bp                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/pXGS2msRAVQ
## 2020-01-22
## Q: Why does --derep_fulllength drop sequences shorter than ~30 bp?
## A: The default --minseqlength is 32; lower it (e.g. --minseqlength 30) to keep shorter sequences.
DESCRIPTION="forum (2020-01-22): derep_fulllength drops a 30 nt sequence by default (minseqlength 32)"
[ "$(printf ">s1\nACGTACGTACGTACGTACGTACGTACGTAC\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
    grep -c "^>")" -eq 0 ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2020-01-22): --minseqlength 30 keeps the 30 nt sequence in derep_fulllength"
[ "$(printf ">s1\nACGTACGTACGTACGTACGTACGTACGTAC\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --minseqlength 30 \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
    grep -c "^>")" -eq 1 ] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Indexing database                                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/3PEsOYRAaOQ
## 2020-01-28
## Q: Does vsearch implement UDB pre-indexed database files to speed up repeated searches?
## A: UDB support was added (--makeudb_usearch, --udbinfo, --udbstats, --udb2fasta); --db auto-detects UDB.
## not testable: feature-availability discussion; building/inspecting UDB files is covered by their own dedicated command tests, not pinned by this thread.


#******************************************************************************#
#                                                                              #
#  Duplicate OTU numbers                                                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/0QUOG62ncT8
## 2020-04-28
## Q: Why does my usearch_global blast6out taxonomy output contain duplicate OTUs with different taxa?
## A: Short alignments (26 nt) were accepted; --mincols 30 filters out alignments shorter than the threshold.
DESCRIPTION="forum (2020-04-28): --mincols rejects an alignment shorter than the threshold"
printf ">q1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --mincols 31 \
        --output_no_hits \
        --quiet \
        --blast6out - 2> /dev/null | \
    awk '$2 == "*" {n++} END {if (n == 1) exit 0; exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2020-04-28): --mincols accepts an alignment equal to the threshold"
printf ">q1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n") \
        --id 0.9 \
        --minseqlength 1 \
        --mincols 30 \
        --quiet \
        --blast6out - 2> /dev/null | \
    awk '$1 == "q1" && $2 == "t1" {n++} END {if (n == 1) exit 0; exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Hi, I have problem to run vsearch                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/v9lpdwHKKOs
## 2020-05-14
## Q: vsearch.exe on Windows opens and closes immediately; PowerShell install throws errors.
## A: vsearch is a command-line app; run it from CMD/PowerShell. No specific vsearch behaviour.
## not testable: platform/launch issue (Windows GUI double-click, install), no reproducible vsearch option or error.


#******************************************************************************#
#                                                                              #
#  Is it possible to resume truncated --cluster_smallmem run?                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/iACwEOp7074
## 2020-06-10
## Q: Can a truncated --cluster_smallmem run be resumed after an interruption?
## A: No built-in resume; manual workaround (re-feed seeds + unclustered seqs). No testable vsearch behaviour.
## not testable: feature-absence / procedural workaround, nothing a small black-box test can pin down.


#******************************************************************************#
#                                                                              #
#  protein clustering                                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/iwVKINHqffo
## 2020-06-25
## Q: Why does cluster_smallmem silently strip non-nucleotide characters from protein sequences?
## A: vsearch is nucleotide-only; amino-acid characters are stripped (a clearer warning was requested, issue #414).
## not testable: discusses a requested warning improvement; the amino-acid-stripping warning itself is already
## covered by the 2016-05-09 and 2021-03-07 tests.


#******************************************************************************#
#                                                                              #
#  Vsearch for AMR gene determination                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/ReMl5dLmpgI
## 2020-07-03
## Q: How to determine AMR genes in metagenomic data using the SARG database with vsearch?
## A: Question deemed too vague; general pipeline advice, no command given.
## not testable: open-ended methodology / external database question, no reproducible vsearch behaviour.


#******************************************************************************#
#                                                                              #
#  Problem encountered during MiteTracker                                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/adiYgPvdQac
## 2020-08-25
## Q: MiteTracker fails at the clustering step with a FileNotFoundError for the vsearch binary.
## A: Relative path to the binary was wrong; use an absolute path. Third-party wrapper config issue.
## not testable: FileNotFoundError comes from MiteTracker's Python, not vsearch; binary-path/wrapper config.


#******************************************************************************#
#                                                                              #
#  Implementation details on kh_find_diagonals                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/pBEe7gy5cDI
## 2020-09-01
## Q: How does kh_find_diagonals work and why use k-mer hashing instead of Needleman-Wunsch for merging?
## A: K-mers screen candidate overlap diagonals quickly; full optimal alignment would be too slow.
## not testable: source-code internals / algorithmic rationale, no observable command behaviour.


#******************************************************************************#
#                                                                              #
#  Help with command for --usearch_global, only 1 result                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/4m9NBXurO-g
## 2020-10-01
## Q: usearch_global returns only 1 hit when many matches are expected.
## A: Search stopped early; --maxaccepts 0 --maxrejects 0 searches the whole database.
DESCRIPTION="forum (2020-10-01): --maxaccepts 0 --maxrejects 0 reports all database hits, not just one"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>t2\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.9 \
        --maxaccepts 0 \
        --maxrejects 0 \
        --quiet \
        --blast6out - 2> /dev/null | \
    awk 'END {if (NR == 2) exit 0; exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Having vsearch --cluster_fast to output fastq sequences                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/xMbtqrVzwOs
## 2020-10-27
## Q: Can --cluster_fast output FASTQ sequences?
## A: No; clustering commands only produce FASTA, --fastqout is not a valid option.
DESCRIPTION="forum (2020-10-27): --cluster_fast rejects --fastqout (FASTA-only output)"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 0.97 \
        --fastqout /dev/stdout 2>&1 | \
    grep -qx "Invalid option(s): --fastqout" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  --usearch global (taxonomy, sintax)                                         #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/CnI6g82yIrk
## 2020-12-11
## Q: Why does usearch_global return 0 results with short sequences?
## A: Default minseqlength is 32 (short seqs discarded); use --minseqlength 1 to keep shorter sequences.
DESCRIPTION="forum (2020-12-11): usearch_global discards sequences shorter than default minseqlength 32"
printf ">q1\nACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nACGTACGTACGTACGTACGT\n") \
        --id 0.9 \
        --blast6out /dev/null 2>&1 | \
    grep -qx "minseqlength 32: 1 sequence discarded." && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

DESCRIPTION="forum (2020-12-11): --minseqlength 1 lets usearch_global match a short sequence"
printf ">q1\nACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nACGTACGTACGTACGTACGT\n") \
        --id 0.9 \
        --minseqlength 1 \
        --quiet \
        --blast6out - 2> /dev/null | \
    awk '$1 == "q1" && $2 == "t1" {n++} END {if (n == 1) exit 0; exit 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  For point mutation identification                                           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/pjLg8N1TC_Q
## 2021-02-04
## Q: Can vsearch align PacBio reads against a protein template to find point mutations?
## A: vsearch is nucleotide-only; cannot align against protein/amino-acid sequences.
## not testable: capability/suitability advice (no protein support), no specific reproducible command behaviour.


#******************************************************************************#
#                                                                              #
#  Difference between vsearch and usearch clustering outputs                   #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/kh8UZuJlT6g
## 2021-02-19
## Q: Why does vsearch produce many more OTUs than usearch on the same data at 97% identity?
## A: usearch removes singletons before clustering; algorithmic/heuristic differences explain the gap.
## not testable: cross-tool comparison and heuristic behaviour on a large real dataset, not a small pinned corner-case.


#******************************************************************************#
#                                                                              #
#  Clustering unique ASV sequences (no abundances)                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/orqWhwGlPPY
## 2021-02-26
## Q: How to map clustered ASVs back to their OTU centroids when there are no abundances?
## A: The --uc file holds the mapping; H lines carry the member in column 9 and its seed (centroid) in column 10, S/C lines carry the seed label in column 9 and '*' in column 10.

# in a uc file, an H (hit) line places the clustered member in field 9 and
# its centroid (seed) in field 10
DESCRIPTION="forum (2021-02-26): uc H line has member in field 9 and seed in field 10"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGA\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --strand plus \
        --quiet \
        --uc /dev/stdout 2> /dev/null | \
    awk '$1 == "H" && $9 == "s2" && $10 == "s1" { found = 1 } END { exit !found }' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# in a uc file, an S (seed) line places the centroid label in field 9 and a
# placeholder '*' in field 10
DESCRIPTION="forum (2021-02-26): uc S line has seed label in field 9 and '*' in field 10"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGA\n" | \
    ${VSEARCH} \
        --cluster_size - \
        --id 0.97 \
        --strand plus \
        --quiet \
        --uc /dev/stdout 2> /dev/null | \
    awk '$1 == "S" && $9 == "s1" && $10 == "*" { found = 1 } END { exit !found }' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  why not 100% matching query sequences                                       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/JjzzYS8uDkw
## 2021-03-04
## Q: Why does usearch_global report <100% matches against the centroids the queries were clustered into?
## A: usearch_global is heuristic; raising --maxrejects (or setting it to 0) considers more candidates.
## not testable: the missed-match effect requires a large, structured database to expose the maxrejects heuristic;
## a minimal printf input cannot reliably reproduce a heuristic miss (parameter-tuning advice already covered by
## per-command maxrejects tests).


#******************************************************************************#
#                                                                              #
#  Unrecognized string Error                                                   #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/0flwvF3KfCs
## 2021-03-07
## Q: Why does '--cluster_fast in.txt --clusters --id 1' fail, and why are protein sequences mangled?
## A: --clusters requires a filename-prefix argument (omitting it yields "Unrecognized string on command line"); vsearch is nucleotide-only and strips amino-acid-only characters with a WARNING.

# --clusters expects a filename prefix argument; when the next token is another
# option (here --id), vsearch reports the missing argument as an unrecognized
# string on the command line
DESCRIPTION="forum (2021-03-07): --clusters without a prefix argument is a fatal error"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --clusters \
        --id 1 2>&1 | \
    grep -qx "Fatal error: Unrecognized string on command line (1)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# vsearch processes nucleic acids only; amino-acid-only characters (here I, L,
# P) are stripped from the input and a WARNING is emitted
DESCRIPTION="forum (2021-03-07): amino-acid characters are stripped with a WARNING"
printf ">s1\nILPILPILPILPILPILPILPILPILPILPILP\n" | \
    ${VSEARCH} \
        --cluster_fast - \
        --id 1 \
        --centroids /dev/null 2>&1 | \
    grep -q "^WARNING:.*invalid characters stripped from FASTA file" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Reference database                                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/L7oc83Dy76o
## 2021-04-15
## Q: Where to download a SILVA reference database compatible with vsearch --sintax?
## A: Pointed to GitHub issue 438 for prepared databases.
## not testable: external database sourcing/download question; no vsearch behaviour, option, or error to pin down with a black-box test.


#******************************************************************************#
#                                                                              #
#  usearch_global not matching even at lower identity                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/DxI4xOFB-jM
## 2021-05-04
## Q: Why does usearch_global miss a short divergent query even at --id 0.5?
## A: The default k-mer prefilter (--minwordmatches) needs enough shared words; a short divergent sequence shares too few, so the alignment is never attempted. Setting --minwordmatches 0 disables the prefilter and rescues the match.

# a short, divergent query shares too few words with the target to pass the
# default k-mer prefilter, so no alignment is attempted and no match is
# reported, even at a permissive identity threshold
DESCRIPTION="forum (2021-05-04): default minwordmatches prefilter misses a short divergent query"
DB=$(mktemp)
printf ">t1\nTTTTGGGGCCCCAAAATTTTGGGGCCCCAAAAACGTTCGATCTATCGTTCGTTTTGGGGCCCCAAAATTTTGGGGCCCCAAAA\n" > "${DB}"
printf ">q1\nACGATCGATCGATCGATCG\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db "${DB}" \
        --id 0.5 \
        --minseqlength 1 \
        --strand plus \
        --quiet \
        --userfields query \
        --userout /dev/stdout 2> /dev/null | \
    grep -q . && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${DB}"

# disabling the k-mer prefilter with --minwordmatches 0 forces the alignment
# and rescues the otherwise-missed short divergent query
DESCRIPTION="forum (2021-05-04): --minwordmatches 0 rescues the short divergent query"
printf ">q1\nACGATCGATCGATCGATCG\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nTTTTGGGGCCCCAAAATTTTGGGGCCCCAAAAACGTTCGATCTATCGTTCGTTTTGGGGCCCCAAAATTTTGGGGCCCCAAAA\n") \
        --id 0.5 \
        --minseqlength 1 \
        --minwordmatches 0 \
        --strand plus \
        --quiet \
        --userfields query \
        --userout /dev/stdout 2> /dev/null | \
    grep -qx "q1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --minwordmatches 0 is accepted and does not break ordinary identical matches
DESCRIPTION="forum (2021-05-04): --minwordmatches 0 is accepted on a normal match"
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --usearch_global - \
        --db <(printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.9 \
        --minwordmatches 0 \
        --strand plus \
        --quiet \
        --userfields id \
        --userout /dev/stdout 2> /dev/null | \
    grep -qx "100.0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  different otu numbers in otu table and rep seqs                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/a7WWm1sZ2C4
## 2021-12-08
## Q: Why does the rep-seqs file contain more OTUs than the OTU table?
## A: Question about a third-party pipeline's allocation of multi-mapping reads; no vsearch command was given and the thread has no developer resolution.
## not testable: third-party-wrapper output discrepancy with no vsearch command, option, or error to reproduce.


#******************************************************************************#
#                                                                              #
#  micca otu vsearch error                                                     #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/MPBeY6b0TD0
## 2021-12-14
## Q: Why does a micca otu run fail right after vsearch reads the input?
## A: The actual error was not from vsearch; developer redirected the user to the micca forum.
## not testable: failure originates in the micca wrapper, not vsearch; no reproducible vsearch behaviour or error message.


#******************************************************************************#
#                                                                              #
#  Dereplication with fastq out file                                          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/U6tJQow4XX8
## 2022-01-11
## Q: Can dereplication read FASTQ and write FASTQ with quality scores preserved?
## A: derep_fulllength is FASTA-out only; fastx_uniques (v2.20.0+) dereplicates FASTQ->FASTQ, averaging quality by default and keeping the best score per position with --fastq_qout_max.

# by default fastx_uniques averages the per-position quality of merged
# duplicates: combining Q40 ('I') and Q20 ('5') yields Q22 ('7')
DESCRIPTION="forum (2022-01-11): fastx_uniques averages quality of duplicates by default"
printf "@a\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n@b\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\n55555555555555555555555555555555\n" | \
    ${VSEARCH} \
        --fastx_uniques - \
        --quiet \
        --fastqout /dev/stdout 2> /dev/null | \
    awk 'NR == 4 && /^7+$/ { ok = 1 } END { exit !ok }' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# --fastq_qout_max keeps the best (maximum) quality per position instead of
# averaging: combining Q40 ('I') and Q20 ('5') yields Q40 ('I')
DESCRIPTION="forum (2022-01-11): fastx_uniques --fastq_qout_max keeps the best quality per position"
printf "@a\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n@b\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\n55555555555555555555555555555555\n" | \
    ${VSEARCH} \
        --fastx_uniques - \
        --quiet \
        --fastq_qout_max \
        --fastqout /dev/stdout 2> /dev/null | \
    awk 'NR == 4 && /^I+$/ { ok = 1 } END { exit !ok }' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

# derep_fulllength is FASTA-output only and rejects --fastqout
DESCRIPTION="forum (2022-01-11): derep_fulllength rejects --fastqout"
printf "@a\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    ${VSEARCH} \
        --derep_fulllength - \
        --quiet \
        --fastqout /dev/stdout 2>&1 | \
    grep -q "^Invalid option(s): --fastqout" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Vsearch cluster results seems inconsistent                                  #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/qZpjwLqT1WA
## 2022-08-31
## Q: Why do clustering results differ when reproducing a colleague's analysis?
## A: Threshold-based clustering is sensitive to parameters, vsearch version, input order, and threading; cluster content is stable but ordering/results can shift.
## not testable: explanation of reproducibility factors (version, parameters, input order, threading) with no specific command or single pinnable behaviour.


#******************************************************************************#
#                                                                              #
#  fastq_mergepairs gives drastically different results than usearch           #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/ojqZYbEyUw4
## 2022-10-10
## Q: Why does fastq_mergepairs merge far fewer pairs than usearch?
## A: vsearch is deliberately stricter (lower error rate); --fastq_allowmergestagger handles staggered reads as usearch does.
## not testable: the core resolution is a design-philosophy difference between tools (strictness/error-rate trade-off), not a single reproducible behaviour (staggered-read handling is covered by the 2018-09-26 test).


#******************************************************************************#
#                                                                              #
#  mothur output file is too large                                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/8hFowsiJs00
## 2022-11-09
## Q: How to shrink a 533 GB mothur shared output from a closed-reference meta-analysis?
## A: Insert a clustering step (--cluster_size at 99% or --cluster_unoise) between dereplication and usearch_global to merge similar sequences before alignment.
## not testable: workflow advice to reduce output size; file size is data-volume dependent, not a pinnable black-box behaviour (the clustering commands themselves are covered by their own tests).


#******************************************************************************#
#                                                                              #
#  replacing perl script with shell command line                               #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/zvTMtfJarCQ
## 2023-04-27
## Q: How to replace a Perl mapping script with shell commands to extract non-chimeric, non-singleton sequences?
## A: User found an alternative external Perl script; no vsearch command-line equivalent was demonstrated.
## not testable: scripting/workflow help around an external Perl script; no specific vsearch option, behaviour, or error to reproduce.


#******************************************************************************#
#                                                                              #
#  23S and 16S analysis                                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/uW4WwRb8Yjw
## 2023-05-22
## Q: What is the correct sequence of vsearch commands for 16S/23S taxonomic classification and abundance?
## A: No resolution provided; thread is an unanswered pipeline-design request.
## not testable: open-ended pipeline-design question with no specific command, behaviour, or error; thread is unanswered.


#******************************************************************************#
#                                                                              #
#  fastq_mergepairs: multiple potential alignments report                      #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/DNdmOKtxM3w
## 2023-05-31
## Q: Can vsearch report which reads were discarded due to multiple potential alignments?
## A: No such feature exists (feature request, GitHub issue #524).
## not testable: feature request for not-yet-implemented reporting; no observable behaviour to pin down


#******************************************************************************#
#                                                                              #
#  Merged unsync fastq files                                                   #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/DKKrbvVc7u0
## 2023-08-13
## Q: Does fastq_mergepairs check headers, or does it require R1/R2 to be in sync?
## A: vsearch requires R1 and R2 files to be in sync; it does not resync them.

## more forward reads than reverse reads is a fatal error (files must be in sync)
DESCRIPTION="forum (2023-08-13): fastq_mergepairs aborts when forward/reverse counts differ"
FORWARD=$(mktemp)
REVERSE=$(mktemp)
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n@s2\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${FORWARD}"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" > "${REVERSE}"
"${VSEARCH}" \
    --fastq_mergepairs "${FORWARD}" \
    --reverse "${REVERSE}" \
    --fastqout /dev/null 2>&1 | \
    grep -q "More forward reads than reverse reads" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${FORWARD}" "${REVERSE}"
unset FORWARD REVERSE


#******************************************************************************#
#                                                                              #
#  PRE-PROCESSING                                                              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/JZ4jjO9yzPg
## 2023-10-11
## Q: What is the difference between --fastq_trunclen and --fastq_minlen?
## A: trunclen cuts reads to a fixed length (and discards shorter ones); minlen only discards reads below a length.

## fastq_trunclen truncates a longer read to the requested length
DESCRIPTION="forum (2023-10-11): fastq_trunclen truncates reads to the given length"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen 32 \
        --fastqout /dev/stdout \
        --quiet 2> /dev/null | \
    sed -n '2p' | \
    awk '{exit (length($0) == 32) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_trunclen also discards reads shorter than the requested length
DESCRIPTION="forum (2023-10-11): fastq_trunclen discards reads shorter than the given length"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_trunclen 40 \
        --fastqout /dev/stdout \
        --quiet 2> /dev/null | \
    awk 'END {exit (NR == 0) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## fastq_minlen only discards reads shorter than the threshold (does not truncate)
DESCRIPTION="forum (2023-10-11): fastq_minlen discards reads shorter than the given length"
printf "@s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_minlen 40 \
        --fastqout /dev/stdout \
        --quiet 2> /dev/null | \
    awk 'END {exit (NR == 0) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Inconsistent reads between derep.fa and otutab?                             #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/p6Sb6-ZjJHg
## 2023-10-17
## Q: Why does the OTU table hold fewer reads than the dereplicated input?
## A: --minuniquesize 2 discards sequences with post-dereplication abundance below 2 (singletons).

## --minuniquesize 2 removes singleton sequences from dereplication output
DESCRIPTION="forum (2023-10-17): derep_fulllength --minuniquesize 2 discards singletons"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s2\nACGTACGTACGTACGTACGTACGTACGTACGT\n>s3\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --minuniquesize 2 \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
    grep -c "^>" | \
    grep -qx "1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  --uchime_denovo doesn't write nonchimeras using abundance information       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/Cvgbb6xjFqI
## 2023-10-31
## Q: Why does --nonchimeras hold few sequences while the stats say ~99% are non-chimeric?
## A: per-unique-sequence counts differ from abundance-weighted (;size=) totals; --nonchimeras writes representatives, abundance is used only in the weighted stats line.

## uchime_denovo reports an abundance-weighted total reflecting ;size= annotations
DESCRIPTION="forum (2023-10-31): uchime_denovo abundance-weighted stats use ;size= info"
printf ">a;size=99\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=1\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --sizein \
        --nonchimeras /dev/null 2>&1 | \
    grep -q "in 100 total sequences" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --nonchimeras output keeps the abundance annotation (with --sizein --sizeout)
DESCRIPTION="forum (2023-10-31): uchime_denovo --nonchimeras preserves ;size= with sizeout"
printf ">a;size=99\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=1\nTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n" | \
    "${VSEARCH}" \
        --uchime_denovo - \
        --sizein \
        --sizeout \
        --nonchimeras /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">a;size=99" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  vsearch --usearch_global N stretches                                        #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/8IRNR3qant4
## 2023-11-23
## Q: How to detect/avoid matches driven by N (ambiguous) stretches in queries?
## A: aligning any ambiguous symbol scores zero, so an all-N query yields raw score 0; N positions add nothing to the score.

## an all-N query produces a raw alignment score of zero
DESCRIPTION="forum (2023-11-23): all-N query yields a raw alignment score of 0"
printf ">q\nNNNNNNNNNNNNNNNNNNNN\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTACGTACGTACGTACGT\n") \
        --id 0.1 \
        --minseqlength 1 \
        --userfields query+raw \
        --userout /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx "q	0" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## the 12 trailing N positions add nothing to the raw alignment score: only
## the 8 leading ACGT matches score (8 x default match reward 2 = 16)
DESCRIPTION="forum (2023-11-23): N positions do not contribute to the raw alignment score"
printf ">q\nACGTACGTNNNNNNNNNNNN\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t\nACGTACGTACGTACGTACGT\n") \
        --id 0.1 \
        --qmask none \
        --dbmask none \
        --minseqlength 1 \
        --userfields query+raw \
        --userout /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx "q	16" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Is the usearch --otutab and vsearch --usearch_global command the same       #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/0b3OfZE4L9k
## 2023-12-21
## Q: Are usearch --otutab and vsearch --usearch_global the same command?
## A: No; --otutab is not a vsearch command and --otus is not a vsearch option (use --usearch_global with --db and --otutabout).

## --otutab is not a recognized vsearch command
DESCRIPTION="forum (2023-12-21): --otutab is not a valid vsearch command"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --otutab - 2>&1 | \
    grep -q "no valid command specified" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --otus is not a recognized vsearch option
DESCRIPTION="forum (2023-12-21): --otus is not a valid vsearch option"
DB=$(mktemp)
printf ">t\nACGTACGTACGTACGTACGTACGTACGTACGT\n" > "${DB}"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db "${DB}" \
        --otus /dev/null 2>&1 | \
    grep -q "unrecognized option .--otus'" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${DB}"


#******************************************************************************#
#                                                                              #
#  OTU Table Labels                                                            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/hJokKGCFgrA
## Marita White / Frédéric Mahé 2024-06-27
## Q: how to pass sample names to option otutabout?
## A: filenames are truncated to the first hyphen; use ;sample=NAME annotations.
##
## (test moved verbatim from fixed_bugs.sh)

## OTU Table Labels (Marita White) 2024-06-26
# how to pass sample names to option otutabout?
# - filenames are trunctated to first hyphen when building OTU tables
# - solution is to use ;sample=NAME annotations
DESCRIPTION="forum (2024-06-26): OTU table labels"
SAMPLE1=$(mktemp)
SAMPLE2=$(mktemp)
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sample "sample1-ITS1-good" \
        --quiet \
        --fastaout "${SAMPLE1}"
printf ">s1\nA\n" | \
    "${VSEARCH}" \
        --fastx_filter - \
        --sample "sample2-ITS1-good" \
        --quiet \
        --fastaout "${SAMPLE2}"

cat "${SAMPLE1}" "${SAMPLE2}" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">s\nA\n") \
        --minseqlength 1 \
        --id 1.0 \
        --quiet \
        --otutabout - 2> /dev/null | \
    grep -q "sample[12]-ITS1-good" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm "${SAMPLE1}" "${SAMPLE2}"
unset SAMPLE1 SAMPLE2

# expect:
# #OTU ID	sample1-ITS1-good	sample2-ITS1-good
# s	1	1


#******************************************************************************#
#                                                                              #
#  More OTU counts than number of starting/merged reads in a sample            #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/n_sQ8GVp78Q
## 2024-07-03
## Q: Why are there more OTU counts than merged reads in a sample?
## A: --sizein makes clustering abundance-weighted, so centroid sizes sum the abundances of clustered sequences.

## --sizein sums member abundances into the centroid size
DESCRIPTION="forum (2024-07-03): cluster_size --sizein sums member abundances into centroid size"
printf ">a;size=5\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b;size=3\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --sizein \
        --sizeout \
        --centroids /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">a;size=8" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  How to analyze several fastq files at once + Other Questions                #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/xalA8QaNZy0
## 2024-07-10
## Q: fastq_filter fails with quality values outside qmin/qmax bounds.
## A: a quality value above qmax or below qmin is a fatal error; adjust --fastq_qmax / --fastq_qmin to the data.

## a quality value above qmax is a fatal error (41 was the default when
## the question was asked; since 3.0 it has to be requested)
DESCRIPTION="forum (2024-07-10): fastq_filter errors when a quality value exceeds qmax"
printf "@s1\nACGT\n+\nKKKK\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmax 41 \
        --fastqout /dev/null 2>&1 | \
    grep -q "above qmax (41)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## a quality value below qmin is a fatal error
DESCRIPTION="forum (2024-07-10): fastq_filter errors when a quality value is below qmin"
printf "@s1\nACGT\n+\n3333\n" | \
    "${VSEARCH}" \
        --fastq_filter - \
        --fastq_qmin 20 \
        --fastqout /dev/null 2>&1 | \
    grep -q "below qmin (20)" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Max length for derep or cluster commands                                    #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/_Bk4vr1P660
## 2024-08-06
## Q: Is there an upper length limit for derep/cluster (sequences several kb long)?
## A: No hard limit; only speed degrades for very long sequences in alignment-heavy steps.

## derep_fulllength accepts a long (6000 nt) sequence
DESCRIPTION="forum (2024-08-06): derep_fulllength accepts sequences several kb long"
printf ">s1\n%s\n" "$(awk 'BEGIN {for (i = 0; i < 6000; i++) printf "A"; print ""}')" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">s1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Cluster different samples, I need same otus id                              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/fzFti9CMuFM
## 2024-12-17
## Q: How to cluster many samples while keeping consistent OTU ids across them?
## A: cluster the pooled reads (e.g. with --relabel) then map per sample; --sample can tag reads with their sample of origin.

## --sample adds a ;sample= annotation to output headers (per-sample tagging)
DESCRIPTION="forum (2024-12-17): --sample annotates output headers with ;sample="
printf ">q1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --derep_fulllength - \
        --sample sampleA \
        --output /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">q1;sample=sampleA" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## --relabel gives clustering centroids consistent, predictable OTU ids
DESCRIPTION="forum (2024-12-17): cluster_size --relabel produces consistent OTU ids"
printf ">a\nACGTACGTACGTACGTACGTACGTACGTACGT\n>b\nGGGGCCCCGGGGCCCCGGGGCCCCGGGGCCCC\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --relabel OTU_ \
        --centroids /dev/stdout \
        --quiet 2> /dev/null | \
    grep -qx ">OTU_1" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Recommendations for clustering ONT reads with variable length?              #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/qs_9Zo6cc8c
## 2025-01-31
## Q: How to cluster variable-length full-length 16S ONT reads?
## A: lower gap-open penalties for noisy reads via --gapopen (e.g. 4I/2E), use ~97% id, skip derep.

## --gapopen accepts the per-context "4I/2E" syntax
DESCRIPTION="forum (2025-01-31): cluster_size accepts --gapopen 4I/2E syntax"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n>r\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --gapopen 4I/2E \
        --centroids /dev/null \
        --quiet 2> /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## an invalid character in the gap penalty string is a fatal error
DESCRIPTION="forum (2025-01-31): --gapopen rejects an invalid penalty character"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n>r\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_size - \
        --id 0.97 \
        --gapopen 4Z \
        --centroids /dev/null 2>&1 | \
    grep -q "Invalid char 'Z' in gap penalty string" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  ASVs vs 97% OTUs when using -usearch_global to create an OTU table          #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/VWeKh1KvPVo
## 2025-08-04
## Q: Does usearch_global --id 0.97 turn ASVs into 97% OTUs, and what does --id do here?
## A: it preserves ASVs (maps reads to them); --id is a mapping threshold and each read is counted once (single best hit).

## usearch_global returns a single hit per query even when several targets tie
DESCRIPTION="forum (2025-08-04): usearch_global returns one hit per query (single best match)"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>t2\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.97 \
        --userfields query+target \
        --userout /dev/stdout \
        --quiet 2> /dev/null | \
    awk 'END {exit (NR == 1) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## a read counted once contributes a total of 1 across the OTU table
DESCRIPTION="forum (2025-08-04): usearch_global --otutabout counts each read once"
printf ">q\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --usearch_global - \
        --db <(printf ">t1\nACGTACGTACGTACGTACGTACGTACGTACGT\n>t2\nACGTACGTACGTACGTACGTACGTACGTACGT\n") \
        --id 0.97 \
        --otutabout /dev/stdout \
        --quiet 2> /dev/null | \
    awk 'NR > 1 {sum += $2} END {exit (sum == 1) ? 0 : 1}' && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#******************************************************************************#
#                                                                              #
#  Pac Bio amplicon clustering                                                 #
#                                                                              #
#******************************************************************************#
##
## https://groups.google.com/g/vsearch-forum/c/6jvZQ_ye0Go
## 2025-09-18
## Q: Best practices for quality filtering, chimera detection, dereplication and clustering of PacBio HiFi reads?
## A: (no answer in the thread; open-ended best-practice request)
## not testable: unanswered open-ended best-practices question, no concrete vsearch behaviour/option/error to pin down


