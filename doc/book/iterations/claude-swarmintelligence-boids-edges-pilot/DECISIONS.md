# Boids — edges pilot

Sequence `swarmintelligence`, hall `SwarmIntelligence_Boids_Algorithm`. 24 September 2026. Not installed: `final.candidate.md` is a candidate, `before/final.md` is the shipped chapter, `final.diff` is the delta. Palle installs or not.

Why this hall: the four thinnest sequences in the spine reading (swarmintelligence, graphtheory, softbodies, machinelearning) all run 300–420 words a chapter and end on "a future experiment could…". This chapter was 419 words about one artifact of six, named the rule in its second paragraph, and said the flock "wraps around the display's bounds" as its only edge. Three of the six things standing in the hall were never mentioned.

## 1. The beats, and where each one comes from

| beat | in the candidate | verified against |
|---|---|---|
| **Encounter** | a hundred prisms already through the room; through walls, floor, you; hold out your hand, nothing turns | `boid_manager.tscn` `num_boids = 100`; `boid.tscn` prism scaled 0.357 × 0.605 (≈ 0.6 m long); `Boid.gd` `min_speed 5 / max_speed 10` m/s, `extends Node3D`, no collider; `boid_manager.gd:103` `spawn_area_size = (20, 10, 20)` centred on the placement at floor level in a 13 × 13 hall, so half the school is dealt under the floor and the box overhangs the walls by 3.5 m; `Boid.gd:26` `boundary_size = (50, 30, 50)`, push only when `abs(pos) > half - 5` |
| **Disturbance** | at the slider panel a boid that leaves the right side is on the left; the neighbours it was flying with are now out of sight; its arrows swing | `flocking_controls.gd:498–512` wrap on x, y, z ("open-air, no bounce"); `:454–456` neighbours by plain `distance_to` inside `perception_radius` (default 0.2, box 0.8 × 0.6 × 0.8) — there is no toroidal distance, so a boid that has just crossed sees nobody across the seam |
| **Search** | ring, three arrows, one slider at a time, then RADIUS | `flocking_controls.gd:60,80,191` highlight ring; force arrows cached for the highlighted boid; sliders SEP/ALIGN/COH clamped 0–5, RADIUS 0.05–0.5 — kept from the shipped chapter, tightened |
| **Rule** | each boid, its own neighbours, three weighted requests, moves along the sum; a slider changes a weight for everyone, tells the flock nothing | `flocking_controls.gd:445–470` |
| **Name** | Reynolds 1987, "boids", the three words — arrives after the reader has watched all three disagree | footnote; the sequence has no attribution anywhere (task .014) |
| **Edge** | three edges in one hall: the tank's ceiling that is not there; the panel's seam; the open flock's boundary bigger than the hall, with no term for the visitor | `boids_aquarium.gd:373–380` five panes, no top; `:775,839–847` bounce at `tank_size * 0.45` on all three axes, so the lid is 5 cm below the rim; `boid_manager.gd:108–110,135–146` `vr_player_path`, `left_controller_path`, `right_controller_path` are NodePaths, unset in the `.tscn`, so `vr_player` and both controllers are null in every placed copy and `_process_controller_interaction` never finds a hand |

The QFEP paragraph ("Alignment is not consent…") is kept verbatim. It was the strongest paragraph and it is beat 6 for the model as a whole — the edge of the concept as an account of belonging — so it sits after the three architectural edges.

The closing "a future experiment could give different agents different perception ranges" is replaced by something the hall can do now: the panel's RESET is unseeded (`flocking_controls.gd:405–413` `randf_range`) and the tank's is seeded (`boids_aquarium.gd:588→_deposit_school`, `DEPOSIT_SEED`), so "return the slider, don't reset" is a real instruction with a real contrast.

## 2. What the encounter costs in honesty

The encounter paragraph is built on two things that read as faults:

1. **The open flock is not fitted to its hall.** Spawn box 20 m, boundary 50 m, in a 13 m hall, no collider. The prisms go through the museum's walls into neighbouring halls, and half of them start under the floor. The chapter says so, because it is what the visitor sees, and because it is the honest form of "the room is not in the rule". If someone later adds a `#fit` or clamps the box to the hall (as `LineNetworkCA` got on 24 Sept), **the first paragraph must be rewritten** — it would then be false.
2. **The hand does nothing.** `boid_manager.gd`'s header promises "left trigger attracts boids toward controller; right trigger repels — learner's body becomes a temporary leader". In a placed copy this is dead: the three NodePaths are never set. The chapter says "hold out your hand, nothing turns", which is true today. It is also the better encounter — a refusal is stronger than a pet — but it is a decision, not a discovery, and it is Palle's to make. Two futures: (a) keep it, and delete the header promise and the `needs: [has] VR controller attract/repel` line so no reader of the code is misled; (b) wire the controllers (find `XRController3D` by group, as `removal_arena.gd` now finds the body), in which case paragraph one becomes "hold out your hand and the nearest turn" and the Edge paragraph loses "no term in the rule for you".

Either way, the chapter and the code must agree; today the code disagrees with its own comment.

## 3. Tasks this touches

- `book_swarmintelligence.003` (the other four flocks get a paragraph) — done differently: the tank and the open flock are load-bearing beats, not a paragraph before the handover. The screen (`science_screen #mode:scatter`, plots whichever boid-like artifact it is tracking as dots) and the reading panel (`boids_2d_in_3d`) stay unmentioned on purpose; they are decoration in the arrangement.
- `book_swarmintelligence.007` (RESET deals a new scatter) — in, with the seeded/unseeded contrast.
- `book_swarmintelligence.014` (Reynolds attribution) — in, as the Name beat's footnote.
- New, added to `doc/tasks/book_swarmintelligence.json` with source "the edges pilot of 24 Sept": the dead-hand decision (kind `encounter`, event `proximity`), the unfitted open flock (kind `encounter`, event `leak`), and `boid_flocking` at (2,2) being a `CanvasLayer` documentation overlay — a screen-space UI that the headset cannot show and that covers the desktop view (kind `vr`).

## 4. Not done

- Not walked in a headset. The claims are about code and geometry; the reading order (panel → tank) assumes the visitor can find "the panel with the sliders" from the entry, which in the museum depends on the deal.
- Not installed, not committed, no registry or sequence file touched.

## 5. Installed

Palle: "install boids", 24 September 2026. `final.candidate.md` copied over `commons/maps/SwarmIntelligence_Boids_Algorithm/final.md` (LF, 890 words); shipped chapter verified unchanged since the `before/` snapshot. Tasks .003, .007, .014 marked done; .015/.016/.017 stay open as decisions. Not committed.
