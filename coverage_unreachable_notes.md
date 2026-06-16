# Unreachable / dead code found during coverage work

This list records lines that gcov reports as uncovered but that **cannot
be reached by any black-box test** (given current vsearch behaviour).
They are candidates for code review: either remove the dead code, turn
defensive checks into asserts, or document why they are kept.

Line numbers refer to the source used for the coverage run under
`/tmp/vsearch/src/` (vsearch v2.31.0). They may drift as the code
changes.

## fastq.cc
- **204, 210, 214** — `fastq_fatal()` out-of-memory branches (`xsprintf`
  failure / null string). Not triggerable from input.
- **245-249** — `case 0:` (strip-with-warning) in `buffer_filter_extend`.
  No byte in either `char_fq_action_seq` or `char_fq_action_qual` maps to
  action `0`; the case is dead. (Stripping in FASTQ uses action `3`,
  "silently stripped".)
- **336** — `fastq_fatal(... "Header line must start with '@' character")`.
  The quality-reading loop in `fastq_next` only stops at a record
  boundary when the next byte is `@` *and* quality/sequence lengths
  match; otherwise it consumes the line as quality and fails on a
  length mismatch first. So `fastq_next` is always re-entered positioned
  on `@`, and the `!= '@'` check can never be true. Defensive only.
- **652-655** — `fastq_get_abundance_and_presence()`: declared in
  fastq.h, never called.
- **659-663** — `fprint_seq_label()`: unused twin of the identical
  function in fasta.cc; never called.
- **762-767** — `fastq_print()`: declared in fastq.h, never called.

## fasta.cc
- **265-266** — `fprintf(stderr, "Found character ...")` /
  `fatal("Invalid FASTA - header must start with > character")`. Format
  auto-detection rejects a non-`>` first byte with "File type not
  recognized." before `fasta_parse` runs, so this defensive check is
  never reached.
- **379** — `fasta_get_lineno()` (and `fastx_get_lineno()` in fastx.cc):
  no callers.
- **628** — `fasta_print_db()` (the non-relabel variant): no callers;
  only `fasta_print_db_relabel()` is used.

## eestats.cc
- **531, 571** — `break;` taken when `len_cutoff >
  opt_length_cutoffs_longest` in the `--fastq_eestats2` output (531) and
  log (571) loops. `len_steps` is computed as
  `1 + (min(longest_read, opt_longest) - shortest) / increment`, and
  `--length_cutoffs` validation rejects `shortest > longest`, so the
  largest generated cutoff is always `<= opt_longest`. The break can
  never fire.

## getseq.cc
- **113** — `fatal("Unable to get status for labels file (%s)")`.
  Requires `stat()` to fail on a labels file that nonetheless opened;
  not reachable through normal input.

## otutable.cc
- **141, 148, 155** — `fatal("Compilation of regular expression for
  {sample,otu,taxonomy} annotation failed")`. The three regexes are
  fixed string literals that always compile; these `regcomp` failure
  branches cannot be reached.
