# Catalyst Abilities × Friend/Foe × Hazards — Catalog and Improvement Plan

> 2026-07-11. Mapped by two Opus 4.8 audit agents (catalyst system + hazard system), verified against
> current code. Status legend: REAL (exists + wired), PARTIAL, DESIGN-ONLY.

## 1. What exists today

### Catalyst modes (the timeline abilities)

Authoritative registry: `MODE_DEFS` in `commons/hazards/becoming_catalyst/becoming_catalyst.gd:27`.

- **10 REAL projectile modes**, each themed to a spine sequence, each with `modes/mode_<x>.gd` +
  `<x>_projectile.gd`: primitives, transformation, chromatic (color), forces, waveform
  (wavefunctions), chaos (randomness), cellular (CA), fractal, branching (lsystems), swarm.
- **7 editor-tool modes** (voxel_editor, wedge_placer, artifact_edit, lab_edit, biome_brush,
  modifier, utility_edit) — unlocked by default.
- **4 DESIGN-ONLY modes** named in `soft_stages.json` with no mode file: `array`, `change`,
  `isosurface`, `csg`.
- **11 spine sequences have NO catalyst mode**: symmetry, formfinding, noise,
  proceduralgeneration, softbodies, machinelearning, graphtheory, foundationscrisis,
  qfeplaboratory, postfoundationscrisis, mosaicanalysis.
- Progression: `CatalystCapabilityManager` (autoload, REAL) tracks capacity ladder L1–L6
  (Observe/Touch/Manipulate/Construct/Control/Embody), hand_verbs, movement_abilities,
  catalyst_modes; unlock on `sequence_completed`. **No persistence** — `save_state()` and
  `_save_unlocked_modes()` are both `pass`.

### Friend/foe (the misaligned critters)

- `commons/hazards/catalyst_foe/catalyst_foe.gd` extends `HazardCreatureBase`
  (`commons/hazards/hazard_creature_base.gd`) — the base gives ALL ~43 hazard creatures the
  personality arc `foe → wary → neutral → curious → friend`; each catalyst hit advances ONE step.
- Only **4 friend behaviors** (`FoeMode`): GOO (convert peer on contact), TRANSPORT (shove peer
  away), SWARM (fast, 2× wave), DRAINFRIEND (drags a friend back — entropy). Five modes
  (primitives, chromatic, waveform, fractal, branching) all collapse to GOO.
- **A converted FRIEND grants the player nothing.** It follows the player and chases foes;
  no call into `CatalystCapabilityManager`, no unlocked verb, no lasting power. This is the
  headline gap — "critter becomes a power for the player" is DESIGN-ONLY.
- `soft_stages.json` `enemies.kind` is data-only — `CatalystFoe` derives foe_mode from the
  projectile's mode_id, never from the sequence.
- `CatalystVentScanner.gd` (editor `e:` token → vent) is UNWIRED — not autoloaded, never called.
- Two disconnected creature/ability lineages: `HazardCreatureBase` (combat, catalyst arc) vs
  `algorithms/nature_system/` CritterEntity + `transmutation_manager.gd` (bond → 24 latent
  abilities). No bridge.
- Real named creatures on disk: miura_crawler, kaleidocycle, fractal_hydra (each .gd+.tscn).
- Placement: 10-map `Catalyst_01..10` test ring (sequence `catalyst_test`, NOT in spine);
  pedestals in 41 maps; the full vent/foe loop only in the test ring + Chamber_Primitives family.

### Static hazards (the environments to cross)

Engine: `commons/hazards/DangerZone.gd` (REAL, 6 types), token `h:` in `UtilityRegistry.gd:120`.

| Token | Damage model | Visual |
|---|---|---|
| `h:fire` | 10 dmg / 2.0s tick, ramps ×4 with heat | flames + pulsing light |
| `h:vacuum` | O₂ depletes, damage below 50 | fresnel sphere + suction |
| `h:electric` | ×2 burst / 1.5s + screen flash | tesla sphere + sparks |
| `h:toxic` | ×0.7 / 0.5s (linger TODO) | slime floor + vapor |
| `h:radiation` | ×0.5 / 0.5s (Geiger TODO, no visual) | PARTIAL |
| `h:death` | instant kill | red cross |

- `f:` force_field token — "hazard that transmutes into benefit" (QFEP dual-nature) — is
  registered but has an **empty scene binding and zero placements**. It is the static
  prefiguration of the foe→friend flip.
- `transformation_blocks/` (grower/pusher/sweeper) — CODE-ONLY, no token, no map.
- No laser/crusher/timed-platform hazard exists.
- **Placement: 4 maps total contain `h:` tokens; only 1 is in the spine** — `Trans_Pit` (fire),
  the capstone of `transformation` (spine order 2). `Lab_Death` (all-type gallery),
  `Zone_ForbiddenWetLab` (toxic), `VFM_Catalyst_Chamber` (fire) are orphaned from all sequences.
  Spine sequences 1 and 3–24: zero static hazards.
- Death flow is forgiving (supports early hazards): hurt = red flash + teleport to spawn +
  3s immunity, health retained; death = full reset to Lab via death scene.
- `tools/map_pathfinder.py` is **hazard-blind** — `h:`/`f:` cells are free walkable cells.

## 2. The intended arc (design)

**Static before dynamic.** The environment is the first opponent; the critters come later; the
catalyst turns opponents into powers.

1. **Act I (spine 1–6) — static hazards.** The world itself is misaligned: fire pits, toxic
   floors, electric fences. Crossing is spatial reasoning (the era of geometric/deterministic
   algorithms — matches the timeline theme). Introduce `f:` force fields late in Act I: the first
   thing that *flips* — a hazard that becomes a benefit when approached correctly. Static
   prefiguration of the catalyst.
2. **Act II (spine 7–14) — dynamic foes + catalyst.** Simulation-era sequences (forces, waves,
   randomness, CA, fractals, lsystems, swarm) introduce vents and foes. The catalyst mode themed
   to each sequence is earned there.
3. **Act III (spine 15–24) — friends as powers.** Conversion is no longer just defense: each
   friend kind grants the player an aligned ability. By QFEP the player walks with an ecology of
   powers.

## 3. The ability system — friend kind → player power

Rule: **while at least one FRIEND of a kind is alive and following, the player holds that kind's
power**; the first-ever conversion of a kind permanently registers the verb in
`CatalystCapabilityManager` (so powers survive map transitions once persistence exists).
Powers deliberately answer the Act I hazards — friends become the crossing solution.

| Spine seq | Mode | FoeMode today | Proposed friend kind | Player power |
|---|---|---|---|---|
| primitives | primitives | GOO | SHIELD | friend orbits, absorbs one hazard/foe hit |
| transformation | transformation | TRANSPORT | PORTER | friend shoves path_blocks — bridges gaps/pits |
| color | chromatic | GOO→ **CHROMA** | NEUTRALIZER | friend standing in a DangerZone mutes its damage |
| forces | forces | SWARM | LAUNCHER | friends cluster underfoot → jump boost (movement_ability) |
| wavefunctions | waveform | GOO→ **WAVE** | CALMER | friend emits slow-wave, foes in radius half speed |
| randomness | chaos | SWARM | DECOY | foes target the chaotic friend instead of player |
| cellularautomata | cellular | DRAINFRIEND | REPLICATOR | friend's peer-conversion yields 2 friends (growth rule) |
| fractals | fractal | GOO→ **FRACTAL** | SPLITTER | friend splits in two when hit instead of reverting |
| lsystems | branching | GOO→ **BRANCH** | BRIDGER | friend grows a walkable tendril (path_passable) over hazard cells |
| swarmintelligence | swarm | SWARM | ESCORT | flock forms a moving shield-wall around player |

The 5 bolded kinds break the GOO collapse — every mode gets a distinct friend identity.

## 4. Punch list (priority order)

1. **Friend→power hook** (the missing spine of the whole design): when a creature reaches
   FRIEND, `CatalystFoe` calls `CatalystCapabilityManager.grant_friend_power(mode_id)`;
   manager stores it beside hand_verbs. Emit a signal so HUD/screens can react.
2. **Persistence**: implement `CatalystCapabilityManager.save_state()` +
   `BecomingCatalyst._save_unlocked_modes()` (user:// JSON). Without it every power resets.
3. **Front-load static hazards** (content, no engine change): rescue the orphans — wire
   `Lab_Death` as a safe "dumb ways to die" gallery into `primitives`; add small `h:` crossings
   to one map each in symmetry, color, change; keep `Trans_Pit` as-is. Bind the `f:` force_field
   scene and place its first instance at the end of Act I (change or forces).
4. **Pathfinder hazard-awareness** (grid discipline: same change as #3): treat `h:death` as
   blocked, other `h:` as high-cost; add a negative test (a map whose only path crosses
   `h:death` must fail validation).
5. **Break the GOO collapse**: add CHROMA/WAVE/FRACTAL/BRANCH friend kinds (contact rules +
   badges) so all 10 modes are distinct in `MODE_BY_ID`.
6. **Consume `soft_stages.json` enemies.kind**: vents seed spawned foes' default kind from the
   sequence, so maps don't need per-vent overrides.
7. **Wire `CatalystVentScanner`** into GridSystem post-load so editor `e:` tokens work in VR.
8. **Bring the loop into the spine**: catalyst_test stays a test ring; the real home is the
   Chamber_* capstones — build the vent/foe loop into the Act II chambers (Forces, Waves,
   Random, CA, Fractals, LSystems, Swarm) that already have pedestals.
9. Later: modes for the 4 DESIGN-ONLY names (array/change/isosurface/csg) or remove them from
   soft_stages; bridge to nature_system's transmutation abilities (or explicitly keep separate);
   VR win/lose HUD.

## Source files (quick nav)

- Modes: `commons/hazards/becoming_catalyst/becoming_catalyst.gd` (MODE_DEFS L27,
  unlock L2999, save stub L3068), `modes/mode_*.gd`
- Foe: `commons/hazards/catalyst_foe/catalyst_foe.gd` (FoeMode L51, hit L141, friend chase L241)
- Arc: `commons/hazards/hazard_creature_base.gd` (PERSONALITY_ARC L16, _apply_personality L433)
- Manager: `commons/managers/CatalystCapabilityManager.gd` (save stubs L489)
- Hazards: `commons/hazards/DangerZone.gd` (types L8, notation L558),
  `commons/grid/UtilityRegistry.gd` (h: L120, f: L127)
- Death: `commons/managers/DeathEffect.gd` (hurt/immunity L15/L128), `GameManager.gd` (L285–395)
- Placement truth: only `Trans_Pit` (spine seq 2) has in-spine `h:` tokens; orphans =
  `Lab_Death`, `Zone_ForbiddenWetLab`, `VFM_Catalyst_Chamber`
