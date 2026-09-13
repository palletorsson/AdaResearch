## 2026-09-10 — the Noise_Perlin_Simplex pilot (doc/research/waves-chance-noise)

Ruling: a fair comparison matters more than the current cabinet (the card's latitude), and the map is the placement authority.

Structure CHANGED, and why: the pre-museum map (a36f33c9) was an all-void basin with four floor cells; the 100 m `noise_terrain` WAS the floor. The museum conversion added a walkable rim and three piers; the pathfinder read 1 of 89 cells reachable, and the museum had to move the terrain to keep its walk. The interior is now floor (`1`), the three east piers at (10,3),(10,7),(10,11) are removed (they were the conversion's, not the room's), and the walk reads 149 of 195 reachable. The basin is archived (doc/space/waves-chance-noise-pilots-2026-09-10/{before,pre-museum}); `noise_terrain` is removed from this hall and its book line left in place for Astra to rule on. `perlin_noise_terrain` stays as the secondary, moved to (2,11); dark_sphere to (6,11); the portal keeps its cell and is relabelled "Lab Path (optional)". No teleporter was added: the museum carries its own passage to CA_Introduction.

Placement: `simplex_noise:0:1.1#seed:20260910#size:8#ramp:shared#panel:front` at (3,7) and `perlin_noise:0:1.1#generator:perlin#seed:20260910#size:8#ramp:shared#panel:front` at (8,7). y 1.1 lifts the root by one amplitude so the relief's lowest cube sits on the floor; size 8 keeps the 0.5 m resolution (fewer cubes, not smaller), so two 4 m fields fit with a one-metre aisle; `size` is an already-listed grid config key, `seed`/`octaves` are newly listed.

Artifacts: both visualizers gain seed_value (−1 = shipped randi), a recorded current_seed, reseed(), rebuild_size(), sample_at() and a shared colour ramp; NoiseVisualizer gains the fractal gain it never set (it ran on the 0.5 default by luck). Both roots gain seed/ramp/size/panel, a RackTemplates panel (FREQ, OCTAVES, REGEN, REPLAY), a readout that names the basis FROM THE GENERATOR and prints the value at (0,0) and (2.5,2.5), and root-side parameter state so the stripped 2D UI is no longer dereferenced. Defaults untouched. The two roots are kept as deliberate twins (local first, share on a third consumer).

The correction the card called high-value: the Perlin display's basis. `_noise_type_for`'s default is simplex and no placement had ever passed the word; it drew simplex under the Perlin name until today.

Exactness: the final quotes `_noise_type_for` and `generate_noise_at` verbatim; the same-integer-two-bases caveat is stated, not hidden.

Rejected: scaling the roots (would shrink the panels with them); keeping the basin with the fields floating over void; a lattice overlay (technical.md's proposal — a later instrument).

Evidence: source checks pass (gdparse, pathfinder 149/195 OK, token gate, final_tags, cite_gate held on critical.md's quoted sentence, excerpts verbatim). Runtime probe written, NOT RUN (Godot occupied). Headset: not walked.

Supporting texts: intent, blurb, summary, tutorial, critical rewritten (they described crosshairs, a 45° toggle and identical-parameter terrains that were never built); technical.md's invented configurations and the terrain-versus-terrain section replaced with the real build.


## Astra source review - 2026-09-10

Both placements now explicitly include #frequency:10#amplitude:0.8#persistence:0.5#octaves:4. This overrides the old Simplex 2D slider gain of 0.1. Both visualizers sample each cube at its actual x/z; the readouts use (-1,0.5) and (1,-1), within the fields. Shared finish is metallic 0.1 / roughness 0.8. REPLAY restores seed, frequency, octaves and handles. Both labels read the generator. The stale noise_terrain role and book entry are removed. The compact technical chapter supersedes earlier perfect-isotropy and unmeasured performance claims.

All three pilots explicitly set `museum.artifact_placement: "map"`. This replaces the broad authored-map exemption: other rooms keep their existing necklace placement behaviour. Recovered wave geometry is unchanged.

Status: source corrections complete; museum runtime probes and tracked-hand verification pending. See `doc/book/handoffs/astra-wcn-pilot-review-2026-09-10.md`. Earlier evidence in this file describes the Fable handback before these corrections.


## 2026-09-10 — first museum runs (Fable)

`probe_wcn_noise_pair.gd`, rendered under the watchdog, five runs. Observed: at frequency 1 both fields were flat slabs (the four-metre field covers 0.175 of one noise period; sampled values ±0.07), so the comparison had nothing to compare. Both placements now declare frequency 10 and the FREQ slider runs 1..20 (FREQ_MIN / FREQ_MAX in both roots; the probe's handle formula follows). The standalone 2D control overlays of both scenes were painted on the museum screen, twice over; hidden when the scene is not the root. Museum sculpture plinths stood in the one-metre aisle between the fields and in the front row; `museum.sculpture_clear_rects` [[1,1,11,10]] keeps them out (a per-map key the museum reads for map-authored halls since today). The probe's east-corridor cast at x 11.5 from z 1.5 met the hall's own gate: this map declares no `gate_depth_rows`, so the museum's gate stands four rows in (world z 4.5), unlike the recovered wave halls where it stands at the doorway. The cast now starts behind it, at z 5.5 in the free column x 11 (x 10.5 is the perlin field's own edge). Final run: 51 checks, 0 failures. Capture: `probe_noise_pair.png` from the doorway, relief visible on both fields, the aisle clear.


## 2026-09-10, evening — second runtime pass, under project startup (Fable, after Astra's runtime review)

Run: `bash tools/run_wcn_probe.sh noise live` (the probe ported to a Node, run as the project's main scene through `commons/testing/probe_live.tscn`, autoloads present). 54 checks, 0 failures (`probe_noise_pair_live.json`), no script errors in the engine log.

Actual desktop input, recorded apart from the emitted signals: the project's desktop rig stood 0.9 m on the simplex panel's own +z side, at segment-local (3.5, 0, 5.69), looked at REGEN (the panel at 1.37 m) and left-clicked through the input pipeline; its pointer reported `SIMPLEX/Btn_0/InteractableAreaButton` under the crosshair and the simplex seed went 20260910 → 3994018885. From that spot the rig's camera photographed the panel and its readout (`probe_noise_pair_desktop_panel_live.png`): `simplex · seed 3994018885 · oct 4 · f 10.00 · gain 0.50` and the two sampled values `(-1.0, 0.5) = +0.568   (1.0, -1.0) = +0.035` read at reach; the panel's own labels (FREQ, OCTAVES, REGEN, REPLAY) are small at 0.9 m but legible. The rig then walked the aisle between the fields from (6.0, 4.5) south on `ui_up`: 5.0 m in 60 physics frames, no obstruction. `probe_noise_pair_desktop_aisle_live.png` is the rig's view at the end of that walk (the south half of the hall: the Lab Path portal, the dark sphere, the wall text); the aisle itself with the two fields either side is the doorway capture `probe_noise_pair_live.png`. The gate four rows in (this map declares no `gate_depth_rows`) is unchanged. Headset: pending.


## 2026-09-11, 07:37 — refreshed under the current probe sources (Fable, Astra's W2 completion brief, item 1)

`bash tools/run_wcn_probe.sh noise live`, Godot free: 54 checks, 0 failures. Why the rerun: after this room's 20:50 run the shared probe sources changed (the capture settle moved from the render server's `frame_post_draw` to a timer; the driver's pose log and the guard flag were added), so the evidence is regenerated from the sources that now stand; the results are the same as the second pass. Captures refreshed in place. Headset: pending.

## 2026-09-13 — N6: what must stay the same before a difference can be attributed to a rule (Fable, active hall 6 of Astra's noise arc; her card: "Logic/route probe passed; actual input and headset pending")

**The ruling.** The 2026-09-10 repair was right and it was not yet evidence. It placed `#generator:perlin` on the right-hand display, matched every other term through the token, and added readouts that name the basis read back from the instantiated generator. What it could not do was let anyone CHECK the match. `contract()` on both roots reports each script's own bookkeeping variables, so "the frequencies are the same" was a claim about two GDScript floats, not about the two FastNoiseLite objects that actually drew the fields. And no saved run in this room had ever recorded a basis readback from the PERLIN side: the only readout quoted anywhere in the folder was the simplex panel's.

So both roots gained `generator_readback()`, which asks the live generator for its own properties, and an opt-in `#witness:show` builds a plate between the displays printing both sides at once. Ten `simplex_noise` and twenty `perlin_noise` placements are untouched at the default.

**Measured, and the room's claim holds.** Every term equal, read off the generators: seed 20260910, generator frequency 0.05, fractal octaves 4, gain 0.5, lacunarity 2.0, fractal type 1, sample multiplier 10.0, sample offset 0.0. `noise_type` 0 against 3 — simplex against perlin. The counterfactual that would have cost this room fourteen sentences is dead.

**Actual input, which is what Astra's card asked for.** The pilot pressed ONE control in the whole room through the input pipeline: REGEN on the simplex panel. Every slider and the REPLAY button were driven by `set_normalized_value()` plus `emit_signal()` — no pointer, no ray, no collider. Every control on both panels is now pressed or dragged through the desktop rig's pointer, each press counted at the button's own signal, and the basis is read back after each one: simplex REPLAY, perlin REGEN, perlin REPLAY, and the perlin FREQ slider dragged from 10.00 to 20.00 with the pointer reporting a drag midway. The basis survives all of them.

**Why that mattered more than it looked.** `PerlinNoise.apply_grid_config` only pushes the basis down when `_built` is already true, and the museum configures before `_ready`. The two paths reach TYPE_PERLIN by two different routes — in the museum the config lands first and `_ready` calls `set_dna`; under the grid path `_ready` runs first and the deferred config calls it. The child `NoiseVisualizer._ready` builds the whole field on TYPE_SIMPLEX before either. Reading the basis once, before any control is touched, could not see any of that.

**Three defects in the pilot probe, each fixed.** `check(not (A and B))` on the two sampled coordinates passes when only ONE differs, so a single coincidence satisfied the two-bases-differ control; it now requires both. The terrain check matched on token `noise_terrain` while the map places `perlin_noise_terrain`, so it passed without looking at anything; it now finds the body the map holds and measures it. And the report said "no tracked hand" on runs where the pointer lane had passed, while `_live()` is a filename test that skips the whole desktop block in silence — the report now carries a `lanes` block saying which lane was expected and which ran.

**The door does not work, and now says so.** `configurable_portal#dest_map:Lab_Path` resolves its destination by asking the grid system for a `load_map` method and then a node in group `scene_manager` for `load_scene`. GridSystem has neither; nothing in the repo joins that group. Every path reaches a `push_warning`. A read-only `resolve_destination()` runs the same lookups and reports which branch would be taken without taking it: `resolves: false, via: "nothing"`. I did not make it live. In the museum a map switch severs the endless walk, so a door that starts working is a decision about the walk, not a hall pass.

**The route to Cellular Automata is the spine's, not this sequence's.** Four texts asserted the active route continues to CA_Introduction. `curriculum_spine.json` does put cellularautomata straight after noise, and the museum carries its own passage — but `commons/maps/sequences/noise.json` ends its maps array at Lab_Path and names `proceduralgeneration` and `morphogenesis` as unlocks, and morphogenesis was absorbed into softbodies. The sentences now say which of those they mean. Making the sequence agree with the spine is a fold-level edit and is not made here.

**Exactness decisions.** The plate prints raw numbers with no argument on them, because the argument is the room's and the numbers are the generators'. It stands between the two panels at about 1.25 m rather than over either field, so reading it is not reading one side. `sample_offset` is on the plate even though it is zero, because it is the one sampling term the two visualizers do not share: `NoiseVisualizer` adds `animation_offset` to both coordinates and `SimplexVisualizer` has no such term. A term that happens to be zero is still part of the contract.

**Rejected.** Making the portal work: one line reaches the SceneManager autoload, and GridSystem already does that lookup, but a door that teleports is a museum decision. Rejected too: rewriting `eye_shot.md`'s clearance table, which measures a hall that no longer exists — hand-editing generated measurements is inventing numbers, so it carries a dated head instead.

**Pending.** A headset walk. A person at the controls rather than a rig. Whether a visitor can actually SEE the lattice signature that `critical.md` argues for, at four octaves and half-metre cubes, is still unmeasured and still the room's open question. Astra's review.
