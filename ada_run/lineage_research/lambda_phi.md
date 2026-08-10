# Lambda / Phi — the first artifact-lineage register

> Research only. Audited 2026-08-10 against the working tree. No maps, scenes,
> registries, dressing rooms, `project.godot` or existing documentation were
> touched. The companion JSON is labelled a **proposal for review** and
> deliberately declares no canonical schema name.

Thirteen candidates accepted, seventeen rejected with reasons. Every accepted
`lookup_name` was checked against the registry files and its `scene` path
checked for existence on disk; all thirteen resolve. (The brief asked for 6–12.
The thirteenth is `phi_rate_bench`, found on a late pass through the neighbour
data — dropping it would have kept the count and lost the finding.)

---

## The headline

**Lambda and Phi are not twins.** They are the two terms of one formula, they
share a rail geometry to the millimetre, and they carry the same DNA axis with
the same five values — and the museum that already exists exhibits them in two
completely different ways.

| | Lambda | Phi |
|---|---|---|
| its own demonstration room | `QFEP_Lambda_Spectrum` | `QFEP_Phi_Term` |
| the dial stands in that room | **no** | **yes** |
| where the dial actually stands | `QFEP_Edge_Of_Chaos` (the single-value room, λ≈0.4) | its own room |
| what the room contains | seven bodies across the range | three bodies plus the dial |

That table is read out of `map_data.json` files, not inferred. `QFEP_Lambda_Spectrum`
contains `bifurcation_walkway`, `chaos_particles`, `complexity_pattern`,
`crystal_formation`, `dissolving_form`, `edge_particles`, `ordered_grid` — and no
slider. `QFEP_Phi_Term` contains `phi_slider` itself alongside `rigid_sculpture`,
`fluid_form`, `preserved_pattern`, `transforming_pattern`.

So the shipped curriculum already made the ruling the brief asks about, and made
it more strongly than "separate rooms". **Lambda is exhibited as a spectrum you
walk. Phi is exhibited as a dial you turn.** One is a corridor of consequences
with the cause removed; the other is a cause with three consequences around it.

This is the real answer to *why separate rooms even when consecutive*. Not
because two instruments beside each other look cluttered — that is a taste
argument and taste arguments lose to layout engines. Because **the two rooms are
different exhibition types**, and a negotiation layer that derives one room shape
from "slider, 1×1 footprint, wall posture" will generate the same bay twice and
be wrong once. Lambda's room needs a walkable range. Phi's room needs a station
with sightlines to three bodies. Same object class, incompatible floorplans.

The secondary reason is smaller and still real: they carry **one axis, two
files** — `calibration`, five values, identical in both registry entries, with
`lambda_slider.gd:24-27` stating the pair "would be incoherent … if they spoke
different vocabularies about the same question." A shared vocabulary is only
legible if the two speakers can be heard separately. Side by side at
`calibration:dispute`, a visitor reads one control panel with two knobs. Two
rooms apart, they read as the same question asked twice about different
quantities — which is what the axis is for.

---

## Three findings that change what the negotiation layer can trust

### 1. Half the "related" artifacts are wired to nothing

Six files search the Godot group `"qfep_slider"`:

```
edge_detector.gd:205   entropy_meter.gd:181       phase_cube.gd:234
qfep_oscilloscope.gd:235   qfep_reactor.gd:428    reactive_particle_field.gd:294
```

**Nothing in the repository ever calls `add_to_group("qfep_slider")`.** The
sliders join `qfep_lambda_controllers` (`lambda_slider.gd:196`) and
`qfep_phi_controllers` (`phi_slider.gd:145`). Exactly one consumer reads those
correct names — `edge_of_chaos_orb.gd:194,199`. One more,
`queer_morphology_specimen.gd:599,603`, sidesteps groups entirely and connects by
direct node reference.

`qfep_reactor.gd:23-25` already documents this for itself, in the project's own
words: *set_lambda and set_phi* "have never been called in any room … an orb
whose whole claim is that the state MOVES has only ever drawn one state." This
audit confirms it is not one file. It is six.

The consequence for placement is concrete. The registry cannot distinguish an
artifact that responds to the dial from one that was written to respond and
never does. Both look like strong relations. Put a dead one in the lambda bay
and the room makes a promise the building cannot keep — the visitor turns the
dial and a thing that is visibly *about* the dial does not move. **A live-wiring
test belongs in the negotiator's evidence, beside footprint and clearance.**

### 2. Phi's declared body is a placeholder, and it is 100× too big

```
lambda_slider   footprint [0.69, 0.33, 1.31]   posture wall    production_grade featured_aaa
phi_slider      footprint [8,    8,    1]      posture floor   (no grade)
```

Both sources declare `rail_length 0.5`, `rail_height 0.02`, `rail_depth 0.05`,
`handle_radius 0.03`. Lambda additionally has `@export var console_body: bool =
true` (`lambda_slider.gd:131`); phi has no such export. **Phi is the bare rail —
it is smaller than Lambda, not sixty times larger in floor area.**

`[8, 8, 1]` is the unmeasured default. It also appears verbatim in the dressing
rooms for `qfep_sandbox_console`, `edge_of_chaos_orb`, `chaos_particles`,
`edge_core` and `qfep_reactor` — five of them in this lineage alone.

This blocks layout, not polish. The negotiator's `grow` decision reads declared
footprints; fed `[8,8,1]` it will expand a 3×3 bay to a gallery for an object
that fits on a shelf, then report the expansion as a justified compromise. The
report will be internally consistent and wrong. **Measure Phi before laying out
this lineage.** The `museum_aaa_pass` capture path already exists for exactly
this — `ada_run/museum_aaa_pass/capture/lambda_slider.json` is the template.

There is a smaller instance of the same class: `bifurcation_walkway` declares
`[2, 3, 10]` in the registry and `[9, 3, 1]` in its dressing room. The two
sources disagree about which axis is length.

### 3. The most-related artifact has never shared a room with either slider

`queer_morphology_specimen` is named in **both** `@identity` relationships
fields, connects to **both** sliders by direct node reference, and exposes
`set_lambda` and `set_phi` (`:761`, `:764`). By authored intent and by code it is
the strongest edge in the graph.

Its `placements_together` with either slider is **0**.

This is the brief's warning in its purest available form, and it argues for
`textual_link_only`. Co-locating it would not be *recovering* a relation the
project already has; it would be *making* one, and that is a design decision for
Palle, not a research output.

---

### 4. Similarity found the artifact that five better signals missed — and also ranked a stranger above the formula

`commons/data/artifact_neighbors.json` is embedding similarity: exactly the
topic-association reading the brief warns against. Lambda's neighbours come back

```
phi_slider 0.806 · shannon_workbench 0.754 · qfep_balance_workbench 0.753
microstate_counter 0.733 · qfep_formula_3d 0.713
```

**`qfep_formula_3d` — named in both `@identity` fields, co-located with lambda in
nine maps — ranks fifth, below a workbench neither slider mentions and which
shares no map with lambda at all.** As evidence, the ranking is worthless.

And it was the only signal that found `phi_rate_bench`: registered, scene on
disk, declaring a `complement` axis, its name literally phi's rate term. Empty
`sequence` field, absent from all 799 spine-order entries, never co-placed with
`phi_slider`. The `@identity`, sibling, axis-kin and co-placement passes all
missed it, because it is unsequenced, unnamed and unplaced — invisible to every
strong signal by construction.

So: keep similarity as a **candidate generator**, never let it set an edge kind
or a bay. And do not treat the four strong signals as complete — they are
complete about artifacts that are already installed, which is a different thing.

### 5. The taxonomy already grades them differently

`category_index.json` puts exactly two artifacts under `13_qfep / parameters`:
the two sliders. `artifact_theme_index.json` puts `lambda_slider` under
`by_complexity/intermediate` and `phi_slider` under `advanced`.

A third independent source agreeing with the headline. The family has exactly two
members, and the project already considers them unequal in difficulty — so an
order that walks lambda first is supported by the taxonomy, not only by the
formula.

---

## The register

Roles: **ancestor** (the idea the dial assumes) · **sibling** (the pair) ·
**extension** (something the dial drives or supersedes) · **contrast** (a pole of
the scale) · **application** (the dial's output used for something else).

Bay column respects the ruling already published in *Handover: three rooms that
fit* — **Lambda's own bay is solitary, 3 × 3 × 3, no neighbours.** `adjacent_bay`
therefore means *the next bay along*, never *inside Lambda's room*.

| # | lookup_name | role | conf | bay | why |
|---|---|---|---|---|---|
| 1 | `lambda_slider` | *anchor* | — | — | spine 750, `Crisis_Synthesis` |
| 2 | `ordered_grid` | contrast | high | adjacent | the λ=0 pole; contrast declared in `chaos_particles.gd:17` |
| 3 | `chaos_particles` | contrast | high | adjacent | the λ=1 pole; declares the contrast itself. Body is a placeholder |
| 4 | `bifurcation_walkway` | application | med | later | the parameter line as floor — 9 m, it *is* a room |
| 5 | `bifurcation_diagram` | ancestor | med | later | parameter→regime drawn; **shipped order disagrees**, see below |
| 6 | `edge_core` | extension | med | later | has `set_lambda`, already shares `QFEP_Edge_Of_Chaos`; wiring dead |
| 7 | `edge_of_chaos_orb` | extension | high | later | **the only live consumer**; currently absent from the spine walk |
| 8 | `phi_slider` | sibling | high | later | one axis, two files; see the headline |
| 9 | `rigid_sculpture` | contrast | med | later | φ<0, resists change; already installed with its dial |
| 10 | `fluid_form` | contrast | med | later | φ>0, seeks change; never split from 9 |
| 11 | `queer_morphology_specimen` | application | high | **textual only** | both terms on one body; co-placement 0 |
| 12 | `qfep_formula_3d` | application | high | later | the formula both terms live in; recolours as they move |
| 10½ | `phi_rate_bench` | extension | med | later | phi's `complement` axis; **found only by similarity**, see finding 4 |
| 13 | `qfep_sandbox_console` | extension | high | later | joins **both** controller groups — supersedes both dials |

Proposed one-dimensional order, offered as one defensible arc rather than a
derived fact: **term → its extremes → its line → its edge → second term → its
extremes → recombination → formula → the console that replaces both dials.**

Where it contradicts what is shipped, the contradiction is stated rather than
smoothed:

- Spine order puts `bifurcation_diagram` at **752**, *after* `lambda_slider` at
  750, in the same map. Calling it an ancestor is a conceptual claim the shipped
  order does not support. A reviewer may downgrade it to sibling and lose
  nothing else in the proposal.
- Spine order puts `phi_slider` at **751**, immediately after lambda. This
  proposal moves it six places later so lambda's own poles are walked first.

`edge_of_chaos_orb` and `qfep_sandbox_console` are **not in
`spine_artifact_order.json` at all** — 799 entries, neither present. The live
consumer and the console that holds both dials are both off the walk.

---

## Rejected, with reasons

**Dead group lookup** (`get_nodes_in_group("qfep_slider")`, a group nothing
joins) — `entropy_meter`, `phase_cube`, `qfep_oscilloscope`, `edge_detector`,
`reactive_particle_field`, `qfep_reactor`. All six are registered with scenes on
disk; all six would be defensible on a topic reading and indefensible on a
wiring reading. `qfep_reactor` is the closest call — it is named in both
`@identity` fields — but `edge_core` already carries the dead-driver lesson and
one is enough for a visitor to see. `reactive_particle_field` fails twice: it is
also the scene behind two other registry names (`edge_particles`,
`emergence_zone`), so a placement by lookup would be ambiguous about which member
the room means.

**`grab_sphere_lambda`, `grab_sphere_phi`** — registered, scenes exist, and they
share `grab_sphere_point_with_color.tscn` with `grab_sphere_E`, `grab_sphere_F`
and `grab_sphere_point_with_color`. Five names, one scene: the corpus's most
common hidden family. These are coloured spheres standing for terms inside
`QFEP_Synthesis`, not instruments in the instrument's lineage.

**`lambda_hall`** — matches on the word and carries a `lambda` variable. Filed
under `concept_architecture.json`, no sequence, and it is architecture rather
than instrumentation. Name collision.

**`edge_of_chaos_unlocked`** — named by lambda and co-located once, but keyed to
`tenure`: it belongs to the sequence's unlock grammar, not to the parameter.

**`shannon_entropy_meter`** — different sequence, never co-located, never named.
Reached only through the word *entropy*.

**`dissolving_form`** (low) and **`preserved_pattern`** (low) — both sit in the
right rooms at spine 769 and 775, but neither is named by a slider's `@identity`,
and each slider's field names exactly three controlled bodies. Include only if
the reviewer wants the whole room rather than its named contents.

**`particle_chaos`** — co-located twice, declares `constraint`, but belongs to
the E-term room where the subject is entropy itself rather than the dial that
weights it. Same reasoning excludes `microstate_counter` (spine 761, `macrostate`),
`entropy_fan` (762, `prospect`) and `possibility_space_cloud` (763, `occupancy`) —
all three sit on the walk *between* the sliders at 750/751 and the Lambda
Spectrum at 767–770, so a visitor meets them inside this lineage's span, but
their subject is entropy's bookkeeping rather than the dial.

**`shannon_workbench`** — listed only because it is the counter-example in
finding 4.

**`qfep_balance_workbench`** (low) — the strongest of the similarity-generated
candidates: declares `settling`, is in the `qfeplaboratory` sequence, and does
share `QFEP_Introduction` with a slider. Excluded on distance — spine index
**222** against the sliders' 750/751, more than five hundred positions upstream.
If you want a fourteenth entry, take this one.

**`phi_becoming_room`** (medium) — the only candidate whose *name* claims room
scale for phi. Registered with a scene on disk, and then: empty `sequence`, no
declared axes, absent from spine order, placed in no map at all. Unbuilt rather
than unrelated, and worth knowing exists.

---

## One discrepancy worth someone's eye

`doc/book/dig_reports/qfeplaboratory.md` lines 12 and 14 record both sliders as
register **side** and annotate both **"mute (no @identity)"**. Both files have
full `@identity` blocks — lambda's at line 12, phi's at line 38, behind a long
header. Either the dig predates them or its parser only looks at the top of the
file. Low stakes for placement, but the `side` register should not be used as a
curatorial ranking until it is re-dug.

---

## What this hands the negotiation layer

Four things it can use immediately, and one it must not:

1. **A live-wiring predicate.** Does this artifact's group lookup match a group
   something joins? Cheap to compute, and it separates two populations the
   registry cannot tell apart.
2. **A placeholder detector.** `footprint == [8,8,1]` means *unmeasured*. Five of
   thirteen candidates here. A `grow` decision taken on a placeholder is a
   fabricated compromise.
3. **A source-disagreement check.** Registry footprint versus dressing-room
   footprint, flagged when they differ (`bifurcation_walkway`).
4. **Room-type as a first-class attribute.** Spectrum-you-walk versus
   dial-you-turn is not derivable from footprint and posture, and it is the
   difference between Lambda's room and Phi's.
5. **A completeness check that runs on the uninstalled.** Four of this lineage's
   candidates — `phi_rate_bench`, `phi_becoming_room`, `edge_of_chaos_orb`,
   `qfep_sandbox_console` — are absent from all 799 spine-order entries. The
   strong relation signals are complete about artifacts that are already placed,
   which is not the same as complete.

And the one to refuse: **do not let a strong relation imply adjacency.** The
single most strongly related artifact in this lineage has co-placement zero, and
the honest output was a link, not a bay.
