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
    grep -qi "Illegal unprintable ASCII character no 1" && \
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
    grep -q "unrecognized option '--max_accepts'" && \
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

DESCRIPTION="forum (2016-11-15): --wordlength 15 is accepted by cluster_smallmem"
printf ">s1\nACGTACGTACGTACGTACGTACGTACGTACGT\n" | \
    "${VSEARCH}" \
        --cluster_smallmem - \
        --usersort \
        --id 0.97 \
        --wordlength 15 \
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
    grep -q "unrecognized option '--otus'" && \
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
    grep -q "unrecognized option '--cluster_agg'" && \
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
    wc -l | \
    grep -qx "2" && \
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
    wc -l | \
    grep -qx "1" && \
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
    grep -q "Illegal character '-'" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

DESCRIPTION="forum (2017-10-26): alignment dot '.' is rejected as an illegal character"
printf ">s1\nACG.TACGTACGTACGTACGTACGTACGTACGT\n" | \
    ${VSEARCH} \
        --uchime_denovo - \
        --nonchimeras /dev/null 2>&1 | \
    grep -q "Illegal character '\.'" && \
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


