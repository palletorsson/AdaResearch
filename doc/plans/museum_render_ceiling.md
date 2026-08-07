# The honest ceiling — what a procedural museum can and cannot look like

> Critic report, 2026-08-07, after three render rounds on `commons/scenes/endless_museum.gd`.
> The brief was the harshest question available: *if this frame sat in a store-page gallery
> beside a current AAA first-person title, what would a player notice FIRST as the tell?* —
> and for each tell, is it reachable procedurally, or does it structurally need an art team?
>
> **No side-by-side with Call of Duty was performed.** No such frames were obtainable in this
> session, and every critic was instructed to say so rather than fabricate one. What follows is
> criteria-based judgement with pixel evidence, which is worth more than a claimed comparison.

## The four tells, in the order a player clocks them

### 1. The frames contain architecture and no objects — and the surfaces contain no features
A 420×360 crop of the left wall in `aaa_axis` (about 2 m² of plaster) contains exactly one
feature: a light blob. No socket, no vent, no seam, no scuff, no signage. A player scanning a
gallery for half a second reads **blockout** before they read anything about materials.

**Reachable — and the cheapest week available.** The reason is specific: what makes a prop read
as authored is silhouette complexity plus placement that implies use, and for the objects a
museum corridor actually holds — bench, vitrine, stanchion, radiator, floor grate, cable tray,
extinguisher, socket, door closer, handrail — silhouette complexity is *rectilinear and
parametric*. These are manufactured objects, designed from dimensions in the first place, which
is exactly a generator's input. A photoscan adds nothing to a floor grate.

And on placement the generator is **advantaged** over a hand-dressed level: it knows every door,
light, wall run and walker path, so it can put the bench opposite the plaque and the grate under
the downlight by rule, consistently, forever. That is a strength this project is not spending.

*The wall inside this bucket:* the **semantic** prop — a painting, a poster with real
typography, a discarded cup with a brand — objects that exist because a person chose *this
specific thing*. Not derivable. Also out: organic silhouettes (cloth, foliage, bodies), which
need sculpting or simulation, not a noise field.

### 2. Light with no body and no shadow
The floor pool in `aaa_hero` is a parabolic white blob with near-binary edges and a hard
horizontal cut where the light stops. No fixture above it, no shaft, no bounce. The wall blobs in
`aaa_axis` are perfect isotropic gaussians with no scallop. They read as **decals projected on
geometry**, which is functionally what they are: `em_lighting.gd` sets `shadow_enabled = false`
on most of the rig under a budget allowance, and `sdfgi_read_sky_light = false` is why every room
seen through a doorway is a black void.

**Reachable, and partly a config change.** Luminaires are boxes with an emissive face. A
soft-edged aperture cookie for `SpotLight3D.light_projector` is a radial `Gradient` — simpler
than the textures already generated. The design correction is arithmetic, not tech:

> **Three to six shadow-casting lights will look dramatically better than twenty shadowless
> ones. A shadowless light is not a cheap light; it is a light that actively produces the decal
> artifact.**

*Structurally unfixable:* SDFGI convergence latency in a **streamed** scene — a segment built
ahead of the walker takes frames to settle, so turning a corner shows a room brightening. Baking
is the only real answer and baking is unavailable here. It does not affect a still, and
overshooting the streaming radius mitigates it, but it will never be exactly right.

### 3. Junctions are stamped strips that do not mitre
Chamfers *do* exist now (`_add_arris_beads`, `_add_skirt_chamfers`, `_ch()`) and a facet clearly
catches light on the jamb pier. The residual fault is **termination and hierarchy**: the chamfer
ends in a hard square cut with a dark notch where it fails to meet the skirting; three chamfer
boxes stack at mismatched depths at a column base; the beam soffit has none. And every chamfer is
one width, where real architecture runs a hierarchy — ~2 mm arris on a door reveal, ~20 mm
bullnose on a skirting, ~60 mm profile on a cornice.

**Completely reachable, and the highest AAA-per-line item on the list.** A mitred corner is a
solved geometry problem with a closed form; a stamped box always ends in a square cut, and *the
square cut is the artifact*. Nothing an artist knows about a mitre is unavailable to a
generator — a mitre is literally a bisected angle. Emit an `ArrayMesh` per face with its chamfer
built in, cache by rounded dimension, and the terminations disappear. Human vision resolves edges
before surfaces, which is why this beats another texture pass.

### 4. The materials are stationary — nothing knows where it is
**This is the split, and it is the most useful paragraph in the report.**

`FastNoiseLite` is *stationary*: its statistics are identical at every point in space, by
construction. Real weathered surfaces are the exact opposite — **non-stationary and causal**. The
black smear is at the bottom of the wall because feet are there. The shine is at 95 cm because
hands are there. The chip is on the outer corner because a trolley hit it. Every one of those is a
fact about **where things happen in the room**, not a fact about the material, and no noise
function can derive it, because a noise function does not know where the floor is.

**But the generator does.** It knows the floor plane, the door positions, the light positions, the
wall corners, and — because the scene streams around a walker — the actual traffic line. So
contact history is reachable *if and only if stationarity is broken* by modulating materials with
scene-derived fields: a world-Y gradient darkening and roughening the bottom 15 cm of every wall
(one line, and it reads instantly as "a room that has been walked in"), a proximity term to the
nearest perpendicular wall for corner grime, a roughness dip around each door edge at hand
height, soot above lights. The price is moving off `StandardMaterial3D` to a `ShaderMaterial` or
`next_pass` that can see world position. Worth paying.

*What stays permanently out of reach:* the correlated micro-truth of a real surface at nose
distance. Photoscanned limestone has albedo, normal and roughness correlated by 300 million years
of deposition and eighty years of janitors — correlations that encode **events**. Noise encodes
**statistics**. The honest formulation: **materials will read right at arm's length and wrong at
nose length**, and the design answer is to control viewing distance rather than chase the texture.

## Two outright defects to fix regardless
- `aaa_threshold`: the plaque text is clipped at the left edge — "nsbury Wing, National Gallery".
- `aaa_hero`: a blue wireframe box on a distant object reads as a **debug gizmo** in shot.

## The honest ceiling

With no authored art, no photogrammetry and no bake, the reachable ceiling is **high-end
architectural walkthrough / stylised first-person** — the register of *Tacoma*, *The Witness*,
*NaissanceE*, *Manifold Garden*. **Not photoreal AAA, and not close to it.**

That is a better outcome than it sounds, because the win condition was never "beat Call of Duty".
It is crossing the line from **unfinished** to **deliberate**. These frames currently read as a
blockout. At the ceiling they read as a chosen aesthetic — and a chosen aesthetic does not get
compared to a shooter's texture budget at all. *The comparison simply stops being made, which is
the only version of winning available here.*

## The work, in ratio order

1. **Mitred junctions with a real edge hierarchy** — arithmetic, cheapest, biggest perceptual return.
2. **Fewer lights, with shadows and visible fixtures** — mostly config and design, not new tech.
3. **Hand-scale rectilinear props placed by rule** from the graph the generator already has.
4. **Materials modulated by world position** so surfaces know where they are.

All four are procedural. None requires an artist, a scanner, or a bake. What permanently caps the
scene is exactly two things, both worth accepting rather than fighting: semantic content, and
micro-surface truth at nose distance.
