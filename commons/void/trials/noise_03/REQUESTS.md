# noise_03: shared-code requests (Claude worker D, batch 25)

All requests are trial-scoped. No source, map, text or shared file is touched by this
folder. "Static" means read from the source before any native run.

| id | what | blocks native? |
|---|---|---|
| R1 | `simplex_noise` and `perlin_noise` configured before `_ready` | **yes**: without it floor 3 throws a SCRIPT ERROR |
| R2 | identity anchor named `PerlinNoiseTerrain` on the terrain placement | no: plinth, collider and caption missing; one check fails |
| R3 | `box_shell_space` / `box_atrium_space` configured before `_ready` | no: performance only (each shell is built twice) |
| R4 | `DesktopHand` re-enables itself after a transient reparent (host finding) | the full run keeps one failing desktop check until it is installed |

R1 to R3 are wired by Codex (`floor_content.gd:427-445`); I checked them by reading. R4 is
new.

## R1. The noise pair must be configured before `_ready` (static; required)

**Placements:** `f3_simplex_noise_3_13` and `f3_perlin_noise_8_13`. Their tokens carry `seed`,
`size:8`, `ramp:shared`, `panel:front`, `frequency/amplitude/persistence/octaves`. The
simplex token also carries `witness:show`, `study:compare` and `enclosure:arches`.

Neither catalog entry has `configure_before_ready`. So `floor_content.gd` adds the node and
calls `apply_grid_config()` after `_ready`. The museum configures before `_ready`; both
scripts are written for that order ("the museum configures before _ready").

Read in the Void order, three things go wrong.

1. **A script error on floor 3.**
   - `SimplexNoise._ready()` reads `config_study` from metadata and queues
     `_build_pair_study` deferred. `witness` is still `"none"`, so no witness plate is queued.
   - Then `apply_grid_config` sets `witness = "show"` and queues `_build_witness_plate`
     deferred, *after* the pair study.
   - `pair_study.gd:24` then runs `first.get_node("Witness/Case")` before the plate exists and
     sets `case.position.y` on null.
   - The pair study's twin lookup succeeds (the perlin is built first; see "Order" below), so
     the error is reached whether the floor loads immediately or one factory per frame.
2. **Panels stand 3 m too far out.** `apply_grid_config` builds the `panel:front` panel before
   it applies `size:8`. `half` is computed from the default 20-cell field, so both panels
   stand at z −5.7 instead of −2.7, where the witness case and pair-study controls expect them.
3. **The perlin panel is titled SIMPLEX.** `PerlinNoise.apply_grid_config` builds the panel
   before `noise_field.set_dna(generator, …)`. The script's default generator is `"simplex"`,
   so `basis_name()` still reads simplex when the title is drawn.

Before `_ready`, both `apply_grid_config` bodies only assign values:
- `_built` is false, so nothing is built and nothing is deferred;
- `noise_field` is `@onready` and null, so the contract waits for `_ready`.

`_ready` then builds once: contract, panel at −2.7 with the right basis, witness deferred
first, pair study deferred second.

**Hook** (either form). Catalog form, matching the museum:

```json
"simplex_noise": { …, "configure_before_ready": true },
"perlin_noise":  { …, "configure_before_ready": true }
```

Or trial-scoped, in `floor_content._build_artifact` after
`var before_ready := bool(definition.get("configure_before_ready", false))`:

```gdscript
if trial_id == "noise_03" and item.artifact in ["simplex_noise", "perlin_noise"]:
	before_ready = true
```

Neither scene root carries exported overrides; no script is swapped.

**Probe evidence once installed** (`pair` case):
- panels at z −2.7;
- `PairStudy` bound to the perlin twin;
- `Witness/Case` present;
- two arches.

## R2. The pair study cannot find the terrain by name (static; source behaviour only)

`pair_study.gd:43` runs `hall.find_child("PerlinNoiseTerrain", true, false)`. In the museum
that is the terrain's scene-root name. It hangs three things on the terrain:
- a 1.2 x 0.5 x 1.2 m stone plinth;
- its box collider;
- the caption "A 3D FIELD / ANOTHER SLICE".

The Void finds the hall correctly, because the floor root carries `em_map`. But
`floor_content` renames every artifact root to `Artifact`, so the lookup returns null and
the terrain floats at 1.0 m without its plinth.

**Hook**, in `floor_content._build_artifact`, before `mount.add_child(artifact)`. An identity
anchor, so the plinth lands exactly where the museum puts it and follows editor
moves and turns:

```gdscript
if trial_id == "noise_03" and item.artifact == "perlin_noise_terrain":
	# simplexnoise/pair_study.gd finds the terrain by its scene-root name; the Void
	# renames every root "Artifact".
	var anchor := Node3D.new()
	anchor.name = "PerlinNoiseTerrain"
	artifact.add_child(anchor)
```

The terrain script reads `$NoisePlane` only, so the extra child changes nothing else.

**Order dependency, already handled in `rooms.json`.** The pair study is deferred from the
simplex's `_ready`, so the terrain and the perlin must already be in the tree when a
streamed floor builds one factory per frame. Floor 3 lists:

terrain, sphere, perlin, simplex, portal.

## R3. The two Noise_Box shells are built twice (static; optional, performance)

`cellular_volume.gd` builds in `_ready`:
- the full box-sampled membrane, 27 x 11 x 29 m in 0.65 m cells;
- a trimesh collider;
- a 13.8 m floor disc;
- four lights.

`apply_grid_config({floor:false, …})` then runs `regenerate()` again, because
`is_node_ready()` is true. The CELLS atrium samples about 32k points against 20 sites
twice. Before `_ready` it only assigns `create_floor`, `seed`, `softness`,
`clearing_radius` and `box_size`.

**Hook** (catalog): `"configure_before_ready": true` on `box_shell_space` and
`box_atrium_space`. The trial-scoped form is the same as R1, with those two keys. The probe
prints each shell's `build_msec` (the last build) in the `shells` case.

## R4. The scale portal kills the desktop mouse hand (host finding; measured + static)

**Measured.** First full acceptance, 2026-10-21, `evidence/engine.log` lines 68–100.
- On floor 2, the desktop visitor walks through SMALLER and back out. Both size checks pass.
- On floor 3, every desktop press and drag then has no effect: REGEN, the FREQ drag
  ("perlin FREQ 10.0 -> 10.0"), SAMPLE and VIEW.
- XR passes everything, and the same presses pass in the focused `pair` case, which never
  visits floor 2.

**Static.** `noise_scale_portals.gd` (`enter` and `restore`) uses
`child.reparent(_pivot, false)` and back on every non-collision Node3D child of the desktop
body. That includes the `Camera3D` and the `DesktopHand`. A reparent leaves the tree and
enters it again. `commons/void/desktop_hand.gd:133`:
- `_exit_tree()` calls `set_enabled(false)`;
- it clears `ability.desktop_source` (the catalyst's desktop source);
- nothing re-enables either on entry. `game._set_enabled(true)` only runs after a death.

**Consequence.** After one SMALLER, a desktop visitor can neither point nor grab until they
die and retry. XR is unaffected: XRTools bodies are not reparented.

The probe now records this as its own check (`the mouse hand is still enabled after the
scale portal round trip (host; needs R4)`), plus a `PRESS_TRACE` before every desktop press.
Only then does it re-enable the hand through the API, labelled `PROBE_RESTORE`, so floor 3
still tests its own controls.

**Hook** (`commons/void/desktop_hand.gd`; shared, Codex). A transient reparent restores what
leaving the tree took away. A deliberate `set_enabled(false)` (recovery) is not undone,
because `enabled` is already false when the hand exits:

```gdscript
var _reenable_on_enter := false
var _restore_ability_source := false

func _enter_tree() -> void:
	if _reenable_on_enter:
		_reenable_on_enter = false
		set_enabled(true)
	if _restore_ability_source and is_instance_valid(ability):
		ability.desktop_source = self
	_restore_ability_source = false

func _exit_tree() -> void:
	_reenable_on_enter = enabled
	_restore_ability_source = is_instance_valid(ability) and ability.desktop_source == self
	set_enabled(false)
	if is_instance_valid(ability) and ability.desktop_source == self:
		ability.desktop_source = null
		ability._hide_all()
```

The alternative is a trial-scoped adapter for the source portal. It is not practical: the
walk study creates `noise_scale_portals.gd` with `.new()` at run time. The fix belongs to
the host hand, and it applies to any artifact that reparents the visitor's children.

## Not requested

- **Noise_Box shells outside the tower.** That is a placement decision, recorded in
  HANDOFF.md and STATUS.json `open_questions`. Each shell is about 24–27 x 29 x 10 m. Two
  cannot share a 42 m floor. Any dome over a shaft would fill that shaft's column in the
  storey above.
- **The configurable portal builds its children twice.** `_ready` and `apply_grid_config`
  each start `_build_portal()`, which awaits a frame. This happens in every lane: the museum
  configures before `_ready` and still calls `_build_portal()` twice. It is source behaviour
  and reported only; the probe prints the Area3D and surface counts.
