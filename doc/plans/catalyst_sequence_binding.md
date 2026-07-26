# Catalyst Sequence Binding — the catalyst knows where it belongs

> 2026-07-26. Builds on `catalyst_ability_hazard_map.md` (2026-07-11 audit).
> Code: `commons/hazards/catalyst_sequence_binding.gd` (the canonical table),
> `becoming_catalyst.gd` (home_sequence), `catalyst_vent.gd` (brood binding).
> Test ring: sequence `catalyst_lab` (6 maps). Smoke:
> `commons/testing/smoke_catalyst_sequence_binding.gd`.

## The relation

The catalyst and its counterpart (the foe) are the same becoming seen from
two sides: the catalyst is the hand that gives color, the foe is the grey
body missing it. Before this change the relation existed only implicitly,
scattered across three files. Now one sequence name binds the triple:

| Sequence | Catalyst mode | Foe kind (brood) | Friend power |
|---|---|---|---|
| primitives | primitives | goo | shield |
| transformation | transformation | transport | porter |
| color | chromatic | chroma | neutralizer |
| forces | forces | swarm | launcher |
| wavefunctions | waveform | wave | calmer |
| randomness | chaos | swarm | decoy |
| cellularautomata | cellular | drainfriend | replicator |
| fractals | fractal | fractal | splitter |
| lsystems | branching | branch | bridger |
| swarmintelligence | swarm | swarm | escort |

Sources of truth mirrored: `BecomingCatalyst.MODE_DEFS` (mode column),
`CatalystFoe.MODE_BY_ID` (foe kind), `CatalystCapabilityManager.FRIEND_POWERS`
(power). The smoke test fails if the table drifts out of sync with any of
the three.

## How each side knows its sequence

**Catalyst** (`becoming_catalyst.gd`):
- **Passive knowledge** — at `_ready` the crystal records the running
  sequence from `AdaSceneManager` into `home_sequence`. No behavior change;
  `get_home_sequence()` / `get_native_mode_id()` expose it.
- **Armed binding** — token `becoming_catalyst#sequence:<name|auto>`
  (also forwarded through `catalyst_pedestal`): resolves the sequence,
  unlocks its native mode, and selects it as the active stone. A sequence
  with no table entry logs "knowledge only" and changes nothing.

**Counterpart** (`catalyst_vent.gd`):
- Token `catalyst_vent:0:0#sequence:<name|auto>` — the vent resolves the
  SAME table and seeds every spawned foe's kind from it (lazily, at first
  emit, so the scene manager is ready; retries while no sequence resolves).
- `foe_mode:auto` is shorthand for `sequence:auto`, so the editor utility
  token `e:RATE:WAVE:DELAY:auto` also works.
- Explicit `foe_mode:<kind>` always wins over the sequence binding.

## Who names whom (the counterpart asymmetry)

A vent may seed its brood's kind, but `CatalystFoe.hit_by_catalyst_mode`
re-locks the lineage at the FIRST hit on a creature still in "foe". So:

- **Raw foes**: the catalyst's mode overwrites the vent's seed — the
  catalyst names the unformed.
- **Pre-warmed creatures** (`initial_state:wary/neutral/curious`): past
  "foe", they keep the vent's lineage — the counterpart remembers who
  touched it first.

`CatalystLab_05_Mismatch` stages exactly this: a chromatic catalyst against
two cellularautomata-bound vents, one raw, one curious.

## The catalyst_lab test ring

Six 12×10 arenas, sequence `catalyst_lab` (layer: test, not in spine).
See `commons/maps/sequences/catalyst_lab_README.md` for the per-map table.
The older `catalyst_test` ring still covers the 10-mode roster; this ring
covers the binding logic: negative test (01), matched pairs (02–04),
mismatch (05), chain propagation (06).

Regenerate: `python tools/generate_catalyst_lab_maps.py` then compact.

## Fixed in passing

`GridInteractablesComponent.CONFIG_PARAM_NAMES` never listed the catalyst
family's keys, so `wave_size:5` arrived as boolean `true` (= wave of 1)
and `emit_interval_s:2.0` collapsed to 1.0s in EVERY map that placed vents
via interactables tokens — including the original `Catalyst_01..10` ring.
The authored tunables now actually apply. (The `e:` utility tokens went
through a different parser and were unaffected.)

## The timed lease (BUILT 2026-07-26)

Token: `catalyst_pedestal:0:0#sequence:auto#lease_s:20`. Test map:
`CatalystLab_07_Lease`. Smoke: `smoke_catalyst_lease.gd`.

How it works — three actors, one handshake:

1. **Crystal** (`becoming_catalyst.gd`): takes `lease_s` config (pedestal
   forwards it). On absorb it reports the lease to the manager and does
   nothing else — the crystal can't keep time because it is freed and
   recreated on every map transition. On expiry the manager calls its
   `end_lease_dissolve()`: farewell haptic, gone from the hand.
2. **Manager** (`CatalystCapabilityManager.gd`): owns the clock
   (`begin_lease` / `is_lease_running` / `get_lease_remaining` /
   `end_lease_now`, signals `lease_started` / `lease_ended`). Haptic
   ticks the last 3 seconds. On expiry it dissolves absorbed crystals,
   frees the bracelet, and clears `_bracelet_activated` so scene
   transitions stop respawning them. **The lease returns the TOOL, not
   the knowledge** — unlocked modes, friend powers, capacity all persist.
3. **Pedestal** (`catalyst_pedestal.gd`): with `lease_s` set it survives
   the pickup — cage fades and hides instead of `queue_free`. Its own
   return countdown (lease + 1.5s grace, started at pickup) re-materializes
   the cage and grows a fresh crystal carrying the remembered config
   (sequence binding, lease, mode seeds). Re-pickup restarts the window.
   If the player leaves the map mid-lease, the crystal still dissolves on
   the manager's clock; the pedestal comes back fresh with the map.

## Next: placement in the spine

1. **Placement** — one pedestal per spine sequence, early-to-mid map:
   `catalyst_pedestal:0:0#sequence:auto#lease_s:<N>`. The binding table
   arms the right mode per sequence; sequences without a binding entry
   (11 of them) need modes designed first, or the pedestal grants
   knowledge only.
2. **Counterpart pairing** — the same maps place vents with
   `sequence:auto`, so the encounter is always the matched pair; mismatch
   encounters (foreign-mode catalyst vs local brood) become a deliberate
   late-game device, not an accident.
3. Chamber_* capstones (already inserted after theme events) stay the
   full vent/foe loop homes; the lease pedestals are the APPETIZER at
   sequence start, the chamber is the meal.
4. Later polish: countdown readout on the bracelet/mode label; a
   lease-aware vent that winds down when the lease ends.
