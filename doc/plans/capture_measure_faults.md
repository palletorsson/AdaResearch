# ~~Five faults left in `_measure_artifact_aabb`~~ — RETRACTED, one left

> ## RETRACTION, 2026-08-13
>
> **This document was wrong when written and the patch below is redundant.**
> Five of the six faults were already repaired in `549f83e23` (2026-08-12,
> *"capture_dressing_room.gd — five faults from the audit"*), and that repair is
> in `HEAD`. I diagnosed against a **regressed working copy** — a 25,993-byte
> uncommitted version of the file that still carried the 18 m guard, against
> HEAD's repaired 29,367 bytes. I read the working tree, saw the faults, and did
> not check `git show HEAD:` on the file I was about to rewrite. That is the
> exact mistake `doc/spatial/CURRENT_STATE.md` opens by recording — *"the
> repository is the durable memory, not the working tree"* — made a second time,
> a day later, in the same repo.
>
> The prior session found the same faults independently, with the same evidence
> (`draw_dot` 3.29 m, `force_field`'s caption, `scale_lines`' 100 m rung,
> `laser_measure`'s fifty ticks) and numbered them F1–F4 as I did. Convergent
> diagnosis, one day apart.
>
> **Verified against HEAD by `tools/test_measure_faults.py` — 9 of 9 pass:**
>
> | # | artifact | before | now |
> |---|---|---|---|
> | 1 | `scale_lines` | 10.0 m | **100.00 m** |
> | 2 | `laser_measure` | 50.081 m | **0.058 m** |
> | 3 | `pythagorean_triangle_angles` | depth 1.67 m | 0.006 m body, **1.67 m signage** |
> | 4 | `force_field` | 3.645 m wide | 3.000 m body, **3.645 m signage** |
> | 5 | `draw_dot` | 3.29 m | **0.500 m** |
> | 6 | `draw_triangle_faces` | 3.224 m | **0.070 m** |
> | 7 | `edge_core` | 0.99 m | 1.138 m, effects reported |
> | 8 | `particle_chaos` | `[1,1,1]` silent | `fallback: true` **+ reason** |
> | 9 | `lambda_slider` | 0.69 × 0.33 × 1.31 | **unchanged** |
>
> Tests 3, 4 and 8 initially reported FAIL and **the tests were wrong, not the
> code** — provenance lives under `measurement`, and they read the top level. A
> test that cannot find the evidence reports the absence of evidence. Fixed and
> re-run.
>
> **Still open: F6 only.** `dna.fixture` is never read by the harness — 0
> occurrences in the file. Note that test 2 passes *without* it: removing the
> per-mesh guard alone took `laser_measure` from 50.081 m to 0.058 m, so my claim
> that F6 was required to fix it was also wrong.
>
> The measured numbers in the fault descriptions below stand as a record of what
> the faults cost. The patch does not — do not apply it.

---

# Five faults left in `_measure_artifact_aabb`, with the patch and its tests

> Written 2026-08-10, **not applied**. `commons/testing/capture_dressing_room.gd`
> was modified 4 minutes before this file was written and is uncommitted — a
> second session is inside this function. A 90-line rewrite dropped on top of
> in-flight work is how a good fix becomes a lost afternoon. The patch is here
> to be applied by whoever owns that buffer.
>
> One of the six faults is **already fixed** in the working tree: the
> `is_visible_in_tree()` check now sits at line 424. It was not there at 22:40.
> That leaves five.

## Why this function is worth the care

72 artifacts were staged and read back against source. **25 of the measurements
described this function rather than the artifact** — 35%. Every fault below is a
named case, reproducible, and found by an agent reading source against a number
that did not make sense.

The stakes are not the 72. There are 2,631 artifacts still unmeasured and a
`Measure now` button now wired into `/artifact-editor`. At the current error rate
a full sweep manufactures roughly **900 wrong numbers**, each landing in
`staged_measurements.json` looking exactly as authoritative as the good ones.

---

## F1 · the 18 m guard is per-mesh, and vestigial

```gdscript
var footprint: float = Vector2(world.size.x, world.size.z).length()
if footprint > 18.0: continue          # ← delete
```

It discards any *single* geometry whose XZ diagonal exceeds 18 m, as studio
floor. It fails in both directions at once:

- **invents** — `laser_measure`'s one 50 m beam was caught and dropped, but the
  fifty separate 12 mm tick marks it pools out to `z = -50` each have a 0.012 m
  diagonal, so every one sailed through. 50.001 (last tick) + 0.08 (the grab
  stick's highlight ring) = **50.081 m**, the reported figure, exactly.
- **deletes** — `scale_lines`' 100 m rung *is* a single mesh, so it was thrown
  away and the artifact measured **10.0 m**. It is genuinely a hundred metres
  wide, declared `[1,1,1]`, standing in **22 live maps**.

And it is guarding against nothing. `StudioFloor` is parented to `root`, not to
`RoomRoot` — see the comment at its construction: *"Keep it outside RoomRoot so
it never contributes to artifact/room bounds."* The floor was never in this
subtree. **Delete the guard; report the widest single mesh instead.**

## F2 · billboarded text is counted as body

`Label3D` extends `GeometryInstance3D`, so it passes the type test and reports an
AABB the size of its own glyphs — which then rotates to face the camera.

- `force_field`'s 3.645 m width **is its caption**.
- `example_6_4_windmill_vr`'s entire 2.325 × 2.325 × 3.253 m box is lettering
  wrapped around a 0.35 m machine.
- `pythagorean_triangle_angles`' 1.67 m depth is seven labels while every real
  mesh sits coplanar at `z = 0`. Its declared `[3,1]` was right and the
  measurement was wrong.

Found independently in three of six batches. Text is authored to be **read**, not
occupied. Measure it separately as `signage`.

## F3 · top-level nodes drag the box to the world origin

`set_as_top_level(true)` detaches a node from its parent transform, so it stays
at the world origin while the capture's own seating step lifts the artifact away
from it.

- `draw_dot` reports **3.29 m**, centre 1.625 — reproducible to the byte from a
  1.52 m seat lift (`draw_dot.gd:144`).
- `draw_triangle_faces` reports **3.224 m**, its AABB floor at exactly −0.075 m,
  the snap sphere's half-height.

Two agents found this independently, neither knowing of the other's case. A node
that has left the artifact's frame is not part of the artifact's extent.

## F4 · particles, and the [8,8,1] epidemic

`GPUParticles3D` returns a zero-size local AABB and dies at the
`size.length_squared() < 0.0001` test. That is *correct* here — but it is the
other half of a story worth knowing, because the **old** oracle
(`tools/measure_artifact_aabbs.py`) used `visibility_aabb` instead and recorded
`[8, 8, 8]` — Godot's default — for **19 artifacts**.

```
GPUParticles3D.visibility_aabb [8,8,8]
  → artifact_sizes.json
    → dressing-room generator, height clamped to 1
      → 15 of the 20 dressing rooms declaring [8,8,1]
```

`[8, 8, 1]` was never a placeholder anybody chose. It is a particle system's
default visibility box, propagated. Falsification that settles which mechanism
applies: `edge_core` builds a 0.8 m sphere **plus** particles and measures
0.99 m. Had the 8³ box counted it would read ≥ 8 m, and an 8 × 8 XZ diagonal is
11.31 m — comfortably under the old 18 m cut. Confirmed on four more.

**Keep particles out of body; report them as `effects`** so the two paths can
never silently diverge again.

## F5 · `[1,1,1]` is a fallback wearing a measurement's clothes

```gdscript
if not has_any:
    return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
```

Four of 72 returned exactly this. It is indistinguishable from an artifact that
is genuinely 1 m cubed, and two of the four — `particle_chaos` and
`chaos_particles` — are the λ=0 and λ=1 poles I had proposed for the bay adjacent
to Lambda, on the strength of a number that was never taken.

Return the fallback, but **say so in the manifest.**

---

## The patch

Replace the body of `_measure_artifact_aabb` (currently ~line 409–438). The
`is_visible_in_tree()` check already present is kept as-is.

```gdscript
var _last_measure: Dictionary = {}

func _measure_artifact_aabb(node: Node) -> AABB:
	var combined := AABB()
	var has_any := false
	var signage := AABB()
	var has_signage := false
	var effects := AABB()
	var has_effects := false
	var skipped_invisible: int = 0
	var skipped_top_level: Array[String] = []
	var counted: int = 0
	var widest: float = 0.0
	var widest_name: String = ""

	var stack: Array = [node]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null: continue
		for c in n.get_children():
			stack.push_back(c)
		if not (n is GeometryInstance3D): continue
		var vi := n as GeometryInstance3D

		# already in the tree — hidden geometry is not body, and the seating
		# step reads this box to decide how far to lift the artifact
		if not vi.is_visible_in_tree():
			skipped_invisible += 1
			continue

		# F3 — a top-level node has left the artifact's frame
		if vi is Node3D and (vi as Node3D).top_level:
			skipped_top_level.append(String(vi.name))
			continue

		var local := vi.get_aabb()
		if local.size.length_squared() < 0.0001: continue
		var world: AABB = vi.global_transform * local

		# F2 — text is authored to be read, not occupied
		if vi is Label3D or vi is Sprite3D:
			signage = world if not has_signage else signage.merge(world)
			has_signage = true
			continue

		# F4 — effects are shown, not stood on
		if vi is GPUParticles3D or vi is CPUParticles3D:
			effects = world if not has_effects else effects.merge(world)
			has_effects = true
			continue

		# F1 — no size guard. StudioFloor is parented to root, not RoomRoot,
		# so it was never in this subtree. Report the widest mesh instead.
		var reach: float = Vector2(world.size.x, world.size.z).length()
		if reach > widest:
			widest = reach
			widest_name = String(vi.name)
		counted += 1
		combined = world if not has_any else combined.merge(world)
		has_any = true

	_last_measure = {
		"counted_meshes": counted,
		"skipped_invisible": skipped_invisible,
		"skipped_top_level": skipped_top_level,
		"widest_single_mesh_m": snappedf(widest, 0.001),
		"widest_single_mesh": widest_name,
		"signage": _aabb_dict(signage) if has_signage else null,
		"effects": _aabb_dict(effects) if has_effects else null,
		"fallback": not has_any,
	}
	if not has_any:
		# F5 — NOT a measurement, and the caller must be able to tell
		_last_measure["fallback_reason"] = (
			"no visible, non-signage, non-effect GeometryInstance3D in the subtree"
			+ (" (%d hidden, %d top-level skipped)" % [skipped_invisible, skipped_top_level.size()]))
		return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
	return combined


func _aabb_dict(a: AABB) -> Dictionary:
	return {
		"center": [snappedf(a.get_center().x, 0.001), snappedf(a.get_center().y, 0.001),
			snappedf(a.get_center().z, 0.001)],
		"size": [snappedf(a.size.x, 0.001), snappedf(a.size.y, 0.001), snappedf(a.size.z, 0.001)],
	}
```

Then merge `_last_measure` into the manifest beside `aabb`, so provenance ships
with the number.

## F6 · the harness never reads `dna.fixture`

Separate one-line-ish fix in `_run`, not in this function. `laser_measure`'s
registry entry **already declares** `dna.fixture {max_range: 0.25}` to pin
exactly this capture. Nothing reads it. The fix for the worst number in the set
is already sitting in the data.

---

## The negative tests

Each must FAIL on today's code and PASS after. Do not accept the patch on the
strength of the fixes reading well.

| # | artifact | today | after | proves |
|---|---|---|---|---|
| 1 | `scale_lines` | 10.0 m wide | ~100 m | F1 stops deleting real geometry |
| 2 | `laser_measure` | 50.081 m tall | ~0.17 m *with* F6 | F1 + F6 |
| 3 | `pythagorean_triangle_angles` | depth 1.67 m | ~0.0 m body, 1.67 m signage | F2 |
| 4 | `force_field` | 3.645 m wide | ≪ 3.645 m body | F2 |
| 5 | `draw_dot` | 3.29 m tall | ~0.34 m | F3 |
| 6 | `draw_triangle_faces` | 3.224 m tall | ≪ 3.224 m | F3 |
| 7 | `edge_core` | 0.99 m | unchanged, `effects` populated | F4 without regression |
| 8 | `particle_chaos` | `[1,1,1]` silent | `[1,1,1]` + `fallback: true` | F5 |
| 9 | `lambda_slider` | 0.69 × 0.33 × 1.31 | **unchanged** | the fixes break nothing that worked |

Test 9 is the one to run first. Three artifacts already reproduce published
featured-grade captures — `lambda_slider`, `origin`, `platonicsolids` — and if
the patch moves any of them, it is wrong regardless of how good the other eight
look.

## After it lands

Re-measure the 25 known-bad from `commons/data/staged_measurements.json`
(`GET /api/staging-measurements?flagged=1`). That is 50 captures, about ten
minutes serial, and it is the honest test of whether the fix worked. Then the
oracle: `artifact_sizes.json` still carries 19 particle-box entries, 223 zeros
and 125 giants, and it is what everything except `staged_measurements.json`
reads.
