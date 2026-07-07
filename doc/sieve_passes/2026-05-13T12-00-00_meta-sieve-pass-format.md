# Sieve pass — meta: the sieve-pass document convention

_Recorded 2026-05-13T12:00:00_

**Target:** the conventions of `doc/sieve_passes/*.md` themselves. After tonight produced ten sieve documents and the realisation that the *propose, hold, return* mechanism was failing structurally (see [The hold collapsed](/blog/2026-05-13-the-hold-collapsed)), the meta-question: **is the sieve-pass document format itself adequate to the work it now has to support?**

This pass exists to (a) test the new substrate (parser + chip UI + pause primitive) without risking a real reorder, and (b) audit the sieve format reflexively, which the three-question sieve has not yet been turned against.

## 1. The claim

Each sieve pass document is a recorded artifact with implicit invariants:
- A heading like *"# Sieve pass — ..."*
- The three questions answered (Q1 thicken, Q2 foreclose, Q3 dark spot)
- A *"Reorder candidates"* table when structural moves are proposed
- A *"Verdict"* section
- A *"Load-bearing rule out"* one-liner at the bottom

The format claims: *"a sieve pass is recoverable from its document; future sessions can read what was concluded and what was proposed, without re-running the sieve."*

## 2. The trace

Ten passes recorded today:
- 2 morning sieves: math-density, catalyst-arsenal-mapping
- 5 phase sieves: oscillation, E_entropy, lambda-edge, integration, synthesis
- 1 macro sieve: QFEP-arc
- 1 verification pass: after-reorder
- 1 master change list

Document size ranges from ~5 KB (verification) to ~18 KB (math-density). The "Reorder candidates" table format is used by 4 of 10 passes. The other 6 vary:
- macro-qfep-arc: uses subsection lists rather than a table
- master-change-list: uses tables with different schema (change/from/to but also "files touched")
- verification-pass: has a summary table not under "Reorder candidates"
- build-complete: file-listing, not reorder
- two morning sieves: section-oriented prose, no reorder table

The new parser found 13 proposals across the 4 sieves that use the canonical table. **6 of 10 sieves are invisible to the chip system.** That's a structural finding.

## 3. Per-document reading

| pass | format used | parser sees | gap |
|---|---|---|---|
| morning math-density | prose recommendations | ❌ | proposals are in section 6 but not tabular |
| morning catalyst-arsenal | prose recommendations | ❌ | "Recommendations" section is prose |
| phase-oscillation | no reorder candidates section | n/a | passes with no structural move |
| phase-e-entropy | table | ✓ | CA → λ_edge captured |
| phase-lambda-edge | table | ✓ | 3 moves captured |
| phase-integration | table | ✓ | 3 moves captured |
| phase-synthesis | table | ✓ | 6 moves captured |
| macro-qfep-arc | subsection list | ❌ | the macro's 7-move summary is in 6a as bullets, not table |
| verification-pass | inline summary table | ❌ | section titled "The reorder summary (one place)", not "Reorder candidates" |
| master-change-list | extended tables | partial | tables exist but different schema |
| build-complete | file listing | n/a | retrospective, not proposal |

## 4. Cross-document (the format as a format)

Two structural issues surface.

**Issue A — table-or-prose drift.** The "Reorder candidates" table is canonical in phase sieves but informal everywhere else. The macro sieve, where the *integrated* reorder lives, doesn't use the table — its 7 moves are scattered across subsection lists ("Move 1: …", "Move 2: …"). This is the most consequential pass and the parser cannot see it. The seven moves that actually applied tonight are nowhere as machine-readable records *unless* backfilled (which we did, but only because we hand-mapped each one).

**Issue B — header naming drift.** "Reorder candidates" is one specific phrase. Adjacent docs use "The reorder summary," "Reorder summary (one place)," "Reorder candidates," "Reorder moves." The parser hard-codes the canonical phrase. Other valid sieves with valid recommendations are silently invisible.

## 5. Three-question sieve

### Q1 — Does this format thicken the cognitive water?

It does, partially. The table form is concise and surfaces the *change / from / to / impact* shape clearly. Future sessions reading these passes can scan the tables and see what was proposed without reading prose. The 4 phase sieves that follow the convention are very readable.

But the thickening is *uneven*. The macro pass — which integrates all the phase sieves into actionable moves — is in prose. That's where the thickening should be densest. The most important pass to be machine-readable is the one least machine-readable.

### Q2 — What is foreclosed?

Three things:

- **Multi-effect moves.** The table has columns change/from/to/impact. A move that touches *multiple files* (e.g., tonight's CA move touched the spine, the soft_stages, the sequence file, and the layer field) gets compressed into one row that under-reports the actual edits. The apply script has to reconstruct the file set; the table doesn't list it.
- **Conditional moves.** A move like *"apply X only if Y already happened"* has no place. The integration sieve's `graphtheory` move depended on `swarmintelligence` having moved first. The table doesn't express ordering.
- **Phase-truth and new-phase moves.** Tonight's pass added a new phase (`relation`) and 7 phase truth statements. None of these fit the change/from/to schema cleanly. They show up as one row each saying "unwritten → written" which is unhelpful.

### Q3 — What lives in the dark spot?

The dark spot is **what counts as a "move."** The table format implies that every actionable thing is a single discrete change. But sieves often produce conclusions like *"the player needs to feel resonance"* — a directional recommendation that doesn't reduce to one JSON edit. These live in section 6 of the synthesis sieve, get noted in the verdict, then disappear from any tracking. The chip system can't surface them because they're not moves.

This is generative habitat as long as the prose stays rich. It becomes sterilising the moment we start treating the chip table as the sieve's *output* and the rest as commentary.

## 6. Recommendations

### 6a. Standardise the "Reorder candidates" header phrase

Move the parser to accept multiple equivalent phrases (`Reorder candidates`, `Reorder summary`, `Structural moves`, `Apply set`). Or, more cleanly, **add a sibling document** alongside each sieve pass: `{pass_id}_moves.yaml` with explicit structured records. That separates structured moves from prose-bound recommendations.

### 6b. Promote the macro pass to first-class structured table

The macro QFEP-arc sieve had a "## 6a. Apply the reorder (this session)" subsection with seven numbered moves in prose. Tonight's apply was driven from this section. Going forward, that section MUST be the "Reorder candidates" table — same schema as phase sieves — so the parser sees the canonical apply set without having to read prose.

### 6c. Add a "Files touched" column to the table

The current schema (change / from / to / impact) under-reports. Add `files` column listing the JSON files the move will edit. The apply script then doesn't have to infer.

### 6d. Distinguish three move classes in the schema

Move "kind" column: `phase` | `order` | `layer` | `unlock` | `truth_write` | `new_phase` | `manual`. Lets the chip UI show the right action set and lets the apply script dispatch correctly.

### 6e. Track conditional dependencies

Optional `depends_on: [other-move-id]` column. If `graphtheory-1` depends on `swarmintelligence-0`, the UI greys out graphtheory's apply button until swarm is applied.

## 7. Reorder candidates

These are recommendations about the *document format*, not about the curriculum. The chip UI will surface them as actionable proposals; Palle decides whether to commit each.

| change | from | to | impact |
|---|---|---|---|
| **sieve_proposals.py parser** | hard-coded "Reorder candidates" header | accept aliases (Reorder summary, Structural moves, Apply set) | low — parser-only change |
| **macro-qfep-arc sieve** | section 6a as numbered bullet list | rewrite as canonical Reorder candidates table | medium — historical doc edit, plus parser re-run picks up 7 new chips |
| **table schema** | change / from / to / impact | add files (listing affected JSON paths) and kind (phase/order/layer/unlock/truth_write/new_phase/manual) | medium — schema change, requires parser update |
| **morning sieve recommendations** | prose-only | add Reorder candidates table where appropriate | low — backfill cosmetic, no behaviour change |

## 8. Verdict

The sieve-pass format passes under three light refactors:

1. Parser accepts header aliases (1-line code change).
2. Macro sieves and verification sieves use the canonical table — going forward, by convention; backfill optional.
3. Table schema gains `files` and `kind` columns to compress what the apply script currently has to infer.

Tonight's substrate proves the convention can be tightened without losing the prose richness — the chip UI surfaces the *table* part, the rationale excerpt surfaces the *prose* part, and the dark-spot/foreclose discussion stays in the document body where it belongs.

The four chips above will surface in `/sieve-proposals` for explicit review. **Apply, defer, or reject each.** I will not apply them. The hold mechanism is now actually held.

Load-bearing rule out:

> **A research format earns its persistence by making the next session's work easier than the last.** Tonight's format was good prose. The new substrate asks it to also be good structured data. The two are compatible — prose for the rationale, table for the move set — but only if the table is in every sieve, in the same shape. The substrate's first finding is to ask the format to be consistent enough that the substrate can see it.
