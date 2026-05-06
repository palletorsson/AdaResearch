# Vector

> The direction Ada points in, and the practices that keep it pointing.
> Read this when starting a session, when stuck, when something feels off.
> Five minutes.

---

## The vector

Three corners. Not goals — *directions*.

```
                   BEING
            (the third party,
             the player, the reader,
             the one who is here)
                  ▲
                 ╱ ╲
                ╱   ╲
               ╱     ╲
              ╱       ╲
   TRUTH  ◀──────────────▶  SEAM
   (the abstraction:        (the manifestation
   QFEP, curriculum,         layer: editor, Godot,
   artifact specs)           book, encyclopedia)
```

- **Truth** is what survives an engine change. QFEP. Curriculum. Algorithm specs. Map JSON. The book's argument. Slow to author. Long to live. Engine-agnostic.
- **Seam** is how truth manifests in *one* technology. The Three.js editor. The Godot VR runtime. The InDesign book. The encyclopedia API. Cheap to rewrite. Engine-specific. Should be thin.
- **Being** is what the whole arrangement is for. A person walks a map. A reader holds the book. An author opens the editor. Without the third party, none of the rest exists.

You stay on the vector when every meaningful decision strengthens at least one corner *without weakening another*. You drift when one corner grows unilaterally.

---

## What drift looks like

Concrete failure modes. Each one has happened in real projects. Watch for them.

| Drift | Symptom | What was sacrificed |
|---|---|---|
| **Procedural creep** | Variants ship faster than spines get authored. The corpus inflates with `_v7_curve` maps no human has walked. | Truth thinned. Variants without intent are forest, not curriculum. |
| **Museum drift** | A single map gets two weeks of polish. Sequences stall. | Procedural texture thinned. Becomes precious, not lived-in. |
| **Engine capture** | Code that should be portable accumulates Godot-specific calls. The "spec_url" for new artifacts never gets filled. | Truth bound to one substrate. Future engines can't carry it. |
| **Player forgotten** | Days since last VR walk grows. The bridge listener's `desktop_feedback.md` is empty. | Being layer goes silent. Tools optimize for themselves. |
| **Ad-hoc QFEP** | Artifacts get added without `qfep` classification. Or artifacts are tagged inconsistently. | Truth's spine fuzzes. The framework stops indexing. |
| **Seam thickening** | The editor grows a feature that doesn't write to map JSON. The book pipeline grows a renderer that doesn't read the registry. | Manifestations stop being manifestations. They become forks. |

If you can't tell whether you're drifting, you are.

---

## Rituals

Time-bound practices. Cheap individually; the calendar is the system.

### Per-action — when you make a change
**The triangle question.** Before any non-trivial change ask:

> Does this strengthen Truth, Seam, or Being? Is it neutral on the others?

Three answers acceptable: "Truth", "Seam", "Being". Two answers: bonus. Zero corners: stop and reconsider. The change might be right, but you owe yourself an explanation.

Examples:
- *Adding a brush mutator to the editor* → strengthens Seam (a thicker authoring tool) — neutral on Truth, neutral on Being. Acceptable; mutators compose with everything below.
- *Refactoring `bulging_tunnel.gd` to a JSON spec* → strengthens Truth (now portable) — strengthens Being (encyclopedia can render it without Godot) — neutral on Seam. Two corners; ship it.
- *Hardcoding a special case for one artifact in `GridSystem.gd`* → drift. Thickens the seam, weakens truth. Find a generalization or push the special case into the registry.

### Weekly — Friday afternoon, 30 minutes
**Walk one sequence in VR.** Not to debug. To inhabit. End-to-end. If the sequence has 12 maps, walk 12. Notice what feels alive and what feels fluorescent.

Write three lines in `desktop_feedback.md`:
- One thing the third party would love
- One thing the third party would not notice
- One thing the third party would find broken

Three lines. That's all. The point is staying connected to what we're for.

### Monthly — first Monday
**Run `python tools/vector_check.py`.** Look at the drift report. If two metrics drift in the same direction, name it explicitly. Decide one corrective action. Add it to a TODO. That's the whole ritual.

### Quarterly — every three months
**Test a neglected manifestation.** Pick a corner you haven't touched in 90 days. Build the smallest thing that uses it.

Examples:
- The book has been quiet → write one chapter from scratch
- The encyclopedia hasn't shipped a new view → ship a small one
- VR feedback is empty → put on the headset for an hour
- The auto-researcher hasn't run on a sequence in a month → re-run, audit results

The corner that's been neglected longest tells you what's been drifting.

---

## Instruments

Things `vector_check.py` measures. None of them are perfect; together they are honest.

| Metric | Healthy range | Reads which corner |
|---|---|---|
| `authored_maps / total_maps` | 0.10 – 0.30 | Truth ↔ Seam balance. Too low → procedural creep. Too high → museum. |
| `days_since_last_vr_walk` | < 7 | Being. |
| `qfep_coverage` (% artifacts with `qfep` tag) | > 0.85 | Truth. |
| `spec_url_coverage` (% artifacts with portable spec) | growing month-over-month | Truth → Seam migration. |
| `bridge_feedback_count` (lines added to `desktop_feedback.md` last 30d) | > 5 | Being. |
| `auto_research_to_human_ratio` (variants per spine map authored last 90d) | 3 – 12 | Truth ↔ Seam balance. |
| `engine_specific_loc / total_loc` (Godot calls in supposedly-portable files) | trending down | Seam thickening. |
| `sequences_with_both` (sequences having ≥1 authored AND ≥1 variant map) | == 19 | Hybrid intentionality. |

The script doesn't fail-build on any of these. It surfaces. Humans decide.

---

## Gates

Things the system *enforces* (not just measures), because some boundaries are worth committing to.

1. **Spine-map protection.** Auto-research can generate variants of any map, but the *first* map of any sequence (`_intro` or position-zero) cannot be overwritten by an automated process. Hand-edit only. Codified in `tools/spine_auto_research.py` (we should check this is enforced).

2. **QFEP required at registration.** New artifact registry entries without `qfep` field reject. Enforced via `tools/classify_artifacts.py` (or a pre-commit hook).

3. **Map JSON is the contract.** Tools that author maps must write *only* the three-layer schema. Anything tool-specific lives in side files (`/blurb.md`, `/intent.md`), not in the map JSON. Enforced by JSON schema validation.

4. **No engine-specific Godot calls in registry-level code.** Files in `commons/artifacts/registry/`, `commons/maps/sequences/`, and `tools/map_grammar/` should reference Godot APIs zero times. Enforced by a lint rule (we should write it).

These four gates are small but expensive to violate. Each one prevents a specific drift mode from becoming permanent.

---

## When drift is detected

A protocol so we don't argue in the moment.

1. **Name the drift.** "We're 30 days without VR feedback" is better than "things feel off." Specificity defuses anxiety.
2. **Pick the smallest corrective action.** Not "fix the pipeline." "Walk one sequence Friday afternoon."
3. **Schedule it.** A drift correction not on the calendar is a wish.
4. **Don't compensate by overcorrecting.** A week without VR doesn't mean four hours next Monday. It means 30 minutes Friday and 30 minutes Friday after that.

The point is the *direction* not the magnitude. Small, regular corrections. The vector is restored by the practice, not by heroic effort.

---

## What this isn't

- **Not a milestone tracker.** We are not "behind" or "ahead." Being-games don't have those.
- **Not a metric to optimize.** Hitting a perfect 0.20 authored-ratio doesn't make Ada better. Drifting toward 0.05 *with no one noticing* does make Ada worse.
- **Not a substitute for taste.** All of these instruments together don't tell you whether a map is good. They tell you whether the *system that produces maps* is healthy. The work itself still requires judgment.
- **Not Brittle.** If a metric becomes meaningless because the project shape changed, drop it. The vector is the durable thing; the instruments serve the vector.

---

## The shortest possible version

When you make something, ask which corner it strengthens. Walk a map in VR every Friday. Run the drift check on the first of the month. Don't let any corner go silent for more than 90 days.

That's the system.
