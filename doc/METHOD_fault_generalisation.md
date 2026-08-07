# Fault generalisation — the loop, and what testing it actually showed

*Recorded 2026-08-08, after an eight-agent test with pre-registered predictions.*

## The loop

1. Understand ONE artifact deeply.
2. Find something wrong.
3. **Name the fault as a mechanism, not a symptom.** "The picture has static" generalises to
   nothing. "A texture feature landed below one pixel" is a query. This rewording is the
   whole step that turns a case into something askable.
4. Ask the corpus how many others have it.
5. Verify the query before believing the count.
6. Fix the class, add a guard, record a baseline.

## The hypothesis that was tested

> If a fault generalises, it is usually because a **shared instrument** permitted it.
> If it is unique, it is usually a real quirk of that one artifact.

Eight agents, eight artifacts across eight categories, none touched by the session that
proposed the heuristic. Each had to write `predicted_layer` and `predicted_count` **before**
running any corpus query. Pre-registration is what makes it a test rather than a story.

## Results

| | |
|---|---|
| count predicted within 50% | **2 / 8** |
| layer prediction matched the spread | **6 / 8** |
| agents finding no fault | **0 / 8** |

**Magnitude prediction is worthless.** Misses ran in both directions and were large:
`env_one` predicted 35, measured 156; `newton_cradle` 168 → 523; `path_cube` 300 → 702;
`fontana_puncture` 10 → 1; `crystal_cluster` 30 → 6. Nobody should be asked to estimate how
many artifacts share a fault. Ask the corpus instead — it is cheap, which is the entire point.

**The layer call is decent but the test was primed.** 6 of 8 predicted `shared_instrument`,
and the brief handed them two shared-instrument examples (17 and 70 hits) against one
artifact-local example (1 hit). A brief that leads 2:1 gets a 6:2 answer. The 6/8 should be
read as "not refuted", not as "confirmed".

**Nobody returned a null, and that is a warning.** Agents were told explicitly that
`fault_found: false` is a good data point, and all eight still found something. Either the
corpus is faulty nearly everywhere — possible, several findings are well evidenced — or the
method has a find-something bias. Until a run produces a null, treat every count as an upper
bound.

## The refinement the test produced

The `line_builder_3d` agent got the count exactly right (7 predicted, 7 measured) and the
layer wrong, and its explanation is better than the hypothesis it was testing:

> No shared instrument manufactured these; three authors independently wrote `randf` into a
> per-frame material write. What the shared instrument did is subtler: it made the fault
> **unfalsifiable**. Every gate in this project photographs a single still, so a temporal
> defect cannot be scored by the sweep, the critic, or the gallery.

That is a third category the original heuristic did not have:

| category | the instrument's role | example |
|---|---|---|
| instrument **caused** it | a fallback or default manufactured the fault | the gate resolving scripts by FILENAME — cctv, 17 artifacts |
| instrument **cannot see** it | the fault is real and structurally unmeasurable | every quality gate is a single still, so per-frame flicker is unscoreable — 7 artifacts |
| genuinely **local** | a real quirk of one body | dome's grain sized wrong for its own extent — 1 artifact |

The middle row is the dangerous one, because it accumulates silently and no amount of running
the existing gates will ever surface it. Worse, in `line_builder_3d` the sanctioned harness
fix — a seed export plus `dna.fixture`, listed in CLAUDE.md as the cure for unseeded `randf`
— had been used to branch *around* the flicker on the measurement path, leaving the bench
clean and all 72 placements dirty.

## The step that is actually hard

Not step 3. Step 4, and every agent that produced a trustworthy number got there by being
wrong first and tightening by hand:

> v1 `random + material write in the same function` → **67** tokens. Collapsed on reading:
> `spawn_flower`, `_spawn_boid`, `_grow_tree` randomise a colour ONCE for a NEW node.
> v2 add "reachable through unconditional call sites" → **18**. Still lying: `phase_cube`
> has `randf` feeding rotation speed while the material write uses a deterministic colour.
> v3 require one-hop **dataflow** — the material write's RHS is tainted by the random → **11**.
> Then hand-read all 11 and reject four more. → **7**.
>
> "Same-function co-occurrence is not the predicate. Dataflow is. If I had reported 67, or
> even 18, I would have published a fact about my regex."

That is the finding to carry: **the first query is always wrong, and it is wrong in the
direction of over-reporting.** Budget two or three tightenings with hand-verification between
them. A count nobody opened by hand is not a result.

The orchestrator repeated the lesson while checking this write-up: the WorldEnvironment class
was reported as 156 and an independent query counted 105, and one cited example
(`triangle.tscn`) turned out to contain no `WorldEnvironment` at all. The class is real and
large; the exact number is a property of the query.

## What to keep

- The loop is sound in shape. Its value is that asking is cheap and a negative answer is a
  result — two of this session's four probes returned 1, which is what stops a one-off being
  mistaken for a pattern.
- Predict the **layer**, never the count.
- Add the third category: ask not only "what caused this" but "what could never have seen this".
- Treat the query as an instrument. It will lie exactly like the others, and only hand-reading
  its hits catches it.
- Watch for find-something bias until a run returns a null.

## Related

- `tools/corpus_probes.py` — the cases from this session as standing queries, with baselines
- `tools/axis_vocabulary_research.py` — the same method aimed at a claim the project makes about itself
- `tools/check_dna_declarations.py` — where a confirmed class becomes a gate rather than a probe
