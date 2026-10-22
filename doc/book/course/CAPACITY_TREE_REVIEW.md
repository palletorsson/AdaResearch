# The capacity tree: what it draws, where its progress comes from, how to improve it

19 October 2026. A review of `localhost:3003/capacity-tree#view=tree&seq=all` made from the
files that feed it. Measured with `python tools/capacity_progress.py`; the numbers below are
that run, and they go stale the moment a tutorial changes. Re-run before quoting.

**What could not be read.** The page itself is not in either repository as pushed. The
encyclopedia's GitHub copy was last pushed on 25 July 2026 and has none of the October
surfaces (`/tutorial-lineage`, `/tutorial-cards`, `/tutorial-plan`, `/project-memory`,
`/capacity-tree`). This review therefore reconstructs the page from its data layers and from
its four predecessors, all of which are documented here. Where it says what the page shows,
read "what the data lets it show".

## 1. Where "capacity" comes from

Five surfaces were built in eleven days. Each added a layer and a new word for "done".

| date | surface | authored file | its word for done |
|---|---|---|---|
| 29 Sept | `/tutorial-lineage` (Tree · Walk · Gaps, `#view=`) | `doc/book/tutorial-lineage/curriculum.json`: 72 capability nodes, `requires` edges | node `status`: proposed · desktop-tested · implemented_unverified_learner |
| 4 Oct | `/project-memory` | `doc/book/memory/state.json` + `history/`: findings with source fingerprints | finding `status`: proposed · accepted · dismissed |
| 4 Oct | whole-spine capacity review | `doc/book/iterations/2026-10-04-whole-spine-capacity/`: the 8-step chain *Receive and distinguish → … → Question and revise* | editorial; three capacities (perceptual, making, critical) |
| 5 Oct | `/tutorial-cards` + lineage | `doc/book/course/hall-cards/lineage-{opening,middle,later}.json`, `state.json` | hall `status`: aligned · needs_revision · missing; a saved card = author chose |
| 5–6 Oct | `/tutorial-plan` (`?view=sequences&seq=`) | `doc/book/course/execution-plan/plan.json`: 207 lessons, 25 sequence capacities, 116 topics | lesson choice: draft · accepted · revise · deferred; `checks` empty or not |

The tree view with a sequence filter is the shape all five share. `#view=tree&seq=all` is the
lineage atlas's hash state plus the plan's `seq=` filter: a tree of sequences → halls →
capabilities, over all 25 sequences. The sequence capacity sentences themselves are the 25
entries of `SEQUENCES` in `execution-plan/seed.py` (capacity · continuing object · exit
demonstration · note), and the 8-step chain in the whole-spine review groups those 25 into
the arc the tree should read as.

## 2. The progress, measured today

Live spine: **25 sequences, 206 halls** (CLAUDE.md still says 24; the October docs say 207;
Pattern_Temple entered on 9 October, two Forces halls left).

One evidence rung per hall, the highest any file supports. It is a floor, not a grade.

| rung | meaning | halls |
|---|---|---|
| none | no `tutorial.md` | 10 |
| written | tutorial exists; lineage says the focus still needs revision | 122 |
| focused | lineage says aligned, or the author saved a focus on the card | 69 |
| contracted | `plan.json` lesson has behaviour checks | unknown: `plan.json` is not in git |
| runs | a current native ghost state exists | 5 |
| learner | observed learner work | 0: no file records this |

The five halls that run are Point One (60 checks), Point Coordinates (46), Point Lines (170),
Point Trace (134) and Point Line Grid (53), from the 6 October `trace-saved-to-grid` record.
Point Zero has separate counter evidence that no index lists.

Per sequence (`python tools/capacity_progress.py --markdown`):

| # | sequence | halls | none | written | focused | runs | ladder nodes | tutorials changed since 5 Oct |
|---|---|---|---|---|---|---|---|---|
| 1 | primitives | 15 | 0 | 0 | 10 | 5 | 13 | 15 |
| 2 | transformation | 7 | 0 | 4 | 3 | 0 | 4 | 2 |
| 3 | array_tutorial | 5 | 1 | 4 | 0 | 0 | 3 | |
| 4 | color | 8 | 0 | 5 | 3 | 0 | 4 | |
| 5 | tiling | 9 | 4 | 1 | 4 | 0 | 2 | 1 |
| 6 | change | 2 | 0 | 2 | 0 | 0 | 2 | 2 |
| 7 | forces | 11 | 0 | 6 | 5 | 0 | 3 | 11 |
| 8 | formfinding | 6 | 0 | 5 | 1 | 0 | 3 | 3 |
| 9 | wavefunctions | 12 | 0 | 8 | 4 | 0 | 4 | 12 |
| 10 | randomness | 14 | 0 | 8 | 6 | 0 | 2 | 1 |
| 11 | noise | 9 | 0 | 7 | 2 | 0 | 2 | 3 |
| 12 | shaders | 6 | 3 | 3 | 0 | 0 | 2 | 1 |
| 13 | cellularautomata | 8 | 0 | 8 | 0 | 0 | 2 | 8 |
| 14 | fractals | 7 | 0 | 6 | 1 | 0 | 1 | 7 |
| 15 | lsystems | 8 | 1 | 5 | 2 | 0 | 3 | 1 |
| 16 | proceduralgeneration | 7 | 0 | 7 | 0 | 0 | 2 | |
| 17 | softbodies | 9 | 0 | 4 | 5 | 0 | 2 | |
| 18 | isosurfaces | 13 | 1 | 5 | 7 | 0 | 2 | |
| 19 | boolean_surfaces | 3 | 0 | 1 | 2 | 0 | 1 | 1 |
| 20 | swarmintelligence | 7 | 0 | 5 | 2 | 0 | 2 | |
| 21 | machinelearning | 8 | 0 | 6 | 2 | 0 | 3 | |
| 22 | graphtheory | 8 | 0 | 6 | 2 | 0 | 2 | |
| 23 | foundationscrisis | 8 | 0 | 7 | 1 | 0 | 2 | 8 |
| 24 | qfeplaboratory | 8 | 0 | 6 | 2 | 0 | 2 | |
| 25 | postfoundationscrisis | 8 | 0 | 3 | 5 | 0 | 2 | |
| | all | 206 | 10 | 122 | 69 | 5 | 70 | 76 |

The other layers, read the same day:

- **Capability ladder** (`curriculum.json`): 72 nodes, 70 still `proposed`, one
  `desktop-tested` (line), one `implemented_unverified_learner` (sweep). Nothing has moved
  since 29 September except those two. Four live halls belong to no node (Pattern_Temple,
  Primitives_Columns, Primitives_Godot, Primitives_Profiles); two nodes point at halls that
  are no longer in the spine (VFM_02_Operations, Vectors_Act2_VectorArithmetic).
- **Hall lineage**: 74 aligned · 121 need revision · 10 missing · 1 unrecorded. The
  published headline in `LINEAGE.md` and `lineage-verification.json` still says 65 · 132.
  The files moved on 6 October; the headline did not.
- **Saved author focus**: 13 cards, all Primitives plus Trans_Pre. Last save 6 October.
- **Execution plan**: `validation.json` (5–6 October) records 30 concrete contracts, 177
  unresolved, and one changed protected source. Checked live today, **242 of 637 protected
  sources have changed** without a recorded revision (the 11 October book passes rewrote
  `final.md` across sequences). The plan's own gate would fail on this checkout.
- **Project memory**: revision 56, 4 October 18:29. 36 findings, 27 accepted, 9 proposed.
  The proposed ones are the Change and Forces revisions and the whole-spine review itself.
  Nothing has been written to memory since.
- **Installed studies** (`recent-studies.json`): 19 in 16 halls, one with a new capability.
- **Pipeline scorer** (LOD discovery, 14 October): stage 7 polish is 100 % on all 25
  sequences; stage 6 (VR SEND) is the single head on 24 of 25.

So the honest sentence is: the course has a chosen focus in a third of its halls, a running
reconstruction in five, a measured hand-off in one pair (Trace → Grid), and no learner
observation anywhere. The plan and memory layers stopped on 4 and 6 October; the hall texts
kept moving through 15 October, so the plan's fingerprints no longer describe the texts.

## 3. What the tree cannot show as it stands

1. **Five vocabularies, one picture.** A hall can be `aligned`, `proposed`, `draft`,
   `accepted` and `current` at the same time, in five files. The tree has to pick one colour
   per node, and whichever it picks hides four. Nothing in the data says which is
   authoritative.
2. **Half its sources live on one machine.** `plan.json`, `memory/state.json` and the
   `early/growth/later.json` storyboards are named as authoritative by their READMEs and are
   not in git. They are not gitignored; they were never committed. The encyclopedia pages that
   read them are also unpushed. Any progress the tree shows from these is unverifiable from a
   clone and will be lost with that disk.
3. **Fingerprints are line-ending bound.** The lineage and plan records hash CRLF bytes from a
   Windows checkout. On an LF clone 101 of 195 tutorial fingerprints only match after
   normalising; a naive comparison reports 177 changed tutorials where 76 actually changed.
   A freshness badge computed that way lies on every machine but one.
4. **Headlines are pasted, not computed.** 65/132 (lineage), 207 halls (plan), 24 sequences
   (CLAUDE.md) are all wrong today. Every number the page prints should be recomputed on read.
5. **Edges mean nothing yet.** The ladder's `requires` and the lineage's `builds_on` /
   `carries` give the tree its edges, but one hand-off has been tested (Trace saves, Grid
   receives, 10 shared producer assertions) and the rest are proposals. Drawn the same way,
   they read the same way.
6. **Spine drift is silent.** Pattern_Temple is in the spine and in no layer; two Forces halls
   are in the layers and not in the spine. The lineage builder asserts equality and would
   refuse to run; the page has no such refusal and will draw a tree of 207 over a spine of 206.

## 4. Improvements, in the order I would make them

Each is tied to a fact above. None needs a new permission or a runtime change.

1. **One evidence rung per node, computed from files.** Use the six-rung ladder in §2 (or
   amend it) as the node's fill. Keep every underlying flag in the tooltip so the five
   vocabularies stay inspectable; the rung is the summary, not a replacement. No percentage:
   the rungs are not additive, and a room that chiefly composes (Melencolia) is not a deficit
   at `focused`. Give such halls their `kind` from the ladder (`reflect`, `compare`) and cap
   the ladder visibly rather than count them as missing work.
2. **Read one committed JSON, do not re-derive in TypeScript.** `tools/capacity_progress.py`
   now writes `doc/reports/capacity_progress.json` with per-hall flags, per-sequence counts,
   drift and the list of absent authoritative files. The page should read that and nothing
   else. This repo already paid for the alternative once: `long_museum.py` re-derived hall
   geometry in Python and drifted 16 % from the engine while its check stayed green. A second
   implementation of the rung rule will drift the same way.
3. **Show drift before progress.** At the top of `seq=all`: halls in spine but unknown, halls
   known but gone, tutorials changed since the lineage read them (76), protected sources
   changed since the plan was sealed (242), authoritative files absent (5). A tree that shows
   progress over stale fingerprints is the `operations_gallery` case: every stage green, the
   verdict a fact about a typo.
4. **Normalise fingerprints.** Compare raw, CRLF and LF bytes; record which matched. The tool
   does this; `build_lineage.py` and `validate.py` do not, and will disagree with the page
   across machines until they do.
5. **Commit the authoritative layer, or declare it derived.** `plan.json`, `memory/state.json`,
   the three storyboard files, and the encyclopedia's October routes. The CLAUDE.md rule for
   the museum applies: what is authored is tracked; what is derived has a producer and a
   rebuild command. Right now these are authored and untracked, which is the worst square.
6. **Draw two kinds of edge.** Proposed carries (lineage `builds_on`, ladder `requires`) as
   thin lines; tested carries as solid, with the assertion count. Today that is one edge,
   Trace → Grid. Making it visibly alone is the point: the tree should make the next tested
   hand-off (Lines → Trace → Grid together, per the 5 October anchor) look like the obvious
   move.
7. **Make `seq=all` a row per sequence.** Rung counts, the sequence capacity sentence from
   `seed.py`, which of the eight chain steps it belongs to, and its proposed next pass
   (ladder `priority`, memory `proposed` findings, plan "Next passes"). Click → `seq=<id>`
   keeping `view`. Add `rung=<name>` and `node=<id>` to the hash so a pass can be linked.
8. **Refuse to draw over a mismatched spine.** If live halls ≠ data halls, show the diff and
   stop, as `build_lineage.py` does. `python tools/capacity_progress.py --check` exits 1 on
   exactly this and on absent authoritative files; it can gate a rebuild.
9. **Fix the pasted numbers at source.** Re-run `build_lineage.py` (it will fail on the 76
   changed tutorials, which is correct) and re-publish the 74/121 headline; update the
   ladder's halls for Pattern_Temple and the two Forces removals; correct CLAUDE.md to 25
   sequences.

## 5. Sieve

**Does this thicken the cognitive water?** One rung vocabulary gives relational handles the
five files do not: which hall feeds which, with what evidence, and where the single tested
hand-off is. Drift shown first makes the gap between what was sealed and what is on disk a
thing to think with rather than a surprise two sessions later.

**What is foreclosed?** A ladder invites a scoreboard. Rungs can read reflective halls as
deficits, and "author saved a focus" is not "the text supports it", yet both land on
`focused`. Ranking sequences by rung would be wrong; the table above is deliberately in spine
order. Mitigation: keep the raw flags visible, cap reflective halls by `kind`, print counts,
never a percentage.

**What lives in the dark spot?** The `learner` rung. It has no file and is always zero: the
one thing the course exists for is the one the tree cannot see. Keep the empty column. The
tree also measures making capacity only; the whole-spine review names perceptual and critical
capacity as well, and `final.md` carries those. The tree should say so in its legend rather
than let an all-`runs` Primitives row imply the sequence is done.

## 6. Open questions for Palle

- Is `/capacity-tree` committed in the encyclopedia? Its GitHub copy stops at 25 July.
- Commit `plan.json`, `memory/state.json` and the three storyboard files, or name them derived
  with a producer? They are the authoritative layer and exist on one disk.
- Which vocabulary is authoritative for a node's colour until the rung exists?
- The 242 changed protected sources: record them as authorized revisions (the 11 October book
  passes were requested work) or re-seal the baseline?

## Files

- `tools/capacity_progress.py`: the measurement. `--markdown` for the table, `--seq=<id>` per
  hall, `--check` for a gate. Writes `doc/reports/capacity_progress.json`.
- Predecessors: `doc/book/tutorial-lineage/README.md`, `doc/book/course/hall-cards/README.md`,
  `doc/book/course/execution-plan/README.md`, `doc/book/memory/README.md`,
  `doc/book/iterations/2026-10-04-whole-spine-capacity/OVERVIEW.md`.
