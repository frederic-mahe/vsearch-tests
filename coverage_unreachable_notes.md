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

## eestats.cc -> src/commands/fastq_eestats2.cpp (re-checked 2026-09-08)
- **531, 571** — `break;` taken when `len_cutoff >
  opt_length_cutoffs_longest` in the `--fastq_eestats2` output (531) and
  log (571) loops. `len_steps` is computed as
  `1 + (min(longest_read, opt_longest) - shortest) / increment`, and
  `--length_cutoffs` validation rejects `shortest > longest`, so the
  largest generated cutoff is always `<= opt_longest`. The break can
  never fire.
  - Still true, but there is now **one** such break, not two:
    `eestats.cc` was split, and the output and log loops were merged
    into the single `report_eestats2()` called once per destination.
    The surviving break is `src/commands/fastq_eestats2.cpp:134`.
  - Re-verified empirically, not just by reading: a build with
    `fatal("INSTRUMENTATION: dead break was taken")` in the branch
    survived the whole `fastq_eestats2.sh` script (97 PASS) and a
    hand-built sweep of read lengths 1..1000 against
    `--length_cutoffs` values `50,100,7`, `10,10,1`, `1,3,5`,
    `1,1000,997`, `40,101,60`, `1,2,1`, `50,*,7` and
    `1,2000000000,999999999`. The branch was never taken.

## getseq.cc
- **113** — `fatal("Unable to get status for labels file (%s)")`.
  Requires `stat()` to fail on a labels file that nonetheless opened;
  not reachable through normal input.

## otutable.cc
- **141, 148, 155** — `fatal("Compilation of regular expression for
  {sample,otu,taxonomy} annotation failed")`. The three regexes are
  fixed string literals that always compile; these `regcomp` failure
  branches cannot be reached.

## Library API never wired to the CLI
Several TUs define a public embedding API (declared in `vsearch_api.h`
and the per-module headers) that no CLI subcommand calls. All of it is
unreachable through black-box tests:
- **search.cc** — `search_session_alloc/free/init/single/cleanup`
  (~1031-1185) and `search_batch_worker_fn`/`search_batch` (~1192-1422).
- **cluster.cc** — `cluster_session_alloc/free/init`,
  `cluster_assign_single/batch`, `cluster_session_cleanup` (~1808-2152).
- **chimera.cc** — `chimera_info_alloc/free`, `chimera_session_*`,
  `chimera_detect_*`, `chimera_batch_*` (~2689-3029); plus the
  `if (ci->result_out != nullptr)` result-struct blocks (~978-1010,
  ~1575-1607), since `result_out` is only set by the API path.
- **derep.cc** — `derep_session_alloc/free/init`, `derep_add_sequence`,
  `derep_get_results`, `derep_session_cleanup` (~969-1123).
- **fastq_mergepairs.cc** — `mergepairs_init/single`, `merge_result_free`
  (~1717-1827).

## searchcore.cc
- **151, 155, 159** — `hit_compare_byid_typed` aligned/unaligned
  difference branches; every compared pair is already aligned, so these
  symmetry branches are never taken.
- **181-241** — `hit_compare_bysize_typed`. Could NOT be triggered even
  with `--cluster_size --sizeorder` and a query matching two distinct
  centroids of different abundance: the best-hit selection does not
  route through this comparator with realistic input. Effectively dead
  for the CLI.
- **251-254** — `hit_compare_bysize` void* wrapper: never referenced.
- **296-297** — `increment_counters_from_bitmap_sse2` non-SSSE3 fallback;
  not selectable on a modern x86_64 host.
- **405, 410** — `trim_{q,t}_right = 0` guards; never true for a real hit.

## cluster.cc (besides the API above)
- **163-168, 189-202** — symmetric tie-break arms of `compare_byclusterno`
  / `compare_byclusterabundance`. libc qsort only ever calls these
  comparators in the operand order that hits the `<` arm for the small,
  unique inputs available; the `>` and `return 0` arms are not
  deterministically reachable.
- **610-624** — `compare_kmersample`: defined but never referenced.
- **676-680, 832-834, 862-863** — `evaluate_extra_hits` same-batch
  extra-hit list edge cases (list filled to maxaccepts+maxrejects-1 in a
  single round); only reachable via a precise multithreaded k-mer
  collision, not deterministic from the CLI.
- **774-793** — SIMD-aligner overflow fallback (`snwscore == SHRT_MAX`);
  see "SIMD overflow" below.
- **1104, 1129-1137** — serial-path branches guarded by `opt_strand > 1`
  / `opt_sizeorder`; `--strand both` is rejected for clustering and the
  sizeorder path is threaded, so these serial branches are shadowed.

## SIMD 16-bit score overflow fallback (multiple TUs)
- **search.cc ~663-676, cluster.cc ~774-793, chimera.cc ~2000-2026** —
  re-alignment with the linear-memory aligner when the vectorised 16-bit
  aligner saturates (`nwscore == SHRT_MAX = 32767`). Requires extremely
  long / high-scoring alignments to overflow; not reproducible with
  small black-box inputs. (Possibly reachable with ~tens-of-kb highly
  similar sequences — unconfirmed.)

## chimera.cc (algorithmic, besides API/SIMD above)
- **375** — `compare_positions` returns 0: needs two parent fragments
  with identical start offsets, which parent selection avoids.
- **441** — `scan_matches` returns false (`best_c < 0`): a candidate is
  only present because it matched during search, guaranteeing >= 1 match.
- **1930-1934** — frees alignment for accepted hits beyond
  `maxcandidates`; the small `few`/`rejects` caps make this unreachable.
- **2458** — `fatal("Internal error")` in the denovo branch: entering the
  branch already implies one of the option pointers is set.

## derep family / db / dbhash / dbindex (hash-collision & qsort tails)
- **derep.cc 201/205/237, 512-513; derep_smallmem.cc 138/163/171,
  379-380, 586-587; derep_prefix.cc 273-276, 317; dbhash.cc 149-150** —
  linear-probe wraparound and "deleted"/median branches reachable only on
  a hash collision or marked `// unreachable` in the source. Not
  constructible deterministically with small inputs.
- **db.cc 483-490, 529-533, 563-567** — final pointer tie-break arms of
  the `compare_by{length,abundance}` comparators; value-equivalent to the
  covered `<` arm and not forceable via qsort operand order.
- **db.cc 95-107 (`db_init`), 412-413 (`db_getlongestheader`)** — getters
  / initializers not called by any covered command path.
- **dbindex.cc 220** — `bitmap_mincount = seqcount + 1` (`use_bitmap == 0`);
  covered commands always prepare the index with the bitmap enabled.
- **unique.cc 152-166 (`unique_compare`)** — defined but never referenced;
  269-277 / 393-405 are `wordlength >= 10` hash-grow paths not used by the
  covered commands.

## udb.cc
- **110-114** — `>`/equal tails of the kmer comparator (build data never
  hits them).
- **154-158** — `largewrite(..., seek=true)`; all CLI writers pass
  `seek=false`.
- **202, 229, 314, 320, 377, 395, 417, 463, 470, 479, 588, 609, 1041** —
  I/O-open / OOM fatals and "Invalid UDB file" checks that need a corrupt
  binary UDB crafted at precise byte offsets, or a zero-sequence UDB that
  earlier header validation already rejects. Impractical/brittle to test.

## fastq_mergepairs.cc (besides API above)
- **430** — `%.13lf` branch for merged EE < 1e-9: unreachable, the
  smallest achievable per-read EE (Q93 over the 5 bp minimum overlap) is
  ~2.5e-9 > 1e-9.
- **512-517, 547-549, 1431-1434, 1529-1532** — `Reason::ok` /
  `Reason::undefined` / `Reason::indel` switch cases. `ok` reads are never
  discarded, `undefined` is always overwritten before use, and `indel` is
  never assigned anywhere in the source.
- **1177** — `finished_all = true` reader-thread branch: a thread-timing
  race, not deterministically triggerable.

## msa.cc
- **134-135, 394-395** — `default: break` in the profile-update and
  cigar-operation switches; DB sequences are normalised to
  A/C/G/T/U/ambiguity/gap and cigars contain only M/D/I.
- **364-365** — gap padding inside `case 'D'` when the deletion run is
  shorter than the max insertion at the same query position; not
  produced by simple clusters (no minimal robust input found).

## results.cc
- **107, 159, 186** — `if (hits == nullptr) return;` guards in
  `results_show_{fastapairs,qsegout,tsegout}_one`. A no-hit query is not
  routed to these fasta-pairs/segment writers (even with
  `--output_no_hits`), so the guard is not reachable in practice.
- **630-631** — `if (tophitcount == 0) { fprintf("\n"); return; }` in
  the LCA writer; `--lcaout` is not invoked for a query with zero hits.

## Coverage-snapshot staleness (NOT unreachable — already covered)
The gcov snapshot under `/tmp/vsearch/src/` predates some current tests,
so a few lines it marks `#####` are in fact already covered by existing
tests. No new test was added for these:
- **derep.cc 226-235** (`derep_compare_full` `seqno_first` tie-break) is
  covered by `derep_fulllength.sh` "sort clusters by input order"
  (line 236 there, `return 0`, is genuinely `// unreachable`).
- **fastq_mergepairs.cc 436** (`%.10lf` EE branch, 1e-7 <= EE < 1e-6) is
  covered by `fastq_mergepairs.sh` "EE = 0.0000001".
When working from this snapshot, grep the test scripts before adding a
test, and confirm the target line actually flips on the instrumented
binary at `/tmp/vsearch/bin/vsearch`.
