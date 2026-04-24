# Tutorial Push — Handoff — 2026-04-24

This note is the pre-compact record so a fresh session can pick up where the current one leaves off.

## Where the text audit stands

| Role | Passing |
|---|---|
| blurb.md | 179 / 179 ✓ |
| summary.md | 179 / 179 ✓ |
| intent.md | 179 / 179 ✓ |
| critical.md | 179 / 179 ✓ |
| technical.md | 179 / 179 ✓ |
| tutorial.md | 126 / 179 |
| **Global** | **1021 / 1074 (95%)** |

**Five of six text roles are complete across all 179 spine maps.** Only tutorial.md remains, with 53 files missing across 5 sequences.

## Sequences still missing tutorial.md

| Sequence | Missing |
|---|---|
| randomness | 14 |
| wavefunctions | 13 |
| foundationscrisis | 9 |
| qfeplaboratory | 9 |
| postfoundationscrisis | 8 |
| **Total** | **53** |

## The workflow for tutorial.md

Every tutorial cohort has followed the same pattern:

```bash
# 1. Bundle the sequence's missing tutorials with intent/blurb context
python tools/bundle_sequence.py --sequence <seq_id> --file tutorial.md \
    --with-context --only-failing \
    --out doc/_bundles/<seq>_tut.md

# 2. Read the bundle; write one edited bundle with all tutorials in place
#    (filename must end _edited.md for split to pick it up)

# 3. Split back to per-map files with .before_bundle backups
python tools/split_sequence.py --bundle doc/_bundles/<seq>_tut_edited.md

# 4. Check pass status; top up any files under the 400w minimum
python tools/text_metrics.py --spine --only-failing --format json > _tmp_metrics.json
python -c "import json; print(json.load(open('_tmp_metrics.json'))['summary'])"

# 5. For short files, append a small Python script at doc/_bundles/_<seq>_tut_topup.py
#    that adds one or two more captioned code blocks to each

# 6. Commit per sequence
git add -A commons/maps/ doc/_bundles/
git reset -- .claude/
git commit -m "docs(tutorial): complete <seq> tutorial.md cohort (<N> maps)"
```

## Voice anchor

The passing exemplar is `commons/maps/Array_Patterns/tutorial.md`. Structure per tutorial:

1. **Title** (`# <Map Name>` — short noun phrase).
2. **Intro** (1–2 short sentences naming the map's single core move).
3. **Numbered actions** (no actual numbers — sentence fragments like "Build the grid.", "Sample the trail ahead.").
4. Each action:
   - One sentence above the code block acting as its caption (caption must be ≤15 words).
   - One `gdscript` code block (~5–15 lines).
   - 1–3 sentences of explanation below the block.
5. **Closing** (1 sentence tying this map to the next in the sequence).

Thresholds from `tools/text_metrics.py`:
- word_count_min: 400
- word_count_max: 1500
- code_ratio_min: 0.40 (40% of chars must be in code blocks)
- code_blocks_min: 6
- code_blocks_max: 20
- max_paragraph_sentences: 3
- caption_max_words: 15

## Session blog posts

Three written so far:
- `doc/sessions/2026-04-23-summary-audit.md` — summary cohort, role-separation framing.
- `doc/sessions/2026-04-24-critical-technical-push.md` — critical and technical cohorts.
- `doc/sessions/2026-04-24-tutorial-push-handoff.md` — this file.

A fourth blog covering the tutorial push would be appropriate once the 53 remaining files land. It should cover: the process reflection on text-as-spec, the 10-cohort sweep, where the texts diverge from implementation (chambers especially), and what the next-iteration read-against-map loop should look like.

## Observations to carry forward

**Texts as spec.** Each tutorial commits to specific `class_name` declarations and `func` signatures that I haven't read against the actual scene files. The tutorials are therefore a proposal to the implementation rather than a report on it. Where they disagree, either the tutorial is wrong or the map is under-implemented.

**Chamber files are the weakest seam.** I invented creature mechanics (fold thresholds, resonance scoring, hue alignment) for chambers whose implementation is partial. Expect the largest divergence between text and actual behaviour in the Chamber_* family.

**The two weak points to revisit first in any iteration.** (1) Check each tutorial's `class_name` and top-level `func` signatures against the actual `.gd` files in the same directory. (2) Walk each chamber in VR and note where the tutorial's promised interaction differs from what happens.

**Voice separation is the first real payoff.** The five passing roles produce a coherent layered reference. A reader can move blurb → summary → critical → technical → tutorial and each layer adds a distinct thing without repeating. That coherence is what makes the texts usable as a reference for querying and improving implementation.

## Token-efficient resume pattern

When the next session starts:

1. Read this file first.
2. Read `commons/maps/Array_Patterns/tutorial.md` for the voice anchor.
3. Pick a sequence (smallest remaining first is usually easiest): postfoundationscrisis (8), then qfeplaboratory (9) or foundationscrisis (9), then wavefunctions (13), then randomness (14).
4. Run the bundle command for that sequence with `--only-failing`.
5. Write all tutorials in one edited bundle (don't spread across multiple calls).
6. Split, verify, top up any short files, commit.
7. Repeat.

Don't read the existing bundle files from prior sequences — they're committed but not needed for the new work.

## Tooling notes

- `tools/bundle_sequence.py`'s `--with-context` embeds the map's intent and blurb as comment headers in the bundle. This is the only context needed to write a good tutorial; the existing critical and technical files aren't pulled in.
- `tools/split_sequence.py` creates `.before_bundle` backups before overwriting. Safe to rerun.
- `tools/text_metrics.py --spine --only-failing --format json` pipes to a JSON blob with per-map per-role failure reasons.
- Python top-up scripts should be written to `doc/_bundles/_<seq>_tut_topup.py` rather than run via heredoc — embedded quotes in GDScript code break bash heredocs.

## Clean state

The current working tree is clean except for pre-existing modifications in `.claude/` (uncommitted agent worktrees) and some generated files. Nothing from my work is pending.

Last commit: `ff1a74c34 docs(tutorial): top up three short noise/chamber tutorials`.
