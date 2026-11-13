# 3D Sphere Fractal — five-way growth

Open `/spatial-lab?recipe=lab_sphere_fractal&sequence=fractals`.

This study is based on **11 / 3D Sphere MultiMesh Fractal** in
`Fractal_RecursiveTrees`: the `fractal_scene:0:1:0.65` occurrence at grid x5,
row20. The actual generator is `algorithms/fractals/meshfractal/fractal.gd`.
The original scene and map are unchanged.

## What carries forward

Each parent creates five children: one along its local up axis, four turned by
90 degrees around its local X or Z axes. A child inherits the parent's rotation,
receives a world-up sag correction, then spins around its own Y axis. Its centre
is offset along its resulting up axis by 1.5 times its size. The original size
ratio is one half. Branches use spheres; the final generation uses cubes.

The lab exposes size ratio, spacing, sag, spin speed, reverse-spin fraction,
seed, depth and pose time. A deterministic seed replaces the museum's unseeded
random coefficients so the web and Godot versions agree. Speed and sag retain
the original ranges around their mean values. Sag is a prescribed rotation,
not a rigid-body or Jolt simulation.

The original defaults to six levels (3,906 instances rendered using MultiMesh).
This editable study permits one to four levels: **1, 6, 31 or 156 separate
parts**. It does not claim MultiMesh batching for those individual parts.

## Use it

1. Choose **Sphere + cube original rule**, **Geometric crystal**, or **Mixed
   suspended form**.
2. Swap **Root + branches**, **Alternating inner branches**, and **Terminal
   generation** independently. The middle role applies to even inner levels;
   at four levels it is generation two. It has no visible effect at fewer than
   four levels because that generation is then absent or terminal.
3. Press **Play motion**. Pause with **Pause and keep pose**, or set pose time
   directly. Motion stops at 60 seconds; playing again begins at zero.
4. **Save variation + native check** builds a separate lab trial. Open **Arrange
   this variation in the lab editor** to move, rotate or copy individual members.

New saved trials also animate in Godot. A separate movable control stand offers
**speed** (0–45 degrees/s), **size** (0.4–1.8 metres root diameter) and **depth**
(1–4 levels). Aim at a slider handle and hold the left mouse button while moving
along its track. Speed zero holds the current pose; changing speed does not
restart it. These controls change the current play session. Save the initial
parameters in the Spatial Lab when making a reusable variation.

The lab editor and exported models show the saved starting pose. A member's
saved position and rotation edits become offsets from its animated pose. Hidden
members retain those edits when depth is reduced and increased. A copied single
member stays still, so it can be arranged independently. The control stand is a
separate editable placement linked to the study by its placement ID.

Actual catalogue meshes and materials are fitted to each member's cube envelope.
Moving collision uses that envelope, including for spheres, with dimensions
updated alongside visible size. This is prescribed motion, not a physically
connected assembly or Jolt simulation. Overlaps remain findings to inspect.

The existing mixed reference `spatial_lab_ca573ae619` has been upgraded in place;
its member arrangement was preserved; the staged version raises the whole study by 1.05 metres. The older sphere/cube reference remains a
static historical pose. New variations and the reusable catalogue entry use
`sphere_fractal_live.tscn`.

Shared grammar example:

```json
{
  "t": "lab_sphere_fractal",
  "with": {
    "source": "trace_point_ball",
    "inner_source": "traffic_pyramid_5",
    "tip_source": "pentagonal_bipyramid_7",
    "depth": 4,
    "size": 1.2,
    "ratio": 0.5,
    "spacing": 1.5,
    "sag": 28,
    "speed": 22.5,
    "reverse": 0.25,
    "seed": 17,
    "phase": 16.75
  }
}
```

## Verification

The native probe instantiates the **original museum script**, injects the same
spin/sag coefficients, and compares all its computed world positions and
orientations at 0 and 7 seconds with the lab rule, using the original 0.5 ratio
and 1.5 spacing. Both comparisons pass. This validates the generator's stored
poses, not any quirks in its original MultiMesh world/local rendering setup.

The reference sphere/cube pose and mixed pose paused at 16.75 seconds each have
478 passing native checks and 159 exported model files. Both pass the full
web/native pose and editor save comparison. The checks include actual source geometry, finite dimensions,
collider presence, independent member edits and copies. The web test compares
every saved native position/orientation and prefab role with Three.js, parses
every member GLB, validates editor changes and checks save/reload with stale-save
rejection in an isolated fixture. Main Void rooms are never rewritten.

Saved references:
- Sphere/cube: `spatial_lab_9240714f95` (41.9 seconds save/export/check).
- Mixed, paused in the browser: `spatial_lab_ca573ae619` (42.1 seconds).

The reference run observed an unchanged main layout. The mixed run recorded an
external main-layout change during testing; this workflow only wrote its own
isolated trial and preserved that concurrent work. Neither pose extends outside
its trial slab or into the shafts, but both contain intentional overlapping
member envelopes. This is geometric evidence, not a walkability claim.

Receipts: `ada_run/spatial-studies-2026-11-13/references.json` and each referenced
trial's `ada_run/spatial-lab-2026-10-27/<trial>/checks.json` / `result.json`.
Screenshots: `ada_run/sphere-fractal-web/`.

## Live desktop controls

`tools/check_sphere_fractal_live.py` exercises the actual game camera, ray and
mouse-button dragging through all three physical sliders. It verifies automatic
motion, zero-speed hold and restart, matching visual/collision size, depth
rebuilds, retained member edits, static copies and frozen export poses. Receipts
and native pictures live in `ada_run/sphere-fractal-live/`. This does not certify
physical-headset interaction. The separate source/editor probe is still used to
verify the exported saved pose and actual member models.


## Staged mixed reference — 13 November 2026

`spatial_lab_ca573ae619` now frames the moving form with a 5.6 m square,
12 cm high charcoal deck, a freestanding ivory backdrop and pink edge strips.
The backdrop, feet, uprights, deck and strips are ten separate editable parts
made from existing construction boards and cubes. The control stand sits just
outside the motion envelope, on the front right. Walk around the deck to inspect
the inherited motion and its changing silhouette on the backdrop.

`studio_finish: true` applies local material overrides: black steel branches,
pink inner polyhedra and ivory tips. The source prefab scenes and materials are
unchanged. The editor exports the same finishes. The stage adapter supplies its
local recipe when placed from the catalogue; individual copies retain that
recipe and their material. No lights or main-tower arrangements were changed.

The complete form is raised 1.05 m. A conservative envelope for every rotation
phase, at size 1.8 m with ratio 0.5 and spacing 1.5, remains above the deck,
below the structural ceiling and clear of the backdrop and control stand.
This bound does not cover arbitrary member offsets, larger spacing or a changed
ratio; those edits need their own space review. Branch envelopes intentionally
overlap. Motion remains prescribed, not a linked rigid-body simulation.

The staged reference passes 30 native checks for real desktop slider input,
motion, materials, clearance, copied staging and independent edits; 478 source
and geometry checks; and editor move/rotate/copy/validate/save/reload checks in
an isolated fixture. The export references 170 actual GLB model files. This is
not physical-headset acceptance. Runtime slider settings remain session-only.

Screenshots: `ada_run/sphere-fractal-live/desktop-moving.png` and `controls.png`.

![Staged living fractal](evidence/sphere-fractal-staged.png)

![Pink physical controls](evidence/sphere-fractal-controls.png)


## Reuse the staging

In Spatial Lab choose **Black / pink / ivory studio** under **Presentation**.
The Three.js preview and new Godot trial use the same ten-part stage term and
material palette. **Original materials / no stage** keeps the source finishes
and omits the stage. This choice is saved alongside the recipe bindings and
restored by **Reuse recipe settings**. Existing saved arrangements are untouched.

The shared stage lives in `fractal_studio_stage` in `commons/modular/terms.json`;
its palette, placement and envelope limits are in `commons/modular/fractal_studio.json`.
Older trial-local stage recipes remain supported. All stage members remain
individually editable, including independent copies.

The stage supports a conservative 2.6 m motion radius over all four native depth
settings and the full native size-slider range. Oversized spacing/ratio choices
remain visible in the preview, with a warning and no staged save. Reduce those
relations or select no stage; the tool never shrinks the original automatically.
This bound assumes unedited member poses and the declared fitted collision boxes.

**Counter-rotating blocks** reuses the same rule with construction cubes, walkable
wedges and trace balls. The speed is 14 degrees/s, sag 14 degrees and reverse-spin
fraction 0.65. It is a prescribed moving sculpture, not a hinged physics assembly.

The saved mixed study is `spatial_lab_879ae4f288`, paused at 6.05 seconds in the
browser before saving. It contains 156 moving members, ten separate staging
pieces and a control stand. The main Void arrangement is not part of this edit.
Choose this preset to explore another combination, or use **Reuse recipe settings**
on the saved variation to recover its exact starting pose and presentation.

The native export runner now allows the shared slot's 20-minute queue budget
before its five-minute render budget. Previously the outer timeout could kill a
valid queued export while a desktop playtest or Quest build occupied the slot.

The mixed study passes 478 native source/geometry checks and 30 live desktop
input/motion checks. Its 170 exported model files and every member pose agree
with the web editor; independent move/rotate/copy, validation, isolated
save/reload and stale-save rejection pass. The ten staging pieces are included.
The main layout hash stayed unchanged during the successful check.

The variation saved in 0.106 seconds; the successful native export and placement
check took 25.375 seconds (12.769 export + 12.413 native process, plus receipt
work). The full first attempt took longer because a shared Quest export occupied
the native slot and missing station defaults required a correction. The durable
job receipt records that queue/recovery time separately from the successful run.
Physical headset interaction has not been tested.

Receipts: `ada_run/fractal-studio-reuse/live/checks.json`,
`ada_run/spatial-studies-2026-11-13/editor-checks.json`, and
`ada_run/spatial-lab-2026-10-27/spatial_lab_879ae4f288/result.json`.

![Counter-rotating cubes, wedges and spheres](evidence/fractal-blocks-desktop-moving.png)

![Speed, size and level controls](evidence/fractal-blocks-controls.png)
