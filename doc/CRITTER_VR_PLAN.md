# Critter VR Optimization Plan

> Status: 2026-05-06. Tier 1 + Tier 2-full + Tier 2.5 + **Tier 3b (impostor swarm)** shipped. Per-critter cost is 7–12 draw calls; per-swarm cost is **1 draw call regardless of N** with a recognisable-creature canonical mesh. 50-critter swarm measured at 501 → 1 draw call.

## Measured Tier 3b results (2026-05-06)

```
N = 50, walker kingdom, random DNA per member
LEFT   — 50 × CreatureMorphology + Tier 2.5 batched      501 draw calls
RIGHT  — 50 × SwarmRenderer impostor (one MultiMesh)       1 draw call
                                                         ━━━━━━━━━━━━━
                                                            501× reduction
```

Lab: `commons/testing/swarm_compare_lab.gd`. Side-by-side image at `user://swarm_compare.png`.

The impostor mesh (`commons/testing/swarm_renderer.gd:_build_canonical_critter_mesh`) is one ArrayMesh built from a body capsule + head sphere + tail cone + 4 leg cylinders, ~120 vertices total. Per instance:
- **Transform3D** scales it by `(girth, length × 0.5, girth)` based on `dna.scale` and `dna.segments`, with a random heading rotation
- **INSTANCE_COLOR** carries `dna.primary_color`
- **INSTANCE_CUSTOM** packs `(iridescence, secondary_luma, tertiary_luma, 2.0 = swarm flag)` for the eventual shader-aware version (Tier 3c)

For Tier 3b the material is `StandardMaterial3D` with `vertex_color_use_as_albedo = true` — per-instance colour drives appearance with zero shader work. Tier 3c will swap this for the trait-mapper shader once the per-instance reading is wired (the `2.0` swarm flag in `INSTANCE_CUSTOM.w` is the discriminator).

## VR budget impact, updated

```
Before any batching (Tier 0):
  150 baseline + 80 per critter
  → ~3 critters fit in ~300 draw call Quest 3 budget.

Tier 2-full + 2.5:
  150 baseline + ~10 per critter
  → ~15 critters fit comfortably.

Tier 3b (this PR):
  150 baseline + ~10 per HERO critter + 1 per swarm of N
  → 5 hero critters + multiple 50-creature flocks
                  comfortably within budget.
```

A 200-critter ecology with 4 hero critters (named, full-detail, bondable) and 4 swarms of 50 (MultiMesh impostors) costs `4 × 10 + 4 × 1 = 44` draw calls. Previously it would have cost `200 × 80 = 16,000` — 53× over budget.

## Measured Tier 2-full results

Sweep across one variant per archetype, LOD 3, with limbs + tips + body all batched into per-bucket MultiMeshes (head / eyes / antennae remain as individual MeshInstance3Ds):

```
archetype                raw   bat  saved    %cut
----------               ---   ---  -----    ----
bug_beetle_03             31     7     24   77.4%
larva_worm_05             77     7     70   90.9%
walker_quad_03            36    12     24   66.7%
flier_wing_02             66    11     55   83.3%
alien_crab_05             76    10     66   86.8%
----------               ---   ---  -----    ----
TOTAL (5 critters)       286    47    239   83.6%
```

Numbers measured by `commons/testing/critter_drawcall_compare.gd`. Walker_quad keeps more individual mesh instances because its limb count is below the batching threshold per leg-pair. Larva_worm hits 91% reduction — a long worm has many body segments and limbs all sharing one DNA.

For comparison with the limb-only Tier 2 prototype (43% aggregate), this run more than doubled the savings by also batching tips + body.

### Tier 2.5 — per-instance taper + tint (shipped same day)

Tier 2-full collapsed limbs/body/tips into one MultiMesh each, but the trade-off was visual: limbs lost taper (uniform-radius cylinders instead of tapered tubes), and body lost its per-segment alternating darkness (one MultiMesh = one material).

Tier 2.5 restores both via per-instance shader inputs that don't add draw calls:

- **Taper via `INSTANCE_CUSTOM`** — `creature_morphology.gd` now stamps `limb_start_radius` and `limb_end_radius` (and `body_start_radius`, `body_end_radius`) separately. The batcher writes `taper = end_radius / start_radius` into `INSTANCE_CUSTOM.x`, sets `INSTANCE_CUSTOM.w = 1.0` as an "apply-transform" flag, and the basis uses `start_radius` for xz scale (so the bottom matches). The shader's vertex stage reads `INSTANCE_CUSTOM` and scales `VERTEX.xz` by `mix(1.0, taper, t)` where `t` is the unit cylinder's normalised Y. Default `INSTANCE_CUSTOM.w = 0.0` (for non-MultiMesh meshes that share the same shader material) leaves geometry untouched.
- **Body alternating tint via `INSTANCE_COLOR`** — `body_index` is stamped per segment; the batcher writes `Color(0.92, 0.92, 0.92, 1.0)` for odd segments and white for even, matching `creature_morphology`'s original `darkened(0.08)`. The fragment shader's existing `base_color *= v_instance_color.rgb` reproduces it across all instances of one MultiMesh.

Net effect: draw-call counts unchanged (still 83.6% reduction); the batched critter visually matches the un-batched one again. As a bonus, the per-instance plumbing is exactly what Tier 3 swarm batching needs — different DNAs in one MultiMesh will pack `primary_color`, `surface_type`, and pattern into the same channels.

## VR budget impact

```
Before any batching (Tier 0):
  150 draw calls baseline (terrain/UI) + 80 per critter
  → ~3 critters fit in ~300 draw call Quest 3 budget.

After Tier 2-full (this PR):
  150 baseline + ~10 per critter
  → ~15 critters fit comfortably. 30 if we drop the baseline overhead.

After Tier 3 (swarm batching, queued):
  150 baseline + ~10 per HERO critter + 1 per swarm of N
  → 5 hero critters + multiple 50-creature flocks.
```

## Why this matters

## Why this matters

Quest 2 / Quest 3 native rendering needs to stay under ~300 draw calls per frame to hit 72 fps consistently. Each `MeshInstance3D` is one draw call. Each `MultiMeshInstance3D` is one draw call regardless of instance count.

The current critter pipeline does NOT batch:

| Configuration | Draw calls |
|---|---|
| 1 critter, LOD 2, full anatomy | ~80 |
| 1 critter, LOD 0 (close, max detail) | ~110 |
| 5 critters in view | ~400 — **already over budget** |
| 50-critter swarm | ~5,700 — **20× over budget** |

The non-critter VR scene already costs ~150 draw calls (terrain, biome layers, hazards, UI). That leaves ~150 for living things across the whole world. We need 50–500× the headroom we currently have for any meaningful ecology.

## The plan, in three tiers

### Tier 1 — shipped (2026-05-05)

1. **Limb seam fix**: `creature_morphology.gd:260` — limbs now start at `seg_pos + limb_dir * (seg_radius - limb_overlap)` with `limb_overlap = limb_radius * 1.5`, so the limb's first ring is *inside* the body. Result: solid silhouettes, no visible joint gap.
2. **Critter DNA gallery + Pokemon Studio link on /dna**: 60 sampled CreatureMorphology variants covering bug → larva → walker → flier → alien archetypes, each as a static T-pose for inspecting silhouettes and per-critter draw cost.
3. **Trait-mapper shader bug fix** (relevant to Tier 2 because MultiMesh uses the same materials): the shader's `if (transparency > 0.05) ALPHA_SCISSOR_THRESHOLD = 0.1` (`critter_dna.gdshader:463`) was discarding fragments wholesale because the trait mapper feeds `dna.transparency` straight through, even when the DNA picks a small but non-zero value (e.g. 0.07). Gallery labs now zero that uniform via a `_zero_transparency(node)` post-pass. Production note: the dispatcher's `_spawn_*` paths likely have the same problem in VR.

### Tier 2 (limbs only) — prototype shipped (2026-05-05)

4. **`commons/testing/creature_batcher.gd`** — post-process pass that collects every `Limb_*` `MeshInstance3D` under a critter root, reads new `limb_start` / `limb_end` / `limb_radius` metadata that `creature_morphology.gd` now stamps on each limb segment, builds one `MultiMeshInstance3D` of unit cylinders sized + positioned per segment, frees the originals. Material from the first matched limb is reused — every limb of one critter shares one DNA → one shader material → one MultiMesh works.
5. **`commons/testing/critter_drawcall_compare.gd`** — A/B sweep that builds the same DNA twice (raw vs batched), prints draw-call deltas, renders a side-by-side image. Confirms 35–53% reduction per critter, 43% in aggregate.

### Tier 2 — per-critter MultiMesh consolidation

**Goal**: cut a single critter from ~80 → ~6 draw calls.

**Approach**: in `creature_morphology.gd`, the limb pass currently spawns ~32–64 `MeshInstance3D`s (every limb segment is its own node). Each segment is a *cylinder tube of varying radius*. We can:

1. Define **one canonical limb segment mesh** — a unit cylinder, 6-sided, 1m tall, 1m radius. Store as a static `Mesh` resource on the morphology class.
2. Create **one `MultiMeshInstance3D` per critter** for limbs.
3. For each limb segment, instead of building a tube mesh and adding a `MeshInstance3D`, compute the segment's `Transform3D` (translate, rotate to direction, scale by `(radius_scale, length, radius_scale)`) and append it as a multimesh instance.
4. For tapering: bake the taper into the canonical mesh (vertex-color alpha → vertex shader scales radius along Y) OR use two cylinder instances (start radius, end radius) per segment — still cheaper than separate meshes.

**Estimated win per critter**:

| Part | Before | After |
|---|---|---|
| Body segments | 10 mesh instances | 10 mesh instances (or 1 multimesh of 10) |
| Limb segments | 32–64 mesh instances | **1 multimesh** |
| Head + eyes + antennae | 5 mesh instances | 5 mesh instances |
| Tip / claws | 32 mesh instances | **1 multimesh** |
| Tail | 3 mesh instances | 3 mesh instances |
| **Total** | ~80 | **~20** |

A second pass batching body segments + tail into another multimesh brings it to ~6. This is the biggest single win for VR perf.

**Risk**: medium. Touches `creature_morphology.gd` heavily. Needs careful testing because the existing system is consumed by `CritterSpawner`, `Pokemon Studio`, and `BiomePaintDispatcher._spawn_creature`. Build a parallel `creature_morphology_batched.gd` first, A/B test, then decide whether to replace or coexist.

### Tier 3 — swarm MultiMesh

**Goal**: 50 swarm critters → 1 draw call.

**Approach**: in `algorithms/nature_system/systems/spawner.gd`, when `CritterSpawner.spawn(dna, position)` is called and the spawner detects:

- `dna.sociality > 0.7` (swarming gene high)
- `CritterDNA.distance(dna, last_swarm_dna) < 0.15` (similar enough)

…then instead of building a fresh `CritterEntity`, append the new spawn as an instance to a shared `MultiMeshInstance3D` for the canonical "swarm critter" of that DNA cluster. Per-instance variation is communicated via:

- Per-instance `Transform3D` (position + rotation + small scale variation)
- Per-instance `Color` (drift on the DNA's primary_color so each member of the swarm reads slightly different)
- Per-instance custom data Vec4 (bond level, age phase, etc., consumed by the shader)

For animation (when reintroduced): the multimesh instances get their transforms updated each frame from a CPU-side particle / boid simulation. CPU pays for behaviour; GPU pays only for the one batched draw.

**Estimated win**:

| Configuration | Before | After |
|---|---|---|
| 50 similar-DNA flock | ~5,700 calls | **1 call** |
| 200 mixed creatures (4 distinct species) | ~22,000 calls | **~4 calls** |
| 1 hand-bonded named pet (full DNA) | ~80 calls | unchanged (we want detail) |

The "1 hand-bonded pet" case is important: nearby/important critters keep their full per-critter mesh tree so they can be inspected, bonded, named. Distant flock members are MultiMesh impostors. The transition between modes is a follow-up (Tier 3.5: LOD impostor swap).

**Risk**: medium-high. The behavioural code in `CritterEntity` (bonding, age, breed lifecycle) currently assumes one critter = one Node3D. Swarm members can't have full lifecycle — they're rendering-only impostors. Need to formalize a `SwarmMember` lighter struct that holds DNA + transform but no individual scene node. Pokemon Studio's BreedingLab and naming/collecting features must continue to work on the "full critter" path; only ecology spawns get swarmed.

### Tier 3.5 — LOD impostor swap (longer-term)

When a critter is far from the player, replace its mesh tree with a single sprite (billboard) or a low-poly impostor mesh. When the player approaches a swarm, the nearest N critters "unfold" into full mesh trees; the rest stay as MultiMesh instances.

This is the same pattern Unity / Unreal use for crowds. Requires:

- A "critter impostor" texture renderer (offline, like our gallery lab — render each canonical DNA cluster from N angles, save sprite atlas)
- A distance-based unfold/fold system in `CritterSpawner`
- A budget cap (max-N nearby full critters)

## Build order recommendation

1. **Now**: ship Tier 1 (done).
2. **Next session, ~90 min**: Tier 2 prototype as `creature_morphology_batched.gd`, side-by-side gallery (60 critters in batched vs unbatched draw call counts) so we can measure exactly.
3. **Following session, ~120 min**: Tier 3 swarm path in `spawner.gd`, gated behind a feature flag (`use_swarm_batching` in `biome_config.json`). Test with the catalyst-foe maps that already deploy 4-creature peer-infection patterns.
4. **Future**: Tier 3.5 impostor system once we have spare time and need it.

## Files touched in Tier 1

- `algorithms/nature_system/morphology/creature_morphology.gd` — limb seam fix at line 260–267
- `tools/generate_critter_dna_gallery.py` — new
- `commons/testing/critter_dna_gallery_lab.gd` — new
- `commons/testing/smoke_critter_dna.gd` — new
- `ada_encyclopedia/src/app/critter-dna/page.tsx` — new
- `ada_encyclopedia/src/app/dna/page.tsx` — added Critter DNA + Pokémon Studio entries
- `ada_encyclopedia/src/components/layout/app-header.tsx` — added Critter DNA nav

## Files to touch in Tier 2/3

- `algorithms/nature_system/morphology/creature_morphology_batched.gd` — NEW (parallel to existing creature_morphology.gd)
- `algorithms/nature_system/systems/spawner.gd` — extend with swarm dispatch path
- `algorithms/nature_system/critter_entity.gd` — accept a `_render_mode: enum {FULL, SWARM_MEMBER, IMPOSTOR}` so behaviour code can branch
- `commons/biome_layers/biome_paint_dispatcher.gd:_spawn_creature` — opt into swarm batching when sociality is high

## Open questions for the next iteration

1. Does the trait-mapper shader's MEMBRANE / FUR / SCALES variation matter visually enough to keep the shader path, or can we ship a `StandardMaterial3D` baseline and only re-enable shader for hero critters?
2. Is the body-segment-to-segment seam (still subtly visible after Tier 1) worth a SurfaceTool-based combined-body mesh that produces one closed body silhouette? Or does Tier 2's body-multimesh hide it via shader tricks?
3. For the catalyst-foe transformation arc (cube-foe ↔ goo ↔ swarm friend), do we need per-critter mesh continuity, or is a discrete swap acceptable visually?
