# Orb Gesture Slice — design spec

**Status:** Spec'd 2026-05-11. Not yet implemented.

Replaces the catalyst projectile (gun-shot) with a **two-handed force-field gesture**. The orb is the relation between the palms while the gesture is held; it dissolves when palms part. **One-handed mode preserves accessibility as a strategic affordance with cooldown cost** — not a fallback.

Sieved 2026-05-11. Pass: [`doc/sieve_passes/2026-05-11T10-54-27_orb-gesture-detector.md`](sieve_passes/2026-05-11T10-54-27_orb-gesture-detector.md). Result: clean pass with the design rule below as load-bearing constraint.

---

## Design rule (load-bearing constraint)

**No orb-action produces a number on screen or a confirmation toast.** Audiotactile feedback and creature-visual change are the *only* feedback channels. Adding UI accretions over time would seal the dark spot the slice depends on.

This is the keep-honest constraint. Future PRs that violate it should be rejected at review.

---

## Two modes

### Two-handed: sustained dose

- Both controllers within ~30 cm of each other
- Midpoint > ~40 cm from the headset (extended out from the chest)
- Held for > 0.3 s → orb materialises at the midpoint
- Continuous: the field projects as long as the gesture is held
- Both hands committed; no other gestural verb is available while sustaining

### One-handed: burst with cooldown

- One controller in a "presenting" pose — palm forward, arm extended past ~35 cm from headset
- Pose held > 0.2 s → orb fires a single burst along the controller's forward
- After firing, *that hand* enters cooldown for ~1.2 s (≈ 2× dose-window)
- Other hand free for movement, climbing, bracelet rotation, etc.
- Cooldown is **felt, not displayed** — the bracelet stone dims and re-brightens; no numeric timer

The two modes share the same orb-substance and the same per-contact dose-window. They differ only in commitment cost and rhythm.

---

## Components

### `OrbGestureDetector` — `commons/hazards/becoming_catalyst/orb_gesture_detector.gd` (new)

Node3D, instanced once per player. Reads both XR controller transforms each frame. Maintains a small state machine:

| State                       | Entry condition                                                     | Exit |
|-----------------------------|---------------------------------------------------------------------|------|
| `IDLE`                      | Neither mode's conditions met                                       | — |
| `FORMING_TWO_HANDED`        | Two-handed conditions met, sustain timer < 0.3 s                    | conditions broken OR timer ≥ 0.3 s → `TWO_HANDED_ACTIVE` |
| `TWO_HANDED_ACTIVE`         | sustain timer ≥ 0.3 s                                               | palms part → emits `orb_dissolved` → `IDLE` |
| `FORMING_ONE_HANDED_<hand>` | One-handed conditions met for `hand`, sustain timer < 0.2 s         | conditions broken OR timer ≥ 0.2 s → `ONE_HANDED_FIRING_<hand>` |
| `ONE_HANDED_FIRING_<hand>`  | sustain timer ≥ 0.2 s                                               | burst lifetime expired (~0.4 s) → `COOLDOWN_<hand>` |
| `COOLDOWN_<hand>`           | After firing                                                        | cooldown timer ≥ 1.2 s → `IDLE` |

Signals:
- `orb_formed(mode: String, origin: Vector3, direction: Vector3)`  — emitted on entering an active state
- `orb_dissolved` — emitted on leaving an active state for any reason
- `hand_cooldown_started(hand: String)` — `"left"` or `"right"`
- `hand_cooldown_finished(hand: String)`

Two-handed and one-handed gestures are mutually exclusive: if both could match, two-handed wins.

### `CatalystOrb` — `commons/hazards/becoming_catalyst/catalyst_orb.gd` (new)

Node3D instanced when the detector fires `orb_formed`. Lives until `orb_dissolved`.

- Emissive sphere mesh at the gesture's origin (midpoint for two-handed; controller-tip for one-handed)
- **Two-handed visual:** larger (radius ~0.08 m), fuller emission, smooth pulse
- **One-handed visual:** smaller (radius ~0.05 m), dimmer emission, sharp attack-and-fall
- Cone-shaped `Area3D` projecting along the gesture's forward
  - One-handed cone length: ~2.0 m fixed
  - Two-handed cone length: scales with distance-from-head, range ~1.5–3.5 m
- `AudioStreamPlayer3D` humming in the active bracelet stone's key
  - **Two-handed audio:** sustained chord (root + fifth + octave)
  - **One-handed audio:** single note, sharp envelope
  - Tone-shifts when the cone overlaps matter
- Haptic on the relevant controllers
  - **Two-handed:** continuous soft pulse on both
  - **One-handed:** single pulse on fire, then silence during cooldown
- Tinted by active bracelet stone (mode-color)

### `HazardCreatureBase.receive_catalyst_field(dt: float, mode: String)` — modify `commons/hazards/hazard_creature_base.gd`

New method on the existing base class.

```gdscript
var _dose: float = 0.0
var _last_dose_tick: float = 0.0

func receive_catalyst_field(dt: float, mode: String) -> void:
    _dose += dt
    _last_dose_tick = Time.get_ticks_msec() / 1000.0
    if _dose >= 0.6:
        _dose = 0.0
        # advance personality one step toward FRIEND
        _advance_personality_along_arc(mode)
```

Plus a `_process()` check that resets `_dose` if `> 0.4 s` have passed since the last tick (lets the player release pressure briefly without losing all progress, but real interruption resets cleanly).

The existing `hit_by_catalyst_mode()` projectile path is kept behind a `legacy_projectile_enabled: bool = false` flag so test scenes can still use it during transition. Removed once the orb is felt-right.

### `OrbTestChamber` — `commons/maps/OrbTestChamber/` (new)

Minimal test environment:

- spawn + bracelet pickup
- three creature spawn pedestals (not pylons yet — single-slice scope)
- three creature kinds known to differ visibly across personality stages: `catalyst_foe`, `fractal_hydra`, `gradient_hunter`
- one quiet ambient sequence (sequence 1 ecology — low density)
- no other artifacts, no distractions

The map's job is to be a tutorial-of-one: the new verb is the only thing to learn.

---

## Out of scope for this slice

Deliberately *not* building yet:

- Cord-trails on the floor (separate slice — load-bearing for the tapestry)
- Pylon spawn system (separate slice — load-bearing for f-agent ecology)
- Bracelet luminance tied to friend-density (separate slice — felt cognitive water for the bracelet itself)
- Per-bracelet-stone cooldown variation (uniform cooldown for v1; revisit after feel-test)
- Watershed metadata in `curriculum_spine.json` (separate slice — curriculum reframe)

Each of these gets its own sieve pass before building.

---

## Open questions (resolve in implementation, not in spec)

1. **One-handed firing trigger.** Pose-detected (palm-forward + arm-extended) OR pose-plus-brief-sustain (lean toward the latter — avoids accidental fires). Lean: pose + 0.2 s sustain, *no button press*. Keeps the gesture-grammar consistent with two-handed (no button press for catalyst actions anywhere).
2. **Cooldown duration exact value.** Proposed 1.2 s. Feel-test after first build.
3. **Visual mode-distinction strength.** Lean: strong enough that players know which mode they are in without UI, subtle enough that one-handed doesn't read as "weaker version."
4. **Two-handed wind-up.** Lean: gentle fade-in over 0.3 s, matching the sustain detection time. Wind-up == gesture-completion.

---

## Acceptance criteria

The slice is felt-right when:

- A player can convert one creature using only two-handed sustain
- A player can convert one creature using only one-handed bursts
- The cooldown is **felt** (bracelet stone dims and re-brightens) without any number being shown
- The bracelet's mode-rotation changes the orb's hum and tone audibly
- No reticle, no toast, no numeric feedback appears anywhere
- A new VR player figures out the gesture within 30 seconds of being shown nothing but the bracelet and a target

---

## Files to add / modify

**New:**
- `commons/hazards/becoming_catalyst/orb_gesture_detector.gd`
- `commons/hazards/becoming_catalyst/orb_gesture_detector.tscn`
- `commons/hazards/becoming_catalyst/catalyst_orb.gd`
- `commons/hazards/becoming_catalyst/catalyst_orb.tscn`
- `commons/maps/OrbTestChamber/map_data.json`
- `commons/maps/OrbTestChamber/blurb.md`
- `commons/maps/OrbTestChamber/intent.md`

**Modify:**
- `commons/hazards/hazard_creature_base.gd` (add `receive_catalyst_field`, dose reset in `_process`)
- The autoload that owns player rig — wire `OrbGestureDetector` into the player's XR origin
- Bracelet visuals — listen for `hand_cooldown_started`/`finished` to dim/brighten the active stone

---

## After this ships, in order

Sieve each before building:

1. **Cord-trails** — agent trails on the floor, FRIEND brightens, crossings as knots (tapestry foundation)
2. **Bracelet luminance** — felt friend-density, no number
3. **Pylon system** — vertical spawners with kind + affinity + bound state
4. **Watershed metadata** — `curriculum_spine.json` schema change + `/watersheds` page

---

## Pointers

- Sieve pass: `doc/sieve_passes/2026-05-11T10-54-27_orb-gesture-detector.md`
- Framework integration: `doc/ENTRY.md` § The Self-Q
- Blog arc: `/blog/2026-05-11-cognitive-water`, `/blog/2026-05-11-self-colonial-recognition`
