# Cloth Physics — pilot delivery

Sequence `softbodies`, hall `SoftBodies_Cloth_Physics`. 23 September 2026.

---

## 1. What I preserved, and the one change this hall needed

I preserved the distinction the assignment named: **material response versus pinning**, and the closing question about how much of "compliant" belongs to the object and how much to the arrangement holding it. I kept the code block, the honest note that the falling spheres are not woven cloth, and the handover to Carusell. The title question is unchanged and still matches the console's chapter title.

The one change this hall needed is not the pinning comparison — **that already exists and works.** It is that the hall *asserts* its best sentence instead of letting the reader test it. "A convincing support does not prove how the simulation is attached to it" was a claim with nothing behind it, because there was no way to change the support. Now there is, and the sentence is the consequence of an action rather than a warning attached to one.

Second change: the reader now meets the cloth, finds a fold and follows it before any control is named. In the original, PINS arrived in sentence three.

---

## 2. The developed encounter

### Current capability — verified, not assumed

The full pinned-edge → corners → release comparison **already existed and was reachable**. It does not live on the artifact; it lives on the console.

`commons/artifacts/timing_machines/soft_workshop.gd:87` `_cloth_pins(mode)` computes, per strip:

```gdscript
var top: bool = absf(verts[i].y - ymax) < 0.01
var keep: bool = top and (mode == 0 or (mode == 1 and absf(absf(verts[i].x) - xmax) < 0.01))
sb.set_point_pinned(i, keep)
```

Mode 0 is the full top row, mode 1 the two upper corners, mode 2 nothing. `PINS` alternates 0↔1, `RELEASE` calls 2, `REBUILD` rebuilds and re-pins to 0. I read this after first concluding from `cloth_straps.gd` alone that none of it existed — that conclusion was wrong, and it is recorded here because the artifact file genuinely contains no pinning controls and reading it alone misleads.

### The gap that was real

`cloth_straps` declares five suspension rigs, all fully implemented:

```gdscript
@export_enum("none", "gantry", "wall", "hoop", "mast") var suspension: String = "gantry"
```

No map token anywhere set it and the cloth chapter's control list did not include it. **Every visitor who has entered this hall has seen exactly one rig.** Meanwhile the pin rule reads rest-mesh coordinates and never consults the frame — so the hall's own claim was demonstrable and undemonstrated.

### Built (not proposed)

Two edits, both additive:

- `soft_workshop.json`, slug `cloth`: `SUPPORT` added to `controls`; rule card updated. The desk's own layout code already handles a seventh control ("Six controls use three columns. A seventh uses four columns and keeps two rows"), so nothing else moved.
- `soft_workshop.gd`, cloth branch: one line, `"SUPPORT":model.apply_grid_config({"suspension":["gantry","none","hoop","mast","wall"][_next(id,5)]})`. The artifact's `apply_grid_config` already guarded this correctly and `setup_frame()` was already rebuild-safe; I changed neither.
- The cloth readout now shows which support is standing, and says the pins are read from mesh coordinates rather than from the frame.

The cycle begins on `none`, so the first press removes the frame entirely. That is the sharpest form of the demonstration and it lands immediately.

### The bodily consequence, checked

`commons/testing/probe_cloth_support.gd` — 7 cases, exits non-zero, **all pass**:

| | check | measured |
|---|---|---|
| A | lesson build | 8 strips, 8 of 112 points pinned each |
| B | SUPPORT changes the rig | gantry 6 parts → hoop 38 parts |
| C | pinned index set across the change | identical, 8 → 8 |
| D | the held edge across the change | 0.000000 m — but see the correction below |
| **J** | **a free vertex, no frame change at all** | **moved 0.031 m in 30 frames** |
| E | `suspension: none` | 0 frame parts, cloth unmoved (0.000000 m) |
| F | all five values accepted | 5 of 5 |
| G | pin arithmetic | mode 0 → 8, mode 1 → exactly 2, mode 2 → 0 |
| H | `act("SUPPORT")`, the real dispatch | first press → `none`, second → `hoop` |
| I | the desk | 7 buttons built, SUPPORT wired, firing it changes the support |

### Correction — the first version of this pilot overclaimed, and the probe was why

The revision originally ended its SUPPORT paragraph: *"the cloth does not move. Not a little. Not at all."* An adversarial review pass caught it, and the fault was in case D rather than in the sentence.

`_pinned_positions()` reads back only the indices `_pinned()` returns — the points the solver holds fixed. **Pinned points cannot move by construction.** `largest movement 0.000000 m` was close to a tautology: it proved the pin set survived the rebuild, not that the cloth was undisturbed. No unpinned vertex was measured anywhere in the probe.

Case J now measures one, and settles it the other way: **a free vertex moves 0.031 m in 30 frames with no frame change at all.** The artifact's own note says as much — a 3.5 m sheet at `linear_stiffness` 0.34 is still stretching and swinging long after it is built. So the absolute claim was false on its face, independently of the frame, and could have been measured before it was written.

What the evidence actually supports is narrower and still worth saying: the frame changes completely and **the held edge does not move**. The prose now claims that and no more.

A second thing the review caught, from source rather than from measurement: the cycle's fifth value, `wall`, is the one rig whose geometry reaches into the space the cloth occupies — its own docstring says it is the value you cannot walk through. Enumerating it alongside hoop and mast as another inert frame was wrong. It now gets its own paragraph.

H and I close the path from button to artifact. The desk builds all seven controls — `PINS, SUPPORT, STIFFNESS, RELEASE, REBUILD, LANDING, RULE` — SUPPORT's `pressed` signal has one connection, and firing it moves the artifact from `gantry` to `none`. **Emitting a signal is not input**: this proves the wiring, not that a hand can reach the button. Reach still needs a museum-lane walk.

---

## 3. The revision

- Original preserved at `before/final.md`.
- Candidate at `final.candidate.md`, installed to `commons/maps/SoftBodies_Cloth_Physics/final.md`.
- Exact diff at `final.diff`. Console diffs at `soft_workshop.diff` and `soft_workshop.json.diff`.

357 → 727 words. Both artifact anchors preserved.

The important changes, in order: the reader arrives and finds a fold before any button is named; SUPPORT arrives as a question ("something up there is being held — before naming it, find out what") and answers it by removing the frame; the code block is now the actual pin selector rather than the one-line call, because the selector is what shows the frame is not a party to the arrangement; PINS is given its bodily consequence (the top edge "stops being an edge"); and the qualification pile around the falling spheres is cut from three sentences to one, with the rest belonging in `technical.md`.

---

## 4. Field notes

**Inspected.** `cloth_straps.gd` (415 lines) and `.tscn`; `soft_workshop.gd` (212) and `soft_workshop.json`; `pg_workshop.gd` layout builder; the hall's nine companion `.md` files; the neighbouring halls `SoftBodies_Soft_Body_Deformation` and `SoftBodies_Carusell`; `WRITING_BRIEF.md`, `ASSIGNMENT.md`, `ASSESSMENT.md`, `VOICE_EXAMPLES.md`, `state.json`. A 37-agent sweep read the artifact, the console, the sequence, the voice exemplars, the companions and every secondary cloth artifact, with adversarial verification on 30 capability claims (1 refuted).

**The git state, which bears on everything.** `final.md` is tracked and *was* unmodified; the hall it describes is not committed. `soft_workshop.gd/.json/.tscn` and `pg_workshop.gd/.tscn` are **untracked**. `cloth_straps.gd` is modified — the entire `_setup_lesson_straps` path is an uncommitted hunk. `map_data.json` at HEAD is a 6×11 room holding one token; the 30×47 hall exists only in the working tree. Forum `260923-n9p6t` claims these files; thread `260923-pc08y` is a breather session landing stranded artifacts under gate M, and `soft_workshop.gd` is on its list.

**Claims I found circulating that should not reach prose.**
- *"After RELEASE only REBUILD restores the full edge."* False. `PINS` is `(pin_mode+1)%2`; from mode 2 the first press gives corners and the second gives the full edge. Probe case G confirms: 2 then 8.
- *"The 2026-09-15 acceptance receipt asserts the comparison works."* It does not. Three of its five recorded source hashes now differ, and the harness presses each control once in list order, so every cloth assertion is measured after REBUILD in mode 0 only. It proves the buttons do not error.
- `STIFFNESS` never returns to the built 0.34 except via REBUILD, and `_next` increments before returning, so the first press gives 0.1, not the 0.5 listed first. The revision does not state a value.

**Not done, deliberately.** `ClothSimulation.gd` builds all three pin regimes side by side, labelled, and is in zero softbodies maps — but its `cloth_stiffness` is read by no force, so importing it into a hall about what a control is attached to would import the exact fault the brief forbids papering over. Recorded as a candidate for a later hall, not used.

**Limits of the evidence.** The probe is headless physics with a real solver; it is not a walked hall. The console binds by walking up for an `em_map` ancestor, so it only exists in the endless-museum lane — **I could not press the real SUPPORT button**, only drive `apply_grid_config` and `_cloth_pins` directly, which is what the button calls. No capture yet.

**Captured.** `python tools/build_dna_gallery.py --slug=cloth-support --tokens=cloth_straps` swept the axis and wrote five variants to `ada_encyclopedia/public/cloth-support/` — one per rig, plus `manifest.json`. The gantry frame is a red portal around the rank; `none` has no frame at all and the strips hang in the same arrangement with the same folds.

**A limit on that capture, stated because the brief separates kinds of evidence.** The sweep fits its camera to the artifact's merged AABB, and removing the rig shrinks that box, so the `none` tile is drawn at a larger scale than the `gantry` tile. The images are proof that the rig changes and that the cloth survives without it. They are *not* proof that the cloth did not move — the two frames are not registered to each other. That claim rests on probe case D, which reads pinned point positions back from the physics server and measures 0.000000 m. If the pair is wanted as a book illustration, it needs a fixed camera rather than a DNA sweep; a `layers = 0` anchor sized to the rank would pin the framing.

**Museum lane, run.** `endless_museum.tscn --em-chapter=softbodies --em-map=SoftBodies_Cloth_Physics`. `--em-map` alone is not enough — it opened at primitives and said so. With both flags the log reads:

```
the walk opens at softbodies · softbodies cloth physics (pearl 2/9, map SoftBodies_Cloth_Physics)
[em-pack] softbodies · softbodies cloth physics <- SoftBodies_Cloth_Physics: 3 verbatim + 0 slid of 3, 0 left behind
seg 0 = mezquita-hypostyle ... placed 3/0 ... z -4..50, lights 15
```

All three tokens stamped verbatim, none slid, none left behind — and **no `Soft workshop missing`**, which is the error `_bind` raises when it cannot resolve a primary after its hundred retries. The console binds in the real hall.

`hall_desk.png` is an in-situ shot from that run. It is aimed at the falling spheres, not the desk: four bodies each on a rail, which is `#landing:rail` built as written. It was not re-aimed because the evidence it adds is incidental.

**What it accidentally shows, and what that means for the writing.** The hall is 30 × 47 and almost all of it is bare floor. The three exhibits sit far apart with a long empty crossing between them. That is either the best thing in the room — you walk a long way after pulling the pins, with nothing to look at — or a hole. The current revision does not use it either way. **Queued, not solved.**

**Still not done.** Nobody has pressed the button with a hand. Case I fires the signal, which proves the wiring and not the reach: the touch target, the pointer and the standing distance are untested, and this artifact's own desk has a 4 cm button area. That is a headset or desktop-walk task.
