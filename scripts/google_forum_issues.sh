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


